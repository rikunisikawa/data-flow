# AGENTS.md — 開発時の考慮事項まとめ

本ドキュメントは、本プロジェクト（mHealth データの ETL/分析基盤）でコーディングする際の実務的な指針・注意点を整理したものです。Lambda/Step Functions/Glue/Terraform/DBT/Athena/テスト/運用に跨る観点を網羅します。

## 目的と範囲
- Kaggle の mHealth ログを S3 に取り込み、Parquet 化・スキーマ整備・カタログ登録・分析（Athena/DBT）までのサーバレス基盤を継続運用可能に保つ。
- 既存コード・IaC（主に Terraform）・データ仕様・運用フローと整合性を保ち、変更時の影響を最小化する。

## 守るべき原則
- 一貫性: 既存のディレクトリ構成、命名、レスポンス形式（Lambda の `statusCode`/`body`）を踏襲。
- 安全性: 認証情報はコードに埋め込まない（SSM/環境変数/Layer を活用）。失敗時は例外を握りつぶさず、明示的にログ＋適切なステータスで返却。
- 冪等性: 再実行で破綻しない（重複書き込み・中間ファイルの扱い・リトライ耐性）。
- テスト駆動: 仕様変更・バグ修正では `tests/` を必ず更新。モック（moto/patch）で外部依存を遮断。
- コスト配慮: Lambda のメモリ/タイムアウト/データスキャン量、S3 オブジェクト数、Glue 実行回数、Athena スキャン量に注意。

## コミュニケーション/応答言語
- 原則として、AI/エージェントの応答は日本語で記述する。
- ただし、コード、識別子、ログ、エラーメッセージ、一般的な技術用語は英語表記を許容する。
- 外部仕様やCLI/SDKの固定表記は原文（英語）を維持し、説明は日本語で補足する。

## データ/スキーマ
- 入力: mHealth の `.log`（空白区切り）。列数は 24 列（最後が `activity_label`）。列名は `convert_log_to_parquet` の `COLUMN_NAMES` に準拠。
- パーティション戦略: S3 `stage/` は `subject_id` × `activity_label` でパーティション。`activity_label=0`（null クラス）は除外。
- 変更時の影響: 列追加/名称変更は Glue Catalog、DBT モデル、テスト（列数/スキーマ検証）へ波及。DDL/カタログ/モデル/ユニットテストを同期更新。

## Lambda（Python 3.11）
- 共通: `boto3`/`pandas`/`fastparquet` を使用。`/tmp` の 512MB 制限、300s タイムアウト、1024MB メモリ設定を前提。ログは `logging` を使用し JSON ライクな単行で出力。
- ダウンロード関数（download_and_upload）:
  - Kaggle 認証は `KAGGLE_USERNAME`/`KAGGLE_KEY`（SSM から注入）＋ `KAGGLE_CONFIG_DIR=/tmp/.kaggle`。
  - 現実装はコスト配慮で `mHealth_subject1.log` のみアップロード。全件対応へ変更する場合はコスト/実行時間/テストを更新。
  - 例外時は 500 を返却し、原因をログ出力（stacktrace 含む）。
- 変換関数（convert_log_to_parquet）:
  - `raw/` 配下の `.log` を走査→`pandas.read_csv(sep=r"\s+")` で読込→列数検証→列名付与→`fastparquet` で Parquet 生成→`stage/subject_id=…/activity_label=…/` へ書込。
  - 大規模化時はチャンク処理/一時ファイル/圧縮や、Glue 置換の検討。
  - S3 エラーやスキーマ不一致はスキップ/500 を返却（ログで要因を明確化）。

## Step Functions
- 構成: Download → Convert を直列実行。`ResultPath` で結果を保持し、`Catch` で失敗を FailState にハンドリング。
- 変更時は `state_machine/` の ASL JSON と Terraform の参照（定義テンプレート）を合わせて更新。

## Glue（任意/将来拡張）
- 役割: 列名正規化、選択列抽出、ユーザー ID 抽出などのバッチ整形。`glue_job/glue_job.py` を参照。
- GlueVersion/ワーカー型・数はコスト/パフォーマンス見合いで調整。S3 I/O の整合性（出力先・形式）を Lambda/DBT と揃える。

## DBT/Athena
- Source: Glue Data Catalog（`awsdatacatalog`）の `stage_mhealth.raw_activities` を参照。
- モデル: `cleaned_activities` は `$path` から `user_id` を抽出し、3 軸平均列を生成。`activity_label != 0` を前提。
- マテリアライズ: 既定 `table`。出力先は `processed` スキーマ（S3 `processed/`）。増分化が必要ならモデル設定を見直す。
- 品質: `tests.yml` でルールを追加・維持。スキーマ変更時は必ず更新。

## Terraform（優先の IaC）
- ワークスペース分離: `dev`/`prod` でステート/命名を分離（リソース名にワークスペース接頭辞）。
- S3/Lambda/Layer/Step Functions/IAM/Glue Catalog をコード化。SSM から Kaggle 認証を読み出し Lambda に渡す。
- 注意: `main.tf` の GitHub Actions 用ロールは権限が広い（コメントあり）。本番ではスコープダウン推奨。
- 変更時は `build/` 成果物（zip）生成と S3 アップロード・ハッシュ整合を考慮（`build.sh`/モジュール参照パス）。

## SAM（レガシー参照）
- `template.yaml` は設計参照として残置。現行は Terraform が主。SAM を変更する場合は整合性・重複リソースに注意。

## 認証/秘密情報
- Kaggle 資格情報は SSM Parameter Store に保管し、Lambda の環境変数に注入。リポジトリへ直書き/残置しない。
- GitHub Actions は OIDC で IAM ロールを引き受け。ポリシーの最小権限化を徹底。

## テスト/品質保証
- Python の変更にはユニットテストを必須追加・更新（`pytest`/`moto`/`unittest.mock`）。S3/Kaggle/Boto3 はモックで代替。
- 変換の列数・列名・出力パス・パーティションキー・例外時応答をテストで担保。
- 大きな変更ではサンプルデータを追加し E2E 的なケースも検討。

## ロギング/監視
- Lambda は `logging` を使用し、レベル/例外を明示。機密値はログしない。
- CloudWatch Logs の出力整形を崩さない（単行/JSON 風）。失敗時はコンテキスト付きで出力。

## パフォーマンス/コスト最適化
- データスキャン削減: パーティション活用、必要列の選択、圧縮（必要に応じて Parquet 圧縮）。
- Lambda 実行時間/メモリ/再試行回数、Glue ワーカー数、Athena クエリ回数を管理。
- 不要ファイルのアップロード回避（現状は subject1 のみアップロード仕様）。全件処理は Step Functions 並列化や Glue 置換を検討。

## PR/コミット/禁止事項
- PR タイトルに Issue 番号を含める。本文に背景/変更点/影響範囲を簡潔に記載。
- コミットは意味単位で分割（関係ない変更を混在させない）。
- 禁止: `.github/workflows/` の直接編集（運用フローに影響）。必要時は専用議論・レビューを経る。

## ローカル開発/デプロイ
- 依存: Python 3.11。ローカル検証は `pytest`。Lambda 依存の展開は Layer/Zip を使用（`layer/`/`build.sh`）。
- Terraform: `terraform workspace select dev` → `terraform apply -var-file=dev.tfvars`。本番は CI 経由。
- 既存の SAM コマンドは過去資産の検証用途としてのみ利用。

## 変更時の影響範囲チェックリスト
- スキーマ変更: COLUMN_NAMES/Glue Catalog/DBT/テストの同期更新
- S3 パス変更: Athena 外部テーブル/DBT Source/Glue スクリプトの修正
- 依存追加: Layer ビルド/サイズ/Cold Start への影響確認
- Lambda 設定: タイムアウト/メモリ/リトライ/同時実行の見直し
- IAM 権限: 最小権限・リージョン/リソーススコープ確認
- コスト影響: 実行回数/データ量/スキャン量の見積もり
