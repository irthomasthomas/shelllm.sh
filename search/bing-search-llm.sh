#!/bin/bash

# ====================================================
# Optimized Bing Search to LLM Processing Script
# ====================================================
#
# Description:
#   A companion script to perform a Bing search, scrape each result page,
#   convert the HTML to text, and process the text with an LLM to extract
#   relevant quotes based on the original search query.
#

# Requirements:
#   - bash
#   - curl
#   - jq
#   - sed
#   - tr
#   - md5sum
#   - parallel
#   - llm-cerebras
#   - bing-search.sh (the provided script)
#   - shot-scraper (for handling JavaScript-rendered pages)
#
# Usage:
#   ./bing-search-llm.sh -q "search query" [bing-search.sh options]
#
# Examples:
#   ./bing-search-llm.sh -q "low latency LLM provider" -f json -n 5
#
# ====================================================



# Function to display usage instructions
usage() {
    echo "Usage: $0 -q \"search query\" [bing-search.sh options]"
    echo "Example: $0 -q \"low latency LLM provider\" -f json -n 5"
}

bing_search () {
    #!/bin/bash

    # ====================================================
    # Bing Custom Search CLI
    # ====================================================
    #
    # Description:
    #   A comprehensive Bash CLI to perform searches using the
    #   Bing Custom Search API.
    #
    # Requirements:
    #   - curl
    #   - jq
    #
    # Usage:
    #   ./bing_search.sh -q "search query" [options]
    #
    # Options:
    #   -q, --query            : (Required) The search query.
    #   -c, --config-id        : (Optional) Azure Custom Config ID.
    #                            Defaults to the environment variable KAGI_AZURE_SEARCH_CONFIG.
    #   -k, --api-key          : (Optional) Azure Subscription Key.
    #                            Defaults to the environment variable KAGI_AZURE_SEARCH_KEY.
    #   -r, --region           : (Optional) Azure region (e.g., en-us).
    #                            Defaults to the environment variable AZURE_REGION or "en-us".
    #   -n, --count            : (Optional) Number of search results to return.
    #                            Defaults to 10.
    #   -o, --offset           : (Optional) The result offset.
    #                            Defaults to 0.
    #   -f, --format           : (Optional) Output format (`json`, `text`, or `raw`).
    #                            Defaults to `json`.
    #   -h, --help             : Show this help message and exit.
    #
    # Examples:
    #   ./bing_search.sh -q "OpenAI ChatGPT"
    #   ./bing_search.sh --query "Bash scripting" --format text
    #
    # ====================================================

    # Default values
    DEFAULT_REGION="en-us"
    DEFAULT_COUNT=20
    DEFAULT_OFFSET=0
    DEFAULT_FORMAT="json"
    CONFIG_ID="$BING_CUSTOM_CODE_SEARCH_CONF"

    API_KEY="$BING_CUSTOM_SEARCH_KEY"
    AZURE_REGION="${AZURE_REGION:-$DEFAULT_REGION}"

    # Function to display usage instructions
    usage() {
        grep '^#' "$0" | sed 's/^#//'
    }

    # Function to check if a command exists
    command_exists() {
        command -v "$1" >/dev/null 2>&1
    }

    # Check for required dependencies
    if ! command_exists curl; then
        echo "Error: 'curl' is not installed. Please install it and try again." >&2
        exit 1
    fi

    if ! command_exists jq; then
        echo "Error: 'jq' is not installed. Please install it and try again." >&2
        exit 1
    fi

    # Parse command-line arguments using getopt
    PARSED_ARGS=$(getopt -o q:c:k:r:n:o:f:h --long query:,config-id:,api-key:,region:,count:,offset:,format:,help \
        -n "$0" -- "$@")
    if [[ $? -ne 0 ]]; then
        usage
        exit 1
    fi

    eval set -- "$PARSED_ARGS"

    # Initialize variables with defaults or environment variables
    QUERY=""
    COUNT="$DEFAULT_COUNT"
    OFFSET="$DEFAULT_OFFSET"
    OUTPUT_FORMAT="$DEFAULT_FORMAT"
    # Extract options and their arguments
    while true; do
        case "$1" in
            -q|--query)
                QUERY="$2"
                shift 2
                ;;
            -c|--config-id)
                CONFIG_ID="$2"
                shift 2
                ;;
            -k|--api-key)
                API_KEY="$2"
                shift 2
                ;;
            -r|--region)
                AZURE_REGION="$2"
                shift 2
                ;;
            -n|--count)
                COUNT="$2"
                shift 2
                ;;
            -o|--offset)
                OFFSET="$2"
                shift 2
                ;;
            -f|--format)
                OUTPUT_FORMAT="$2"
                shift 2
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            --)
                shift
                break
                ;;
            *)
                echo "Invalid option: $1" >&2
                usage
                exit 1
                ;;
        esac
    done

    # Validate required parameters
    if [[ -z "$QUERY" ]]; then
        echo "Error: Search query is required." >&2
        usage
        exit 1
    fi

    if [[ -z "$CONFIG_ID" ]]; then
        echo "Error: Config ID is not set. Provide it via --config-id or set the KAGI_AZURE_SEARCH_CONFIG environment variable." >&2
        exit 1
    fi

    if [[ -z "$API_KEY" ]]; then # API_KEY is not set
        echo "Error: API Key is not set. Provide it via --api-key or set the KAGI_AZURE_SEARCH_KEY environment variable." >&2
        exit 1
    fi

    # URL encode the search query
    query_encoded=$(jq -rn --arg q "$QUERY" '$q|@uri')
    # Construct the API URL with query parameters
    api_url="https://api.bing.microsoft.com/v7.0/custom/search"
    full_url="${api_url}?q=${query_encoded}&customconfig=${CONFIG_ID}&count=${COUNT}&offset=${OFFSET}"

    # Make the API request and capture response and HTTP status
    response=$(curl -s -w "\n%{http_code}" -X GET "$full_url" \
        -H "Ocp-Apim-Subscription-Key: $API_KEY" \
        -H "Ocp-Apim-Subscription-Region: $AZURE_REGION")

    # Split response body and HTTP status
    http_body=$(echo "$response" | sed '$d')
    http_status=$(echo "$response" | tail -n1)

    # Handle the response based on HTTP status
    if [[ "$http_status" -ge 200 && "$http_status" -lt 300 ]]; then
        case "$OUTPUT_FORMAT" in
            json)
                echo "$http_body" | jq
                ;;
            text)
                echo "Search Results for: \"$QUERY\""
                echo "----------------------------------------"
                echo "$http_body" | jq -r '.webPages.value[] | "\(.name)\n\(.url)\n\(.snippet)\n"'
                ;;
            raw)
                echo "$http_body"
                ;;
            *)
                echo "Unsupported output format: $OUTPUT_FORMAT" >&2
                exit 1
                ;;
        esac
    else
        echo "Error: Received HTTP status $http_status" >&2
        # Attempt to parse and display error message
        echo "$http_body" | jq '.' 2>/dev/null || echo "$http_body"
        exit 1
    fi

    exit 0

}

# Check for dependencies
dependencies=(curl jq sed tr md5sum parallel html2text shot-scraper /home/thomas/Projects/claude.sh/utils/llm-cerebras.sh)

# Set default cache directory
CACHE_DIR="/tmp/bing_search_cache"

# Parse arguments: extract -q and pass others to bing-search.sh
# Since we need the search query, and to pass others to bing-search.sh as is

# Initialize variables
SEARCH_QUERY=""
MAX_RESULTS=10
OUTPUT_FILE=""
BING_ARGS=()

# Parse options
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -q|--query)
            if [[ -n "$2" && ! "$2" =~ ^- ]]; then
            SEARCH_QUERY="$2"
                BING_ARGS+=("$1" "$2")
            shift 2
            else
                echo "Error: Missing value for $1 option." >&2
                usage
                exit 1
            fi
            ;;
        -c|--config-id|-k|--api-key|-r|--region|-n|--count|-o|--offset|-f|--format|-h|--help)
            # Check if the option expects a value
            case $key in
                -h|--help)
                    usage
                    exit 0
                    ;;
                *)
                    if [[ -n "$2" && ! "$2" =~ ^- ]]; then
                        BING_ARGS+=("$1" "$2")
            shift 2
                    else
                        echo "Error: Missing value for $1 option." >&2
                        usage
                        exit 1
                    fi
                    ;;
            esac
            ;;
        *)
            echo "Unknown option: $1" >&2
            usage
            exit 1
            ;;
    esac
done

if [[ -z "$SEARCH_QUERY" ]]; then
    echo "Error: Search query is required." >&2
    exit 1
fi

# Function to process a single URL
process_url() {
    # print to stderr to avoid mixing with the output
    echo "bing: Processing URL: $1" >&2

    local url="$1"
    local cache_key
    cache_key=$(echo -n "${url}${SEARCH_QUERY}" | md5sum | cut -d' ' -f1)
    local cache_file="${CACHE_DIR}/${cache_key}"
    mkdir -p "$CACHE_DIR"
    # Check if cached result exists and is less than 1 hour old
    if [[ -f "$cache_file" && $(($(date +%s) - $(stat -c %Y "$cache_file"))) -lt 3600 ]]; then
        echo "bing: Using cached result for $url" >&2
        cat "$cache_file"
        return
    fi

    local page_content
    page_content=$(curl -sL --max-time 3 --retry 3 --retry-delay 1 "$url")
    echo "bing: Retrieved content from $url" >&2
    if [[ -z "$page_content" ]]; then
        echo "Failed to retrieve content from $url" >&2
        return
    fi

    local page_text
    if [[ "$url" == *.pdf ]]; then
        page_text=$(pdftotext - - <<< "$page_content" 2>/dev/null || echo "Failed to convert PDF")
    else
        page_text=$(echo "$page_content" | html2text -b 0 --ignore-images --ignore-emphasis --ignore-links --single-line-break 2>/dev/null || echo "Failed to convert HTML")
    fi
    echo "bing: Converted content to text" >&2
    if [[ -z "$page_text" || "$page_text" == "Failed to convert PDF" || "$page_text" == "Failed to convert HTML" || "$page_text" == *"Enable JavaScript and cookies to continue"* ]]; then
        page_content=$(shot-scraper html "$url")
        if [[ -z "$page_content" ]]; then
            echo "Failed to retrieve content from $url using shot-scraper" >&2
            return
        fi
        page_text=$(echo "$page_content" | html2text -b 0 --ignore-images --ignore-emphasis --ignore-links --single-line-break)
        if [[ -z "$page_text" ]]; then
            echo "Failed to convert rendered HTML to text for $url" >&2
            return
        fi
        if echo "$page_text" | grep -q 'Verifying you are human.'; then
            local archived_url="https://web.archive.org/web/0/$url"
            page_content=$(curl -sL "$archived_url")
            if [[ -z "$page_content" ]]; then
                echo "Failed to retrieve content from web.archive.org for $url" >&2
                return
            fi
            page_text=$(echo "$page_content" | html2text -b 0 --ignore-images --ignore-emphasis --ignore-links --single-line-break)
            if [[ -z "$page_text" ]]; then
                echo "Failed to convert archived HTML to text for $url" >&2
                return
            fi
        fi
    fi

    local word_count
    word_count=$(echo "$page_text" | wc -w)
    local estimated_tokens=$((word_count * 4 / 3))
    local llm_model
    if ((estimated_tokens < 8000)); then
        # todo: check for HTTP status code 429 and switch to a different model
        llm_model="cerebras-llama3.3-70b"
    else
        llm_model="gemini-2"
    fi
    llm_model="openrouter/google/gemini-2.0-flash-001"
    local output
    output="URL: $url
Relevant Quotes:
"
    output+=$(echo "$page_text" | llm -m "$llm_model" "<system>Summarize the page in two sentences. Then, extract ALL relevant passages and CODE related to the search query \"$SEARCH_QUERY\". Do NOT include ANY introduction or meta-commentary</system>")

    output+="
--------------------------------------------------
"

    echo -e "$output" > "$cache_file"
    echo -e "$output"
}

export -f process_url
export SEARCH_QUERY
export CACHE_DIR

# Run bing-search.sh with collected arguments and capture JSON
SEARCH_JSON=$(bing_search -q "$SEARCH_QUERY" -n "$MAX_RESULTS" "${BING_ARGS[@]}")
# Check if bing-search.sh command was successful
if [[ $? -ne 0 ]]; then
    echo "Error: bing-search.sh failed." >&2
    exit 1
fi
# Extract URLs from the JSON
URLS=$(echo "$SEARCH_JSON" | jq -r '.webPages.value[].url')

# Verify that URLs were extracted
if [[ -z "$URLS" ]]; then
    echo "No URLs found in the search results." >&2
    exit 1
fi

# Process URLs in parallel
RESULTS=$(echo "$URLS" | parallel -j $(nproc) process_url {})

# Generate and output the summary
word_count=$(echo "$RESULTS" | wc -w)
estimated_tokens=$((word_count * 4 / 3))
if ((estimated_tokens < 8000)); then
    llm_model="cerebras-llama3.3-70b"
else
    llm_model="openrouter/google/gemini-2.0-flash-001"
fi
SUMMARY_PROMPT="
Extract ALL KEY FACTS by quoting paragraphs from the search results related to:
<QUERY>
'$SEARCH_QUERY'
</QUERY>. 
Provide a concise overview of the main findings, INCLUDING the most relevant text. Try to answer the users query.
"
# SUMMARY="$(LLM_LOAD_PLUGINS='llm-cerebras, llm-gemini' echo "$RESULTS" | llm -m "$llm_model" --system "$SUMMARY_PROMPT" "$SUMMARY_PROMPT")"

if [[ -n "$OUTPUT_FILE" ]]; then
    echo "$RESULTS" >> "$OUTPUT_FILE"
    echo "Summary:" >> "$OUTPUT_FILE"
    echo "$SUMMARY" >> "$OUTPUT_FILE"
else
    echo -e "$RESULTS"
    echo "Summary:"
    echo "$SUMMARY"
fi

exit 0