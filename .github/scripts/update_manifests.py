import subprocess
import os
import yaml
import glob
import sys

def get_git_dates(path):
    # Get all commit dates for the path
    try:
        # Define patterns for commits to ignore (automated metadata updates)
        ignore_patterns = [
            "Add timestamp metadata",
            "Implement sorting by newest",
            "Merge updated-apps",
            "Fix YAML formatting",
            "Update manifest metadata",
            "Merge branch",
            "Tag consolidation",
            "llm generated categories",
            "Fix Updates and script",
            "Fix updated ts",
            "Implement sorting by newest and last updated in app viewer"
        ]
        ignore_regex = "|".join(ignore_patterns)

        # Use TZ=UTC to get dates in UTC format.
        env = os.environ.copy()
        env["TZ"] = "UTC"

        # Get published (oldest)
        cmd_pub = ["git", "log", "--reverse", "--date=iso-strict-local", "--format=%ad", "--", path]
        output_pub = subprocess.check_output(cmd_pub, env=env).decode("utf-8").strip()
        if not output_pub:
            return None, None
        published = output_pub.splitlines()[0]

        # Get updated (newest, excluding automated commits)
        cmd_upd = [
            "git", "log", "-1", "--date=iso-strict-local", "--format=%ad",
            "--invert-grep", f"--grep={ignore_regex}", "--extended-regexp",
            "--", path
        ]
        output_upd = subprocess.check_output(cmd_upd, env=env).decode("utf-8").strip()

        # If no "real" update found, use published date
        updated = output_upd if output_upd else published

        return published, updated
    except Exception as e:
        print(f"Error getting dates for {path}: {e}")
        return None, None

class IndentDumper(yaml.SafeDumper):
    def increase_indent(self, flow=False, indentless=False):
        return super(IndentDumper, self).increase_indent(flow, False)

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

    if data.get('tags') is None:
        data['tags'] = []

    if changed:
        print(f"Updating {manifest_path}: published={published}, updated={updated}")
        with open(manifest_path, 'w', encoding='utf-8') as f:
            yaml.dump(data, f, Dumper=IndentDumper, sort_keys=False, default_flow_style=False, explicit_start=True, allow_unicode=True, width=1000, indent=4)


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
