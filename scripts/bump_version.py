#!/usr/bin/env python3
"""Bumps pubspec.yaml's version before a release build.

version: MAJOR.MINOR.PATCH+BUILD — PATCH is our build counter within a
minor-version line (see CHANGELOG.md, e.g. "how many builds to 2.4" is
just the highest PATCH under a 2.4.x section); BUILD is the strictly
increasing versionCode/CFBundleVersion the stores require per upload.
Both move together so they never drift apart.
"""
import re
import sys
from pathlib import Path

pubspec = Path(__file__).resolve().parent.parent / "pubspec.yaml"
content = pubspec.read_text()

match = re.search(r"^version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)", content, re.M)
if not match:
    sys.exit("Could not find a version: MAJOR.MINOR.PATCH+BUILD line in pubspec.yaml")

major, minor, patch, build = (int(g) for g in match.groups())
patch += 1
build += 1
new_line = f"version: {major}.{minor}.{patch}+{build}"

content = re.sub(r"^version:.*$", new_line, content, count=1, flags=re.M)
pubspec.write_text(content)
print(new_line)
