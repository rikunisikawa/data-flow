# 要件: Elementary でデータ品質指標（件数/NULL/分布）を可視化

## 背景/Context
- 目的: mHealth のステージング/加工テーブルに対し、件数/NULL 件数/分布といった品質指標を継続的に確認できる仕組みを用意したい。
- 現状: dbt のテストはあるが、指標の継続的な収集/可視化が不足している。

## 機能要件（FR）
- FR-1: Elementary を dbt プロジェクトに導入し、メタデータテーブルを作成できる。
- FR-2: 行数/NULL 件数/分布などの指標を Elementary のメトリクスとして収集できる。
- FR-3: 指標は `cleaned_activities` など主要モデルを対象に設定できる。
- FR-4: `edr monitor` で HTML レポートを生成し、指標を確認できる。
- FR-5: 既存の dbt 実行環境（Athena + Glue Catalog）を維持したまま追加できる。

## 非機能要件（NFR）
- NFR-1: IaC/設定ファイルで再現可能（ローカル/Docker いずれでも同手順）。
- NFR-2: Athena のスキャン量を抑える（対象モデル/期間を限定）。
- NFR-3: 秘密情報はコードに埋め込まず、既存の環境変数/プロファイルで注入する。

## 制約/Assumptions
- `data_flow_dbt` を対象とし、接続先は `awsdatacatalog` + Athena を継続利用する。
- Elementary のメタデータ用スキーマは既存スキーマと分離する（例: `dev_elementary`）。

## 受け入れ基準（Acceptance Criteria）
- AC-1: `dbt deps` と `dbt build --select elementary` が成功する。
- AC-2: `edr monitor` で HTML レポートが生成され、件数/NULL 件数/分布の指標が確認できる。
- AC-3: 既存の dbt モデル/テストが影響を受けない。

## アーキ設計
- dbt packages: `packages.yml` に Elementary を追加。
- Elementary 設定: `elementary_config.yml` を追加し、`ELEMENTARY_SCHEMA` を明示。
- 実行: `dbt build --select elementary` → `edr monitor --config-file ...` の順で実行。
- 出力: レポートは `elementary/monitoring-reports/` に生成。

---
