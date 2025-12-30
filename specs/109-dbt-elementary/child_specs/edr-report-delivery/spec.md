# 方針: Elementary レポート HTML を S3 + CloudFront（OAC）+ Cognito/OIDC で配信

## 目的
- ECS で生成された Elementary の HTML レポートを、安全に閲覧できる仕組みを用意する。
- S3 直アクセスは遮断し、CloudFront 経由で配信・認証を必須にする。

## 前提
- レポート生成コマンド: `edr monitor report` を ECS タスク内で実行。
- 生成物は `elementary/monitoring-reports/` 配下に出力される。
- Terraform でリソース管理を行う。

## 方針（高レベル）
- 配信基盤: S3（静的オブジェクト格納）+ CloudFront（OAC）
- 認証: Cognito User Pool + Hosted UI（OIDC）を CloudFront に紐付け
- アクセス制御: OAC で S3 直アクセスを遮断し、署名付きリクエストのみ許可

## 具体設計
### 1) レポートの格納
- S3 へ `processed/elementary-reports/` など専用プレフィックスに配置。
- ECS タスク内で `aws s3 sync` を実行し、最新レポートを上書き配置。
- 例: `s3://<bucket>/processed/elementary-reports/latest/`

### 2) CloudFront + OAC
- CloudFront のオリジンに S3 を設定し、OAC を有効化。
- S3 バケットポリシーで CloudFront 経由のみ許可。
- キャッシュポリシーは HTML 向けに短め（例: 5-15 分）を推奨。

### 3) 認証（Cognito / OIDC）
- Cognito User Pool を作成し、Hosted UI でログイン画面を提供。
- CloudFront に OIDC 認証を適用（Lambda@Edge or CloudFront Functions を利用）。
- 認証成功後のみ CloudFront オリジンへアクセス可能。

### 4) 運用
- レポート更新は ECS 実行のたびに上書き。
- 古いレポートは世代管理が必要なら `history/yyyymmdd/` に保存。
- アクセスログは CloudFront 標準ログで監査。

## 受け入れ基準
- AC-1: ECS 実行後、最新レポートが S3 に配置される。
- AC-2: CloudFront 経由でのみアクセス可能（S3 直アクセス不可）。
- AC-3: Cognito 認証なしではレポート閲覧不可。
- AC-4: 認証後に HTML レポートが正常に表示される。

## 手順（初回のみ2段階）
1) `terraform apply` を実行して CloudFront のドメインを確定する。
2) `terraform/outputs.tf` の `elementary_reports_url` を確認し、
   `terraform/dev.tfvars` の `elementary_reports_callback_urls` / `elementary_reports_logout_urls` を
   `https://<cloudfront-domain>/oauth2/idpresponse` と `https://<cloudfront-domain>/logout` に更新する。
3) もう一度 `terraform apply` を実行して Cognito 設定を確定する。

## 留意点
- CloudFront + Cognito の統合は Lambda@Edge が必要になるため、
  デプロイリージョン/権限設計に注意。
- OIDC と CloudFront の構成は Terraform で統一管理する。

---
