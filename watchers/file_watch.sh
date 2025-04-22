#!/bin/bash

# Source the file_summarize.sh script to use its functionality
source "$(dirname "$0")/file_summarize.sh"

watch_and_summarize() {
  # This function watches specified directories for new files, summarizes them, and extracts key metadata
  # Usage: watch_and_summarize <directory> [<directory2> ...] [--types=<ext,ext>] [--interval=<sec>] [--db=<path>] [--format=<fmt>] [--watch] [--max-size=<size>] [-m=<model>]
  # Usage: 
  # Options:
  #   --types=<ext,ext>  File types to process (default: txt,md,pdf,doc,docx)
  #   --interval=<sec>   Polling interval in seconds (default: 60)
  #   --db=<path>        Path to database file (default: ~/.ai_file_summaries.db)
  #   --format=<fmt>     Output format: json, yaml, text (default: text)
  #   --watch            Continuous watching mode (default: one-time scan)
  #   --max-size=<size>  Max file size to process in KB (default: 5000)
  #   -m=<model>    LLM model to use (default: claude-3.5-haiku)
  
  local verbose=false
  local watch_mode=false
  local poll_interval=60
  local max_size=5000  # KB
  local output_format="text"
  local db_path="$HOME/.ai_file_summaries.db"
  local filetypes="txt,md,pdf,doc,docx,py,sh,js,java,cpp,h,html,css,xml,json,yaml"
  local model="claude-3.5-haiku"
  local dirs=()
  local force_rescan=false
  
  # Process arguments
  for arg in "$@"; do
    case $arg in
      --types=*) filetypes="${arg#*=}" ;;
      --interval=*) poll_interval="${arg#*=}" ;;
      --db=*) db_path="${arg#*=}" ;;
      --format=*) output_format="${arg#*=}" ;;
      --watch) watch_mode=true ;;
      --max-size=*) max_size="${arg#*=}" ;;
      --verbose) verbose=true ;;
      -m=*) model="${arg#*=}" ;;
      --rescan) force_rescan=true ;;
      -*) echo "Unknown option: $arg"; return 1 ;;
      *) 
        if [ -d "$arg" ]; then
          dirs+=("$arg")
        else
          echo "Error: Directory not found: $arg"
          return 1
        fi
        ;;
    esac
  done
  
  # Check if any directories were specified
  if [ ${#dirs[@]} -eq 0 ]; then
    echo "Error: No directories specified to watch"
    echo "Usage: ai-file-watch-and-summarize [options] <directory> [<directory2> ...]"
    return 1
  fi
  
  # Create database if it doesn't exist
  if [ ! -f "$db_path" ]; then
    [ "$verbose" = true ] && echo "Creating new database at $db_path"
    echo "CREATE TABLE IF NOT EXISTS processed_files (
      file_path TEXT PRIMARY KEY,
      hash TEXT,
      timestamp INTEGER,
      summary TEXT,
      keywords TEXT
    );" | sqlite3 "$db_path"
  else
    # Ensure the table exists even if the database file already exists
    echo "CREATE TABLE IF NOT EXISTS processed_files (
      file_path TEXT PRIMARY KEY,
      hash TEXT,
      timestamp INTEGER,
      summary TEXT,
      keywords TEXT
    );" | sqlite3 "$db_path"
  fi

  # Track files processed in this session to avoid duplicates in continuous mode
  declare -A processed_this_session
  
  # Function to process a single file
  process_file() {
    local file_path="$1"
    local file_size=$(du -k "$file_path" | cut -f1)
    
    # Use absolute path for consistent database lookups
    file_path=$(realpath "$file_path" 2>/dev/null || echo "$file_path")
    
    local file_hash=$(sha256sum "$file_path" | cut -d' ' -f1)
    
    # Skip if already processed in this session
    if [ -n "${processed_this_session[$file_path]}" ]; then
      [ "$verbose" = true ] && echo "Skipping file already processed in this session: $file_path"
      return 0
    fi

    # Check if file has already been processed and has the same hash, unless force_rescan is enabled
    if [ "$force_rescan" = false ]; then
      # Properly escape the file path for SQLite query
      local escaped_path=$(printf '%s' "$file_path" | sed "s/'/''/g")
      local query="SELECT COUNT(*) FROM processed_files WHERE file_path='$escaped_path' AND hash='$file_hash';"
      local is_processed=$(sqlite3 "$db_path" "$query")
      
      # Debug SQLite query if verbose mode
      if [ "$verbose" = true ]; then
        echo "Checking if file is already processed: $file_path"
        echo "File hash: $file_hash"
        echo "Query: $query"
        echo "Result: $is_processed"
      fi
      
      if [[ "$is_processed" =~ ^[0-9]+$ ]] && [ "$is_processed" -gt 0 ]; then
        [ "$verbose" = true ] && echo "Skipping already processed file with unchanged hash: $file_path"
        # Mark this file as processed in this session
        processed_this_session["$file_path"]="$file_hash"
        return 0
      fi
    fi
    
    # Check file size
    if [ "$file_size" -gt "$max_size" ]; then
      [ "$verbose" = true ] && echo "Skipping file exceeding size limit: $file_path"
      # Still mark as processed to avoid checking again
      processed_this_session["$file_path"]="$file_hash"
      return 0
    fi
    
    [ "$verbose" = true ] && echo "Processing file: $file_path"
    
    # Use ai-file-summarize to process the file, with the specified format and model
    local verbose_opt=""
    [ "$verbose" = true ] && verbose_opt="--verbose"
    
    local response=$(file_summarize --format=json --model="$model" $verbose_opt "$file_path")
    
    # Extract summary and keywords from the JSON response
    local summary=$(echo "$response" | grep -o '"summary":"[^"]*"' | cut -d'"' -f4)
    local keywords=$(echo "$response" | grep -o '"keywords":"[^"]*"' | cut -d'"' -f4)
    
    # Store results in database - properly escape values for SQLite
    local timestamp=$(date +%s)
    local escaped_path=$(printf '%s' "$file_path" | sed "s/'/''/g")
    local escaped_summary=$(printf '%s' "$summary" | sed "s/'/''/g")
    local escaped_keywords=$(printf '%s' "$keywords" | sed "s/'/''/g")
    
    # Use a single SQL command with variables to prevent injection
    local sql_query="INSERT OR REPLACE INTO processed_files 
      (file_path, hash, timestamp, summary, keywords) 
      VALUES ('$escaped_path', '$file_hash', $timestamp, '$escaped_summary', '$escaped_keywords');"
      
    sqlite3 "$db_path" "$sql_query"
    
    # Ensure the entry is properly saved
    if [ $? -ne 0 ]; then
      [ "$verbose" = true ] && echo "Warning: Failed to update database for file: $file_path"
    else
      [ "$verbose" = true ] && echo "Successfully updated database for: $file_path"
    fi
    
    # Mark as processed in this session
    processed_this_session["$file_path"]="$file_hash"
    
    # Output results based on format
    case "$output_format" in
      json)
        # Escape JSON special characters
        local json_file_path=$(printf '%s' "$file_path" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g')
        local json_summary=$(printf '%s' "$summary" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g')
        local json_keywords=$(printf '%s' "$keywords" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g')
        echo "{\"file\":\"$json_file_path\",\"summary\":\"$json_summary\",\"keywords\":\"$json_keywords\",\"timestamp\":$timestamp}"
        ;;
      yaml)
        echo "---"
        echo "file: $file_path"
        echo "summary: |"
        echo "  $summary"
        echo "keywords: $keywords"
        echo "timestamp: $timestamp"
        ;;
      *)  # Default text format
        echo -e "\033[1;36m=== $file_path ===\033[0m"
        echo -e "\033[1;33mSummary:\033[0m"
        echo "$summary"
        echo -e "\033[1;33mKeywords:\033[0m"
        echo "$keywords"
        echo ""
        ;;
    esac
    
    return 1  # File was processed
  }
  
  # Function to scan directories for files
  scan_directories() {
    local extensions_pattern=$(echo "$filetypes" | sed 's/,/\\|/g')
    local found_files=0
    local processed_files=0
    
    for dir in "${dirs[@]}"; do
      [ "$verbose" = true ] && echo "Scanning directory: $dir"
      
      # Find files with matching extensions
      while IFS= read -r file; do
        # Skip empty results
        [ -z "$file" ] && continue
        
        ((found_files++))
        # Process file and track if it was actually processed
        process_file "$file"
        if [ $? -eq 1 ]; then
          ((processed_files++))
        fi
      done < <(find "$dir" -type f -regex ".*\.\(${extensions_pattern}\)$" 2>/dev/null || true)
    done
    
    if [ "$processed_files" -gt 0 ]; then
      echo "Processed $processed_files files"
    elif [ "$found_files" -gt 0 ] && [ "$verbose" = true ]; then
      echo "No new files to process"
    elif [ "$verbose" = true ]; then
      echo "No matching files found in specified directories"
    fi
  }
  
  # Initialize the database connection once
  sqlite3 "$db_path" "PRAGMA journal_mode = WAL; PRAGMA synchronous = NORMAL;" >/dev/null
  
  # Main execution
  if [ "$watch_mode" = true ]; then
    echo "Starting file watch mode (Ctrl+C to stop)"
    echo "Watching directories: ${dirs[*]}"
    echo "Checking every $poll_interval seconds"
    
    # Initial scan
    scan_directories
    
    # Continuous monitoring
    while true; do
      sleep "$poll_interval"
      [ "$verbose" = true ] && echo "Running periodic scan..."
      scan_directories
    done
  else
    # One-time scan
    scan_directories
  fi
}

if [ "$0" = "$BASH_SOURCE" ]; then # If the script is executed, not sourced.
    watch_and_summarize "$@"
fi

