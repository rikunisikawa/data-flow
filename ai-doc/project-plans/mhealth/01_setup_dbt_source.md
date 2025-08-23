# タスク1.1: dbtソースの定義とデータ品質の確認

## 目的

MHEALTHデータセットの生データをdbtのソースとして定義し、データの基本的な品質を確認するためのモデルを構築する。

## 背景

このプロジェクトでは、S3に配置済みの `stage_raw_activities` テーブルをデータソースとして利用します。
まず、このテーブルをdbtのソースとして正式に定義し、後続の変換処理で参照できるようにします。
また、データの品質（カラム数、データ型、欠損値の有無など）を確認するための基本的なテストとモデルを実装し、データの信頼性を担保します。

## 手順

### 1. dbtソースの定義 (`src_mhealth.yml`)

`data_flow_dbt/models/src_mhealth.yml` を開き、`stage_raw_activities` テーブルをソースとして定義します。
カラムのデータ型や説明、基本的なテスト（`not_null`, `unique`）を追加してください。

**想定される `src_mhealth.yml` の内容:**
```yaml
version: 2

sources:
  - name: mhealth_raw
    # dbt_project.ymlのprofile設定に応じてAthenaのデータベース・スキーマ名を指定
    database: "{{ env_var('ATHENA_DATABASE') }}"
    schema: "{{ env_var('ATHENA_SCHEMA') }}"
    tables:
      - name: stage_raw_activities
        description: "ウェアラブルセンサから収集した10名の被験者の12種類の日常動作データ"
        columns:
          - name: subject_id
            description: "被験者ID"
            tests:
              - not_null
          - name: activity_id
            description: "活動ID"
            tests:
              - not_null
          - name: timestamp
            description: "タイムスタンプ"
            tests:
              - not_null
          # センサーデータのカラム定義は実際のテーブルに合わせて追加する
          - name: acc_chest_x
          - name: acc_chest_y
          - name: acc_chest_z
          - name: ecg_lead_1
          - name: ecg_lead_2
          - name: acc_left_ankle_x
          - name: acc_left_ankle_y
          - name: acc_left_ankle_z
          - name: gyro_left_ankle_x
          - name: gyro_left_ankle_y
          - name: gyro_left_ankle_z
          - name: mag_left_ankle_x
          - name: mag_left_ankle_y
          - name: mag_left_ankle_z
          - name: acc_right_wrist_x
          - name: acc_right_wrist_y
          - name: acc_right_wrist_z
          - name: gyro_right_wrist_x
          - name: gyro_right_wrist_y
          - name: gyro_right_wrist_z
          - name: mag_right_wrist_x
          - name: mag_right_wrist_y
          - name: mag_right_wrist_z
          - name: label
            description: "活動ラベル (0:不明, 1:立位, 2:座位, ...)"

```

### 2. データ品質確認用のdbtモデル作成

ソースデータを直接参照し、品質確認を行うための中間モデル（stagingモデル）を作成します。

- **ファイルパス:** `data_flow_dbt/models/staging/stg_mhealth_raw_activities.sql`
- **内容:**
  - `source`関数を使って `stage_raw_activities` を参照します。
  - カラム名の変更（スネークケースへの統一など）や、基本的なデータ型のキャストを行います。

**`stg_mhealth_raw_activities.sql` の作成を指示してください。**

### 3. dbtの実行と確認

以下のコマンドを実行し、モデルが正しく構築されることを確認します。

```bash
dbt run --select stg_mhealth_raw_activities
dbt test --select stg_mhealth_raw_activities
```

## 成果物

- 更新された `data_flow_dbt/models/src_mhealth.yml`
- 新規作成された `data_flow_dbt/models/staging/stg_mhealth_raw_activities.sql`
- 上記モデルのdbt実行が成功したログ
