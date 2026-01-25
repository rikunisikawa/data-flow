# Reporting

## Plan
- 主要結果を図表として整理し、意思決定に使える形で出力する
- EDA / Features / Models / Generalization の成果を統合する

## Spec
- 入力: 各テーマの成果物
- 出力: まとめ図表・比較表（`analysis/reports/`）
- 制約: 再現性確保、最終成果は `analysis/reports/` に保存

## Task
- 図表（分布、特徴量重要度、性能比較）を統一フォーマットで作成
- 主要結果の表（モデル比較、subject汎化）を作成
- 重要な前提（seed/データ仕様/分割ルール）を明記
- 再実行可能なスクリプト化（必要なら `analysis/src/reporting.py`）
