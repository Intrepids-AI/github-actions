#!/usr/bin/env python3
"""Fail if tfsec CRITICAL results include findings not in the baseline.

Baseline (optional) format:
{
  "version": 1,
  "findings": [
    {"rule_id": "AVD-AWS-0107", "resource": "aws_security_group.x", "path": "modules/foo/main.tf"}
  ]
}

Without a baseline file, any CRITICAL finding fails the gate.
"""
from __future__ import annotations

import argparse
import json
import os
import sys
from pathlib import Path
from typing import Any


def normalize_path(filename: str, repo_root: Path) -> str:
    p = Path(filename)
    try:
        return str(p.resolve().relative_to(repo_root.resolve())).replace("\\", "/")
    except Exception:
        # Already relative or outside repo — strip leading ./ and abs noise
        s = filename.replace("\\", "/")
        root = str(repo_root.resolve()).replace("\\", "/")
        if s.startswith(root + "/"):
            return s[len(root) + 1 :]
        return s.lstrip("./")


def fingerprint(result: dict[str, Any], repo_root: Path) -> tuple[str, dict[str, str]]:
    loc = result.get("location") or {}
    path = normalize_path(str(loc.get("filename") or ""), repo_root)
    rule_id = str(result.get("rule_id") or result.get("long_id") or "unknown")
    resource = str(result.get("resource") or "")
    fp = f"{rule_id}|{resource}|{path}"
    return fp, {"rule_id": rule_id, "resource": resource, "path": path}


def load_results(path: Path) -> list[dict[str, Any]]:
    raw = path.read_text(encoding="utf-8")
    idx = raw.find("{")
    if idx < 0:
        raise SystemExit(f"No JSON object in tfsec output: {path}")
    data = json.loads(raw[idx:])
    return list(data.get("results") or [])


def load_baseline(path: Path | None) -> set[str] | None:
    if path is None or not path.is_file():
        return None
    data = json.loads(path.read_text(encoding="utf-8"))
    findings = data.get("findings") or []
    out: set[str] = set()
    for f in findings:
        out.add(f"{f.get('rule_id')}|{f.get('resource')}|{f.get('path')}")
    return out


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--results", required=True, type=Path)
    parser.add_argument("--baseline", type=Path, default=None)
    parser.add_argument("--repo-root", type=Path, default=Path(os.environ.get("GITHUB_WORKSPACE", ".")))
    parser.add_argument(
        "--write-baseline",
        type=Path,
        default=None,
        help="If set, write a baseline from current results and exit 0.",
    )
    args = parser.parse_args()

    results = load_results(args.results)
    fps: list[tuple[str, dict[str, str]]] = [fingerprint(r, args.repo_root) for r in results]

    if args.write_baseline is not None:
        payload = {
            "version": 1,
            "minimum_severity": "CRITICAL",
            "note": "SEC-33: known CRITICAL debt. Gate fails only on fingerprints not listed here.",
            "findings": sorted((meta for _, meta in fps), key=lambda m: (m["path"], m["rule_id"], m["resource"])),
        }
        args.write_baseline.parent.mkdir(parents=True, exist_ok=True)
        args.write_baseline.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
        print(f"Wrote baseline with {len(payload['findings'])} finding(s) to {args.write_baseline}")
        return 0

    baseline = load_baseline(args.baseline)
    if not fps:
        print("tfsec CRITICAL gate: no CRITICAL findings.")
        return 0

    if baseline is None:
        print(f"tfsec CRITICAL gate: {len(fps)} CRITICAL finding(s) and no baseline — failing.")
        for _, meta in fps[:50]:
            print(f"  - {meta['rule_id']} {meta['path']} ({meta['resource']})")
        if len(fps) > 50:
            print(f"  ... and {len(fps) - 50} more")
        print("Fix findings or add .tfsec/critical-baseline.json for known debt (SEC-33).")
        return 1

    new = [(fp, meta) for fp, meta in fps if fp not in baseline]
    if new:
        print(f"tfsec CRITICAL gate: {len(new)} NEW CRITICAL finding(s) not in baseline — failing.")
        for _, meta in new[:50]:
            print(f"  - {meta['rule_id']} {meta['path']} ({meta['resource']})")
        if len(new) > 50:
            print(f"  ... and {len(new) - 50} more")
        return 1

    print(
        f"tfsec CRITICAL gate: {len(fps)} CRITICAL finding(s) all covered by baseline "
        f"({len(baseline)} entries). No new CRITICAL issues."
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
