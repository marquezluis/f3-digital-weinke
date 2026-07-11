#!/usr/bin/env python3
"""
generate_gifs.py — Digital Weinke Animation Pipeline
════════════════════════════════════════════════════
Reads the F3 Exicon CSV export, looks for YouTube/Video URLs, 
downloads the first 5 seconds, and converts them to optimized .webp animations.

Dependencies: 
  - yt-dlp (pip install yt-dlp)
  - ffmpeg (brew install ffmpeg / apt install ffmpeg)
"""

import csv
import subprocess
import os
import sys
from pathlib import Path

def process_video(url: str, output_path: Path):
    """Downloads the first 5 seconds of a video and converts to a looping WebP."""
    temp_mp4 = "temp_video.mp4"
    
    # 1. Download first 5 seconds (max 480p to save bandwidth/processing)
    dl_cmd = [
        "yt-dlp",
        "--download-sections", "*00:00-00:05",
        "-f", "bestvideo[height<=480][ext=mp4]/worst",
        "-o", temp_mp4,
        url
    ]
    
    # 2. Convert to WebP (10 fps, 320px wide, quality 50 for tiny file sizes)
    ff_cmd = [
        "ffmpeg", "-y", "-i", temp_mp4,
        "-vcodec", "libwebp", "-lossless", "0", "-compression_level", "6",
        "-q:v", "50", "-loop", "0",
        "-vf", "fps=10,scale=320:-1:flags=lanczos",
        str(output_path)
    ]
    
    try:
        print(f"  ↓ Downloading {url}...")
        subprocess.run(dl_cmd, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        print(f"  ↻ Converting to {output_path.name}...")
        subprocess.run(ff_cmd, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except subprocess.CalledProcessError as e:
        print(f"  ⚠ Error processing {url}: {e}")
    finally:
        if os.path.exists(temp_mp4):
            os.remove(temp_mp4)

def main():
    input_csv = Path('f3-codex-export.csv')
    output_dir = Path('assets/gifs')
    output_dir.mkdir(parents=True, exist_ok=True)

    if not input_csv.exists():
        print(f"ERROR: {input_csv} not found.", file=sys.stderr)
        sys.exit(1)

    with input_csv.open(newline='', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        
        for row in reader:
            ex_id = row.get('ID', '').strip()
            video_url = row.get('VideoUrl', '').strip()
            
            if not ex_id or not video_url:
                continue
                
            target_file = output_dir / f"{ex_id}.webp"
            
            if target_file.exists():
                continue # Skip if we already generated it
                
            print(f"\nProcessing {row.get('Name', ex_id)}...")
            process_video(video_url, target_file)

if __name__ == '__main__':
    main()