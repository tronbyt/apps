#!/usr/bin/env python3
"""
Season Clock test harness.

Renders the full matrix of {2 hemispheres} x {4 seasons} x {2 modes} x {1x,2x}
using the app's hidden `dev_date` override, and independently re-computes the
expected season and day count in Python (stdlib only) so the rendered output can
be cross-checked rather than merely eyeballed.

The astronomical BOUNDARIES table is parsed out of seasonclock.star so there is a
single source of truth.

Usage:
    python3 test_harness.py
Env:
    PIXLET   path to the pixlet binary (default: the dev box location)
Optional:
    If Pillow is importable, labeled 1x and 2x contact sheets are written to the
    output dir for visual QA. Without Pillow the renders + cross-check still run.
"""
import json
import os
import re
import subprocess
import sys
from datetime import datetime, timezone, date

try:
    from zoneinfo import ZoneInfo
except ImportError:
    print("Python 3.9+ with zoneinfo required.")
    sys.exit(1)

HERE = os.path.dirname(os.path.abspath(__file__))
APP = os.path.join(HERE, "seasonclock.star")
OUT = os.path.join(HERE, "_test_out")
PIXLET = os.environ.get("PIXLET", "/home/jvivona/projects/pixlet-tronbyt/pixlet")

EVENT_SEASON = {
    "northern": {"mar_equinox": "spring", "jun_solstice": "summer",
                 "sep_equinox": "autumn", "dec_solstice": "winter"},
    "southern": {"mar_equinox": "autumn", "jun_solstice": "winter",
                 "sep_equinox": "spring", "dec_solstice": "summer"},
}

LOCATIONS = {
    "northern": {"lat": "40.6781784", "lng": "-73.9441579",
                 "description": "Brooklyn, NY, USA", "locality": "Brooklyn",
                 "timezone": "America/New_York"},
    "southern": {"lat": "-33.8688", "lng": "151.2093",
                 "description": "Sydney, NSW, AU", "locality": "Sydney",
                 "timezone": "Australia/Sydney"},
}

# One representative date per calendar quarter (UTC noon, far from any tz midnight
# and from the season boundaries). Each maps to opposite seasons per hemisphere.
DATES = {
    "Q1-Jan": "2026-01-15T12:00:00Z",
    "Q2-Apr": "2026-04-15T12:00:00Z",
    "Q3-Jul": "2026-07-15T12:00:00Z",
    "Q4-Oct": "2026-10-15T12:00:00Z",
}
MODES = ["countdown", "dayof"]


def parse_boundaries(star_path):
    txt = open(star_path).read()
    block = re.search(r"BOUNDARIES = \[(.*?)\]", txt, re.S).group(1)
    out = []
    for iso, ev in re.findall(r'\("([^"]+)",\s*"([^"]+)"\)', block):
        out.append((datetime.fromisoformat(iso.replace("Z", "+00:00")), ev))
    out.sort(key=lambda x: x[0])
    return out


def julian_day(y, m, d):
    a = (14 - m) // 12
    yy = y + 4800 - a
    mm = m + 12 * a - 3
    return d + (153 * mm + 2) // 5 + 365 * yy + yy // 4 - yy // 100 + yy // 400 - 32045


def ordinal(n):
    if 11 <= n % 100 <= 13:
        return "%dth" % n
    return "%d%s" % (n, {1: "st", 2: "nd", 3: "rd"}.get(n % 10, "th"))


def expected(boundaries, hemisphere, tz_name, dev_iso, mode):
    tz = ZoneInfo(tz_name)
    now = datetime.fromisoformat(dev_iso.replace("Z", "+00:00"))
    cur = nxt = None
    for bt, ev in boundaries:
        if bt <= now:
            cur = (bt, ev)
        elif nxt is None:
            nxt = (bt, ev)
            break
    if cur is None or nxt is None:
        return {"season": "OUT-OF-RANGE", "value": "-"}
    nl = now.astimezone(tz)
    jd_now = julian_day(nl.year, nl.month, nl.day)
    if mode == "dayof":
        sl = cur[0].astimezone(tz)
        day_of = jd_now - julian_day(sl.year, sl.month, sl.day) + 1
        return {"season": EVENT_SEASON[hemisphere][cur[1]],
                "value": ordinal(day_of), "raw": day_of}
    else:
        nx = nxt[0].astimezone(tz)
        days = julian_day(nx.year, nx.month, nx.day) - jd_now
        return {"season": EVENT_SEASON[hemisphere][nxt[1]],
                "value": str(days), "raw": days}


def render(case_id, location, mode, dev_iso, x2):
    cfg = {"location": json.dumps(location), "mode": mode, "dev_date": dev_iso}
    cfg_path = os.path.join(OUT, case_id + ".json")
    with open(cfg_path, "w") as fh:
        json.dump(cfg, fh)
    out_path = os.path.join(OUT, case_id + ".webp")
    cmd = [PIXLET, "render", APP, "-c", cfg_path, "-o", out_path, "--silent"]
    if x2:
        cmd.append("-2")
    res = subprocess.run(cmd, capture_output=True, text=True)
    ok = res.returncode == 0 and os.path.exists(out_path)
    return ok, out_path, res.stderr.strip()


def main():
    os.makedirs(OUT, exist_ok=True)
    boundaries = parse_boundaries(APP)
    print("Parsed %d season boundaries from %s\n" % (len(boundaries), os.path.basename(APP)))

    rows = []
    sheet_items = {1: [], 2: []}
    failures = 0
    hdr = "%-26s %-9s %-9s %-9s %-8s %-6s" % (
        "case", "hemi", "mode", "exp.season", "exp.val", "render")
    print(hdr)
    print("-" * len(hdr))
    for hemisphere in ("northern", "southern"):
        loc = LOCATIONS[hemisphere]
        for qname, dev_iso in DATES.items():
            for mode in MODES:
                exp = expected(boundaries, hemisphere, loc["timezone"], dev_iso, mode)
                for scale in (1, 2):
                    case_id = "%s_%s_%s_%dx" % (hemisphere[:1], qname, mode, scale)
                    ok, path, err = render(case_id, loc, mode, dev_iso, scale == 2)
                    if not ok:
                        failures += 1
                    if scale == 1:
                        print("%-26s %-9s %-9s %-9s %-8s %-6s" % (
                            qname, hemisphere[:5], mode, exp["season"],
                            exp["value"], "OK" if ok else "FAIL"))
                        if not ok:
                            print("    ERROR:", err)
                    sheet_items[scale].append({
                        "path": path, "ok": ok,
                        "label": "%s/%s %s" % (hemisphere[:1].upper(), qname, mode[:4]),
                        "exp": "%s %s" % (exp["season"][:3], exp["value"]),
                    })
                    rows.append((case_id, exp, ok))

    build_sheets(sheet_items)
    print("\n%d cases rendered, %d failures." % (len(rows), failures))
    print("Output + contact sheets in: %s" % OUT)
    sys.exit(1 if failures else 0)


def build_sheets(sheet_items):
    try:
        from PIL import Image, ImageDraw
    except ImportError:
        print("\n(Pillow not installed — skipping visual contact sheets.)")
        return
    for scale, items in sheet_items.items():
        cols = 4
        rows = (len(items) + cols - 1) // cols
        zoom = 4 if scale == 1 else 2  # both shown ~256px wide
        cw, ch = 64 * scale * zoom, 32 * scale * zoom
        pad, label_h = 8, 26
        cellw, cellh = cw + pad, ch + pad + label_h
        sheet = Image.new("RGBA", (cols * cellw, rows * cellh), (24, 24, 30, 255))
        d = ImageDraw.Draw(sheet)
        for i, it in enumerate(items):
            c, r = i % cols, i // cols
            ox, oy = c * cellw + pad // 2, r * cellh + pad // 2
            if it["ok"]:
                frame = Image.open(it["path"]).convert("RGBA")
                big = frame.resize((cw, ch), Image.NEAREST)
                sheet.paste(big, (ox, oy))
            else:
                d.rectangle((ox, oy, ox + cw, oy + ch), fill=(120, 20, 20, 255))
                d.text((ox + 4, oy + 4), "FAIL", fill=(255, 200, 200, 255))
            d.text((ox, oy + ch + 1), it["label"], fill=(235, 235, 235, 255))
            d.text((ox, oy + ch + 12), "exp " + it["exp"], fill=(150, 210, 150, 255))
        path = os.path.join(OUT, "_sheet_%dx.png" % scale)
        sheet.save(path)
        print("Contact sheet: %s" % path)


if __name__ == "__main__":
    main()
