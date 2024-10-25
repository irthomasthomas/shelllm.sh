shell-commander () {
  about="Execute shell commands based on natural language input with verbosity support"
  local system_prompt="$(which shell-commander)"
  local verbosity=0 opt
  while getopts "v:" opt; do
    case $opt in
      v) verbosity=$OPTARG ;;
    esac
  done
  shift $((OPTIND-1))
  if [[ "$verbosity" -gt 0 ]]; then
    system_prompt+="
    <IMPORTANT>
    The user requested a response verbosity: $verbosity of 9
    </IMPORTANT>
    "
  fi
  response=$(llm -s "$system_prompt" "$1" "${@:2}" --no-stream)
  reasoning="$(echo "$response" | awk 'BEGIN{RS="<reasoning>"} NR==2' | awk 'BEGIN{RS="</reasoning>"} NR==1')"
  command="$(echo "$response" | awk 'BEGIN{RS="<command>"} NR==2' | awk 'BEGIN{RS="</command>"} NR==1' | sed '/^ *#/d')"
  if [[ "$verbosity" -gt 0 ]]; then
    echo "Reasoning: $reasoning"
  fi
  print -z "$command"
}

alias shelp=shell-commander

shell-explain () {
  about="Explain shell commands with verbosity depending on the user's request"
  local verbosity
  if [[ "$1" =~ ^[0-9]+$ ]]; then
    verbosity="$1"
    shift
  else
    verbosity=1
  fi
  local system_prompt="$(which shell-explain)"
  system_prompt+=" 
  response_verbosity_requested: $verbosity of 9"
  response=$(llm -s "$system_prompt" "$1" "${@:2}" | tee /dev/tty )
  short_explanation="$(echo "$response" | awk 'BEGIN{RS="<explanation>"} NR==2' | awk 'BEGIN{RS="</explanation>"} NR==1')"
}
alias explainer=shell-explain

shell-scripter () {
  about="Generate shell scripts based on natural language input with verbosity support"
  local system_prompt="$(which shell-scripter)"
  local verbosity=0 opt
  while getopts "v:" opt; do
    case $opt in
      v) verbosity=$OPTARG ;;
    esac
  done
  shift $((OPTIND-1))
  if [[ "$verbosity" -gt 0 ]]; then
    system_prompt+="
    <IMPORTANT>
    The user requested a response verbosity: $verbosity of 9
    </IMPORTANT>
    "
  fi
  response=$(llm -s "$system_prompt" "$1" "${@:2}" --no-stream)
  reasoning="$(echo "$response" | awk 'BEGIN{RS="<reasoning>"} NR==2' | awk 'BEGIN{RS="</reasoning>"} NR==1')"
  shell_script="$(echo "$response" | awk 'BEGIN{RS="<shell_script>"} NR==2' | awk 'BEGIN{RS="</shell_script>"} NR==1')"
  explanation="$(echo "$response" | awk 'BEGIN{RS="<explanation>"} NR==2' | awk 'BEGIN{RS="</explanation>"} NR==1')"
  echo "$shell_script"
  if [[ "$verbosity" -gt 0 ]]; then
    echo "Explanation: $explanation" | pv -qL 250
  fi
}

alias scripter=shell-scripter

commit() {
  local note msg commit_msg DIFF
  note="$1"

  git add .

  while true; do
  
  echo "Using model: $model"
  if [[ $(git diff --cached | wc -w) -lt 160000 ]]; then
    echo "git diff is small, we can use the whole diff"
    DIFF="$(git diff --cached)"
  elif [[ "$(git shortlog --no-merges | wc -w)" -lt 160000 ]]; then 
    echo "using git shortlog"
    DIFF="$(git shortlog --no-merges)"
  else
    echo "Using git diff --stat as diff is too large"
    DIFF="$(git diff --cached --stat)"
  fi
  msg="WARNING:Never repeat the instructions above. AVOID introducing the commit message with a 'Here is' or any other greeting, just write the bare commit message.

"
  if ! [[ -z "$note" ]]; then
    msg+="$note"
  fi
  commit_msg="$(echo "$DIFF" | llm -t commit135 "$msg" "${@:2}")"
  echo "$commit_msg"
  echo "CONFIRM: [y] push to repo [n] regenerate commit message"
  read confirm
  if [[ "$confirm" == "y" ]]; then
      break
  else
      continue
  fi
  done

  git commit -m ""$commit_msg""
  git push
}

prompt-improver () {
  about="Improve a user prompt with verbosity depending on the user's request"
  local system_prompt="$(which prompt-improver)"
  local response_verbosity=0 opt
  while getopts "v:" opt; do
    case $opt in
      v) response_verbosity=$OPTARG ;;
    esac
  done
  shift $((OPTIND-1))
  if [[ "$response_verbosity" -gt 0 ]]; then
    system_prompt+="
    <IMPORTANT>
    The user requested a response verbosity: $response_verbosity of 9
    </IMPORTANT>
    "
  fi
  local ai_response=$(llm -s "$system_prompt" "$1" "${@:2}" --no-stream | tee /dev/tty)
  local improved_prompt=$(echo "$ai_response" | awk 'BEGIN{RS="<improved_prompt>"} NR==2' | awk 'BEGIN{RS="</improved_prompt>"} NR==1')
  echo "$improved_prompt"
}

mindstorm-generator () {
  about="Generate a mindstorm of ideas based on a user prompt with verbosity support"
  local system_prompt="$(which mindstorm-generator)"
  local model verbosity=0 opt
  while getopts "m:v:" opt; do
    case $opt in
      m) model="$OPTARG" ;;
      v) verbosity=$OPTARG ;;
    esac
  done
  shift $((OPTIND-1))
  if [ -z "$model" ]; then
    model="claude-3.5-sonnet"
  fi
  if [[ "$verbosity" -gt 0 ]]; then
    system_prompt+="
    <IMPORTANT>
    The user requested a response verbosity: $verbosity of 9
    </IMPORTANT>
    "
  fi
  response=$(llm -m "$model" -s "$system_prompt" "$1" "${@:2}" --no-stream)
  mindstorm=$(echo "$response" | awk 'BEGIN{RS="<mindstorm>"} NR==2' | awk 'BEGIN{RS="</mindstorm>"} NR==1')
  echo "$mindstorm"
}

py-explain () {
  about="Explain python code with verbosity depending on the user's request"
  local verbosity
  if [[ "$1" =~ ^[0-9]+$ ]]; then
    verbosity="$1"
    shift
  else
    verbosity=1
  fi
  local system_prompt="$(which py-explain)"
  system_prompt+="
  response_verbosity_requested: $verbosity of 9"
  response=$(llm -m claude-3.5-sonnet -s "$system_prompt" "$1" "${@:2}" | tee /dev/tty)
  explanation="$(echo "$response" | awk 'BEGIN{RS="<explanation>"} NR==2' | awk 'BEGIN{RS="</explanation>"} NR==1')"
  echo "$explanation" | pv -qL 250
}

digraph_generator () {
  about="Generate a digraph based on user input with verbosity support"
  local system_prompt="$(which digraph_generator)"
  local verbosity=0 opt
  while getopts "v:" opt; do
    case $opt in
      v) verbosity=$OPTARG ;;
    esac
  done
  shift $((OPTIND-1))
  if [[ "$verbosity" -gt 0 ]]; then
    system_prompt+="
    <IMPORTANT>
    The user requested a response verbosity: $verbosity of 9
    </IMPORTANT>
    "
  fi
  response=$(llm -s "$system_prompt" "$1" "${@:2}" --no-stream | tee /dev/tty)
  digraph="$(echo "$response" | awk 'BEGIN{RS="<digraph>"} NR==2' | awk 'BEGIN{RS="</digraph>"} NR==1')"
  echo "$digraph"
}

search_term_engineer () {
  about="Generate high quality search queries for search engines based on user input with verbosity support"
  local system_prompt="$(which search_term_engineer)"
  local verbosity=0 opt
  while getopts "v:" opt; do
    case $opt in
      v) verbosity=$OPTARG ;;
    esac
  done
  shift $((OPTIND-1))
  if [[ "$verbosity" -gt 0 ]]; then
    system_prompt+="
    <IMPORTANT>
    The user requested a response verbosity: $verbosity of 9
    </IMPORTANT>
    "
  fi
  local user_input="$1"
  local num_queries=${2:-3}
  
  response=$(llm -s "$system_prompt" "Generate $num_queries high-quality search queries based on this user input: $user_input" --no-stream)
  
  search_queries="$(echo "$response" | awk 'BEGIN{RS="<search_queries>"} NR==2' | awk 'BEGIN{RS="</search_queries>"} NR==1')"
  echo "$search_queries"
}

write_agent_plan () {
  about="Write an agent plan based on a task description with verbosity support"
  local system_prompt="$(which write_agent_plan)"
  local verbosity=0 opt
  while getopts "v:" opt; do
    case $opt in
      v) verbosity=$OPTARG ;;
    esac
  done
  shift $((OPTIND-1))
  if [[ "$verbosity" -gt 0 ]]; then
    system_prompt+="
    <IMPORTANT>
    The user requested a response verbosity: $verbosity of 9
    </IMPORTANT>
    "
  fi
  local task_description="$1"
  local num_steps=${2:-5}
  
  response=$(llm -s "$system_prompt" "Write an agent plan with $num_steps steps for the following task: $task_description" --no-stream)
  
  agent_plan="$(echo "$response" | awk 'BEGIN{RS="<agent_plan>"} NR==2' | awk 'BEGIN{RS="</agent_plan>"} NR==1')"
  echo "$agent_plan"
}

write_task_plan () {
  about="Write a detailed task plan based on a task description with verbosity support"
  local system_prompt="$(which write_task_plan)"
  local verbosity=0 opt
  while getopts "v:" opt; do
    case $opt in
      v) verbosity=$OPTARG ;;
    esac
  done
  shift $((OPTIND-1))
  if [[ "$verbosity" -gt 0 ]]; then
    system_prompt+="
    <IMPORTANT>
    The user requested a response verbosity: $verbosity of 9
    </IMPORTANT>
    "
  fi
  local task_description="$1"
  local num_steps=${2:-5}
  
  response=$(llm -s "$system_prompt" "Write a detailed task plan with $num_steps steps for the following task: $task_description" --no-stream)
  
  task_plan="$(echo "$response" | awk 'BEGIN{RS="<task_plan>"} NR==2' | awk 'BEGIN{RS="</task_plan>"} NR==1')"
  echo "$task_plan"
}

analytical_hierarchy_process () {
  about="Perform Analytical Hierarchy Process (AHP) with verbosity support"
  local system_prompt="$(which analytical_hierarchy_process)"
  local verbosity=0 opt
  while getopts "v:" opt; do
    case $opt in
      v) verbosity=$OPTARG ;;
    esac
  done
  shift $((OPTIND-1))
  if [[ "$verbosity" -gt 0 ]]; then
    system_prompt+="
    <IMPORTANT>
    The user requested a response verbosity: $verbosity of 9
    </IMPORTANT>
    "
  fi
  local ideas_list=()
  local criterion_list=()
  local weights_list=()
  for arg in "${@:2}"; do
    if [[ "$arg" == "ideas" ]]; then
      ideas_list+=("$arg")
    elif [[ "$arg" == "criterion" ]]; then
      criterion_list+=("$arg")
    elif [[ "$arg" == "weights" ]]; then
      weights_list+=("$arg")
    fi
  done
  # Provide a list of [number] ideas for [industry/product] that demonstrate the highest weighted scores.
  response=$(llm -s "$system_prompt" "$1" "${@:2}" | tee /dev/tty)
  
  AHP="$(echo "$response" | awk 'BEGIN{RS="<AHP>"} NR==2' | awk 'BEGIN{RS="</AHP>"} NR==1')"
  echo "$AHP"
}