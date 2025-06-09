# ffmpeg-batch-convert-davinci-linux

A robust batch video converter optimized for DaVinci Resolve compatibility on Linux systems. This tool automatically converts video files to formats that work seamlessly with DaVinci Resolve, with support for resume functionality and command-line options.

## Features

- **DaVinci Resolve Optimized**: Converts videos to VP9/FLAC (MKV), H.264/PCM (MOV), or H.264/AAC (MP4) formats
- **Command Line Interface**: Flexible CLI options for different workflows
- **Resume Support**: Automatically resumes interrupted conversions using cache
- **Queue Management**: Processes files in batches with queue tracking
- **Configurable**: Customizable settings via configuration file
- **Progress Logging**: Detailed logging with timestamps
- **Auto-cleanup**: Optional deletion of original files after conversion

## Requirements

- FFmpeg (with VP9 and FLAC support)
- Bash 4.0 or higher

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

### Command Line Options

```bash
# Basic usage - convert all videos in current directory to MKV
./convert.sh

# Convert to MOV format for maximum DaVinci Resolve compatibility
./convert.sh --format mov

# Convert to MP4 format (niche use cases)
./convert.sh -f mp4

# Convert videos from specific directory
./convert.sh --input /path/to/your/videos

# Convert and delete original files
./convert.sh --delete

# Combine options
./convert.sh -f mov -i /path/to/videos -d

# Show help
./convert.sh --help
```

### Configuration File

Create or edit `.convertrc` to customize settings:

```bash
# Directory to scan (defaults to current dir if empty)
INPUT_DIR="/path/to/your/videos"

# Output format (mkv, mov, or mp4)
OUTPUT_FORMAT="mkv"

# Delete original files after conversion (true or false)
DELETE_AFTER=false
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

### Command Line vs Config File

Command line options override configuration file settings:
- Use CLI options for one-time conversions
- Use `.convertrc` for your default workflow settings

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

- FFmpeg is already highly optimized and uses multiple CPU cores internally
- Consider using faster storage (SSD) for better I/O performance
- Ensure sufficient RAM is available for the conversion process

**DaVinci Resolve won't import files**

- MKV format (default) should work well with DaVinci Resolve for high-quality editing
- Try MOV format for maximum compatibility: Set `OUTPUT_FORMAT="mov"` in `.convertrc`
- MP4 format may have issues with AAC audio on Linux DaVinci Resolve: Set `OUTPUT_FORMAT="mp4"` only if specifically needed
- Ensure your DaVinci Resolve version supports the codecs

### Performance Tips

1. **SSD Storage**: Use SSD for faster I/O during conversion
2. **RAM**: Ensure sufficient RAM is available (4-8GB recommended)
3. **CPU**: FFmpeg automatically utilizes multiple CPU cores efficiently
4. **Network Storage**: Avoid converting files over network mounts for best performance

## License

This project is open source. Feel free to modify and distribute according to your needs.

## Contributing

Contributions are welcome! Please feel free to submit pull requests or open issues for bugs and feature requests.
