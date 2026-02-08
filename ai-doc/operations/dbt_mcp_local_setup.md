# dbt MCP ローカル導入 指示書（PoC / VS Code + Codex + Gemini）

## 目的
- VS Code 上の AI エージェント（Codex / Gemini）から dbt を操作できるようにする。
- モデル生成・修正・テスト・build までを AI 主導で行えるようにする。
- まずは開発環境（dev）限定で PoC 実施。

## 方針（PoC 前提）
- MCP サーバーはローカル起動。
- dbt 実行は許可（dev のみ）。
- 本番ターゲットは禁止。
- full-refresh / 大規模 backfill は禁止。
- 実行前に必ずコマンド提示 → 人間承認。

## 成果物
- dbt MCP が VS Code から利用可能。
- AI が以下を実行可能。
  - `dbt ls`
  - `dbt compile`
  - `dbt test`
  - `dbt build`
- 実行ログをローカル保存。
- MCP 停止・権限剥奪手順を明文化。

## 1. 前提条件
### 必須
- VS Code インストール済。
- Codex / Gemini Code Assist 有効化済。
- Python / uv / uvx がローカルで使える。
- dbt Core が動作すること。
- dev 用 `profiles.yml` が設定済。

### 確認コマンド
macOS / Linux:
```
which dbt
dbt --version
```

Windows:
```
where dbt
dbt --version
```

## 2. 決めるべき変数（必須）
以下を埋める：

| 項目 | 値 |
| --- | --- |
| `DBT_PROJECT_DIR` | `/absolute/path/to/dbt-project` |
| `DBT_PATH` | `/absolute/path/to/dbt` |
| 実行ターゲット | `dev` |
| CLI タイムアウト | `120` 秒 |

## 3. dbt MCP サーバー起動設定
### 3.1 基本構成
- MCP サーバーは `uvx` 経由で起動する。
- 起動時に以下を環境変数として渡す：
  - `DBT_PROJECT_DIR`
  - `DBT_PATH`
  - `DBT_CLI_TIMEOUT`

### 3.2 MCP 設定（共通フォーマット）
VS Code / Gemini の MCP 設定に以下を登録。
```
{
  "mcpServers": {
    "dbt": {
      "command": "uvx",
      "args": ["dbt-mcp"],
      "env": {
        "DBT_PROJECT_DIR": "/absolute/path/to/dbt-project",
        "DBT_PATH": "/absolute/path/to/dbt",
        "DBT_CLI_TIMEOUT": "120"
      }
    }
  }
}
```

## 4. VS Code 側設定
### 4.1 Codex 用
- VS Code の MCP 設定ファイルに上記 JSON を追加。
- MCP サーバー一覧に `dbt` が表示されること。

### 4.2 Gemini Code Assist 用
`~/.gemini/settings.json` に追記：
```
{
  "mcpServers": {
    "dbt": {
      "command": "uvx",
      "args": ["dbt-mcp"],
      "env": {
        "DBT_PROJECT_DIR": "/absolute/path/to/dbt-project",
        "DBT_PATH": "/absolute/path/to/dbt",
        "DBT_CLI_TIMEOUT": "120"
      }
    }
  }
}
```

VS Code を再起動。

## 5. PoC ガードレール（必須）
### AI に課すルール
- 実行前に必ずコマンド全文を表示。
- `--select` 未指定の `run`/`build` は禁止。
- `--full-refresh` 禁止。
- `target=prod` 禁止。
- 失敗時はログ要約 → 修正案提示 → 再実行は承認必須。

### 推奨チェックテンプレ（AI に渡す）
実行前チェック:
- コマンド:
- ターゲット:
- 対象モデル:
- full-refresh 有無:
- 影響範囲:
→ OK なら「実行して」と明示されてから走らせる

## 6. 動作確認
AI に以下を指示：
- dbt プロジェクトのモデル一覧を取得して。
- `models/my_model.sql` を修正し、`dbt test --select my_model` を実行。
- `dbt build --select my_model` を実行。

成功すれば PoC 完了。

## 7. ログ管理
### 保存対象
- dbt CLI 出力
- 実行コマンド
- 実行時刻
- 対象ターゲット

### 保存場所（例）
- `~/.dbt/logs/`
- `repo_root/logs/dbt-mcp/`

## 8. 停止・ロールバック手順
### MCP 停止
- VS Code の MCP 設定から `dbt` を削除。
- `uvx` プロセス停止。

### 権限剥奪
- `profiles.yml` の dev 資格情報削除。
- SSO セッション破棄。

## 9. PoC 成功基準
- AI が `dbt build` / `dbt test` を実行できる。
- dev 環境のみ使用。
- 危険操作は弾かれる。
- ログが残る。
