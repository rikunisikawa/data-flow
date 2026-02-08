# Feature Engineering

## Plan
- 時系列ウィンドウ化と特徴量設計を行い、学習可能な形式に整理する
- window長とstrideの影響を検証し、初期設定を定める
- 特徴量の再現性と安定性を担保する

## Spec
- 入力: mHealth時系列データ
- 出力: 特徴量テーブル（`analysis/reports/`）
- 制約: seed固定、ウィンドウ仕様は設定化、最終は `analysis/src/features.py` に移植

## Task
- windowing（固定長・stride）を実装
- 統計特徴量（平均/標準偏差/エネルギー等）を作成
- 特徴量の列数・順序・dtypeを固定
- 検算ログ（行数・合計）を出力
- `analysis/tests/` にwindowingのユニットテストを追加
