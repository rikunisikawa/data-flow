# Skill: 60-report — レポート設計・エグゼクティブサマリー生成

## name
60-report

## description
分析結果のレポートアウトライン・エグゼクティブサマリーを生成する。
レポートの配布・送信は行わない。生成のみ。

---

## 目的
「分析の問いへの答え」と「意思決定者へのメッセージ」を構造化する。
実数字が埋まっていなくても、構造を先に確定しておくことで品質を高める。

---

## 入力（ユーザーが埋めるパラメータ）

```
slug:           依頼の識別子
date:           依頼日（YYYYMMDD）
question:       分析の問い（00-intakeと同じ）
key_findings:   主要な発見（箇条書き。数字はTBDで可）
recommendation: 推奨アクション
audience:       報告対象
sensitivity:    機密区分
format:         希望する形式（例: 1ページサマリー / スライド構成 / 詳細レポート）
```

## 出力（成果物ファイルのパス）

```
docs/artifacts/<date>_<slug>/report_outline.txt
docs/artifacts/<date>_<slug>/executive_summary.txt
```

---

## ガードレール（禁止事項）

- レポートの外部送信（メール・Slack・社外共有）は行わない
- 実数値が確認前の段階で確定的な数字を記述しない（[TBD]を使う）
- confidential/restricted区分のデータを含む場合は機密ラベルを必ず付ける
- PIIを含む個人レベルの情報をレポートに含めない

> **このSkillは生成のみ。実行はしない。**

---

## 使用手順

1. 40-edaまたは50-ml-optionalの成果物を参照してパラメータを埋める
2. 数字は後から埋められるようにプレースホルダ（[TBD]）で記述する
3. Reporter AgentとOrchestrator AgentがレビューしてからPRでレビューに出す
4. 配布はL3承認後に人間が実施する

---

## 関連テンプレート

- `templates/report_outline.txt`    → レポートアウトラインの雛形
- `templates/executive_summary.txt` → エグゼクティブサマリーの雛形
