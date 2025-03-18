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