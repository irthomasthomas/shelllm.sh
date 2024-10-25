
prompt-improver () {
    about="Improve a user prompt with verbosity depending on the user's request"
    local system_prompt="$(which prompt_improver)"
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
 

shell-explain () {
  about="Explain shell commands with verbosity depending on the user's request"
	local verbosity
	if [[ "$1" =~ ^[0-9]+$ ]]; then
		verbosity="$1"
		shift
	else
		verbosity=1
	fi
  local system_prompt="$(which shell_explain)"
	system_prompt+=" 
	response_verbosity_requested: $verbosity of 9"
  	response=$(llm -s "$system_prompt" "$1" "${@:2}" | tee /dev/tty )
	short_explanation="$(echo "$response" | awk 'BEGIN{RS="<explanation>"} NR==2' | awk 'BEGIN{RS="</explanation>"} NR==1')"	
}

shell-commander () {
  local system_prompt="$(which shell-commander)"
  response=$(llm -s "$system_prompt" "$1" "${@:2}" --no-stream)
  reasoning="$(echo "$response" | awk 'BEGIN{RS="<reasoning>"} NR==2' | awk 'BEGIN{RS="</reasoning>"} NR==1')"
  command="$(echo "$response" | awk 'BEGIN{RS="<command>"} NR==2' | awk 'BEGIN{RS="</command>"} NR==1' | sed '/^ *#/d')"
  print -z "$command"
}

alias shelp=shell-commander

shell-scripter () {
  local system_prompt="$(which shell-scripter)"
  response=$(llm -s "$system_prompt" "$1" "${@:2}" --no-stream)
  reasoning="$(echo "$response" | awk 'BEGIN{RS="<reasoning>"} NR==2' | awk 'BEGIN{RS="</reasoning>"} NR==1')"
  script="$(echo "$response" | awk 'BEGIN{RS="<shell_script>"} NR==2' | awk 'BEGIN{RS="</shell_script>"} NR==1')"
  explanation="$(echo "$response" | awk 'BEGIN{RS="<explanation>"} NR==2' | awk 'BEGIN{RS="</explanation>"} NR==1')"
  echo "$reasoning"
  echo "$explanation" | pv -qL 250
  echo "$script"
}

mindstorm-generator () {
  about="Generate a mindstorm of ideas based on a user prompt"
	local system_prompt="$(which mindstorm-generator)"
  local model
  while [[ $# -gt 0 ]]; do
    case $1 in
        -m|--model)
            model="$2"
            shift 2
            ;;
        *)
            user_prompt="$*"
            shift
            ;;
    esac
  done
  if [ -z "$model" ]; then
    model="claude-3.5-sonnet"
  fi
	mindstorm=$(llm -m "$model" -s "$system_prompt" "$user_prompt" "${@:2}" --no-stream \
  | awk 'BEGIN{RS="<mindstorm>"} NR==2' | awk 'BEGIN{RS="</mindstorm>"} NR==1')
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
  local system_prompt="$(which python_explainer)"
  system_prompt+="
  response_verbosity_requested: $verbosity of 9"
  response=$(llm -m claude-3.5-sonnet -s "$system_prompt" "$1" "${@:2}" | tee /dev/tty)
  short_explanation="$(echo "$response" | awk 'BEGIN{RS="<explanation>"} NR==2' | awk 'BEGIN{RS="</explanation>"} NR==1')"
}


