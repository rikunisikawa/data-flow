# AIコーディング最適化

## Issue
- Issue Title: AIコーディング最適化
- Issue Body: GEMINI.mdの内容を修正したい。ai-doc/infraに新しくmdファイルを作成して、そこにGemini.mdに書かれている全体の設計を移動させたい。その上で、GEMINI.mdには全体設計はai-doc/infraに存在することを明記したい。さらに、GEMINI.mdには、以下を付け加えたい
  - 指示の内容と変更履歴、進捗を gemini-cli-log/フォルダに.mdで保存する
  - pythonコードを変更する場合はテストコードを作成する

## 変更概要

Issueに基づき、`GEMINI.md`と`ai-doc/infra/system_design.md`を確認しました。
結果、Issueで要求されている以下の項目はすべて対応済みであることが判明しました。

1.  **全体設計の別ファイルへの移行**:
    - `GEMINI.md`から全体設計が削除され、`ai-doc/infra/system_design.md`に移動されていました。
2.  **`GEMINI.md`の更新**:
    - 全体設計ドキュメントへのリンクが記載されていました。
    - `gemini-cli-log/`へのログ保存ルールが追記されていました。
    - テストコード作成のルールが追記されていました。

## 結論

要求されたコード変更はすでに完了しているため、今回はファイルの確認のみ実施しました。
この変更を反映させるためのPull Requestを作成します。
