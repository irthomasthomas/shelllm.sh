google_search() {
    usage() {
        echo "Usage: $0 -q \"search query\" [-n number_of_results]"
        echo "  -q, --query     Search query (required)"
        echo "  -n, --num       Number of results to return (default: 10, max: 100)"
        echo "  -h, --help      Display this help message"
    }

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        key="$1"
        case $key in
            -q|--query)
                QUERY="$2"
                shift 2
                ;;
            -n|--num)
                NUM="$2"
                shift 2
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done

    # Check if query is provided
    if [ -z "$QUERY" ]; then
        echo "Error: Search query is required."
        usage
        exit 1
    fi

    # Set default number of results if not provided
    NUM=${NUM:-30}
    if [ "$NUM" -gt 100 ]; then
        NUM=100
    fi

    # Google Custom Search API key and Search Engine ID
    # These should be set as environment variables
    API_KEY=${GOOGLE_SEARCH_KEY}
    SEARCH_ENGINE_ID=${GOOGLE_SEARCH_ID}

    if [ -z "$API_KEY" ] || [ -z "$SEARCH_ENGINE_ID" ]; then
        echo "Error: GOOGLE_SEARCH_KEY and GOOGLE_SEARCH_ID environment variables must be set."
        echo "Please set up a Google Custom Search Engine and obtain an API key."
        echo "Then set the following environment variables:"
        echo "export GOOGLE_SEARCH_KEY='your_api_key_here'"
        echo "export GOOGLE_SEARCH_ID='your_search_engine_id_here'"
        exit 1
    fi

    # URL encode the query
    ENCODED_QUERY=$(printf '%s' "$QUERY" | jq -sRr @uri)

    # Function to perform search
    perform_search() {
        local start=$1
        local num=$2
        SEARCH_URL="https://www.googleapis.com/customsearch/v1?key=${API_KEY}&cx=${SEARCH_ENGINE_ID}&q=${ENCODED_QUERY}&num=${num}&start=${start}"

        RESPONSE=$(curl -s "$SEARCH_URL")
        CURL_EXIT_CODE=$?

        if [ $CURL_EXIT_CODE -ne 0 ]; then
            echo "Error: curl command failed with exit code $CURL_EXIT_CODE" >&2
            return 1
        fi

        if [ -z "$RESPONSE" ]; then
            echo "Error: Empty response received from the API" >&2
            return 1
        fi

        # Check if the API request was successful
        if echo "$RESPONSE" | jq -e '.error' > /dev/null; then
            echo "Error: API request failed." >&2
            echo "Error code: $(echo "$RESPONSE" | jq -r '.error.code')" >&2
            echo "Error message: $(echo "$RESPONSE" | jq -r '.error.message')" >&2
            echo "Error details:" >&2
            echo "$RESPONSE" | jq '.error.errors' >&2
            return 1
        fi

        echo "$RESPONSE" | jq '.items'
    }

    # Function to process and display search results
    process_search_results() {
        local start=$1
        local num=$2
        local results=()
        local total_results=0
        
        while [ $start -le $num ]; do
            # Get batch of results
            local batch=$(perform_search $start 10)
            if [ $? -ne 0 ]; then
                echo "Error retrieving search results" >&2
                return 1
            fi
            
            # Append results
            results+=("$batch")
            
            # Update counters
            local batch_count=$(echo "$batch" | jq '. | length')
            total_results=$((total_results + batch_count))
            start=$((start + 10))
            
            # Break if we have enough results
            if [ $total_results -ge $NUM ]; then
                break
            fi
        done
        
        # Format and output results
        for result in "${results[@]}"; do
            echo "$result" | jq -r '.[] | "Title: \(.title)\nLink: \(.link)\nSnippet: \(.snippet)\n"'
        done
    }

    # Initialize variables for pagination
    START=1
    RESULTS="[]"

    # Fetch results in batches
    while [ $START -le $NUM ]; do
        BATCH_SIZE=$((NUM - START + 1))
        if [ $BATCH_SIZE -gt 10 ]; then
            BATCH_SIZE=10
        fi

        BATCH_RESULTS=$(perform_search $START $BATCH_SIZE)
        if [ $? -ne 0 ]; then
            exit 1
        fi

        RESULTS=$(echo "$RESULTS" "$BATCH_RESULTS" | jq -s 'add')
        START=$((START + BATCH_SIZE))
    done

    # Output the aggregated results in JSON format
    echo "$RESULTS" | jq '.'
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # If the script is run directly, call the google_search function
    google_search "$@"
fi