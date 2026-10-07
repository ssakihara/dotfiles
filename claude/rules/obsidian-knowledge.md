# ナレッジ管理 (Obsidian CLI)

Claude Codeのメモリー機能はOFFにしている。代わりに `obsidian` コマンドを使ってObsidian Vaultにメモを保存・検索すること。
このVaultはチームのナレッジベースである。
後続メンバー（人間・AI問わず）が同じ調査を繰り返さずに済むよう、再利用価値のある知見を残すこと。

## タスク開始時の検索

タスクに着手する前に、関連する既存メモを検索する。

```bash
obsidian search query="検索キーワード"
obsidian search:context query="検索キーワード"
```

## メモを書くタイミング

設計判断・ハマりポイント解決・ユーザーの好み検知・環境の知見・タスク完了時・タスク中断時など、再利用価値のある情報を書くこと。

タイミングの詳細一覧・セルフチェックリストは ~/.claude/references/obsidian-knowledge-detail.md を参照

## ノートフォーマット

すべてのノートに YAML フロントマター（`type` / `status` / `project` / `date` / `summary`）を付けること。
本文は結論を先頭に書き（逆ピラミッド）、種別ごとのテンプレートに従うこと。

- `type` は `design-decision`（ADR形式） / `troubleshooting` / `runbook` / `til` / `handover` の5種別
- `summary` は結論1行。検索結果からノートを判別するために必須
- 知見が無効になったと気づいたら `status` を `outdated` / `superseded` に更新する

フロントマターの詳細・種別ごとのセクション構成・タグ規約は ~/.claude/references/obsidian-knowledge-detail.md を参照

## ディレクトリ構造

ノートは Vault 直下ではなく `プロジェクト名/` または `general/` ディレクトリ配下に作成する。

`obsidian create` の `name` パラメータにスラッシュを含めるとパースに失敗し、`Untitled` で作成される。
ディレクトリ付きノートは `path` パラメータで作成し、`.md` 拡張子を付ける。

`path` は `ディレクトリ名/ノート名.md` の1階層のみとする（スラッシュはちょうど1つ）。
ノート名は英語の kebab-case、ノートの内容（content）は日本語で書く。

- ✅ `path="my-web-app/api-design.md"`
- ✅ `path="general/docker-tips.md"`
- ❌ `name="project-a/api-design"` ← nameにスラッシュを含めるとUntitledになる
- ❌ `path="my-web-app/設計メモ.md"` ← 日本語のノート名は禁止
- ❌ `path="設計メモ.md"` ← ディレクトリ指定がない

プロジェクト名の判定:
1. git 管理下では**リポジトリ名**を使用する。
   `basename -s .git "$(git remote get-url origin)"` で判定する（worktree や clone 先のディレクトリ名に依存させない。SSH / HTTPS どちらのURL形式でも動作する）。
2. リモート未設定の場合はメインワークツリーのディレクトリ名を使用する。
   `basename "$(git worktree list --porcelain | head -1 | sed 's/^worktree //')"` で取得する。
3. git 管理外の場合は作業ディレクトリ名を使用する。
4. プロジェクト横断的な知見は `general/` を使用する。
