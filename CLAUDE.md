# CLAUDE.md

本ドキュメントは、Claude Code (claude.ai/code) がこのリポジトリで作業する際のガイドラインです。

## プロジェクト概要

Kaggle の mHealth データセットを多段 ETL パイプラインで処理する AWS サーバレスデータ基盤。生の `.log` ファイルを Kaggle からダウンロードし、Parquet に変換、dbt（Athena 上）で変換処理を行い、Glue Data Catalog 経由でクエリ可能にする。インフラは Terraform（主）で管理し、GitHub Actions CI/CD でデプロイする。

## アーキテクチャ

### データフロー（Step Functions パイプライン）

```
EventBridge（日次）→ Step Functions:
  1. Lambda①（download_and_upload）→ S3 /raw/
  2. Lambda②（convert_log_to_parquet）→ S3 /stage/（パーティション済み Parquet）
  3. ECS Fargate（dbt）→ S3 /processed/（変換済みテーブル）
                       → Elementary レポート（データ品質）
  4. Athena → Glue Data Catalog 経由でクエリ
```

### S3 構成

```
s3://{workspace}-aws-data-platform-20250607/
├── raw/              # Kaggle からの生 .log ファイル
├── stage/            # subject_id/activity_label でパーティションされた Parquet
├── processed/        # dbt 変換済み Parquet テーブル
├── athena/staging/   # Athena クエリ結果
├── scripts/          # Glue ジョブスクリプト
├── layers/           # Lambda レイヤー zip
└── dbt-temp/         # dbt 一時ステージング
```

### 使用 AWS サービス

Lambda, S3, Step Functions, EventBridge, Glue（Data Catalog）, Athena, ECS Fargate, ECR, CloudFront, Cognito, IAM, SSM Parameter Store, VPC

## ディレクトリ構成

```
├── download_and_upload/          # Lambda①: Kaggle ダウンロード
├── convert_log_to_parquet/       # Lambda②: log→Parquet 変換
├── glue_job/                     # Glue ETL スクリプト（レガシー、dbt に置換済み）
├── data_flow_dbt/                # Athena 変換用 dbt プロジェクト
│   ├── models/                   #   SQL モデル（cleaned_activities 等）
│   ├── tests/                    #   dbt データテスト
│   ├── elementary_config.yml     #   データ品質監視設定
│   └── dbt_project.yml
├── docker/                       # dbt Fargate タスク用 Docker 設定
├── dbt_profiles/                 # dbt 接続プロファイル
├── state_machine/                # Step Functions ASL 定義
├── terraform/                    # Infrastructure as Code（主要 IaC）
│   ├── modules/                  #   再利用可能モジュール（lambda, iam, glue_*）
│   ├── main.tf                   #   コアリソース
│   ├── ecs.tf                    #   dbt 用 ECS Fargate
│   ├── network.tf                #   VPC ネットワーク
│   ├── cognito.tf                #   Cognito 認証（Elementary レポート）
│   ├── cloudfront_reports.tf     #   CloudFront ディストリビューション
│   ├── edge_auth.tf              #   CloudFront エッジ認証 Lambda
│   └── dev.tfvars / prod.tfvars  #   環境別変数
├── layer/                        # Lambda レイヤービルド（Docker ベース）
│   ├── src/Dockerfile            #   x86_64 向けマルチステージビルド
│   ├── src/requirements.txt      #   本番 Python 依存
│   └── terraform/build-layer.sh  #   レイヤービルドスクリプト
├── tests/                        # Python ユニットテスト（pytest + moto）
├── .github/workflows/            # CI/CD パイプライン
├── ai-doc/                       # アーキテクチャドキュメント、トラブルシュート
├── specs/                        # Spec Kit Issue 計画
├── notebooks/                    # Jupyter EDA ノートブック
├── scripts/                      # ヘルパースクリプト
├── template.yaml                 # SAM テンプレート（レガシー参照のみ）
└── build.sh                      # Lambda デプロイパッケージビルド
```

## 開発コマンド

### Lambda パッケージのビルド

```bash
# 全 Lambda zip とレイヤーをビルド（Docker 必須）
bash build.sh

# 出力: build/download_and_upload.zip, build/convert_log_to_parquet.zip, build/layer.zip
```

### Terraform デプロイ

```bash
# 開発環境
cd terraform
terraform workspace select dev
terraform apply -var-file=dev.tfvars

# 本番デプロイは CI/CD 経由（main への push）で行うこと
```

### テスト実行

```bash
pip install -r tests/requirements.txt
pytest tests/
```

### ローカル Lambda テスト（SAM — レガシー）

```bash
sam build
sam local invoke DownloadAndUploadFunction
sam local invoke ConvertLogToParquetFunction
```

### dbt

```bash
cd data_flow_dbt
dbt run --profiles-dir ../dbt_profiles
dbt test --profiles-dir ../dbt_profiles
```

## 主要ソースファイル

| ファイル | 用途 |
|---------|------|
| `download_and_upload/download_and_upload.py` | Lambda①: Kaggle から mHealth データセットをダウンロードし、`.log` ファイルを S3 `/raw/` にアップロード |
| `convert_log_to_parquet/convert_log_to_parquet.py` | Lambda②: `/raw/` の `.log` ファイルを読み込み、`subject_id`/`activity_label` でパーティションした Parquet に変換し `/stage/` に書き込み |
| `glue_job/glue_job.py` | カラム正規化用 Glue ETL スクリプト（レガシー — 現在は dbt が変換を担当） |
| `data_flow_dbt/models/cleaned_activities.sql` | dbt モデル: パスから `user_id` を抽出、3軸加速度センサーの平均を算出、null クラスを除外 |
| `state_machine/data_processing.asl.json` | Step Functions 定義: Download → Convert → RunDbtTask（ECS Fargate） |
| `terraform/main.tf` | Terraform コア設定: S3, Lambda, Layer, Step Functions, IAM, Glue Catalog |
| `terraform/ecs.tf` | dbt 用 ECS Fargate クラスタ/タスク定義 |
| `build.sh` | Lambda デプロイ用 zip とレイヤーのビルド |

## 環境変数

### Lambda

- `BUCKET_NAME`: S3 バケット名（ワークスペース接頭辞付き、例: `dev-aws-data-platform-20250607`）
- `KAGGLE_USERNAME`: Kaggle API ユーザー名（SSM Parameter Store から注入）
- `KAGGLE_KEY`: Kaggle API キー（SSM Parameter Store から注入）

### dbt / Fargate

- `S3_STAGING_DIR`: Athena ステージングディレクトリ
- `S3_DATA_DIR`: 処理済みデータディレクトリ
- `AWS_REGION`: `ap-northeast-1`
- `GLUE_STAGE_DATABASE`: Glue データベース名（例: `dev_stage_mhealth`）
- `DBT_SCHEMA`: 出力スキーマ（例: `dev_processed`）
- `ELEMENTARY_SCHEMA`: Elementary スキーマ名

## 依存関係

### 本番（Lambda レイヤー — `layer/src/requirements.txt`）

- `pandas` — データ操作
- `fastparquet` — Parquet シリアライゼーション
- `kaggle` — Kaggle API クライアント
- `numpy==1.26.4` — 数値計算
- `boto3` — AWS SDK（Lambda ランタイムに同梱、requirements ではコメントアウト）

### テスト（`tests/requirements.txt`）

- `pytest` — テストフレームワーク
- `moto` — AWS サービスモック
- `pyarrow` — Parquet 読み込み/検証
- `boto3`, `pandas`, `fastparquet`

## データスキーマ

mHealth データセットは 24 列（空白区切り `.log` ファイル）。カラム名は `convert_log_to_parquet.py` の `COLUMN_NAMES` リストで定義:

- 胸部加速度センサー 3 列（`chest_acc_x/y/z`）
- 胸部 ECG 2 列（`chest_ecg_1/2`）
- 左足首センサー 9 列（加速度、ジャイロ、磁力計 × 3 軸）
- 右前腕センサー 9 列（加速度、ジャイロ、磁力計 × 3 軸）
- 活動ラベル 1 列（`activity_label`）— `0` = null クラス（stage から除外）

### パーティション

stage データのパーティション構成: `stage/subject_id={id}/activity_label={label}/data_{id}_{label}.parquet`

## Infrastructure as Code

### Terraform（主要）

- **ワークスペース戦略**: `dev` と `prod` を Terraform ワークスペースで分離
- **リソース命名**: `{workspace}-{resource-name}` 接頭辞規則
- **モジュール**: `modules/lambda/`, `modules/iam/`, `modules/glue_catalog/`, `modules/glue_database/`
- **シークレット**: Kaggle 認証情報は SSM Parameter Store に保管（`/data-flow/kaggle/username`, `/data-flow/kaggle/key`）

### SAM（レガシー）

`template.yaml` は設計参照として残置。Terraform が現行の IaC。本番環境で SAM デプロイは行わないこと。

## CI/CD

### メインパイプライン（`.github/workflows/terraform-deploy.yml`）

`main` への push または手動ディスパッチでトリガー:
1. Lambda パッケージのビルド（キャッシュ有）
2. dbt Docker イメージのビルド・ECR への push
3. Terraform apply（2段階: IAM 先行、その後全リソース）

認証は OIDC（長期間有効なクレデンシャルを使用しない）。

### 自動 PR パイプライン（`.github/workflows/auto-pr.yml`）

Gemini CLI を使用した Issue → PR 自動化ワークフロー。

## コーディング規約

### Lambda 関数

- `{'statusCode': 200|500, 'body': '...'}` 形式でレスポンスを返却
- `logging` モジュールで構造化された単行ログを出力
- テスタビリティのため boto3 クライアントはゲッター関数（`get_s3_client()`）で生成
- 例外の握りつぶし禁止 — 完全なスタックトレースをログに出力し 500 を返却
- 冪等性を考慮した設計（再実行しても安全であること）
- 認証情報のハードコード禁止 — SSM から環境変数で注入

### テスト

- Python の変更には必ずユニットテストを追加・更新すること
- 外部サービスは `moto`（`@mock_aws`）と `unittest.mock.patch` でモック
- 正常系・異常系の両方をテスト
- カラム数、スキーマ、出力パス、パーティションキーを検証

### インフラ

- 全リソース名に Terraform ワークスペースを接頭辞として付与
- 環境別設定は `.tfvars` ファイルを使用
- IAM ポリシーは最小権限の原則に従う

### Git/PR ルール

- PR タイトルに Issue 番号を必ず含める（例: `feat: 新機能の追加 (issue #17)`）
- コミットは機能単位または論理的なまとまりで分割
- **`.github/workflows/` ファイルは編集禁止** — CI/CD に影響するため専用レビューが必要

### 応答言語

- AI/エージェントの応答は日本語（日本語）で行うこと
- コード、識別子、ログ、エラーメッセージ、一般的な技術用語は英語表記を許容

## 変更時の影響範囲チェックリスト

変更を行う際は、以下の関連領域を確認すること:

- **スキーマ変更**: Lambda② の `COLUMN_NAMES`、Terraform の Glue Catalog 定義、dbt モデル、テストを同期更新
- **S3 パス変更**: Athena 外部テーブル、dbt ソース、Glue スクリプト、Terraform の S3 参照を修正
- **依存関係追加**: Lambda レイヤーを再ビルド（`build.sh`）、レイヤーサイズとコールドスタートへの影響を確認
- **Lambda 設定変更**: タイムアウト（300s）、メモリ（1024MB）、リトライ、同時実行数を見直し
- **IAM 変更**: 最小権限の原則を遵守、リソースとリージョンのスコープを確認
- **コスト影響**: Lambda 実行時間、S3 オブジェクト数、Athena スキャン量、Fargate タスク実行時間を考慮

## トラブルシュート

- Mermaid 図の構文エラーと Jupyter Notebook の JSON 破損: `ai-doc/tips/troubleshooting-notebook-mermaid.md` を参照
- ETL フロー図: `ai-doc/infra/etl_flow.md`
- Terraform 設計思想: `ai-doc/infra/terraform-design.md`
- GitHub Actions CI/CD ドキュメント: `.github/docs/github-actions/`
