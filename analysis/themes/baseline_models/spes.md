# Baseline Models

## Plan
- activity分類のベースラインを複数手法で比較する
- 評価指標を統一し、再現性のある比較表を作成する

## Spec
- 入力: 特徴量テーブル
- 出力: モデル比較表、混同行列（`analysis/reports/`）
- 制約: seed固定、評価は統一指標、最終は `analysis/src/models.py` / `analysis/src/metrics.py` に移植

## Task
- baselineモデル（例: logistic regression / random forest）を実装
- 指標（accuracy / F1 / macro-F1）を算出
- 混同行列と分類レポートを作成
- 検算ログ（行数・合計）を出力
- `analysis/tests/` に指標計算のテストを追加
