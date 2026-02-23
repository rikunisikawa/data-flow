==============================================================
artifacts/ ディレクトリ — 成果物置き場ポリシー
==============================================================
最終更新: 2026-02-23

--------------------------------------------------------------
このディレクトリの目的
--------------------------------------------------------------
Claude Skills（00-intake〜80-improve）が生成する成果物の置き場。
分析プロジェクト1件 = サブディレクトリ1つ。

--------------------------------------------------------------
ディレクトリ命名規則
--------------------------------------------------------------
形式: docs/artifacts/<YYYYMMDD>_<slug>/

  YYYYMMDD : 依頼受付日（例: 20260223）
  slug     : 依頼の短縮識別子（英数字とハイフンのみ。例: medication-kpi）

例:
  docs/artifacts/20260223_medication-kpi/
  docs/artifacts/20260224_churn-analysis/

--------------------------------------------------------------
成果物ファイル一覧（各Skillが生成する最低限のファイル）
--------------------------------------------------------------
docs/artifacts/<YYYYMMDD>_<slug>/
  analysis_charter.txt    [00-intake]  分析チャーター
  wbs.txt                 [00-intake]  作業分解構造
  constraints.txt         [00-intake]  制約一覧
  data_map.txt            [10-discover] データ所在マップ
  grain_notes.txt         [10-discover] 粒度確認メモ
  data_contract.yaml      [20-contract-quality] データ契約
  data_quality_plan.txt   [20-contract-quality] 品質計画
  transform_blueprint.txt [30-transform-blueprint] 変換設計書
  eda_plan.txt            [40-eda]     EDA計画
  hypothesis_log.txt      [40-eda]     仮説ログ
  ml_plan.txt             [50-ml-optional] ML計画（任意）
  eval_plan.txt           [50-ml-optional] 評価設計（任意）
  model_card.txt          [50-ml-optional] モデルカード（任意）
  report_outline.txt      [60-report]  レポートアウトライン
  executive_summary.txt   [60-report]  エグゼクティブサマリー
  monitoring_plan.txt     [70-operate] 監視計画
  runbook_incident.txt    [70-operate] インシデントランブック
  slos_slis.txt           [70-operate] SLO/SLI定義
  improvement_backlog.txt [80-improve] 改善バックログ
  tech_debt_register.txt  [80-improve] 技術負債登録

--------------------------------------------------------------
運用ルール
--------------------------------------------------------------
1. 成果物はすべてGitで管理する（レビュー可能・監査可能）
2. 実データ・secrets（APIキー/パスワード/個人情報）は絶対に含めない
3. 数値はすべてTBDで生成し、人間がレビュー後に実測値を補完する
4. 配布・実行が必要なものはPRレビューを経てL3承認を得てから行う
5. 成果物ファイルを削除する場合はPRで変更理由を明記する

--------------------------------------------------------------
サンプルディレクトリ構造
--------------------------------------------------------------
docs/artifacts/
  README.txt                        ← このファイル
  20260223_example-project/
    analysis_charter.txt            ← サンプル（実データなし）
    data_map.txt                    ← サンプル（プレースホルダのみ）

--------------------------------------------------------------
注意: artifacts/ は .gitignore しない
--------------------------------------------------------------
設計書・契約書・仮説ログはすべてGit管理対象とする。
実行結果・ログ・大容量バイナリはこのディレクトリに置かない。

==============================================================
