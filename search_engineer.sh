search_engineer () {
  local system_prompt="You are a search query optimization expert. Your task is to generate multiple effective search queries based on a user's question or context. Focus on creating concise, specific queries that cover the topic from different angles. The goal is to provide the user with a diverse set of search terms that will lead to relevant and informative results.

An effective search query should:
- Use precise keywords and concepts related to the topic
- Employ appropriate search operators (quotes, site:, OR, -, etc.) when beneficial
- Be specific enough to filter out irrelevant results
- Consider synonyms and alternative phrasings
- Break complex questions into simpler searchable components

Here's an example:

User Question: \"What are the main causes of the French Revolution?\"

<think>
A good starting point would be to identify the major factors often associated with the French Revolution, such as economic hardship, social inequality, and political instability. Then we can create queries that explore each of these factors in relation to the Revolution. A good approach would be to first look for overview level explanations, and then to refine the query based on the information found to more specific areas.
</think>
A search query which directly answers the root question
A search query focusing on a specific aspect of the question
An alternative search query using different keywords
A broader search query to capture general information
A search query looking for counter-arguments or opposing perspectives

Output:
causes of french revolution economic inequality
social causes of the french revolution
political factors leading to french revolution
role of enlightenment in french revolution
french revolution causes summary

For factual questions: Focus on precise terminology and authoritative sources.
For exploratory topics: Use broader terms and consider multiple perspectives.
For technical problems: Include error messages, platform-specific terms, and version numbers.
For ambiguous requests: Provide queries covering different possible interpretations.

Examples of effective queries:
- \"climate change mitigation strategies site:.edu OR site:.gov\"
- \"javascript \"uncaught TypeError\" fix -jquery\"
- \"best hiking trails near Portland Oregon difficulty:moderate\"

Format your response as follows:

<think>
[Step-by-step reasoning for complex queries. Use this section to brainstorm and refine search queries before making the final selection. The length of this section should be proportional to the complexity of the question and the specified thinking level.]
</think>

Then provide one search query per line, with no additional formatting, numbering or explanation.
"

  local thinking_level="none"
  local args=()
  local model=""
  local count=5
  local auto_reasoning="true" # Set auto-reasoning to true by default

  # Associative array for thinking level descriptions
  declare -A thinking_descriptions
  thinking_descriptions[none]=""
  thinking_descriptions[minimal]="Three or four sentences. Briefly identify key concepts and potential search terms related to the user's question. Focus on the most obvious and direct approaches."
  thinking_descriptions[moderate]="Five to ten sentences. Analyze the main search requirements, consider different angles and perspectives, and identify potential keywords. Explain why you are choosing specific search terms."
  thinking_descriptions[detailed]="Ten to fifteen sentences. Thoroughly analyze the search parameters and devise a search strategy. Explore various approaches, consider the relationships between different concepts, and justify your choices in detail."
  thinking_descriptions[comprehensive]="Twenty to thirty sentence. In-depth analysis of the user's question, exploring multiple approaches, considering trade-offs, and evaluating the potential effectiveness of different search queries. Consider background context, implicit assumptions, and potential biases."

  # Function to select a reasoning level automatically
  auto_select_reasoning() {
    system_prompt+=" <auto_reasoning>Since no reasoning level was selected, please pick one based on the complexity of the prompt provided. The reasoning levels are: none, minimal, moderate, detailed, and comprehensive. You should pick the one that will provide the best results</auto_reasoning>"
  }

  if [ ! -t 0 ]
  then
    local piped_content
    piped_content=$(cat)
    args+=("$piped_content")
  fi

  local llm_args=()
  local input_parts=()

  while [[ $# -gt 0 ]]
  do
    case "$1" in
      (--thinking=*) thinking_level=${1#*=}
        if [[ -v "thinking_descriptions[$thinking_level]" ]]; then
          if [[ "$thinking_level" != "none" ]]; then
            system_prompt+="<think>${thinking_descriptions[$thinking_level]}</think>"
          fi
          auto_reasoning="false" # Disable auto reasoning when thinking level is explicitly set
        else
          echo "Error: Invalid thinking level. Use: none, minimal, moderate, detailed, or comprehensive" >&2
          return 1
        fi ;;
      (--auto-reasoning)
        auto_reasoning="true" ;;
      (-m)
        if [[ -n "$2" && ! "$2" =~ ^- ]]; then
          llm_args+=("$1" "$2")
          shift
        else
          echo "Error: -m requires a model name" >&2
          return 1
        fi ;;
      (--raw)
        raw="true" ;;
      (--count=*) count=${1#*=}
        system_prompt+=" <count>Generate approximately $count search queries.</count>" ;;
      (*)
        if [[ -n "$piped_content" ]]; then
          llm_args+=("$1")
        else
          input_parts+=("$1")
        fi ;;
    esac
    shift
  done

  if [[ -z "$piped_content" ]]; then
    piped_content="${input_parts[*]}"
  fi

  # If auto reasoning is selected and no explicit reasoning level is provided, ask the LLM to pick one
  if [[ "$auto_reasoning" == "true" ]] && [[ "$thinking_level" == "none" ]]; then
    auto_select_reasoning
  fi

  response=$(llm -s "$system_prompt" "${llm_args[@]}" --no-stream)
  # Return raw response if requested
  if [ "$raw" = true ]; then
    echo "$response"
    return
  fi
  
  # Extract thinking process if available
  thinking="$(echo "$response" | awk 'BEGIN{RS="<think>"} NR==2' | awk 'BEGIN{RS="</think>"} NR==1')"

  # Parse the response to extract queries (one per line, after any thinking section)
  queries="$(echo "$response" | sed -n '/^<think>/,/<\/think>/d; /./p' | grep -v "^$")"

  if [ -z "$queries" ]; then
    # Fallback: If no queries found after removing thinking section, try to extract everything
    queries="$(echo "$response" | grep -v "^$" | grep -v "<think>" | grep -v "</think>")"
  fi

  if [ -n "$thinking" ] && [ "$thinking_level" != "none" ]; then
      echo "Thinking Process:" >&2
      echo "$thinking" >&2
      echo "" >&2
  fi

  # Output numbered queries
  local query_count=1
  while IFS= read -r line; do
    if [[ -n "$line" ]]; then
      echo "$query_count. $line"
      ((query_count++))
    fi
  done <<< "$queries"
}