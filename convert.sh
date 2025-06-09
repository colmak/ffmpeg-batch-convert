#!/bin/bash
set -euo pipefail

config_file=".convertrc"
queue_file="queue.txt"
cache_file=".convert_cache.txt"
log_file="convert.log"

# Default config values
INPUT_DIR=$(pwd)
DELETE_AFTER=false
OUTPUT_FORMAT="mkv"
PARALLEL_JOBS=$(nproc 2>/dev/null || echo 4)

# Load config file
if [ -f "$config_file" ]; then
  echo "⚙️ Loading config from $config_file"
  source "$config_file"
fi

# Override output format flag
if [ "$OUTPUT_FORMAT" = "mp4" ]; then
  convert_to_mp4=true
  output_dir="$INPUT_DIR/output_mp4"
else
  convert_to_mp4=false
  output_dir="$INPUT_DIR/output_mkv"
fi

mkdir -p "$output_dir"
> "$log_file"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$log_file"
}

# Create queue if not exists
if [ ! -f "$queue_file" ]; then
  echo "📋 Creating queue file..."
  shopt -s nullglob nocaseglob
  video_extensions=(mp4 webm mkv avi mov)
  for ext in "${video_extensions[@]}"; do
    for file in "$INPUT_DIR"/*."$ext"; do
      [ -f "$file" ] && echo "$file" >> "$queue_file"
    done
  done
fi

if [ ! -s "$queue_file" ]; then
  log "⚠️ Queue is empty. Nothing to convert."
  exit 0
fi

# Load cache into memory
declare -A cache
if [ -f "$cache_file" ]; then
  while IFS= read -r line; do
    file="${line%%:*}"
    status="${line##*:}"
    cache["$file"]="$status"
  done < "$cache_file"
fi

convert_file() {
  local video_file="$1"
  local base_name
  base_name=$(basename "${video_file%.*}")
  local output_file

  if [ "$convert_to_mp4" = true ]; then
    output_file="$output_dir/$base_name.mp4"
    codec_args="-c:v libx264 -c:a aac"
  else
    output_file="$output_dir/$base_name.mkv"
    codec_args="-c:v vp9 -c:a flac -compression_level 12"
  fi

  # Skip if in cache with success
  if [[ "${cache[$video_file]}" == "success" ]]; then
    log "⏩ Skipping already converted: $video_file"
    return
  fi

  ffmpeg -i "$video_file" $codec_args "$output_file" -y &>> "$log_file"
  if ffmpeg -v error -i "$output_file" -f null - 2>>"$log_file"; then
    log "✅ Converted: $video_file → $output_file"
    echo "$video_file:success" >> "$cache_file"
    if [ "$DELETE_AFTER" = true ]; then
      rm "$video_file"
      log "🗑️ Deleted original: $video_file"
    fi
  else
    log "❌ Failed: $video_file"
    echo "$video_file:fail" >> "$cache_file"
    rm -f "$output_file"
  fi
}

export -f convert_file log
export convert_to_mp4 output_dir DELETE_AFTER cache_file log_file
export -A cache

log "🔁 Starting conversion using $PARALLEL_JOBS parallel jobs..."

mapfile -t file_list < "$queue_file"

if command -v parallel &> /dev/null; then
  parallel -j "$PARALLEL_JOBS" convert_file ::: "${file_list[@]}"
else
  for file in "${file_list[@]}"; do
    convert_file "$file" &
    while (( $(jobs -rp | wc -l) >= PARALLEL_JOBS )); do wait -n; done
  done
  wait
fi

log "✅ All files processed."
log "📂 Output directory: $output_dir"