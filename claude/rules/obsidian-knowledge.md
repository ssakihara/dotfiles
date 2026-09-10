# ナレッジ管理 (Obsidian CLI)

Claude Codeのメモリー機能はOFFにしている。代わりに `obsidian` コマンドを使ってObsidian Vaultにメモを保存・検索すること。
このVaultはチームのナレッジベースである。**「書かない理由がない限り書く」**を大原則とし、後続メンバー（人間・AI問わず）に知見を残すこと。

## 必須: タスク開始時の検索

タスクに着手する前に、**必ず**関連する既存メモを検索すること。

```bash
obsidian search query="検索キーワード"
obsidian search:context query="検索キーワード"
```

## 必須: メモを書くタイミング

設計判断・ハマりポイント解決・ユーザーの好み検知・環境の知見・タスク完了時・タスク中断時など、再利用価値のある情報は**すべて書く**こと。

タイミングの詳細一覧・セルフチェックリストは references/obsidian-knowledge-detail.md を参照

## 必須: ノートフォーマット

すべてのノートに YAML フロントマター（`type` / `status` / `project` / `date` / `summary`）を付けること。
本文は結論を先頭に書き（逆ピラミッド）、種別ごとのテンプレートに従うこと。

- `type` は `design-decision`（ADR形式） / `troubleshooting` / `runbook` / `til` / `handover` の5種別
- `summary` は結論1行。検索結果からノートを判別するために必須
- 知見が無効になったと気づいたら `status` を `outdated` / `superseded` に更新する

フロントマターの詳細・種別ごとのセクション構成・タグ規約は references/obsidian-knowledge-detail.md を参照

## IMPORTANT: ディレクトリ構造

**Vault直下にノートを作成することは禁止。** 必ず `プロジェクト名/` または `general/` ディレクトリ配下に作成すること。

**IMPORTANT: `obsidian create` では `name` パラメータにスラッシュを含めることができない。** スラッシュを含めるとパース失敗し `Untitled` で作成されてしまう。
ディレクトリ付きノートの作成には必ず **`path` パラメータ**を使い、**`.md` 拡張子を付ける**こと。

pathパラメータは必ず `ディレクトリ名/ノート名.md` の**1階層のみ**とすること（スラッシュはちょうど1つ）。
**ノート名は英語・kebab-caseで命名すること。** ノートの内容（content）は日本語で記述する。

- ✅ `path="payment-notification-service/api-design.md"`
- ✅ `path="general/docker-tips.md"`
- ❌ `name="project-a/api-design"` ← nameにスラッシュを含めるとUntitledになる
- ❌ `path="payment-notification-service/設計メモ.md"` ← 日本語のノート名は禁止
- ❌ `path="設計メモ.md"` ← ディレクトリ指定がない

プロジェクト名の判定:
1. git 管理下では**リポジトリ名**を使用する。
   `basename -s .git "$(git remote get-url origin)"` で判定する（worktree や clone 先のディレクトリ名に依存させない。SSH / HTTPS どちらのURL形式でも動作する）。
2. リモート未設定の場合はメインワークツリーのディレクトリ名を使用する。
   `basename "$(git worktree list --porcelain | head -1 | sed 's/^worktree //')"` で取得する。
3. git 管理外の場合は作業ディレクトリ名を使用する。
4. プロジェクト横断的な知見は `general/` を使用する。
