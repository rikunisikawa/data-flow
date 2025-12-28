# 要件: dbt を Fargate で実行し Step Functions に統合

## 背景/Context
- 現状: dbt はローカル/Docker で手動実行。将来的にパイプラインへ組み込みたい。
- 目標: Download → Convert（Lambda）→ dbt（Fargate）を Step Functions で直列実行し、再現性/安定性/権限管理を強化。

## 機能要件（FR）
- FR-1: ECR に dbt コンテナイメージを配置できる。
- FR-2: Fargate タスクで `dbt run -m cleaned_activities` と `dbt test` を実行できる。
- FR-3: タスクは `.env.dev` 相当の環境変数で設定可能（S3/Athena/Glue/Region/WorkGroup）。
- FR-4: Step Functions から `RunTask` で起動し、成功/失敗の状態遷移を制御できる。
- FR-5: ログは CloudWatch Logs に集約し、失敗時は原因調査可能な粒度で出力される。

## 非機能要件（NFR）
- NFR-1: IaC（Terraform）で再現可能。
- NFR-2: 最小権限の IAM を適用。
- NFR-3: コスト見積り/メトリクス（実行時間/回数）を可視化できる。

## 制約/Assumptions
- Athena + Glue Data Catalog を継続利用。
- VPC 内 Fargate（パブリックサブネット + Public IP 付与）で外部エンドポイントに到達。

## 受け入れ基準（Acceptance Criteria）
- AC-1: dev 環境で Step Functions 実行完了（dbt ステップ成功）を確認。
- AC-2: `processed` スキーマ/S3 出力の整合性が保たれる（既存と同等）。
- AC-3: CloudWatch Logs に実行/エラーが記録される。

## アーキ設計
- ECR: `data-platform/dbt`（タグ: `dev|prod-<semver>`）。
- ECS/Fargate: 1 サービス（on-demand 起動用に RunTask のみ、常駐サービスは不要）。
- Step Functions: `Download` → `Convert` → `Run dbt (ECS)` → `Done`（Catch/Fail 設計を維持）。
- ネットワーク: VPC/パブリックサブネット/IGW/SG（最小開放、NAT なし）。

---
