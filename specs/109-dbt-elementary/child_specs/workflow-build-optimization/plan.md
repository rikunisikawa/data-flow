# 計画: Lambda/Layer ビルドの条件付きスキップ

## 目的
- PR/CI の所要時間を削減しつつ、Terraform の参照エラーを防ぐ。

## 前提
- `.github/workflows/` は直接編集禁止（設計とタスク化まで）。
- 同階層の `terraform-deploy copy.yml` / `terraform-deploy-pr-dev copy.yml` を参考にする。

## 作業ステップ
1) 既存ワークフローの対象パス/ビルド手順を整理。
2) 条件判定（paths または git diff）とフォールバック条件を設計。
3) 実装タスクの切り出し（別チケット化）。

## 受け入れ条件
- 変更が無い場合のスキップ条件が定義されている。
- 変更がある場合は必ずビルドが実行される。
- スキップ時も Terraform が失敗しない運用が明確。

---
