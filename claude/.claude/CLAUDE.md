# Claude Code 設定

## IMPORTANT: エージェント選択ルール

rules/agents.md のエージェント選択ルールに必ず従うこと。
コードレビュー依頼やコード変更後は**必ず** code-reviewer エージェントを実行すること。

## ファイル命名規則

TypeScript・Vueで新規ファイルを作成する場合、ファイル名は**必ずケバブケース**（例: `my-component.ts`, `user-service.ts`, `app-header.vue`）で命名すること。
キャメルケースやスネークケースは使用しないこと。

## コメント

複雑な設計や一見して意図が分かりにくい処理には、**なぜそのような実装になっているのか（Why）**をコメントで残すこと。
「何をしているか（What）」ではなく「なぜそうしているか（Why）」を書くこと。

## 検証

作業完了時、テスト実行・スクリーンショット・検証コマンドなど検証方法を必ず提供すること。

## メモリー代替: Obsidian CLI

Claude Codeのメモリー機能はOFFにしている。代わりに `obsidian` コマンドを使ってObsidian Vaultにメモを保存・検索すること。

### 基本方針

- ユーザーの好み・決定事項・プロジェクト知見など、後で参照したい情報はObsidianに記録する
- 利用可能なコマンドは `obsidian help` で確認すること（CLIは更新される可能性があるため）

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
