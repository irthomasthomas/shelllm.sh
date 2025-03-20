task_plan_generator() {
  # Generates a task plan based on user input.
  # Usage: task_plan_generator <task description> [--thinking=0-9] [-m MODEL_NAME]
  #        cat file.txt | task_plan_generator [--thinking=0-9] [-m MODEL_NAME]
  
  # Define system prompt - use absolute path or locate relative to script location
  local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  local system_prompt
  if [[ -f "$script_dir/prompts/task-plan-generator" ]]; then
    system_prompt="$(cat "$script_dir/prompts/task-plan-generator")"
  elif [[ -f "/home/thomas/Projects/shelllm.sh/prompts/task-plan-generator" ]]; then
    system_prompt="$(cat "/home/thomas/Projects/shelllm.sh/prompts/task-plan-generator")"
  else
    echo "Error: Could not locate task-plan-generator prompt file" >&2
    return 1
  fi
  local thinking_level=0
  local args=()
  local model=""

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
        system_prompt+="<thinking>${thinking_level}/9</thinking>"
        ;;
      -m)
        if [[ -n "$2" && ! "$2" =~ ^- ]]; then
          model="-m$2"
          shift
        else
          echo "Error: -m requires a model name" >&2
          return 1
        fi
        ;;
      *)
        args+=("$1")
        ;;
    esac
    shift
  done

  response=$(llm -s "$system_prompt" "${args[@]}" $model --no-stream)
  plan="$(echo "$response" | awk 'BEGIN{RS="<plan>"} NR==2' | awk 'BEGIN{RS="</plan>"} NR==1' | sed '/^ *#/d;/^$/d')"

  if [ "$thinking_level" -gt 0 ]; then
    thinking="$(echo "$response" | awk 'BEGIN{RS="<think>"} NR==2' | awk 'BEGIN{RS="</think>"} NR==1')"
  fi
  echo "$plan"
}

shelp() {
  # Generate a shell command based on user input.
  # Usage: shelp <command description> [--thinking=0-9] [-m MODEL_NAME]
  #        cat file.txt | shelp [--thinking=0-9] [-m MODEL_NAME]
  local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  local system_prompt="write a shell command to accomplish the following task: "
  local thinking_level=0
  local args=()
  local model=""
  if [ ! -t 0 ]; then
    local piped_content
    piped_content=$(cat)
    args+=("$piped_content")
  fi
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --thinking=*)
        thinking_level=${1#*=}
        system_prompt+="<thinking>${thinking_level}/9</thinking>"
        ;;
      -m)
        if [[ -n "$2" && ! "$2" =~ ^- ]]; then
          model="-m $2"
          shift
        else
          echo "Error: -m requires a model name" >&2
          return 1
        fi
        ;;
      *)
        args+=("$1")
        ;;
    esac
    shift
  done
  inst="<INST>$system_prompt</INST>"
  response=$(llm "$inst\n${args[@]}" $model --no-stream)
	shelllm_commands="$(echo -E "$response" | awk 'BEGIN{RS="```bash"} NR==2' | awk 'BEGIN{RS="```"} NR==1'  | sed '/^ *#/d;/^$/d')" 
  if [ "$thinking_level" -gt 0 ]; then
    thinking="$(echo "$response" | awk 'BEGIN{RS="<think>"} NR==2' | awk 'BEGIN{RS="</think>"} NR==1')"
  fi
  print -r -z "$shelllm_commands"
}

commit_generator() {
  # Generates a commit message based on the changes made in the git repository.
  # Usage: commit_generator [--thinking=0-9] [-m MODEL_NAME] [--note=NOTE|-n NOTE]
  local system_prompt="Write a sensible commit message for the changes made. The commit message should be concise and descriptive, with a technical tone. Include the following XML tags in your response: <commit_msg>...</commit_msg>"
  local thinking_level=0
  local args=()
  local model=""
  local note=""
  local diff=""
  
  # Process arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --thinking=*)
        thinking_level=${1#*=}
        system_prompt+=" <thinking>${thinking_level}/9</thinking>"
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
      -m)
        if [[ -n "$2" && ! "$2" =~ ^- ]]; then
          model="$2"
          shift
        else
          echo "Error: -m requires a model name" >&2
          return 1
        fi
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
    
    # Generate commit message using LLM
    if [[ -n "$model" ]]; then
      response=$(echo "$diff" | llm -s "$system_prompt" "${args[@]}" -m "$model" --no-stream)
    else
      response=$(echo "$diff" | llm -s "$system_prompt" "${args[@]}" --no-stream)
    fi
    commit_msg="$(echo "$response" | awk 'BEGIN{RS="<commit_msg>"} NR==2' | awk 'BEGIN{RS="</commit_msg>"} NR==1')"
    
    if [ "$thinking_level" -gt 0 ]; then
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


brainstorm_generator() {
  # Generates a list of unique ideas based on a user query.
  # Usage: brainstorm <topic or question> [--count=<number>] [--reasoning=0-9] [--model=<model>] [--raw] [--show-reasoning]
  # Options:
  #   --count=<number>   Number of ideas to generate (default: 10)
  #   --reasoning=0-9    Control reasoning depth  
  #   --raw              Return the raw LLM response
  #   --show-reasoning   Show reasoning process

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
    <ideas>
    1. [First idea with brief explanation]
    2. [Second idea with brief explanation]
  ...etc.
  </ideas>

    Note: Your response should include between 5 and 10 ideas, all within the <brainstorm> tags."

  local reasoning_level=0
  local args=()
  local model=""
  local count=10
  local raw=false
  local show_reasoning=false
  
  # Check if input is being piped
  if [ ! -t 0 ]; then
    local piped_content
    piped_content=$(cat)
    args+=("$piped_content")
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
      --reasoning)
        if [[ -n "$2" && ! "$2" =~ ^- ]]; then
          reasoning_level=${2#*=}
          system_prompt+=" <reasoning>${reasoning_level}/9</reasoning>"
          shift
        else
          echo "Error: --reasoning requires a number" >&2
          return 1
        fi
        ;;
      --model=*|--model)
        if [[ "$1" == "--model=*" ]]; then
          model="-m ${1#*=}"
        elif [[ -n "$2" && ! "$2" =~ ^- ]]; then
          model="-m $2"
          shift
        else
          echo "Error: --model requires a model name" >&2
          return 1
        fi
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
  
  # Call LLM
  response=$(llm -s "$system_prompt" "${args[@]}" $model --no-stream)
  
  # Return raw response if requested
  if [ "$raw" = true ]; then
    echo "$response"
    return
  fi
  
  # Extract ideas
  ideas="$(echo "$response" | awk 'BEGIN{RS="<ideas>"} NR==2' | awk 'BEGIN{RS="</ideas>"} NR==1' | sed 's/<item>//g; s/<\/item>/\n/g' | sed '/^[[:space:]]*$/d')"
  
  # Extract reasoning if available
  if [ "$reasoning_level" -gt 0 ] && [ "$show_reasoning" = true ]; then
    reasoning="$(echo "$response" | awk 'BEGIN{RS="<reasoning>"} NR==2' | awk 'BEGIN{RS="</reasoning>"} NR==1')"
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
alias brainstorm=brainstorm_generator

prompt_engineer() {
  # Helps craft and refine LLM prompts with suggestions for improvements.
  # Usage: prompt_engineer <existing_prompt> [--thinking=0-9] [-m MODEL_NAME] [--format=<format>] [--task=<task>] [--target-model=<model>]
  #        cat prompt.txt | prompt_engineer [--thinking=0-9] [-m MODEL_NAME] [--format=<format>] [--task=<task>] [--target-model=<model>]
  # Options:
  #   --thinking=0-9        Level of reasoning to display (0=none, 9=most detailed)
  #   -m MODEL_NAME         Specify which LLM model to use
  #   --format=<format>     Output format (standard, detailed, structured)
  #   --task=<task>         Specific task the prompt is for (classification, generation, etc.)
  #   --target-model=<model> Target model the prompt is designed for
  
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
  
  local thinking_level=0
  local args=()
  local model=""
  local format="standard"
  local task=""
  local target_model=""
  
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
        system_prompt+=" <thinking>${thinking_level}/9</thinking>"
        ;;
      --model=*|--model)
        if [[ "$1" == "--model=*" ]]; then
          model="-m ${1#*=}"
        elif [[ -n "$2" && ! "$2" =~ ^- ]]; then # check if next argument is not a flag
          model="-m $2"
          shift
        else
          echo "Error: --model requires a model name" >&2
          return 1
        fi
        ;;
      -m)
        if [[ -n "$2" && ! "$2" =~ ^- ]]; then
          model="-m$2"
          shift
        else
          echo "Error: -m requires a model name" >&2
          return 1
        fi
        ;;
      --format=*)
        format=${1#*=}
        ;;
      --task=*)
        task=${1#*=}
        system_prompt+=" <task>This prompt is for ${1#*=}.</task>"
        ;;
      --target-model=*)
        target_model=${1#*=}
        system_prompt+=" <target_model>The prompt is intended for ${1#*=}.</target_model>"
        ;;
      *)
        args+=("$1")
        ;;
    esac
    shift
  done
  # Call LLM
  response=$(llm -s "$system_prompt" "${args[@]}" $model --no-stream)
  
  # Extract sections
  analysis="$(echo "$response" | awk 'BEGIN{RS="<analysis>"} NR==2' | awk 'BEGIN{RS="</analysis>"} NR==1')"
  improvements="$(echo "$response" | awk 'BEGIN{RS="<improvements>"} NR==2' | awk 'BEGIN{RS="</improvements>"} NR==1' | sed 's/<item>//g; s/<\/item>/\n/g')"
  refined_prompt="$(echo "$response" | awk 'BEGIN{RS="<refined_prompt>"} NR==2' | awk 'BEGIN{RS="</refined_prompt>"} NR==1')"
  
  # Format output based on specified format
  if [ "$thinking_level" -gt 0 ]; then
    thinking="$(echo "$response" | awk 'BEGIN{RS="<think>"} NR==2' | awk 'BEGIN{RS="</think>"} NR==1')"
    echo -e "\033[1;34m🧠 Thinking Process:\033[0m\n$thinking\n"
  fi
  
  if [[ "$format" == "structured" ]]; then
    echo -e "\033[1;33m📊 PROMPT ANALYSIS\033[0m\n"
    echo -e "\033[1;32m✅ ANALYSIS:\033[0m\n$analysis\n"
    
    echo -e "\033[1;32m🔧 SUGGESTED IMPROVEMENTS:\033[0m"
    count=1
    while IFS= read -r line; do
      if [[ -n "$line" ]]; then
        echo -e "\033[1;36m$count.\033[0m $line"
        ((count++))
      fi
    done <<< "$improvements"
    
    echo -e "\n\033[1;32m📝 REFINED PROMPT:\033[0m"
    echo -e "\033[1;37m\`\`\`\n$refined_prompt\n\`\`\`\033[0m"
    
  elif [[ "$format" == "detailed" ]]; then
    echo -e "\033[1;33m🔍 PROMPT ENGINEERING REPORT\033[0m\n"
    echo -e "\033[1;32mPROMPT ANALYSIS:\033[0m\n$analysis\n"
    
    echo -e "\033[1;32mSUGGESTED IMPROVEMENTS:\033[0m\n"
    count=1
    while IFS= read -r line; do
      if [[ -n "$line" ]]; then
        echo -e "  \033[1;36m$count)\033[0m $line\n"
        ((count++))
      fi
    done <<< "$improvements"
    
    echo -e "\033[1;32mREFINED PROMPT:\033[0m\n"
    echo -e "$refined_prompt"
    
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
    
    echo -e "\n\033[1;32mREFINED PROMPT:\033[0m\n$refined_prompt"
  fi
}

structured_chain_of_thought() {}