shelllm_gemini () {
	local system_prompt="$(which shelllm_gemini)" raw=false args=() 
	local llm_args shell_query reasoning_amount verbosity_score reasoning verbosity generation_control gemini_response
	for arg in "$@"
	do
		case $arg in
			(-p=*|--prompt=*) shell_query+="<PROMPT>
${arg#*=}
</PROMPT>"  ;;
			(--reasoning=*) reasoning_length=${arg#*=}  && reasoning=true  ;;
			(--verbosity=*) verbosity_score=${arg#*=}  && verbosity=true  ;;
			(--raw|--r) raw=true  ;;
			(*) args+=("$arg")  ;;
		esac
	done
	if [ "$reasoning" ]
	then
		generation_control+="<REASONING_LENGTH>
$reasoning_length
</REASONING_LENGTH>
" 
	fi
	if [ "$verbosity" ]
	then
		generation_control+="<VERBOSITY>
$verbosity_score
</VERBOSITY>" 
	fi
	shell_query+="
$generation_control
" 
	prompt="$system_prompt
    
    $shell_query" 
	gemini_response="$(llm  "$prompt" --no-stream -o temperature 0 ${args[*]})" 
	shelllm_command="$(echo -E "$gemini_response" | awk 'BEGIN{RS="<COMMAND>"} NR==2' | awk 'BEGIN{RS="</COMMAND>"} NR==1'  | sed '/^ *#/d;/^$/d')" 
	if "$raw"
	then
		echo -n "$gemini_response"
	elif [ -n "$reasoning_amount" ]
	then
		THINKING_TOKENS="$(echo -E "$gemini_response" | sed -n '/<THINKING>/,/<\/THINKING>/p')" 
	fi
	print -z "$shelllm_command"
}

alias gshelp=shelllm_gemini