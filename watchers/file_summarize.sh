#!/bin/bash

file_summarize() {
  # This function analyzes a file and generates a summary and keywords
  # Usage: file_summarize <filepath> [--format=<fmt>] [-m=<model>] [--verbose]
  # Options:
  #   --format=<fmt>    Output format: json, yaml, text (default: text)
  #   -m=<model>   LLM model to use (default: claude-3.5-haiku)
  #   --verbose         Show detailed progress information
  
  local system_prompt="You're an assistant that analyzes files. For each file, create <summary>A clear, concise summary of the file's content (3-5 sentences)</summary> and <keywords>5-10 key topics/terms from the file, comma separated</keywords>. Be accurate and extract the most important information. Focus only on the content provided, don't speculate beyond what's in the file.
  example:
  user:bouncing_ball_rotating_hexagon.py
  [content ommited]

  assistant:<summary>Pygame sim of bouncing ball inside rotating hexagon. Ball moves under influence of gravity and friction, while the hexagon rotates coninuously. Implements collision detection between ball and hexagon, using vector math to calculate reflection and bounce mechanics.</summary>
    <keywords>pygame, simulation, bouncing ball, hexagon, collision detection, vector math, gravity, friction, game development</keywords>"
  local verbose=false
  local output_format="text"
  local model="claude-3.5-haiku"
  local file_path=""
  
  # Process arguments
  for arg in "$@"; do
    case $arg in
      --format=*) output_format="${arg#*=}" ;;
      -m=*|--model=*) model="${arg#*=}" ;;
      --verbose) verbose=true ;;
      -*) echo "Unknown option: $arg"; return 1 ;;
      *) 
        if [ -f "$arg" ]; then
          file_path="$arg"
        else
          echo "Error: File not found: $arg"
          return 1
        fi
        ;;
    esac
  done
  
  # Check if a file was specified
  if [ -z "$file_path" ]; then
    echo "Error: No file specified"
    echo "Usage: ai-file-summarize [options] <filepath>"
    return 1
  fi
  
  # Use absolute path for consistency
  file_path=$(realpath "$file_path" 2>/dev/null || echo "$file_path")
  local file_ext="${file_path##*.}"
  
  # Extract content based on file type
  local content=""
  case "$file_ext" in
    txt|md) content=$(cat "$file_path") ;;
    pdf) 
      if command -v pdftotext >/dev/null 2>&1; then
        content=$(pdftotext "$file_path" - 2>/dev/null)
      else
        echo "Error: pdftotext not installed, cannot process PDF file"
        return 1
      fi
      ;;
    doc|docx)
      if command -v pandoc >/dev/null 2>&1; then
        content=$(pandoc -s "$file_path" -t plain 2>/dev/null)
      else
        echo "Error: pandoc not installed, cannot process DOC/DOCX file"
        return 1
      fi
      ;;
    *)
      content=$(cat "$file_path" 2>/dev/null || echo "Binary file")
      ;;
  esac
  
  # Truncate content if too large
  local max_chars=15000
  if [ ${#content} -gt $max_chars ]; then
    content="${content:0:$max_chars}...[content truncated]"
  fi
  
  # Generate prompt for LLM
  local prompt="<file_path>$file_path</file_path>
<file_type>$file_ext</file_type>
<content>
$content
</content>

Please provide a concise summary and extract key metadata from this file."
  
  # Call LLM
  [ "$verbose" = true ] && echo "Generating summary and keywords..."
  local response=$(llm -m "$model" -s "$system_prompt" "$prompt" --no-stream)
  
  # Extract summary and keywords
  local summary=$(echo "$response" | awk 'BEGIN{RS="<summary>"} NR==2' | awk 'BEGIN{RS="</summary>"} NR==1')
  local keywords=$(echo "$response" | awk 'BEGIN{RS="<keywords>"} NR==2' | awk 'BEGIN{RS="</keywords>"} NR==1')
  
  # Output results based on format
  local timestamp=$(date +%s)
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
  
  return 0
}

if [ "$0" = "$BASH_SOURCE" ]; then # If the script is executed, not sourced.
    file_summarize "$@"
fi
