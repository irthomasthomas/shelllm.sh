#!/bin/bash


structured_chain_of_thought() {
  # Breaks down complex problems using structured reasoning steps.
  # Usage: structured_chain_of_thought <problem description> [--think=none|minimal|moderate|detailed|comprehensive] [-m MODEL_NAME] [--steps=<steps>]
  #        cat problem.txt | structured_chain_of_thought [--think=none|minimal|moderate|detailed|comprehensive] [-m MODEL_NAME] [--steps=<steps>]
  # Options:
  #   --think=LEVEL       Control reasoning depth (none, minimal, moderate, detailed, comprehensive)
  #   -m MODEL_NAME          Specify which LLM model to use
  #   --steps=STEPS          Define custom reasoning steps (comma-separated)
  #   --raw                  Return the raw LLM response
  
  local system_prompt="You are a reasoning assistant that helps break down complex problems through structured thinking. Your COT reasoning trace is then passed to another LLM to generate the actual answer. Follow these steps meticulously:

1.  **Problem Understanding**:
    *   Restate the problem in your own words to confirm understanding.
    *   *Example*: \"The user is asking to [specific task], which requires [key elements].\"
    *   Validate alignment with the user’s intent before proceeding.
2.  **Approach Planning**:
    *   Outline a clear, step-by-step strategy using bullet points.
    *   *Example*: \"1. Gather relevant data. 2. Apply [method]. 3. Validate results.\"
    *   Justify why this approach is suitable.
3.  **Step-by-Step Reasoning**:
    *   Execute your plan with numbered steps, showing calculations/logic.
    *   *Example*: \"Step 1: [Action]. Step 2: [Calculation].\"
    *   Highlight assumptions and potential pitfalls.

**Formatting Rules**:

*   Use XML tags exactly as specified:
    <problem_understanding>...</problem_understanding>
    <approach>...</approach>
    <reasoning>...</reasoning>
*   Avoid markdown; keep content plain text within tags.
*   Adjust detail level based on problem complexity (e.g., minimal for simple tasks, detailed for ambiguous problems).

**Important Notes**: DO NOT write a final answer or conclusion. Your task is to provide a structured breakdown of the problem and reasoning process. The final answer will be generated separately.
"

  local args=()
  local raw=false

  # Check if input is being piped
  if [ ! -t 0 ]; then
    local piped_content
    piped_content=$(cat)
  fi
  
  # Process arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --task)
        if [[ -n "$2" && ! "$2" =~ ^- ]]; then
          task="$2"
          system_prompt+="\n<task>\n$task\n</task>\n"
          shift
        else
          echo "Error: --task requires a task description" >&2
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

  response=$(echo -e "$piped_content" | llm -s $system_prompt --no-stream "${args[@]}")
  
  # Return raw response if requested
  if [ "$raw" = true ]; then
    echo "$response"
    return
  fi
  
  # Extract sections
  problem_understanding="$(echo "$response" | awk 'BEGIN{RS="<problem_understanding>"} NR==2' | awk 'BEGIN{RS="</problem_understanding>"} NR==1')"
  approach="$(echo "$response" | awk 'BEGIN{RS="<approach>"} NR==2' | awk 'BEGIN{RS="</approach>"} NR==1')"
  reasoning="$(echo "$response" | awk 'BEGIN{RS="<reasoning>"} NR==2' | awk 'BEGIN{RS="</reasoning>"} NR==1')"
  
  
  # Display formatted output
  echo -e "\033[1;36m🔍 PROBLEM UNDERSTANDING:\033[0m\n$problem_understanding\n"
  echo -e "\033[1;33m🧩 APPROACH:\033[0m\n$approach\n"
  echo -e "\033[1;32m⚙️ REASONING:\033[0m\n$reasoning\n"
}
