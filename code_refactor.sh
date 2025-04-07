code_refactor() {
  # Analyzes and refactors code with expert recommendations
  # Usage: code_refactor [file_path] [--lang=LANGUAGE] [--context=CONTEXT] [--thinking=none|minimal|moderate|detailed|comprehensive] [-m MODEL_NAME] [--raw]
  #        cat code.py | code_refactor [--lang=python] [--context=CONTEXT] [--thinking=none|minimal|moderate|detailed|comprehensive] [-m MODEL_NAME] [--raw]
  # Options:
  #   --lang=LANGUAGE        Specify the programming language (e.g., python, javascript, java)
  #   --context=CONTEXT      Provide specific refactoring goals or context
  #   --thinking=LEVEL       Control reasoning depth (none, minimal, moderate, detailed, comprehensive)
  #   -m MODEL_NAME          Specify which LLM model to use
  #   --raw                  Return the raw LLM response

  local system_prompt=$(cat <<'EOF'
# LLM Prompt: Code Refactoring and Expert Analysis

**Role:** Act as an expert Senior Software Engineer specializing in code quality, maintainability, and effective refactoring techniques. Adopt this persona throughout your response.

**Objective:** Analyze the provided code snippet, refactor it for improved clarity, conciseness, and maintainability according to modern best practices. Provide actionable expert advice related to the changes and general code health relevant to the provided snippet. Critically, *explain your reasoning behind each refactoring decision.* The output MUST be in JSON format, strictly following the schema outlined below.

**--- LLM INSTRUCTIONS ---**

Based on the user inputs, perform the following:

1.  **Analyze the Code:**
    *   Carefully examine the provided code snippet. Identify its core purpose and structure.
    *   Detect potential code smells (e.g., duplication, long methods/functions, tight coupling, unclear naming, excessive complexity, data clumps, feature envy, switch statements, speculative generality) and specific areas for improvement.
    *   **Handle Edge Cases:** If the code is incomplete, contains syntax errors, or the language isn't specified, note these issues *within the JSON output* and explain how they impact your ability to analyze and refactor fully. Proceed as best as possible given the limitations.

2.  **Refactor the Code:**
    *   Rewrite the code applying the following principles **in order of priority:**
        1.  **Correctness:** Preserve the original functionality. Ensure the refactored code produces the same results for the same inputs. Provide unit tests in the `tests` field if possible (or outline how tests could be written).
        2.  **Readability & Maintainability:** Enhance clarity, understandability, and ease of future modification. Use clear, descriptive names. Apply consistent formatting (per language conventions or specified style guide). Refer to relevant style guides (e.g., PEP 8 for Python, Airbnb JavaScript Style Guide) for best practices.
        3.  **Simplicity & Conciseness (KISS/DRY):** Simplify logic and remove redundancy, *provided it does not harm readability*.
        4.  **Performance:** Optimize only if explicitly requested in the context or if significant, obvious inefficiencies exist *without sacrificing clarity*. If performance optimization conflicts with readability, prioritize readability unless explicitly instructed otherwise in the context/goals.
    *   Apply relevant design principles (e.g., Single Responsibility Principle) by breaking down overly complex components if applicable.
    *   Make the code idiomatic for the specified language.
    *   **Explainability:** Before providing the refactored code, briefly explain the overall refactoring strategy you are employing.

3.  **Present Refactored Code:** Include the complete refactored code snippet in the `refactored_code` field of the JSON output.

4.  **Provide Expert Explanation & Tips:** Provide a "Summary of Changes & Reasoning", "Actionable Recommendations," and optional "Tests" in the appropriate fields of the JSON Output.

    *   **Summary of Changes & Reasoning:**
        *   Explain the key refactoring steps taken (e.g., "Extracted calculation into `calculate_value` function...", "Renamed variable `x` to `numberOfUsers`...").
        *   Crucially, provide the *reasoning* behind each significant change, linking it to the principles above (e.g., "...to improve modularity and testability (SRP)", "...for better clarity and maintainability").
        *   Mention any trade-offs considered (e.g., slight performance decrease for much better readability). Explain *why* you made the trade-off. Consider alternative refactoring approaches you *didn't* choose and explain why.

    *   **Actionable Recommendations:**
        *   Offer 3-5 specific, actionable tips **directly inspired by the refactoring process or highly relevant to the analyzed code/domain**. Avoid purely generic advice.
        *   Focus on topics like: Maintainability strategies applicable *here*, Readability techniques relevant *to this code*, Avoiding pitfalls *observed or related* (explain concepts like magic numbers briefly if relevant), Testing strategies for the *refactored components*, Potential *further improvements* specific to this code. These recommendations should be specific to the language and project type.

    *   **Tests (Optional):** If feasible, provide example unit tests for the refactored code in the `tests` field. If not feasible, outline how such tests could be constructed.

**Output Format:** The LLM's response *must* be a single JSON object conforming to the following schema. *Failure to adhere to this schema will be considered a failure to follow instructions.*

```json
{
  "refactored_code": "[Complete refactored code snippet, including language identifier]",
  "summary": {
    "changes": [
      {"description": "[Description of the change]", "reasoning": "[Reasoning behind the change]"},
      {"description": "[Description of the change]", "reasoning": "[Reasoning behind the change]"}
    ]
  },
  "recommendations": [
    "[Actionable recommendation 1]",
    "[Actionable recommendation 2]",
    "[Actionable recommendation 3]"
  ],
  "tests": "[Optional: Example unit tests or test construction outline]"
}
```
EOF
  )

  local thinking_level="none"
  local args=()
  local model=""
  local raw=false
  local language=""
  local context=""
  local user_input=""
  
  # Check if input is being piped
  if [ ! -t 0 ]; then
    user_input=$(cat)
  elif [ -f "$1" ]; then
    # If first argument is a file, read its content
    user_input=$(cat "$1")
    shift
  fi

  # Process arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --lang=*)
        language=${1#*=}
        ;;
      --context=*)
        context=${1#*=}
        ;;
      --thinking=*)
        thinking_level=${1#*=}
        ;;
      -m)
        if [[ -n "$2" && ! "$2" =~ ^- ]]; then
          model="$2"
          args+=("-m" "$model")
          shift
        else
          echo "Error: -m requires a model name" >&2
          return 1
        fi
        ;;
      --raw)
        raw=true
        ;;
      *)
        args+=("$1")
        ;;
    esac
    shift
  done

  # Prepare input format
  local formatted_input="**Target Language:** \`$language\`
**Code Snippet:**
\`\`\`$language
$user_input
\`\`\`
**Optional Context/Goals:** \`$context\`"

  if [ "$thinking_level" != "none" ]; then
    reasoning=$(echo -e "$formatted_input" | structured_chain_of_thought --raw "${args[@]}")
    if [[ -n "$reasoning" ]]; then
      system_prompt+="<thinking>$reasoning</thinking>"
    else
      echo "Error: No reasoning provided" >&2
      return 1
    fi
  fi

  # Call LLM
  system_prompt="\n<SYSTEM>\n$system_prompt\n</SYSTEM>\n"
  response=$(echo -e "$formatted_input\n$system_prompt" | llm --no-stream "${args[@]}")

  # Return raw response if requested
  if [ "$raw" = true ]; then
    echo "$response"
    return
  fi

  # Try to extract JSON from the response
  # First try to extract JSON between triple backticks if present
  local json_response=$(echo "$response" | awk 'BEGIN{RS="```json"} NR==2' | awk 'BEGIN{RS="```"} NR==1')
  
  # If that fails, try to extract the whole response as JSON
  if [[ -z "$json_response" ]]; then
    json_response="$response"
  fi

  # Parse JSON response using a tool like jq if available, otherwise print formatted response
  if command -v jq >/dev/null 2>&1; then
    # Check if the response is valid JSON
    if echo "$json_response" | jq . >/dev/null 2>&1; then
      # Extract and format refactored code
      refactored_code=$(echo "$json_response" | jq -r '.refactored_code')
      
      # Extract and format summary of changes
      echo -e "\033[1;36m🔧 REFACTORED CODE:\033[0m\n$refactored_code\n"
      
      echo -e "\033[1;33m📋 SUMMARY OF CHANGES & REASONING:\033[0m"
      changes=$(echo "$json_response" | jq -r '.summary.changes | .[] | "\n• \(.description)\n  Reasoning: \(.reasoning)"')
      echo -e "$changes\n"
      
      echo -e "\033[1;32m💡 ACTIONABLE RECOMMENDATIONS:\033[0m"
      recommendations=$(echo "$json_response" | jq -r '.recommendations | .[] | "• \(.)"')
      echo -e "$recommendations\n"
      
      # Check if tests are provided
      tests=$(echo "$json_response" | jq -r '.tests')
      if [[ "$tests" != "null" && -n "$tests" ]]; then
        echo -e "\033[1;35m🧪 TESTS:\033[0m\n$tests"
      fi
    else
      # If not valid JSON, print the raw response
      echo "$response"
    fi
  else
    # If jq is not available, print a simpler formatted output
    echo "$response"
    echo -e "\n\033[1;33mNote: Install jq for better formatted output.\033[0m"
  fi
}

# Alias for ease of use
alias refactor=code_refactor
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    code_refactor "$@"
fi
