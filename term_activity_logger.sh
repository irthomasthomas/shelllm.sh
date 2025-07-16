#!/usr/bin/env bash

# --- Shell Activity Logger ---
# The shell activity logger is NOT enabled by default.
# To enable, first ensure this script is sourced in your shell's startup file
# (e.g., ~/.zshrc or ~/.bashrc).
#
# Then, add the following line to your startup file AFTER sourcing this script:
#
#   setup_shell_activity_logger
#
# To disable logging for the current session, you can run:
#
#   disable_shell_activity_logger
#
# This will set up the necessary hooks for both Zsh and Bash.
#
set +m  # Disable job control to avoid background job messages interfering with logging
setup_shell_activity_logger() {
  # Check if llm command exists
  if ! command -v llm >/dev/null 2>&1; then
    echo "Warning: llm command not found. Shell activity logging disabled." >&2
    return 1
  fi

  # --- Configuration ---
  _SHELL_ACTIVITY_DIARY_DIR="${HOME}/.zsh_shell_activity_diary"
  mkdir -p "${_SHELL_ACTIVITY_DIARY_DIR}"
  _SHELL_ACTIVITY_CID_FILE="${_SHELL_ACTIVITY_DIARY_DIR}/.note_shell_activity_cid"

  # --- Initialization ---
  if [[ ! -f "$_SHELL_ACTIVITY_CID_FILE" ]]; then
    echo "Initializing note_shell_activity_cid..."
    llm -d /home/thomas/.config/io.datasette.llm/terminal.db "$(uuidgen) - Only acknowledge receipt, say nothing else." > /dev/null 2>&1
    _retrieved_cid=$(llm logs list -d /home/thomas/.config/io.datasette.llm/terminal.db -n 1 --json | jq -r '.[] | .conversation_id')
    if [[ -n "$_retrieved_cid" && "$_retrieved_cid" != "null" ]]; then
      echo "$_retrieved_cid" > "$_SHELL_ACTIVITY_CID_FILE"
      note_shell_activity_cid="$_retrieved_cid"
      echo "note_shell_activity_cid initialized and saved: $note_shell_activity_cid"
    else
      echo "Error: Could not retrieve conversation_id. Activity logging might be impacted." >&2
      note_shell_activity_cid=""
    fi
  else
    note_shell_activity_cid=$(cat "$_SHELL_ACTIVITY_CID_FILE")
  fi

  # Export variables for use by hook functions
  export _SHELL_ACTIVITY_DIARY_DIR
  export _SHELL_ACTIVITY_CID_FILE
  export note_shell_activity_cid
  
  # Setup hooks for the current shell
  if [[ -n "$ZSH_VERSION" ]]; then
    # Setup for Zsh
    autoload -Uz add-zsh-hook
    add-zsh-hook preexec _log_shell_command_activity
  elif [[ -n "$BASH_VERSION" ]]; then
    # Setup for Bash
    # Use a DEBUG trap to call the logger before a command is executed.
    # PROMPT_COMMAND is used to get the command from history.
    export PROMPT_COMMAND='_shell_activity_log_last_command'
    trap '_log_shell_command_activity "$BASH_COMMAND"' DEBUG
  fi
}

# Function to disable the shell activity logger for the current session.
disable_shell_activity_logger() {
  if [[ -n "$ZSH_VERSION" ]]; then
    # Disable for Zsh
    autoload -Uz add-zsh-hook
    add-zsh-hook -d preexec _log_shell_command_activity
    echo "Shell activity logger disabled for Zsh session."
  elif [[ -n "$BASH_VERSION" ]]; then
    # Disable for Bash
    trap - DEBUG
    # Unset PROMPT_COMMAND if it was only for the logger
    if [[ "$PROMPT_COMMAND" == '_shell_activity_log_last_command' ]]; then
      unset PROMPT_COMMAND
    fi
    echo "Shell activity logger disabled for Bash session."
  else
    echo "Unsupported shell. Could not disable activity logger." >&2
    return 1
  fi
}

# Helper for Bash to get the last command.
_shell_activity_log_last_command() {
  # In Bash, the DEBUG trap runs before the command is in history.
  # We don't need to do anything here, but PROMPT_COMMAND is a common
  # place to handle history-related tasks. The trap is sufficient.
  return
}

# shellcheck disable=SC2317  # Function called indirectly via shell hooks
note_shell_activity() {
  # Ensure logger is set up. If not, run setup.
  if [[ -z "$_SHELL_ACTIVITY_DIARY_DIR" || -z "$note_shell_activity_cid" ]]; then
    # This will run if the script is sourced but setup wasn't run from .zshrc
    # It might not set the hook for the current session, but will for subsequent commands.
    setup_shell_activity_logger
    # If still not set, exit to prevent errors.
    if [[ -z "$_SHELL_ACTIVITY_DIARY_DIR" || -z "$note_shell_activity_cid" ]]; then
        echo "Error: Shell activity logger setup failed. Cannot log command." >&2
        return 1
    fi
  fi

  local shell_command_input="$1"
  local daily_log_file="${_SHELL_ACTIVITY_DIARY_DIR}/$(date +%Y-%m-%d).log"
  local error_log_file="${_SHELL_ACTIVITY_DIARY_DIR}/errors.log"
  local system_prompt="<MACHINE_NAME>Zsh Command Activity Logger</MACHINE_NAME>
<MACHINE_DESCRIPTION>
It interprets Zsh commands to generate brief diary entries.
</MACHINE_DESCRIPTION>
<CORE_FUNCTION>
It will receive a Zsh command. Its task is to generate a concise diary-style entry (1-2 sentences, <20 words) summarizing the user's likely activity. If the command is too generic for a meaningful entry after initial filtering, respond with only a hyphen '-'. Focus solely on the diary entry or the hyphen.
</CORE_FUNCTION>
Keep responses brief and directly usable as a diary line."

  (
    local llm_output
    if [[ -z "$note_shell_activity_cid" ]]; then
      echo "Error: note_shell_activity_cid is not set. Cannot log activity." >>"$error_log_file"
      return 1
    fi
    llm_output=$(llm -d /home/thomas/.config/io.datasette.llm/terminal.db --system "$system_prompt" -c --cid "$note_shell_activity_cid" "$shell_command_input" -m gemini-flash-lite 2>>"$error_log_file")
    local llm_exit_status=$?
    if (( llm_exit_status == 0 )) && [[ -n "$llm_output" && "$llm_output" != "-" ]]; then
      echo "$(date +'%Y-%m-%d %H:%M:%S') $llm_output" >> "$daily_log_file"
    fi
  ) > /dev/null 2>>"$error_log_file" &
}

# shellcheck disable=SC2317  # Function called indirectly via shell hooks
_log_shell_command_activity() {
  local command_line="$1"
  if [[ "$command_line" =~ ^(bd|ls|cd|pwd|history|clear|exit|bg|fg|jobs|top|htop|man|which|cat|less|tail|head|mv|cp|rm|mkdir|touch|vim|nvim|v|n|source|\.?/note_shell_activity)( |$) ]] || \
     [[ "$command_line" =~ ^llm ]]; then
    return 0
  fi
  note_shell_activity "$command_line"
}

setup_shell_activity_logger