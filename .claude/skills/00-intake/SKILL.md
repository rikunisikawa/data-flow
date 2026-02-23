# Skill: 00-intake — 分析依頼の受付・スコープ定義

## name
00-intake

## description
分析依頼を受け取り、目的・KPI・制約・WBSを整理した分析チャーターを生成する。
実データへのアクセス・実行は行わない。生成のみ。

---

## 目的
分析プロジェクトの「起点」を明確化する。
曖昧な依頼を構造化し、後続フェーズ（discover → contract → EDA → report）で迷わないための
基盤ドキュメントを生成する。

---

## 入力（ユーザーが埋めるパラメータ）

```
slug:          依頼の短縮識別子（英数字ハイフン。例: medication-kpi）
date:          依頼日（YYYYMMDD。例: 20260223）
question:      分析で答えたい問い（1〜3文）
decision:      この分析で何を決めるか
kpi:           成功条件・主要指標（1〜5件）
deadline:      期限（例: 2026-03-31）
audience:      報告対象（例: プロダクトマネージャー、経営陣）
sensitivity:   機密区分（public / internal / confidential / restricted）
constraints:   既知の制約（データ制限・期間・ツール制限など）
```

## 出力（成果物ファイルのパス）

```
docs/artifacts/<date>_<slug>/analysis_charter.txt
docs/artifacts/<date>_<slug>/wbs.txt
docs/artifacts/<date>_<slug>/constraints.txt
```

---

## ガードレール（禁止事項）

- 実データの取得・参照は行わない
- SQL・クエリの実行は行わない
- 外部サービスへの送信は行わない
- secrets（APIキー・アカウントID・テーブル実名）を成果物に含めない
- 技術スタックに依存した実装コードを生成しない（プレースホルダのみ）

> **このSkillは生成のみ。実行はしない。**

---

## 使用手順

1. 上記「入力」パラメータを埋めてOrchestratorまたはClaudeに渡す
2. 成果物が `docs/artifacts/<date>_<slug>/` に生成される
3. 内容をレビューし、問題があれば修正してから次のSkill（10-discover）へ進む

---

## 関連テンプレート

- `templates/analysis_charter.txt`  → 分析チャーターの雛形
- `templates/request_clarification.txt` → 不明点ヒアリング用テンプレ
