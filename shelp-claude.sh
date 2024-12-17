shelp_claude () {
	local system_prompt=$'which shelllm_gemini\n'"$(which shelllm_gemini)"'' 
	local shell_query reasoning_amount verbosity_score reasoning verbosity generation_control gemini_response prompt raw=false args=() CFR
	for arg in "$@"
	do
		case $arg in
			(-p=*|--prompt=*) prompt=$'4<TERMINAL_INPUT>\n'"${arg#*=}"$'\n</TERMINAL_INPUT>'  ;;
			(--reasoning=*) reasoning_ammount=${arg#*=}  && reasoning=true  ;;
			(--verbosity=*) verbosity_score=${arg#*=}  && verbosity=true  ;;
            (--cfr=*) CFR=${arg#*=}  && generation_control=$'<CFR>\n'"$CFR"$'\n</CFR>'  ;;
			(--raw|--r) raw=true  ;;
			(*) args+=("$arg")  ;;
		esac
	done
	if [ "$reasoning" ]
	then
		generation_control+=$'<REASONING_LENGTH>\n'"$reasoning_ammount"$'\n</REASONING_LENGTH>\n' 
	fi
	if [ "$verbosity" ]
	then
		generation_control+=$'<CODE_VERBOSITY>\n'"${verbosity_score}"'\n</CODE_VERBOSITY>' 
	fi
	prompt+=$'\nuname\n'"$(uname -a)"$'\nSHELL\n'"${SHELL}"$'\n' 
	prompt+=$'<OUTPUT_FORMAT>\n'"${generation_control}"'</OUTPUT_FORMAT>' 
	llm_response="$(llm -s $system_prompt  "$prompt" --no-stream -o temperature 0 ${args[*]})" 
	shelllm_commands="$(echo -E "$llm_response" | awk 'BEGIN{RS="<SHELL_COMMANDS>"} NR==2' | awk 'BEGIN{RS="</SHELL_COMMANDS>"} NR==1'  | sed '/^ *#/d;/^$/d')" 
	if "$raw"
	then
		echo -n "$llm_response"
	fi
	
    REASONING_PRE_TOKENS="$(echo -E "$llm_response" | sed -n '/<PRE_REASONING>/,/<\/PRE_REASONING>/p')" 
    COUNTERFACTUAL_REGRET_MINIMIZATION="$(echo -E "$llm_response" | sed -n '/<COUNTERTACTUAL_REGRET_MINIMIZATION>/,/<\/COUNTERTACTUAL_REGRET_MINIMIZATION>/p')"
	echo
	print -r -z -- "$shelllm_commands"
}