# 要件: ML グリッドサーチ自動化

## 機能要件（FR）
- FR-1: Group ベース分割（GroupShuffleSplit/StratifiedGroupKFold）に対応。
- FR-2: 検索空間を外部ファイル（YAML/JSON）で指定可能。
- FR-3: モデル（例: XGBoost/LightGBM/Sklearn Estimator）に対し GridSearch を実行。
- FR-4: 最良モデル・メトリクス・パラメータを S3 に保存。
- FR-5: Step Functions から起動し、入力で検索空間・分割戦略・乱数などを変更可能。

## 非機能要件（NFR）
- NFR-1: 5〜30分スケールのジョブを安定実行（Lambdaではなくコンテナ/SM）。
- NFR-2: ログ/メトリクスが CloudWatch に出力され、失敗時に原因特定可能。
- NFR-3: IaC で再現可能（ECS/SageMaker/Step Functions）。

## 受け入れ基準
- AC-1: dev 環境で指定の検索空間が実行され、S3 に `best_model.pkl`/`metrics.json`/`params.json` が保存される。
- AC-2: Group 分割が期待通りに機能し、リークがないことを確認（ユニットテスト）。
- AC-3: Step Functions 実行が成功し、遷移/エラーハンドリングが機能。

## インタフェース（例）
- 入力: `{ "split": "group", "cv": 5, "random_state": 42, "search_space_s3": "s3://.../hyperparams.yaml" }`
- 出力: `{ "s3_model": "s3://.../models/2025-09-27/best_model.pkl", "metrics": { ... } }`

---
