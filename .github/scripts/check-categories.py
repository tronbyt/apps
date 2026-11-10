#!/usr/bin/env python3
"""Validate manifest.yaml category fields against categories.yaml."""

from __future__ import annotations

import argparse
import glob
import sys
from collections import Counter
from pathlib import Path

import yaml

REPO_ROOT = Path(__file__).resolve().parents[2]
CATEGORIES_FILE = REPO_ROOT / "categories.yaml"
APPS_GLOB = str(REPO_ROOT / "apps" / "*" / "manifest.yaml")


def load_allowed_categories() -> set[str]:
    with CATEGORIES_FILE.open(encoding="utf-8") as handle:
        data = yaml.safe_load(handle) or {}

    categories = data.get("categories")
    if not isinstance(categories, list) or not categories:
        raise ValueError(f"{CATEGORIES_FILE} must define a non-empty 'categories' list")

    allowed = {str(category).strip().lower() for category in categories}
    if len(allowed) != len(categories):
        raise ValueError(f"{CATEGORIES_FILE} contains duplicate categories")

    return allowed


def validate_manifests(
    allowed: set[str],
    *,
    min_apps: int | None = None,
) -> list[str]:
    errors: list[str] = []
    counts: Counter[str] = Counter()

    for manifest_path in sorted(glob.glob(APPS_GLOB)):
        with open(manifest_path, encoding="utf-8") as handle:
            manifest = yaml.safe_load(handle) or {}

        category = manifest.get("category")
        app_name = Path(manifest_path).parent.name

        if category is None:
            errors.append(f"{app_name}: missing category")
            continue

        if not isinstance(category, str):
            errors.append(f"{app_name}: category must be a string, got {type(category).__name__}")
            continue

        normalized = category.strip().lower()
        if normalized != category:
            errors.append(f"{app_name}: category must be lowercase ({category!r})")

        if normalized not in allowed:
            errors.append(
                f"{app_name}: unknown category {category!r} "
                f"(allowed: {', '.join(sorted(allowed))})"
            )
            continue

        counts[normalized] += 1

    if min_apps is not None:
        for category in sorted(allowed):
            count = counts.get(category, 0)
            if count < min_apps:
                errors.append(
                    f"category {category!r} has {count} app(s); minimum is {min_apps}"
                )

    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--min-apps",
        type=int,
        default=None,
        help="Fail if any allowed category has fewer than this many apps",
    )
    args = parser.parse_args()

    try:
        allowed = load_allowed_categories()
    except (OSError, ValueError, yaml.YAMLError) as exc:
        print(f"Error loading categories: {exc}", file=sys.stderr)
        return 1

    errors = validate_manifests(allowed, min_apps=args.min_apps)
    if errors:
        print("Category validation failed:", file=sys.stderr)
        for error in errors:
            print(f"  - {error}", file=sys.stderr)
        return 1

    manifest_count = len(glob.glob(APPS_GLOB))
    print(
        f"✔ All {manifest_count} apps have valid categories "
        f"({len(allowed)} allowed categories)"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
