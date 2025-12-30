# 要件: PR 作成時に dev へ自動デプロイする GitHub Actions

## 背景/Context
- dbt の修正後に ECR へ push し忘れるケースがあるため、PR の段階で dev 環境へ自動反映したい。
- 本番向けの GitHub Actions は既に運用中（main への push/merge 時）。

## 目的
- PR 作成/更新時に dev 環境へ自動デプロイし、検証を早期に完了できる状態にする。
- Lambda 更新・Terraform apply・ECR push を一連で自動化し、手作業を減らす。

## 対象スコープ
- Terraform apply（dev workspace / dev.tfvars）
- Lambda/Layer のビルドと更新
- dbt イメージ build と ECR push（dev タグ）

## 非対象
- `.github/workflows/` の直接編集（運用ルールにより禁止）
- prod 環境の自動 apply（既存の main merge フローを維持）

## 機能要件（FR）
- FR-1: PR 作成/更新時に dev 用の GitHub Actions をトリガーできる。
- FR-2: dbt イメージを build し、ECR に push できる（タグは `dev-<sha>` など）。
- FR-3: Lambda/Layer をビルドして dev に反映できる。
- FR-4: Terraform apply を dev workspace に対して実行できる。
- FR-5: 実行結果（成功/失敗）が PR で確認できる。

## 非機能要件（NFR）
- NFR-1: dev のみに限定し、prod へは影響を与えない。
- NFR-2: 失敗時に原因が追跡できるログを残す。
- NFR-3: 権限は最小限（OIDC で assume role）。

## フロー設計
1) Checkout
2) AWS 認証（OIDC assume role）
3) Lambda/Layer build
4) dbt イメージ build + ECR push
5) Terraform apply（dev tfvars）

## トリガー条件案
- `pull_request` on `main`
- 対象パス: `terraform/**`, `download_and_upload/**`, `convert_log_to_parquet/**`, `layer/**`, `build.sh`, `docker/dbt/**`, `dbt_profiles/**`, `scripts/build_dbt_image.sh`

## 受け入れ基準（Acceptance Criteria）
- AC-1: PR 作成時に dev への deploy が動作する。
- AC-2: ECR に dev タグのイメージが作成される。
- AC-3: Terraform apply が dev で成功する。
- AC-4: PR で実行結果が確認できる。

## 運用/セキュリティ
- apply の実行条件をラベル/手動承認に限定する案を検討。
- prod は既存フローに限定し、dev とはロール/変数を分離。

---
