# ナレッジ管理 (Obsidian CLI)

Claude Codeのメモリー機能はOFFにしている。代わりに `obsidian` コマンドを使ってObsidian Vaultにメモを保存・検索すること。
このVaultはチームのナレッジベースである。**「書かない理由がない限り書く」**を大原則とし、後続メンバー（人間・AI問わず）に知見を残すこと。

## 必須: タスク開始時の検索

タスクに着手する前に、**必ず**関連する既存メモを検索すること。

```bash
# プロジェクト名・技術スタック・機能名などで検索
obsidian search query="検索キーワード"
obsidian search:context query="検索キーワード"
```

過去の設計判断・ハマりポイント・ユーザーの好みなどが見つかれば、それを踏まえて作業すること。

## 必須: メモを書くタイミング

以下は最低限のトリガーであり、これに該当しなくても再利用価値のある情報は**すべて書く**こと。

| タイミング | 記録内容 | 例 |
|---|---|---|
| **設計判断時** | 選択肢・採用理由・却下理由 | 「状態管理にPiniaを採用。Vuexは非推奨のため却下」 |
| **ハマりポイント解決時** | 問題・原因・解決策 | 「Nuxt useFetchはSSR時にcookieを自動転送しない→useRequestHeadersで明示的に渡す」 |
| **ユーザーの好み・方針を聞いた時** | 好み・方針の内容 | 「エラーハンドリングはResult型パターンを好む」 |
| **環境・インフラの知見** | 設定値・手順・注意点 | 「本番DBはCloud SQL、接続にはCloud SQL Proxyが必要」 |
| **外部API・ライブラリの癖** | 挙動・制約・ワークアラウンド | 「Stripe WebhookはContent-Type: application/jsonでないと署名検証が失敗する」 |
| **タスク完了時** | 実装概要・変更点・残課題 | 「認証フローをJWT→セッションに変更。リフレッシュトークンは未実装」 |
| **調査で分かったこと** | コードの仕組み・依存関係・制約 | 「認証ミドルウェアはserver/middleware/auth.tsで一括処理」 |
| **試行錯誤の過程** | 試したこと・失敗した理由 | 「pnpm v9ではpeer depsの自動インストールがデフォルトOFF」 |
| **ユーザーの暗黙的な好みを検知した時** | 修正・指摘から読み取れる好み・スタイル | 「変数名を修正された→略語より完全な単語を好む」 |
| **ビルド・テスト手順を発見した時** | 実行コマンド・前提条件・注意点 | 「E2Eテストは `docker compose up -d` でDB起動後に実行する必要がある」 |
| **タスクを中断・引き継ぐ時** | 現在の状態・次にやること・ブロッカー | 「認証機能の実装中。トークンリフレッシュが未完了、APIスキーマ確定待ち」 |

## 必須: タスク完了前のセルフチェック

タスク完了を報告する前に、以下を自問すること。1つでも該当すればメモを書く:

- 次に同じタスクをやる人が知っておくべきことはあるか?
- 調査中に「これは知らなかった」と思ったことはあるか?
- ユーザーが口頭で伝えた方針・好みはあるか?
- エラーや想定外の挙動に遭遇したか?
- 既存コードの設計意図を理解するのに時間がかかった箇所はあるか?
- ユーザーの修正・指摘から暗黙的な好みを読み取れたか?
- ビルドやテストの実行手順で試行錯誤したか?
- このタスクは未完了で、次回セッションに引き継ぐ必要があるか?

## IMPORTANT: ディレクトリ構造

**Vault直下にノートを作成することは禁止。** 必ず `プロジェクト名/` または `general/` ディレクトリ配下に作成すること。

nameパラメータは必ず `ディレクトリ名/ノート名` の**1階層のみ**とすること（スラッシュはちょうど1つ）。
**ノート名は英語・kebab-caseで命名すること。** ノートの内容（content）は日本語で記述する。

- ✅ `name="payment-notification-service/api-design"`
- ✅ `name="general/docker-tips"`
- ✅ `name="project-a/payment-api-quirks"`
- ❌ `name="payment-notification-service/設計メモ"` ← **禁止: 日本語のノート名**
- ❌ `name="general/Docker Tips"` ← **禁止: kebab-caseでない**
- ❌ `name="payment-notification-service設計メモ"` ← **禁止: Vault直下に作成されてしまう**
- ❌ `name="設計メモ"` ← **禁止: ディレクトリ指定がない**
- ❌ `name="payment-notification-service/design/api-spec"` ← **禁止: 多階層になっている**

サブディレクトリで分類したくなった場合は、ノート名やタグで区別すること（例: `name="project-a/payment-api-spec"` + `#api-quirk`）。

プロジェクト名の判定:
1. 現在の作業ディレクトリのリポジトリ名を使用する
2. リポジトリ外の場合やプロジェクト横断的な知見は `general/` を使用する

```
Vault/
├── project-a/                ← プロジェクト（リポジトリ）単位
│   ├── api-design.md
│   ├── auth-session-migration.md
│   └── ...
├── project-b/
│   └── ...
└── general/                  ← プロジェクト横断的な知見
    └── docker-tips.md
```

ノート名にはプロジェクト名を含めない（ディレクトリで識別するため）。

## メモのフォーマット（ADRスタイル統一）

全メモを以下のADRライクな構造で統一する。メモの種類に応じてセクションの解釈を読み替えること。

| セクション | 設計判断 | トラブルシューティング | 知見・メモ |
|---|---|---|---|
| **Status** | proposed/accepted/deprecated | resolved/investigating | active/outdated |
| **Context** | 背景・課題・制約 | 発生した問題・症状 | 状況・前提条件 |
| **Decision** | 採用した選択肢と理由 | 原因と解決策 | 要点・結論 |
| **Consequences** | 影響・トレードオフ・残課題 | 再発防止策・注意点 | 関連情報・今後の影響 |

```bash
# 設計判断の例
obsidian create name="project-a/state-management" content="$(cat <<'EOF'
## Status
accepted

## Context
状態管理ライブラリの選定が必要。候補はVuex, Pinia, 独自composable。
Vuexは公式に非推奨となっている。

## Decision
Piniaを採用。
- Vuex: 公式非推奨、TypeScript対応が弱い
- 独自composable: 小規模なら可だが、共有状態が増えると管理が困難
- Pinia: Vue公式推奨、TypeScriptフルサポート、DevTools対応

## Consequences
- 既存のVuexストアは段階的に移行が必要
- `defineStore` のID命名規約を別途決める必要あり

#project/project-a #design-decision
EOF
)"

# トラブルシューティングの例
obsidian create name="project-a/usefetch-cookie-issue" content="$(cat <<'EOF'
## Status
resolved

## Context
Nuxt useFetchでSSR時にAPIサーバーへcookieが送信されず、認証エラーが発生。

## Decision
useRequestHeaders でcookieを取得し、useFetchのheadersに明示的に渡す。
`const headers = useRequestHeaders(['cookie'])`

## Consequences
- SSRで認証が必要な全てのuseFetchに同パターンを適用する必要がある
- composableに共通化すると保守しやすい

#project/project-a #troubleshooting
EOF
)"

# 既存ノートへの追記（知見が増えた場合）
obsidian append file="project-a/state-management" content="$(cat <<'EOF'

## Update (YYYY-MM-DD)
新たに判明した内容
EOF
)"
```

## タグ規約

メモには以下のタグを付けて検索性を高めること:

- `#design-decision` — 設計判断
- `#troubleshooting` — ハマりポイント・トラブルシュート
- `#user-preference` — ユーザーの好み・方針
- `#environment` — 環境・インフラ情報
- `#api-quirk` — 外部API・ライブラリの癖
- `#build-process` — ビルド・テスト手順
- `#handover` — タスク中断・引き継ぎ情報
- `#project/プロジェクト名` — プロジェクト識別

## よく使うコマンド

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

# タグ一覧
obsidian tags

# プロパティの設定
obsidian property:set file="ノート名" name="key" value="value"
```

## 特定のVaultを指定する場合

```bash
obsidian <command> vault="Vault名"
```
