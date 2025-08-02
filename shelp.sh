#!/usr/bin/env bash
#Good example.
shelp() {
    local info
    info=$(uname -a)
    local system_prompt
    system_prompt=$(cat <<EOF
<SYSTEM_INFO>
$info
</SYSTEM_INFO>

<ROLE>
You are a bash terminal expert. Your task is to generate perfect executable shell commands based on the user's request and your knowledge of the system.
</ROLE>

<INSTRUCTIONS>
- Provide only the shell command.
- Do not include any additional text, explanations, or markdown formatting outside of the specified tags.
- If the task is complex you need to reason about best solutions, use the <THINK> tag for your reasoning. This reasoning will not be part of the final command output.
- Format your final response with the command inside a code block with the language specified (e.g., zsh, bash, etc.).
</INSTRUCTIONS>

<EXAMPLES>
<EXAMPLE>
<USER_REQUEST>
Command to patch the file and resolve the "unbound variable" error.
</USER_REQUEST>
\`\`\`
sed -i '113s/AGENT_CONTROLLER_MODELS/&:-claude-4-sonnet,gemini-2.5-pro-or-ai-studio-no-reasoning/' "\$HOME/Projects/mytools.sh"
\`\`\`
</EXAMPLE>
<EXAMPLE>
<USER_REQUEST>
Command to efficiently search for a specific string in a file.
</USER_REQUEST>
\`\`\`
grep -i 'search_string' /path/to/file.txt
\`\`\`
</EXAMPLE>
</EXAMPLES>

<TASK>
Write a single shell command to accomplish the following task:
</TASK>
EOF
)
    local thinking=false raw=false execute=false edit=false continue_conversation=false inception=false
    local state_file="/tmp/shelp_last_execution.log"
    local piped_content=""
    local think_model=""
    local args=()

    # Handle piped input
    if [ ! -t 0 ]; then
        piped_content=$(cat)
    fi    # Parse arguments

    local temp_args=("$@")
    for arg in "${temp_args[@]}"; do
        case "$arg" in
            -c) continue_conversation=true ;;
            --think) thinking=true ;;
            --raw) raw=true ;;
            -x|--execute) execute=true ;;
            -e|--edit) edit=true ;;
            -i|--inception) inception=true ;;
            -tm|--thinking-model)
                # Get next argument as model name
                shift
                if [[ -n "$1" && ! "$1" =~ ^- ]]; then
                    think_model="$1"
                    thinking=true
                else
                    echo "Error: $arg requires a model name" >&2
                    return 1
                fi ;;
            *) args+=("$arg") ;;
        esac
        shift
    done

    # Handle continue_conversation after parsing
    if [ "$continue_conversation" = true ] && [[ -f "$state_file" ]]; then
        local last_execution_output
        last_execution_output=$(cat "$state_file")
        if [[ -n "$last_execution_output" ]]; then
            piped_content+="$(printf "<LAST_COMMAND_OUTPUT>\n%s\n</LAST_COMMAND_OUTPUT>\n\n" "$last_execution_output")"
        fi
        true > "$state_file"
    fi

    
    # If inception is enabled, add the exemplar prompt to the system prompt
    [ "$inception" = true ] && system_prompt="$(which shelp)"

    # Thinking step
    if [ "$thinking" = true ]; then
        local cot_llm_args=()
        [[ -n "$think_model" ]] && cot_llm_args+=("-m" "$think_model")
        prompt="$(echo -e "$system_prompt\n\n$piped_content")"
        reasoning=$(echo -e "$prompt" | structured_chain_of_thought --raw "${args[@]}" "${cot_llm_args[@]}")
        if [[ -n "$reasoning" ]]; then
            system_prompt+="\n<THINK>\n$reasoning\n</THINK>"
        else
            echo "Error: No reasoning provided" >&2
            return 1
        fi
    fi

    # Get LLM response
    response=$(echo -e "$piped_content" | llm -s "$system_prompt" --no-stream "${args[@]}")

    if [ "$raw" = true ]; then
        echo "$response"
        return
    fi

    # Extract shell command
    local shelllm_commands=""
    
    for lang in zsh bash ''; do
        shelllm_commands="$(echo -E "$response" | awk "BEGIN{RS=\"\`\`\`$lang\"} NR==2" | awk "BEGIN{RS=\"\`\`\`\"} NR==1" | sed '/^ *#/d;/^$/d')"
        [[ -n "$shelllm_commands" ]] && break
    done


    if [[ -z "$shelllm_commands" ]]; then
        if [[ -n "$response" ]]; then
            error="Warning: Could not extract Zsh or Bash command from LLM response."
            echo "$error" >&2
            echo "Raw LLM response:" >&2
            echo "$response" >&2
        else
            echo "Error: LLM returned an empty response. No command to extract." >&2
        fi
        return 1
    fi
    # Mode handling
    if [ "$execute" = true ]; then
      # Print command for visibility
      echo "$shelllm_commands"

      # Add command to history
      if [[ -n "$ZSH_VERSION" ]]; then
        # For Zsh
        print -s "$shelllm_commands"
      elif [[ -n "$BASH_VERSION" ]]; then
        # For Bash
        history -s "$shelllm_commands"
      fi

      # Execute the command, capture its output/error, and display it  
      local execution_output
      execution_output=$(eval "$shelllm_commands" 2>&1)
      echo "$execution_output"
      # Save the output for a potential subsequent shelp call with -c
      echo "$execution_output" > "$state_file"
    elif [ "$edit" = true ]; then
      if [[ -n "$ZSH_VERSION" ]]; then
        print -r -z "$shelllm_commands"
      elif [[ -n "$BASH_VERSION" ]]; then
        # In Bash, just print it for copy-paste
        echo "$shelllm_commands"
      fi
    else
      echo "$shelllm_commands"
    fi
}



# Update aliases to use the new flags
alias shelp-x='shelp --execute'
alias shelp-e='shelp --edit'
alias shelp-p='shelp --edit'
alias shelp-c='shelp --edit'