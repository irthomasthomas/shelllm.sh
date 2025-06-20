#!/bin/bash

set -e
set -o pipefail
source "$(dirname "$0")/google-search.sh"

error() {
    echo "[ERROR] $1" >&2
}

usage() {
    echo "Usage: $0 -q \"search query\" [options]"
    echo "Options:"
    echo "  -q, --query        Search query (required)"
    echo "  -n, --num-results  Number of results to fetch (default: 10, max: 100)"
    echo "  -o, --output       Output file for results (default: stdout)"
    echo "  -r, --raw-content  Output raw scraped text content without LLM processing"
    echo "Example: $0 -q \"low latency LLM provider\" -n 50 -o results.txt"
}

estimate_token_count() {
    local text="$1"
    local word_count=$(echo "$text" | wc -w)
    local estimated_tokens=$((word_count * 4 / 3))
    echo "$estimated_tokens"
}

select_llm_model() {
    local token_count="$1"
    if ((token_count < 8000)); then
        echo "cerebras-llama3.3-70b"
        # TODO: check for HTTP status code 429 and switch to a different model
        # echo "llm-cerebras -m cerebras-llama3.3-70b"
    else
        echo "gemini-2"
        # echo "llm-groq -m llama-3.1-8b-instant"
    fi
}

fetch_archived_content() {
    local url="$1"
    local archived_url="https://web.archive.org/web/0/$url"
    
    local page_html
    page_html=$(curl -sL "$archived_url")
    if [[ $? -ne 0 || -z "$page_html" ]]; then
        echo "Failed to retrieve content from web.archive.org for $url" >&2
        return
    fi

    local page_text
    page_text=$(echo "$page_html" | html2text -b 0 --ignore-images --ignore-emphasis --ignore-links --single-line-break)
    if [[ -z "$page_text" ]]; then
        echo "Failed to convert archived HTML to text for $url" >&2
        return
    fi

    echo "$page_text"
}

process_content_with_llm() {
    local page_text="$1"
    local original_search_query="$2"
    local url="$3"
    local llm_output

    local EXTRACT_PROMPT="Extract relevant quotes from the page text related to \"$original_search_query\". Provide a summary of the key points."

    local token_count=$(estimate_token_count "$page_text")
    # local llm_model=$(select_llm_model "$token_count") # select_llm_model is defined but not used this way in original

    if ((token_count < 8000)); then
        llm_output=$(LLM_LOAD_PLUGINS='llm-cerebras' echo "<url>
$url
</url>

<page_text>
$page_text
</page_text>" | llm -m cerebras-llama3.3-70b --system "$EXTRACT_PROMPT")
    else
        llm_output=$(LLM_LOAD_PLUGINS='llm-gemini' echo "
<url>
$url
</url>
<page_text>
$page_text
</page_text>" | llm -m openrouter/google/gemini-2.0-flash-001 --system "$EXTRACT_PROMPT")
    fi
    echo "$llm_output"
}

CACHE_DIR="/tmp/google_search_cache"
SEARCH_QUERY=""
MAX_RESULTS=10
OUTPUT_FILE=""
PROCESS_WITH_LLM_FLAG="true" # Default to true, meaning LLM processing is on

while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -q|--query)
            SEARCH_QUERY="$2"
            shift 2
            ;;
        -n|--num-results)
            MAX_RESULTS="$2"
            if ((MAX_RESULTS > 100)); then
                MAX_RESULTS=100
                echo "Warning: Maximum results capped at 100." >&2
            fi
            shift 2
            ;;
        -o|--output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        -r|--raw-content)
            PROCESS_WITH_LLM_FLAG="false"
            shift
            ;;
        *)
            error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

if [[ -z "$SEARCH_QUERY" ]]; then
    error "Search query is required."
    usage
    exit 1
fi

process_url() {
    local url="$1"
    local original_search_text="$2" # Renamed from search_query for clarity
    local cache_dir="$3"
    local process_llm_str_flag="$4"
    local page_text
    local page_content
    local final_output

    local should_process_llm=false
    if [[ "$process_llm_str_flag" == "true" ]]; then
        should_process_llm=true
    fi

    local mode_suffix="raw"
    if [[ "$should_process_llm" == "true" ]]; then
        mode_suffix="llm"
    fi

    local cache_key=$(echo -n "$url:$original_search_text:$mode_suffix" | md5sum | cut -d' ' -f1)
    local cache_file="$cache_dir/$cache_key"
    mkdir -p "$cache_dir"

    page_content=$(curl -sL --max-time 3 --retry 3 --retry-delay 1 "$url")
    if [[ -z "$page_content" ]]; then
        error "Failed to retrieve content from $url"
        return
    fi
    
    if [[ "$url" == *.pdf ]]; then
        page_text=$(pdftotext - - <<< "$page_content" 2>/dev/null || echo "Failed to convert PDF")
    else
        page_text=$(echo "$page_content" | html2text -b 0 --ignore-images --ignore-emphasis --ignore-links --single-line-break 2>/dev/null || echo "Failed to convert HTML")
    fi
    if [[ -z "$page_text" || "$page_text" == "Failed to convert PDF" || "$page_text" == "Failed to convert HTML" ]]; then
        error "Failed to convert content to text for $url"
        return
    elif echo $page_text | grep -q 'Verifying you are human'; then
        fetch_archived_content "$url"
    fi

    if [[ "$should_process_llm" == "true" ]]; then
        local llm_processed_content
        llm_processed_content=$(process_content_with_llm "$page_text" "$original_search_text" "$url")
        final_output="URL: $url
Relevant Quotes:
"
        final_output+="$llm_processed_content"
        final_output+="
--------------------------------------------------
"
    else
        # Raw content requested
        final_output="$page_text"
    fi

    echo -e "$final_output" > "$cache_file"
    echo -e "$final_output"
}

export -f process_url
export -f process_content_with_llm
export -f error
export -f estimate_token_count
export -f select_llm_model
export CACHE_DIR
export SEARCH_QUERY

SEARCH_TEXT="$SEARCH_QUERY" # Save the original query for prompts
SEARCH_QUERY_FOR_API=$(echo "$SEARCH_QUERY" | sed 's/ /+/g') # Use a different var for API call
SEARCH_JSON=$(google_search -q "$SEARCH_QUERY" -n "$MAX_RESULTS")
echo "Google search results for: $SEARCH_QUERY"
if [[ -z "$SEARCH_JSON" ]]; then
    error "Received empty response from google-search.sh"
    exit 1
fi

URLS=$(echo "$SEARCH_JSON" | jq -r '.[] | .link')

if [[ -z "$URLS" ]]; then
    error "No URLs found in the search results"
    exit 1
fi

RESULTS=$(echo "$URLS" | parallel -j $(nproc) process_url {} "$SEARCH_TEXT" "$CACHE_DIR" "$PROCESS_WITH_LLM_FLAG")

output_result() {
    if [[ -n "$OUTPUT_FILE" ]]; then
        echo "$1" >> "$OUTPUT_FILE"
    else
        echo "$1"
    fi
}

output_result "Search Results for: $SEARCH_TEXT"
output_result "=========================="
output_result "$RESULTS"

if [[ "$PROCESS_WITH_LLM_FLAG" == "true" ]]; then
    # Summary makes sense only if LLM processing was done
    # SUMMARY_TOKEN_COUNT=$(estimate_token_count "$RESULTS")
    # # SUMMARY_MODEL=$(select_llm_model "$SUMMARY_TOKEN_COUNT")
    # if ((SUMMARY_TOKEN_COUNT < 8000)); then
    #     SUMMARY=$(LLM_LOAD_PLUGINS='llm-cerebras' echo "$RESULTS" | llm -m cerebras-deepseek-r1-distill-llama-70b --system "Summarize the key points from the search results related to '$SEARCH_TEXT'. ")
    # else
    #     SUMMARY=$(LLM_LOAD_PLUGINS='llm-gemini' echo "$RESULTS" | llm -m gemini-2 --system "Summarize the key points from the search results related to '$SEARCH_TEXT'. Focus on the most relevant and highest-scored quotes. Provide a concise overview of the main findings")
    # fi
    # output_result "Summary:"
    # output_result "========"
    # output_result "$SUMMARY"
    : # Placeholder for summary logic, which is currently commented out
fi

exit 0
