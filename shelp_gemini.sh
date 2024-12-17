shelllm_gemini () {
	local system_prompt="$(which shelllm_gemini)" 
	local llm_args shell_query reasoning_amount verbosity_score reasoning verbosity generation_control gemini_response raw=false args=()
	system_prompt+="uname:$(uname -a)\nhostname:$(hostname)\nwhoami:$(whoami)\n\n" 
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
	if [ "$reasoning" ]; then
		generation_control+="<REQUESTED_REASONING_LENGTH>$reasoning_length</REQUESTED_REASONING_LENGTH>" 
	fi
	if [ "$verbosity" ]; then
		generation_control+="<COT_VERBOSITY>$verbosity_score</COT_VERBOSITY>" 
	fi
	shell_query+="<OUTPUT_FORMAT>$generation_control</OUTPUT_FORMAT>" 
	prompt="$shell_query" 
	gemini_response="$(llm -s "$system_prompt"  "$prompt" --no-stream -o temperature 0 ${args[*]})" 
    session_id=$(llm logs list -n 1 --json | jq -r '.[] |  .conversation_id')
	shelllm_command="$(echo -E "$gemini_response" | awk 'BEGIN{RS="<SHELL_COMMAND>"} NR==2' | awk 'BEGIN{RS="</SHELL_COMMAND>"} NR==1'  | sed '/^ *#/d;/^$/d')" 
	if "$raw"; then
        printf -v shelllm_command "%s" "$shelllm_command"
	elif [ -n "$reasoning_amount" ]; then
		REASONING_TOKENS="$(echo -E "$gemini_response" | sed -n '/<REASONING>/,/<\/REASONING>/p')" 
	fi
	print -r -z "$shelllm_command"
}

