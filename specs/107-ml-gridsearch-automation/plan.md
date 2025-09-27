# 計画: 機械学習のグリッドサーチ自動化（Step Functions 統合）

**Branch**: `107-ml-gridsearch-automation` | **Owner**: ML Platform | **Date**: 2025-09-27

## 目的
- 特徴量（Athena/dbt 出力）を用いたモデル学習を自動化し、ハイパーパラメータ探索（GridSearch）を実装。
- Group 単位の分割（データリーク防止）を標準化し、成果物（モデル/メトリクス）を S3 に保存。

## スコープ
- Python 実装: `model_training/train_evaluate.py`（GroupShuffleSplit/StratifiedGroupKFold 対応）。
- 実行基盤: SageMaker Processing/Training もしくは ECS Fargate（本基盤のサーバレス方針に合わせ後者も可）。
- オーケストレーション: Step Functions で `Train → Evaluate → Register` を実行。

## 方針
- 検索空間は YAML/JSON で外部化（例: `configs/hyperparams.yaml`）。
- メトリクス: F1/Accuracy/Recall/Precision。Group 単位の評価をサマリ化。
- 出力: `s3://.../models/<date>/best_model.pkl` と `metrics.json`、`params.json`。

## フェーズ
1) PoC: ローカル/Docker で GridSearch 実装・小規模データで動作確認。
2) コンテナ化: 依存（pandas, scikit-learn, xgboost, awswrangler）をイメージ化。
3) 実行基盤: SageMaker Processing or ECS RunTask による実行を IaC 化。
4) Orchestration: Step Functions に学習ステップを追加、dbt 完了後に起動。
5) 記録と可視化: S3 への成果物保存、CloudWatch Logs、必要なら MLflow 導入を検討。

## DoD
- 指定の検索空間で GridSearch が完走し、best params とメトリクスが S3 に保存。
- 再現性（乱数固定）と Group 分割の一貫性が担保される。
- Step Functions から起動し、失敗時は FailState へ遷移。

---
