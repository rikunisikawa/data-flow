# Subject Generalization

## Plan
- subject_id を跨いだ汎化性能を評価する
- GroupKFoldの分割ルールを明文化し、リークを防ぐ

## Spec
- 入力: 特徴量テーブル（subject_id含む）
- 出力: 汎化評価結果（`analysis/reports/`）
- 制約: 分割はsubject単位、seed固定、最終は `analysis/src/splits.py` に移植

## Task
- GroupKFoldでsubject単位の分割を実施
- 各foldの評価指標を算出し分布を可視化
- subject別の性能差を整理
- 検算ログ（行数・合計）を出力
- `analysis/tests/` に分割ルールのテストを追加
