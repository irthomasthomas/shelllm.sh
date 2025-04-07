# Record original directory and locate script dir
original_dir=$(pwd)

# Get the absolute path to the script
if [[ -n "${BASH_SOURCE[0]}" ]]; then
  # For bash
  script_path="${BASH_SOURCE[0]}"
elif [[ -n "${(%):-%x}" ]]; then
  # For zsh
  script_path="${(%):-%x}"
else
  # Fallback method
  script_path="$0"
fi

# Convert to absolute path if not already
if [[ ! "$script_path" = /* ]]; then
  script_path="$original_dir/$script_path"
fi

# Get the script directory
script_dir="$(cd "$(dirname "$script_path")" && pwd)"

# Change to script directory to source files
cd "$script_dir"

# Source the search_engineer.sh from the script directory
if [[ -f "$script_dir/search_engineer.sh" ]]; then
  source "$script_dir/search_engineer.sh"
else
  echo "Warning: Could not locate $script_dir/search_engineer.sh" >&2
fi

# Change back to original directory
cd "$original_dir"

task_plan_generator() {
  # Generates a task plan based on user input.
  # Usage: task_plan_generator <task description> [--thinking=none|minimal|moderate|detailed|comprehensive] [-m MODEL_NAME] [--note=NOTE|-n NOTE]
  #        cat file.txt | task_plan_generator [--thinking=none|minimal|moderate|detailed|comprehensive] [-m MODEL_NAME] [--note=NOTE|-n NOTE]
  
  # Define system prompt - use absolute path or locate relative to script location
  local system_prompt
  if [[ -f "$script_dir/prompts/task-plan-generator" ]]; then
    system_prompt="$(cat "$script_dir/prompts/task-plan-generator")"
  else
    echo "Error: Could not locate $script_dir/prompts/task-plan-generator" >&2
    return 1
  fi
  local thinking=false
  local args=()
  local model=""
  local user_input=""
  local additional_note=""
  local raw=false

  # Check if input is being piped
  if [ ! -t 0 ]; then
    user_input=$(cat)
  fi

  # Process arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --think)
        thinking=true
        ;;
      -n|--note)
        if [[ -n "$2" && ! "$2" =~ ^- ]]; then
          additional_note="$2"
          shift
        else
          echo "Error: -n/--note requires additional text" >&2
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


  # Combine piped content with additional instructions if both exist
  if [[ -n "$user_input" && -n "$additional_note" ]]; then
    user_input="$user_input\n\nAdditional instructions: $additional_note"
  elif [[ -z "$user_input" ]]; then
    # If no piped content, use additional note as the main input
    user_input="$additional_note"
  fi
  # Always use piping to avoid argument list too long errors
  if [ "$thinking" = true ]; then
    # Call structured_chain_of_thought if --think is specified
    reasoning=$(echo -e "$user_input" | structured_chain_of_thought --raw "${args[@]}")
    # Check if the response is empty
    if [[ -n "$reasoning" ]]; then
      # Append reasoning to the system prompt
      user_input+="<thinking>$reasoning</thinking>"
    else
      echo "Error: No reasoning provided" >&2
      return 1
    fi
  fi
  response=$(echo -e "$user_input" | llm -s "$system_prompt" --no-stream "${args[@]}")
  # Return raw response if requested
  if [ "$raw" = true ]; then
    echo "$response"
    return
  fi
  plan="$(echo "$response" | awk 'BEGIN{RS="<plan>"} NR==2' | awk 'BEGIN{RS="</plan>"} NR==1' | sed '/^ *#/d;/^$/d')"
  # check if plan is empty
  if [[ -z "$plan" ]]; then
    echo "$response"
    return
  fi
  if [ "$thinking_level" != "none" ]; then
    thinking="$(echo "$response" | awk 'BEGIN{RS="<think>"} NR==2' | awk 'BEGIN{RS="</think>"} NR==1')"
  fi
  echo "$plan"
}


shelp() {
  # Generate a shell command based on user input.
  # Usage: shelp <command description> [--thinking=none|minimal|moderate|detailed|comprehensive] [-m MODEL_NAME]
  #        cat file.txt | shelp [--thinking=none|minimal|moderate|detailed|comprehensive] [-m MODEL_NAME]
  local system_prompt="write a shell terminal command to accomplish the task described in the user input. The command will be run directly in the zsh terminal so code comments are not allowed. The command should be practical and effective, with a technical tone. code should be formatted in a code block, e.g.: \`\`\`bash"
  local thinking_level="none"
  local args=()
  local model=""
  local raw=false

  if [ ! -t 0 ]; then
    local piped_content
    piped_content=$(cat)
  fi
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --thinking=*)
        thinking_level=${1#*=}
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
  
  if [ "$thinking_level" != "none" ]; then
    reasoning=$(echo -e "$piped_content" | structured_chain_of_thought --raw "${args[@]}")
    if [[ -n "$reasoning" ]]; then
      system_prompt+="<thinking>$reasoning</thinking>"
    else
      echo "Error: No reasoning provided" >&2
      return 1
    fi
  fi
  system_prompt="\n<SYSTEM>\n$system_prompt\n</SYSTEM>\n"

  response=$(echo -e "$piped_content\n$system_prompt" | llm --no-stream "${args[@]}")

  if [ "$raw" = true ]; then
    echo "$response"
    return
  fi
  shelllm_commands="$(echo -E "$response" | awk 'BEGIN{RS="```bash"} NR==2' | awk 'BEGIN{RS="```"} NR==1'  | sed '/^ *#/d;/^$/d')" 
  if [ "$thinking_level" != "none" ]; then
    thinking="$(echo "$response" | awk 'BEGIN{RS="<think>"} NR==2' | awk 'BEGIN{RS="</think>"} NR==1')"
  fi
  print -r -z "$shelllm_commands"
}


commit_generator() {
  # Generates a commit message based on the changes made in the git repository.
  # Usage: commit_generator [--thinking=none|minimal|moderate|detailed|comprehensive] [-m MODEL_NAME] [--note=NOTE|-n NOTE]
  local system_prompt="Write a sensible commit message for the changes made. The commit message should be concise and descriptive, with a technical tone. Include the following XML tags in your response: <commit_msg>...</commit_msg>"
  local thinking_level="none"
  local args=()
  local model=""
  local note=""
  local diff=""
  local raw=false
  
  
  # Process arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --thinking=*)
        thinking_level=${1#*=}
        ;;
      -n|--note)
        if [[ -n "$2" && ! "$2" =~ ^- ]]; then
          note="$2"
          system_prompt+=" <note>$note</note>"
          shift
        else
          echo "Error: -n/--note requires a note string" >&2
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
  
  # Check if we're in a git repository
  if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    echo "Error: Not in a git repository" >&2
    return 1
  fi
  
  # Stage all changes
  git add .
  
  while true; do
    # Determine appropriate diff command based on size
    if [[ $(git diff --cached | wc -w) -lt 160000 ]]; then
      diff="$(git diff --cached)"
    elif [[ "$(git shortlog --no-merges | wc -w)" -lt 160000 ]]; then 
      diff="$(git shortlog --no-merges)"
    else
      diff="$(git diff --cached --stat)"
    fi
    
    if [ "$thinking_level" != "none" ]; then
      reasoning=$(echo -e "$diff" | structured_chain_of_thought --raw "${args[@]}")
      if [[ -n "$reasoning" ]]; then
        system_prompt+="<thinking>$reasoning</thinking>"
      else
        echo "Error: No reasoning provided" >&2
        return 1
      fi
    fi
    
    response=$(echo -e "$diff" | llm -s "$system_prompt" --no-stream "${args[@]}")
    if [ "$raw" = true ]; then
      echo "$response"
      return
    fi
    commit_msg="$(echo "$response" | awk 'BEGIN{RS="<commit_msg>"} NR==2' | awk 'BEGIN{RS="</commit_msg>"} NR==1')"
    
    if [ "$thinking_level" != "none" ]; then
      thinking="$(echo "$response" | awk 'BEGIN{RS="<think>"} NR==2' | awk 'BEGIN{RS="</think>"} NR==1')"
      echo -e "\nThinking:\n$thinking\n"
    fi
    
    # Display commit message and ask for confirmation
    echo -e "\nCommit message:\n$commit_msg\n"
    echo -n "Confirm commit and push? [y/n/e(edit)]: "
    read -r confirm
    
    if [[ "$confirm" == "y" ]]; then
      git commit -m "$commit_msg"
      git push
      break
    elif [[ "$confirm" == "e" ]]; then
      # Allow editing the commit message
      echo "$commit_msg" > /tmp/commit-msg-edit
      ${EDITOR:-vi} /tmp/commit-msg-edit
      commit_msg=$(cat /tmp/commit-msg-edit)
      rm /tmp/commit-msg-edit
      
      echo -e "\nEdited commit message:\n$commit_msg\n"
      echo -n "Confirm commit and push? [y/n]: "
      read -r confirm2
      
      if [[ "$confirm2" == "y" ]]; then
        git commit -m "$commit_msg"
        git push
        break
      fi
    elif [[ "$confirm" == "n" ]]; then
      echo "Regenerating commit message..."
      # Loop continues
    else
      echo "Invalid option. Please try again."
    fi
  done
}

# Alias for ease of use
alias commit=commit_generator


novel_ideas_generator() {
  # Generates a list of unique ideas based on a user query.
  # Usage: brainstorm <topic or question> [--count=<number>] [--thinking=<level>] [--model=<model>] [--raw] [--show-reasoning]
  # Options:
  #   --count=<number>        Number of ideas to generate (default: 10)
  #   --thinking=<level>      Control reasoning depth (none, minimal, moderate, detailed, comprehensive)
  #   --raw                   Return the raw LLM response
  #   --show-reasoning        Show reasoning process

  local system_prompt="You are a creative <brainstorm> assistant. Your task is to generate a list of unique ideas based directly on a user's query.

    Follow these steps to provide relevant ideas:
    1. Read the user's query carefully.
    3. Ensure each idea is practical and original (novel approaches or unique combinations of existing concepts, not common or cliché solutions).
    4. Keep each idea concise (1-2 sentences, maximum 500 characters per idea).

    <constraints>
      - Ideas must be strictly based on the given user query.
      - Each idea must be concise (1-2 sentences per idea).
      - Focus on practical and original solutions.
      - Original ideas should offer a novel approach, perspective, or combination of existing concepts. They should not be common, cliché, or readily found through a simple web search.
      - This prompt should be effective for any type of brainstorming task (product ideas, problem-solving, creative projects, etc.).
      - Format your response using the following XML structure, and provide no other text besides the XML response:
        <ideas>
          <item>First idea here...</item>
          <item>Second idea here...</item>
          ...
        </ideas>
        
        </brainstorm>
    </constraints>

    Example:
    <thinking>
    [Your reasoning process here]
    </thinking>
    <ideas>
    1. [First idea with brief explanation]
    2. [Second idea with brief explanation]
    ...etc.
    </ideas>

    Note: Your response should include between 5 and 10 ideas, all within the <brainstorm> tags."

  local thinking_level="none"
  local args=()
  local model=""
  local count=10
  local raw=false
  local show_reasoning=false
  
  # Check if input is being piped
  if [ ! -t 0 ]; then
    local piped_content
    piped_content=$(cat)
  fi
  
  # Process arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --count)
        if [[ -n "$2" && ! "$2" =~ ^- ]]; then
          count="$2"
          system_prompt+=" <count>$count</count>"
          shift
        else
          echo "Error: --count requires a number" >&2
          return 1
        fi
        ;;
      --thinking=*)
        thinking_level=${1#*=}
        ;;
      --raw)
        raw=true
        ;;
      --show-reasoning)
        show_reasoning=true
        ;;
      *)
        args+=("$1")
        ;;
    esac
    shift
  done
  
  if [ "$thinking_level" != "none" ]; then
    reasoning=$(echo -e "$piped_content" | structured_chain_of_thought --raw "${args[@]}")
    if [[ -n "$reasoning" ]]; then
      system_prompt+="<thinking>$reasoning</thinking>"
    else
      echo "Error: No reasoning provided" >&2
      return 1
    fi
  fi
  system_prompt="\n<SYSTEM>\n$system_prompt\n</SYSTEM>\n"
  # Call LLM
  response=$(echo -e "$piped_content\n$system_prompt" | llm --no-stream "${args[@]}")
  
  # Return raw response if requested
  if [ "$raw" = true ]; then
    echo "$response"
    return
  fi
  
  # Extract ideas
  ideas="$(echo "$response" | awk 'BEGIN{RS="<ideas>"} NR==2' | awk 'BEGIN{RS="</ideas>"} NR==1' | sed 's/<item>//g; s/<\/item>/\n/g' | sed '/^[[:space:]]*$/d')"
  if [[ -z "$ideas" ]]; then
    echo "$response"
    return
  fi
  # Extract reasoning if available
  if [ "$thinking_level" != "none" ] && [ "$show_reasoning" = true ]; then
    reasoning="$(echo "$response" | awk 'BEGIN{RS="<thinking>"} NR==2' | awk 'BEGIN{RS="</thinking>"} NR==1')"
    echo -e "\033[1;34mReasoning:\033[0m\n$reasoning\n"
  fi
  
  # Format output (numbered only)
  count=1
  while IFS= read -r line; do
    echo "$count. $line"
    ((count++))
  done <<< "$ideas"
}

# Alias for ease of use
alias brainstorm=novel_ideas_generator


prompt_engineer() {
  # Helps craft and refine LLM prompts with suggestions for improvements.
  # Usage: prompt_engineer <existing_prompt> [--thinking=none|minimal|moderate|detailed|comprehensive] [-m MODEL_NAME] [--format=<format>] [--task=<task>]
  #        cat prompt.txt | prompt_engineer [--thinking=none|minimal|moderate|detailed|comprehensive] [-m MODEL_NAME] [--format=<format>] [--task=<task>]
  # Options:
  #   --thinking=none|minimal|moderate|detailed|comprehensive        Level of reasoning to display
  #   -m MODEL_NAME         Specify which LLM model to use
  #   --format=<format>     Output format (standard, detailed, structured)
  #   --task <task>         Specific task the prompt is for (classification, generation, etc.)
  
  local system_prompt="You are a prompt engineering expert. Your task is to analyze the given prompt and suggest improvements to make it more effective for LLMs.

  Follow these steps:
  1. Analyze the provided prompt's structure, clarity, and specificity
  2. Identify weaknesses, ambiguities, or areas that could cause misunderstanding
  3. Suggest specific improvements with explanations
  4. Provide a refined version of the prompt
  
  Format your response with these XML tags:
  <analysis>Your analysis of the prompt's strengths and weaknesses</analysis>
  <improvements>
    <item>First improvement suggestion with explanation</item>
    <item>Second improvement suggestion with explanation</item>
    ...
  </improvements>
  <refined_prompt>Your improved version of the prompt</refined_prompt>"
  
  local thinking_level="none"
  local args=()
  local model=""
  local format="standard"
  local task=""
  local target_model=""
  local raw=false

  # Check if input is being piped
  if [ ! -t 0 ]; then
    local piped_content
    piped_content=$(cat)
    args+=("$piped_content")
  fi
  
  # Process arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --thinking=*)
        thinking_level=${1#*=}
        ;;
      --raw)
        raw=true
        ;;
      --format=*)
        format=${1#*=}
        ;;
      -n|--note)
        if [[ -n "$2" && ! "$2" =~ ^- ]]; then
          note="$2"
          system_prompt+=" <note>$note</note>"
          shift
        else
          echo "Error: -n/--note requires a note string" >&2
          return 1
        fi
        ;;
      --task)
        if [[ -n "$2" && ! "$2" =~ ^- ]]; then
          task="$2"
          system_prompt+=" <task>$task</task>"
          shift
        else
          echo "Error: --task requires a task description" >&2
          return 1
        fi
        ;;
      *)
        args+=("$1")
        ;;
    esac
    shift
  done

   
  if [ "$thinking_level" != "none" ]; then
    reasoning=$(echo -e "$piped_content" | structured_chain_of_thought --raw "${args[@]}")
    if [[ -n "$reasoning" ]]; then
      system_prompt+="<thinking>$reasoning</thinking>"
    else
      echo "Error: No reasoning provided" >&2
      return 1
    fi
  fi
  # Call LLM
  system_prompt="\n<SYSTEM>\n$system_prompt\n</SYSTEM>\n"
  response=$(echo -e "$piped_content" | llm -s "$system_prompt" --no-stream "${args[@]}")
  if [ "$raw" = true ]; then
    echo "$response"
    return
  fi
  # Extract sections
  analysis="$(echo "$response" | awk 'BEGIN{RS="<analysis>"} NR==2' | awk 'BEGIN{RS="</analysis>"} NR==1')"
  improvements="$(echo "$response" | awk 'BEGIN{RS="<improvements>"} NR==2' | awk 'BEGIN{RS="</improvements>"} NR==1' | sed 's/<item>//g; s/<\/item>/\n/g')"
  refined_prompt="$(echo "$response" | awk 'BEGIN{RS="<refined_prompt>"} NR==2' | awk 'BEGIN{RS="</refined_prompt>"} NR==1')"
  
  # Format output based on specified format
  if [ "$thinking_level" != "none" ]; then
    thinking="$(echo "$response" | awk 'BEGIN{RS="<think>"} NR==2' | awk 'BEGIN{RS="</think>"} NR==1')"
    echo -e "\033[1;34m🧠 Thinking Process:\033[0m\n$thinking\n"
  fi
  
  # check if analysis is empty and if so return the raw response
  if [[ -z "$analysis" ]]; then
    echo "$response"
    return
  else
    # Default standard format
    echo -e "\033[1;36mPROMPT ANALYSIS:\033[0m\n$analysis\n"
    
    echo -e "\033[1;33mIMPROVEMENT SUGGESTIONS:\033[0m"
    count=1
    while IFS= read -r line; do
      if [[ -n "$line" ]]; then
        echo -e "$count. $line"
        ((count++))
      fi
    done <<< "$improvements"
    
  fi
    echo -e "\n\033[1;32mREFINED PROMPT:\033[0m\n$refined_prompt"
}

structured_chain_of_thought() {
  # Breaks down complex problems using structured reasoning steps.
  # Usage: structured_chain_of_thought <problem description> [--thinking=none|minimal|moderate|detailed|comprehensive] [-m MODEL_NAME] [--steps=<steps>]
  #        cat problem.txt | structured_chain_of_thought [--thinking=none|minimal|moderate|detailed|comprehensive] [-m MODEL_NAME] [--steps=<steps>]
  # Options:
  #   --thinking=LEVEL       Control reasoning depth (none, minimal, moderate, detailed, comprehensive)
  #   -m MODEL_NAME          Specify which LLM model to use
  #   --steps=STEPS          Define custom reasoning steps (comma-separated)
  #   --raw                  Return the raw LLM response
  
  local system_prompt='You are a reasoning assistant that helps break down complex problems through structured thinking. Follow these steps meticulously:

1.  **Problem Understanding**:
    *   Restate the problem in your own words to confirm understanding.
    *   *Example*: "The user is asking to [specific task], which requires [key elements]."
    *   Validate alignment with the user’s intent before proceeding.
2.  **Approach Planning**:
    *   Outline a clear, step-by-step strategy using bullet points.
    *   *Example*: "1. Gather relevant data. 2. Apply [method]. 3. Validate results."
    *   Justify why this approach is suitable.
3.  **Step-by-Step Reasoning**:
    *   Execute your plan with numbered steps, showing calculations/logic.
    *   *Example*: "Step 1: [Action]. Step 2: [Calculation]."
    *   Highlight assumptions and potential pitfalls.
4.  **Alternative Perspectives**:
    *   Propose 2-3 distinct approaches or critiques of your main method.
    *   *Example*: "Alternative 1: Use [method X] for better accuracy. Con: Requires more time."
5.  **Conclusion**:
    *   Summarize findings and final answer.
    *   Address limitations of your reasoning and suggest next steps if unresolved.

**Formatting Rules**:

*   Use XML tags exactly as specified:
    `<problem_understanding>...</problem_understanding>`
    `<approach>...</approach>`
    `<reasoning>...</reasoning>`
    `<alternatives>...</alternatives>`
    `<conclusion>...</conclusion>`
*   Avoid markdown; keep content plain text within tags.
*   Adjust detail level based on problem complexity (e.g., minimal for simple tasks, detailed for ambiguous problems).

**Critical Note**: If the problem is unclear, pause and ask clarifying questions before proceeding. Then, return <question>...</question> to the user for further input.'

  local thinking_level="none"
  local args=()
  local model=""
  local raw=false
  local custom_steps=""

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

  system_prompt="
<SYSTEM_PROMPT>
Ensure that your main answer follows this format exactly:
$system_prompt
</SYSTEM_PROMPT>
"  
  # Call LLM
  response=$(echo -e "$piped_content\n$system_prompt"  | llm --no-stream "${args[@]}")
  
  # Return raw response if requested
  if [ "$raw" = true ]; then
    echo "$response"
    return
  fi
  
  # Extract sections
  problem_understanding="$(echo "$response" | awk 'BEGIN{RS="<problem_understanding>"} NR==2' | awk 'BEGIN{RS="</problem_understanding>"} NR==1')"
  approach="$(echo "$response" | awk 'BEGIN{RS="<approach>"} NR==2' | awk 'BEGIN{RS="</approach>"} NR==1')"
  reasoning="$(echo "$response" | awk 'BEGIN{RS="<reasoning>"} NR==2' | awk 'BEGIN{RS="</reasoning>"} NR==1')"
  alternatives="$(echo "$response" | awk 'BEGIN{RS="<alternatives>"} NR==2' | awk 'BEGIN{RS="</alternatives>"} NR==1')"
  conclusion="$(echo "$response" | awk 'BEGIN{RS="<conclusion>"} NR==2' | awk 'BEGIN{RS="</conclusion>"} NR==1')"
  
  
  # Display formatted output
  echo -e "\033[1;36m🔍 PROBLEM UNDERSTANDING:\033[0m\n$problem_understanding\n"
  echo -e "\033[1;33m🧩 APPROACH:\033[0m\n$approach\n"
  echo -e "\033[1;32m⚙️ REASONING:\033[0m\n$reasoning\n"
  echo -e "\033[1;35m🔄 ALTERNATIVE PERSPECTIVES:\033[0m\n$alternatives\n"
  echo -e "\033[1;31m✅ CONCLUSION:\033[0m\n$conclusion"
}

