task_plan_generator() {
  # Generates a task plan based on user input.
  # Usage: task_plan_generator <task description> [--thinking=0-9]
  
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
  local show_thinking=false
  local args=()

  for arg in "$@"; do
    case $arg in
      --thinking=*) thinking_level=${arg#*=} && system_prompt+="<thinking>${arg#*=}/9</thinking>" ;;
      *) args+=("$arg") ;;
    esac
  done

  response=$(llm -s "$system_prompt" "${args[@]}" --no-stream)
  plan="$(echo "$response" | awk 'BEGIN{RS="<plan>"} NR==2' | awk 'BEGIN{RS="</plan>"} NR==1' | sed '/^ *#/d;/^$/d')"

  if [ "$thinking_level" -gt 0 ]; then
    thinking="$(echo "$response" | awk 'BEGIN{RS="<think>"} NR==2' | awk 'BEGIN{RS="</think>"} NR==1')"
  fi
  echo "$plan"

}