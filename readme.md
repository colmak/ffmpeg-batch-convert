# ffmpeg-batch-convert-davinci-linux

A robust batch video converter optimized for DaVinci Resolve compatibility on Linux systems. This tool automatically converts video files to formats that work seamlessly with DaVinci Resolve, with support for parallel processing and resume functionality.

## Features

- **DaVinci Resolve Optimized**: Converts videos to VP9/FLAC (MKV), H.264/PCM (MOV), or H.264/AAC (MP4) formats
- **Parallel Processing**: Multi-threaded conversion for faster processing
- **Resume Support**: Automatically resumes interrupted conversions using cache
- **Queue Management**: Processes files in batches with queue tracking
- **Configurable**: Customizable settings via configuration file
- **Progress Logging**: Detailed logging with timestamps
- **Auto-cleanup**: Optional deletion of original files after conversion

## Requirements

- FFmpeg (with VP9 and FLAC support)
- Bash 4.0 or higher
- GNU Parallel (optional, for better performance)

## Installation

1. Clone or download the converter:

```bash
git clone <repository-url>
cd ffmpeg-davinci-linux-converter
```

2. Make the script executable:

```bash
chmod +x convert.sh
```

3. Ensure FFmpeg is installed:

```bash
# Ubuntu/Debian
sudo apt install ffmpeg

# Fedora
sudo dnf install ffmpeg

# Arch Linux
sudo pacman -S ffmpeg
```

## Usage

### Basic Usage

Convert all video files in the current directory:

```bash
./convert.sh
```

### Configuration

Create or edit `.convertrc` to customize settings:

```bash
# Directory to scan (defaults to current dir if empty)
INPUT_DIR="/path/to/your/videos"

# Output format (mkv, mov, or mp4)
OUTPUT_FORMAT="mkv"

# Delete original files after conversion (true or false)
DELETE_AFTER=false

# Enable parallel processing
PARALLEL=true

# Number of parallel jobs
PARALLEL_JOBS=3
```

### Supported Input Formats

- MP4
- WebM
- MKV
- AVI
- MOV

### Output Formats

#### MKV (Default - Recommended for DaVinci Resolve)

- **Video Codec**: VP9 with compression level 12
- **Audio Codec**: FLAC (lossless)
- **Best for**: Professional editing, color grading, high quality archival

#### MOV (Alternative - Maximum Compatibility)

- **Video Codec**: H.264
- **Audio Codec**: PCM (uncompressed)
- **Best for**: Maximum compatibility with DaVinci Resolve, professional editing workflows

#### MP4 (Niche Use - AAC Audio Requirements)

- **Video Codec**: H.264
- **Audio Codec**: AAC
- **Best for**: Specific workflows requiring AAC audio, web sharing, broader compatibility outside DaVinci Resolve

## File Structure

After running the converter, your directory will contain:

```
your-video-folder/
├── original-video.mp4          # Original files (deleted if DELETE_AFTER=true)
├── output_mkv/                 # Converted MKV files (default)
│   └── original-video.mkv
├── output_mov/                 # Converted MOV files (if selected)
│   └── original-video.mov
├── output_mp4/                 # Converted MP4 files (if selected)
│   └── original-video.mp4
├── queue.txt                   # Processing queue
├── .convert_cache.txt          # Conversion cache for resume
├── convert.log                 # Detailed conversion log
└── .convertrc                  # Configuration file
```

## Advanced Features

### Resume Interrupted Conversions

The converter automatically tracks completed conversions in `.convert_cache.txt`. If the process is interrupted, simply run the script again to resume from where it left off.

### Queue Management

- Files are queued in `queue.txt` before processing
- Manually edit this file to control which files get converted
- Delete the queue file to regenerate it with current directory contents

### Parallel Processing

The converter uses all available CPU cores by default. Adjust `PARALLEL_JOBS` in `.convertrc` to:

- Reduce system load: Set to 1-2 for background processing
- Maximize speed: Set to CPU core count or higher (if you have sufficient RAM)

### Logging

Check `convert.log` for detailed information about:

- Conversion progress and results
- FFmpeg output and error messages
- File processing timestamps

## Troubleshooting

### Common Issues

**"Command not found: ffmpeg"**

- Install FFmpeg using your distribution's package manager

**"Permission denied"**

- Make sure the script is executable: `chmod +x convert.sh`

**Slow conversion speed**

- Increase `PARALLEL_JOBS` in `.convertrc`
- Install GNU Parallel for better job management: `sudo apt install parallel`

**DaVinci Resolve won't import files**

- MKV format (default) should work well with DaVinci Resolve for high-quality editing
- Try MOV format for maximum compatibility: Set `OUTPUT_FORMAT="mov"` in `.convertrc`
- MP4 format may have issues with AAC audio on Linux DaVinci Resolve: Set `OUTPUT_FORMAT="mp4"` only if specifically needed
- Ensure your DaVinci Resolve version supports the codecs

### Performance Tips

1. **SSD Storage**: Use SSD for faster I/O during conversion
2. **RAM**: Ensure sufficient RAM for parallel jobs (2-4GB per job)
3. **CPU**: More cores = faster parallel processing
4. **Network Storage**: Avoid converting files over network mounts

## License

This project is open source. Feel free to modify and distribute according to your needs.

## Contributing

Contributions are welcome! Please feel free to submit pull requests or open issues for bugs and feature requests.
