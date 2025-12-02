#!/usr/bin/env python3

import subprocess
import struct
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor, as_completed
import shutil
import sys
import argparse

# Configuration
FFMPEG_ARGS = [
    "-c:v", "libwebp",
    "-lossless", "1",
    "-compression_level", "6",
    "-q:v", "100",
    "-loop", "0",
    "-y"
]

# Magick equivalent: -define webp:lossless=true -define webp:method=6 -quality 100 -loop 0
MAGICK_ARGS = [
    "-define", "webp:lossless=true",
    "-define", "webp:method=6",
    "-quality", "100",
    "-loop", "0"
]

# cwebp -z 9 is the specific shortcut for: Lossless + Quality 100 + Method 6 (Best)
CWEBP_ARGS = ["-z", "9", "-quiet"] 

TOOLS = {}

def check_prerequisites():
    """Checks if required tools are available in the system PATH."""
    global TOOLS
    
    TOOLS["ffmpeg"] = shutil.which("ffmpeg")
    TOOLS["magick"] = shutil.which("magick")
    TOOLS["cwebp"] = shutil.which("cwebp")

    missing = []
    if not TOOLS["cwebp"]:
        missing.append("cwebp")
    
    # We need ffmpeg for animations
    if not TOOLS["ffmpeg"]:
        missing.append("ffmpeg")
    
    if missing:
        print("\033[91mError: Missing required dependencies:\033[0m")
        for tool in missing:
            print(f"  - {tool}")
        print("\nPlease install them and try again.")
        print("  macOS: brew install ffmpeg webp")
        print("  Debian/Ubuntu: apt-get install ffmpeg webp")
        sys.exit(1)

def is_animated(file_path: Path) -> bool:
    """
    Reads the WebP header to check for the Animation flag.
    Efficient binary check avoiding external dependencies.
    """
    try:
        with file_path.open('rb') as f:
            riff = f.read(12)
            if not riff.startswith(b'RIFF') or riff[8:12] != b'WEBP':
                return False
            
            chunk_header = f.read(8)
            chunk_tag = chunk_header[0:4]
            
            # The 'VP8X' chunk contains the extended flags
            if chunk_tag == b'VP8X':
                flags = f.read(4)
                # The Animation bit is the 2nd bit (0x02) of the first byte of flags
                return (flags[0] & 0x02) != 0
    except Exception:
        return False
    return False

def get_size(path: Path) -> int:
    return path.stat().st_size

def format_bytes(size: int) -> str:
    if size == 0:
        return "0 bytes"
    power = 2**10
    n = size
    power_labels = {0: 'bytes', 1: 'KB', 2: 'MB', 3: 'GB', 4: 'TB'}
    loop = 0
    while n >= power and loop < len(power_labels) - 1:
        n /= power
        loop += 1
    return f"{n:.2f} {power_labels[loop]}"

def process_file(file_path: Path, dry_run: bool = False):
    """
    Optimizes a single file using the appropriate tool.
    Returns: (status_code, original_size, saved_bytes, path_str, error_msg)
    """
    # 0=Skipped, 1=Optimized, 2=Error
    original_size = get_size(file_path)
    temp_path = file_path.with_suffix(file_path.suffix + ".temp.webp")
    
    animated = is_animated(file_path)
    
    try:
        if animated:
            # Use FFmpeg for Animations (Magick can cause corruption)
            if TOOLS["ffmpeg"]:
                cmd = ["ffmpeg", "-i", str(file_path)] + FFMPEG_ARGS + [str(temp_path)]
                result = subprocess.run(cmd, capture_output=True, text=True, check=True)
            else:
                return (2, original_size, 0, file_path.name, "No suitable tool found for animation (need ffmpeg)")
        else:
            # Use cwebp for Stills (most efficient)
            cmd = ["cwebp", str(file_path)] + CWEBP_ARGS + ["-o", str(temp_path)]
            result = subprocess.run(cmd, capture_output=True, text=True, check=True)

        # Check results
        if not temp_path.exists():
            return (2, original_size, 0, file_path.name, "Temp file not created")

        new_size = get_size(temp_path)

        if new_size < original_size:
            saved = original_size - new_size
            if dry_run:
                temp_path.unlink() # Clean up temp in dry run
                return (1, original_size, saved, file_path.name, None)
            else:
                temp_path.replace(file_path) # Atomic replacement
                return (1, original_size, saved, file_path.name, None)
        else:
            temp_path.unlink() # Delete temp
            return (0, original_size, 0, file_path.name, None)

    except subprocess.CalledProcessError as e:
        if temp_path.exists(): temp_path.unlink()
        # Return stdout/stderr to diagnose
        err_msg = f"Command failed: {e.cmd}\nStderr: {e.stderr.strip()}"
        return (2, original_size, 0, file_path.name, err_msg)
    except Exception as e:
        if temp_path.exists(): temp_path.unlink()
        return (2, original_size, 0, file_path.name, str(e))

def main():
    parser = argparse.ArgumentParser(description="Optimize WebP files recursively.")
    parser.add_argument("--dry-run", action="store_true", help="Simulate optimization without modifying files.")
    parser.add_argument("--workers", type=int, default=4, help="Number of concurrent workers (default: 4).")
    args = parser.parse_args()

    check_prerequisites()

    target_ext = ".webp"
    files_to_process = []
    root_dir = Path.cwd()

    print(f"Scanning {root_dir} for WebP files...")
    
    # Modern pathlib walk (Python 3.12+)
    for root, _, files in root_dir.walk():
        for file in files:
            if file.lower().endswith(target_ext) and not file.lower().endswith(".temp.webp"):
                files_to_process.append(root / file)

    total_files = len(files_to_process)
    if total_files == 0:
        print("No WebP files found.")
        return

    mode_str = " (DRY RUN)" if args.dry_run else ""
    print(f"Found {total_files} files. Optimizing with max_workers={args.workers}{mode_str}...")

    stats = {"optimized": 0, "skipped": 0, "errors": 0, "saved_bytes": 0, "total_orig": 0}
    errors_list = []

    # Parallel processing for speed
    with ThreadPoolExecutor(max_workers=args.workers) as executor:
        future_to_file = {executor.submit(process_file, f, args.dry_run): f for f in files_to_process}
        
        for i, future in enumerate(as_completed(future_to_file)):
            status, orig, saved, name, err_msg = future.result()
            
            stats["total_orig"] += orig
            if status == 1:
                stats["optimized"] += 1
                stats["saved_bytes"] += saved
                action_text = "WOULD OPTIMIZE" if args.dry_run else "UPDATED"
                print(f"[{i+1}/{total_files}] \033[92m{action_text}\033[0m {name} (-{format_bytes(saved)})")
            elif status == 0:
                stats["skipped"] += 1
                print(f"[{i+1}/{total_files}] SKIPPED {name}")
            else:
                stats["errors"] += 1
                print(f"[{i+1}/{total_files}] \033[91mERROR\033[0m   {name}")
                # Store error for summary, maybe print short version here
                if err_msg:
                    # Print first line of error to avoid spam
                    first_line = err_msg.split('\n')[0] if err_msg else "Unknown error"
                    print(f"    -> {first_line}")
                    errors_list.append(f"{name}: {err_msg}")

    print("-" * 50)
    print(f"PROCESSING COMPLETE{mode_str}")
    print("-" * 50)
    print(f"Files Optimized:       {stats['optimized']}")
    print(f"Files Skipped:         {stats['skipped']}")
    print(f"Errors:                {stats['errors']}")
    
    if stats['total_orig'] > 0:
        percent = (stats['saved_bytes'] / stats['total_orig']) * 100
        print(f"Total Space Saved:     {format_bytes(stats['saved_bytes'])} ({percent:.2f}%)")
    
    if errors_list:
        print("\n\033[91mError Summary (First 5):\033[0m")
        for err in errors_list[:5]:
             print(f"- {err}\n")
        if len(errors_list) > 5:
            print(f"... and {len(errors_list) - 5} more errors.")

if __name__ == "__main__":
    main()

