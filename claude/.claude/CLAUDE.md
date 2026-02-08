# Claude Code 設定

## サブエージェントルール

Nuxt プロジェクトでは**必ず** nuxt4-coder エージェントを使用すること。最初に必ず nuxt.config.ts の存在を確認すること。

コード変更後は**必ず** code-reviewer エージェントを実行すること。

## ドメインルール

データベース、キャッシュ、API最適化は @rules/performance.md を参照
セキュリティチェックとシークレット管理は @rules/security.md を参照

## ブラウザ自動化

テストには agent-browser を使用。ワークフロー: open → snapshot -i → interact → re-snapshot

## コンテキスト管理

- 調査にはサブエージェントを使用してコンテキストを節約
- 関連のないタスク間では /clear を実行
- 複雑なマルチステップタスクには Task ツールを使用

## 検証

テスト、スクリーンショット、検証コマンドなど、作業を検証する方法を必ず提供すること。
