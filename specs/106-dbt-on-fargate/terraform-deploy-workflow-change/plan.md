# 計画: Terraform デプロイワークフローに dbt イメージ対応を追加

**Branch**: `106-dbt-on-fargate` | **Owner**: Data Platform | **Date**: 2025-10-03

## 目的
- dbt イメージのビルド/プッシュを CI に組み込み、Terraform の `dbt_image_tag` と整合させる。
- 手動手順のばらつきを減らし、デプロイの再現性を高める。

## スコープ
- 追加: ワークフロー内の dbt イメージ build/push ステップ
- 変更: Terraform apply に `dbt_image_tag` を上書き指定
- 非対象: `.github/workflows/` の直接編集（別ファイルとして提案のみ）

## 方針/設計
- タグは CI で生成（例: `prod-<short_sha>`）。
- `prod.tfvars` は変更しない。`terraform apply -var "dbt_image_tag=..."` で上書き。
- トリガー条件に dbt 関連ファイルの変更を追加。

## フェーズ
1) ワークフロー差分の設計と合意
2) IAM 権限（ECR push）確認
3) ワークフロー反映（別途レビュー/承認）

## DoD（受入基準）
- dbt イメージが CI でビルド/プッシュされる。
- Terraform apply が CI のタグを参照して実行される。
- 既存の Lambda/Layer デプロイに影響がない。

## リスク/対策
- ECR 権限不足: `GitHubActionsTerraformDeployRole` のポリシーを事前確認。
- タグ衝突: `short_sha` 等で一意性を担保。
