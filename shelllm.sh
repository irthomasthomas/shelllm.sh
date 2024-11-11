write-agent-plan () {
  local system_prompt="$(which write-agent-plan)"

}
alias agent-plan=write-agent-plan

code-explainer () {
  local system_prompt="$(which code-explainer)"
  local verbosity=0
  local raw=false
  local reasoning=false
  local show_reasoning=false
  local args=()

  for arg in "$@"; do
    case $arg in
      --v=*|--verbosity=*) system_prompt+="<verbosity> The user requests a <task_plan> with a verbosity level of ${arg#*=} out of 9 </verbosity>" ;;
      --reasoning=*) reasoning=true && system_prompt+="<reasoning> The user requests that you use <reasoning> tokens to think through the problem BEFORE the <explanation>. The reasoning section is requested to have a verbosity level of ${arg#*=} out of 9. The higher the requested verbosity level, the longer, smarter, and more detailed should be your strategems within the <reasoning> section, but it should no affect the verbosity of the main answer, who's verbosity should be only be guided by the main --verbosity flag. Again, the amount of reasoning tokens requested is: ${arg#*=} out of 9 </reasoning>" ;;
      --show-reasoning) show_reasoning=true ;;
      --raw|--r) raw=true ;;
      *) args+=("$arg") ;;
    esac
  done

  code_explainer_response=$(llm -s "$system_prompt" "${args[@]}" --no-stream)
  if [ "$raw" = true ]; then
    echo "$code_explainer_response"
  else
    if [ "$reasoning" = true ]; then
      reasoning="$(echo "$code_explainer_response" | awk 'BEGIN{RS="<reasoning>"} NR==2' | awk 'BEGIN{RS="</reasoning>"} NR==1')"
      if [ "$show_reasoning" = true ]; then
        echo "$reasoning"
      fi
    fi
    explanation="$(echo "$code_explainer_response" | awk 'BEGIN{RS="<explanation>"} NR==2' | awk 'BEGIN{RS="</explanation>"} NR==1')"
    echo "$explanation"
  fi
}
alias explainer=code-explainer

shell-commander () {
  local system_prompt="$(which shell-commander)" 
  local verbosity=0
  local raw=false
  local args=()
  local user_query
  local model
  local reasoning_amount

  for arg in "$@"; do
    case $arg in
      --v=*|--verbosity=*) system_prompt+="<verbosity> The user requests a <shell_command> with a verbosity level of ${arg#*=} out of 9 </verbosity>" ;;
      --reasoning=*) reasoning_amount=${arg#*=} && system_prompt+="<REASONING> The user requests that you use <REASONING> tokens to think through the problem BEFORE the <shell_command>. The reasoning section is requested to have a verbosity level of ${reasoning_amount} out of 9. The higher the requested verbosity level, the longer, smarter, and more detailed should be your strategems within the <reasoning> section, but it should no affect the verbosity of the main answer, whos verbosity should  only be guided by the main --verbosity flag. Again, the amount of reasoning tokens requested is: $reasoning_amount out of 9 </reasoning>" ;;
      --raw|--r) raw=true ;;
      -m | --model=*) model=${arg#*=} ;;
      *) args+=("$arg") ;;
    esac
  done
  if [ -z "$model" ]; then 
    model="claude-3.5-sonnet"
  fi
  user_query="${args[@]}"
  raw_response=$(llm -s "$system_prompt" "$user_query" -m $model --no-stream)
  shell_command="$(echo -E "$raw_response" | awk 'BEGIN{RS="<shell_command>"} NR==2' | awk 'BEGIN{RS="</shell_command>"} NR==1' | sed '/^ *#/d;/^$/d')" 
  if [ "$raw" = true ]; then
    echo -n "$raw_response"
  else
    if [ -n "$reasoning_amount" ]; then
      echo -E "$raw_response" | sed -n '/<REASONING>/,/<\/REASONING>/p'
    fi    
    print -z "$shell_command" 
  fi
}
alias shelp=shell-commander


task-plan-generator () {
  local system_prompt="$(which task-plan-generator)"
  local verbosity=0
  local raw=false
  local reasoning=0
  local show_reasoning=false
  local args=()

  for arg in "$@"; do
    case $arg in
      --v=*|--verbosity=*) system_prompt+="<verbosity> The user requests a <task_plan> with a verbosity level of ${arg#*=} out of 9 </verbosity>" ;;
      --reasoning=*) reasoning=true && system_prompt+="<reasoning> I understand that I need to use <reasoning> tokens to think through the problem BEFORE the <task_plan>. I should adjust my reasoning section's verbosity to a level of ${arg#*=} out of 9. If the requested verbosity level is higher, I will make my strategies within the <reasoning> section longer, more intelligent, and more detailed. However, I note that this shouldn't affect the verbosity of my main answer, which is separately controlled by the --verbosity flag. I'll keep these guidelines in mind when formulating my responses. To confirm, the amount of reasoning tokens requested is: ${arg#*=} out of 9 </reasoning>" ;;
      --show-reasoning) show_reasoning=true ;;
      --raw|--r) raw=true ;;
      *) args+=("$arg") ;;
    esac
  done

  assistant_response=$(llm -s "$system_prompt" "${args[@]}" --no-stream)
  task_plan="$(echo "$assistant_response" | awk 'BEGIN{RS="<task_plan>"} NR==2' | awk 'BEGIN{RS="</task_plan>"} NR==1' | sed '/^ *#/d;/^$/d')"

  if [ "$raw" = true ]; then
    echo -n "$assistant_response"
  else
    if [ "$reasoning" = true ]; then
      reasoning="$(echo "$assistant_response" | awk 'BEGIN{RS="<reasoning length=""$reasoning"">"} NR==2' | awk 'BEGIN{RS="</reasoning>"} NR==1')"
      if [ "$show_reasoning" = true ]; then
        echo "$reasoning"
      fi
    fi
    echo "$task_plan"
  fi
}
alias task-plan=task-planner

bash-script-generator () {
  local system_prompt="$(which bash-script-generator)"
  local verbosity=0
  local raw=false
  local reasoning=false
  local show_reasoning=false
  local args=()

  for arg in "$@"; do
    case $arg in
      --v=*|--verbosity=*) system_prompt+="<verbosity> The user requests a <bash_script> with a verbosity level of ${arg#*=} out of 9 </verbosity>" ;;
      --reasoning=*) reasoning=true && system_prompt+="<reasoning> The user requests that you use <reasoning> tokens to think through the problem BEFORE the <bash_script>. The reasoning section is requested to have a verbosity level of ${arg#*=} out of 9. The higher the requested verbosity level, the longer, smarter, and more detailed should be your strategems within the <reasoning> section, but it should no affect the verbosity of the main answer, whos verbosity should  only be guided by the main --verbosity flag. Again, the amount of reasoning tokens requested is: ${arg#*=} out of 9 </reasoning>" ;;
      --show-reasoning) show_reasoning=true ;;
      --raw) raw=true ;;
      *) args+=("$arg") ;;
    esac
  done
  
  bash_script_generator_response=$(llm -s "$system_prompt" "${args[@]}" --no-stream)
  
  if [ "$raw" = true ]; then
    echo "$bash_script_generator_response"
  else
    if [ "$reasoning" = true ]; then
      reasoning="$(echo "$bash_script_generator_response" | awk 'BEGIN{RS="<reasoning>"} NR==2' | awk 'BEGIN{RS="</reasoning>"} NR==1')"
      if [ "$show_reasoning" = true ]; then
        echo "$reasoning"
      fi
    fi
    bash_script="$(echo "$bash_script_generator_response" | awk 'BEGIN{RS="<bash_script>"} NR==2' | awk 'BEGIN{RS="</bash_script>"} NR==1')"
    echo "$bash_script"
  fi

}
alias shell-script=shell-script-generator
alias scripter=shell-script-generator


prompt-improver () {
  local system_prompt="$(which prompt-improver)"
  local verbosity=0
  local raw=false
  local reasoning=false
  local args=()

  for arg in "$@"; do
    case $arg in
      --v=*|--verbosity=*) system_prompt+="<verbosity> The user requests an <improved_prompt> with a verbosity level of ${arg#*=} out of 9 </verbosity>" ;;
      --reasoning=*) reasoning=true && system_prompt+="<reasoning> The user requests that you use <reasoning> tokens to think through the problem BEFORE writing the <improved_prompt>. The reasoning section is requested to have a verbosity level of ${arg#*=} out of 9. The higher the requested verbosity level, the longer, smarter, and more detailed should be your strategems within the <reasoning> section, but it should no affect the verbosity of the main answer, whos verbosity should  only be guided by the main --verbosity flag. Again, the amount of reasoning tokens requested is: ${arg#*=} out of 9 </reasoning>" ;;
      --creativity=*) creativity=${arg#*=} && system_prompt+="<creativity> The user requests an <improved_prompt> with a creativity level of $creativity out of 9 </creativity>" ;;
      --raw) raw=true ;;
      *) args+=("$arg") ;;
    esac
  done
  
  response=$(llm -s "$system_prompt" "${args[@]}" --no-stream)
  
  if [ "$raw" = true ]; then
    echo "$response"
  else
    if [ "$reasoning" = true ]; then
      reasoning="$(echo "$response" | awk 'BEGIN{RS="<reasoning>"} NR==2' | awk 'BEGIN{RS="</reasoning>"} NR==1')"
      echo "$reasoning"
    fi
    prompt="$(echo "$response" | awk 'BEGIN{RS="<improved_prompt>"} NR==2' | awk 'BEGIN{RS="</improved_prompt>"} NR==1')"
    echo "$prompt"
  fi
}

brainstorm-generator () {
  local system_prompt="$(which mindstorm-generator)"
  response=$(llm -m "$model" -s "$system_prompt" "$1" "${@:2}" --no-stream)
  brainstorm=$(echo "$response" | awk 'BEGIN{RS="<brainstorm>"} NR==2' | awk 'BEGIN{RS="</brainstorm>"} NR==1')
  echo "$brainstorm"
}
alias brainstorm=brainstorm-generator


digraph-generator () {
  local system_prompt="$(which digraph-generator)"
  local verbosity=0
  local raw=false
  local reasoning=false
  local show_reasoning=false
  local args=()

  for arg in "$@"; do
    case $arg in
      --v=*|--verbosity=*) system_prompt+="<verbosity> The user requests a <digraph> with a verbosity level of ${arg#*=} out of 9 </verbosity>" ;;
      --reasoning=*) reasoning=true && system_prompt+="<reasoning> The user requests that you use <reasoning> tokens to think through the problem BEFORE the <digraph>. The reasoning section is requested to have a verbosity level of ${arg#*=} out of 9. The higher the requested verbosity level, the longer, smarter, and more detailed should be your strategems within the <reasoning> section, but it should no affect the verbosity of the main answer, whos verbosity should  only be guided by the main --verbosity flag. Again, the amount of reasoning tokens requested is: ${arg#*=} out of 9 </reasoning>" ;;
      --show-reasoning) show_reasoning=true ;;
      --raw) raw=true ;;
      *) args+=("$arg") ;;
    esac
  done

  digraph_generator_response=$(llm -s "$system_prompt" "${args[@]}" --no-stream)

  if [ "$raw" = true ]; then
    echo "$digraph_generator_response"
  else
    if [ "$reasoning" = true ]; then
      reasoning="$(echo "$digraph_generator_response" | awk 'BEGIN{RS="<reasoning>"} NR==2' | awk 'BEGIN{RS="</reasoning>"} NR==1')"
      if [ "$show_reasoning" = true ]; then
        echo "$reasoning"
      fi
    fi
    digraph="$(echo "$digraph_generator_response" | awk 'BEGIN{RS="<digraph>"} NR==2' | awk 'BEGIN{RS="</digraph>"} NR==1')"
    echo "$digraph"
  fi
}
alias digraph=digraph-generator

search-engineer () {
	local system_prompt="$(which search-engineer)" 
	local verbosity=0 
	local number=1 
	local raw=false 
	local reasoning=false 
	local creativity=0 
	local args=() 
	for arg in "$@"
	do
		case $arg in
			(--number=*) number=${arg#*=}  && system_prompt+="<number>
The user requests the top $number search terms in an unnumbered and unsorted list with no formatting. </number>"  ;;
			(--verbosity=*) system_prompt+="<verbosity>
The user requests a <search_term> with a verbosity level of ${arg#*=} out of 9 </verbosity>"  ;;
			(--reasoning=*) reasoning=true  && system_prompt+="<reasoning>
The user requests that you use <reasoning> tokens to think through the problem BEFORE the <search_term>. The reasoning section is requested to have a verbosity level of ${arg#*=} out of 9. The higher the requested verbosity level, the longer, smarter, and more detailed should be your strategems within the <reasoning> section, but it should no affect the verbosity of the main answer, whos verbosity should  only be guided by the main --verbosity flag. Again, the amount of reasoning tokens requested is: ${arg#*=} out of 9 </reasoning>"  ;;
			(--creativity=*) creativity=${arg#*=}  && system_prompt+="<creativity>
The user requests a <search_term> with a creativity level of $creativity out of 9 </creativity>"  ;;
			(-m=* | --model=*) model=${arg#*=}  ;;
			(--raw) raw=true  ;;
			(*) args+=("$arg")  ;;
		esac
	done
	if [ -z "$model" ]
	then
		model="claude-3.5-sonnet" 
	fi
	claude_response=$(llm -s "$system_prompt" "${args[@]}" -m $model --no-stream) 
	if [ "$raw" = true ]
	then
		echo "$search_term_engineer_response"
	else
		search_terms=$(echo "$claude_response" | awk 'BEGIN{RS="<SEARCH_TERMS>"} NR==2' | awk 'BEGIN{RS="</SEARCH_TERMS>"} NR==1')
		echo "$search_terms"
	fi
}

ai-judge () {
  usage="  usage: classifai [-h] -c CLASSES [CLASSES ...] [-m MODEL] [-t TEMPERATURE]
                  [-e EXAMPLES [EXAMPLES ...]] [-p PROMPT] [--no-content]
                  [content ...]
    classifai: error: the following arguments are required: -c/--classes
  "
  # classifai "Two candidates have refactored the <original_code>. Which code is better, candidate_one or candidate_two? In deciding which candidate code is better, completeness relative to original is crucial.
  # <original_code>
  # $(paster 0)
  # </original_code>

  # <candidate_one>
  # $(paster 1)
  # </candidate_one>

  # <candidate_two>
  # $(paster 2)
  # </candidate_two>
  # " -c "candidate_one" "candidate_two" --no-content -m gpt-4o

  # todo: call the classifai tool

}

analytical-hierarchy-process-generator () {
  local system_prompt="$(which analytical-hierarchy-process-generator)"
  local ideas_list=()
  local criterion_list=()
  local weights_list=()
  local verbosity=0
  local raw=false
  local args=()

  # Process arguments, stripping out -v, -n, and -raw flags
  for arg in "$@"; do
    case $arg in
      --v=*|--verbosity=*) system_prompt+="<verbosity> User requests a generated response with a verbosity level of ${arg#*=} out of 9 </verbosity>" ;;
      --n=*|--note=*) system_prompt+="<note> User added the following note to guide your response generation: ${arg#*=} </note>" ;;
      --raw|--r) raw=true ;;
      *) args+=("$arg") ;;
    esac
  done
  
  for arg in "$@"; do
    if [[ "$arg" == "ideas" ]]; then
      ideas_list+=("$arg")
    elif [[ "$arg" == "criterion" ]]; then
      criterion_list+=("$arg")
    elif [[ "$arg" == "weights" ]]; then
      weights_list+=("$arg")
    fi
  done
  # Provide a list of [number] ideas for [industry/product] that demonstrate the highest weighted scores.
  response=$(llm -s "$system_prompt" "${args[@]}" --no-stream)
  
  if [ "$raw" = true ]; then
    echo "$response"
  else  
    AHP="$(echo "$response" | awk 'BEGIN{RS="<AHP>"} NR==2' | awk 'BEGIN{RS="</AHP>"} NR==1')"
    echo "$AHP"
  fi
}

alias ahp=analytical_hierarchy_process_generator

commit-msg-generator () {
  local verbosity note msg commit_msg DIFF
  local system_prompt="$(which commit-msg-generator)"
  local args=()
  # Process arguments, stripping out -v and -n flags
  for arg in "$@"; do
    case $arg in
      -v=*|-verbosity=*) system_prompt+="<verbosity> User requests a generated response with a verbosity level of ${arg#*=} out of 9 </verbosity>" ;;
      -n=*|-note=*) system_prompt+="<note> User added the following note to guide your response generation: ${arg#*=} </note>" ;;
      *) args+=("$arg") ;;
    esac
  done

  # Stage all changes
  git add .
  
  while true; do
    # Determine appropriate diff command based on size
    if [[ $(git diff --cached | wc -w) -lt 160000 ]]; then
      DIFF="$(git diff --cached)"
    elif [[ "$(git shortlog --no-merges | wc -w)" -lt 160000 ]]; then 
      DIFF="$(git shortlog --no-merges)"
    else
      DIFF="$(git diff --cached --stat)"
    fi

    # Generate commit message using AI model
    response="$(echo "$DIFF" | llm -s "$system_prompt" "${args[@]}")"
    commit_msg="$(echo "$response" | awk 'BEGIN{RS="<commit_msg>"} NR==2' | awk 'BEGIN{RS="</commit_msg>"} NR==1')"
    
    # Display commit message and ask for confirmation
    echo "$commit_msg"
    echo "CONFIRM: [y] push to repo [n] regenerate commit message"
    read -r confirm
    if [[ "$confirm" == "y" ]]; then
      break
    fi
  done

  # Commit changes and push to remote repository
  git commit -m "$commit_msg"
  git push
}
alias commit=commit-msg-generator

cli-ergonomics-engineer () {
  local system_prompt="$(which cli-ergonomics-engineer)"
  local verbosity=0
  local raw=false
  local args=()

  for arg in "$@"; do
    case $arg in
      --v=*|--verbosity=*) system_prompt+="<verbosity> User requests a generated response with a verbosity level of ${arg#*=} out of 9 </verbosity>" ;;
      --n=*|--note=*) system_prompt+="<note> User added the following note to guide your response generation: ${arg#*=} </note>" ;;
      --raw|--r) raw=true ;;
      *) args+=("$arg") ;;
    esac
  done
  
  response=$(llm -s "$system_prompt" "${args[@]}" --no-stream)
  
  if [ "$raw" = true ]; then
    echo "$response"
  else
  thinking="$(echo "$response" | awk 'BEGIN{RS="<THINKING>"} NR==2' | awk 'BEGIN{RS="</THINKING>"} NR==1')"
  refactored_cli="$(echo "$response" | awk 'BEGIN{RS="<refactored_cli>"} NR==2' | awk 'BEGIN{RS="</refactored_cli>"} NR==1')"
  echo "$refactored_cli"
  fi
}
