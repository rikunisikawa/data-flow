# インフラチェックリスト

## 維持すべき不変条件
- S3 レイアウトは `raw/`, `stage/`, `processed/` を維持する。
- `stage/` のパーティションは `subject_id × activity_label`、`activity_label=0` は除外する。
- スキーマは 24 列（最後が `activity_label`）で `convert_log_to_parquet` に整合させる。
- dbt の `cleaned_activities` は `$path` から `user_id` を抽出し、3 軸平均を計算する。
- Terraform は `dev/prod` の workspace 分離と workspace 接頭辞付き命名を維持する。

## スキーマ/パーティション変更時の同期更新
- Glue Catalog のテーブル定義。
- dbt モデルとテスト（例: `schema.yml`）。
- 列数やパーティションパスを検証する `tests/` のユニットテスト。

## ガードレール
- `.github/workflows/` を直接編集しない。
- IAM は最小権限を維持し、権限拡大の理由を記録する。
- 秘密情報をコードやログに残さない。

## クロスファイル整合
- `ai-doc/infra/system_design.md` と `ai-doc/infra/etl_flow.md` の整合を維持する。
- Step Functions の ASL と Terraform 定義を同時に更新する。
