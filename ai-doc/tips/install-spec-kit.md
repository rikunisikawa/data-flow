✅ 前提条件

Python 3.11+ がインストール済み

uv（Pythonの次世代パッケージ管理ツール）をインストール済み

curl -LsSf https://astral.sh/uv/install.sh | sh


Gemini CLI が導入されている
（Google AI Studio で API Key を発行し、gemini config set api_key <YOUR_API_KEY> 済み）

🚀 導入手順（Gemini向け）
1. プロジェクトを初期化

任意のフォルダで以下を実行します。

# 新規ディレクトリを作って初期化
uvx --from git+https://github.com/github/spec-kit.git specify init --ai gemini my-spec-kit-project
cd my-spec-kit-project


既存リポジトリで使いたい場合は --here をつけます：

uvx --from git+https://github.com/github/spec-kit.git specify init --here --ai gemini


👉 実行すると以下のようなディレクトリが自動生成されます：

my-spec-kit-project/
  ├─ memory/      # 仕様や履歴を保存
  ├─ scripts/     # CLIスクリプト群
  ├─ templates/   # spec/plan/tasks の雛形

2. Gemini と連携確認

Gemini CLI が動作するかテストします：

gemini chat


（ここで普通に会話できればOK）

Spec Kit は Gemini CLI に slash コマンドを追加する形ではなく、specify CLI が Gemini API を叩いて仕様作成を補助する形です。

3. 仕様作成の開始

初期化後、以下を実行して仕様を生成します：

uvx --from git+https://github.com/github/spec-kit.git specify run /specify "○○なアプリを作りたい。主なユーザーは..."


生成物は specs/001-<project-name>/spec.md に保存されます

必要に応じて Gemini が [NEEDS CLARIFICATION] を付与するので、それを埋めていく流れになります

4. 実装計画とタスク分解
# 技術スタックや制約を明記
uvx --from git+https://github.com/github/spec-kit.git specify run /plan "Next.jsとPostgreSQLを使いたい"

# タスク化
uvx --from git+https://github.com/github/spec-kit.git specify run /tasks "実装タスクを洗い出して"

5. 開発フローの実践

/specify → 仕様ドラフト

/plan → 技術スタック・設計方針

/tasks → タスク化・実装開始

Gemini CLI と GitHub Actions などを組み合わせて、自動ブランチ作成・PR化も可能

📌 ポイント

Gemini CLI 単体では “/specify” などのコマンドは無い → Spec Kit の specify CLI がその部分を担います

AIエージェントを gemini に指定することで、Copilot や Claude の代わりに Gemini を利用できます

生成物（仕様・計画・タスク）は全てファイル化される → GitHub リポジトリで管理可能

👉 この流れで、Geminiをバックエンドにして Spec Kit を導入できます。


log

riku_nishikawa@TABLET-75V7LCN2:~/dev/data-flow$ curl -LsSf https://astral.sh/uv/install.sh | sh
downloading uv 0.8.15 x86_64-unknown-linux-gnu
no checksums to verify
installing to /home/riku_nishikawa/.local/bin
  uv
  uvx
everything's installed!

riku_nishikawa@TABLET-75V7LCN2:~/dev/data-flow$ uvx --from git+https://github.com/github/spec-kit.git specify init --here --ai gemini
    Updated https://github.com/github/spec-kit.git (7176d2
      Built specify-cli @ git+https://github.com/github/sp
Installed 18 packages in 80ms
 ███████╗██████╗ ███████╗ ██████╗██╗███████╗██╗   ██╗ 
 ██╔════╝██╔══██╗██╔════╝██╔════╝██║██╔════╝╚██╗ ██╔╝ 
 ███████╗██████╔╝█████╗  ██║     ██║█████╗   ╚████╔╝  
 ╚════██║██╔═══╝ ██╔══╝  ██║     ██║██╔══╝    ╚██╔╝   
 ███████║██║     ███████╗╚██████╗██║██║        ██║    
 ╚══════╝╚═╝     ╚══════╝ ╚═════╝╚═╝╚═╝        ╚═╝    
                                                      
           Spec-Driven Development Toolkit            

Warning: Current directory is not empty (31 items)
Template files will be merged with existing content 
and may overwrite existing files
Do you want to continue? [y/N]:         y
╭──────────────────────────────────────────────╮
│ Specify Project Setup                        │
│ Initializing in current directory: data-flow │
│ Path: /home/riku_nishikawa/dev/data-flow     │
╰──────────────────────────────────────────────╯
Initialize Specify Project
├── ● Check required tools (ok)
├── ● Select AI assistant (gemini)
├── ● Fetch latest release (release v0.0.14 (22,728 
│   bytes))
├── ● Download template 
│   (spec-kit-template-gemini-v0.0.14.zip)
├── ● Extract template
├── ● Archive contents (20 entries)
├── ● Extraction summary (temp 4 items)
├── ● Cleanup
├── ● Initialize git repository (existing repo 
│   detected)
└── ● Finalize (project ready)

Project ready.




uvx --from git+https://github.com/github/spec-kit.git specify run /specify "このデータ基盤におけるテストを実装する"
uvx --from git+https://github.com/github/spec-kit.git specify run /plan "技術スタック..."
uvx --from git+https://github.com/github/spec-kit.git specify run /tasks "タスク分解..."

