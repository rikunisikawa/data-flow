from __future__ import annotations

import argparse
import json
import logging
import os
from contextlib import contextmanager
from datetime import datetime, timezone
from pathlib import Path

import papermill as pm

from extract_summary import build_summary, write_outputs


LOGGER = logging.getLogger(__name__)


@contextmanager
def _chdir(path: Path):
    current = Path.cwd()
    os.chdir(path)
    try:
        yield
    finally:
        os.chdir(current)


def _load_state(state_path: Path) -> dict:
    if not state_path.exists():
        return {"runs": []}
    try:
        return json.loads(state_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        LOGGER.warning("state file is not valid json: %s", state_path)
        return {"runs": []}


def _write_state(state_path: Path, state: dict) -> None:
    state_path.parent.mkdir(parents=True, exist_ok=True)
    state_path.write_text(json.dumps(state, indent=2, ensure_ascii=True), encoding="utf-8")


def _resolve_executed_path(executed_dir: Path, notebook_path: Path, run_id: str | None) -> Path:
    base = notebook_path.stem
    suffix = f".{run_id}" if run_id and run_id != base else ""
    return executed_dir / f"{base}{suffix}.executed.ipynb"


def main() -> int:
    theme_root = Path(__file__).resolve().parents[1]
    analysis_root = theme_root.parents[1]

    parser = argparse.ArgumentParser(description="Run EDA notebook and extract summary.")
    parser.add_argument(
        "--notebook",
        type=Path,
        default=theme_root / "eda/notebooks/01_eda_overview.ipynb",
        help="Notebook to execute.",
    )
    parser.add_argument(
        "--executed-dir",
        type=Path,
        default=theme_root / "eda/executed",
        help="Directory to store executed notebooks.",
    )
    parser.add_argument(
        "--reports-dir",
        type=Path,
        default=analysis_root / "reports/eda",
        help="Directory containing EDA report CSV/JSON files.",
    )
    parser.add_argument(
        "--summary-path",
        type=Path,
        default=theme_root / "artifacts/summaries/01_eda_overview.summary.json",
        help="Output summary JSON path.",
    )
    parser.add_argument(
        "--findings-path",
        type=Path,
        default=theme_root / "artifacts/findings/01_eda_overview.findings.txt",
        help="Output findings text path.",
    )
    parser.add_argument(
        "--state-path",
        type=Path,
        default=theme_root / "agent/state.json",
        help="State file to track runs.",
    )
    parser.add_argument(
        "--workdir",
        type=Path,
        default=analysis_root,
        help="Working directory for notebook execution.",
    )
    parser.add_argument(
        "--run-id",
        type=str,
        default=None,
        help="Optional run id suffix for executed notebook.",
    )
    parser.add_argument("--topk", type=int, default=5, help="Top-k entries to keep.")
    args = parser.parse_args()

    logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")

    args.executed_dir.mkdir(parents=True, exist_ok=True)
    executed_path = _resolve_executed_path(args.executed_dir, args.notebook, args.run_id)

    notebook_path = args.notebook.resolve()
    executed_path = executed_path.resolve()

    LOGGER.info("executing notebook: %s", notebook_path)
    with _chdir(args.workdir):
        pm.execute_notebook(
            notebook_path.as_posix(),
            executed_path.as_posix(),
            parameters={},
        )
    LOGGER.info("notebook executed: %s", executed_path)

    summary = build_summary(args.reports_dir, topk=args.topk)
    write_outputs(summary, args.summary_path, args.findings_path)

    run_info = {
        "run_id": args.run_id or args.notebook.stem,
        "notebook": args.notebook.as_posix(),
        "executed_notebook": executed_path.as_posix(),
        "summary": args.summary_path.as_posix(),
        "findings": args.findings_path.as_posix(),
        "generated_at": datetime.now(timezone.utc).isoformat(),
    }
    state = _load_state(args.state_path)
    state["runs"].append(run_info)
    state["last_run"] = run_info
    _write_state(args.state_path, state)

    LOGGER.info("state updated: %s", args.state_path)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
