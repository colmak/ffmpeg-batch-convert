#!/bin/bash
set -euo pipefail

input_dir=$(pwd)
delete_after=false
convert_to_mp4=false
log_file="convert.log"

print_help() {
  echo "convert.sh - Bulk video converter"
  echo
  echo "This script converts all video files in the current directory to either:"
  echo "  • MKV (default) with VP9 (video) + FLAC (audio), or"
  echo "  • MP4 with H.264 (video) + AAC (audio) if --to_mp4 is set"
  echo
  echo "Supported input formats: .mp4, .webm, .mkv, .avi, .mov (any case)"
  echo
  echo "Usage:"
  echo "  ./convert.sh [--delete-after] [--to_mp4] [--help]"
  echo
  echo "Options:"
  echo "  --delete-after    Delete original files after successful conversion"
  echo "  --to_mp4          Convert to MP4 instead of MKV"
  echo "  --help            Show this help message"
}

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$log_file"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --delete-after) delete_after=true ;;
    --to_mp4) convert_to_mp4=true ;;
    --help) print_help; exit 0 ;;
    *) echo "Unknown flag: $1"; exit 1 ;;
  esac
  shift
done

if [ "$convert_to_mp4" = true ]; then
  output_dir="$input_dir/output_mp4"
else
  output_dir="$input_dir/output_mkv"
fi

mkdir -p "$output_dir"
> "$log_file"  

shopt -s nullglob nocaseglob

video_extensions=(mp4 webm mkv avi mov)
file_list=()
for ext in "${video_extensions[@]}"; do
  for file in "$input_dir"/*."$ext"; do
    [ -f "$file" ] && file_list+=("$file")
  done
done

if [ ${#file_list[@]} -eq 0 ]; then
  log "⚠️ No video files found in $input_dir"
  exit 0
fi

convert_file() {
  local video_file="$1"

  local base_name
  base_name=$(basename "${video_file%.*}")
  local output_file

  if [ "$convert_to_mp4" = true ]; then
    output_file="$output_dir/$base_name.mp4"
    ffmpeg -i "$video_file" -c:v libx264 -c:a aac "$output_file" -y &>> "$log_file"
  else
    output_file="$output_dir/$base_name.mkv"
    ffmpeg -i "$video_file" -c:v vp9 -c:a flac -compression_level 12 "$output_file" -y &>> "$log_file"
  fi

  if [ $? -eq 0 ]; then
    log "✅ Converted: $video_file → $output_file"
    if [ "$delete_after" = true ]; then
      rm "$video_file"
      log "🗑️ Deleted original: $video_file"
    fi
  else
    log "❌ Failed to convert: $video_file"
  fi
}

log "🔍 Found ${#file_list[@]} file(s) to process"
log "🔁 Starting conversion..."

for file in "${file_list[@]}"; do
  convert_file "$file"
done

log "✅ All files processed successfully."
log "📂 Output files are in: $output_dir"