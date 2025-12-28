# Terraform Deploy Workflow 変更案（dbt イメージ対応）

このドキュメントは、現行の Terraform デプロイワークフローに **dbt イメージのビルド/プッシュ** を組み込むための変更案をまとめたものです。  
`.github/workflows/` は直接編集できないため、差分内容と手順のみを記載します。

## 目的
- dbt イメージを CI/CD で自動ビルドし、ECR に push する
- Terraform の `dbt_image_tag` と整合の取れたタグを使う

## 変更方針（推奨）
1. **タグは CI で生成**（`GITHUB_SHA` の short など）
2. **Terraform には `-var` でタグを渡す**（`prod.tfvars` を直接変更しない）
3. **paths フィルタに dbt 関連を追加**（`docker/dbt/**`, `dbt_profiles/**`, `scripts/build_dbt_image.sh`）

## 追加が必要な前提
- `GitHubActionsTerraformDeployRole` に ECR push 権限があること  
  例: `ecr:GetAuthorizationToken`, `ecr:BatchCheckLayerAvailability`, `ecr:InitiateLayerUpload`,
  `ecr:UploadLayerPart`, `ecr:CompleteLayerUpload`, `ecr:PutImage`

## 変更ステップ（具体）
1. dbt タグを決定  
   例: `DBT_IMAGE_TAG=prod-${GITHUB_SHA::7}`
2. dbt イメージをビルド & push  
   `bash scripts/build_dbt_image.sh prod "${DBT_IMAGE_TAG}"`
3. Terraform apply で `dbt_image_tag` を上書き  
   `terraform apply -auto-approve -var-file=prod.tfvars -var "dbt_image_tag=${DBT_IMAGE_TAG}"`

## 差分案（terraform-deploy.yml）
以下は **差分イメージ**（抜粋）です。実ファイルの編集は行いません。

```yaml
jobs:
  deploy:
    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v1
        with:
          role-to-assume: arn:aws:iam::<account_id>:role/GitHubActionsTerraformDeployRole
          aws-region: ap-northeast-1

      - name: Build Lambda Deployment Packages
        run: bash build.sh prod

      - name: Build and Push dbt Image
        env:
          DBT_IMAGE_TAG: prod-${{ github.sha }}
        run: |
          SHORT_TAG="${DBT_IMAGE_TAG:0:12}"
          bash scripts/build_dbt_image.sh prod "${SHORT_TAG}"
          echo "DBT_IMAGE_TAG=${SHORT_TAG}" >> "$GITHUB_ENV"

      - name: Build and Run Terraform
        run: |
          cd terraform
          docker compose build
          docker compose run --rm \
            -e AWS_ACCESS_KEY_ID \
            -e AWS_SECRET_ACCESS_KEY \
            -e AWS_SESSION_TOKEN \
            -e AWS_DEFAULT_REGION \
            -e AWS_REGION \
            terraform sh -c "\
              terraform init -reconfigure && \
              (terraform workspace select prod || terraform workspace new prod) && \
              terraform apply -auto-approve -var-file=prod.tfvars \
                -var \"dbt_image_tag=${DBT_IMAGE_TAG}\""
```

## paths フィルタ追加案
Terraform デプロイのトリガーに dbt 関連の変更を含めます。

```yaml
on:
  push:
    paths:
      - 'terraform/**'
      - 'download_and_upload/**'
      - 'convert_log_to_parquet/**'
      - 'layer/**'
      - 'build.sh'
      - 'docker/dbt/**'
      - 'dbt_profiles/**'
      - 'scripts/build_dbt_image.sh'
```

## 代替案（保守的）
- `prod.tfvars` の `dbt_image_tag` は手動管理
- ワークフローでは **イメージの build/push のみ** を追加
- Terraform 側は `prod.tfvars` のタグを使い続ける

## 影響と注意点
- **Terraform Apply の一貫性**: `-var "dbt_image_tag=..."` で明示しないと、ECR に push したタグとずれる可能性あり
- **再実行**: 同じタグで再実行すると上書きされるため、タグの一意性を確保する
- **コスト**: 変更頻度が高い場合は ECR のイメージ数に注意
