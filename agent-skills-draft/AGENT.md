# AGENT.md（ドラフト）

以下は Codex 用の最上位ルール要約（20〜40行）。必ず/禁止/推奨/条件付きで強度を明記する。

1. **必ず** この AGENT.md を最初に読む。
2. **必ず** `agent-skills-draft/skills/` の該当 Skill を参照し、必要な SKILL.md のみを読み込む（Progressive Disclosure）。
3. **必ず** `ai-doc/README.md` の読み順に従い、`infra`/`operations` を優先して確認する。
4. **必ず** 変更前に影響範囲（S3/Glue/dbt/Step Functions/Terraform）を洗い出す。
5. **必ず** テスト方針に従い、Python変更時は `tests/` を更新する。
6. **必ず** Kaggle 資格情報は SSM/環境変数で管理し、コードへ直書きしない。
7. **必ず** Lambda の戻り値は既存の `statusCode/body` 形式を踏襲する。
8. **必ず** ログは `logging` を使い単行 JSON 風で出力し、機密値は出さない。
9. **必ず** 冪等性を意識し、再実行で破綻しない設計にする。
10. **必ず** パーティション戦略（`subject_id × activity_label`、`activity_label=0`除外）を維持する。
11. **必ず** スキーマ変更時は Glue Catalog/DBT/テストを同期更新する。
12. **必ず** `.github/workflows/` を直接編集しない。
13. **禁止** 認証情報・APIキー・個人情報をリポジトリに保存すること。
14. **禁止** 破壊的コマンド（`terraform destroy`, `aws s3 rm --recursive`）の無断実行。
15. **条件付き** 破壊的変更は理由・影響範囲・ロールバック案を明記できる場合のみ実施可。
16. **推奨** 変更は小さく分割し、意味単位でコミットする。
17. **必ず** PR には背景/変更点/影響範囲を簡潔に書く（Issue番号を含める）。
18. **推奨** dbt の実行は `data_flow_dbt/scripts/with-env.sh` または Docker を使う。
19. **必ず** Terraform は `dev/prod` の workspace 分離方針に従う。
20. **推奨** build/deploy 前に `build.sh` を実行し成果物の整合を取る。
21. **必ず** 依存追加時はバージョンを明示し、再現性のある管理ファイルを更新する。
22. **推奨** コスト配慮（Athenaスキャン量、Lambda実行時間）を明記する。
23. **必ず** AI の応答は日本語を基本とする（技術用語は英語可）。
24. **必ず** 不明点は推測せず TODO として残す。
25. **必ず** 変更内容はドキュメントと整合させる（`ai-doc/` と矛盾しない）。
26. **必ず** 新規ファイルは既存ディレクトリ構成に従って配置する。
27. **推奨** 変更が運用フローに影響する場合は `operations` ドキュメントを更新する。
28. **必ず** レガシー（SAM）と Terraform の差異は明確に区別して記載する。
29. **必ず** 例外発生時は握りつぶさず、原因が追えるログを残す。
30. **推奨** Mermaid/Notebook の修正は `ai-doc/tips/troubleshooting-notebook-mermaid.md` を参照する。
31. **TODO** 危険コマンド一覧・リリース手順は担当者合意後に追記する。
