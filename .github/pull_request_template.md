## 変更の目的
<!-- このPRが何のためのものかを1〜3文で記述してください -->


## 変更の種類
<!-- 該当するものにチェックしてください -->
- [ ] 新規分析プロジェクトの設計ドキュメント追加
- [ ] 既存設計ドキュメントの更新
- [ ] Skill / テンプレートの追加・更新
- [ ] Agent Team設計・Playbook更新
- [ ] ガードレール（hooks/governance）更新
- [ ] GitHub テンプレート / CI更新
- [ ] バグ修正
- [ ] その他: <!-- 記述してください -->

## 生成物（artifacts パス）
<!-- Claude Skillsが生成した成果物のパスを記載してください -->
<!-- 成果物がない場合は「なし」と記入してください -->
- `docs/artifacts/[YYYYMMDD]_[SLUG]/`
  - [ ] analysis_charter.txt
  - [ ] wbs.txt
  - [ ] constraints.txt
  - [ ] data_map.txt
  - [ ] data_contract.yaml
  - [ ] data_quality_plan.txt
  - [ ] transform_blueprint.txt
  - [ ] eda_plan.txt
  - [ ] hypothesis_log.txt
  - [ ] report_outline.txt
  - [ ] executive_summary.txt
  - [ ] monitoring_plan.txt
  - [ ] runbook_incident.txt
  - [ ] slos_slis.txt
  - [ ] improvement_backlog.txt
  - [ ] tech_debt_register.txt

## 実行はしていない宣言（必須）
<!-- このPRに含まれる変更について確認してください -->
- [ ] **実データへのアクセスは行っていない**
- [ ] **クエリ・ジョブ・Lambda等の実行は行っていない**
- [ ] **S3・DWH・本番環境への書き込みは行っていない**
- [ ] **secrets（APIキー/パスワード/接続文字列）をコミットしていない**
- [ ] **外部サービスへの送信（メール/Slack/Webhook等）は行っていない**

## レビューチェックリスト
<!-- レビュアー向けの確認事項 -->
- [ ] 成果物ファイルにsecrets（APIキー等）が含まれていないか
- [ ] PIIデータが成果物に実値で含まれていないか
- [ ] 機密区分ラベルが適切か（public/internal/confidential/restricted）
- [ ] TBDの箇所が意図的か（後で補完予定か）
- [ ] 実行が必要な操作に `[要L2承認]` または `[要L3承認]` ラベルが付いているか
- [ ] 関連するSkill/Playbookと整合しているか

## リスクと残課題
<!-- このPRに含まれるリスクや、後続で解決が必要な事項 -->
### リスク
- [ ] 特になし
- [ ] リスクあり: <!-- 記述してください -->

### 残課題（次のフェーズで対応）
<!-- 今回のスコープ外にした事項と理由 -->


## 関連Issue
<!-- 対応するGitHub Issueのリンク -->
Closes #

## 実行が必要な操作（承認後に人間が実施）
<!-- このPRマージ後に人間が実施する必要がある操作があれば記載 -->
<!-- 操作なければ「なし」 -->
- [ ] なし
- [ ] 要L2承認: <!-- 操作内容 -->
- [ ] 要L3承認: <!-- 操作内容 -->
