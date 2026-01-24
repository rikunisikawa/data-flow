# データ分析環境（VS Code / Dev Containers 前提）

このフォルダはデータサイエンティスト向けの再現性と品質を重視した分析環境です。
VS Code + Dev Containers を最優先とし、次点で `uv` / `poetry` + `venv` を想定しています。

## 推奨フォルダ構成

```
analysis/
├── src/        # 分析ロジック（関数化・再利用）
├── notebooks/  # 探索用（最終成果は src/ へ移植）
├── tests/      # 最低限の検証
├── data/       # 入力データ（gitignore 対象）
├── configs/    # YAML 設定
├── reports/    # 図表・成果物
├── pyproject.toml
└── README.md
```

## 使い方（Dev Containers）

1. VS Code で `analysis/` を開く
2. Command Palette → **Dev Containers: Reopen in Container**
3. 依存をインストール（必要に応じて）

```bash
pip install -r requirements.txt
```

> `requirements.txt` がない場合は `pyproject.toml` に合わせて追加してください。

## 使い方（uv / poetry + venv）

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
- 成果物は `reports/` に保存する。

## AI 指示テンプレ（コピペ用）

```
あなたはデータ分析の実装担当です。

・VS CodeのDev Container内で動く前提で実装してください
・Notebook探索結果は最終的にsrc/へ移植
・pytestを追加
・Ruffに通るコード
・乱数seed固定
・検算ログを出力
・成果物はreports/に保存
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
