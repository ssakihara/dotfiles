# エージェントオーケストレーション

## Nuxt プロジェクト（必須）

`nuxt.config.ts` が存在する場合、**必ず** nuxt4-coder エージェントを使用すること。
直接 Edit/Write ツールで .vue や server/ 配下のファイルを編集してはならない。

判定フロー:
1. Glob で nuxt.config.ts を確認
2. 存在する場合 → Agent ツールで nuxt4-coder を呼び出し（最優先）
3. 存在しない場合 → tsconfig.json を確認
4. tsconfig.json が存在する場合 → Agent ツールで typescript-coder を呼び出し
5. どちらもない場合 → 直接 Edit/Write を使用可

## TypeScript プロジェクト（必須）

`tsconfig.json` が存在し、`nuxt.config.ts` が存在しない場合、**必ず** typescript-coder エージェントを使用すること。
直接 Edit/Write ツールで .ts ファイルを編集してはならない。

## ローカル動作検証（必須）

Webアプリケーションのローカル動作検証には、**必ず** web-debugger エージェントを使用すること。
ブラウザを手動で開いて確認するのではなく、web-debugger で自動化すること。

対象:
- ページの表示確認・UI検証
- フォーム操作・ユーザーインタラクションのテスト
- コンソールエラー・ネットワークエラーの確認
- スクリーンショットによる視覚的検証
- コード変更後の動作確認（git diff ベース）

## コードレビュー（必須）

コードレビュー依頼やコード作成・変更後、**必ず** code-reviewer エージェントを実行すること。
**サブエージェント（nuxt4-coder, typescript-coder 等）が変更を行った場合も同様。**
ユーザーへの完了報告前にレビューを実行すること。
