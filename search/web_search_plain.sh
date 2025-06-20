#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e
# Exit if any command in a pipeline fails.
set -o pipefail


CACHE_DIR="/tmp/shelllm_search_cache"

SEARCH_QUERY_TEXT=""

MAX_RESULTS=10

OUTPUT_FILE=""

PROCESS_WITH_LLM_FLAG="true"

ENABLE_META_SUMMARY_FLAG="false"

DEBUG_MODE="false"


error() {
    echo "[ERROR] $1" >&2
}


usage() {
    echo "Usage: $0 -q \"search query\" [options]"
    echo "Options:"
    echo "  -q, --query        Search query (required)"
    echo "  -n, --num-results  Number of Google search results to fetch (default: 10, max: 100)"
    echo "  -o, --output       Output file for results (default: stdout)"
    echo "  -r, --raw-content  Output raw scraped text content without LLM processing for each URL"
    echo "  -S, --enable-summary Enable a final meta-summary of all processed content (requires LLM processing)"
    echo "  -d, --debug        Enable debug logging"
    echo "  -h, --help         Display this help message"
    echo ""
    echo "Environment Variables Required:"
    echo "  GOOGLE_SEARCH_KEY: Your Google Custom Search API Key"
    echo "  GOOGLE_SEARCH_ID: Your Google Custom Search Engine ID"
    echo ""
    echo "Example: $0 -q \"low latency LLM provider\" -n 5 -o results.txt -S"
}


debug_log() {
    if [[ "$DEBUG_MODE" == "true" ]]; then
        echo "[DEBUG] $1" >&2
    fi
}


estimate_token_count() {
    local text="$1"
    local word_count
    word_count=$(echo "$text" | wc -w)
    local estimated_tokens
    estimated_tokens=$((word_count * 4 / 3))
    echo "$estimated_tokens"
}

# Select LLM model based on token count and task type.
# Outputs: "<plugin_name> <model_name>"
select_llm_model_for_task() {
    local token_count="$1"
    local task_type="$2" # "extract" or "summarize"

    # Define models for content extraction (per-URL analysis)
    # Using OpenRouter models for broader accessibility, ensure `llm-openrouter` plugin is installed
    local extract_small_plugin="llm-openrouter"
    local extract_small_model="cerebras-llama-4-scout-17b-16e-instruct" # Or any small, fast model
    local extract_large_plugin="llm-openrouter"
    local extract_large_model="openrouter/google/gemini-2.5-flash-preview-05-20" # Good for larger context

    # Define models for meta-summarization (aggregate summary)
    local summarize_small_plugin="llm-openrouter"
    local summarize_small_model="cerebras-llama-4-scout-17b-16e-instruct" # Mid-size for smaller summaries
    local summarize_large_plugin="llm-openrouter"
    local summarize_large_model="openrouter/google/gemini-2.5-flash-preview-05-20" # Good for very large context summarization

    local token_threshold=7500 # Threshold to switch between "small" and "large" models for context window management

    if [[ "$task_type" == "extract" ]]; then
        if ((token_count < token_threshold)); then
            echo "$extract_small_plugin $extract_small_model"
        else
            echo "$extract_large_plugin $extract_large_model"
        fi
    elif [[ "$task_type" == "summarize" ]]; then
        if ((token_count < token_threshold)); then
            echo "$summarize_small_plugin $summarize_small_model"
        else
            echo "$summarize_large_plugin $summarize_large_model"
        fi
    else
        error "Unknown task type for model selection: $task_type"
        return 1
    fi
}

fetch_archived_content() {
    local url="$1"
    local archived_url="https://web.archive.org/web/0/${url}"
    
    local page_html
    page_html=$(curl -sL --max-time 10 "$archived_url")
    if [[ $? -ne 0 || -z "$page_html" ]]; then
        error "Failed to retrieve content from web.archive.org for $url"
        echo ""
        return
    fi

    local page_text
    page_text=$(echo "$page_html" | html2text -b 0 --ignore-images --ignore-emphasis --ignore-links --single-line-break 2>/dev/null)
    if [[ -z "$page_text" ]]; then
        error "Failed to convert archived HTML to text for $url"
        echo ""
        return
    fi

    echo "$page_text"
}


process_content_with_llm() {
    local page_text="$1"
    local original_search_query="$2"
    local url="$3"
    local llm_output

    local extract_prompt="From the text content of the URL: $url, extract relevant quotes related to \"$original_search_query\". Also, provide a concise summary of the key points found in the text regarding the query. Each extracted quote should be accompanied by its context and explicitly state the URL it came from.
Structure your output clearly with:
1. A section titled 'Relevant Quotes' where each quote explicitly mentions:
   - The quote itself (with relevant surrounding context, if helpful)
   - The URL from which it was extracted (i.e., '$url').
2. A section titled 'Summary of Key Points' that summarizes the main insights from the page text related to the search query.
"

    local token_count
    token_count=$(estimate_token_count "$page_text")
    
    local model_info
    model_info=$(select_llm_model_for_task "$token_count" "extract")
    if [[ $? -ne 0 ]]; then
        error "Failed to select LLM model for extraction for $url. Content will not be processed by LLM."
        echo "Raw Text Fallback: $(echo "$page_text" | head -c 500)..."
        return
    fi

    local llm_plugin
    llm_plugin=$(echo "$model_info" | cut -d' ' -f1)
    local llm_model_name
    llm_model_name=$(echo "$model_info" | cut -d' ' -f2-)

    # Construct context for LLM
    local llm_input_text
    llm_input_text=$(cat <<EOF
<url>
$url
</url>

<page_text>
$page_text
</page_text>
EOF
)

    # Call the LLM tool with the specified plugin, model, and prompt
    local llm_stderr_file
    llm_stderr_file=$(mktemp "/tmp/gsearch_llm_stderr_${url//[^a-zA-Z0-9]/_}.XXXXXX")
    
    llm_output=$(LLM_LOAD_PLUGINS="$llm_plugin" echo "$llm_input_text" | llm -m "$llm_model_name" --system "$extract_prompt" 2>"$llm_stderr_file")
    local llm_exit_status=$?
    
    if [[ $llm_exit_status -ne 0 || -z "$llm_output" ]]; then
        local llm_stderr_content
        llm_stderr_content=$(cat "$llm_stderr_file")
        error "LLM processing failed for $url (Plugin: $llm_plugin, Model: $llm_model_name, Exit: $llm_exit_status). Check LLM configuration or API key."
        if [[ -n "$llm_stderr_content" ]]; then
            error "LLM stderr for $url:"
            while IFS= read -r line; do error "    $line"; done <<< "$llm_stderr_content"
        fi
        echo "Raw Text Fallback (first 500 chars): $(echo "$page_text" | head -c 500)..."
        rm -f "$llm_stderr_file"
        return
    fi
    rm -f "$llm_stderr_file"
    echo "$llm_output"
}

google_search() {
    local query_arg=""
    local num_results_arg="10"

    # Parse arguments specifically for google_search function
    while [[ $# -gt 0 ]]; do
        key="$1"
        case $key in
            -q|--query)
                query_arg="$2"
                shift 2
                ;;
            -n|--num)
                num_results_arg="$2"
                shift 2
                ;;
            *)
                # Ignore unknown options passed to the outer script
                shift
                ;;
        esac
    done

    # Validate arguments for this function
    if [ -z "$query_arg" ]; then
        error "Search query is required for google_search internal function."
        return 1
    fi
    if ! [[ "$num_results_arg" =~ ^[0-9]+$ ]] || [ "$num_results_arg" -le 0 ]; then
        error "Number of results must be a positive integer for google_search internal function."
        num_results_arg=10
    fi
    if [ "$num_results_arg" -gt 100 ]; then
        num_results_arg=100
        echo "Warning: google_search capping results at 100 as per Google API limits." >&2
    fi

    API_KEY=${GOOGLE_SEARCH_KEY}
    SEARCH_ENGINE_ID=${GOOGLE_SEARCH_ID}

    if [ -z "$API_KEY" ] || [ -z "$SEARCH_ENGINE_ID" ]; then
        error "GOOGLE_SEARCH_KEY and GOOGLE_SEARCH_ID environment variables must be set."
        echo "Please set up a Google Custom Search Engine and obtain an API key." >&2
        echo "Then set the following environment variables:" >&2
        echo "export GOOGLE_SEARCH_KEY='your_api_key_here'" >&2
        echo "export GOOGLE_SEARCH_ID='your_search_engine_id_here'" >&2
        return 1
    fi

    # URL encode the query
    ENCODED_QUERY=$(printf '%s' "$query_arg" | jq -sRr @uri)

    # Function to perform a single batch search (max 10 results per API call)
    _perform_batch_search() {
        local start_index=$1
        local batch_num_results=$2 # Max 10 for Google API as `num` parameter
        local search_url="https://www.googleapis.com/customsearch/v1?key=${API_KEY}&cx=${SEARCH_ENGINE_ID}&q=${ENCODED_QUERY}&num=${batch_num_results}&start=${start_index}"

        local response
        response=$(curl -s "$search_url")
        local curl_exit_code=$?

        if [ $curl_exit_code -ne 0 ]; then
            error "curl command failed with exit code $curl_exit_code for URL $search_url"
            return 1
        fi

        if [ -z "$response" ]; then
            error "Empty response received from the API for URL $search_url"
            return 1
        fi

        if echo "$response" | jq -e '.error' > /dev/null; then
            echo "Error: Google Custom Search API request failed." >&2
            echo "Error code: $(echo "$response" | jq -r '.error.code')" >&2
            echo "Error message: $(echo "$response" | jq -r '.error.error.message')" >&2 
            local error_details=$(echo "$response" | jq '.error.errors')
            if [[ -n "$error_details" && "$error_details" != "null" ]]; then
                echo "Error details: $error_details" >&2
            fi
            return 1
        fi

        echo "$response" | jq '.items'
    }

    local current_start_index=1
    local aggregated_results="[]" # Start with an empty JSON array

    # Fetch results in batches, respecting total desired results and API limits
    while true; do
        local num_fetched=$(echo "$aggregated_results" | jq 'length')
        local num_remaining_to_fetch=$((num_results_arg - num_fetched))

        if [[ "$num_remaining_to_fetch" -le 0 ]]; then
            break # Fetched enough results
        fi

        local batch_size_to_request=$(( num_remaining_to_fetch > 10 ? 10 : num_remaining_to_fetch ))
        
        if [[ "$batch_size_to_request" -le 0 ]]; then
            break # No more to request
        fi

        # Google Custom Search API has a max 'start' index of 100 for pagination
        if [[ "$current_start_index" -gt 100 ]]; then
             echo "Reached Google Custom Search API 'start' limit (100). Cannot fetch more than ~100 results." >&2
             break
        fi

        local batch_json_results
        batch_json_results=$(_perform_batch_search "$current_start_index" "$batch_size_to_request")
        if [ $? -ne 0 ]; then
            return 1 # Error already printed by _perform_batch_search, stop.
        fi

        # jq might return 'null' if .items is not found or empty, ensure it's treated as an empty array
        if [[ -z "$batch_json_results" ]] || [[ "$batch_json_results" == "null" ]]; then
            printf -v batch_json_results '[]' # Reset to valid empty JSON array
        fi
        
        local items_in_batch
        items_in_batch=$(echo "$batch_json_results" | jq 'length')

        aggregated_results=$(echo "$aggregated_results" "$batch_json_results" | jq -s 'add')
        
        if [[ "$items_in_batch" -lt "$batch_size_to_request" ]]; then
            # API returned fewer items than requested, likely end of available results for this query.
            break
        fi

        current_start_index=$((current_start_index + items_in_batch))
        if ((current_start_index % 10 != 1)); then # Ensure start index is always _+1 for next batch
             # This is a safety check: if API returned fewer than 10, current_start_index might not be x1, where x is a multiple of 10.
             # This assumes start index for next batch is always current + 10, but if last batch was N items, next start is current + N.
             # The API typically takes current_start_index as 1-indexed.
             : # No specific correction needed, current_start_index update is accurate.
        fi
    done

    # Output the aggregated results in pretty JSON format
    echo "$aggregated_results" | jq '.'
}

# --- Core URL Processing Function for Parallel Execution ---
process_url() {
    local url="$1"
    local original_search_text="$2" 
    local current_cache_dir="$3" # Passed explicitly for parallel scope
    local process_llm_str_flag="$4" # "true" or "false" as string

    debug_log "process_url: url='$url', process_llm_str_flag='$process_llm_str_flag'"

    local page_text=""
    local final_output=""

    local should_process_llm=false
    if [[ "$process_llm_str_flag" == "true" ]]; then
        should_process_llm=true
    fi

    local mode_suffix="raw"
    if [[ "$should_process_llm" == "true" ]]; then
        mode_suffix="llm"
    fi

    local cache_key
    cache_key=$(echo -n "$url:$original_search_text:$mode_suffix" | md5sum | cut -d' ' -f1)
    local cache_file="$current_cache_dir/$cache_key"
    mkdir -p "$current_cache_dir" # Ensure cache directory exists

    # Try reading from cache first
    if [[ -f "$cache_file" ]]; then
        cat "$cache_file"
        return
    fi

    local page_content
    # Try fetching with a timeout and retries
    # --compressed: Request compressed response, curl decompresses it.
    # -L: Follow redirects.
    # -s: Silent mode.
    # --max-time: Max time for overall operation.
    # --connect-timeout: Max time for connection phase.
    # --retry: Number of retries on transient errors.
    # --retry-delay: Delay between retries.
    page_content=$(curl -sL --compressed --max-time 15 --connect-timeout 5 --retry 3 --retry-delay 2 "$url")
    if [[ -n "$page_content" ]]; then
        # Check if it's a PDF based on MIME type or URL extension
        local mime_type=$(echo "$page_content" | head -c 100 | grep -o '%PDF' || echo "")
        if [[ "$url" == *.pdf ]] || [[ -n "$mime_type" ]]; then
            if command -v pdftotext &>/dev/null; then
                page_text=$(pdftotext - - <<< "$page_content" 2>/dev/null)
            else
                page_text="Error: pdftotext command not found for PDF conversion at $url"
            fi
        else
            if command -v html2text &>/dev/null; then
                page_text=$(echo "$page_content" | html2text -b 0 --ignore-images --ignore-emphasis --ignore-links --single-line-break 2>/dev/null)
            else
                page_text="Error: html2text command not found for HTML conversion at $url"
                # Fallback: simple tag stripping
                page_text=$(echo "$page_content" | sed -e 's/<[^>]*>//g' -e 's/&[^;]*;//g' -e 's/\s\s*/ /g' | tr -d '\n\r')
            fi
        fi
    fi

    # Check for common blockers after initial content retrieval
    # Add "blocked by network security" to the patterns
    if [[ -z "$page_text" ]] || echo "$page_text" | grep -qiE 'verifying you are human|are you a robot|js challenge|cloudflare|access denied|forbidden|blocked by network security'; then
        error "Detected blocker/empty content for $url. Attempting to fetch from web.archive.org..."
        archived_text=$(fetch_archived_content "$url") # Capture the output
        if [[ -n "$archived_text" ]]; then
            page_text="$archived_text"
            echo "[INFO] Successfully fetched and used content from web.archive.org for $url." >&2
        else
            error "Failed to retrieve clean content for $url even from web.archive.org."
        fi
    fi

    if [[ -z "$page_text" ]]; then
        error "Failed to get any text content for $url. Skipping."
        return # Skip this URL if no content found
    fi

    if [[ "$should_process_llm" == "true" ]]; then
        local llm_processed_content
        llm_processed_content=$(process_content_with_llm "$page_text" "$original_search_text" "$url")
        
        if [[ -z "$llm_processed_content" ]]; then
            # LLM processing failed or returned empty (error already logged by process_content_with_llm)
            final_output="URL: $url
Error: LLM analysis failed or returned empty.
Raw Text Fallback (first 1000 chars):
$(echo "$page_text" | head -c 1000)...
--------------------------------------------------
"
        else
            final_output="URL: $url
--- LLM Analysis ---
$llm_processed_content
--------------------------------------------------
"
        fi
    else
        # Raw content requested
        final_output="URL: $url
--- Raw Content ---
$page_text
--------------------------------------------------
"
    fi

    # Write the final result to cache and stdout/file
    echo -e "$final_output" > "$cache_file"
    echo -e "$final_output"
}

# --- Optional Meta-Summary Generation Function ---
_generate_meta_summary() {
    if [[ "$PROCESS_WITH_LLM_FLAG" == "true" ]] && [[ "$ENABLE_META_SUMMARY_FLAG" == "true" ]]; then
        if [[ -z "$ALL_PROCESSED_RESULTS" ]]; then
            output_result ""
            output_result "Meta-Summary: No content was successfully processed to summarize."
        else
            output_result ""
            output_result "=================================================="
            output_result "META-SUMMARY:"
            output_result "=================================================="
            echo "Generating meta-summary (this may take a while for large content sets)..." >&2

            local summary_token_count ALL_PROCESSED_RESULTS_length
            summary_token_count=$(estimate_token_count "$ALL_PROCESSED_RESULTS")
            ALL_PROCESSED_RESULTS_length=${#ALL_PROCESSED_RESULTS}

            debug_log "Meta-summary generation initiated."
            debug_log "Estimated token count for ALL_PROCESSED_RESULTS: $summary_token_count (length: $ALL_PROCESSED_RESULTS_length chars)"
            if [[ "$ALL_PROCESSED_RESULTS_length" -gt 0 && "$ALL_PROCESSED_RESULTS_length" -lt 5000 ]]; then # Only print if reasonably small
                 debug_log "ALL_PROCESSED_RESULTS (first 500 chars): ${ALL_PROCESSED_RESULTS:0:500}..."
            elif [[ "$ALL_PROCESSED_RESULTS_length" -eq 0 ]]; then
                 debug_log "ALL_PROCESSED_RESULTS is empty."
            fi


            local summary_model_info summary_llm_plugin summary_llm_model_name summary_prompt meta_summary
            summary_model_info=$(select_llm_model_for_task "$summary_token_count" "summarize")
            
            if [[ $? -ne 0 ]]; then
                error "Failed to select LLM model for meta-summary. Summary generation skipped."
                output_result "Error: Could not generate meta-summary due to model selection failure."
            else
                local summary_llm_plugin
                summary_llm_plugin=$(echo "$summary_model_info" | cut -d' ' -f1)
                local summary_llm_model_name
                summary_llm_model_name=$(echo "$summary_model_info" | cut -d' ' -f2-)
                debug_log "Selected meta-summary LLM: Plugin='$summary_llm_plugin', Model='$summary_llm_model_name'. Timeout will be 900s."

                local summary_prompt="Based on the provided collection of processed search results (each containing a URL and LLM-extracted quotes/summaries related to the original query \"$SEARCH_QUERY_TEXT\"), synthesize a comprehensive meta-summary that synthesizes the findings across all sources. Highlight the key themes, most relevant findings, and any consensus or contradictions found across the different sources. Aim for a concise yet informative overview. Your summary should be well-structured with clear paragraphs."
                
                local meta_summary llm_exit_status llm_stderr_file llm_stderr_content
                llm_stderr_file=$(mktemp "/tmp/gsearch_llm_meta_stderr.XXXXXX")
                
                # Local trap for this specific temp file cleanup
                _cleanup_llm_stderr_file() {
                    rm -f "$llm_stderr_file"
                }
                trap _cleanup_llm_stderr_file RETURN # Cleans up when function returns

                debug_log "Attempting LLM call for meta-summary..."
                # Use printf for robustness with large inputs, increased timeout to 900s (15 minutes)
                meta_summary=$(LLM_LOAD_PLUGINS="$summary_llm_plugin" printf "%s" "$ALL_PROCESSED_RESULTS" | llm -m "$summary_llm_model_name" --system "$summary_prompt" 2>"$llm_stderr_file")
                llm_exit_status=$?

                debug_log "LLM call for meta-summary finished. Exit status: $llm_exit_status"
                
                llm_stderr_content=$(cat "$llm_stderr_file")
                debug_log "LLM stderr content for meta-summary (first 500 chars): $(echo "${llm_stderr_content:0:500}")..."

                debug_log "Checking meta_summary result. Is meta_summary empty? $( [[ -z "$meta_summary" ]] && echo 'Yes' || echo 'No' ). Is meta_summary whitespace? $( [[ ! "$meta_summary" =~ [^[:space:]] ]] && echo 'Yes' || echo 'No' )"
                
                # Check for non-zero exit status, empty summary, or summary with only whitespace
                if [[ $llm_exit_status -ne 0 ]] || { [[ -z "$meta_summary" ]] && [[ ! "$meta_summary" =~ [^[:space:]] ]]; }; then
                    error "Meta-summary generation failed or returned empty/whitespace."
                    error "  LLM Exit Status: $llm_exit_status"
                    error "  LLM Plugin: $summary_llm_plugin, Model: $summary_llm_model_name"
                    if [[ -n "$llm_stderr_content" ]]; then
                        error "  LLM stderr output:"
                        # Indent stderr for clarity
                        while IFS= read -r line; do error "    $line"; done <<< "$llm_stderr_content"
                    else
                        error "  LLM produced no stderr output."
                    fi
                    output_result "" # Ensure a newline before the error message if outputting to file
                    output_result "Error: Meta-summary generation failed. Please check script error messages (stderr) for details."
                else
                    # Success, output the meta_summary
                    output_result "$meta_summary"
                fi
            fi
        fi
    elif [[ "$ENABLE_META_SUMMARY_FLAG" == "true" ]]; then # Note: elif here to handle the case where summary is enabled but LLM processing is not
         output_result ""
         output_result "Meta-Summary: Skipped because LLM processing for individual URLs was disabled (the -r flag was used). Meta-summary requires processed content."
    fi
}

# --- Main Script Logic ---

# Check for essential command-line tools at script start
check_dependencies() {
    local required_commands=("jq" "curl" "md5sum" "parallel" "llm" "wc" "html2text")
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            error "$cmd command not found. Please install it: sudo apt-get install $cmd"
            exit 1
        fi
    done
    # pdftotext is optional but highly recommended.
    if ! command -v pdftotext &> /dev/null; then
        echo "Warning: pdftotext not found. PDF content will not be processed correctly. Install with: sudo apt-get install poppler-utils" >&2
    fi
     # llc_cli plugins for specific models (e.g., llm-openrouter) are required. Inform user.
    if ! llm plugins install --help &> /dev/null; then
        echo "Warning: llm CLI tool seems to be missing or misconfigured. Ensure 'llm' is installed and its plugins are set up. Refer to https://llm.datasette.com/" >&2
        echo "Example: llm install llm-openrouter" >&2
    fi
}
check_dependencies

# Parse command-line arguments for the main script
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -q|--query)
            SEARCH_QUERY_TEXT="$2"
            shift 2
            ;;
        -n|--num-results)
            if ! [[ "$2" =~ ^[0-9]+$ ]] || [[ "$2" -le 0 ]]; then
                error "Number of results must be a positive integer."
                usage
                exit 1
            fi
            MAX_RESULTS="$2"
            if ((MAX_RESULTS > 100)); then
                MAX_RESULTS=100
                echo "Warning: Maximum results capped at 100." >&2
            fi
            shift 2
            ;;
        -o|--output)
            OUTPUT_FILE="$2"
            mkdir -p "$(dirname "$OUTPUT_FILE")" # Ensure directory for output file exists
            shift 2
            ;;
        -r|--raw-content)
            PROCESS_WITH_LLM_FLAG="false"
            shift
            ;;
        -S|--enable-summary)
            ENABLE_META_SUMMARY_FLAG="true"
            shift
            ;;
        -d|--debug)
            DEBUG_MODE="true"
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Validate required arguments
if [[ -z "$SEARCH_QUERY_TEXT" ]]; then
    error "Search query is required. Use -q or --query."
    usage
    exit 1
fi

# Ensure `GOOGLE_SEARCH_KEY` and `GOOGLE_SEARCH_ID` are set.
if [ -z "${GOOGLE_SEARCH_KEY}" ] || [ -z "${GOOGLE_SEARCH_ID}" ]; then
    error "Both GOOGLE_SEARCH_KEY and GOOGLE_SEARCH_ID environment variables must be set."
    echo "Please configure your environment before running this script." >&2
    exit 1
fi

# Export functions and variables needed by GNU Parallel.
# Functions must be exported to be available in subshells created by parallel.
export -f process_url
export -f process_content_with_llm
export -f fetch_archived_content
export -f error
export -f estimate_token_count
export -f select_llm_model_for_task
export -f debug_log # Export debug_log for parallel processes
export GOOGLE_SEARCH_KEY GOOGLE_SEARCH_ID DEBUG_MODE # For google_search internal calls and parallel processes

# Perform Google Search
echo "Fetching Google search results for: \"$SEARCH_QUERY_TEXT\" (max $MAX_RESULTS results)..." >&2
SEARCH_JSON=$(google_search -q "$SEARCH_QUERY_TEXT" -n "$MAX_RESULTS")
if [[ $? -ne 0 || -z "$SEARCH_JSON" || "$SEARCH_JSON" == "null" || "$(echo "$SEARCH_JSON" | jq 'length')" -eq 0 ]]; then
    error "Failed to retrieve search results from Google, or no results found. Exiting."
    exit 1
fi

# Extract URLs from the search results. `jq -r` outputs raw strings, `select(. != null)` filters out any null links.
URLS=$(echo "$SEARCH_JSON" | jq -r '.[].link | select(. != null)')

if [[ -z "$URLS" ]]; then
    error "No valid URLs found in the Google search results based on the provided query. Exiting."
    exit 1
fi

# Function to handle output (to specified file or stdout).
output_result() {
    if [[ -n "$OUTPUT_FILE" ]]; then
        echo -e "$1" >> "$OUTPUT_FILE"
    else
        echo -e "$1"
    fi
}

# Clear output file content once at the beginning if specified.
if [[ -n "$OUTPUT_FILE" ]]; then
    echo -n "" > "$OUTPUT_FILE" # Clear the file
fi


# --- Process URLs in Parallel ---
echo "Processing $(echo "$URLS" | wc -l) URLs in parallel..." >&2
# `nproc` determines the number of parallel jobs (CPU cores)
# The arguments to `process_url` are: URL, SEARCH_QUERY_TEXT, CACHE_DIR, PROCESS_WITH_LLM_FLAG
ALL_PROCESSED_RESULTS=$(echo "$URLS" | parallel --quote -j "$(nproc)" process_url {} "$SEARCH_QUERY_TEXT" "$CACHE_DIR" "$PROCESS_WITH_LLM_FLAG")

# --- Aggregate and Output Results ---
output_result "Search Query: \"$SEARCH_QUERY_TEXT\""
output_result "Number of results requested: $MAX_RESULTS"
output_result "LLM Processing: $(if [[ "$PROCESS_WITH_LLM_FLAG" == "true" ]]; then echo "Enabled"; else echo "Disabled (Raw Content)"; fi)"
output_result "Generated on: $(date)"
output_result "=================================================="
output_result "DETAILED RESULTS:"
output_result "=================================================="
output_result "$ALL_PROCESSED_RESULTS"


# --- Generate Meta-Summary (if enabled) ---
_generate_meta_summary

echo "Script execution completed." >&2
if [[ -n "$OUTPUT_FILE" ]]; then
    echo "Results saved to: $OUTPUT_FILE" >&2
fi

exit 0