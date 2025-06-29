# Record original directory and locate script dir
original_dir=$(pwd)

# Get the absolute path to the script
if [[ -n "${BASH_SOURCE[0]}" ]]; then
  # For bash
  script_path="${BASH_SOURCE[0]}"
elif [[ -n "${(%):-%x}" ]]; then
  # For zsh
  script_path="${(%):-%x}"
else
  # Fallback method
  script_path="$0"
fi

# Convert to absolute path if not already
if [[ ! "$script_path" = /* ]]; then
  script_path="$original_dir/$script_path"
fi

# Get the script directory and source the necessary files
script_dir="$(cd "$(dirname "$script_path")" && pwd)"
cd "$script_dir"
source "$script_dir/search_engineer.sh"
source "$script_dir/code_refactor.sh"
cd "$original_dir"


task_plan_generator() {
  # Generates a task plan based on user input.
  # Usage: task_plan_generator <task description> [--thinking=none|minimal|moderate|detailed|comprehensive] [-m MODEL_NAME] [--note=NOTE|-n NOTE]
  #        cat file.txt | task_plan_generator [--thinking=none|minimal|moderate|detailed|comprehensive] [-m MODEL_NAME] [--note=NOTE|-n NOTE]
  
  # Define system prompt - use absolute path or locate relative to script location
  local system_prompt
  if [[ -f "$script_dir/prompts/task-plan-generator" ]]; then
    system_prompt="$(cat "$script_dir/prompts/task-plan-generator")"
  else
    echo "Error: Could not locate $script_dir/prompts/task-plan-generator" >&2
    return 1
  fi
  local thinking=false
  local args=()
  local model=""
  local user_input=""
  local additional_note=""
  local raw=false

  # Check if input is being piped
  if [ ! -t 0 ]; then
    user_input=$(cat)
  fi

  # Process arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --think)
        thinking=true
        ;;
      -n|--note)
        if [[ -n "$2" && ! "$2" =~ ^- ]]; then
          additional_note="$2"
          shift
        else
          echo "Error: -n/--note requires additional text" >&2
          return 1
        fi
        ;;
      --raw)
        raw=true
        ;;
      *)
        args+=("$1")
        ;;
    esac
    shift
  done


  # Combine piped content with additional instructions if both exist
  if [[ -n "$user_input" && -n "$additional_note" ]]; then
    user_input="$user_input\n\nAdditional instructions: $additional_note"
  elif [[ -z "$user_input" ]]; then
    # If no piped content, use additional note as the main input
    user_input="$additional_note"
  fi
  # Always use piping to avoid argument list too long errors
  if [ "$thinking" = true ]; then
    # Call structured_chain_of_thought if --think is specified
    reasoning=$(echo -e "$user_input" | structured_chain_of_thought --raw "${args[@]}")
    # Check if the response is empty
    if [[ -n "$reasoning" ]]; then
      # Append reasoning to the system prompt
      user_input+="<thinking>$reasoning</thinking>"
    else
      echo "Error: No reasoning provided" >&2
      return 1
    fi
  fi
  response=$(echo -e "$user_input" | llm -s "$system_prompt" --no-stream "${args[@]}")
  # Return raw response if requested
  if [ "$raw" = true ]; then
    echo "$response"
    return
  fi
  plan="$(echo "$response" | awk 'BEGIN{RS="<plan>"} NR==2' | awk 'BEGIN{RS="</plan>"} NR==1' | sed '/^ *#/d;/^$/d')"
  # check if plan is empty
  if [[ -z "$plan" ]]; then
    echo "$response"
    return
  fi
  if [ "$thinking_level" != "none" ]; then
    thinking="$(echo "$response" | awk 'BEGIN{RS="<think>"} NR==2' | awk 'BEGIN{RS="</think>"} NR==1')"
  fi
  echo "$plan"
}

# local system_prompt="$info\n\nwrite shell terminal commands to accomplish the task beautifully. The command will be run directly in the zsh terminal so code comments are not allowed. The command should be practical and effective, with a technical tone. code should be formatted in a code block, e.g.: \`\`\`bash" 
shelp () {
  local info="$(uname -a)" 
  local system_prompt="$(which shelp)\n\n$info"
  local thinking=false 
  local args=() 
  local raw=false
  if [ ! -t 0 ]; then
    local piped_content
    piped_content=$(cat) 
  fi
  while [[ $# -gt 0 ]]; do
    case "$1" in
      (--think) thinking=true  ;;
      (--raw) raw=true  ;;
      (*) args+=("$1")  ;;
    esac
    shift
  done
  if [ "$thinking" = true ]; then
    reasoning=$(echo -e "$piped_content" | structured_chain_of_thought --raw "${args[@]}") 
    if [[ -n "$reasoning" ]]; then
      system_prompt+="<thinking>$reasoning</thinking>" 
    else
      echo "Error: No reasoning provided" >&2
      return 1
    fi
  fi
  system_prompt="\n<SYSTEM>\n$system_prompt\n</SYSTEM>\n" 
  response=$(echo -e "$piped_content" | llm -s "$system_prompt" --no-stream "${args[@]}") 
  if [ "$raw" = true ]; then
    echo "$response"
    return
  fi
  # Uses the FIRST code block only and discards everything else.
  shelllm_commands="$(echo -E "$response" | awk 'BEGIN{RS="```zsh"} NR==2' | awk 'BEGIN{RS="```"} NR==1'  | sed '/^ *#/d;/^$/d')" 
  # if shelllm_commands is empty, display the response
  if [[ -z "$shelllm_commands" ]]; then
    if [[ -n "$response" ]]; then
      echo "Warning: Could not extract Zsh command from LLM response." >&2
      echo "Raw LLM response:" >&2
      echo "$response" >&2
    else
      echo "Error: LLM returned an empty response. No command to extract." >&2
    fi
    return 1 # Exit with error if no command was extracted
  fi
  echo "$shelllm_commands"
}

alias shelp-x='shelp_wrapper() { eval "$(shelp "$@")"; }; shelp_wrapper'
alias shelp-e='shelp_wrapper() { print -r -z "$(shelp "$@")"; }; shelp_wrapper'
alias shelp-p='shelp-e'
alias shelp-c='shelp-e'

shelp_v2 () {
    # Set options for Zsh: localoptions ensures settings are local to the function,
    # noksharrays enables 0-indexed arrays like bash.
    setopt localoptions noksharrays 2>/dev/null
    
    local system_prompt
    local thinking=false 
    local raw=false 
    local piped_content
    local user_query
    local query_parts=()
    local main_model=""
    local think_model=""
    
    # Combine system info for prompt; paste -sd ' ' ensures it's a single line if needed.
    system_prompt="$( (uname -a; which shelp) | paste -sd ' ' - )"
    
    if [ ! -t 0 ]; then
        piped_content=$(cat)
    fi
    
    local all_args_for_parsing=("$@")
    # Loop from 0 to actual number of arguments for 0-indexed processing
    local i=0 
    while (( i < ${#all_args_for_parsing[@]} )); do
        local arg="${all_args_for_parsing[$i]}"
        local next_arg_val=""
        
        # Check if there's a next argument AND it doesn't start with a hyphen (i.e., it's a value)
        if (( i + 1 < ${#all_args_for_parsing[@]} )) ; then
            if [[ ! "${all_args_for_parsing[$((i+1))]}" =~ ^- ]]; then
                next_arg_val="${all_args_for_parsing[$((i+1))]}"
            fi
        fi
        
        case "$arg" in
            (--think) thinking=true ;;
            (--raw)   raw=true ;;
            (-m | --model)
                if [[ -n "$next_arg_val" ]]; then
                    main_model="$next_arg_val"
                    ((i++)) # Increment i to consume the value
                else
                    echo "Error: $arg requires a model name" >&2
                    return 1
                fi ;;
            (-tm | --thinking-model)
                if [[ -n "$next_arg_val" ]]; then
                    think_model="$next_arg_val"
                    ((i++)) # Increment i to consume the value
                else
                    echo "Error: $arg requires a model name" >&2
                    return 1
                fi ;;
            # Remove or make no-op: Any flag not explicitly handled above will fall to (*),
            # which adds it to query_parts if it's a positional argument.
            (-*)      : ;; # Ignore unrecognized flags (or add them to query_parts if needed)
            (*)       query_parts+=("$arg") ;; # Capture non-flag arguments as part of the query
        esac
        ((i++)) # Move to the next argument
    done

    # Join query parts with a space
    user_query="${query_parts[*]}" # ${(j: :)query_parts} is a more Zsh-idiomatic way to join
    
    local full_input=""
    if [[ -n "$piped_content" ]]; then
        full_input="$piped_content"
        if [[ -n "$user_query" ]]; then
            full_input+="\n\n${user_query}"
        fi
    elif [[ -n "$user_query" ]]; then
        full_input="$user_query"
    else
        echo "Error: No query provided." >&2
        return 1
    fi
    
    local cot_llm_args=()
    [[ -n "$think_model" ]] && cot_llm_args+=("-m" "$think_model")
    local main_llm_call_args=()
    [[ -n "$main_model" ]] && main_llm_call_args+=("-m" "$main_model")
    
    if [ "$thinking" = true ]; then
        local reasoning
        reasoning=$(echo -e "$full_input" | structured_chain_of_thought --raw "${cot_llm_args[@]}") 
        local cot_status=$? 
        if [[ $cot_status -ne 0 ]]; then
            echo "Error: structured_chain_of_thought failed (exit code: $cot_status)" >&2
            return 1
        elif [[ -z "$reasoning" ]]; then
            echo "Error: Reasoning process produced no output." >&2
            return 1
        else
            system_prompt+="\n<think>$reasoning</think>" 
        fi
    fi
    
    local final_system_prompt="\n<SYSTEM>\n$system_prompt\n</SYSTEM>\n" 
    response=$(echo -e "$full_input" | llm -s "$final_system_prompt" --no-stream "${main_llm_call_args[@]}") 
    local llm_status=$? 
    if [[ $llm_status -ne 0 ]]; then
        echo "Error: LLM command failed (exit code: $llm_status)" >&2
        return 1
    fi
    
    if [ "$raw" = true ]; then
        echo "$response"
        return 0
    fi
    
    local shell_terminal_code
    # Enhanced extraction for various backtick code blocks
    if ! shell_terminal_code=$(echo -E "$response" | 
        awk 'BEGIN{RS="```(zsh|shell|bash)"} NR==2 {print; exit}' | 
        awk 'BEGIN{RS="```"} NR==1 {print; exit}' |
        sed -E '/^#/d; /^[[:space:]]*$/d'); then # Remove comments and empty lines
        echo "Command extraction failed" >&2
        return 1
    fi

    if [[ -z "$shell_terminal_code" ]]; then
        if [[ -n "$response" ]]; then
            echo "Warning: Could not extract Zsh command from LLM response." >&2
            echo "Raw LLM response:" >&2
            echo "$response" >&2
        else
            echo "Error: LLM returned an empty response. No command to extract." >&2
        fi
        return 1
    fi
    echo "$shell_terminal_code"
}

commit_generator() {
  # Generates a commit message based on the changes made in the git repository.
  # Usage: commit_generator [--thinking=none|minimal|moderate|detailed|comprehensive] [-m MODEL_NAME] [--note=NOTE|-n NOTE]
  local system_prompt="Write a sensible commit message for the changes made. The commit message should be concise and descriptive, with a technical tone. Include the following XML tags in your response: <commit_msg>...</commit_msg>"
  local thinking_level="none"
  local args=()
  local model=""
  local note=""
  local diff=""
  local raw=false
  
  
  # Process arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --thinking=*)
        thinking_level=${1#*=}
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
      --raw)
        raw=true
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
    
    if [ "$thinking_level" != "none" ]; then
      reasoning=$(echo -e "$diff" | structured_chain_of_thought --raw "${args[@]}")
      if [[ -n "$reasoning" ]]; then
        system_prompt+="<thinking>$reasoning</thinking>"
      else
        echo "Error: No reasoning provided" >&2
        return 1
      fi
    fi
    
    response=$(echo -e "$diff" | llm -s "$system_prompt" --no-stream "${args[@]}")
    if [ "$raw" = true ]; then
      echo "$response"
      return
    fi
    commit_msg="$(echo "$response" | awk 'BEGIN{RS="<commit_msg>"} NR==2' | awk 'BEGIN{RS="</commit_msg>"} NR==1')"
    
    if [ "$thinking_level" != "none" ]; then
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


novel_ideas_generator() {
  # ... existing function setup ...
  local system_prompt="You are a creative <brainstorm> assistant. Your task is to generate a list of unique ideas based directly on a user's query.

    Follow these steps to provide relevant ideas:
    1. Read the user's query carefully.
    3. Ensure each idea is practical and original (novel approaches or unique combinations of existing concepts, not common or cliché solutions).
    4. Keep each idea concise (1-2 sentences, maximum 500 characters per idea).

    <constraints>
      - Ideas must be strictly based on the given user query.
      - Each idea must be concise (1-2 sentences per idea).
      - Focus on practical and original solutions.
      - Original ideas should offer a novel approach, perspective, or combination of existing concepts. They should not be common, cliché, or readily found through a simple web search.
      - This prompt should be effective for any type of brainstorming task (product ideas, problem-solving, creative projects, etc.).
      - Format your response using the following XML structure, and provide no other text besides the XML response:
        <ideas>
          <item>First idea here...</item>
          <item>Second idea here...</item>
          ...
        </ideas>

        </brainstorm>
    </constraints>

    Example:
    <thinking>
    [Your reasoning process here]
    </thinking>
    <ideas>
    1. [First idea with brief explanation]
    2. [Second idea with brief explanation]
    ...etc.
    </ideas>

    Note: Your response should include between 5 and 10 ideas, all within the <brainstorm> tags."

  local thinking_level="none"
  local llm_args=() # Array to hold arguments specifically for the llm command
  local query_parts=() # Array to hold parts of the user query if not piped
  local count=10
  local raw=false
  local show_reasoning=false
  local user_input=""

  # Check if input is being piped
  if [ ! -t 0 ]; then
    user_input=$(cat)
  fi

  # Process arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --count=*)
        count=${1#*=}
        # Validate count is a number
        if ! [[ "$count" =~ ^[0-9]+$ ]]; then
          echo "Error: --count requires a number" >&2
          return 1
        fi
        system_prompt+=" <count>$count</count>"
        shift # Consume argument
        ;;
      --thinking=*)
        thinking_level=${1#*=}
        shift # Consume argument
        ;;
      --raw)
        raw=true
        shift # Consume argument
        ;;
      --show-reasoning)
        show_reasoning=true
        shift # Consume argument
        ;;
      # Explicitly handle known llm options
      -m)
        if [[ -n "$2" && ! "$2" =~ ^- ]]; then
          llm_args+=("$1" "$2") # Add -m and its value to llm_args
          shift 2 # Consume both arguments
        else
          echo "Error: $1 requires a model name" >&2
          return 1
        fi
        ;;
      # Add other llm options here if needed, e.g., -t for temperature
      # -t) ... llm_args+=("$1" "$2"); shift 2 ;;
      *)
        # If input is piped, unhandled args are llm args
        if [[ -n "$user_input" ]]; then
           llm_args+=("$1")
        else
           # If not piped, unhandled args are part of the query
           query_parts+=("$1")
        fi
        shift # Consume argument
        ;;
    esac
  done

  # If not piped, construct user_input from query_parts
  if [[ -z "$user_input" ]]; then
    if [[ ${#query_parts[@]} -eq 0 ]]; then
        echo "Error: No topic or question provided." >&2
        echo "Usage: brainstorm <topic or question> [options]" >&2
        echo "       cat topic.txt | brainstorm [options]" >&2
        return 1
    fi
    user_input="${query_parts[*]}"
  fi

  # Ensure user_input is not empty (this check might be redundant now)
  if [[ -z "$user_input" ]]; then
      echo "Error: No topic or question provided." >&2
      return 1
  fi

  if [ "$thinking_level" != "none" ]; then
    # Pass user_input for reasoning, and also pass llm_args
    # Assuming structured_chain_of_thought correctly passes its args array to llm
    reasoning=$(echo -e "$user_input" | structured_chain_of_thought --no-stream --raw "${llm_args[@]}")
    if [[ -n "$reasoning" ]]; then
      system_prompt+="<thinking>$reasoning</thinking>"
    else
      echo "Error: No reasoning provided" >&2
      return 1
    fi
  fi
  system_prompt="\n<SYSTEM>\n$system_prompt\n</SYSTEM>\n"
  # Call LLM, piping user_input and passing collected llm_args
  response=$(echo -e "$user_input" | llm -s "$system_prompt" --no-stream "${llm_args[@]}")

  # Return raw response if requested
  if [ "$raw" = true ]; then
    echo "$response"
    return
  fi

  # Extract ideas
  ideas="$(echo "$response" | awk 'BEGIN{RS="<ideas>"} NR==2' | awk 'BEGIN{RS="</ideas>"} NR==1' | sed 's/<item>//g; s/<\/item>/\n/g' | sed '/^[[:space:]]*$/d')"
  if [[ -z "$ideas" ]]; then
    echo "Warning: Could not extract ideas from the response." >&2
    echo "$response" # Show raw response if extraction fails
    return 1
  fi
  # Extract reasoning if available and requested
  if [ "$thinking_level" != "none" ] && [ "$show_reasoning" = true ]; then
    reasoning="$(echo "$response" | awk 'BEGIN{RS="<thinking>"} NR==2' | awk 'BEGIN{RS="</thinking>"} NR==1')"
    if [[ -n "$reasoning" ]]; then
        echo -e "\033[1;34mReasoning:\033[0m\n$reasoning\n"
    fi
  fi

  # Format output (numbered only)
  idea_count=1
  while IFS= read -r line; do
    echo "$idea_count. $line"
    ((idea_count++))
  done <<< "$ideas"
}

# Alias for ease of use
alias brainstorm=novel_ideas_generator

taste++ () {
  local system_prompt=$(cat "$script_dir/prompts/taste++.md") 
  local thinking=false 
  local args=() 
  local raw=false 
  if [ ! -t 0 ]
  then
    local piped_content
    piped_content=$(cat) 
  fi
  while [[ $# -gt 0 ]];  do
    case "$1" in
      (--think) thinking=true  ;;
      (--raw) raw=true  ;;
      (*) args+=("$1")  ;;
    esac
    shift
  done
  if [ "$thinking" = true ]; then
    reasoning=$(echo -e "$piped_content" | structured_chain_of_thought --raw "${args[@]}") 
    if [[ -n "$reasoning" ]]; then
      system_prompt+="<notes>$reasoning</notes>" 
    else
      echo "Error: No reasoning provided" >&2
      return 1
    fi
  fi
  response=$(echo -e "$system_prompt\n\n$piped_content" | llm --no-stream "${args[@]}") 
  if [ "$raw" = true ]; then
    echo "$response"
    return
  fi
  refined_text="$(echo "$response" | awk 'BEGIN{RS="<refined_text>"} NR==2' | awk 'BEGIN{RS="</refined_text>"} NR==1')" 
  if [[ -z "$refined_text" ]]; then
    echo "Warning: Could not extract refined prompt. Displaying raw response:" >&2
    echo "$response"
    return 1
  fi
  echo "$refined_text"
}


prompt_engineer() {
  # Helps craft and refine LLM prompts with suggestions for improvements.
   local system_prompt="You are a prompt engineering expert. Your task is to analyze the given prompt and suggest improvements to make it more effective for LLMs.

  Follow these steps:
  1. Analyze the provided prompt's structure, clarity, and specificity
  2. Identify weaknesses, ambiguities, or areas that could cause misunderstanding
  3. Suggest specific improvements with explanations
  4. Provide a refined version of the prompt

  Format your response with these XML tags:
  <analysis>Your analysis of the prompt's strengths and weaknesses</analysis>
  <improvements>
    <item>First improvement suggestion with explanation</item>
    <item>Second improvement suggestion with explanation</item>
    ...
  </improvements>
  <refined_prompt>Your improved version of the prompt</refined_prompt>"
  local thinking_level="none"
  local args=()
  local model=""
  local raw=false

  if [ ! -t 0 ]; then #
    local piped_content
    piped_content=$(cat)
  fi
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --thinking=*)
        thinking_level=${1#*=}
        ;;
      --raw)
        raw=true
        ;;
      *)
        args+=("$1")
        ;;
    esac
    shift
  done
  
  if [ "$thinking_level" != "none" ]; then
    reasoning=$(echo -e "$piped_content" | structured_chain_of_thought --raw "${args[@]}")
    if [[ -n "$reasoning" ]]; then
      system_prompt+="<thinking>$reasoning</thinking>"
    else
      echo "Error: No reasoning provided" >&2
      return 1
    fi
  fi
  system_prompt="\n<SYSTEM>\n$system_prompt\n</SYSTEM>\n"

  response=$(echo -e "$system_prompt\n\n$piped_content\n\n$system_prompt" | llm --no-stream "${args[@]}")

  if [ "$raw" = true ]; then
    echo "$response"
    return
  fi
  if [ "$thinking_level" != "none" ]; then
    thinking="$(echo "$response" | awk 'BEGIN{RS="<think>"} NR==2' | awk 'BEGIN{RS="</think>"} NR==1')"
  fi
  # Extract sections
  analysis="$(echo "$response" | awk 'BEGIN{RS="<analysis>"} NR==2' | awk 'BEGIN{RS="</analysis>"} NR==1')"
  improvements="$(echo "$response" | awk 'BEGIN{RS="<improvements>"} NR==2' | awk 'BEGIN{RS="</improvements>"} NR==1')"
  refined_prompt="$(echo "$response" | awk 'BEGIN{RS="<refined_prompt>"} NR==2' | awk 'BEGIN{RS="</refined_prompt>"} NR==1')"
  # check if analysis is empty
  if [[ -z "$analysis" && -z "$refined_prompt" ]]; then
    echo "Warning: Could not extract analysis or refined prompt. Displaying raw response:" >&2
    echo "$response"
    return 1
  fi
  # Display formatted output
  if [ "$thinking_level" != "none" ]; then
    if [[ -n "$thinking" ]]; then
      echo -e "\033[1;34m🧠 Thinking Process:\033[0m\n$thinking\n"
    fi
  fi
  if [[ -n "$analysis" ]]; then
    echo -e "\033[1;36mANALYSIS:\033[0m\n$analysis\n"
  fi
  if [[ -n "$improvements" ]]; then
    echo -e "\033[1;35mIMPROVEMENTS:\033[0m"
    count=1
    while IFS= read -r line; do
      trimmed_line=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//') # Trim leading and trailing whitespace
      if [[ -n "$trimmed_line" ]]; then
        echo "$count. $trimmed_line"
        ((count++))
      fi
    done <<< "$improvements"
    echo
  fi
  if [[ -n "$refined_prompt" ]]; then
    echo -e "\033[1;32mREFINED PROMPT:\033[0m\n$refined_prompt"
  fi
}


prompt_engineer_old() {
  # Helps craft and refine LLM prompts with suggestions for improvements.
  # Usage: prompt_engineer <existing_prompt> [--think] [-m MODEL_NAME] [--format=<format>] [--task=<task>]
  #        cat prompt.txt | prompt_engineer [--think] [-m MODEL_NAME] [--format=<format>] [--task=<task>]
  # Options:
  #   --think               Enable and display the reasoning process
  #   -m MODEL_NAME         Specify which LLM model to use
  #   --format=<format>     Output format (standard, detailed, structured)
  #   --task <task>         Specific task the prompt is for (classification, generation, etc.)

  local system_prompt="You are a prompt engineering expert. Your task is to analyze the given prompt and suggest improvements to make it more effective for LLMs.

  Follow these steps:
  1. Analyze the provided prompt's structure, clarity, and specificity
  2. Identify weaknesses, ambiguities, or areas that could cause misunderstanding
  3. Suggest specific improvements with explanations
  4. Provide a refined version of the prompt

  Format your response with these XML tags:
  <analysis>Your analysis of the prompt's strengths and weaknesses</analysis>
  <improvements>
    <item>First improvement suggestion with explanation</item>
    <item>Second improvement suggestion with explanation</item>
    ...
  </improvements>
  <refined_prompt>Your improved version of the prompt</refined_prompt>"

  local thinking=false # Use boolean flag for thinking
  local args=()
  local model=""
  local task=""
  local raw=false
  local user_prompt=""   # Initialize user_prompt
  local note=""          # Initialize note

  # Check if input is being piped
  if [ ! -t 0 ]; then
    local piped_content
    piped_content=$(cat)
  fi

  # Process arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --think)
        thinking=true
        ;;
      --raw)
        raw=true
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
      --task)
        if [[ -n "$2" && ! "$2" =~ ^- ]]; then
          task="$2"
          system_prompt+=" <task>$task</task>"
          shift
        else
          echo "Error: --task requires a task description" >&2
          return 1
        fi
        ;;
      *)
        args+=("$1")
        ;;
    esac
    shift
  done

  # If not piped, construct user_prompt from collected args
  user_prompt="$piped_content"
  if [[ -z "$piped_content" ]]; then
      if [[ ${#args[@]} -eq 0 ]]; then
          echo "Error: No prompt provided." >&2
          echo "Usage: prompt_engineer <prompt> [options]" >&2
          echo "       cat prompt.txt | prompt_engineer [options]" >&2
          return 1
      fi
      user_prompt="${args[*]}"
      args=() # Reset args if they were used for the prompt itself
  fi


  if [ "$thinking" = true ]; then # Check boolean flag
    # Pass user_prompt for reasoning, and also pass llm args
    # structured_chain_of_thought is called with --raw to get its reasoning output
    reasoning=$(echo -e "$user_prompt" | structured_chain_of_thought --raw "${args[@]}")
    local cot_status=$?
    if [[ $cot_status -ne 0 ]]; then
        echo "Error: Failed to generate reasoning (exit code: $cot_status)" >&2
        # Optionally return or proceed without reasoning
        return 1
    elif [[ -n "$reasoning" ]]; then
      # Append reasoning within <think> tags for the main LLM call
      system_prompt+="<think>$reasoning</think>"
    else
      echo "Warning: Reasoning process produced no output." >&2
      # Optionally return or proceed without reasoning
      # return 1
    fi
  fi
  # Call LLM
  system_prompt="\n<SYSTEM>\n$system_prompt\n</SYSTEM>\n"
  response=$(echo -e "$user_prompt" | llm -s "$system_prompt" --no-stream "${args[@]}")
  local llm_status=$?
   if [[ $llm_status -ne 0 ]]; then
    echo "Error: LLM command failed (exit code: $llm_status)" >&2
    return 1
  fi

  if [ "$raw" = true ]; then
    echo "$response"
    return
  fi
  # Extract sections
  analysis="$(echo "$response" | awk 'BEGIN{RS="<analysis>"} NR==2' | awk 'BEGIN{RS="</analysis>"} NR==1')"
  improvements="$(echo "$response" | awk 'BEGIN{RS="<improvements>"} NR==2' | awk 'BEGIN{RS="</improvements>"} NR==1' | sed 's/<item>//g; s/<\/item>/\n/g')"
  refined_prompt="$(echo "$response" | awk 'BEGIN{RS="<refined_prompt>"} NR==2' | awk 'BEGIN{RS="</refined_prompt>"} NR==1')"

  # Format output based on specified format
  if [ "$thinking" = true ]; then # Check boolean flag
    # Extract think from the *final* response (which should include the CoT reasoning if generated)
    thinking="$(echo "$response" | awk 'BEGIN{RS="<think>"} NR==2' | awk 'BEGIN{RS="</think>"} NR==1')"
    if [[ -n "$thinking" ]]; then # Check if thinking content exists
        echo -e "\033[1;34m🧠 Thinking Process:\033[0m\n$thinking\n"
    fi
  fi

  # check if analysis is empty and if so return the raw response
  if [[ -z "$analysis" && -z "$refined_prompt" ]]; then # Check both analysis and refined prompt
    echo "Warning: Could not extract analysis or refined prompt. Displaying raw response:" >&2
    echo "$response"
    return 1 # Indicate failure
  fi

  # Default standard format
  if [[ -n "$analysis" ]]; then
    echo -e "\033[1;36mPROMPT ANALYSIS:\033[0m\n$analysis\n"
  fi

  if [[ -n "$improvements" ]]; then
    echo -e "\033[1;33mIMPROVEMENT SUGGESTIONS:\033[0m"
    count=1
    while IFS= read -r line; do
      # Trim whitespace before checking if line is empty
      trimmed_line=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
      if [[ -n "$trimmed_line" ]]; then
        echo -e "$count. $trimmed_line"
        ((count++))
      fi
    done <<< "$improvements"
    # Add a newline after suggestions if there were any
    [[ $count -gt 1 ]] && echo ""
  fi

  if [[ -n "$refined_prompt" ]]; then
    echo -e "\033[1;32mREFINED PROMPT:\033[0m\n$refined_prompt"
  fi
}


structured_chain_of_thought() {
  # Breaks down complex problems using structured reasoning steps.
  # Usage: structured_chain_of_thought <problem description> [--think=none|minimal|moderate|detailed|comprehensive] [-m MODEL_NAME] [--steps=<steps>]
  #        cat problem.txt | structured_chain_of_thought [--think=none|minimal|moderate|detailed|comprehensive] [-m MODEL_NAME] [--steps=<steps>]
  # Options:
  #   --think=LEVEL       Control reasoning depth (none, minimal, moderate, detailed, comprehensive)
  #   -m MODEL_NAME          Specify which LLM model to use
  #   --steps=STEPS          Define custom reasoning steps (comma-separated)
  #   --raw                  Return the raw LLM response
  
  local system_prompt='You are a reasoning assistant that helps break down complex problems through structured thinking. Follow these steps meticulously:

1.  **Problem Understanding**:
    *   Restate the problem in your own words to confirm understanding.
    *   *Example*: "The user is asking to [specific task], which requires [key elements]."
    *   Validate alignment with the user’s intent before proceeding.
2.  **Approach Planning**:
    *   Outline a clear, step-by-step strategy using bullet points.
    *   *Example*: "1. Gather relevant data. 2. Apply [method]. 3. Validate results."
    *   Justify why this approach is suitable.
3.  **Step-by-Step Reasoning**:
    *   Execute your plan with numbered steps, showing calculations/logic.
    *   *Example*: "Step 1: [Action]. Step 2: [Calculation]."
    *   Highlight assumptions and potential pitfalls.
4.  **Alternative Perspectives**:
    *   Propose 2-3 distinct approaches or critiques of your main method.
    *   *Example*: "Alternative 1: Use [method X] for better accuracy. Con: Requires more time."

**Formatting Rules**:

*   Use XML tags exactly as specified:
    `<problem_understanding>...</problem_understanding>`
    `<approach>...</approach>`
    `<reasoning>...</reasoning>`
    `<alternatives>...</alternatives>`
*   Avoid markdown; keep content plain text within tags.
*   Adjust detail level based on problem complexity (e.g., minimal for simple tasks, detailed for ambiguous problems).

**Important Notes**: DO NOT write a final answer or conclusion. Your task is to provide a structured breakdown of the problem and reasoning process. The final answer will be generated separately.
'

  local thinking_level="none"
  local args=()
  local model=""
  local raw=false
  local custom_steps=""

  # Check if input is being piped
  if [ ! -t 0 ]; then
    local piped_content
    piped_content=$(cat)
  fi
  
  # Process arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --task)
        if [[ -n "$2" && ! "$2" =~ ^- ]]; then
          task="$2"
          system_prompt+="\n<task>\n$task\n</task>\n"
          shift
        else
          echo "Error: --task requires a task description" >&2
          return 1
        fi
        ;;
      --raw)
        raw=true
        ;;
      *)
        args+=("$1")
        ;;
    esac
    shift
  done

#   system_prompt+="
# <SYSTEM_PROMPT>
# Ensure that your main answer follows this format exactly:
# $system_prompt
# </SYSTEM_PROMPT>
# "  
  # Call LLM
  response=$(echo -e "$piped_content" | llm -s $system_prompt --no-stream "${args[@]}")
  
  # Return raw response if requested
  if [ "$raw" = true ]; then
    echo "$response"
    return
  fi
  
  # Extract sections
  problem_understanding="$(echo "$response" | awk 'BEGIN{RS="<problem_understanding>"} NR==2' | awk 'BEGIN{RS="</problem_understanding>"} NR==1')"
  approach="$(echo "$response" | awk 'BEGIN{RS="<approach>"} NR==2' | awk 'BEGIN{RS="</approach>"} NR==1')"
  reasoning="$(echo "$response" | awk 'BEGIN{RS="<reasoning>"} NR==2' | awk 'BEGIN{RS="</reasoning>"} NR==1')"
  alternatives="$(echo "$response" | awk 'BEGIN{RS="<alternatives>"} NR==2' | awk 'BEGIN{RS="</alternatives>"} NR==1')"
  conclusion="$(echo "$response" | awk 'BEGIN{RS="<conclusion>"} NR==2' | awk 'BEGIN{RS="</conclusion>"} NR==1')"
  
  
  # Display formatted output
  echo -e "\033[1;36m🔍 PROBLEM UNDERSTANDING:\033[0m\n$problem_understanding\n"
  echo -e "\033[1;33m🧩 APPROACH:\033[0m\n$approach\n"
  echo -e "\033[1;32m⚙️ REASONING:\033[0m\n$reasoning\n"
  echo -e "\033[1;35m🔄 ALTERNATIVE PERSPECTIVES:\033[0m\n$alternatives\n"
  echo -e "\033[1;31m✅ CONCLUSION:\033[0m\n$conclusion"
}

llm_smell_detector() {
  SYSTEM_PROMPT=$(cat "$script_dir/prompts/LLM_SMELL.md")

  local args=()
  local raw=false
  local piped_content=""

  # Check for piped input
  if [ ! -t 0 ]; then
    piped_content=$(cat)
  fi

  # Process arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --raw)
        raw=true
        ;;
      *)
        args+=("$1")
        ;;
    esac
    shift
  done

  # If no piped content, use first argument as input file
  if [[ -z "$piped_content" && ${#args[@]} -gt 0 && -f "${args[0]}" ]]; then
    piped_content=$(cat "${args[0]}")
    args=("${args[@]:1}")
  elif [[ -z "$piped_content" && ${#args[@]} -gt 0 ]]; then
    piped_content="${args[*]}"
    args=()
  fi

  if [[ -z "$piped_content" ]]; then
    echo "Error: No LLM output provided (pipe input or pass a file/argument)" >&2
    return 1
  fi

  response=$(echo -e "$piped_content" | llm -s "$SYSTEM_PROMPT" --no-stream "${args[@]}")

  if [ "$raw" = true ]; then
    echo "$response"
    return
  fi

  # --- Robust XML Parsing ---
  # Extract content within <smells>...</smells>
  smells_content=$(echo "$response" | awk '/<smells>/,/<\/smells>/' | sed '1d;$d')

  if [[ -z "$(echo "$smells_content" | tr -d '[:space:]')" ]]; then
    echo "Warning: Could not extract valid <smells> content from the response." >&2
    echo "--- Raw LLM Response ---"
    echo "$response"
    echo "------------------------"
    return 1
  fi

  count=1
  items_found=0
  echo -e "\033[1;36mDetected LLM Smells:\033[0m"

  # Split by </item>, clean up, and extract fields
  echo "$smells_content" | awk 'BEGIN{RS="</item>"; FS="\n"} /<item>/ {gsub(/^[[:space:]]*<item>[[:space:]]*/,""); print $0}' | while IFS= read -r item_block; do
    if [[ -z "$(echo "$item_block" | tr -d '[:space:]')" ]]; then
      continue
    fi

    smell=$(echo "$item_block" | awk -F'<smell>|</smell>' 'NF>1{print $2}' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    evidence=$(echo "$item_block" | awk -F'<evidence>|</evidence>' 'NF>1{print $2}' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    explanation=$(echo "$item_block" | awk -F'<explanation>|</explanation>' 'NF>1{print $2}' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    suggestion=$(echo "$item_block" | awk -F'<suggestion>|</suggestion>' 'NF>1{print $2}' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

    if [[ -z "$smell" ]]; then
      echo "Warning: Skipping malformed item block."
      continue
    fi

    items_found=1

    echo -e "\n\033[1;33m$count. $smell\033[0m"
    if [[ -n "$evidence" ]]; then
      echo -e "  \033[1;34mEvidence:\033[0m $evidence"
    fi
    if [[ -n "$explanation" ]]; then
      echo -e "  \033[1;32mExplanation:\033[0m $explanation"
    fi
    if [[ -n "$suggestion" ]]; then
      echo -e "  \033[1;35mSuggestion:\033[0m $suggestion"
    fi
    ((count++))
  done

  if [[ $items_found -eq 0 ]]; then
    echo "No smells detected, or failed to parse items within the <smells> block."
  fi
}


bash_script_generator() {
  if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    echo "Usage: bash_script_generator <description> [options]"
    echo "       cat description.txt | bash_script_generator [options]"
    echo ""
    echo "Options:"
    echo "  --thinking=LEVEL     Set thinking level (none|minimal|moderate|detailed|comprehensive)"
    echo "  --save[=FILENAME]    Save script to file (prompts if filename not given)"
    echo "  --auto-save[=FILE]   Automatically save script (default: script.sh if not specified)"
    echo "  --posix              Generate POSIX-compliant shell script (#/bin/sh)"
    echo "  --advanced           Request advanced features (error handling, logging etc.)"
    echo "  --preview            Preview script without saving (outputs to stderr)"
    echo "  -m, --model NAME     Specify which LLM model to use"
    echo "  -n, --note TEXT      Add additional instructions or context"
    echo "  --raw                Output raw LLM response without processing"
    echo "  -h, --help           Show this help message"
    return 0
  fi

  local system_prompt="You are a bash script generator specializing in creating well-structured, robust shell scripts.

For any given description, you'll create a complete bash script following these best practices:
- Always include proper shebang (#!/bin/bash or #!/bin/sh for POSIX)
- Only a few code comments to organize the script logically.
- Implement proper error handling (set -eo pipefail where appropriate) and input validation
- Use meaningful variable names with consistent naming conventions
- Follow defensive programming practices
- Include proper command-line argument parsing with help text if appropriate
- Add comprehensive usage documentation and examples
- Break complex functionality into well-named functions
- Use 'local' for variables inside functions
- Properly quote variables and handle special characters
- Include useful logging and debug capabilities when appropriate (--advanced)
- Consider security implications (avoid command injection, use mktemp for temp files)

Your script must be directly usable, thoroughly commented, and handle edge cases gracefully.
Format your response with the script inside markdown code blocks: \`\`\`bash ... \`\`\`"

  local thinking_level="none"
  local llm_args=()
  local script_desc=()
  local user_input=""
  local additional_note=""
  local raw=false
  local posix=false
  local advanced=false
  local preview=false
  local save_flag=false
  local auto_save=false
  local save_filename=""

  # Check if input is being piped
  if [ ! -t 0 ]; then
    user_input=$(cat)
  fi

  # Process arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --think|--thinking=*)
        if [[ "$1" == "--think" ]]; then
          thinking_level="moderate" # Default thinking level for --think
        else
          thinking_level=${1#*=}
        fi
        if [[ ! "$thinking_level" =~ ^(none|minimal|moderate|detailed|comprehensive)$ ]]; then
          echo "Error: Invalid thinking level '$thinking_level'. Must be none, minimal, moderate, detailed, or comprehensive." >&2
          return 1
        fi
        ;;
      -n|--note)
        if [[ -n "$2" && ! "$2" =~ ^- ]]; then
          additional_note="$2"
          shift
        else
          echo "Error: -n/--note requires additional text" >&2
          return 1
        fi
        ;;
      --raw)
        raw=true
        ;;
      --posix)
        posix=true
        system_prompt+=$'\n<constraint>Create a POSIX-compliant shell script (#/bin/sh shebang) that runs on most Unix-like systems.</constraint>'
        ;;
      --advanced)
        advanced=true
        system_prompt+=$'\n<constraint>Create an advanced script with comprehensive error handling, detailed logging, command-line options, and robust validation.</constraint>'
        ;;
      --preview)
        preview=true
        ;;
      --save*)
        save_flag=true
        if [[ "$1" == *=* ]]; then
            save_filename="${1#*=}"
        # Check if next arg is a filename (doesn't start with -), handles --save filename
        elif [[ -n "$2" && ! "$2" =~ ^- ]]; then
            save_filename="$2"
            shift
        fi
        ;;
     --auto-save*)
        auto_save=true
        if [[ "$1" == *=* ]]; then
            save_filename="${1#*=}"
        # Check if next arg is a filename, handles --auto-save filename
        elif [[ -n "$2" && ! "$2" =~ ^- ]]; then
            save_filename="$2"
            shift
        fi
        save_filename="${save_filename:-script.sh}" # Default filename for auto-save
        ;;
      -m|--model)
        if [[ -n "$2" && ! "$2" =~ ^- ]]; then
          llm_args+=("-m" "$2")
          shift
        else
          echo "Error: -m/--model requires a model name" >&2
          return 1
        fi
        ;;
      *)
        # If no piped content yet, assume it's part of the description
        if [[ -z "$user_input" ]]; then
          script_desc+=("$1")
        # Otherwise, pass unrecognized args to llm
        else
          llm_args+=("$1")
        fi
        ;;
    esac
    shift
  done

  # If no piped input, build description from command-line arguments
  if [[ -z "$user_input" && ${#script_desc[@]} -gt 0 ]]; then
    user_input="${script_desc[*]}"
  fi

  # Combine description with additional notes if provided
  if [[ -n "$additional_note" ]]; then
      if [[ -n "$user_input" ]]; then
        user_input+=$'\n\nAdditional instructions:\n'"$additional_note"
      else
        user_input="$additional_note" # Use note as input if nothing else provided
      fi
  fi

  # Ensure we have some input description
  if [[ -z "$user_input" ]]; then
    echo "Error: No script description provided." >&2
    echo "Usage: bash_script_generator <description> [options]" >&2
    echo "       cat description.txt | bash_script_generator [options]" >&2
    echo "       Use --help for more information" >&2
    return 1
  fi

  # Apply structured reasoning if thinking is enabled
  if [[ "$thinking_level" != "none" ]]; then
    echo "Analyzing requirements and planning script structure (Level: $thinking_level)..." >&2
    reasoning=$(echo -e "$user_input" | structured_chain_of_thought --raw "${llm_args[@]}")
    local cot_status=$?
    if [[ $cot_status -ne 0 ]]; then
      echo "Error: Failed to generate reasoning (exit code: $cot_status)" >&2
      # Decide whether to proceed without reasoning or exit
      # return 1
      echo "Warning: Proceeding without reasoning analysis." >&2
    elif [[ -n "$reasoning" ]]; then
      system_prompt+=$'\n\n<thinking>\n'"$reasoning"$'\n</thinking>'
      echo "Reasoning analyzed successfully." >&2
    else
      echo "Warning: Reasoning process produced no output for level '$thinking_level'." >&2
    fi
  fi

  # Prepare system prompt with proper tags
  system_prompt="\n<SYSTEM>\n$system_prompt\n</SYSTEM>\n"

  # Call LLM to generate the script
  echo "Generating script..." >&2
  response=$(echo -e "$user_input" | llm -s "$system_prompt" --no-stream "${llm_args[@]}")
  local llm_status=$?
  if [[ $llm_status -ne 0 ]]; then
    echo "Error: LLM command failed (exit code: $llm_status)" >&2
    return 1
  fi
  echo "Script generation complete." >&2

  # Return raw response if requested
  if [ "$raw" = true ]; then
    echo "$response"
    return 0
  fi

  # Extract script using awk (simpler approach)
  # Extracts content between ```bash, ```sh, ```shell, or ``` and ```
  echo "Extracting script from response..." >&2
  script=""
  for lang in bash sh shell ''; do
      # Use awk to find the block delimited by ```[lang] ... ```
      # Uses a flag 'p' to print lines within the block.
      script=$(echo "$response" | awk -v lang="$lang" '
          BEGIN { p=0 }
          $0 ~ "^```" lang { if (p==0) {p=1; next} else {p=0} }
          p==1 { print }
      ')
      [[ -n "$script" ]] && break # Stop if script found
  done

  # If no code blocks found, show warning and raw response (or optionally return the whole response)
  if [[ -z "$script" ]]; then
    echo "Warning: Could not extract script from markdown code blocks." >&2
    echo "Raw LLM response:" >&2
    echo "--------------------------------------------------------" >&2
    echo "$response" >&2
    echo "--------------------------------------------------------" >&2
    # Optionally return the raw response if no blocks found:
    # echo "$response"
    # return 0
    return 1 # Indicate failure to extract
  fi

  # Clean up the script (remove leading/trailing whitespace) - keep empty lines for structure
  script="$(echo "$script" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
  echo "Script extracted successfully." >&2

  # Display script with formatting if in preview mode
  if [ "$preview" = true ]; then
    echo -e "\n\033[1;36m# Generated Script (Preview Mode)\033[0m" >&2
    echo "--------------------------------------------------------" >&2
    echo "$script" >&2
    echo "--------------------------------------------------------" >&2
    return 0
  fi

  # Handle auto-save option
  if [ "$auto_save" = true ]; then
    # Add .sh extension if not already present
    [[ ! "$save_filename" == *.sh ]] && save_filename="${save_filename}.sh"

    echo "Auto-saving script to '$save_filename'..." >&2
    echo "$script" > "$save_filename"
    local save_status=$?
    if [[ $save_status -ne 0 ]]; then
      echo "Error: Failed to auto-save script to '$save_filename'" >&2
      # Output script to stdout as fallback?
      echo "$script"
      return 1
    fi

    chmod +x "$save_filename"
    echo -e "\033[1;32mScript auto-saved to $save_filename and made executable\033[0m" >&2
    return 0
  fi

 # Handle save with prompt option
  if [ "$save_flag" = true ]; then
    # Prompt for filename if not provided via command line
    if [[ -z "$save_filename" ]]; then
      echo -e "\n\033[1;33mEnter filename to save script (default: script.sh):\033[0m " >&2
      read -r reply_filename </dev/tty # Read directly from terminal
      save_filename=${reply_filename:-script.sh}
    fi

    # Add .sh extension if not already present
    [[ ! "$save_filename" == *.sh ]] && save_filename="${save_filename}.sh"

    # Check if file exists and prompt for overwrite
    if [[ -f "$save_filename" ]]; then
      echo -e "\033[1;31mWarning: File '$save_filename' already exists.\033[0m" >&2
      echo -e "\033[1;33mOverwrite? (y/n):\033[0m " >&2
      read -r overwrite </dev/tty

      if [[ ! "$overwrite" =~ ^[Yy] ]]; then
        echo "Operation cancelled. Script not saved." >&2
        # Output script to stdout as fallback?
        echo "$script"
        return 0
      fi
    fi

    # Save to file
    echo "Saving script to '$save_filename'..." >&2
    echo "$script" > "$save_filename"
    local save_status=$?
    if [[ $save_status -ne 0 ]]; then
      echo "Error: Failed to save script to '$save_filename'" >&2
      # Output script to stdout as fallback?
      echo "$script"
      return 1
    fi

    chmod +x "$save_filename"
    echo -e "\033[1;32mScript saved to $save_filename and made executable\033[0m" >&2

    # Offer to open in editor
    echo -e "\033[1;33mOpen in editor? (y/n):\033[0m " >&2
    read -r edit_response </dev/tty

    if [[ "$edit_response" =~ ^[Yy] ]]; then
      ${EDITOR:-vi} "$save_filename" </dev/tty
    fi
    return 0
  fi

  # Default behavior: Output script to stdout
  echo "$script"

}

# Add alias for ease of use
alias genscript=bash_script_generator

mermaid_charts() {
  # Generates mermaid charts from a description in markdown.
  # Usage: mermaid_charts <description> [options]
  #        cat description.txt | mermaid_charts [options]
  # Options:
  #   --think=FALSE|TRUE  Enable COT reasoning process
  #   --output-thinking=TRUE|FALSE  Output reasoning process
  #   -m MODEL_NAME          Specify which LLM model to use
  #   --raw                  Return the raw LLM response

  
  local system_prompt="You are a diagram generator that creates mermaid charts from a description. Follow these steps:
  Study the provided examples to understand the format and structure of mermaid charts.
  Analyze the given data or description and identify the key components to represent in the chart.
  Generate a mermaid chart in the specified format, ensuring it is clear and easy to understand.
  Format your response with the chart inside markdown code blocks: \`\`\`mermaid ... \`\`\`"
  local args=()
  local raw=false
  local piped_content=""
  local user_prompt=""
  local think=false
  local output_thinking=false
  local reasoning=""
  local FEW_SHOT_PROMPT="$(cat "$script_dir/prompts/mermaid_diagrams.md")"

  # Check if input is being piped
  if [ ! -t 0 ]; then
    piped_content=$(cat)
  fi
  # Process arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --think|--thinking=*)
        if [[ "$1" == "--think" ]]; then
          think=true # Default thinking level for --think
        else
          think=${1#*=}
        fi
        ;;
      --output-thinking)
        output_thinking=true
        ;;
      --raw)
        raw=true
        ;;
      *)
        # If not piped, collect arguments as the prompt
        if [[ -z "$piped_content" ]]; then
           args+=("$1")
        else
           # If piped, remaining args are for llm
           args+=("$1")
        fi
        ;;
    esac
    shift
  done

  # If not piped, construct user_prompt from collected args
  user_prompt="$piped_content"
  if [[ -z "$piped_content" ]]; then
      if [[ ${#args[@]} -eq 0 ]]; then
          echo "Error: No description provided." >&2
          echo "Usage: mermaid_charts <description> [options]" >&2
          echo "       cat description.txt | mermaid_charts [options]" >&2
          return 1
      fi
      user_prompt="${args[*]}"
      args=() # Reset args if they were used for the prompt itself
  fi
  # If thinking is enabled, use structured_chain_of_thought
  if [[ "$think" = true ]]; then
    reasoning=$(echo -e "$user_prompt" | structured_chain_of_thought --raw "${args[@]}")
    local cot_status=$?
    if [[ $cot_status -ne 0 ]]; then
        echo "Error: Failed to generate reasoning (exit code: $cot_status)" >&2
        # Optionally return or proceed without reasoning
        return 1
    elif [[ -n "$reasoning" ]]; then
      system_prompt+=$'\n\n<thinking>\n'"$reasoning"$'\n</thinking>'
    else
      echo "Warning: Reasoning process produced no output." >&2
      # Optionally return or proceed without reasoning
      # return 1
    fi
  fi
  # CONTSTRUCT prompt and FEW_SHOT_PROMPT to llm
  system_prompt="\n<SYSTEM>\n$system_prompt\n</SYSTEM>\n"
  # FEW_SHOT to user_prompt
  user_prompt="$FEW_SHOT_PROMPT\n\n$user_prompt"
  # Call LLM
  response=$(echo -e "$user_prompt" | llm -s "$system_prompt" --no-stream "${args[@]}")
  local llm_status=$?
  if [[ $llm_status -ne 0 ]]; then
    echo "Error: LLM command failed (exit code: $llm_status)" >&2
    return 1
  fi
  if [ "$raw" = true ]; then
    echo "$response"
    return
  fi
  # Extract sections
  chart="$(echo "$response" | awk 'BEGIN{RS="```mermaid"} NR==2' | awk 'BEGIN{RS="```"} NR==1')"
  # check if chart is empty and if so return the raw response
  if [[ -z "$chart" ]]; then # Check both analysis and refined prompt
    echo "Warning: Could not extract chart. Displaying raw response:" >&2
    echo "$response"
    return 1 # Indicate failure
  fi
  
  if [[ "$output_thinking" = true ]]; then
    echo -e "\nThinking Process:\n$reasoning\n"
  fi
  echo "$chart"
  return 0
}
# Add alias for ease of use
alias mermaid=mermaid_charts
