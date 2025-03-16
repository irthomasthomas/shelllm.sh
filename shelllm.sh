task_plan_generator() {
  # Generates a task plan based on user input.
  # Usage: task_plan_generator <task description> [--thinking=0-9] [--model=MODEL_NAME|-m MODEL_NAME]
  #        cat file.txt | task_plan_generator [--thinking=0-9] [--model=MODEL_NAME|-m MODEL_NAME]
  
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
  local model_param=""

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
          model_param="--model=$2"
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

  response=$(llm -s "$system_prompt" "${args[@]}" $model_param --no-stream)
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
  local model_param=""
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
          model_param="--model=$2"
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
  response=$(llm "$inst\n${args[@]}" $model_param --no-stream)
	shelllm_commands="$(echo -E "$response" | awk 'BEGIN{RS="```bash"} NR==2' | awk 'BEGIN{RS="```"} NR==1'  | sed '/^ *#/d;/^$/d')" 
  if [ "$thinking_level" -gt 0 ]; then
    thinking="$(echo "$response" | awk 'BEGIN{RS="<think>"} NR==2' | awk 'BEGIN{RS="</think>"} NR==1')"
  fi
  print -r -z "$shelllm_commands"
}