import subprocess
import struct
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor, as_completed
import os

# Configuration
FFMPEG_ARGS = [
    "-c:v", "libwebp",
    "-lossless", "1",
    "-compression_level", "6",
    "-q:v", "100",
    "-loop", "0",
    "-y"
]

# cwebp -z 9 is the specific shortcut for: Lossless + Quality 100 + Method 6 (Best)
CWEBP_ARGS = ["-z", "9", "-quiet"] 

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
    power = 2**10
    n = size
    power_labels = {0: '', 1: 'KB', 2: 'MB', 3: 'GB', 4: 'TB'}
    loop = 0
    while n > power:
        n /= power
        loop += 1
    return f"{n:.2f} {power_labels[loop]}"

def process_file(file_path: Path):
    """
    Optimizes a single file using the appropriate tool.
    Returns: (status_code, original_size, saved_bytes, path_str)
    """
    # 0=Skipped, 1=Optimized, 2=Error
    original_size = get_size(file_path)
    temp_path = file_path.with_suffix(file_path.suffix + ".temp.webp")
    
    animated = is_animated(file_path)
    
    try:
        if animated:
            # Use FFmpeg for Animations
            cmd = ["ffmpeg", "-i", str(file_path)] + FFMPEG_ARGS + [str(temp_path)]
            # FFmpeg is chatty, silence it
            subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)
        else:
            # Use cwebp for Stills
            cmd = ["cwebp", str(file_path)] + CWEBP_ARGS + ["-o", str(temp_path)]
            subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.PIPE, check=True)

        # Check results
        if not temp_path.exists():
            return (2, original_size, 0, file_path.name)

        new_size = get_size(temp_path)

        if new_size < original_size:
            saved = original_size - new_size
            temp_path.replace(file_path) # Atomic replacement
            return (1, original_size, saved, file_path.name)
        else:
            temp_path.unlink() # Delete temp
            return (0, original_size, 0, file_path.name)

    except subprocess.CalledProcessError:
        if temp_path.exists(): temp_path.unlink()
        return (2, original_size, 0, file_path.name)
    except Exception:
        if temp_path.exists(): temp_path.unlink()
        return (2, original_size, 0, file_path.name)

def main():
    target_ext = ".webp"
    files_to_process = []
    root_dir = Path.cwd()

    print(f"Scanning {root_dir} for WebP files...")
    
    # Modern pathlib walk (Python 3.12+)
    for root, _, files in root_dir.walk():
        for file in files:
            if file.lower().endswith(target_ext):
                files_to_process.append(root / file)

    total_files = len(files_to_process)
    if total_files == 0:
        print("No WebP files found.")
        return

    print(f"Found {total_files} files. optimizing with max_workers=4...")

    stats = {"optimized": 0, "skipped": 0, "errors": 0, "saved_bytes": 0, "total_orig": 0}

    # Parallel processing for speed
    # We limit workers to avoid CPU thrashing since encoding is intensive
    with ThreadPoolExecutor(max_workers=4) as executor:
        future_to_file = {executor.submit(process_file, f): f for f in files_to_process}
        
        for i, future in enumerate(as_completed(future_to_file)):
            status, orig, saved, name = future.result()
            
            stats["total_orig"] += orig
            if status == 1:
                stats["optimized"] += 1
                stats["saved_bytes"] += saved
                print(f"[{i+1}/{total_files}] \033[92mUPDATED\033[0m {name} (-{format_bytes(saved)})")
            elif status == 0:
                stats["skipped"] += 1
                print(f"[{i+1}/{total_files}] SKIPPED {name}")
            else:
                stats["errors"] += 1
                print(f"[{i+1}/{total_files}] \033[91mERROR\033[0m   {name}")

    print("-" * 50)
    print("PROCESSING COMPLETE")
    print("-" * 50)
    print(f"Files Optimized:       {stats['optimized']}")
    print(f"Files Skipped:         {stats['skipped']}")
    print(f"Errors:                {stats['errors']}")
    
    if stats['total_orig'] > 0:
        percent = (stats['saved_bytes'] / stats['total_orig']) * 100
        print(f"Total Space Saved:     {format_bytes(stats['saved_bytes'])} ({percent:.2f}%)")

if __name__ == "__main__":
    main()

