#!/usr/bin/env python3
"""
tag_apps.py — Reads manifest.yaml from each app subdirectory and uses a local
LM Studio model to generate up to 5 descriptive tags, writing them back to the manifest.
"""

import os
import sys
import json
import time
import argparse
import signal
import requests
import yaml

# ── Configuration ─────────────────────────────────────────────────────────────

LM_STUDIO_URL = "http://127.0.0.1:1234/v1/chat/completions"
MODEL_ID = "mistralai/ministral-3b"
MAX_TAGS = 5
REQUEST_TIMEOUT = 30  # seconds

SYSTEM_PROMPT = f"""You are an app categorization assistant for a LED display app store.
Given an app manifest, respond ONLY with a valid JSON object — no explanation, no markdown.

Format:
{{"tags": ["tag1", "tag2", "tag3"], "category": "category_name"}}

Rules:
- Return between 1 and {MAX_TAGS} lowercase tags
- Tags should be short (1-2 words max)
- Choose tags that describe the app's content and purpose

Good tag examples (use these as primary suggestions):
  finance, crypto, weather, sports, news, art, clock, transit, fun, utility,
  productivity, nature, music, gaming, retro, health, space, food, travel,
  driving, smart-home, fitness, calendar, world, calendar, stocks, tides, surf,
  skiing, bike, bus, subway, train, flight, airline, tv, movies, anime,
  pokemon, steam, chess, twitch, anime, horoscope, flags, history, sunrise-sunset,
  moon-phase, iss, earthquakes, air-quality, uv, pollen, temperature, thermostat,
  home-assistant, plex, tesla, wifi, qr-code, pets, jokes, nfl, nba, nhl, mlb,
  soccer, football, baseball, basketball, hockey, formula-1, tennis, golf,
  nascar, cricket, rugby, mls, epl, espn, standings, scores

Category must be one of (use these as primary suggestions):
  news, weather, clocks, sports, finance, entertainment, health, lifestyle,
  technology, science, utilities, gaming, art, music, food, travel, shopping,
  social, education, reference, transit, driving, smart-home, community

Do NOT include the app name as a tag
- Do NOT wrap output in markdown fences
"""

# ── LM Studio call ─────────────────────────────────────────────────────────────


def query_lm_studio(manifest_text: str) -> tuple[list[str], str]:
    payload = {
        "model": MODEL_ID,
        "messages": [
            {"role": "system", "content": SYSTEM_PROMPT},
            {"role": "user", "content": f"App manifest:\n\n{manifest_text}"},
        ],
        "temperature": 0.2,  # low temp for consistent classification
        "max_tokens": 150,
    }

    try:
        resp = requests.post(LM_STUDIO_URL, json=payload, timeout=REQUEST_TIMEOUT)
        resp.raise_for_status()
    except requests.exceptions.ConnectionError:
        print("  ✗ Cannot connect to LM Studio — is it running on port 1234?")
        return [], ""
    except requests.exceptions.HTTPError as e:
        print(f"  ✗ HTTP error: {e}")
        return [], ""
    except requests.exceptions.Timeout:
        print("  ✗ Request timed out")
        return [], ""

    raw = resp.json()["choices"][0]["message"]["content"].strip()

    # Strip accidental markdown fences if the model adds them anyway
    if raw.startswith("```"):
        raw = "\n".join(
            line for line in raw.splitlines() if not line.strip().startswith("```")
        ).strip()

    try:
        data = json.loads(raw)
        tags = data.get("tags", [])
        category = data.get("category", "")
        # Sanitise: lowercase, strip whitespace, limit count
        return (
            [str(t).lower().strip() for t in tags[:MAX_TAGS] if t],
            str(category).lower().strip() if category else "",
        )
    except json.JSONDecodeError:
        print(f"  ✗ Model returned non-JSON: {raw!r}")
        return [], ""


# ── Manifest helpers ───────────────────────────────────────────────────────────


def load_manifest(path: str) -> dict:
    with open(path, "r", encoding="utf-8") as f:
        return yaml.safe_load(f) or {}


def save_manifest(path: str, manifest: dict, tags: list, category: str) -> None:
    # Remove existing tags/category keys if present
    manifest_copy = {k: v for k, v in manifest.items() if k not in ("tags", "category")}

    # Add new tags and category
    if category:
        manifest_copy["category"] = category
    manifest_copy["tags"] = tags

    class NoWrapDumper(yaml.SafeDumper):
        def write_line_break(self, data=None):
            return super().write_line_break(data)

        def increase_indent(self, flow=False, indentless=False):
            return super().increase_indent(flow, False)

    with open(path, "w", encoding="utf-8") as f:
        f.write("---\n")
        yaml.dump(
            manifest_copy,
            f,
            Dumper=NoWrapDumper,
            default_flow_style=False,
            allow_unicode=True,
            sort_keys=False,
            width=float("inf"),
        )


# ── Main loop ──────────────────────────────────────────────────────────────────


def process_apps(root_dir: str, overwrite: bool, dry_run: bool) -> None:
    root_dir = os.path.abspath(root_dir)

    if not os.path.isdir(root_dir):
        print(f"Error: '{root_dir}' is not a directory.")
        sys.exit(1)

    # Collect all app directories that contain a manifest.yaml
    app_dirs = sorted(
        [
            entry.path
            for entry in os.scandir(root_dir)
            if entry.is_dir()
            and os.path.isfile(os.path.join(entry.path, "manifest.yaml"))
        ]
    )

    if not app_dirs:
        print(f"No subdirectories with manifest.yaml found in '{root_dir}'.")
        sys.exit(0)

    print(f"Found {len(app_dirs)} app(s) in '{root_dir}'\n")
    if dry_run:
        print("  *** DRY RUN — manifests will NOT be modified ***\n")

    ok_count = 0
    skip_count = 0
    fail_count = 0

    for i, app_dir in enumerate(app_dirs, start=1):
        app_name = os.path.basename(app_dir)
        manifest_path = os.path.join(app_dir, "manifest.yaml")

        print(f"[{i}/{len(app_dirs)}] {app_name}")

        manifest = load_manifest(manifest_path)

        # Skip if tags key already exists in manifest (unless --overwrite is set)
        if "tags" in manifest and not overwrite:
            existing_tags = manifest.get("tags", [])
            print(f"  → skipping (already has tags: {existing_tags})")
            skip_count += 1
            continue

        # Serialise manifest to text for the prompt (exclude existing tags to avoid bias)
        manifest_for_prompt = {k: v for k, v in manifest.items() if k != "tags"}
        manifest_text = yaml.dump(
            manifest_for_prompt, default_flow_style=False, allow_unicode=True
        )

        tags, category = query_lm_studio(manifest_text)

        # Override category to "clocks" if app is a clock
        app_name_lower = app_name.lower()
        if (
            "clock" in app_name_lower
            or app_name_lower.endswith("time")
            or "world clock" in app_name_lower
        ):
            category = "clocks"

        # Override category to "weather" if app is weather-related
        weather_keywords = [
            "weather",
            "temperature",
            "temp",
            "forecast",
            "rain",
            "sun",
            "snow",
            "storm",
            "wind",
            "humidity",
            "uv",
            "pollen",
            "air quality",
            "tide",
            "surf",
            "ski",
            "snow",
        ]
        if any(kw in app_name_lower for kw in weather_keywords):
            category = "weather"

        if not tags:
            print("  ✗ No tags returned — skipping")
            fail_count += 1
            continue

        if manifest.get("supports2x"):
            tags.append("wide 2x support")

        print(f"  ✓ category: {category}, tags: {tags}")

        if not dry_run:
            save_manifest(manifest_path, manifest, tags, category)

        ok_count += 1

        # Small delay to avoid hammering the local server
        if i < len(app_dirs):
            time.sleep(0.3)

    print(f"\nDone — {ok_count} tagged, {skip_count} skipped, {fail_count} failed.")


# ── CLI ────────────────────────────────────────────────────────────────────────


def main():
    parser = argparse.ArgumentParser(
        description="Tag LED display app manifests using a local LM Studio model."
    )
    parser.add_argument(
        "apps_dir",
        nargs="?",
        default=".",
        help="Root directory containing app subdirectories (default: current dir)",
    )
    parser.add_argument(
        "--overwrite",
        action="store_true",
        help="Re-tag apps that already have tags",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Print tags without writing them to manifest.yaml",
    )
    args = parser.parse_args()

    def signal_handler(sig, frame):
        print("\n\nInterrupted. Quitting gracefully.")
        sys.exit(0)

    signal.signal(signal.SIGINT, signal_handler)

    process_apps(args.apps_dir, overwrite=args.overwrite, dry_run=args.dry_run)


if __name__ == "__main__":
    main()
