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


SINGLE_URL_TO_PROCESS=""

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
    echo "  -U, --url-direct   Process a single URL directly, bypassing Google Search. Requires -q for LLM context if LLM processing is enabled."
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
    local extract_small_model="cerebras-scout-4" # Or any small, fast model
    local extract_large_plugin="llm-openrouter"
    local extract_large_model="openrouter/google/gemini-2.5-flash-preview-05-20" # Good for larger context

    # Define models for meta-summarization (aggregate summary)
    local summarize_small_plugin="llm-openrouter"
    local summarize_small_model="cerebras-scout-4" # Mid-size for smaller summaries
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
    local llm_json_output

    # Prompt for JSON output
    local extract_prompt
    # Ensure the heredoc for extract_prompt correctly substitutes variables.
    # Using cat <<EOF is safer for complex strings and variable expansion.
    extract_prompt=$(cat <<EOF
Your task is to analyze the provided text content from the URL: ${url}, in relation to the search query: "${original_search_query}".
You MUST output a valid JSON object with the following structure and nothing else:
{
  "relevant_quotes": [
    {"quote": "The extracted quote...", "context": "Brief context surrounding the quote...", "source_url": "${url}"}
  ],
  "summary_of_key_points": "A concise summary of key points from the text related to the query."
}
If no relevant quotes are found, "relevant_quotes" MUST be an empty array [].
If the text cannot be summarized or no key points are found, "summary_of_key_points" MUST be an empty string "" or null.
Do NOT include any introductory text, explanations, or markdown formatting outside of the JSON object itself.
EOF
)

    local token_count
    token_count=$(estimate_token_count "$page_text")
    
    local model_info
    model_info=$(select_llm_model_for_task "$token_count" "extract")
    if [[ $? -ne 0 ]]; then
        error "Failed to select LLM model for extraction for $url. Content will not be processed by LLM."
        # Return an error structure or empty string to indicate failure to the caller
        echo "" 
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
    _cleanup_llm_stderr_file() {
        debug_log "Cleaning up LLM stderr temp file: $llm_stderr_file for $url"
        rm -f "$llm_stderr_file"
    }
    trap _cleanup_llm_stderr_file RETURN EXIT INT TERM

    # Added timeout 300s (5 minutes) for per-URL LLM processing
    llm_json_output=$(LLM_LOAD_PLUGINS="$llm_plugin" echo "$llm_input_text" | timeout 300s llm -m "$llm_model_name" --system "$extract_prompt" 2>"$llm_stderr_file")
    local llm_exit_status=$?
    
    if [[ $llm_exit_status -ne 0 ]] || ! echo "$llm_json_output" | jq -e . > /dev/null 2>&1; then
        local llm_stderr_content=$(cat "$llm_stderr_file")
        error "LLM processing failed for $url (Plugin: $llm_plugin, Model: $llm_model_name, Exit: $llm_exit_status). Check LLM configuration or API key."
        if [[ -n "$llm_stderr_content" ]]; then
            error "LLM stderr for $url:"
            while IFS= read -r line; do error "    $line"; done <<< "$llm_stderr_content"
        fi
        echo "Raw Text Fallback (first 500 chars): $(echo "$page_text" | head -c 500)..."
        rm -f "$llm_stderr_file"
        trap - RETURN EXIT INT TERM # Clear trap
        echo "" # Return empty on failure to produce valid JSON
        return
    fi

    trap - RETURN EXIT INT TERM # Clear trap
    rm -f "$llm_stderr_file"
    echo "$llm_json_output" # Return the JSON string
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

    debug_log "process_url starting for: url='$url', query_context='$original_search_text', process_llm_flag='$process_llm_str_flag'"

    local page_text=""
    local result_json # This will hold the final JSON object for this URL

    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local status_message="processing"
    local error_detail=""
    local llm_analysis_json=""
    local raw_text_content=""

    local should_process_llm=false # Renamed for clarity
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
    # If cache exists, we assume it's a valid JSON object as per our new output format
    if [[ -f "$cache_file" ]]; then
        debug_log "Using cached result for $url from $cache_file"
        cat "$cache_file"
        return
    fi

    # Helper function to construct JSON output
    _build_json_output() {
        jq -n \
          --arg url "$url" \
          --arg status "$1" \
          --arg processing_mode "$2" \
          --arg search_query_context "$original_search_text" \
          --arg timestamp "$timestamp" \
          --arg error_message "$3" \
          --arg json llm_analysis "${4:-null}" \
          --arg raw_text "${5:-""}" \
          '{url: $url, status: $status, processing_mode: $processing_mode, search_query_context: $search_query_context, timestamp: $timestamp, data: {error_message: (if $error_message == "" then null else $error_message end), llm_analysis: $llm_analysis, raw_text: (if $raw_text == "" then null else $raw_text end)}}'
        return
    } 

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
                raw_text_content=$(pdftotext - - <<< "$page_content" 2>/dev/null)
            else
                error_detail="pdftotext command not found for PDF conversion at $url"
                raw_text_content="" # No text extracted
            fi
        else
            if command -v html2text &>/dev/null; then
                raw_text_content=$(echo "$page_content" | html2text -b 0 --ignore-images --ignore-emphasis --ignore-links --single-line-break 2>/dev/null)
            else
                error_detail="html2text command not found for HTML conversion at $url. Using basic strip."
                # Fallback: simple tag stripping
                raw_text_content=$(echo "$page_content" | sed -e 's/<[^>]*>//g' -e 's/&[^;]*;//g' -e 's/\s\s*/ /g' | tr -d '\n\r')
            fi
        fi
    fi

    # Check for common blockers after initial content retrieval
    # Add "blocked by network security" to the patterns
    if [[ -z "$raw_text_content" ]] || echo "$raw_text_content" | grep -qiE 'verifying you are human|are you a robot|js challenge|cloudflare|access denied|forbidden|blocked by network security'; then
        error "Detected blocker/empty content for $url. Attempting to fetch from web.archive.org..."
        archived_text=$(fetch_archived_content "$url") # Capture the output
        if [[ -n "$archived_text" ]]; then
            raw_text_content="$archived_text"
            echo "[INFO] Successfully fetched and used content from web.archive.org for $url." >&2
            error_detail="" # Clear previous error if archive worked
        else
            error_detail="Failed to retrieve clean content for $url even from web.archive.org. ${error_detail}"
        fi
    fi

    if [[ -z "$raw_text_content" ]]; then
        error "Failed to get any text content for $url. ${error_detail}"
        result_json=$(_build_json_output "error_fetch" "error" "Failed to get any text content. ${error_detail}" "" "")
        echo "$result_json" > "$cache_file"
        echo "$result_json"
        return
    fi

    if [[ "$should_process_llm" == "true" ]]; then
        llm_analysis_json=$(process_content_with_llm "$raw_text_content" "$original_search_text" "$url")
        
        if [[ -z "$llm_analysis_json" ]] || ! echo "$llm_analysis_json" | jq -e . > /dev/null 2>&1 ; then
            # LLM processing failed or returned empty (error already logged by process_content_with_llm)
            error_detail="LLM analysis failed or returned non-JSON/empty. ${error_detail}"
            status_message="success_llm_failed_fallback"
            result_json=$(_build_json_output "$status_message" "llm_fallback_to_raw" "$error_detail" "" "$raw_text_content")
        else
            status_message="success"
            # llm_analysis_json already contains the JSON string from process_content_with_llm
            result_json=$(_build_json_output "$status_message" "llm_processed" "$error_detail" "$llm_analysis_json" "$raw_text_content")
        fi
    else
        # Raw content requested
        status_message="success_raw_only"
        result_json=$(_build_json_output "$status_message" "raw_text" "$error_detail" "" "$raw_text_content")
    fi

    # Write the final result to cache and stdout/file
    echo "$result_json" > "$cache_file"
    echo "$result_json"
}

# --- Optional Meta-Summary Generation Function ---
_generate_meta_summary() { # Takes processed results (JSON Lines) as stdin
    local all_processed_results_stdin
    all_processed_results_stdin=$(cat) # Read from stdin

    if [[ "$PROCESS_WITH_LLM_FLAG" == "true" ]] && [[ "$ENABLE_META_SUMMARY_FLAG" == "true" ]]; then
        if [[ -z "$all_processed_results_stdin" ]]; then
            # Output a JSON object for the summary status
            jq -n --arg msg "No content was successfully processed to summarize." \
                  '{type: "meta_summary", status: "skipped", reason: $msg}'
            return
        else
            echo "Generating meta-summary (this may take a while for large content sets)..." >&2

            local summary_token_count ALL_PROCESSED_RESULTS_length
            summary_token_count=$(estimate_token_count "$all_processed_results_stdin")
            ALL_PROCESSED_RESULTS_length=${#all_processed_results_stdin}

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
                local reason="Failed to select LLM model for meta-summary."
                error "$reason Summary generation skipped."
                jq -n --arg reason "$reason" \
                      '{type: "meta_summary", status: "error", reason: $reason, summary_text: null}'
            else
                local summary_llm_plugin
                # shellcheck disable=SC2034 # summary_llm_plugin is used in LLM_LOAD_PLUGINS
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
                meta_summary=$(LLM_LOAD_PLUGINS="$summary_llm_plugin" printf "%s" "$all_processed_results_stdin" | timeout 900s llm -m "$summary_llm_model_name" --system "$summary_prompt" 2>"$llm_stderr_file")
                llm_exit_status=$?

                debug_log "LLM call for meta-summary finished. Exit status: $llm_exit_status"
                
                llm_stderr_content=$(cat "$llm_stderr_file")
                debug_log "LLM stderr content for meta-summary (first 500 chars): $(echo "${llm_stderr_content:0:500}")..."

                debug_log "Checking meta_summary result. Is meta_summary empty? $( [[ -z "$meta_summary" ]] && echo 'Yes' || echo 'No' ). Is meta_summary whitespace? $( [[ ! "$meta_summary" =~ [^[:space:]] ]] && echo 'Yes' || echo 'No' )"
                
                # Check for non-zero exit status, empty summary, or summary with only whitespace
                if [[ $llm_exit_status -ne 0 ]] || { [[ -z "$meta_summary" ]] && [[ ! "$meta_summary" =~ [^[:space:]] ]]; }; then
                    local reason="Meta-summary generation failed or returned empty/whitespace. LLM Exit: $llm_exit_status. Plugin: $summary_llm_plugin, Model: $summary_llm_model_name."
                    error "$reason"
                    if [[ -n "$llm_stderr_content" ]]; then
                        error "  LLM stderr output:"
                        # Indent stderr for clarity
                        while IFS= read -r line; do error "    $line"; done <<< "$llm_stderr_content"
                    else
                        error "  LLM produced no stderr output."
                    fi
                    jq -n --arg reason "$reason" \
                          '{type: "meta_summary", status: "error", reason: $reason, summary_text: null}'
                else
                    # Success, output the meta_summary
                    jq -n --arg summary "$meta_summary" \
                          '{type: "meta_summary", status: "success", summary_text: $summary}'
                fi
            fi
        fi
    elif [[ "$ENABLE_META_SUMMARY_FLAG" == "true" ]]; then # Note: elif here to handle the case where summary is enabled but LLM processing is not
        local reason="Skipped because LLM processing for individual URLs was disabled (-r flag). Meta-summary requires processed content."
        jq -n --arg reason "$reason" \
              '{type: "meta_summary", status: "skipped", reason: $reason}'
    else
        : # Meta summary not enabled, do nothing.
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
        -U|--url-direct)
            SINGLE_URL_TO_PROCESS="$2"
            shift 2
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
if [[ -z "$SEARCH_QUERY_TEXT" && -z "$SINGLE_URL_TO_PROCESS" ]]; then
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

# Clear output file content once at the beginning if specified.
if [[ -n "$OUTPUT_FILE" ]]; then
    echo -n "" > "$OUTPUT_FILE" # Clear the file
fi

# --- Main Execution Logic ---
if [[ -n "$SINGLE_URL_TO_PROCESS" ]]; then
    debug_log "Single URL mode: Processing $SINGLE_URL_TO_PROCESS"
    if [[ "$PROCESS_WITH_LLM_FLAG" == "true" && -z "$SEARCH_QUERY_TEXT" ]]; then
        error "Search query context (-q) is required when processing a single URL with LLM enabled."
        usage
        exit 1
    fi
    # process_url outputs JSON directly
    result_json=$(process_url "$SINGLE_URL_TO_PROCESS" "$SEARCH_QUERY_TEXT" "$CACHE_DIR" "$PROCESS_WITH_LLM_FLAG")
    if [[ -n "$OUTPUT_FILE" ]]; then
        echo "$result_json" >> "$OUTPUT_FILE"
    else
        echo "$result_json"
    fi
else
    # Search mode
    debug_log "Search mode: Query='$SEARCH_QUERY_TEXT', Max_Results='$MAX_RESULTS'"
    echo "Fetching Google search results for: \"$SEARCH_QUERY_TEXT\" (max $MAX_RESULTS results)..." >&2
    SEARCH_JSON=$(google_search -q "$SEARCH_QUERY_TEXT" -n "$MAX_RESULTS")

    if [[ $? -ne 0 || -z "$SEARCH_JSON" || "$SEARCH_JSON" == "null" || "$(echo "$SEARCH_JSON" | jq 'length')" -eq 0 ]]; then
        error "Failed to retrieve search results from Google, or no results found. Exiting."
        # Output an empty JSON array or a status object if file output is specified
        if [[ -n "$OUTPUT_FILE" ]]; then
            jq -n '{type: "search_results", status: "error", reason: "Failed to retrieve or no results found", results: []}' > "$OUTPUT_FILE"
        else
            jq -n '{type: "search_results", status: "error", reason: "Failed to retrieve or no results found", results: []}'
        fi
        exit 1
    fi

    URLS=$(echo "$SEARCH_JSON" | jq -r '.[].link | select(. != null)')

    if [[ -z "$URLS" ]]; then
        error "No valid URLs found in the Google search results. Exiting."
        if [[ -n "$OUTPUT_FILE" ]]; then
            jq -n '{type: "search_results", status: "no_urls", reason: "No valid URLs found in search results", results: []}' > "$OUTPUT_FILE"
        else
            jq -n '{type: "search_results", status: "no_urls", reason: "No valid URLs found in search results", results: []}'
        fi
        exit 1
    fi

    echo "Processing $(echo "$URLS" | wc -l) URLs in parallel (outputting JSON Lines)..." >&2
    
    # Process URLs in parallel, results will be a stream of JSON objects (JSON Lines)
    # Each call to process_url will output its JSON to stdout here.
    # We capture it into a variable to pass to meta-summary, and also echo/append to file.
    ALL_PROCESSED_RESULTS_JSON_LINES=$(echo "$URLS" | parallel --quote -j "$(nproc)" process_url {} "$SEARCH_QUERY_TEXT" "$CACHE_DIR" "$PROCESS_WITH_LLM_FLAG")

    if [[ -n "$OUTPUT_FILE" ]]; then
        echo "$ALL_PROCESSED_RESULTS_JSON_LINES" >> "$OUTPUT_FILE"
    else
        echo "$ALL_PROCESSED_RESULTS_JSON_LINES"
    fi

    # Generate Meta-Summary (if enabled), it will output its own JSON object
    # Pass the JSON Lines as stdin to the function
    summary_json=$(echo "$ALL_PROCESSED_RESULTS_JSON_LINES" | _generate_meta_summary)
    if [[ -n "$summary_json" ]]; then # If summary was generated (or skipped/errored with JSON output)
        if [[ -n "$OUTPUT_FILE" ]]; then
            echo "$summary_json" >> "$OUTPUT_FILE"
        else
            echo "$summary_json"
        fi
    fi
fi

echo "Script execution completed." >&2
if [[ -n "$OUTPUT_FILE" ]]; then
    echo "Results saved to: $OUTPUT_FILE" >&2
fi

exit 0