#!/usr/bin/env python3
"""Run code-review-graph detect-changes with .code-review-graphignore applied.

Upstream ``detect-changes`` scores the full git diff. Indexing already honors
``.code-review-graphignore`` (e.g. ``openspec/``), but PR risk did not. This
wrapper keeps OpenSpec (and other ignored paths) in the PR while scoring only
implementation paths.

Stdout: same JSON shape as ``code-review-graph detect-changes`` (for
``render_pr_comment.py``), plus optional ``filtered_out`` / ``planning_note``.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


def _repo_relative(repo_root: Path, path: str) -> str:
    p = Path(path)
    if p.is_absolute():
        try:
            return str(p.relative_to(repo_root)).replace("\\", "/")
        except ValueError:
            return str(p).replace("\\", "/")
    return str(p).replace("\\", "/").lstrip("./")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--base", default="HEAD~1")
    parser.add_argument("--repo", default=".")
    parser.add_argument(
        "--churn",
        action="store_true",
        help="Pass include_churn through to analyze_changes",
    )
    args = parser.parse_args()

    from code_review_graph.changes import analyze_changes
    from code_review_graph.context_savings import attach_context_savings, estimate_file_tokens
    from code_review_graph.graph import GraphStore
    from code_review_graph.incremental import (
        _load_ignore_patterns,
        _should_ignore,
        find_repo_root,
        get_changed_files,
    )

    # Optional helpers (present in 2.3.9+).
    try:
        from code_review_graph.incremental import discover_review_changes  # type: ignore[attr-defined]
    except ImportError:
        discover_review_changes = None  # type: ignore[assignment]
    try:
        from code_review_graph.incremental import resolve_data_dir  # type: ignore[attr-defined]
    except ImportError:
        resolve_data_dir = None  # type: ignore[assignment]

    start = Path(args.repo).resolve()
    repo_root = find_repo_root(start) or start
    if resolve_data_dir is not None:
        data_dir = resolve_data_dir(repo_root)
    else:
        data_dir = repo_root / ".code-review-graph"
    db_path = Path(data_dir) / "graph.db"
    if not db_path.is_file():
        print(
            f"Error: graph database missing at {db_path}; run build/update first.",
            file=sys.stderr,
        )
        return 1

    store = GraphStore(db_path)
    try:
        if discover_review_changes is not None:
            changed, base = discover_review_changes(repo_root, args.base)
        else:
            changed = get_changed_files(repo_root, args.base)
            base = args.base
    except Exception as exc:  # noqa: BLE001 — surface as detect-changes would
        print(f"Error: {exc}", file=sys.stderr)
        return 1
    if not changed:
        print("No changes detected.")
        return 0

    patterns = _load_ignore_patterns(repo_root)
    impl: list[str] = []
    filtered: list[str] = []
    for path in changed:
        rel = _repo_relative(repo_root, path)
        if _should_ignore(rel, patterns):
            filtered.append(rel)
        else:
            impl.append(path)

    if not impl:
        # Planning-only PR: still emit JSON so render succeeds with low risk.
        result = {
            "status": "ok",
            "summary": (
                f"No implementation files to score "
                f"({len(filtered)} path(s) excluded by .code-review-graphignore)."
            ),
            "risk_score": 0.0,
            "changed_functions": [],
            "affected_flows": [],
            "test_gaps": [],
            "review_priorities": [],
            "changed_files": [],
            "changed_file_count": 0,
            "filtered_out": filtered,
            "planning_note": (
                "All changed paths matched `.code-review-graphignore` "
                "(e.g. openspec/). Contract review: OpenSpec CI / human HITL."
            ),
        }
        print(json.dumps(result, indent=2))
        return 0

    analyze_kwargs: dict = {
        "repo_root": str(repo_root),
        "base": base,
        "include_churn": args.churn,
    }
    # 2.3.9+ treats missing VCS as a hard error when require_vcs=True.
    import inspect

    if "require_vcs" in inspect.signature(analyze_changes).parameters:
        analyze_kwargs["require_vcs"] = True
    result = analyze_changes(store, impl, **analyze_kwargs)
    original_tokens = estimate_file_tokens(repo_root, impl)
    attach_context_savings(result, original_tokens=original_tokens)
    result["filtered_out"] = filtered
    if filtered:
        result["planning_note"] = (
            f"Excluded {len(filtered)} path(s) via `.code-review-graphignore` "
            f"(still in the PR; not scored): "
            + ", ".join(filtered[:12])
            + ("…" if len(filtered) > 12 else "")
        )
        summary = result.get("summary") or ""
        result["summary"] = (
            f"{summary}\n  - Excluded from score (graphignore): {len(filtered)} path(s)"
        ).strip()

    print(json.dumps(result, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
