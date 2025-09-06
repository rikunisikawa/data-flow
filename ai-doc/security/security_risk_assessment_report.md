# セキュリティリスク評価レポート

## 1. 概要

本レポートは、AWS上に構築されたデータ基盤のセキュリティリスクを評価し、改善策を提案するものである。
調査は、`terraform/main.tf` および `template.yaml` のInfrastructure as Code (IaC) ファイルの静的解析に限定して実施した。

## 2. 調査範囲

- **対象ファイル**:
  - `terraform/main.tf`
  - `template.yaml`
- **調査観点**:
  - 認証・認可 (IAM)
  - データ保護 (S3)
  - ネットワークセキュリティ
  - 監査・モニタリング設定のIaC管理状況

**制約事項**: 本評価はIaCファイルの静的解析に基づくものであり、AWSアカウント上で手動で設定されたリソースや、実行時の動的な脅威は評価対象外とする。

## 3. 評価結果サマリー

| ID  | リスク項目                                                              | リスクレベル | 影響を受けるリソース                                       |
|:----|:--------------------------------------------------------------------------|:-------------|:-----------------------------------------------------------|
| 1   | GitHub Actions用のIAMロールに過剰な権限が付与されている                   | **高**       | `aws_iam_role.github_actions_terraform_deploy_role`        |
| 2   | Terraformで管理されるS3バケットのセキュリティ設定が不十分                 | **中**       | `aws_s3_bucket.this`                                       |
| 3   | Lambda実行ロールのCloudWatch Logs権限が過剰                               | **低**       | `aws_iam_role_policy.lambda_execution_policy`              |
| 4   | 監査・モニタリングサービス (CloudTrail等) の設定がIaCで管理されていない | **低**       | AWSアカウント全体                                          |

## 4. リスク詳細と推奨対策

---

### ID-1: GitHub Actions用のIAMロールに過剰な権限が付与されている

- **リスクレベル**: **高**
- **根拠**:
  - `terraform/main.tf` 内の `aws_iam_role_policy.github_actions_terraform_deploy_policy` にて、`"Resource": "*"` に対して `s3:*`, `lambda:*`, `iam:*`, `states:*`, `glue:*` という極めて広範な権限が付与されている。
  - このロールの認証情報はGitHub Actionsワークフローで利用されるため、万が一漏洩した場合、対象サービスの全リソースに対する操作が可能となり、影響が甚大になる。
- **推奨対策**:
  - **最小権限の原則の適用**: Terraformの実行に必要な最小限の権限に絞り込む。例えば、TerraformのPlan結果を元に、必要なアクションとリソースを特定し、ポリシーを具体的に記述する。
  - **本番環境と開発環境の分離**: 可能であれば、環境ごとにIAMロールを分離し、より厳格な権限管理を行う。

---

### ID-2: Terraformで管理されるS3バケットのセキュリティ設定が不十分

- **リスクレベル**: **中**
- **根拠**:
  - `terraform/main.tf` で定義されている `aws_s3_bucket.this` リソースにおいて、以下のセキュリティ設定が明示的に定義されていない。
    - **パブリックアクセスブロック**: `aws_s3_bucket_public_access_block` リソースによる設定がなく、意図しない公開リスクが存在する。
    - **サーバーサイド暗号化**: `server_side_encryption_configuration` ブロックがなく、保存データの暗号化が保証されていない。
  - 一方で、`template.yaml` で定義されているS3バケットではこれらの設定が適切に行われており、管理方法に一貫性がない。
- **推奨対策**:
  - **パブリックアクセスブロックの明示的な有効化**: 以下の設定を追加し、全てのパブリックアクセスをブロックする。
    ```terraform
    resource "aws_s3_bucket_public_access_block" "this" {
      bucket = aws_s3_bucket.this.id
      block_public_acls       = true
      block_public_policy     = true
      ignore_public_acls      = true
      restrict_public_buckets = true
    }
    ```
  - **サーバーサイド暗号化の有効化**: 以下の設定を追加し、デフォルト暗号化 (SSE-S3) を有効にする。
    ```terraform
    resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
      bucket = aws_s3_bucket.this.id
      rule {
        apply_server_side_encryption_by_default {
          sse_algorithm = "AES256"
        }
      }
    }
    ```

---

### ID-3: Lambda実行ロールのCloudWatch Logs権限が過剰

- **リスクレベル**: **低**
- **根拠**:
  - `terraform/main.tf` 内の `aws_iam_role_policy.lambda_execution_policy` で、CloudWatch Logsへの書き込み権限 (`logs:CreateLogGroup`, `logs:CreateLogStream`, `logs:PutLogEvents`) の対象リソースが `"Resource": "arn:aws:logs:*:*:*"` となっている。
  - これにより、Lambda関数が自身のロググループ以外にもアクセスできる可能性がある。
- **推奨対策**:
  - **リソース範囲の限定**: ロググループのARNを具体的に指定し、権限をLambda関数自身のロググループに限定する。
    ```json
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:ap-northeast-1:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${module.download_and_upload_lambda.function_name}:*"
    }
    ```
    ※各Lambda関数のロググループに対して同様の設定が必要です。

---

### ID-4: 監査・モニタリングサービスの設定がIaCで管理されていない

- **リスクレベル**: **低**
- **根拠**:
  - `terraform/main.tf` および `template.yaml` 内に、AWS CloudTrail, AWS Config, Amazon GuardDuty, AWS Security Hub といった、セキュリティ監査や脅威検知に不可欠なサービスに関する記述が存在しない。
  - これらのサービスが手動で有効化されている可能性はあるが、IaCで管理されていない場合、設定の変更追跡や一貫性の担保が困難になる。
- **推奨対策**:
  - **IaCによる管理**: CloudTrailをはじめとする各種監査サービスの設定をTerraformリソース (`aws_cloudtrail` など) としてコード化し、IaCの管理下に置くことを推奨する。
  - **設定内容のベストプラクティス適用**:
    - CloudTrail: 全リージョンで有効化し、ログファイルの検証を有効にする。ログは専用のS3バケットに集約・保管する。
    - GuardDuty, Security Hub: 有効化し、検出結果の通知や対応の自動化を検討する。

## 5. まとめ

今回の静的解析により、いくつかの重要なセキュリティリスクが特定されました。特に、GitHub Actionsに紐づくIAMロールの権限（ID-1）は早急な見直しが必要です。
また、リソース管理の一貫性を保つため、S3バケットのセキュリティ設定（ID-2）を`template.yaml`のレベルに合わせることを推奨します。
本レポートの指摘事項を改善することで、データ基盤全体のセキュリティレベルを向上させることができます。
