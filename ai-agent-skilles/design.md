# CODEX向け Agent Skills 設計案（ドラフト）

## 目的
- 既存ドキュメント（主に `ai-doc/`）を棚卸しし、Codex が常時参照できる「Agent Skills（行動規範・作業手順・品質基準）」へ再編する設計案を提示する。
- 既存ドキュメントに「基本ルール」が不足している場合は、不足を明示し、最小限の補完案を提示する（推測はせず TODO を残す）。
- **Agent Skills のオープン標準**（SKILL.md + optional resources）に準拠し、Progressive Disclosure を前提に設計する。

---

## 作業開始手順
1. `ai-doc/README.md` の「読み順のおすすめ」から全体像を把握する。
2. `ai-doc/infra/` と `ai-doc/operations/` を優先して読み、運用・設計の方針を把握する。
3. 必要に応じて `README.md` と `AGENTS.md` を参照し、既存のルール・制約を確認する。

---

## タスク2: 基本ルールの有無チェック結果（先に出力）

### A. 既存ドキュメントに存在する基本ルール（根拠付き）
- 作業開始時の手順: `ai-doc/README.md` に「読み順のおすすめ」が明記されている。
- コード品質（テスト）: `AGENTS.md` に「Python変更時のユニットテスト必須」が明記されている。
- 秘密情報/機密: `AGENTS.md` に Kaggle 資格情報は SSM/環境変数に保持し、コードへ直書きしないと明記されている。
- 変更管理（Terraform）: `ai-doc/infra/terraform-design.md` に dev/prod の workspace 分離と CI/CD デプロイ方針が明記されている。
- ログ/監視: `AGENTS.md` に Lambda ログの出力方針（単行・JSON 風）と機密値の非出力が明記されている。
- 依存/環境: `ai-doc/infra/dbt_athena_setup.md` と `ai-doc/infra/dbt_usage_and_design.md` に dbt 実行手順・環境変数・Docker 実行が明記されている。

### B. 存在しない/弱い基本ルール（不足理由を明記）
- 安全（危険コマンド/破壊的変更の扱い）: 明示的な禁止や承認フローがドキュメント化されていない。
- 変更管理（PR/レビュー/リリース）: 自動 PR ワークフローの説明はあるが、ブランチ戦略・レビュー基準・リリース手順の統一ルールが不足。
- ディレクトリ/命名規則: `ai-doc` 内で個別の命名例はあるが、リポジトリ全体の命名規則が不足。
- 依存/環境（バージョン固定/再現性）: dbt 以外の依存やバージョン固定方針が包括的に整理されていない。
- ログ/監視/運用（障害対応/ロールバック）: トラブルシュートはあるが、運用 runbook の体系化が不足。

### C. 不足分を埋めるための“最小ルール案”（AGENT.md追記想定）
- **安全**: 破壊的コマンド（例: `terraform destroy`, `aws s3 rm --recursive`）は原則禁止。実行が必要な場合は理由・影響範囲・ロールバック案を事前に明記する。
- **変更管理**: 変更は小さく分割し、レビュー観点（影響範囲/テスト/ロールバック）を PR 本文に必ず記載する。
- **命名/配置**: 新規ファイルは既存のディレクトリ規約（`ai-doc/`, `scripts/`, `terraform/` など）に従い、命名は snake_case を優先する。
- **依存/環境**: 依存追加はバージョンを明示し、再現性のため `requirements.txt` / `Dockerfile` / `pyproject` のいずれかを更新する。
- **運用/ロールバック**: 変更で障害が起きた場合の復旧手順（S3/Glue/dbt/Step Functions いずれか）を簡潔に残す。
- **TODO**: リポジトリ全体の「危険コマンド一覧」と「リリース手順」は現行ドキュメントに無いため、担当者合意後に追記する。

---

## タスク1: 既存ドキュメント棚卸し（一覧 + 役割分類）

> 形式: `パス / タイトル / 要点 / 役割カテゴリ`

### ai-doc/README.md
- `ai-doc/README.md` / **ai-doc README — ドキュメント案内** / 読み順、関連ドキュメント、dbt/Terraform/運用の参照先を整理 / ルール・全体案内

### ai-doc/infra
- `ai-doc/infra/system_design.md` / **AI向け指示用仕様書：SAMを用いたデータ基盤開発** / 全体像、S3階層、ETL、Fargate dbt、権限・ネットワーク / インフラ設計
- `ai-doc/infra/etl_flow.md` / **mHealth ETL フロー図（Mermaid）** / ETL/ラインエイジ、パーティション戦略 / インフラ設計・データフロー
- `ai-doc/infra/aws_architecture_diagram.md` / **AWS Architecture Diagram** / VPC/ECS/Step Functions 連携図 / インフラ設計
- `ai-doc/infra/dbt_athena_setup.md` / **dbt 導入手順書（Athena + Glue 対応）** / dbt 実行方法（ローカル/Docker/ECS）、環境変数 / 開発・運用
- `ai-doc/infra/dbt_environment_overview.md` / **dbt 環境概要** / dbt プロジェクト構成、profiles 設定 / 開発・運用
- `ai-doc/infra/dbt_usage_and_design.md` / **dbt 運用ガイド（Athena/Glue + mHealth）** / 実行コマンド、環境変数、モデル設計、トラブルシュート / 開発・運用
- `ai-doc/infra/terraform-design.md` / **Terraform 設計ドキュメント** / workspace 分離、命名規則、CI/CD の流れ / インフラ規約
- `ai-doc/infra/sam.md` / **AI向け指示用仕様書：SAMを用いたデータ基盤開発** / SAM でのETL構成（レガシー参照） / レガシー設計

### ai-doc/operations
- `ai-doc/operations/deployment_strategy.md` / **Lambdaレイヤーを含むデプロイ戦略** / build.sh, layer, Terraform apply の実行順序 / 運用手順
- `ai-doc/operations/dbt_elementary_usage.md` / **dbt/Elementary 運用手順** / Elementary のスキーマ/レポート生成 / 運用手順
- `ai-doc/operations/workflow-usage.md` / **開発フロー自動化ガイド** / auto-pr ワークフロー、Plan/Implement フェーズ / 変更管理
- `ai-doc/operations/parallel-worktrees-for-specs-107-108.md` / **複数ブランチの並列開発ガイド** / git worktree の運用 / 変更管理
- `ai-doc/operations/terraform-deploy-workflow-change-proposal.md` / **Terraform Deploy Workflow 変更案** / dbt イメージを CI に組み込む提案 / 変更管理

### ai-doc/project-plans
- `ai-doc/project-plans/issue-29-terraform-migration-plan.md` / **SAM から Terraform への移行計画** / 移行フェーズ、タスク分解 / プロジェクト計画
- `ai-doc/project-plans/mhealth/01_eda_plan.md` / **MHEALTH EDA Plan** / EDA, source 定義、staging/集計モデル / プロジェクト計画
- `ai-doc/project-plans/mhealth/02_cleansing_plan.md` / **MHEALTH Cleansing Plan** / 欠損/異常値処理、cleaned モデル / プロジェクト計画
- `ai-doc/project-plans/mhealth/03_feature_engineering_time_domain_plan.md` / **時間領域特徴量計画** / window 定義、特徴量集計 / プロジェクト計画
- `ai-doc/project-plans/mhealth/04_feature_engineering_frequency_domain_plan.md` / **周波数領域特徴量計画** / Python/FFT, S3 出力 / プロジェクト計画
- `ai-doc/project-plans/mhealth/05_final_feature_table_plan.md` / **最終特徴量テーブル計画** / time/frequency 特徴量の結合 / プロジェクト計画
- `ai-doc/project-plans/mhealth/06_model_training_plan.md` / **モデル学習計画** / LOSO 分割、学習・保存 / プロジェクト計画
- `ai-doc/project-plans/mhealth/07_model_evaluation_plan.md` / **モデル評価計画** / 評価指標、混同行列 / プロジェクト計画

### ai-doc/tips
- `ai-doc/tips/troubleshooting-notebook-mermaid.md` / **Notebook/Mermaid トラブルシュート集** / Mermaid/Notebook の修復手順 / Tips
- `ai-doc/tips/install-spec-kit.md` / **Spec Kit 導入手順** / uvx + Gemini での導入手順 / Tips
- `ai-doc/tips/gemini-cli-tips.md` / **Gemini CLI の Tips** / Gemini CLI のコマンドとセキュリティ / Tips

---

## タスク3: Skills への変換（再編）

### 3-1. 抽出ルール（例）
- **必ず**: 既存ドキュメントの要件や制約は強制ルールとして短文化。
- **禁止**: 機密情報の直書き、`.github/workflows/` 直接編集などは明示。
- **推奨/条件付き**: コスト配慮や optional な運用手順は推奨事項として記載。

### 3-2. 出力物（Skills 構成案）
- ルート直下（ドラフト用フォルダ内）: `AGENT.md`
- `agent-skills-draft/skills/` 配下に **Skill ディレクトリ**を配置（各ディレクトリに `SKILL.md` + `references/`）
  - `governing-mhealth-infra/`（インフラ/IaC/スキーマ/権限）
  - `operating-mhealth-services/`（デプロイ/運用/runbook）
  - `planning-mhealth-work/`（計画・タスクの進め方）
  - `triaging-mhealth-tips/`（トラブルシュート/ツールTips）
- README 追記案: 「AI は AGENT.md を最初に読む」を明記（本設計では提案のみ）。

---

## タスク4: マッピング（対応表）

| 元ドキュメント | Skills への対応 | 備考 |
| --- | --- | --- |
| `ai-doc/infra/system_design.md` | `governing-mhealth-infra` | AWS 構成・S3/ETL 流れ・権限方針 |
| `ai-doc/infra/etl_flow.md` | `governing-mhealth-infra` | パーティション/ラインエイジ |
| `ai-doc/infra/dbt_*` | `governing-mhealth-infra` / `operating-mhealth-services` | dbt 実行・環境変数・トラブルシュート |
| `ai-doc/infra/terraform-design.md` | `governing-mhealth-infra` | workspace 分離・命名規則 |
| `ai-doc/operations/deployment_strategy.md` | `operating-mhealth-services` | build.sh → Terraform apply の順序 |
| `ai-doc/operations/workflow-usage.md` | `operating-mhealth-services` | 自動 PR フロー |
| `ai-doc/operations/parallel-worktrees-for-specs-107-108.md` | `operating-mhealth-services` | worktree 運用 |
| `ai-doc/operations/terraform-deploy-workflow-change-proposal.md` | `operating-mhealth-services` | CI 変更案（注意事項） |
| `ai-doc/project-plans/**` | `planning-mhealth-work` | フェーズ分割・成果物・完了条件 |
| `ai-doc/tips/**` | `triaging-mhealth-tips` | Mermaid/Notebook/Gemini Tips |
| `AGENTS.md` | `AGENT.md` + 全 skills | 既存の原則・テスト方針 |

### 矛盾/重複の優先順位方針（提案）
1. `AGENTS.md` のルールを最優先（安全・テスト・機密）。
2. `ai-doc/infra`・`ai-doc/operations` を次点（設計・運用の最新方針）。
3. `README.md` は参照用だが、Terraform 以降の実装と矛盾する場合は `ai-doc` を優先。
4. `ai-doc/project-plans` は計画ドキュメントのため、最新実装と矛盾した場合は **TODO** 扱いにし、更新提案を残す。

---

## 生成するファイルのドラフト（このフォルダ配下）
- `agent-skills-draft/AGENT.md`
- `agent-skills-draft/skills/governing-mhealth-infra/SKILL.md`
- `agent-skills-draft/skills/operating-mhealth-services/SKILL.md`
- `agent-skills-draft/skills/planning-mhealth-work/SKILL.md`
- `agent-skills-draft/skills/triaging-mhealth-tips/SKILL.md`
- `agent-skills-draft/skills/**/references/*.md`

---

## リポジトリに追加する変更一覧（作成/編集ファイル）
- 作成/更新: `agent-skills-draft/design.md`
- 作成/更新: `agent-skills-draft/AGENT.md`
- 作成: `agent-skills-draft/skills/governing-mhealth-infra/SKILL.md`
- 作成: `agent-skills-draft/skills/operating-mhealth-services/SKILL.md`
- 作成: `agent-skills-draft/skills/planning-mhealth-work/SKILL.md`
- 作成: `agent-skills-draft/skills/triaging-mhealth-tips/SKILL.md`
- 作成: `agent-skills-draft/skills/**/references/*.md`
