# タスクリスト: dbt on Fargate + Step Functions 統合

### Task 1: ECR リポジトリの作成
- **説明**: dbt の Docker イメージを格納するための ECR リポジトリを Terraform で作成します。
- **成果物**: `terraform/modules/ecr/main.tf` (新規作成または既存モジュールへの追記)
- **検証方法**:
  - `terraform apply` を実行し、AWS コンソール上で ECR リポジトリが作成されていることを確認します。
  - または、`aws ecr describe-repositories --repository-names data-flow/dbt` コマンドでリポジトリ情報が返されることを確認します。

### Task 2: Docker イメージのビルドと ECR へのプッシュ
- **説明**: 既存の `docker/dbt/Dockerfile` を使用して dbt 実行用の Docker イメージをビルドし、Task 1 で作成した ECR リポジトリにプッシュします。このタスクは初期段階では手動で行います。
- **成果物**: ECR にプッシュされた Docker イメージ (`<account_id>.dkr.ecr.<region>.amazonaws.com/data-flow/dbt:latest`)
- **検証方法**:
  - `docker push <image_uri>` コマンドが成功することを確認します。
  - AWS コンソールまたは `aws ecr list-images --repository-name data-flow/dbt` コマンドで、イメージが ECR に存在することを確認します。

### Task 3: ECS/Fargate 実行基盤の構築
- **説明**: dbt タスクを実行するための ECS クラスター、Fargate タスク定義、IAM ロール (タスク実行ロール、タスクロール)、および CloudWatch Logs ロググループを Terraform で構築します。
- **成果物**: `terraform/modules/fargate/main.tf` (新規作成)
- **検証方法**:
  - `terraform apply` を実行し、関連リソースが AWS 上に作成されていることを確認します。
  - AWS CLI を使用して `aws ecs run-task` コマンドでタスクを単体で手動実行し、`dbt --version` などの簡単なコマンドが成功することを CloudWatch Logs で確認します。

### Task 4: Step Functions との統合
- **説明**: 既存の Step Functions ステートマシン (`data_processing.asl.json`) に、Task 3 で作成した Fargate タスクを同期的に呼び出す (`"Resource": "arn:aws:states:::ecs:runTask.sync"`) ステップを追加します。
- **成果物**:
    - `state_machine/data_processing.asl.json` の更新
    - `terraform/main.tf` のステートマシン定義リソースの更新
- **検証方法**:
  - AWS コンソールから dev 環境の Step Functions を手動で実行します。
  - ワークフローが dbt 実行ステップを含めて最後まで成功することを確認します。
  - Fargate タスクの実行ログと、最終的に Athena で変換後データが参照できることを確認します。

### Task 5: IAM 権限の最適化
- **説明**: Fargate タスクにアタッチする IAM タスクロールの権限をレビューし、S3 バケット、Glue データベース、Athena ワークグループなどへのアクセスを必要最小限に絞り込みます。
- **成果物**: `terraform/modules/fargate/main.tf` 内の IAM ポリシードキュメントの更新
- **検証方法**:
  - Step Functions を通したエンドツーエンドテストが、権限を絞り込んだ後も正常に動作することを確認します。
  - IAM Access Analyzer を使用して、過剰な権限がないことを確認します。

### Task 6: ドキュメントの更新
- **説明**: 今回のアーキテクチャ変更（dbt の Fargate で実行）について、関連する設計ドキュメントを更新します。
- **成果物**:
    - `ai-doc/infra/system_design.md` の更新
    - `ai-doc/infra/dbt_athena_setup.md` の更新
- **検証方法**:
  - プルリクエストのレビューで、ドキュメントの記述が実際のアーキテクチャと一致していることを確認します。