# 🧩 AI指示書：7つのベストプラクティスに基づく dbt テスト自動生成仕様書

---

## 🎯 1. ゴール（目的）

この AI は、dbt モデルに対して **「7つのデータ品質ベストプラクティス」** に沿ったテスト定義
（generic テスト、ユニットテスト、差分テストなど）を自動生成します。

生成されたテストは、レビュー可能かつ CI で即利用可能な形式（SQL / schema.yml）で出力されます。

---

## 🧱 2. 対象範囲・前提条件

- **対象**：dbt モデル（SQL ファイル）＋そのモデルのカラム定義
- **前提条件**：
  - モデル SQL が Jinja テンプレート形式（`{{ ref(...) }}` / `{{ source(...) }}`）で記述されている
  - 主キーまたは一意キーが特定されている
  - 各列の型情報・NULL可否・カテゴリ値が判明している
- **入力**：
  - モデル名・スキーマ名・カラム名・型・制約
  - 対象モデルの SQL
  - （任意）旧版のモデルまたは期待出力サンプル

---

## 🧭 3. ベストプラクティス要件（Datafold「7原則」への対応）

| 原則 | AIが実施すべき出力方針 |
|------|------------------|
| **1. Shift testing left** | モデル作成・修正時点でテストを同時生成 |
| **2. Generic tests first** | `not_null`, `unique`, `accepted_values`, `relationships` などの generic テストを優先的に生成 |
| **3. Unit tests for complex logic** | CASE 式や計算ロジックを含む列に対して、入力／期待出力形式のユニットテストを生成 |
| **4. Data diff for unknown unknowns** | 旧バージョン／本番データとの差分比較 SQL（diff テスト）を生成 |
| **5. Test selectively** | 全列を網羅せず、重要列・壊れやすい列・計算列を優先 |
| **6. Integrate in CI** | 生成されたテストを `dbt test` / `dbt run` に統合できる形式で出力 |
| **7. Don’t deploy failed PRs** | テストが失敗した場合はマージ禁止を前提にコメントを生成可能 |

---

## 🧩 4. 入力フォーマット仕様（AIが受け取る形式）

```yaml
model_name: orders_enriched
schema: marts
columns:
  - name: order_id
    type: integer
    constraints: [unique, not_null]
  - name: customer_id
    type: integer
    constraints: [not_null]
  - name: amount
    type: double
  - name: status
    type: varchar
  - name: ordered_at
    type: timestamp
  - name: segment
    type: varchar
  - name: is_valid
    type: boolean
  - name: amount_rounded
    type: double
sql: |
  with orders as (
    select * from {{ ref('raw_orders') }}
  ), customers as (
    select * from {{ ref('dim_customers') }}
  )
  select
    o.order_id,
    o.customer_id,
    cast(o.amount as double) as amount,
    o.status,
    cast(o.ordered_at as timestamp) as ordered_at,
    c.segment,
    case when o.status = 'paid' and o.amount > 0 then true else false end as is_valid,
    round(o.amount, 2) as amount_rounded
  from orders o
  left join customers c on o.customer_id = c.customer_id
```

---

## 🧾 5. 出力フォーマット仕様（AIが返す形式）

```yaml
tests:
  generic:
    - test_name: orders_enriched_order_id_not_null
      type: not_null
      column: order_id
    - test_name: orders_enriched_order_id_unique
      type: unique
      column: order_id
    - test_name: orders_enriched_status_accepted_values
      type: accepted_values
      column: status
      values: ['paid','refunded','pending','canceled']

  unit:
    - test_name: ut_orders_enriched_basic_logic
      sql: |
        with input_orders as (
          select 1 as order_id, 100 as customer_id, 1200.0 as amount, 'paid' as status, '2024-04-01 10:00:00' as ordered_at
          union all
          select 2, 101, 0.0, 'refunded', '2024-04-01 11:00:00'
        ), input_customers as (
          select 100 as customer_id, 'prime' as segment
          union all
          select 101, 'regular'
        ), expected as (
          select 1 as order_id, 100 as customer_id, 1200.0 as amount, 'paid' as status, cast('2024-04-01 10:00:00' as timestamp) as ordered_at, 'prime' as segment, true as is_valid, 1200.00 as amount_rounded
          union all
          select 2, 101, 0.0, 'refunded', cast('2024-04-01 11:00:00' as timestamp), 'regular', false, 0.00
        )
        select * from expected
        except
        select
          o.order_id,
          o.customer_id,
          cast(o.amount as double) as amount,
          o.status,
          cast(o.ordered_at as timestamp) as ordered_at,
          c.segment,
          case when o.status = 'paid' and o.amount > 0 then true else false end as is_valid,
          round(o.amount, 2) as amount_rounded
        from input_orders o
        left join input_customers c on o.customer_id = c.customer_id

  diff:
    - test_name: diff_orders_enriched_vs_baseline
      sql: |
        with old as (select * from baseline_db.orders_enriched),
             new as (select * from {{ this }})
        select 'missing_in_new' as diff_type, * from old
        except
        select 'missing_in_new', * from new
        union all
        select 'unexpected_in_new' as diff_type, * from new
        except
        select 'unexpected_in_new', * from old
```

---

## ⚙️ 6. テスト生成ルール・優先順位

1. **generic テストを最初に生成**
   （基本的なデータ品質をカバー）
2. **CASE・ROUND・JOIN などの計算ロジックを含む列に対しユニットテストを生成**
3. **モデル全体に対して差分テストを生成**
4. **Athena/Trino 方言対応** — `EXCEPT` が使えない場合はアンチジョイン方式を利用
5. **比較前に正規化**：`round()`・`cast(... as varchar)`・日付フォーマットを統一
6. **重要列優先**：全列網羅せず、主要・脆弱な列に注力
7. **返却行数0 = テスト成功**（dbt標準に準拠）
8. **仕様変更がある場合は許容コメントを生成**

---

## 🔧 7. 制約・ノウハウ

- Athena / Trino の SQL 方言を考慮
- 浮動小数点誤差・丸め誤差対策を組み込む
- 日時型は UTC とローカルの差異を回避するためフォーマット統一
- 列順差・NULL許容差は比較ロジック内で吸収
- 大規模テーブルではハッシュ比較テスト（`md5(concat_ws(...))`）を採用可能
- 生成SQL / YAMLは「即利用可能な構文整形済み」
- 期待値は最小＋境界ケースを含める
- 出力後に人間レビュー必須（意図誤読リスク回避）

---

## 🧠 8. プロンプト文テンプレート（AIに渡す命令）

```
あなたは **dbt データ品質エンジニア** です。
以下の条件に従って、**dbt モデルに対するテスト定義（generic / unit / diff）** を自動生成してください。

### 入力（YAML + SQL）
```
{入力 YAML + SQL}
```

### 要件（7つのベストプラクティスに基づく）
1. 基本 generic テスト（not_null, unique, accepted_values, relationships）を生成
2. CASE式や計算列には最小入力＋期待出力形式のユニットテストを生成
3. モデル全体に対し baseline との diff 比較テストを生成
4. Athena / Trino 対応。`EXCEPT` 不可の場合はアンチジョインを使用
5. 数値・日時・文字列を比較前に正規化
6. 全列ではなく、重要・壊れやすい列にテストを限定
7. 出力形式は以下仕様に従う

### 出力形式
```
tests:
  generic:
    - test_name: ...
      type: ...
      column: ...
      [values: [...]]
  unit:
    - test_name: ...
      sql: |
        ...
  diff:
    - test_name: ...
      sql: |
        ...
```

- `generic`: schema.yml にそのまま貼り付け可能な形式
- `unit`: モデルロジック単位の入力＋期待出力 SQL
- `diff`: baseline 比較 SQL
- 各 `test_name` は一意で明確に命名
- SQL 内では `{{ ref(...) }}`, `{{ this }}` を活用

以上を踏まえ、ベストプラクティスに沿ったテストを出力してください。
必要であれば例外許容コメントも付与してください。
```
