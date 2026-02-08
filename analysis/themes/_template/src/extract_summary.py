from __future__ import annotations

import argparse
import json
import logging
from datetime import datetime, timezone
from pathlib import Path

import pandas as pd


LOGGER = logging.getLogger(__name__)


def _load_csv(path: Path) -> pd.DataFrame | None:
    if not path.exists():
        return None
    return pd.read_csv(path)


def _load_json(path: Path) -> dict | None:
    if not path.exists():
        return None
    with path.open("r", encoding="utf-8") as file_obj:
        return json.load(file_obj)


def _topk_missing(basic_stats: pd.DataFrame, topk: int) -> list[dict]:
    if basic_stats is None:
        return []
    stats = basic_stats.copy()
    stats["missing_rate"] = stats["missing"] / stats["count"]
    stats = stats.sort_values(["missing_rate", "missing"], ascending=False).head(topk)
    return [
        {
            "column": row["column"],
            "missing_rate": float(row["missing_rate"]),
            "missing_count": int(row["missing"]),
        }
        for _, row in stats.iterrows()
    ]


def _constant_columns(basic_stats: pd.DataFrame) -> list[str]:
    if basic_stats is None:
        return []
    constant = basic_stats[basic_stats["std"] == 0]
    return constant["column"].tolist()


def _numeric_summary(basic_stats: pd.DataFrame, topk: int) -> list[dict]:
    if basic_stats is None:
        return []
    stats = basic_stats.head(topk)
    return [
        {
            "column": row["column"],
            "mean": float(row["mean"]),
            "std": float(row["std"]),
            "min": float(row["min"]),
            "max": float(row["max"]),
        }
        for _, row in stats.iterrows()
    ]


def _distribution_topk(
    counts_df: pd.DataFrame, label_col: str, topk: int
) -> list[dict]:
    if counts_df is None:
        return []
    counts = counts_df.sort_values("count", ascending=False).head(topk)
    return [
        {label_col: int(row[label_col]), "count": int(row["count"])}
        for _, row in counts.iterrows()
    ]


def build_summary(reports_dir: Path, topk: int = 5) -> dict:
    warnings: list[str] = []

    basic_stats = _load_csv(reports_dir / "basic_stats.csv")
    activity_counts = _load_csv(reports_dir / "activity_counts.csv")
    subject_counts = _load_csv(reports_dir / "subject_counts.csv")
    checksums = _load_json(reports_dir / "checksums.json")

    if basic_stats is None:
        warnings.append("missing basic_stats.csv")
    if activity_counts is None:
        warnings.append("missing activity_counts.csv")
    if subject_counts is None:
        warnings.append("missing subject_counts.csv")
    if checksums is None:
        warnings.append("missing checksums.json")

    total_rows = None
    if checksums and "total_rows" in checksums:
        total_rows = int(checksums["total_rows"])
    elif activity_counts is not None:
        total_rows = int(activity_counts["count"].sum())

    summary = {
        "schema_version": "1.0",
        "theme": "template",
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "dataset": {
            "rows": total_rows,
            "cols": int(basic_stats.shape[0]) if basic_stats is not None else None,
            "target": "activity_label",
            "time_index": None,
        },
        "quality": {
            "missing_rate_topk": _topk_missing(basic_stats, topk),
            "constant_columns": _constant_columns(basic_stats),
        },
        "distribution": {
            "numeric_summary_topk": _numeric_summary(basic_stats, topk),
            "target_distribution_topk": _distribution_topk(
                activity_counts, "activity_label", topk
            ),
            "subject_count_topk": _distribution_topk(subject_counts, "subject_id", topk),
        },
        "relationships": {
            "correlation_topk": [],
            "leakage_signals": [],
        },
        "notes": {
            "warnings": warnings,
            "errors": [],
        },
        "source_reports": {
            "basic_stats": str((reports_dir / "basic_stats.csv").as_posix()),
            "activity_counts": str((reports_dir / "activity_counts.csv").as_posix()),
            "subject_counts": str((reports_dir / "subject_counts.csv").as_posix()),
            "checksums": str((reports_dir / "checksums.json").as_posix()),
        },
    }

    return summary


def write_outputs(summary: dict, summary_path: Path, findings_path: Path) -> None:
    summary_path.parent.mkdir(parents=True, exist_ok=True)
    findings_path.parent.mkdir(parents=True, exist_ok=True)

    with summary_path.open("w", encoding="utf-8") as file_obj:
        json.dump(summary, file_obj, indent=2, ensure_ascii=True)

    findings_lines = [
        f"rows: {summary['dataset']['rows']}",
        f"cols: {summary['dataset']['cols']}",
        "top_activity_labels:",
    ]
    for item in summary["distribution"]["target_distribution_topk"]:
        findings_lines.append(f"  - {item['activity_label']}: {item['count']}")
    if summary["quality"]["missing_rate_topk"]:
        findings_lines.append("missing_rate_topk:")
        for item in summary["quality"]["missing_rate_topk"]:
            findings_lines.append(
                f"  - {item['column']}: {item['missing_rate']:.6f}"
            )
    if summary["notes"]["warnings"]:
        findings_lines.append("warnings:")
        for item in summary["notes"]["warnings"]:
            findings_lines.append(f"  - {item}")

    findings_path.write_text("\n".join(findings_lines) + "\n", encoding="utf-8")


def main() -> int:
    theme_root = Path(__file__).resolve().parents[1]
    analysis_root = theme_root.parents[1]

    parser = argparse.ArgumentParser(description="Extract EDA summary from reports.")
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
    parser.add_argument("--topk", type=int, default=5, help="Top-k entries to keep.")
    args = parser.parse_args()

    logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")
    summary = build_summary(args.reports_dir, topk=args.topk)
    write_outputs(summary, args.summary_path, args.findings_path)

    LOGGER.info("summary written: %s", args.summary_path)
    LOGGER.info("findings written: %s", args.findings_path)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
