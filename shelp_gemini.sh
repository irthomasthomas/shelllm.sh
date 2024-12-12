shelllm_gemini () {
	local system_prompt="$(which shelllm_gemini)" 
	local raw=false 
	local args=()
    local llm_args
	local shell_query
	local reasoning_amount
	for arg in "$@"
	do
		case $arg in
			(--reasoning=*) reasoning_amount=${arg#*=}  && shell_query+="<REASONING_LENGTH>
$reasoning_amount
</REASONING_LENGTH>
"  ;;
			(--verbosity=*) verbosity=${arg#*=}  && shell_query+="<COT_VERBOSITY>
$verbosity
</COT_VERBOSITY>
"  ;;
			(--raw|--r) raw=true  ;;
			(--model=*) model=${arg#*=} ;;
            (-p=*|--prompt=*) shell_query="<prompt>${arg#*=}</prompt>" ;;
			(*) args+=("$arg")  ;;
		esac
	done
  
  echo "shell_query: $shell_query"
	gemini_response="$(llm -s "$system_prompt" "$shell_query" -m $model --no-stream -o temperature 0 ${args[*]})" 
	shelllm_command="$(echo -E "$gemini_response" | awk 'BEGIN{RS="<COMMAND>"} NR==2' | awk 'BEGIN{RS="</COMMAND>"} NR==1'  | sed '/^ *#/d;/^$/d')" 
	if "$raw"; then
		echo -n "$gemini_response"
	elif [ -n "$reasoning_amount" ];	then
		THINKING_TOKENS="$(echo -E "$gemini_response" | sed -n '/<THINKING>/,/<\/THINKING>/p')"
	fi
	print -z "$shelllm_command"
}

alias gshelp=shelllm_gemini