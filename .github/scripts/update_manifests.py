import subprocess
import os
import yaml
import glob

def get_git_dates(path):
    # Get all commit dates for the path
    try:
        # Use TZ=UTC to get dates in UTC format.
        # --date=iso-strict-local with TZ=UTC gives format like 2023-01-01T00:00:00Z
        cmd = ["git", "log", "--date=iso-strict-local", "--format=%ad", "--", path]
        env = os.environ.copy()
        env["TZ"] = "UTC"
        output = subprocess.check_output(cmd, stderr=subprocess.STDOUT, env=env).decode("utf-8").strip()
        if not output:
            return None, None
        dates = output.splitlines()
        published = dates[-1] # oldest
        updated = dates[0]    # newest
        return published, updated
    except Exception as e:
        print(f"Error getting dates for {path}: {e}")
        return None, None

def update_manifest(manifest_path):
    # Get the directory of the app
    app_dir = os.path.dirname(manifest_path)
    
    published, updated = get_git_dates(app_dir)
    if not published:
        print(f"Skipping {manifest_path} (no git history)")
        return

    # Check if we need to update
    with open(manifest_path, 'r') as f:
        try:
            data = yaml.safe_load(f)
        except Exception as e:
            print(f"Error parsing YAML in {manifest_path}: {e}")
            return

    if data is None:
        data = {}

    changed = False
    # Only set published if it's missing. This preserves historical dates
    # even when running in a shallow clone.
    if not data.get('published'):
        data['published'] = published
        changed = True
    
    # Always update the 'updated' date to the latest commit
    if data.get('updated') != updated:
        data['updated'] = updated
        changed = True

    if changed:
        print(f"Updating {manifest_path}: published={published}, updated={updated}")
        with open(manifest_path, 'w') as f:
            yaml.dump(data, f, sort_keys=False, default_flow_style=False, explicit_start=True)

import sys

def main():
    if len(sys.argv) > 1:
        # Use provided arguments (files or directories)
        manifests = []
        for arg in sys.argv[1:]:
            if arg.endswith("manifest.yaml"):
                manifests.append(arg)
            elif os.path.isdir(arg):
                m = os.path.join(arg, "manifest.yaml")
                if os.path.exists(m):
                    manifests.append(m)
    else:
        # Scan all apps
        manifests = glob.glob("apps/*/manifest.yaml")
    
    print(f"Checking {len(manifests)} manifests.")
    for m in manifests:
        update_manifest(m)

if __name__ == "__main__":
    main()
