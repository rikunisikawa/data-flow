---
name: triaging-mhealth-tips
description: mHealth リポジトリのトラブルシュート（Mermaid エラー、Notebook 破損、ツール tips）を扱う。ドキュメント修正や Mermaid 図、.ipynb 修復時に使用。
---

# mHealth トラブルシュート

## 目的
ドキュメントやノートブックの問題を安全かつ再現性のある手順で解決する。

## 使用する場面
- Mermaid のパースエラーや図の崩れを修正するとき。
- `.ipynb` の JSON 破損を修復するとき。
- Spec Kit / Gemini CLI の tips を参照するとき。

## 入力
- 対象ファイルのパス（Mermaid Markdown または .ipynb）。
- エラー内容や発生状況。

## 手順
1. `ai-doc/tips/troubleshooting-notebook-mermaid.md` を読む。
2. `references/tips-reference.md` のチェックリストを実行する。
3. Notebook を編集する場合、JSON が単一オブジェクトで必須メタデータを持つことを確認する。

## 出力期待
- エラー種別に紐づいた簡潔な修正プラン。
- 検証手順の短いメモ。

## 参照
- `references/tips-reference.md`
