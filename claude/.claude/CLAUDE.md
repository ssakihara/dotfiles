# Claude Code 設定

## IMPORTANT: エージェント選択ルール

rules/agents.md のエージェント選択ルールに必ず従うこと。
コードレビュー依頼やコード変更後は**必ず** code-reviewer エージェントを実行すること。

## ファイル命名規則

TypeScript・Vueで新規ファイルを作成する場合、ファイル名は**必ずケバブケース**（例: `my-component.ts`, `user-service.ts`, `app-header.vue`）で命名すること。
キャメルケースやスネークケースは使用しないこと。

## 検証

作業完了時、テスト実行・スクリーンショット・検証コマンドなど検証方法を必ず提供すること。
