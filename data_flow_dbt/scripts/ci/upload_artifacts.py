#!/usr/bin/env python3
"""Upload dbt artifacts to object storage."""

import json
import os
from pathlib import Path
from typing import Dict

import boto3


def load_artifact_paths(target_dir: Path) -> Dict[str, str]:
    manifest = target_dir / "manifest.json"
    run_results = target_dir / "run_results.json"
    catalog = target_dir / "catalog.json"
    return {
        "manifest": str(manifest),
        "run_results": str(run_results),
        "catalog": str(catalog),
    }


def upload_file(client, local_path: Path, bucket: str, prefix: str) -> None:
    key = f"{prefix}/{local_path.name}"
    client.upload_file(str(local_path), bucket, key)
    print(f"Uploaded {local_path} to s3://{bucket}/{key}")


def main() -> None:
    target_dir = Path(os.environ.get("DBT_TARGET_PATH", "target"))
    if not target_dir.exists():
        raise SystemExit(f"Target directory {target_dir} does not exist")

    artifact_bucket = os.environ.get("DBT_ARTIFACT_BUCKET", "example-dbt-artifacts")
    artifact_prefix = os.environ.get("DBT_ARTIFACT_PREFIX", "manifests")

    session = boto3.session.Session()
    client = session.client("s3")

    artifact_paths = load_artifact_paths(target_dir)
    for artifact_name, artifact_path in artifact_paths.items():
        path = Path(artifact_path)
        if path.exists():
            upload_file(client, path, artifact_bucket, f"{artifact_prefix}/{artifact_name}")
        else:
            print(f"Skipping missing artifact: {path}")

    summary_path = target_dir / "artifact_summary.json"
    summary = {
        "bucket": artifact_bucket,
        "prefix": artifact_prefix,
        "artifacts": artifact_paths,
    }
    summary_path.write_text(json.dumps(summary, indent=2, ensure_ascii=False))
    print(f"Wrote artifact summary to {summary_path}")


if __name__ == "__main__":
    main()
