# 複数ブランチの並列開発ガイド（git worktree）

本ドキュメントは、Spec Kit で作成した以下の2つの要件を、同一リポジトリから並列に実装・検証するための git worktree 運用手順をまとめたものです。

- 対象スペック: `specs/107-ml-gridsearch-automation`
- 対象スペック: `specs/108-mlops-devops-structure`

配置場所について: 運用手順であるため、`ai-doc/operations/` が適切です（本ファイル）。

## 前提
- 既存のクローンが1つある（例: `~/dev/data-flow`）
- `main` の最新を取り込める状態
- ブランチ命名例:
  - `feature/107-ml-gridsearch-automation`
  - `feature/108-mlops-devops-structure`

## 初期確認（ベースリポ側で実行）
```bash
cd ~/dev/data-flow
git status
git fetch --all --prune
git switch main
git pull --ff-only
```

## 作業ブランチを用意（新規作成する場合）
既存ならスキップ。新規作成例:
```bash
# 107 用
git switch -c feature/107-ml-gridsearch-automation
git push -u origin feature/107-ml-gridsearch-automation

# 108 用
git switch -c feature/108-mlops-devops-structure
git push -u origin feature/108-mlops-devops-structure

# 作成後は main に戻す
git switch main
```

## worktree の作成（別ディレクトリに同時チェックアウト）
物理ディレクトリ（各々が独立したワークスペース）を用意します。
```bash
# 107 用
git worktree add ../ws-107-gridsearch feature/107-ml-gridsearch-automation

# 108 用
git worktree add ../ws-108-mlops-devops feature/108-mlops-devops-structure

# 作成結果の確認
git worktree list
```
出力に3つ（`main`, `../ws-107-gridsearch`, `../ws-108-mlops-devops`）が載ればOK。

## VS Code/実行環境の起動
各ワークツリーを別ウィンドウで開くと混線しません。
```bash
code ../ws-107-gridsearch
code ../ws-108-mlops-devops
```

## 並列開発の進め方（各ワークツリーで独立して作業）

107 側（`../ws-107-gridsearch`）
```bash
cd ../ws-107-gridsearch
# 仕様/計画を確認
ls specs/107-ml-gridsearch-automation
# 変更 → コミット → プッシュ
git add -A
git commit -m "feat(107): implement grid search automation"
git push
```

108 側（`../ws-108-mlops-devops`）
```bash
cd ../ws-108-mlops-devops
ls specs/108-mlops-devops-structure
git add -A
git commit -m "feat(108): establish mlops/devops structure"
git push
```

## Spec Kit を使う場合（任意）
Spec Kit を各ワークツリーで個別に実行できます（生成物は `specs/` 配下に保存）。インストール・使い方は `ai-doc/tips/install-spec-kit.md` を参照。
```bash
# 例: 107 側で追補の計画・タスク生成
uvx --from git+https://github.com/github/spec-kit.git specify run /plan "107の詳細設計"
uvx --from git+https://github.com/github/spec-kit.git specify run /tasks "107の実装タスク洗い出し"
```

## PR 作成と CI
- それぞれのブランチから GitHub 上で PR を作成（`main` 向け）。
- CI は PR 単位で並列に実行可能です。
- 既存の自動化（`ai-doc/operations/workflow-usage.md`）と併用可能。

## main の更新を各ブランチに取り込む（定期）
```bash
# ベースリポ（~/dev/data-flow）で最新化
cd ~/dev/data-flow
git fetch --all --prune
git switch main
git pull --ff-only

# 107 側に取り込み（rebase 推奨）
cd ../ws-107-gridsearch
git fetch --all --prune
git rebase origin/main
# 競合解消後
git push --force-with-lease

# 108 側も同様
cd ../ws-108-mlops-devops
git fetch --all --prune
git rebase origin/main
git push --force-with-lease
```

## クリーンアップ（不要になったら削除）
```bash
# 中で作業中でないことを確認してから
git worktree remove ../ws-107-gridsearch
git worktree remove ../ws-108-mlops-devops
# 参照が残った場合
git worktree prune
```

## よくある落とし穴と対策
- 同じファイルを両ブランチで大幅変更 → 競合増。ディレクトリ分離や Feature flag で並走を許容。
- 片方だけフォーマッタ実行で大量差分 → 衝突増。`pre-commit` を両ワークツリーに設定して揃える。
- IDE の一時ファイル衝突 → 各ワークツリーの `./.git/info/exclude` にローカル無視設定。
  - 例: `echo ".venv/" >> .git/info/exclude`
- ワークツリーごとに設定を変えたい → `git config --worktree` を活用。
  - 例: `git config --worktree core.autocrlf input`
- サブモジュールがある → 各ワークツリーで個別に `git submodule update --init --recursive`
- ブランチ削除済みなのに worktree が残る → `worktree remove` → `prune` の順で掃除（強制削除は避ける）。

## 応用フラグ
- 追跡ブランチを新規作成して同時に worktree を張る:
```bash
git worktree add -b feature/109-sample ../ws-109-sample origin/main
```
- 既存ブランチを強制で張り替え（注意して使用）:
```bash
git worktree add --force ../ws-107-gridsearch feature/107-ml-gridsearch-automation
```

## 運用ミニガイド
- ルート（`~/dev/data-flow`）は `main` 専用にし、作業は原則 worktree 側で実施。
- ブランチ命名はスペック番号で統一（例: `feature/107-...`, `feature/108-...`）。
- CI は `paths` フィルタで無駄を省く（例: `specs/107/**` 変更のみで 107 ジョブを実行）。
- CODEOWNERS で領域オーナーを明確化し、跨り変更のレビューを強制。

> 参考: Spec Kit の導入メモは `ai-doc/tips/install-spec-kit.md`、自動 PR ワークフローは `ai-doc/operations/workflow-usage.md` を参照。

