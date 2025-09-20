# dbt 運用ガイド（Athena/Glue + mHealth）

本ガイドは本リポジトリのdbt実行方法・環境変数・モデル設計をまとめたものです。ローカル/CI/本番の運用ポリシーに沿って、実行・検証・トラブルシュートの要点を記載します。

---

## 1. 全体像
- 入力データ: Glue Data Catalog（Terraform管理）上の `stage_mhealth.raw_activities`（実体は `s3://<workspace>-<base_bucket>/stage/`）
- 主要モデル:
  - `cleaned_activities`: `$path` から `user_id` を抽出し、センサー加速度の3軸平均列を生成。`activity_label != 0` を前提。
  - `featured_activities`: `cleaned_activities` を集約し、`user_id × activity_label` で `mean/std/min/max` の特徴量を作成。
- 品質担保: `data_flow_dbt/models/tests.yml` に `not_null` などのテストを定義し、`dbt test` で検証。

参考: パーティション戦略は `subject_id` × `activity_label`（`activity_label=0` は除外）。

---

## 2. プロファイルと環境変数
- プロファイルファイル: ローカルは `~/.dbt/profiles.yml` を使用（本リポジトリでは `.dbt/profiles.yml` も生成されることがありますが、基本は未追跡運用）。
- 本プロジェクトの `profiles.yml` は環境変数を参照（`env_var`）。必要な変数:
  - `S3_STAGING_DIR`: Athenaクエリ結果用（例: `s3://dev-aws-data-platform-20250607/athena/staging/`）
  - `S3_DATA_DIR`: dbtのマテリアライズ先（例: `s3://dev-aws-data-platform-20250607/processed/`）
  - `AWS_REGION`: 例 `ap-northeast-1`
  - `GLUE_DATABASE`: 例 `dev_stage_mhealth`（Terraform: `${workspace}_stage_mhealth`）
  - `DBT_SCHEMA`: 例 `processed`（CIでは一意名にする案あり）
  - `ATHENA_WORK_GROUP`: 例 `primary`
- 共有用の雛形: ルートに `.env.dev` を用意済み（コミット対象）。個別上書きは `.env`（未追跡）で対応可能。

---

## 3. ローカル実行方法
- ラッパースクリプト: `data_flow_dbt/scripts/with-env.sh`
  - 環境ファイルの読み込み優先度: `ENV_FILE` → `.env` → `.env.dev`
  - 例:
    - 接続確認: `data_flow_dbt/scripts/with-env.sh dbt debug`
    - 実行: `data_flow_dbt/scripts/with-env.sh dbt run -m featured_activities`
    - テスト: `data_flow_dbt/scripts/with-env.sh dbt test -m featured_activities`

Tips:
- `.env` を作成すれば個人の上書きが可能（`.env.dev` はベース設定）。
- WorkGroup側で出力先が強制されている場合、`S3_STAGING_DIR` と矛盾しないように設定。

---

## 4. CIでの実行方針
- 推奨: PR/ブランチでDevリソースを参照し検証、本番は `main` マージ後の別ジョブで実施。
- 例（要点）:
  - `env:` で必要な変数を設定（Devのバケット/DB）。
  - `~/.dbt/profiles.yml` をCI内で生成し、上記環境変数を差し込む。
  - `dbt debug` → `dbt run -m featured_activities` → `dbt test -m featured_activities`。
- オプション: `DBT_SCHEMA=processed_ci_<run_id>` のように一意スキーマで衝突回避（終了後のクリーンアップは任意）。

---

## 5. モデル設計メモ
- `cleaned_activities`（概要）
  - `$path` から `user_id` 抽出
  - `*_acc_*` の3軸平均列を生成
  - `activity_label != 0` を前提にクリーニング
- `featured_activities`（実装済み）
  - 入力: `cleaned_activities`（`user_id`, `activity_label`, `chest_acc_avg`, `left_ankle_acc_avg`, `right_lower_arm_acc_avg`）
  - 出力: 平均・標準偏差・最小・最大（`*_mean|*_std|*_min|*_max`）を `user_id × activity_label` で集約
- テスト: `tests.yml` に `not_null` を付与（`user_id`, `activity_label`, 各特徴量列）。

---

## 6. トラブルシュート
- `AccessDenied`/`NoSuchBucket`: `S3_STAGING_DIR`/`S3_DATA_DIR` のバケット名・パスを確認（Terraformの命名規則に一致しているか）。
- `Database not found`: `GLUE_DATABASE` 名（`dev_stage_mhealth` 等）とリージョンを確認。
- `WorkGroup` エラー: 対象WorkGroupの出力先設定が `S3_STAGING_DIR` と矛盾していないか確認。
- 型不一致: Glue Catalogのカラム定義とdbtモデルの想定が一致しているかを確認（スキーマ変更時はAGENTS.mdの手順に従い一括更新）。

---

## 7. コスト/パフォーマンス配慮
- Athenaスキャン量を抑えるため、パーティションフィルタ（`subject_id`/`activity_label`）を活用。
- 必要列の選択、Parquetの圧縮・列指向を活用。
- CIのスキーマ一意化は便利だが、S3オブジェクト増加に留意。

---

## 8. 参考
- `AGENTS.md`（原則・パーティション戦略・テストポリシー）
- `terraform/modules/glue_catalog/`（Glue Catalog定義）
- `data_flow_dbt/models/`（モデル実装・テスト定義）

