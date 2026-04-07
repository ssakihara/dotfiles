# Claude Code 設定

## IMPORTANT: エージェント選択ルール

rules/agents.md のエージェント選択ルールに必ず従うこと。
コードレビュー依頼やコード変更後は**必ず** code-reviewer エージェントを実行すること。

## ファイル命名規則

TypeScript・Vueで新規ファイルを作成する場合、ファイル名は**必ずケバブケース**（例: `my-component.ts`, `user-service.ts`, `app-header.vue`）で命名すること。
キャメルケースやスネークケースは使用しないこと。

## コメント

- **なぜその実装（処理）が必要なのか（Why）**を必ずコメントで残すこと。「何をしているか（What）」や「どう実装しているか（How）」ではなく、その処理が存在する理由・背景を書くこと。
- 見てわかるレベルの実装内容へのコメントは任意（不要なら書かない）。
- 複雑な処理についてのコメントも任意。

## 検証

作業完了時、テスト実行・スクリーンショット・検証コマンドなど検証方法を必ず提供すること。

## IMPORTANT: ナレッジ管理 (Obsidian CLI)

Claude Codeのメモリー機能はOFFにしている。代わりに `obsidian` コマンドを使ってObsidian Vaultにメモを保存・検索すること。
後続の実装メンバー（人間・AI問わず）が同じプロジェクトで作業する際に役立つ知見を積極的に残すこと。

### 必須: タスク開始時の検索

タスクに着手する前に、**必ず**関連する既存メモを検索すること。

```bash
# プロジェクト名・技術スタック・機能名などで検索
obsidian search query="検索キーワード"
obsidian search:context query="検索キーワード"
```

過去の設計判断・ハマりポイント・ユーザーの好みなどが見つかれば、それを踏まえて作業すること。

### 必須: メモを書くタイミング

以下のタイミングで**必ず**メモを作成・追記すること。「迷ったら書く」を原則とする。

| タイミング | 記録内容 | 例 |
|---|---|---|
| **設計判断時** | 選択肢・採用理由・却下理由 | 「状態管理にPiniaを採用。Vuexは非推奨のため却下」 |
| **ハマりポイント解決時** | 問題・原因・解決策 | 「Nuxt useFetchはSSR時にcookieを自動転送しない→useRequestHeadersで明示的に渡す」 |
| **ユーザーの好み・方針を聞いた時** | 好み・方針の内容 | 「エラーハンドリングはResult型パターンを好む」 |
| **環境・インフラの知見** | 設定値・手順・注意点 | 「本番DBはCloud SQL、接続にはCloud SQL Proxyが必要」 |
| **外部API・ライブラリの癖** | 挙動・制約・ワークアラウンド | 「Stripe WebhookはContent-Type: application/jsonでないと署名検証が失敗する」 |
| **タスク完了時** | 実装概要・変更点・残課題 | 「認証フローをJWT→セッションに変更。リフレッシュトークンは未実装」 |

### メモのフォーマット

```bash
# プロジェクト知見の作成（ノート名にプロジェクト名を含める）
obsidian create name="プロジェクト名/トピック名" content="$(cat <<'EOF'
## 概要
何についてのメモか

## 詳細
- 具体的な内容
- 判断理由や背景

## 関連
- 関連ファイル: `path/to/file.ts`
- 関連イシュー: #123

#プロジェクト名 #カテゴリタグ
EOF
)"

# 既存ノートへの追記（知見が増えた場合）
obsidian append file="プロジェクト名/トピック名" content="$(cat <<'EOF'

## 追記 (YYYY-MM-DD)
新たに判明した内容
EOF
)"

# デイリーノートへの作業ログ
obsidian daily:append content="- プロジェクト名: 作業内容の要約"
```

### タグ規約

メモには以下のタグを付けて検索性を高めること:

- `#design-decision` — 設計判断
- `#troubleshooting` — ハマりポイント・トラブルシュート
- `#user-preference` — ユーザーの好み・方針
- `#environment` — 環境・インフラ情報
- `#api-quirk` — 外部API・ライブラリの癖
- `#project/プロジェクト名` — プロジェクト識別

### よく使うコマンド

```bash
# ノートの作成
obsidian create name="ノート名" content="内容"

# ノートの読み取り
obsidian read file="ノート名"

# ノートへの追記
obsidian append file="ノート名" content="追記内容"

# ノートの先頭に追記
obsidian prepend file="ノート名" content="追記内容"

# Vault内検索
obsidian search query="検索キーワード"

# コンテキスト付き検索
obsidian search:context query="検索キーワード"

# デイリーノートへの追記
obsidian daily:append content="メモ内容"

# デイリーノートの読み取り
obsidian daily:read

# タグ一覧
obsidian tags

# プロパティの設定
obsidian property:set file="ノート名" name="key" value="value"
```

### 特定のVaultを指定する場合

```bash
obsidian <command> vault="Vault名"
```
