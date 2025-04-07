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
DEFAULT_COUNT=10
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
            echo "Bing Results for: \"$QUERY\""
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
