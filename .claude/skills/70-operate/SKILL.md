# Skill: 70-operate — 運用設計・監視計画・インシデントランブック

## name
70-operate

## description
データパイプラインの監視計画・SLO/SLI定義・インシデントランブックを生成する。
監視設定の適用・アラートの発報・インシデント対応の実行は行わない。生成のみ。

---

## 目的
「本番稼働後に何を監視し、障害時にどう動くか」を事前に設計する。
実装後の運用品質を担保するための設計書群を生成する。

---

## 入力（ユーザーが埋めるパラメータ）

```
slug:              依頼の識別子
date:              依頼日（YYYYMMDD）
pipeline_name:     パイプラインの名前（例: mhealth-etl）
slo_availability:  可用性SLO（例: 99.5%）
slo_freshness:     鮮度SLO（例: 1時間以内に処理完了）
alert_channels:    アラート通知先のプレースホルダ（例: [slack_channel], [pagerduty]）
on_call_rotation:  オンコールローテーション設計（あれば）
failure_scenarios: 想定障害シナリオ（例: S3接続失敗, Glue Job タイムアウト）
```

## 出力（成果物ファイルのパス）

```
docs/artifacts/<date>_<slug>/monitoring_plan.txt
docs/artifacts/<date>_<slug>/runbook_incident.txt
docs/artifacts/<date>_<slug>/slos_slis.txt
```

---

## ガードレール（禁止事項）

- 監視ツール・アラートシステムへの設定適用は行わない
- 実アラートの発報・テストは行わない
- インシデント対応を自律実行しない（ランブックは「人間が実施する手順書」）
- 本番環境への接続・変更は行わない
- secrets（Slack webhook URL / PagerDuty APIキー等）を成果物に含めない

> **このSkillは生成のみ。実行はしない。**

---

## 使用手順

1. 30-transform-blueprintの成果物を参照してパイプライン名等を埋める
2. SLO/SLI値は仮値（[TBD]）で生成し、本番計測後に更新する
3. アラート通知先はプレースホルダ（[slack_channel]）で記述する
4. ランブックは人間がレビューして承認する

---

## 関連テンプレート

- `templates/monitoring_plan.txt`   → 監視計画の雛形
- `templates/runbook_incident.txt`  → インシデントランブックの雛形
- `templates/slos_slis.txt`         → SLO/SLI定義の雛形
