# Plan for Issue #27: Implement Test-Driven Workflow for Data Quality Feature

## 1. 概要（目的）

この計画は、Issue #27で定義されたテスト駆動開発（TDD）ワークフローを実践するための最初のタスクです。
具体的な機能として、`convert_log_to_parquet.py`スクリプトにデータ品質チェック機能を追加します。
これにより、データパイプラインの堅牢性を高め、後続の分析処理で利用されるデータの信頼性を向上させます。

## 2. 実装対象機能

- **データ品質検証ロジックの追加**:
  - `convert_log_to_parquet.py`に、入力されるJSONログレコードを検証する関数を追加します。
- **具体的なチェック項目**:
  1.  **必須カラムの存在**: `timestamp`, `user_id`, `activity_type` の3つのキーが存在するかを確認します。
  2.  **タイムスタンプの形式**: `timestamp` の値が `YYYY-MM-DDTHH:MM:SSZ` 形式（ISO 8601）であることを検証します。
  3.  **アクティビティ種別の妥当性**: `activity_type` の値が、事前に定義された許容リスト（例: `login`, `logout`, `purchase`, `view_page`）に含まれていることを確認します。
- **エラーハンドリング**:
  - 品質チェックに失敗したレコードは処理対象から除外します。
  - 失敗したレコードとその理由は、WARNINGレベルでログに出力します。

## 3. 必要なモジュール・ファイル構造

- **実装コード**:
  - `convert_log_to_parquet/convert_log_to_parquet.py`: データ品質チェック関数と、それを呼び出すロジックを追記します。

- **テストコード (Pytest)**:
  - `tests/pytest/issue-27/test_data_quality.py`:
    - 品質チェック関数のための単体テストを実装します。
    - このテストは、実装コードが書かれるまでは失敗します。

- **テストコード (dbt test)**:
  - `tests/dbt/issue-27/schema.yml`:
    - `convert_log_to_parquet`の処理結果であるParquetデータ（dbtからテーブルとして参照）に対するテストを定義します。
    - このテストは、品質チェック機能が実装され、不正なデータがフィルタリングされるまでは失敗する可能性があります。

## 4. 想定される入出力

- **入力 (Input)**:
  - JSON形式のログデータを含むファイル。
  - **正常系レコードの例**:
    ```json
    {"timestamp": "2025-07-28T10:00:00Z", "user_id": "user123", "activity_type": "login"}
    ```
  - **異常系レコードの例**:
    ```json
    {"timestamp": "2025-07-28 10:00:00", "user_id": "user456", "activity_type": "login"}
    ```
    ```json
    {"timestamp": "2025-07-28T11:00:00Z", "activity_type": "purchase"}
    ```
    ```json
    {"timestamp": "2025-07-28T12:00:00Z", "user_id": "user789", "activity_type": "submit_form"}
    ```

- **出力 (Output)**:
  - 品質チェックを通過したレコードのみからなるParquetファイル。
  - 標準エラー出力へのログ（`logging`モジュール経由）。
  - **ログ出力の例**:
    ```
    WARNING:root:Data quality check failed for record: {'timestamp': '2025-07-28 10:00:00', ...}. Reason: Invalid timestamp format.
    WARNING:root:Data quality check failed for record: {'timestamp': '2025-07-28T11:00:00Z', ...}. Reason: Missing required key: user_id.
    WARNING:root:Data quality check failed for record: {'timestamp': '2025-07-28T12:00:00Z', ...}. Reason: Invalid activity_type: submit_form.
    ```

## 5. テスト観点一覧

### Pytest (`tests/pytest/issue-27/test_data_quality.py`)

- **正常系**:
  - [ ] `test_valid_record`: すべてのチェック項目を満たすレコードが検証をパスすること。
- **異常系**:
  - [ ] `test_missing_required_key`: 必須キー (`user_id`など) が欠損しているレコードが検証に失敗すること。
  - [ ] `test_invalid_timestamp_format`: `timestamp`のフォーマットが不正なレコードが検証に失敗すること。
  - [ ] `test_invalid_activity_type`: `activity_type`が許容リストにない値のレコードが検証に失敗すること。
  - [ ] `test_empty_record`: 空のJSONオブジェクト `{}` が検証に失敗すること。
- **境界値**:
  - [ ] `test_null_values`: 必須キーの値が `null` の場合に検証に失敗すること。

### dbt test (`tests/dbt/issue-27/schema.yml`)

- **対象モデル**: `cleaned_activities` (仮定)
- **テスト定義**:
  - [ ] `user_id` カラムに `not_null` 制約を定義。
  - [ ] `timestamp` カラムに `not_null` 制約を定義。
  - [ ] `activity_type` カラムに `accepted_values` を定義し、許容リストと一致することを確認。

---

## テストファイルのパス一覧

- `/home/runner/work/data-flow/data-flow/tests/pytest/issue-27/test_data_quality.py`
- `/home/runner/work/data-flow/data-flow/tests/dbt/issue-27/schema.yml`
