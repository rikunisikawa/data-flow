# mHealth Analysis

## Plan
- Docker（最新Python）で実行環境を固定し、EDAの再現性を確保する
- Notebook実行→要約生成→次タスク提示の最小ループを構築する
- テーマ別に要約スキーマを分け、AIによる分析自動化を進める
- mHealth分類の評価戦略（指標・分割）を明確化し、自動学習ループへ拡張する

## Spec
- 入力: `analysis/data/` のmHealthデータ（stage相当）
- 出力: 図表と要約（`analysis/reports/`、`analysis/themes/mhealth/artifacts/`）
- 実行: Dockerベースは最新Python（例: `python:3.12`系）、Notebook実行は`papermill`
- 要約: テーマ別フォルダに独自`summary.json`を生成し、AIはその要約を入力に使う
- 学習: 分類タスク（`activity_label`）、評価指標は`macro F1`中心
- 分割: `subject_id`でGroupKFold（被験者リーク防止）
- 成果物: `metrics.json`、`model.pkl`、`report.html`を`analysis/themes/mhealth/artifacts/`配下に保存
- 制約: seed固定、外れ値除外は明示、結果は `analysis/src/eda.py` に移植

## Task
- Docker実行環境の作成（最新Pythonベース、依存固定）
- `papermill`でNotebook実行→`executed/`保存のスクリプト整備
- テーマ別`summary.json`生成（例: `analysis/themes/mhealth/artifacts/summaries/`）
- 欠損・外れ値・分布の要約設計と抽出ロジック化
- 分類ベースラインの実装（統計量特徴＋モデル、macro F1算出）
- GroupKFold評価とレポート生成の自動化
- `metrics.json`/`model.pkl`/`report.html`の出力設計
- 最終ロジックを `analysis/src/eda.py` に移植しテスト追加
