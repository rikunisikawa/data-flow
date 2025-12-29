# 計画: dbt 基盤への Elementary 導入

**Date**: 2025-03-05 | **Target**: `data_flow_dbt` (dbt 1.8 + Athena) | **Owner**: TBD

## 目的
- mHealth ステージング/加工テーブルに対し、データ品質モニタリング（テスト収集・アラートレポート生成）を自動化できるよう Elementary を導入する。
- 既存の Athena 接続設定（`.env.dev` + `.dbt/profiles.yml`）と Docker ベースの dbt 実行環境を崩さずに追加する。

## スコープ
- 対象: dbt プロジェクト設定、dbt パッケージ依存、dbt Docker イメージ（CLI 追加）、Elementary CLI 設定ファイル。
- 非対象: CI/CD へのスケジュール投入（GitHub Actions などのワークフロー編集は禁止、別途議論）。

## 前提/整合性（AGENTS.md）
- 一貫性: `data_flow_dbt` 配下の構成・命名を踏襲。プロファイルは既存 `data_flow_dbt` を再利用。
- 安全性: AWS 認証はホストの `~/.aws` マウント or 環境変数で注入。秘密情報をリポジトリへコミットしない。
- 冪等性: `dbt deps`/`dbt build`/`edr monitor` は再実行可能な形で設計する。
- コスト: Athena スキャン量増大を抑えるため、Elementary のメタデータ格納スキーマは専用に分離し、必要最低限の頻度で実行。

## 導入フロー
1) 依存パッケージ追加  
   - `data_flow_dbt/packages.yml` を新規作成し Elementary を追加。例:  
     ```yaml
     packages:
       - package: elementary-data/elementary
         version: [">=0.15.0", "<0.16.0"]
     ```  
   - `data_flow_dbt` で `dbt deps` を実行しパッケージを取得。

2) Elementary 用スキーマ/リソース生成  
   - Athena 上に Elementary 用のスキーマ（例: `dev_elementary`）を作成する。`DBT_SCHEMA` とは分離してコスト/権限を切り分ける。  
   - 環境変数で `ELEMENTARY_DATABASE`/`ELEMENTARY_SCHEMA` を設定（未設定なら `DBT_SCHEMA` を fallback しない方針で明示）。  
   - `dbt build --select elementary` を実行し、Elementary のメタデータテーブルを作成。初回は `--full-refresh` を付与。

3) Elementary CLI（edr）導入  
   - `docker/dbt/Dockerfile` に `pip install "elementary-data>=0.15,<0.16"` を追加し、`docker compose build dbt` で再ビルド。  
   - ローカル CLI 利用の場合は `pip install elementary-data` でも可（バージョンを合わせる）。

4) CLI 設定ファイル追加  
   - `data_flow_dbt/elementary_config.yml` を追加。最低限の例:  
     ```yaml
     project_dir: /work/data_flow_dbt
     profiles_dir: /work/.dbt
     target: dev
     timezone: Asia/Tokyo
     elementary_database: "{{ env_var('ELEMENTARY_DATABASE', env_var('ATHENA_CATALOG', 'awsdatacatalog')) }}"
     elementary_schema: "{{ env_var('ELEMENTARY_SCHEMA', 'dev_elementary') }}"
     monitor:
       days_back: 7
       send_anonymous_usage_stats: false
     ```  
   - `.env.dev` に `ELEMENTARY_SCHEMA=dev_elementary`（および必要なら `ELEMENTARY_DATABASE`）を追記。prod 用は未コミットの `.env` 側で設定。

5) 実行手順（ローカル/Docker）  
   - Docker 常駐コンテナ内で:  
     - `dbt deps`（初回のみ）  
     - `dbt build --select elementary --full-refresh`（初回）  
     - `edr monitor --config-file /work/data_flow_dbt/elementary_config.yml --profiles-dir /work/.dbt --project-dir /work/data_flow_dbt --target dev --skip-dashboards`  
   - HTML レポートは `elementary/monitoring-reports/` に出力されるので `.gitignore` 登録を検討。

6) 運用設計（メモ）  
   - 実行頻度: 手動 or 後続で CI/スケジューラを検討（現時点でワークフロー修正は範囲外）。  
   - アラート: Slack/Webhook 連携は Elementary 側のオプションで設定可能（必要になったら別チケット）。  
   - ストレージ: S3 ステージングディレクトリ（`S3_STAGING_DIR`）の利用を継続し、追加の S3 バケットは作らない。

## 受け入れ条件 (DoD)
- `dbt deps` が Elementary パッケージを取得し、`dbt build --select elementary` が Athena 上で成功する。  
- `edr monitor` が実行でき、HTML レポートが生成される（エラーなし）。  
- 既存の dbt モデル/テストが影響を受けない（`cleaned_activities`/`featured_activities` が従来通り動く）。  
- 機密情報を新規ファイルにハードコードしていない。

## リスクと対策
- スキャン量増大: Elementary の期間指定（`days_back`）と専用スキーマでテーブルサイズを抑制。  
- バージョン不整合: `packages.yml` と Dockerfile の Elementary バージョンを合わせ、将来アップグレード時は同時更新。  
- 認証不足: Docker 実行時に `~/.aws` マウント or 環境変数を必須とし、`dbt debug` で事前検証。  
- 構成漏れ: `elementary_config.yml` にプロファイル/ターゲット/スキーマを明示し、`with-env.sh` からも参照できるようパスを `/work` 固定で記述。
