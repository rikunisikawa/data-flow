# Skill: 80-improve — 改善バックログ・技術負債登録

## name
80-improve

## description
分析プロジェクト完了後の改善バックログと技術負債を整理した文書を生成する。
バックログへの登録・チケット起票の実行は行わない。生成のみ。

---

## 目的
「今回やらなかったこと・次回改善すべきこと」を明文化し、
プロジェクトの学習サイクルを回す。

---

## 入力（ユーザーが埋めるパラメータ）

```
slug:             依頼の識別子
date:             依頼日（YYYYMMDD）
retrospective:    今回の振り返り（うまくいったこと・課題）
missed_items:     対応できなかった事項（スコープ外にしたもの）
tech_debts:       確認された技術負債（テスト不足・スキーマ未整備等）
next_hypotheses:  次のEDA/分析に向けた仮説
quick_wins:       短期間で改善できる項目
long_term:        中長期の改善計画
```

## 出力（成果物ファイルのパス）

```
docs/artifacts/<date>_<slug>/improvement_backlog.txt
docs/artifacts/<date>_<slug>/tech_debt_register.txt
```

---

## ガードレール（禁止事項）

- 改善タスクを自律実行しない（バックログは「計画」であり「実行」ではない）
- 本番環境への変更は行わない
- 次の分析プロジェクトの実データアクセスは行わない
- チケットシステム（Jira/GitHub Issues等）への自動登録は行わない

> **このSkillは生成のみ。実行はしない。**

---

## 使用手順

1. 60-reportおよび70-operateの完了後に実施する
2. チーム全員の振り返りをパラメータとして渡す
3. 生成物はOrchestratorがレビューして次サイクルの00-intakeへフィードバックする
4. tech_debt_register.txtはQuality Agentが優先度付けをする

---

## 関連テンプレート

- `templates/improvement_backlog.txt` → 改善バックログの雛形
- `templates/tech_debt_register.txt`  → 技術負債登録の雛形
