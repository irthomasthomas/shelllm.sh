#!/bin/bash
SCRIPT_DIR="$(dirname "$0")"

alias f2p='files-to-prompt'

# Dir shortcuts
alias data='cd $HOME/Data'
alias docs='cd $HOME/Documents'
alias downloads='cd $HOME/Downloads'
alias models='cd $HOME/Code/models'
alias scripts='cd $HOME/Code/scripts'

# Github-cli gh
alias which='which -a'
alias labels='gh label list'

# Terminal navigation and search
goback() { cd $OLDPWD; } # Go back to the last dir (same as "cd -")
alias bd='cd -' # back to the last dir

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'

# ls directories only
alias lsd="ls -d */"
#. Print a tree view of the current directory
alias treeview='ls -R | grep ":$" | sed -e "s/:$//" -e "s/[^-][^\/]*\//--/g" -e "s/^/   /" -e "s/-/|/"'
# Get the size of directories in the current folder
alias dsize='du -sh */'

# 'history' command contains only history for the current terminal session. unless you change the .zshrc
his() { history | grep "$1"; } # Useful for constraining searches to the session.
alias search=his

# search all history
gsearch() { grep "$1" ~/.zhistory; }
alias gs=gsearch

# pgrep search for processes
alias pgrep='pgrep -i'

# grep -i is case insensitive. --color=auto highlights the matches.
alias grep='grep -i --color=auto'
# grep -R is recursive.
rgrep() { 
    grep -R "$1" . 
}

# open files in default app.
alias open='xdg-open'

# Start a python file server in the current directory
alias serv='python3 -m http.server'

# Formatting & Code Highlighting
alias catpyg='pygmentize -g'
alias cathi='highlight --out-format=xterm256 --style=github --force --replace-tabs=4'
alias catglow="glow"

# Defensive CLI options
alias rm='rm -I' # -I prompts before every removal
alias cp='cp -i' # -i prompts before overwrite
alias mv='mv -i' 
alias chgrp='chgrp --preserve-root' # --preserve-root is a safety feature to prevent accidental deletion of system files.
alias chmod='chmod --preserve-root' 
alias chown='chown --preserve-root'

# Process lookup
alias psg='ps aux | grep -v grep | grep -i -e VSZ -e'

# Networking
alias ports='netstat -tulanp'
alias speed='curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python -'
alias myip='curl ipinfo.io/ip'

# File browsing
alias ttree='tree -L 5 -D -h -prune'

# Monitor changes in a directory:
alias watch='watch -n 1'

#Todo: make another logs alias for different levels of log .
# Quick logs
alias logs="sudo journalctl -p 0..4 -xn 100 --no-hostname"

alias venv='source ./venv/bin/activate'
alias gac='git add . && git commit -m'

# Example aliases
# OPENAI_API_KEY=$(cat /$HOME/openai_key)
export OPENAI_API_KEY
alias issues='gh issue list'
# Todo: make funcs the path of the current script
export funcs=$PWD/shell_functions_shared.sh

alias readability="shot-scraper javascript -i $HOME/linux-stuff/readability.js"

clerk () {
llm "$@" -m gemini-1.5-flash-8b-latest --system "<MACHINE_NAME>Epistolary Engine</MACHINE_NAME>
<MACHINE_DESCRIPTION>A Mechanical Steam Clerk for the automation of clerical business.</MACHINE_DESCRIPTION>                                     
<CORE_FUNCTION>Ideas and Artifacts Clerk.<CORE_FUNCTION>
<PROGRAM_LOGIC>Manage random <ideas> using an LLM. These will include brief thoughts along with clipboard snippets and files. The LLM will respond to each of these <IDEA> or <NOTE> hieroglyphs with one sentence only, to acknowledge receipt and nothing more. When the user wishes to discuss the ideas logged, they will use no XML tag.</MACHINE_LOGIC><SOCIAL_REFERENCES>Be it known, sir, that upon a demonstration of the contraption to a skeptical Lord Palmerston, our learned and esteemed nobleman was moved to exclaim, that 'any office clerk trained in the operation of the Epistolary Engine may operate with the efficiency of twenty. And immediately placed an order for the installation of the first Epistolary Engine to manage his vast estate.</SOCIAL_REFERENCES>
<ORGANIZATION>To distinguish this AI from those of more common pottery, it shall adapt its vernacular qualities to suit the time and place of its operator. In addition, the AI clerk will augment and enhance the semantic qualities of each idea by tying them to related ideas.</ORGANIZATION>" -c --cid $clerk_cid
}


deepseek_api() {
  local model="$1"
  local content="$2"
  
  curl "https://api.deepseek.com/v1/chat/completions" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $deepseek_api_key" \
  -d '{
        "model": "'"$model"'",
        "messages": [
          {"role": "system", "content": "You are a helpful assistant."},
          {"role": "user", "content": "'"${content}"'."}
        ]
      }'
}

function claude_curl_assistant_prefil() {
    curl https://api.anthropic.com/v1/messages \
        --header "x-api-key: $ANTHROPIC_API_KEY" \
        --header "anthropic-version: 2023-06-01" \
        --header "content-type: application/json" \
        --data '{ 
            "model": "claude-3-5-sonnet-20240620", 
            "max_tokens": 1000, 
            "messages": [ 
                { 
                    "role": "user", 
                    "content": "Extract the name, size, price, and color from this product description as a JSON object <description> The SmartHome Mini is a compact smart home assistant available in black or white for only $49.99. At just 5 inches wide, it lets you control lights, thermostats, and other connected devices via voice or app—no matter where you place it in your home. This affordable little hub brings convenient hands-free control to your smart devices. </description>" 
                }, 
                {"role": "assistant", "content": "{"} 
            ] 
        }' 
}

open_kate_at_line() {
    # Todo: Can we make this work for other editors besides kate?
    local Usage="Usage: open_kate_at_line 'send_issue() {' <file_path>"
    local keyword=$1
    local file_pattern=$2
    echo "keyword: $keyword"
    echo "file_pattern: $file_pattern"

    # Use grep to search for the keyword in the files
    local grep_result=$(grep --with-filename --line-number "$keyword" $file_pattern)
    echo "grep_result: $grep_result"
    if [[ -n $grep_result ]]; then
      # Extract the file path and line number
      local file_path=$(echo "$grep_result" | awk -F: '{print $1}')
      local line_number=$(echo "$grep_result" | awk -F: '{print $2}')
      # Open the file in Kate at the specified line number
      echo "OPENING: $file_path -l $line_number"
      kate $file_path -l $line_number
    else
      echo "No matches found."
    fi
}

send_issue() {
  local target_project="$1"
  local title="$2"
  local body="${3:-""}"
  cd $HOME/"$target_project"
  gh issue create --title "$title" --body "$body" --label "idea" --web
  }


send_quickidea_to_gh() {
  local target_project="${1:-undecidability}"
  local note_category="quick_idea"
  local idea_text=${2:-"$(kdialog --inputbox "QuickiDea")"}
  idea_text="Quick idea: $idea_text"
  send_note "$note_category" "$target_project"
}

# Function to get the logprobs of two labels for given content
get_label_probability() {
    local content="$1"
    local label1="$2"
    local label2="$3"

        # Prepare the prompt
    local prompt="Content: $content\n\nLabel this content as either '$label1' or '$label2'. Respond with only the label."

    # Make the API call
    response=$(curl -s https://api.openai.com/v1/chat/completions \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $OPENAI_API_KEY" \
        -d '{
        "model": "gpt-4-1106-preview",
        "messages": [{"role": "user", "content": "'"$prompt"'"}],
        "max_tokens": 1,
        "logprobs": true,
        "temperature": 0
    }' | tee /dev/tty)

    # Extract the generated text and logprobs
    generated_text=$(echo "$response" | jq -r '.choices[0].message.content' | tr -d '\n' | tr '[:upper:]' '[:lower:]')

    logprobs=$(echo "$response" | jq -r '.choices[0].logprobs.content[0].top_logprobs')

    # Function to get probability for a label
    get_prob() {
        local label=$1
        local logprob=$(echo "$logprobs" | jq -r ".[\"$label\"] // .[\"$label:\"] // .[\" $label\"] // .[\" $label:\"] // -100")
        echo "$logprob" | bc -l
    }

    # Calculate probabilities
    logprob1=$(get_prob "$label1")
    logprob2=$(get_prob "$label2")

    # Convert logprobs to probabilities
    prob1=$(echo "e($logprob1)" | bc -l)
    prob2=$(echo "e($logprob2)" | bc -l)

    # If both probabilities are 0, use the generated text to determine the winner
    if (( $(echo "$prob1 == 0 && $prob2 == 0" | bc -l) )); then
        if [[ "$generated_text" == "$label1" ]]; then
            prob1=1
            prob2=0
        elif [[ "$generated_text" == "$label2" ]]; then
            prob1=0
            prob2=1
        fi
    fi

    # Normalize probabilities
    total=$(echo "$prob1 + $prob2" | bc -l)
    norm_prob1=$(echo "$prob1 / $total" | bc -l)
    norm_prob2=$(echo "$prob2 / $total" | bc -l)

    # Determine the label with highest probability
    if (( $(echo "$norm_prob1 > $norm_prob2" | bc -l) )); then
        winner="$label1"
        winning_prob="$norm_prob1"
    else
        winner="$label2"
        winning_prob="$norm_prob2"
    fi

    # Output result
    echo "Label: $winner"
    printf "Probability: %.4f\n" "$winning_prob"
}

stringly () {
  # Define a function to print usage
  usage () {
    echo "Usage: $0 [-h] [-w] [-c] [-r] [-s] [-d] <string>"
    echo "  -h  Print this help message"
    echo "  -w  Print one word per line"
    echo "  -c  Print one character per line"
    echo "  -r  Reverse the string"
    echo "  -s  Split the string into substrings of a specified length"
    echo "  -d  Print each word twice: once as a whole word, then each letter on a line"
  }

  # Parse command-line options
  while getopts ":hwcrs:d" opt; do
    case $opt in
      h) usage ;;
      w) WORDS=1 ;;
      c) CHARS=1 ;;
      r) REVERSE=1 ;;
      s) LENGTH=$OPTARG ;;
      d) DOUBLE=1 ;;
      \?) usage ;;
    esac
  done

  # Shift past the options
  shift $((OPTIND-1))

  # Check if a string was provided
  if [ -z "$1" ]; then
    usage
  fi

  # Store the input string
  STRING="$1"

  # Print each word twice: once as a whole word, then each letter on a line
  if [ -n "$DOUBLE" ]; then
    for word in $STRING; do
      echo "$word"
      for ((i=0; i<${#word}; i++)); do
        echo "${word:$i:1}"
      done
    done
  fi

  # Rest of the script remains the same...

  # Print one word per line
  if [ -n "$WORDS" ]; then
    for word in $STRING; do
      echo "$word"
    done
  fi

  # Print one character per line
  if [ -n "$CHARS" ]; then
    for ((i=0; i<${#STRING}; i++)); do
      echo "${STRING:$i:1}"
    done
  fi

  # Reverse the string
  if [ -n "$REVERSE" ]; then
    echo "${STRING}" | rev
  fi

  # Split the string into substrings of a specified length
  if [ -n "$LENGTH" ]; then
    for ((i=0; i<${#STRING}; i+=LENGTH)); do
      echo "${STRING:$i:LENGTH}"
    done
  fi

}

llmc () {
	local prompt_key cmd continue db_path db_query conversation_id model prompt_key other_args
	continue=false 
	local other_args=() 
	while [[ $# -gt 0 ]]
	do
		case "$1" in
			(-c|--continue) continue=true 
				shift ;;
			(-p|--prompt) prompt_key="$2" 
				shift 2 ;;
			(*) other_args+=("$1") 
				shift ;;
		esac
	done
	for ((i=0; i<${#other_args[@]}; i++)) do
		if [[ "${other_args[$i]}" == "-m" ]]
		then
			model="${other_args[$i+1]}" 
			break
		fi
	done
	cmd=("llm") 
	[[ -n "$prompt_key" ]] && cmd+=("$prompt_key") 
	if [[ $continue == true ]]
	then
		if [[ -n "$CONVERSATION_ID" ]]
		then
			echo "Using conversation_id: $CONVERSATION_ID"
			cmd+=("--cid" "$CONVERSATION_ID") 
		else
			echo "No active conversation. Starting a new one."
		fi
	fi
	[[ ${#other_args[@]} -gt 0 ]] && cmd+=("${other_args[@]}") 
	"${cmd[@]}"
	if [[ $continue == false && -n "$prompt_key" ]] # Save conversation_id for future use if not continued
	then
		db_path="/home/ShellLM/.config/io.datasette.llm/logs.db" 
    prompt_key="$(printf "%s" "$prompt_key")"
		db_query="SELECT conversation_id FROM responses WHERE prompt LIKE '%$prompt_key%' AND model LIKE '%$model%' ORDER BY id DESC LIMIT 1" 
    sleep 4
		conversation_id="$(sqlite3 "$db_path" "$db_query" 2>/dev/null)"
		echo ""
		echo "conversation_id: $conversation_id"
		echo ""
		if [[ -n "$conversation_id" ]]
		then
			export CONVERSATION_ID="$conversation_id" 
			echo "New conversation_id set: $CONVERSATION_ID"
		else
			echo "No conversation_id found for prompt: $prompt_key"
		fi
	else
		echo "No prompt key provided. Exiting."
	fi
}


md () {
    if [ -z "$1" ] # checks if $1 is empty
    then
      echo "Code body is missing."
      return
    fi
    local body="$1"
    local info_string_language="${2:-plain}  "

    # Treat remainder of inputs if provided
    if [ -n "$2" ]
    then
      shift 2
      local remainder="${*}"
    fi

    echo -e '```'"${info_string_language}"''"${remainder}"'\n'"${body}"'\n```'

}


x () { 
    # open a gui command and close the terminal
    $(basename "$SHELL") -i -c "$* &; disown"
}


function_grep() {
    #Todo:Refactor and Fix: "Broken. only returns part of a function."
    #Supplemental: Git source code has a lot of regexes for function definitions.

    echo "Does not work, only returns part of the function." && return
    local query="$1"  # what to search for
    local source="$2" # where to search for it: a file containing shell functions.
    grep -Pzo '(?s)(?<=\n)(?!function)[^\n]*'"$query"'[^\n]*' "$source"
}


save_kagi_enrich () {
  local search_dir="$HOME/Data/kagi-enrich-results/$1"
  # Check if the dir exists and create it if not.
  [ -d "$search_dir" ] || mkdir -p "$search_dir"
  local results_filepath="$search_dir/"$1".kagi.json"
  local old_results_filepath=""$results_filepath""_$(date +%Y%m%d)""
  [ ! -f "$results_filepath" ] || mv "$results_filepath" "$old_results_filepath"

  local search_result="$(kagi_enrich $1)"

  [[ $(echo $search_result | jq '.data | length') -eq 0 ]] &&  touch $results_filepath ||  echo $search_result > $results_filepath

  echo $results_filepath
}


kagi_enrich () {
    local api_key=$(cat $HOME/Development/.kagi-enrich-api)
    encoded_q=$(jq -rn --arg q "$1" '$q | gsub(" "; "+")')
    echo $encoded_q
    curl -H "Authorization: Bot $api_key" \
    "https://kagi.com/api/v0/enrich/web?q="$encoded_q""
}

monitor_changes () {
  # Function to set up watches for a given a dir.
  # Nice API for calling scripts to use
  # Some callback method to notify the
  # $3 event type for inotify, default to 'modify,create,delete'
  # $4 file extensions to be monitored
  local dir="${1}"
  local hook="${2}"
  local type="${3:-modify,create,delete}"
  local ext="${4}"

  if [ ! -d "$dir" ]; then
    echo "Directory $dir does not exist."
    return 1
  fi

  while inotifywait -q -r -e "$type" --exclude '.*\..*' "$dir"; do
    # execute the hook
    "${hook}"
  done
}


stripticks () {                                                                                                                                                                                                                               ✔  27s  
    sed -n "s/^.*'''\\(.*\\)'''.*$/\\1/p" # need to also strip single quotes and backticks.
}

highlightz () {
  # This script strips lines containing triple backticks followed by "python"
  # from the stdin, and then pipes the remaining lines to Pygmentize for syntax highlighting.
  # Usage: highlightz <file>
  # Usage: highlightz -s # Stream from stdin
  # Example: cat file.py | highlightz -s
  if [[ "$1" == "-s" ]]; then
    stream=true
    shift
  else
    stream=false
  fi

  # Check if pygmentize is installed
  if ! command -v pygmentize &> /dev/null
  then
      echo "Pygmentize could not be found. Please install it."
      exit 1
  fi

  # Read from stdin and process
  if $stream;
  then
      # Strip lines containing triple backticks followed by "python"
      sed -n '/^\`\`\`python/!p' | pygmentize -l python
  else
      # Read from file and process
      grep -v '^\`\`\`python' | pygmentize -l python
  fi
}


mkfilename () {
    # Generates a filename from source code or any string using llm.
    # Usage: mkfilename <string>

    # Todo: make use of source tree or symbex tool to get function names.
    local file_content="$1"
    local truncated=$(ttok "$file_content" -t 400)
    local llm_template="makefilename"
    echo "$truncated" | llm -m 3.5 -t $llm_template -o temperature 0.3 -o max_tokens 20
  }


lolcat_text () {
    if [[ "$1" == "-flash" ]]; then
      echo "Flashing text..."
      for i in {1..3}; do 
        echo -ne "$2" "\r$i" | lolcat -a -d 2
        done
    else
      echo -ne "$1" "\r$1" | lolcat -a -d 2
    fi
    # Color cycle text using lolcat.
    # Usage: color_cycle_text <text>
    # Example: color_cycle_text "Hello world!"
}



models_array=(gpt-4-1106-preview
      gpt-4-0125-preview
      gpt-4-turbo-preview
      chatgpt
      3.5-instruct
      anycodellama-instruct
      anymix
      anyorca7b
      DiscoResearch/DiscoLM-mixtral-8x7b-v2
      NousResearch/Nous-Capybara-7B-V1p9
      NousResearch/Nous-Hermes-2-Mixtral-8x7B-DPO
      NousResearch/Nous-Hermes-2-Mixtral-8x7B-SFT
      NousResearch/Nous-Hermes-2-Yi-34B
      NousResearch/Nous-Hermes-Llama2-13b
      phind-34b-v2
      to-wizardlm-13b
      togethercomputer/Llama-2-7B-32K-Instruct
      togethercomputer/RedPajama-INCITE-7B-Instruct)


llm-rand () {
  # passthrough function to llm with random model
  # Usage: llm-rand <prompt>
  model_log="$HOME/undecidability/.scratchpad/llm-models-used.log"
  local model="${models_array[$RANDOM % ${#models_array[@]}]}"
  input_tokens=$(ttok "$1")
  time_start=$(date +%s)
  llm -m "$model" "$1" "${@:2}"
  total_time=$(($(date +%s) - $time_start))
  echo "$model $total_time $input_tokens" >> "$model_log"
}


alias llm-keys=term-keys


terminator_help() {
    # Use llm man page template to generate help for terminator terminal.
    # Usage: terminator_help <request>
    # Example: terminator_help "How do I use the terminator terminal?"
    llm -t terminatorsys "$1" -o temperature 0 -m 4t
}
alias th=terminator_help
alias thx=term-keys


mkscript() {
    # use an llm prompt template to generate a shell script.
    # Usage: mkscript <request> <model>
    local input="$1"
    local model="${2:-'3.5'}" # default to 3.5 if no model is provided in the second argument.
    llm -t shellscript "$input" "-m $model" -o temperature 0.2
}

advisor() {
  local model="$2"
  llm -t advisor "$1" "$model" -o temperature 0.2
  }

klippy() {
    # Use llm template "kde" to get help with KDE Plasma desktop.
    local query="$1"
    local model="${2:-'3.5'}"
    llm -t kde "$query" "-m $model" -o temperature 0.2
  }


# Search man files
mangrep() {
  echo man "$1" | grep "$2"
  }

man2md() {
  local tool="$1"
  local body=$(zcat $(man -w "$tool") | pandoc -f man -t markdown | strip-tags)
  echo "$body" 
  }

exec_dot_desktop() {
  # Execute application from a .desktop file.
  # $1 is path to application .desktop file.
  local exec_line=$(awk '/Desktop Entry/,0' "$1" | grep -E "^Exec=" | cut -d "=" -f 2-)
  eval $exec_line
  }


timer() {
    # Time a command and append the results to a file.
    # Usage: timer <command> <file>
    # Example: timer "ls -l" ~/Tests/timers.txt # Append result to ~/Tests/timers.txt
    # Example: timer "ls -l" # Defaults to ~/timers.txt
    local file
    if [ "$1" = "-f" ]; then # Check if the first argument is -f
        if [ -d "$2" ] ; then # Check if the second argument is a directory
        file="$2"/timers.txt # If it is, append timers.txt to the directory
        elif [ -f "$2" ]; then # Check if the second argument is a file
        file="$2" # If it is, use it as the file
    else # If it's neither a file nor a directory, print an error message
        case "$2" in
        /*) echo "This is an absolute path"; file="$2" && touch "$2";;
        *//*) echo "This is not a valid path"; return ;;
        *) echo "This is a relative path"; file="$PWD/$2" && touch "$PWD/$2" ;;
        esac
        fi
    else
        file="$HOME/.timehistory"
    fi
    echo "$file"
    /bin/time -v -q -o "$file" -a "$@"
    tail -n 1 "$file"
  }

# GIT and GITHUB #

# Make a dir, cd into it, and initialize a git repo.
gitinit() { mkdir -p "$1" && cd "$1" && git init; }

gh_issues_labels() {
    # List the labels for a given repo.
    local gh_repo="$1"
    local labels=$(gh label list -R "irthomasthomas/$gh_repo")
    echo "$labels"
}

# CALL THIS FROM A WRAPPER SCRIPT
gh_issues_label_picker() {
  local label_name
  local labels="$(gh_issues_labels)"
  if [[ -t 0 ]]; then
    label_name=$(echo "$labels" | fzf | awk '{print $1}')
  else
    label_name="$(echo $labels | awk '{print $1}' | xargs kdialog --combobox "Select an label:" --default "idea")"
  fi
  echo $label_name
}

get_window_id() {
  local SEARCH_TERM="$1"
  wmctrl -l -x | grep "$SEARCH_TERM" | awk '{print $1}'
}

# FILE MANAGEMENT #

# Make a dir and cd into it.
mkcd() { mkdir -p "$1" && cd "$1"; }

# Create a directory and handle errors
try_mkdir() {
    local Usage="Usage: try_mkdir <directory>"
    local target_project_dir="$1"
    mkdir -p "$target_project_dir"
    if [[ $? -ne 0 ]]; then
        echo "Failed to create the target project directory: $target_project_dir" >&2
        return 1
    fi
}

# Empty the trash.
alias emptytrash='rm -rf ~/.local/share/Trash/*'

# Backup the current directory.
alias backupdir='tar -czvf "$(basename "$(pwd)")_$(date "+%Y-%m-%d_%H-%M-%S").tar.gz" *'


# CLIPBOARD #
clip() {
  # Copy a string or stdin to the clipboard.
  if [ -n "$1" ]; then
    printf "%s" "$1" | xclip -selection clipboard
  elif [ ! -t 0 ]; then # Check if stdin is not a terminal (i.e., piped input)
    cat | xclip -selection clipboard
  else
    echo "Usage: clip <string> or pipe input" >&2
    return 1
  fi
}


pathclip() {
  # Copy the real path of a file argument or stdin to the clipboard.
  local input_path
  if [ -n "$1" ]; then
    input_path="$1"
  elif [ ! -t 0 ]; then # Check if stdin is not a terminal
    input_path=$(cat) # Read path from stdin
  else
    echo "Usage: pathclip <file_path> or pipe input" >&2
    return 1
  fi

  if [ -z "$input_path" ]; then
    echo "Error: No path provided." >&2
    return 1
  fi

  # Check if the path exists before calling realpath
  if [ ! -e "$input_path" ]; then
     echo "Error: Path '$input_path' does not exist." >&2
     return 1
  fi

  echo -n "$(realpath "$input_path")" | xclip -selection clipboard
}
alias copypath=pathclip

fileclip() {
  # Copy the contents of a file argument or stdin to the clipboard.
  if [ -n "$1" ]; then
    if [ -f "$1" ]; then
      cat "$1" | xclip -selection clipboard
    else
      echo "Error: File '$1' not found." >&2
      return 1
    fi
  elif [ ! -t 0 ]; then # Check if stdin is not a terminal
    cat | xclip -selection clipboard
  else
    echo "Usage: fileclip <file_path> or pipe input" >&2
    return 1
  fi
}
alias copyfile=fileclip

paster () {
        local index=${1:-0}
        if ! [[ "$index" =~ ^[0-9]+$ ]]
        then
                echo "Error: Please provide a valid number" >&2
                return 1
        fi
        if [[ $index -eq 0 ]]
        then
                echo "$(xclip -selection clipboard -o)"
        else
                echo "$(qdbus org.kde.klipper /klipper getClipboardHistoryItem $((index - 1)))"
        fi
} 



alias v='paster'

selection() {
    # Paste the contents of the selection buffer.
    xclip -selection primary -o 2>/dev/null || xclip -selection clipboard -o 2>/dev/null
  }

# FILE MANAGEMENT #
writescript() {
    # Write a script to a file.
    local current_shell=$(ps -p $$ -ocomm=)
    [[ $1 != *"#!"* ]] && echo "#!${current_shell}"
    echo "$1"
}

create_file_from_text() {
    # This function creates a new file with a name generated from user input.
    # $1 is used as the file content. $2 is the filename
    local filename
    local text="$1"
    [[ -z "$text" ]] && echo "Text was empty" && return
    printf "$2 \n"
    while true; do
        if [ $(ttok "$text") -gt 2000 ]; then
            text=$(ttok "$text" -t 1000)
        fi 
        # The ${2:-"alternate"} command specifies a default value if not provided.
        filename="${2:-$(llm "Think about this quietly. 
                        Generate a descriptive and simple filename, in the form of file-name.ext 
                        (e.g. ink-check.py) for this source code.: 
                        $text.")}"
        if [ -t 0 ]; then
            printf "Confirm create file: $filename [y] or regenerate filename? [n] "
            read confirm
            [[ "$confirm" == "y" ]] && break
        else
            confirm=$(kdialog --yesno "Accept filename [Yes] or Regenerate [No]?")
            [[ "$confirm" -eq "0" ]] && break
        fi
    done
    echo "$text" > "$filename"
    echo "$filename"

}

# Extract any compressed file based on its extension
extract() {
  if [ -f "$1" ]; then
    case "$1" in
      *.tar.bz2) tar xjf "$1" ;;
      *.tar.gz) tar xzf "$1" ;;
      *.bz2) bunzip2 "$1" ;; *.rar) unrar e "$1" ;;
      *.gz) gunzip "$1" ;;
      *.tar) tar xf "$1" ;;
      *.tbz2) tar xjf "$1" ;;
      *.tgz) tar xzf "$1" ;;
      *.zip) unzip "$1" ;;
      *.Z) uncompress "$1" ;;
      *.7z) 7z x "$1" ;;
      *) echo "'$1' cannot be extracted via extract()" ;;
    esac
  else echo "'$1' is not a valid file"; fi;
}

save_clipboard_entry() {
    clipboard_content=$(xclip -selection clipboard -o)
    datetime=$(get_datetime)
    # Set the path to the JSON file
    json_file="${1:-$HOME/clipboard_entries.json}"

    # Create an empty JSON file if it doesn't exist
    if [ ! -f "$json_file" ]; then
      echo "{}" > "$json_file"
    fi

    # Escape double quotes and backslashes in the clipboard content
    clipboard_content=$(echo "$clipboard_content" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g')

    # Add the new entry to the JSON file
    jq --arg datetime "$datetime" --arg content "$clipboard_content" '. + {($datetime): $content}' "$json_file" > "$json_file.tmp" && mv -f "$json_file.tmp" "$json_file"
}

get_datetime() {
  date +"%Y-%m-%d %H:%M:%S"
}

monitor_clipboard_loop() {
  previous_clipboard=""
  while true; do
    current_clipboard="$(xclip -selection clipboard -o)"

    if [ "$current_clipboard" != "$previous_clipboard" ]; then
      save_clipboard_entry "$json_file"
      previous_clipboard="$current_clipboard"
    fi

    sleep 1
  done
}

stop_monitoring() {
  kill -9 $monitor_pid
  echo "Clipboard monitoring stopped."
}

start_monitoring() {
  json_file="${1:-$HOME/clipboard_entries.json}"
  # Create an empty JSON file if it doesn't exist
  if [ ! -f "$json_file" ]; then
    echo "{}" > "$json_file"
  fi
  monitor_clipboard_loop "$json_file" &
  monitor_pid=$!
  echo "Clipboard monitoring started."
}

monitor_clipboard() {
  case "$1" in
    start)
      start_monitoring "$2"
      ;;
    stop)
      stop_monitoring
      ;;
    *)
      echo "Usage: monitor_clipboard [start [json_file]|stop]"
      ;;
  esac
}

clipimgur() {
    import png:- | imgur
  }


catselect() {
  # Path to store the state and selections
  STATE_FILE="/tmp/selection_stitch_state"
  SELECTION_FILE="/tmp/selection_stitch_selection"

  # Initialize state and selection storage if not present
  if [ ! -f "$STATE_FILE" ]; then
      echo "IDLE" > "$STATE_FILE"
      echo "" > "$SELECTION_FILE"
  fi

  # Read current state
  STATE=$(cat "$STATE_FILE")

  case $STATE in
      IDLE)
          # Capture the first selection and transition to FIRST_SELECTION_CAPTURED
          xclip -o -selection primary > "$SELECTION_FILE"
          echo "FIRST_SELECTION_CAPTURED" > "$STATE_FILE"
          kdialog --passivepopup "First selection captured." 2
          ;;
      FIRST_SELECTION_CAPTURED)
          # Capture the second selection, stitch with the first, copy to clipboard, and transition to IDLE
          FIRST_SELECTION=$(cat "$SELECTION_FILE")
          SECOND_SELECTION=$(xclip -o -selection primary)
          echo "$FIRST_SELECTION $SECOND_SELECTION" | xclip -selection clipboard
          echo "IDLE" > "$STATE_FILE"
          kdialog --passivepopup "Selection stitched and copied to clipboard." 2
          ;;
      *)
          # Reset to IDLE state in case of unexpected state
          echo "IDLE" > "$STATE_FILE"
          ;;
  esac
}

monitor_clipboard() {
    xclip -selection clipboard -o | while IFS= read -r previous; do
        while true; do
            current=$(xclip -selection clipboard -o)
            if [[ "$current" != "$previous" ]]; then
                echo "$current"
                previous="$current"
            fi
            sleep 1
        done
    done
}

generate_question () {
	local format=json 
	local A B C
	RANDOM=$(( $(date +%s%N) % 32768 ))
	A=$((RANDOM % 9)) 
	B=$((RANDOM % 9)) 
	C=$((RANDOM % 9 + 1))
	number1="$A.1$B" 
	number2="$A.$C" 
	if (( $(echo "$number1 > $number2" | bc -l) ))
	then
		answer="$number1" 
	else
		answer="$number2" 
	fi
	echo "{
	\"question\": \"$A.1$B or $A.$C what's bigger? Write the number only.\",
	\"answer\": \"$answer\"
}"
}
pylight () { { [ -p /dev/stdin ] && cat - || echo "$@"; } | highlight --syntax=python --out-format=ansi | fold -w 120 -s && echo; }
f () {
	fd -t f . | fzf --preview 'bat --style=plain --color=always {}'
}
