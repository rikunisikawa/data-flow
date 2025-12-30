# 計画: dbt 実行環境の Docker 化

**Branch**: `105-dbt-dockerization` | **Date**: 2025-09-23

## 目的
- 現状ローカル実行している dbt（`dbt-core` + `dbt-athena-community`）を Docker 化し、開発者間で一貫した実行環境と再現性を確保する。
- 既存の `.env.dev` と `.dbt/profiles.yml` に基づく環境変数/プロファイル設定を維持しつつ、Docker 上で `dbt debug/run/test/docs` が動作することを保証する。

## スコープ
- 対象: dbt CLI 実行環境（ビルド・実行・ドキュメント閲覧）。
- 非対象: Lambda/Step Functions/Glue/Terraform の Docker 化（Terraform 用 compose は既存を尊重）。
- 変更を加える可能性がある箇所:
  - 新規: `docker/dbt/Dockerfile`、`docker/dbt/docker compose.yml`（またはルートに `docker compose.dbt.yml`）。
  - 新規: `data_flow_dbt/scripts/dbt-docker.sh`（ラッパー）
  - 既存: `ai-doc/infra/dbt_athena_setup.md`（Docker 手順の追記）

## 前提/制約（AGENTS.md 整合）
- 一貫性: 既存のディレクトリ構成・命名を踏襲。`.dbt/profiles.yml` と `.env(.dev)` をそのまま利用。
- 安全性: 認証情報はコード/イメージに埋め込まない。AWS 認証はマウント（`~/.aws`）または環境変数で注入。
- 冪等性: Docker イメージは再ビルド可能、`dbt run` は既存の冪等性要件（Athena/Glue 側）を満たす。
- コスト配慮: Docker 化自体はクラウドコストに影響しないが、`dbt run/test` の実行回数・スキャン量に注意。
- ポート利用: `dbt docs serve` はホストに `8080:8080` を公開。

## 設計方針
- ベースイメージ: `python:3.11-slim`
- 依存インストール: `pip install dbt-core dbt-athena-community`（必要に応じてバージョン固定）
- ランタイム権限: 非 root ユーザー追加（キャッシュ書込用の権限付与）。
- ボリューム/マウント:
  - リポジトリルートを `/work` にマウント
  - `~/.aws` を `/home/app/.aws:ro` にマウント（認証）
  - `.dbt` を `/work/.dbt` として参照（`DBT_PROFILES_DIR=/work/.dbt`）
- 環境変数: 既定はリポジトリルートの `.env.dev` を compose の `env_file` で読み込み（`.env` は必須にしない）。
- 実行ユーザー: `app:app`（UID/GID はホストと衝突しにくい 1000 系）。
 - コンテナ起動形態: 常駐（`sleep infinity`）で起動し、`docker compose exec dbt ...` で対話操作可能。

## フェーズ計画
1. コンテナ設計
   - Dockerfile と compose の設計（ユーザー、依存、ENTRYPOINT）。
2. 実装
   - `docker/dbt/Dockerfile` と `docker/dbt/docker compose.yml` を追加。
3. ラッパー（任意）
   - 必要に応じて `data_flow_dbt/scripts/dbt-docker.sh` を追加し、`dbt` コマンド互換の UX を提供（現状は compose の `exec`を推奨）。
4. 検証
   - `dbt debug`、`dbt run -m cleaned_activities`、`dbt test`、`dbt docs generate/serve` をコンテナで実行して動作確認。
5. ドキュメント
   - `ai-doc/infra/dbt_athena_setup.md` と `ai-doc/infra/dbt_usage_and_design.md` に Docker 手順（`up -d`/`exec`/`--host 0.0.0.0`）を追記済み。
   - dbt Docs 用メタデータ（モデル/ソースの説明・テスト）を登録（`models/schema.yml`、`models/src_mhealth.yml`）。
6. ロールバック
   - ローカル CLI は温存（`with-env.sh` も継続可）。必要なら Docker 用ファイルを削除するだけで復旧可能。

## 受け入れ条件（Definition of Done）
- `docker compose -f docker/dbt/docker compose.yml run --rm dbt dbt debug` が成功する。
- `dbt run/test` が Docker で実行可能であり、Athena/Glue への接続と S3 出力が既存と同じである。
- `dbt docs generate && dbt docs serve --host 0.0.0.0 --port 8080 --no-browser` が Docker で動作し、`http://localhost:8080` にアクセスできる。
- `.env.dev` と `.dbt/profiles.yml` を変更せずに動作する。
- 機密情報を Docker イメージに含めていない（イメージ内に認証ファイルが存在しない）。
 - 常駐コンテナ（`up -d`）に対し `docker compose exec dbt dbt debug` が成功する。
 - dbt Docs の Models/Sources に Description/Tests が反映される。

## リスクと対策
- 認証が伝播しない: `~/.aws` マウント、`AWS_PROFILE`/`AWS_DEFAULT_REGION` の明示、`aws sso login` 事前実施を周知。
- ポート衝突: `8080` が競合する場合、compose 側で `ports` を変更 or `docs serve --port` を変更。
- 権限問題（生成物所有権）: `--user $(id -u):$(id -g)` 実行オプションをラッパーで選択可能に。
- 依存競合: `dbt-athena-community` のバージョンを `ai-doc` に記載、再現性確保。

## ロールバック手順
- ローカル実行に戻す: 既存 `data_flow_dbt/scripts/with-env.sh dbt ...` を継続利用。
- 追加ファイル削除: `docker/dbt/` と `dbt-docker.sh` を削除して元に戻す。

---
*本計画は AGENTS.md の原則（安全・一貫・冪等・コスト配慮）に準拠。*
