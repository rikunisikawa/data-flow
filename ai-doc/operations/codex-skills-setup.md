# Codex Skills セットアップ手順（VSCode/ローカル）

本ドキュメントは、Codex が `SKILL.md` を認識して利用できる状態にするための手順をまとめたものです。VSCode 側の確認ポイントと、ローカル環境で skills を配置・認識させる流れを記載します。

## 前提
- Codex を VSCode で利用していること。
- skills は `~/.codex/skills/` に配置される想定。
- このリポジトリには skills が `ai-agent-skilles/skills/` にある。

## 1. VSCode 側の確認ポイント
1. Codex の拡張機能が有効になっていることを確認する。
2. Codex の設定に `CODEX_HOME` もしくは skills の参照ディレクトリを指定する項目がある場合は、`~/.codex` を指していることを確認する。
3. VSCode の再起動またはウィンドウのリロードを行い、設定の反映を確実にする。

※ Codex の設定項目名は拡張機能のバージョンにより変わるため、具体名称は VSCode の設定画面から検索して確認する。

## 2. skills 配置（ローカル）
リポジトリ内の skills を `~/.codex/skills/` にコピーする。

```bash
mkdir -p ~/.codex/skills
cp -R ai-agent-skilles/skills/* ~/.codex/skills/
```

配置後、以下で確認する。

```bash
ls ~/.codex/skills
cat ~/.codex/skills/governing-mhealth-infra/SKILL.md
```

## 3. Codex が認識するまでの流れ
1. `~/.codex/skills/<skill>/SKILL.md` を配置する。
2. VSCode を再起動、または Codex セッションを新規作成する。
3. 依頼時に skill 名を明示する（例: `governing-mhealth-infra`）。
4. 依頼内容が skill の description と合致していれば Codex が適用する。

## 4. よくある確認事項
- `SKILL.md` が存在しない、またはファイル名が間違っている。
- `~/.codex/skills/` のディレクトリ階層が崩れている。
- VSCode のウィンドウを開き直しておらず、変更が反映されていない。

## 5. 本リポジトリでの運用方針
- skills の編集は `ai-agent-skilles/skills/` で行う。
- 配置は `~/.codex/skills/` にコピーする。
- 反映後は VSCode の再起動 or セッション再作成で確認する。
