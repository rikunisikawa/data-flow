#!/usr/bin/env python3
"""
EDA runner for mHealth log files.
Outputs basic stats, counts, and plots into analysis/reports/eda/.
"""
from __future__ import annotations

import argparse
import json
import logging
import math
import os
import re
from collections import Counter, defaultdict
from typing import Dict, Iterable, List

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import seaborn as sns

try:
    from convert_log_to_parquet.convert_log_to_parquet import COLUMN_NAMES
except ImportError:
    COLUMN_NAMES = [
        "chest_acc_x",
        "chest_acc_y",
        "chest_acc_z",
        "chest_ecg_1",
        "chest_ecg_2",
        "left_ankle_acc_x",
        "left_ankle_acc_y",
        "left_ankle_acc_z",
        "left_ankle_gyro_x",
        "left_ankle_gyro_y",
        "left_ankle_gyro_z",
        "left_ankle_mag_x",
        "left_ankle_mag_y",
        "left_ankle_mag_z",
        "right_lower_arm_acc_x",
        "right_lower_arm_acc_y",
        "right_lower_arm_acc_z",
        "right_lower_arm_gyro_x",
        "right_lower_arm_gyro_y",
        "right_lower_arm_gyro_z",
        "right_lower_arm_mag_x",
        "right_lower_arm_mag_y",
        "right_lower_arm_mag_z",
        "activity_label",
    ]

SUBJECT_PATTERN = re.compile(r"mHealth_subject(\d+)\.log$", re.IGNORECASE)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Run EDA for mHealth logs.")
    parser.add_argument(
        "--input-dir",
        default=os.path.join("analysis", "data"),
        help="Directory containing mHealth_subject*.log files.",
    )
    parser.add_argument(
        "--output-dir",
        default=os.path.join("analysis", "reports", "eda"),
        help="Output directory for reports.",
    )
    parser.add_argument(
        "--chunksize",
        type=int,
        default=200_000,
        help="Chunk size for streaming read.",
    )
    return parser.parse_args()


def setup_logger() -> logging.Logger:
    logger = logging.getLogger("mhealth_eda")
    if not logger.handlers:
        handler = logging.StreamHandler()
        formatter = logging.Formatter("%(asctime)s %(levelname)s %(message)s")
        handler.setFormatter(formatter)
        logger.addHandler(handler)
    logger.setLevel(logging.INFO)
    return logger


def find_log_files(input_dir: str) -> List[str]:
    candidates = []
    for name in os.listdir(input_dir):
        if name.lower().startswith("mhealth_subject") and name.lower().endswith(".log"):
            candidates.append(os.path.join(input_dir, name))
    return sorted(candidates)


def extract_subject_id(path: str) -> int:
    match = SUBJECT_PATTERN.search(os.path.basename(path))
    if not match:
        raise ValueError(f"Could not extract subject_id from {path}")
    return int(match.group(1))


def init_stats(columns: Iterable[str]) -> Dict[str, Dict[str, float]]:
    stats = {}
    for col in columns:
        stats[col] = {
            "count": 0.0,
            "missing": 0.0,
            "sum": 0.0,
            "sumsq": 0.0,
            "min": math.inf,
            "max": -math.inf,
        }
    return stats


def update_stats(stats: Dict[str, Dict[str, float]], chunk: pd.DataFrame) -> None:
    numeric = chunk[COLUMN_NAMES]
    counts = len(numeric)
    sums = numeric.sum(skipna=True)
    sums_sq = (numeric * numeric).sum(skipna=True)
    mins = numeric.min(skipna=True)
    maxs = numeric.max(skipna=True)
    missing = numeric.isna().sum()

    for col in COLUMN_NAMES:
        stats[col]["count"] += counts
        stats[col]["missing"] += float(missing[col])
        stats[col]["sum"] += float(sums[col])
        stats[col]["sumsq"] += float(sums_sq[col])
        stats[col]["min"] = min(stats[col]["min"], float(mins[col]))
        stats[col]["max"] = max(stats[col]["max"], float(maxs[col]))


def finalize_stats(stats: Dict[str, Dict[str, float]]) -> pd.DataFrame:
    rows = []
    for col, values in stats.items():
        count = values["count"]
        mean = values["sum"] / count if count else float("nan")
        variance = (values["sumsq"] / count - mean**2) if count else float("nan")
        std = math.sqrt(variance) if count else float("nan")
        rows.append(
            {
                "column": col,
                "count": int(count),
                "missing": int(values["missing"]),
                "mean": mean,
                "std": std,
                "min": values["min"],
                "max": values["max"],
                "sum": values["sum"],
            }
        )
    return pd.DataFrame(rows)


def save_counts(counter: Counter, path: str, label_name: str) -> None:
    df = pd.DataFrame(
        [{"label": key, "count": value} for key, value in counter.items()]
    ).sort_values("label")
    df.rename(columns={"label": label_name}, inplace=True)
    df.to_csv(path, index=False)


def plot_bar(df: pd.DataFrame, x: str, y: str, title: str, path: str) -> None:
    plt.figure(figsize=(10, 5))
    sns.barplot(data=df, x=x, y=y, color="#4C78A8")
    plt.title(title)
    plt.tight_layout()
    plt.savefig(path, dpi=150)
    plt.close()


def plot_heatmap(df: pd.DataFrame, title: str, path: str) -> None:
    plt.figure(figsize=(10, 6))
    sns.heatmap(df, cmap="Blues", cbar=True)
    plt.title(title)
    plt.tight_layout()
    plt.savefig(path, dpi=150)
    plt.close()


def main() -> int:
    args = parse_args()
    logger = setup_logger()

    input_dir = os.path.abspath(args.input_dir)
    output_dir = os.path.abspath(args.output_dir)
    os.makedirs(output_dir, exist_ok=True)

    log_files = find_log_files(input_dir)
    if not log_files:
        logger.error("No log files found in %s", input_dir)
        return 1

    stats = init_stats(COLUMN_NAMES)
    activity_counts: Counter = Counter()
    subject_counts: Counter = Counter()
    subject_activity_counts: Dict[int, Counter] = defaultdict(Counter)
    total_rows = 0

    for path in log_files:
        subject_id = extract_subject_id(path)
        logger.info("Processing %s (subject_id=%s)", path, subject_id)

        for chunk in pd.read_csv(
            path,
            sep=r"\s+",
            header=None,
            names=COLUMN_NAMES,
            chunksize=args.chunksize,
        ):
            update_stats(stats, chunk)
            total_rows += len(chunk)
            subject_counts[subject_id] += len(chunk)
            activity_counts.update(chunk["activity_label"].value_counts().to_dict())
            subject_activity_counts[subject_id].update(
                chunk["activity_label"].value_counts().to_dict()
            )

    stats_df = finalize_stats(stats)
    stats_df.to_csv(os.path.join(output_dir, "basic_stats.csv"), index=False)

    save_counts(activity_counts, os.path.join(output_dir, "activity_counts.csv"), "activity_label")
    save_counts(subject_counts, os.path.join(output_dir, "subject_counts.csv"), "subject_id")

    subject_activity_df = (
        pd.DataFrame(subject_activity_counts)
        .fillna(0)
        .astype(int)
        .sort_index(axis=0)
        .sort_index(axis=1)
    )
    subject_activity_df.to_csv(os.path.join(output_dir, "subject_activity_counts.csv"))

    checksums = {
        "total_rows": total_rows,
        "sum_by_column": stats_df.set_index("column")["sum"].to_dict(),
    }
    with open(os.path.join(output_dir, "checksums.json"), "w", encoding="utf-8") as f:
        json.dump(checksums, f, indent=2, sort_keys=True)

    logger.info("Total rows: %s", total_rows)
    logger.info("Sum by column: %s", checksums["sum_by_column"])

    plot_bar(
        pd.read_csv(os.path.join(output_dir, "activity_counts.csv")),
        x="activity_label",
        y="count",
        title="Activity Label Counts",
        path=os.path.join(output_dir, "activity_counts.png"),
    )
    plot_bar(
        pd.read_csv(os.path.join(output_dir, "subject_counts.csv")),
        x="subject_id",
        y="count",
        title="Subject Counts",
        path=os.path.join(output_dir, "subject_counts.png"),
    )
    plot_heatmap(
        subject_activity_df,
        title="Subject vs Activity Counts",
        path=os.path.join(output_dir, "subject_activity_heatmap.png"),
    )

    logger.info("Saved reports to %s", output_dir)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
