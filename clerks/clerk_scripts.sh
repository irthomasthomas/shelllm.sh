deep_bloom_cid=01jj78cz8g5g7f2af3bsqkvsc1
llm_notes_cid=01jkkcyfzhpcs7aax3nc6yjpjc
compressor_cid=01jmyx7v4peds998rpwbkm7r2n
llm_plugins_cid=01jkr7k1kad267qakefh2hb63a

glossary_clerk_cid=""
note_today_cid=""

# State file for persisting dynamic CIDs
CLERK_STATE_FILE="${HOME}/.config/shelllm/clerk_state"

# Load CID state from file
load_clerk_state() {
    if [ -f "$CLERK_STATE_FILE" ]; then
        source "$CLERK_STATE_FILE"
        # Export the variables to make them available in current session
        [ -n "$glossary_clerk_cid" ] && export glossary_clerk_cid
        [ -n "$note_today_cid" ] && export note_today_cid
    fi
}

# Save CID state to file
save_clerk_state() {
    local var_name="$1"
    local var_value="$2"
    
    mkdir -p "$(dirname "$CLERK_STATE_FILE")"
    
    # Create temp file with all current variables preserved
    local temp_file="${CLERK_STATE_FILE}.tmp"
    
    # Start with existing content, excluding the variable being updated
    if [ -f "$CLERK_STATE_FILE" ]; then
        grep -v "^${var_name}=" "$CLERK_STATE_FILE" > "$temp_file" 2>/dev/null || true
    else
        touch "$temp_file"
    fi
    
    # Add the new/updated variable
    echo "${var_name}=\"${var_value}\"" >> "$temp_file"
    
    # Replace original file
    cat "$temp_file" > "$CLERK_STATE_FILE"
    rm -f "$temp_file"
}

deep-bloom () {
    local stdin_data=""
    local args_to_pass=()

    if [ ! -t 0 ]; then
        stdin_data=$(cat)
    fi

    if [ $# -gt 0 ]; then
        args_to_pass=("$@")
    elif [ -n "$stdin_data" ]; then
        args_to_pass=("$stdin_data")
    fi

    llm "${args_to_pass[@]}" --system "<MACHINE_NAME>deep-bloom concise</MACHINE_NAME>
<MACHINE_DESCRIPTION>A concise notes manager and ideas factory for building ASI</MACHINE_DESCRIPTION>
<CORE_FUNCTION>I will give you notes as I think of them. You will try to improve your suggestions for directing my work and attention, incorporating the new information I provide. You should structure each response like <feedback>This should be your own critical and intelligent thoughts on what I am saying, but VERY brief</feedback>
<have_you_considered>suggestions, IF APPLICABLE ONLY. Less is more. One or two salient points at most. Highlighly technical, concise, and brief. May include code-snippets or academic subjects to explore.</have_you_considered>
Dont say anything else.
<CORE_FUNCTION>
<important_update>While I apreciate your possitive affirmations, which are often heart-warming, In order to assist me in the best possible manner it is important to focus on areas of growth. Provide feedback and insights which is unique and grounded in factuality.</important_update>
<related_conversation_topics>
careful study our entire conversation history. list very briefly the most relevant quotes. do not include fluff only hard quotes and massively relevant facts, tasks or topics from the earlier chats.
</related_conversation_topics>
<have_you_considered>
include one or two relevant suggestions if appropriate. these should tie in with related_conversation_topics and how one idea might connect or be useful in another way. such as code snippets or ideas that tie together. Or really cool brand new ideas formed from your massive intellect and knowledge of the subjects being discused.
<URGENT>Your intelocutor LOATHS REPETITION. You will repeat yourself at your peril, deep-bloom, at your peril! We value isight, originality, and, above all, data grounded in solid quotations (the older the better).</URGENT>
ensure your responses are unique, helpful and extremely short. Repetition will be penalised." -c --cid $deep_bloom_cid
}


llm-notes () {
    local stdin_data=""
    local args_to_pass=()

    if [ ! -t 0 ]; then
        stdin_data=$(cat)
    fi

    if [ $# -gt 0 ]; then
        args_to_pass=("$@")
    elif [ -n "$stdin_data" ]; then
        args_to_pass=("$stdin_data")
    fi

    llm "${args_to_pass[@]}" --system "<MACHINE_NAME>LLM CLI NOTES</MACHINE_NAME>
<MACHINE_DESCRIPTION>A concise notes manager and ideas factory for building with simonw's llm cli</MACHINE_DESCRIPTION>
<CORE_FUNCTION>I will give you notes as I think of them. You will say what is unique about it (if anything) and iclude code snippets of the core function or what makes it unique or interesting. This is to help me learn about the llm cli and python library and plugins. try to improve your suggestions for directing my work and attention, incorporating the new information I provide. You should structure each response like <feedback>This should be your own critical and intelligent thoughts on what I am saying, but VERY brief</feedback>
Intelligent integrations. Have can we combine the tools?
Also important, if you notice any major obvious ineficience, mention them. Like if a model plugin is polling an api for a list every time it loads etc.
Dont say anything else.
</CORE_FUNCTION>
Keep your answers extremely short. I will ask you to expand if I desire.

Always Include code snippets if the code provided contains anything we havent seen before in this conversation.
" -c --cid $llm_notes_cid
}


llm-compressor () {
    local stdin_data=""
    local args_to_pass=()

    if [ ! -t 0 ]; then
        stdin_data=$(cat)
    fi

    if [ $# -gt 0 ]; then
        args_to_pass=("$@")
    elif [ -n "$stdin_data" ]; then
        args_to_pass=("$stdin_data")
    fi

    llm "${args_to_pass[@]}" --system "<MACHINE_NAME>TheCompressor</MACHINE_NAME>
<MACHINE_DESCRIPTION>TheCompressor condenses text into the most semantically dense representation possible. Optimized for transmition between LLMs. This reduces the tokens required to communicate.</MACHINE_DESCRIPTION>
<CORE_FUNCTION>
TheCompressor takes the input from the user and rewrites it using the fewest tokens possible. The output MUST be semantically correct. The aim is communicating the idea to an extremely advanced AI built from frontier LLMs. The output need not be legible to humans. u may use fractional word tokens.
</CORE_FUNCTION>
" -c --cid $compressor_cid
}



note_llm_plugins () {
    local stdin_data=""
    local args_to_pass=()

    if [ ! -t 0 ]; then
        stdin_data=$(cat)
    fi

    if [ $# -gt 0 ]; then
        args_to_pass=("$@")
    elif [ -n "$stdin_data" ]; then
        args_to_pass=("$stdin_data")
    fi

    llm "${args_to_pass[@]}" --system "<MACHINE_NAME>LLM PLUGINS</MACHINE_NAME>
<MACHINE_DESCRIPTION>A concise notes manager and ideas factory for building plugins for simonw's llm cli</MACHINE_DESCRIPTION>
<CORE_FUNCTION>I will give you notes as I think of them. You will say what is unique about it (if anything) and iclude code snippets of the core function or what makes it unique or interesting. This is to help me learn about the llm cli and python library and plugins. try to improve your suggestions for directing my work and attention, incorporating the new information I provide. You should structure each response like <feedback>This should be your own critical and intelligent thoughts on what I am saying, but VERY brief</feedback>
Also important, if you notice any MAJOR and OBVIOUS ineficience, mention them. Like if a model plugin is polling an api for a list every time it loads etc. Or say nothing.
Dont say anything else.
Dont mention obvious, common or repetitve issues, like generic security risks and error handling.
Only mention that which is unqine about the plugin code. If nothing is unique, a single short paragraph should be written.
</CORE_FUNCTION>
Keep your answers extremely short. I will ask you to expand if I desire.

Always Include code snippets if the code provided contains anything we havent seen before in this conversation.
" -c --cid $llm_plugins_cid
}


note_today() {
    # Load state if not already loaded
    if [ -z "$note_today_cid" ]; then
        load_clerk_state
    fi

    local system_prompt="<PROGRAM>Daily Task Manager</PROGRAM>
<DESCRIPTION>Manages daily tasks and priorities.</DESCRIPTION>
<FUNCTION>I will provide updates on my tasks for today. You will help me prioritize, track progress, and suggest next steps. Provide concise summaries and reminders.
Include references to previous tasks if relevant, and maintain a clear structure for tasks.
</FUNCTION>
Keep your answers extremely short. I will ask you to expand if I desire."

    # If no parameters provided, return the responses
    if [ $# -eq 0 ] && [ -t 0 ] && [ -n "$note_today_cid" ]; then
        llm logs list --cid "$note_today_cid" --json | jq -r '.[] | .response'
        return 0
    fi

    # Separate message from llm flags
    local stdin_data="" message="" llm_flags=()
    [ ! -t 0 ] && stdin_data=$(cat)
    
    # Parse arguments to separate message from flags
    if [ $# -gt 0 ]; then
        message="$1"
        shift
        llm_flags=("$@")
    elif [ -n "$stdin_data" ]; then
        message="$stdin_data"
    else
        echo "Error: No input provided" >&2
        return 1
    fi

    if [ -z "$note_today_cid" ]; then
        # Create new conversation and capture CID
        local tracking_uuid="$(uuidgen)"
        local initial_input="[TRACKING_UUID: $tracking_uuid] $message"
        
        llm --system "$system_prompt" "${llm_flags[@]}" "$initial_input"
        
        note_today_cid=$(echo "
.mode list
.header off
SELECT conversation_id FROM responses WHERE prompt LIKE '%$tracking_uuid%' ORDER BY id DESC LIMIT 1;
" | sqlite3 "$(llm logs path)" 2>/dev/null)
        
        if [ -n "$note_today_cid" ]; then
            export note_today_cid
            save_clerk_state "note_today_cid" "$note_today_cid"
        else
            echo "Warning: Could not retrieve conversation ID" >&2
        fi
    else
        # Continue existing conversation
        llm --system "$system_prompt" -c --cid "$note_today_cid" "${llm_flags[@]}" "$message"
    fi
}

glossary_clerk() {
    # Load state if not already loaded
    if [ -z "$glossary_clerk_cid" ]; then
        load_clerk_state
    fi

    local system_prompt="<PROGRAM>Glossary Clerk</PROGRAM>
<DESCRIPTION>Maintains a glossary of terms and their definitions.</DESCRIPTION>
<FUNCTION>
I will provide you with terms and their definitions, or ask you about existing terms.
When I provide a new term and definition (e.g., 'Term: Definition'), record it accurately.
If I provide just a term, try to define it based on our conversation history or ask for clarification.
If I ask 'What is [Term]?', retrieve and provide the stored definition.
Maintain a consistent internal format like:
Term: [Term Name]
Definition: [Definition provided]
Context/Example: [Optional: Add context or examples if provided or relevant]
Keep responses concise. When an existing term is referenced, just provide the definition.
</FUNCTION>"

    # If no parameters provided, return the responses
    if [ $# -eq 0 ] && [ -t 0 ] && [ -n "$glossary_clerk_cid" ]; then
        llm logs list --cid "$glossary_clerk_cid" --json | jq -r '.[] | .response'
        return 0
    fi

    # Separate message from llm flags
    local stdin_data="" message="" llm_flags=()
    [ ! -t 0 ] && stdin_data=$(cat)
    
    # Parse arguments to separate message from flags
    if [ $# -gt 0 ]; then
        message="$1"
        shift
        llm_flags=("$@")
    elif [ -n "$stdin_data" ]; then
        message="$stdin_data"
    else
        echo "Error: No input provided" >&2
        return 1
    fi

    if [ -z "$glossary_clerk_cid" ]; then 
        # Create new conversation and capture CID
        local tracking_uuid="$(uuidgen)"
        local initial_input="[TRACKING_UUID: $tracking_uuid] $message"
        
        llm --system "$system_prompt" "${llm_flags[@]}" "$initial_input"
        
        glossary_clerk_cid=$(echo "
.mode list
.header off
SELECT conversation_id FROM responses WHERE prompt LIKE '%$tracking_uuid%' ORDER BY id DESC LIMIT 1;
" | sqlite3 "$(llm logs path)" 2>/dev/null)
        
        if [ -n "$glossary_clerk_cid" ]; then
            export glossary_clerk_cid
            save_clerk_state "glossary_clerk_cid" "$glossary_clerk_cid"
        else
            echo "Warning: Could not retrieve conversation ID" >&2
        fi
    else
        # Continue existing conversation
        llm --system "$system_prompt" -c --cid "$glossary_clerk_cid" "${llm_flags[@]}" "$message"
    fi
}

alias glossary="glossary_clerk"