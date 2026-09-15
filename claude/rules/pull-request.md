# PR 作成規約

## アサインとレビュワー（IMPORTANT）

PR 作成時は必ず自分をアサインし、GitHub Copilot をレビュワーに設定すること。

- アサイン: `gh pr create` に `--assignee @me` を付与する
- レビュワー: `gh pr create` は `@copilot` を解決できないため、作成後に `gh pr edit --add-reviewer "@copilot"` で追加する

```sh
gh pr create --base <base> --assignee @me --title "..." --body "..."
gh pr edit --add-reviewer "@copilot"
```

`gh pr edit` は引数を省略すると現在のブランチの PR を対象にする。
別の PR を対象にする場合は `gh pr edit <番号> --add-assignee @me --add-reviewer "@copilot"` のように番号を指定する。
アサインやレビュワーが漏れた既存 PR に気づいた場合も同様に補うこと。

なお `@copilot` は GitHub Enterprise Server では利用できない。

## タイトルと本文

シンプルで分かりやすく、簡潔に書くこと。
読み手が差分を開かなくても変更の概要を把握できる状態を目指す。

- タイトル: 変更内容を1文で表す。
  70文字以内とし、冗長な前置きや装飾を付けない
- 本文: 1項目1行の箇条書きで書き、長文の説明を書かない
- 背景や検討の経緯は関連課題へのリンクに委ね、PR 本文に転記しない

## 本文テンプレート

リポジトリに PR テンプレート（`.github/PULL_REQUEST_TEMPLATE.md` 等）がある場合はそれに従う。
ない場合は以下をデフォルトとして使う。

```md
## 関連課題
- PROJ-123

## 概要
- 変更点を1行ずつ

## 動作確認
- 実行したコマンドと結果

## 注意事項
- なし

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

各セクションの記載ルール:

- セクションは削除せず、順序も変えない。
  該当がない場合は `- なし` の1行だけ書く（水増しの文章で埋めない）
- 関連課題: GitHub issue は `Closes #123` と書きマージ時に自動クローズさせる。
  Backlog 課題はキーのみ記載する
- 概要: 変更点を1行ずつ書く。
  背景や検討の経緯は関連課題に委ねる
- 動作確認: 実行したテストコマンド・確認手順とその結果を書く。
  未実施の場合はその旨を明記する
- 注意事項: レビュー時に見てほしい点・既知の制約・マージ順の依存などを書く
