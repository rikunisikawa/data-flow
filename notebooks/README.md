# Notebooks for EDA and Modeling

This folder contains Jupyter notebooks for local analysis and model training.

## VS Codeでの実行（推奨フロー / 仕組みの説明）

- 仕組み概要:
  - VS Code の Jupyter 拡張は「カーネル（ipykernel）」に接続してノートブックを実行します。
  - カーネルはローカルの Python 環境（venv/conda/pyenv など）上で動作します。VS Code 単体で Python が付属しているわけではありません。
  - Anaconda は必須ではありません。任意の Python 3.11 環境で OK。重要なのは、その環境に `ipykernel` と必要ライブラリが入っていることです。

- 必要な拡張機能（VS Code）:
  - "Python" と "Jupyter" をインストール

- 推奨セットアップ手順（venv の例）:
  1) 仮想環境の作成と有効化
     - `python -m venv .venv`
     - Linux/Mac: `source .venv/bin/activate`
     - Windows: `.venv\Scripts\activate`
  2) 依存インストール（ノート用）
     - `pip install -r notebooks/requirements.txt`
     - 依存に `ipykernel` が含まれているため、これでカーネルも用意されます。
  3) VS Code のカーネル選択
     - ノート右上のカーネル選択から、上記 venv の Python を選ぶ（表示名はパスや環境名）
     - 見つからない場合は VS Code を再起動、または `Python: Select Interpreter` で先にインタプリタを指定

- 環境変数/認証:
  - 本リポジトリのノートは `dotenv` で `.env`（なければ `.env.dev`）を自動読み込みします。
  - AWS 認証はローカルの認証情報に依存（`aws configure` / `aws sso login` / `AWS_PROFILE` など）。
  - 主要変数: `AWS_REGION`, `ATHENA_WORK_GROUP`, `GLUE_STAGE_DATABASE`, `DBT_SCHEMA`, `S3_STAGING_DIR`, `S3_DATA_DIR`。

- トラブルシュート（何も表示されない等）:
  - カーネル未選択/未起動: カーネルを選び直し、`print("hello")` など最小セルで確認。
  - 依存未インストール: 選択中カーネルの環境で `pip install -r notebooks/requirements.txt` を実行。
  - ログ確認: コマンドパレット → "Jupyter: Show Output" で実行時エラーを確認。
  - Athenaが重い/権限不足: ノート先頭に `FORCE_SYNTHETIC = True` を定義し、データ取得セルでフォールバックを強制することでローカル検証可能。

## Setup
- Python 3.11 is recommended
- Create and activate a virtualenv (optional)

```
python -m venv .venv
source .venv/bin/activate  # Windows: .venv\\Scripts\\activate
```

- Install requirements

```
pip install -r notebooks/requirements.txt
```

- Ensure repo root has `.env.dev` (or `.env`). The notebook loads it to get:
  - `AWS_REGION`, `ATHENA_WORK_GROUP`
  - `GLUE_STAGE_DATABASE`, `DBT_SCHEMA`
  - `S3_STAGING_DIR`, `S3_DATA_DIR`

## Run

```
jupyter notebook  # or: jupyter lab
```

Open `01_eda_modeling.ipynb` and run cells in order.

## Notes
- The notebook uses AWS SDK auth from your environment (e.g., `aws sso login` / `aws configure` or GitHub OIDC if running in CI-like env).
- Data source:
  - Athena Catalog: `awsdatacatalog`
  - Stage DB: `${GLUE_STAGE_DATABASE}` (e.g., `dev_stage_mhealth`)
  - Processed DB (dbt outputs): `${DBT_SCHEMA}` (e.g., `dev_processed`)
- Results can be written to `${S3_DATA_DIR}` under `notebooks/` prefix.

### FAQ（よくある質問）
- Q: Anaconda は必須ですか？
  - A: 必須ではありません。venv など任意の Python 環境で動きます。重要なのは `ipykernel` と必要ライブラリがその環境に入っていることです。
- Q: VS Code だけで完結しますか？
  - A: 実行自体は VS Code の Jupyter 拡張がローカルの Python カーネルに接続して行います。VS Code に Python ランタイムは含まれないため、ローカルの Python 環境は必要です。
- Q: カーネルが見つかりません。
  - A: 依存インストール後に VS Code を再起動、または `Python: Select Interpreter` で対象 venv/conda 環境を選択してください。

