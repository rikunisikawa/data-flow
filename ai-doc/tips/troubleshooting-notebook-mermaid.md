## Notebook/Mermaid トラブルシュート集（開発者・AI向け）

このドキュメントは、本プロジェクトで発生しやすい Jupyter Notebook（.ipynb）と Mermaid 図の構文エラーをまとめ、再発時に迅速に対処できるようにするためのメモです。AI（エージェント）が参照する前提の実務指針も含みます。

---

### 1) Mermaid の構文エラー（例）

発生例1（サブグラフ名に記号を含めたケース）
- Error: Parse error: Expecting '... got PS'
- 原因: `subgraph Staging(ETL: Log -> Parquet)` のように `()` や `->`, `/` を含むとパースが崩れることがある。
- 対処: サブグラフ名は英数字とアンダースコアのみにする。
  - 例: `subgraph Staging_ETL_Log_to_Parquet`

発生例2（ノードラベル内の改行・括弧）
- Error: Parse error on line N ... Expecting '... got PS'
- 原因:
  - ノードラベル内の実改行（`\n`）が Mermaid のブロック内で解釈に失敗することがある。
  - `()` を含む文字列が形状指定（例: `([text])`）と衝突する場合がある。
- 対処:
  - ラベル改行は `<br/>` を使用（`\n` を避ける）。
  - 括弧・記号（`()`, `[]`, `<>`, `->`, `/` など）は極力避け、必要なら別の語に置き換える。
  - 例: `schema validate (24 cols)` → `schema validate 24 cols`

発生例3（二つ目の図でも同様の失敗）
- Error: Parse error on line 2 ... Expecting '... got PS'
- 原因: `RAW[stage_mhealth.raw_activities (Glue)]` のように括弧を含む。
- 対処: 括弧を除去し単語にする。
  - 例: `RAW[stage_mhealth.raw_activities Glue]`

参考実装（修正済みの図）
- `ai-doc/infra/etl_flow.md`

---

### 2) Jupyter Notebook（.ipynb）の構文エラー

発生例（JSON パースエラー）
- Error: `JSON parse error: Extra data: line X column Y (char Z)`
- 原因: `.ipynb` が単一の JSON オブジェクトである必要があるのに、2つの JSON が連結されている等の破損状態（手動編集や自動生成時の衝突で発生）。

対処方針（AI/開発者共通）
- 破損が疑われる場合は、該当ノートを一度削除し、正しい JSON を再生成する（apply_patch で Add File し直す）。
- 最小構成を満たすキーを必ず含める：
  - `nbformat`, `nbformat_minor`
  - `metadata.kernelspec`（`name`, `language`, `display_name`）
  - `metadata.language_info`
  - `cells`（配列）
- VS Code 側の挙動:
  - 破損した状態でも開けるが、実行・表示が無反応になることがある。再生成後はファイルを閉じて再オープン、カーネルを選び直す。

運用 Tips
- VS Code のカーネルはローカル Python 環境（venv/conda）に依存。`ipykernel` が必要。
- analysis/requirements.txt で依存を管理（`pip install -r analysis/requirements.txt`）。
- 依存確認セル（例）:
  ```python
  import sys, importlib.util
  print(sys.version)
  for m in ["pandas","awswrangler","xgboost","sklearn","dotenv","ipykernel"]:
      print(m, "installed?", importlib.util.find_spec(m) is not None)
  ```

---

### 3) AI への指示テンプレ（再発時）

- Mermaid 失敗時:
  - 「サブグラフ名・ノードラベルから括弧や記号を除去し、改行は `<br/>` に置き換えて修正して」
  - 対象ファイル: `ai-doc/infra/etl_flow.md`

- Notebook 失敗時:
  - 「`analysis/themes/mhealth/eda/notebooks/01_eda_overview.ipynb` が壊れている可能性。単一 JSON オブジェクトに再生成して」
  - kernelspec と language_info を含めること、cells は配列で先頭に動作確認セルを置くこと。
