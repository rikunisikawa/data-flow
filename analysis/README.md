# データ分析環境（Docker 前提）

このフォルダはデータサイエンティスト向けの再現性と品質を重視した分析環境です。
Docker で実行環境を固定し、テーマ別に分析を自動化できる構成を前提にしています。

## 推奨フォルダ構成（テーマ別）

```
analysis/
├── data/           # 入力データ（gitignore 対象）
├── configs/        # YAML 設定
├── reports/        # 共通の成果物置き場（必要時のみ）
├── themes/
│   ├── <theme>/
│   │   ├── eda/        # EDA用Notebook/実行済みNotebook
│   │   ├── ml/         # 学習/評価用Notebookやスクリプト
│   │   ├── artifacts/  # summaries/findings/metrics/models/reports
│   │   ├── agent/      # state.json など状態管理
│   │   └── src/        # テーマ専用の実装コード
│   └── _template/      # 新規テーマ用テンプレ
├── tests/         # 最低限の検証
├── pyproject.toml
└── README.md
```

## 使い方（Docker）

1. イメージをビルド
2. コンテナを起動
3. 必要なコマンドを実行

```bash
docker build -f analysis/docker/Dockerfile -t data-flow-analysis .
docker run --rm -it -v "$(pwd)":/workspace data-flow-analysis
```

コンテナ内での実行例:
```bash
python analysis/src/eda.py --input-dir analysis/data --output-dir analysis/reports/eda
python analysis/themes/mhealth/src/run_pipeline.py
```

## 使い方（uv / poetry + venv）
ローカルで実行する場合の参考手順です。

```bash
python -m venv .venv
source .venv/bin/activate
pip install -U pip
pip install -e .
```

## ルール（守ってほしいこと）

- Notebook は実験場。**最終成果は `src/` へ移植**する。
- 再実行は **1コマンドで可能**にする（CLI 化推奨）。
- 乱数 `seed` を固定する。
- 検算ログ（行数・合計チェックなど）を出力する。
- 成果物はテーマ配下の `artifacts/` に保存する。

## AI 指示テンプレ（コピペ用）

```
あなたはデータ分析の実装担当です。

・Dockerコンテナ内で動く前提で実装してください
・Notebook探索結果は最終的にsrc/へ移植
・pytestを追加
・Ruffに通るコード
・乱数seed固定
・検算ログを出力
・成果物はthemes/<theme>/artifacts/に保存
```

## AI ガードレール（必須）

分析開始時に必ず明示してください。

- 目的：意思決定内容 / 仮説
- データ仕様：粒度・列・単位
- 禁止事項：リーク・PII 処理・勝手な外れ値除外
- 出力条件：seed 固定 / 保存先
- 検証：行数・合計チェック

## よくある事故と対策

| 問題 | 対策 |
| --- | --- |
| 集計ズレ | dtype 固定 |
| データリーク | 時系列分割 |
| セル順依存 | src 移植 |
| 結果不安定 | seed 固定 |

## 自動化ループ（テーマ別）
テーマ別にNotebook実行→要約生成→次アクション提示を行う最小構成です。

- テーマ: `analysis/themes/<theme>`
- 実行コマンド: `python analysis/themes/<theme>/src/run_pipeline.py`
- 成果物:
  - 実行済みNotebook: `analysis/themes/<theme>/eda/executed/`
  - 要約JSON: `analysis/themes/<theme>/artifacts/summaries/`
  - 要約テキスト: `analysis/themes/<theme>/artifacts/findings/`
  - 状態管理: `analysis/themes/<theme>/agent/state.json`
