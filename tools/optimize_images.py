#!/usr/bin/env python3

import subprocess
import shutil
import argparse
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor, as_completed

# Configuration
# WebP: Lossless, Best Compression
CWEBP_ARGS = ["-z", "9", "-quiet"]

# PNG: oxipng (Lossless)
# -o 4: Max optimization level
# --strip safe: Strip non-essential metadata
OXIPNG_ARGS = ["-o", "4", "--strip", "safe", "--quiet"]

# GIF: gifsicle (Lossless-ish optimization)
# -O3: Optimize heavily
GIFSICLE_ARGS = ["-O3", "-Okeep-empty", "--no-warnings"]

# SVG: svgo
# Default plugins are usually good, maybe ensure it's quiet
SVGO_ARGS = ["--quiet"]

# Magick for Animated WebP
# -coalesce is CRITICAL to prevent corruption (see ImageMagick issue #7386)
# -define webp:lossless=true -define webp:method=6 -quality 100 -loop 0
MAGICK_ANIM_ARGS = [
    "-coalesce",
    "-define", "webp:lossless=true",
    "-define", "webp:method=6",
    "-quality", "100",
    "-loop", "0"
]

TOOLS = {}

def check_prerequisites():
    """Checks if required tools are available in the system PATH."""
    global TOOLS
    
    TOOLS["cwebp"] = shutil.which("cwebp")
    TOOLS["oxipng"] = shutil.which("oxipng")
    TOOLS["gifsicle"] = shutil.which("gifsicle")
    TOOLS["svgo"] = shutil.which("svgo")
    TOOLS["magick"] = shutil.which("magick")

    missing = []
    if not TOOLS["cwebp"]: missing.append("cwebp (for .webp)")
    if not TOOLS["oxipng"]: missing.append("oxipng (for .png)")
    if not TOOLS["gifsicle"]: missing.append("gifsicle (for .gif)")
    if not TOOLS["svgo"]: missing.append("svgo (for .svg)")
    # magick is optional but needed for animated webp
    if not TOOLS["magick"]: missing.append("magick (for animated .webp)")
    
    if missing:
        print("\033[93mWarning: Some optimization tools are missing. Corresponding file types will be skipped.\033[0m")
        for tool in missing:
            print(f"  - {tool}")
        print("To install all: brew install webp oxipng gifsicle svgo imagemagick\n")

def is_webp_animated(file_path: Path) -> bool:
    """
    Reads the WebP header to check for the Animation flag.
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
    n = float(size)
    power_labels = {0: 'bytes', 1: 'KB', 2: 'MB', 3: 'GB', 4: 'TB'}
    loop = 0
    while n >= power and loop < len(power_labels) - 1:
        n /= power
        loop += 1
    format_spec = ".0f" if loop == 0 else ".2f"
    return f"{n:{format_spec}} {power_labels[loop]}"

def optimize_file(file_path: Path, dry_run: bool = False):
    """
    Optimizes a single file using the appropriate tool.
    Returns: (status_code, original_size, saved_bytes, path_str, error_msg)
    """
    # 0=Skipped, 1=Optimized, 2=Error
    original_size = get_size(file_path)
    temp_path = file_path.with_suffix(file_path.suffix + ".temp" + file_path.suffix)
    ext = file_path.suffix.lower()
    
    cmd = []
    
    # Select Tool and Command
    if ext == ".webp":
        if is_webp_animated(file_path):
            if not TOOLS["magick"]:
                 return (0, original_size, 0, file_path.name, "Skipped (Animated WebP, need magick)")
            # Use magick for animated WebP
            cmd = ["magick", str(file_path)] + MAGICK_ANIM_ARGS + [str(temp_path)]
        else:
            if not TOOLS["cwebp"]:
                return (0, original_size, 0, file_path.name, "Tool 'cwebp' missing")
            cmd = ["cwebp", str(file_path)] + CWEBP_ARGS + ["-o", str(temp_path)]
        
    elif ext == ".png":
        if not TOOLS["oxipng"]:
            return (0, original_size, 0, file_path.name, "Tool 'oxipng' missing")
        # oxipng modifies in place by default, but supports --out
        cmd = ["oxipng", str(file_path), "--out", str(temp_path)] + OXIPNG_ARGS

    elif ext == ".gif":
        if not TOOLS["gifsicle"]:
            return (0, original_size, 0, file_path.name, "Tool 'gifsicle' missing")
        # gifsicle reads stdin or file, outputs to stdout by default usually, or -o
        cmd = ["gifsicle", str(file_path), "-o", str(temp_path)] + GIFSICLE_ARGS

    elif ext == ".svg":
        if not TOOLS["svgo"]:
            return (0, original_size, 0, file_path.name, "Tool 'svgo' missing")
        # svgo -i input -o output
        cmd = ["svgo", "-i", str(file_path), "-o", str(temp_path)] + SVGO_ARGS

    else:
        return (0, original_size, 0, file_path.name, "Unsupported format")

    try:
        # Execute Optimization
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)

        # Check if temp file was created (some tools might not create it if no savings? usually they do)
        if not temp_path.exists():
            # Special case: some tools might fail silently or not output if error
            return (2, original_size, 0, file_path.name, "Output file not created")

        new_size = get_size(temp_path)

        # Check for savings
        # Note: For SVG, sometimes 'optimization' might increase size slightly if it adds standard headers, but usually decreases.
        # We only accept if size is smaller.
        if new_size < original_size:
            saved = original_size - new_size
            if dry_run:
                temp_path.unlink()
                return (1, original_size, saved, file_path.name, None)
            else:
                temp_path.replace(file_path) # Atomic replace
                return (1, original_size, saved, file_path.name, None)
        else:
            temp_path.unlink()
            return (0, original_size, 0, file_path.name, "Already optimized")

    except subprocess.CalledProcessError as e:
        if temp_path.exists(): temp_path.unlink()
        err_msg = f"Command failed: {e.cmd}\nStderr: {e.stderr.strip()}"
        return (2, original_size, 0, file_path.name, err_msg)
    except Exception as e:
        if temp_path.exists(): temp_path.unlink()
        return (2, original_size, 0, file_path.name, str(e))

def main():
    parser = argparse.ArgumentParser(description="Optimize images (WebP, PNG, GIF, SVG) recursively.")
    parser.add_argument("directory", nargs="?", default=".", help="Directory to scan (default: current directory).")
    parser.add_argument("--dry-run", action="store_true", help="Simulate optimization without modifying files.")
    parser.add_argument("--workers", type=int, default=4, help="Number of concurrent workers (default: 4).")

    args = parser.parse_args()

    check_prerequisites()

    extensions = {".webp", ".png", ".gif", ".svg"}
    files_to_process = []
    root_dir = Path(args.directory).resolve()

    if not root_dir.exists() or not root_dir.is_dir():
        print(f"Error: Invalid directory '{root_dir}'")
        return

    print(f"Scanning {root_dir} for image files ({', '.join(extensions)})...")
    
    try:
        walker = root_dir.walk()
    except AttributeError:
        # Fallback for Python < 3.12
        import os
        walker = os.walk(root_dir)

    for root, dirs, files in walker:
        # If using os.walk, root is string
        root_path = Path(root)
        
        # Filter hidden directories (like .git)
        if any(part.startswith('.') for part in root_path.parts):
            continue
            
        for file in files:
            file_path = root_path / file
            if file_path.suffix.lower() in extensions and not file_path.name.endswith(".temp" + file_path.suffix):
                files_to_process.append(file_path)

    total_files = len(files_to_process)
    if total_files == 0:
        print("No image files found.")
        return

    mode_str = " (DRY RUN)" if args.dry_run else ""
    print(f"Found {total_files} files. Optimizing with max_workers={args.workers}{mode_str}...")

    stats = {"optimized": 0, "skipped": 0, "errors": 0, "saved_bytes": 0, "total_orig": 0}
    errors_list = []

    with ThreadPoolExecutor(max_workers=args.workers) as executor:
        future_to_file = {executor.submit(optimize_file, f, args.dry_run): f for f in files_to_process}
        
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
                # Optional: Verbose flag to see skipped files? For now keep it quiet or minimal.
                # print(f"[{i+1}/{total_files}] SKIPPED {name} ({err_msg if err_msg else 'No savings'})")
                pass
            else:
                stats["errors"] += 1
                print(f"[{i+1}/{total_files}] \033[91mERROR\033[0m   {name}")
                if err_msg:
                    first_line = err_msg.split('\n')[0]
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

if __name__ == "__main__":
    main()
