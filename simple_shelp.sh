simple_shelp() {
    local info="$(uname -a)"
    local myuuid="$(uuidgen)"
    local shelp_prompt="$info
    $myuuid
    Return carefully crafted shell terminal commands between \`\`\`bash code fence. Return only ONE code block. To accomplish:"
    local thinking=false
    local args=()
    local raw=false
    local execute=false
    [ ! -t 0 ] && local piped_content && piped_content=$(cat)
    while [[ $# -gt 0 ]]; do
    case "$1" in
        (--think) thinking=true ;;
        (--raw) raw=true ;;
        (-x) execute=true ;;
        (*) args+=("$1") ;;
    esac
    shift
    done
    # add piped_content to the prompt
    shelp_prompt+="\n\n$piped_content"
    response=$(echo -e "$shelp_prompt" | llm --no-stream "${args[@]}" -o stop '```   
    ')
    [ "$raw" = true ] && { echo "$response"; return; }
    local commands
    commands="$(echo -E "$response" | awk 'BEGIN{RS="```"} NR==2' | awk 'BEGIN{RS="\n```"} NR==1' | sed '1d')"
    [ "$execute" = true ] && eval "$commands" || echo "$commands"
}
