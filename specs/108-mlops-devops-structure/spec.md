# 要件: MLOps/DevOps 構成

## 機能要件（FR）
- FR-1: PR で dbt test と pytest が実行される（失敗でブロック）。
- FR-2: コンテナ（dbt/学習）のビルドと ECR への push を自動化（dev ブランチ）。
- FR-3: Terraform plan の可視化と apply の承認フロー（dev 自動、本番手動）。
- FR-4: モデル成果物（S3）のバージョン管理とメトリクスの長期保存。

## 非機能要件（NFR）
- NFR-1: OIDC + 最小権限 IAM を使用し、シークレットは保持しない。
- NFR-2: 実行ログ/メトリクスが CloudWatch に集約、失敗時トリアージが容易。
- NFR-3: すべて IaC/コード化し、手動手順を最小化。

## 受け入れ基準
- AC-1: テスト未達（dbt/pytest）の PR はマージ不可。
- AC-2: main マージで dev へ自動反映、prod は承認後に反映。
- AC-3: モデルの世代（timestamp/semver）が S3 キーで一意に判別可能。

---
