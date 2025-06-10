#!/bin/bash
set -euo pipefail

show_usage() {
  cat << EOF
Usage: $0 [OPTIONS]

FFmpeg DaVinci Resolve Linux Converter
Converts video files to DaVinci Resolve compatible formats.

OPTIONS:
  -f, --format FORMAT    Output format: mkv, mov, mp4 (default: mkv)
  -i, --input DIR        Input directory (default: current directory)
  -j, --jobs NUMBER      Number of parallel conversion jobs (default: 3)
  -d, --delete           Delete original files after conversion
  -h, --help             Show this help message
  -v, --version          Show version information

EXAMPLES:
  $0                     Convert all videos in current dir to MKV
  $0 -f mov              Convert to MOV format with PCM audio
  $0 -f mp4 -d           Convert to MP4 and delete originals
  $0 -j 1                Convert one file at a time (sequential)
  $0 -j 5                Convert up to 5 files simultaneously
  $0 -i /path/to/videos  Convert videos from specific directory

CONFIG FILE:
  Create .convertrc in your project directory to set default options.
  Command line options override config file settings.

EOF
}

while [[ $# -gt 0 ]]; do
  case $1 in
    -f|--format)
      CLI_OUTPUT_FORMAT="$2"
      shift 2
      ;;
    -i|--input)
      CLI_INPUT_DIR="$2"
      shift 2
      ;;
    -j|--jobs)
      CLI_PARALLEL_JOBS="$2"
      shift 2
      ;;
    -d|--delete)
      CLI_DELETE_AFTER=true
      shift
      ;;
    -h|--help)
      show_usage
      exit 0
      ;;
    -v|--version)
      echo "FFmpeg DaVinci Resolve Linux Converter v1.0"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      show_usage
      exit 1
      ;;
  esac
done

config_file=".convertrc"
queue_file="queue.txt"
cache_file=".convert_cache.txt"
log_file="convert.log"

INPUT_DIR=$(pwd)
DELETE_AFTER=false
OUTPUT_FORMAT="mkv"
PARALLEL_JOBS=3

if [ -f "$config_file" ]; then
  echo "⚙️ Loading config from $config_file"
  source "$config_file"
fi

# Override with CLI arguments
INPUT_DIR="${CLI_INPUT_DIR:-$INPUT_DIR}"
DELETE_AFTER="${CLI_DELETE_AFTER:-$DELETE_AFTER}"
OUTPUT_FORMAT="${CLI_OUTPUT_FORMAT:-$OUTPUT_FORMAT}"
PARALLEL_JOBS="${CLI_PARALLEL_JOBS:-$PARALLEL_JOBS}"

case "$OUTPUT_FORMAT" in
  "mp4")
    output_format="mp4"
    output_dir="$INPUT_DIR/output_mp4"
    ;;
  "mov")
    output_format="mov"
    output_dir="$INPUT_DIR/output_mov"
    ;;
  *)
    output_format="mkv"
    output_dir="$INPUT_DIR/output_mkv"
    ;;
esac

mkdir -p "$output_dir"
> "$log_file"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$log_file"
}

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

  case "$output_format" in
    "mp4")
      output_file="$output_dir/$base_name.mp4"
      codec_args="-c:v libx264 -c:a aac"
      ;;
    "mov")
      output_file="$output_dir/$base_name.mov"
      codec_args="-c:v libx264 -c:a pcm_s16le"
      ;;
    *)
      output_file="$output_dir/$base_name.mkv"
      codec_args="-c:v vp9 -c:a flac -compression_level 12"
      ;;
  esac

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
export output_format output_dir DELETE_AFTER cache_file log_file
export -A cache

log "🔁 Starting conversion using $PARALLEL_JOBS parallel jobs..."

mapfile -t file_list < "$queue_file"

# Process files with controlled parallelism
for file in "${file_list[@]}"; do
  # Wait if we've reached the maximum number of parallel jobs
  while (( $(jobs -rp | wc -l) >= PARALLEL_JOBS )); do
    wait -n  # Wait for any job to complete
  done
  
  # Start conversion in background
  convert_file "$file" &
done

# Wait for all remaining jobs to complete
wait

log "✅ All files processed."
log "📂 Output directory: $output_dir"