# Theme Template

新規テーマはこのフォルダをコピーして作成します。

## 構成
- `eda/` : EDA用のNotebookや実行済みNotebook
- `ml/` : 学習・評価用のNotebookやスクリプト
- `artifacts/` : 要約・指標・モデル・レポート
- `agent/` : state.json などループ状態
- `src/` : テーマ専用の実装コード

## 使い方
1. `analysis/themes/_template` を `analysis/themes/<theme>` にコピー
2. `src/` に `run_pipeline.py` と `extract_summary.py` を配置
3. `eda/` と `ml/` のNotebookを作成
4. `artifacts/` に成果物を保存
