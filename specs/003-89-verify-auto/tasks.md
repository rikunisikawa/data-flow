# Tasks for Feature: 新しいauto-pr.ymlワークフローの動作確認

- [ ] **フェーズ1: `plan` ジョブの動作検証**
  - [ ] テスト用Issueを作成する
    - タイトル: `[Test-89] auto-pr.yml plan job verification`
    - 本文: `This is a test issue to verify the 'plan' job of the auto-pr.yml workflow.`
  - [ ] `Plan and Implement on Issue` ワークフローの起動を確認する
  - [ ] 自動生成されたPull Requestを確認する
    - [ ] PRが作成されていること
    - [ ] PRのタイトルが `Spec: feature/issue-XXX ...` 形式であること
    - [ ] PRのブランチ名が `feature/issue-XXX` 形式であること
    - [ ] PRの本文に仕様ディレクトリへのリンクが含まれていること
    - [ ] PRの変更ファイルに `specs/` 配下のファイルが含まれていること

- [ ] **フェーズ2: `implement` ジョブの動作検証**
  - [ ] フェーズ1で作成されたIssueまたはPRに `/execute` とコメントを投稿する
  - [ ] `Plan and Implement on Issue` ワークフローの再起動を確認する
  - [ ] Pull Requestの更新内容を確認する
    - [ ] 新しいコミットが追加されていること
    - [ ] PRのタイトルが `feat: implement ...` 形式に変更されていること
    - [ ] PRの本文が実装概要に更新されていること

- [ ] **フェーズ3: 後片付け**
  - [ ] テスト用に作成したPull Requestをマージまたはクローズする
  - [ ] テスト用に作成したフィーチャーブランチを削除する
  - [ ] `specs/003-89-verify-auto/` に検証結果をまとめた `research.md` を作成・コミットする
