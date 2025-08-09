# GitHub Actions: IAMロール認証 (OpenID Connect)

## 概要

このドキュメントは、GitHub ActionsワークフローでAWSリソースにアクセスする際に、静的なアクセスキーとシークレットキーの代わりにIAMロール認証（OpenID Connect: OIDC）を使用する方法について説明します。OIDCを使用することで、セキュリティが大幅に向上し、認証情報の管理が簡素化されます。

## IAMロール認証のメリット

- **セキュリティの向上**: 静的な認証情報をGitHub Secretsに保存する必要がなくなります。認証情報は短期間有効なセッションとして発行されるため、漏洩のリスクが大幅に低減します。
- **認証情報のローテーション不要**: アクセスキーのように定期的なローテーションが不要になります。
- **最小権限の原則**: 特定のGitHubリポジトリやブランチからのアクセスのみを許可するようにIAMロールの信頼ポリシーを設定できます。

## 実装手順

IAMロール認証を有効にするには、以下の2つの主要なステップが必要です。

1.  **AWS側での設定**: GitHub Actionsからの認証を信頼するようにIAM OIDCプロバイダーを作成し、GitHub Actionsが引き受けるIAMロールを作成します。
2.  **GitHub Actionsワークフローの変更**: ワークフローファイル内でIAMロールのARNを指定するように設定を変更します。

---

### 1. AWS側での設定

以下の手順で、AWSアカウント内にGitHub Actionsからの認証を許可する設定を行います。

#### 1.1. IAM OIDCプロバイダーの作成

GitHub Actionsからの認証を信頼するように、AWS IAMでOpenID Connect (OIDC) プロバイダーを作成します。現在のAWSコンソールでは、GitHubの証明書のサムプリントを手動で入力する必要はありません。

1.  AWSマネジメントコンソールにサインインし、IAMサービスに移動します。
2.  左側のナビゲーションペインで「**ID プロバイダー**」を選択します。
3.  「**プロバイダーを追加**」をクリックします。
4.  「プロバイダーのタイプ」で「**OpenID Connect**」を選択します。
5.  「プロバイダーの URL」に `https://token.actions.githubusercontent.com` を入力します。
6.  「**対象者 (Audience)**」に `sts.amazonaws.com` を入力します。
7.  「プロバイダーを追加」をクリックして作成を完了します。

**補足**: 以前はGitHubのOIDC証明書のフィンガープリント（サムプリント）を手動登録する必要がありましたが、現在はAWS側がGitHubの証明書更新を自動管理するため、ユーザーが設定する必要がなくなりました。そのため、「サムプリントを取得」の手順はスキップして問題ありません。

#### 1.2. IAMロールの作成

GitHub Actionsワークフローが引き受けるIAMロールを作成します。このロールには、TerraformがAWSリソースをデプロイするために必要な権限を付与し、信頼ポリシーで先ほど作成したOIDCプロバイダーからのアクセスを許可します。

1.  IAMサービスに移動し、左側のナビゲーションペインで「**ロール**」を選択します。
2.  「**ロールを作成**」をクリックします。
3.  「信頼されたエンティティタイプを選択」で「**カスタム信頼ポリシー**」を選択します。
4.  信頼ポリシーエディタに以下のJSONポリシーを貼り付けます。`YOUR_AWS_ACCOUNT_ID`、`YOUR_GITHUB_ORG`、`YOUR_REPO_NAME` はご自身の環境に合わせて置き換えてください。

    ```json
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Principal": {
            "Federated": "arn:aws:iam::YOUR_AWS_ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
          },
          "Action": "sts:AssumeRoleWithWebIdentity",
          "Condition": {
            "StringEquals": {
              "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
            },
            "StringLike": {
              "token.actions.githubusercontent.com:sub": "repo:YOUR_GITHUB_ORG/YOUR_REPO_NAME:*"
            }
          }
        }
      ]
    }
    ```
    - `YOUR_AWS_ACCOUNT_ID`: あなたのAWSアカウントID。
    - `YOUR_GITHUB_ORG`: GitHubのリポジトリが所属する組織名（例: `my-company`）。個人アカウントの場合はあなたのGitHubユーザー名。
    - `YOUR_REPO_NAME`: このリポジトリの名前（例: `data-flow`）。

5.  「次へ」をクリックします。
6.  「アクセス許可ポリシーをアタッチ」の画面で、このロールに付与する権限を選択します。Terraformがデプロイするリソースに必要な最小限の権限を付与したカスタムポリシーを作成し、アタッチすることを推奨します。

    以下のJSONポリシーを **`GitHubActionsTerraformDeployPolicy`** という名前でカスタム管理ポリシーとして作成し、このロールにアタッチしてください。

    ```json
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Action": [
                    "iam:CreateRole",
                    "iam:GetRole",
                    "iam:UpdateRole",
                    "iam:DeleteRole",
                    "iam:AttachRolePolicy",
                    "iam:DetachRolePolicy",
                    "iam:PutRolePolicy",
                    "iam:DeleteRolePolicy",
                    "iam:PassRole" 
                ],
                "Resource": "*"
            },
            {
                "Effect": "Allow",
                "Action": [
                    "lambda:CreateFunction",
                    "lambda:UpdateFunctionConfiguration",
                    "lambda:UpdateFunctionCode",
                    "lambda:DeleteFunction",
                    "lambda:GetFunction",
                    "lambda:PublishLayerVersion",
                    "lambda:DeleteLayerVersion",
                    "lambda:GetLayerVersion",
                    "lambda:GetLayerVersionPolicy"
                ],
                "Resource": "*"
            },
            {
                "Effect": "Allow",
                "Action": [
                    "ssm:GetParameter"
                ],
                "Resource": "arn:aws:ssm:*:*:parameter/data-flow/kaggle/*"
            },
            {
                "Effect": "Allow",
                "Action": [
                    "s3:ListBucket",
                    "s3:GetBucketLocation"
                ],
                "Resource": "arn:aws:s3:::data-flow-tfstate"
            },
            {
                "Effect": "Allow",
                "Action": [
                    "s3:GetObject",
                    "s3:PutObject",
                    "s3:DeleteObject"
                ],
                "Resource": "arn:aws:s3:::data-flow-tfstate/*"
            }
        ]
    }
    ```

    **注意**: 上記ポリシーは、現在のTerraform構成に基づいたものです。今後、Terraformで管理するAWSリソースが増える場合は、必要に応じてこのポリシーに権限を追加してください。また、`Resource`を`*`としている箇所は、可能であればより具体的なARNに絞り込むことで、さらにセキュリティを強化できます。

    最初はテスト用に`AdministratorAccess`をアタッチし、動作確認後に上記の最小権限ポリシーに絞り込むことも可能です。
7.  「次へ」をクリックします。
8.  「ロール名」に任意の名前を入力します（ `GitHubActionsTerraformDeployRole`）。
9.  「ロールを作成」をクリックして作成を完了します。作成されたロールのARNを控えておいてください。これは次のステップでGitHub Actionsワークフローに設定します。

---

### 2. GitHub Actionsワークフローの変更

`terraform-deploy.yml`ファイル内の`aws-actions/configure-aws-credentials`アクションの設定を変更し、IAMロールのARNを指定するようにします。これにより、ワークフローは指定されたIAMロールを引き受けてAWSリソースにアクセスします。

1.  リポジトリの`.github/workflows/terraform-deploy.yml`ファイルを開きます。
2.  `jobs.deploy.steps`セクションにある`Configure AWS Credentials`ステップを以下のように変更します。

    ```yaml
          - name: Configure AWS Credentials
            uses: aws-actions/configure-aws-credentials@v1
            with:
              role-to-assume: arn:aws:iam::<YOUR_AWS_ACCOUNT_ID>:role/GitHubActionsTerraformDeployRole # ここに作成したIAMロールのARNを指定
              aws-region: ap-northeast-1
              # role-session-name: GitHubActionsSession # オプション：セッション名を指定
    ```
    - `role-to-assume`: AWSで作成したIAMロールのARNを指定します。`YOUR_AWS_ACCOUNT_ID`と`GitHubActionsTerraformDeployRole`は、ご自身の環境に合わせて置き換えてください。

3.  `Build and Run Terraform`ステップの`env`セクションから`AWS_ACCESS_KEY_ID`と`AWS_SECRET_ACCESS_KEY`の行を削除します。OIDC認証を使用する場合、これらのシークレットは不要になります。

    ```yaml
          - name: Build and Run Terraform
            run: |
              cd terraform
              docker-compose build
              docker-compose run --rm terraform-cli bash -c "terraform init && terraform apply -auto-approve"
            # env:
            #   AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
            #   AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
    ```

---

### 3. `GEMINI.md`の更新

新しいドキュメント`github-actions-iam-role-auth.md`への参照を`GEMINI.md`に追加します。

```markdown
- **GitHub Actions**: `.github/docs/github-actions/`
  - `auto-pr-workflow.md`: Issue起票からPull Request作成までの自動化ワークフローに関する仕様。
  - `terraform-deploy-workflow.md`: Terraformによるインフラデプロイ自動化ワークフローに関する仕様。
  - `github-actions-iam-role-auth.md`: GitHub ActionsでのIAMロール認証（OpenID Connect）の設定方法。
```

---

## 次のステップ

上記の手順に従ってAWSでの設定を行い、GitHub Actionsワークフローの変更を`main`ブランチにプッシュしてください。これにより、IAMロール認証を使用したTerraformデプロイが試行されます。
