# コミットメッセージ規約

## 基本フォーマット（Conventional Commits）

```sh
<type>(<scope>): <description>
```

- `type`: feat, fix, refactor, docs, test, chore, ci, perf, style, build
- `scope`: 任意。変更対象のモジュールやコンポーネント名
- `description`: 変更内容を簡潔に日本語で記述すること

## 課題キーの付与（IMPORTANT）

ブランチ名に課題キー（例: `XXX-100`, `PROJ-42`）が含まれている場合、コミットメッセージの先頭に課題キーを付与すること。

```sh
<課題キー> <type>(<scope>): <description>
```

判定手順:

1. `git branch --show-current` でブランチ名を取得する
2. ブランチ名から `[A-Z]+-[0-9]+` パターンに一致する課題キーを抽出する
3. 一致した場合、コミットメッセージの先頭に課題キーを追加する
4. 一致しない場合、課題キーなしで通常の Conventional Commits フォーマットを使用する

例:

| ブランチ名 | コミットメッセージ |
| --- | --- |
| `feature/PROJ-42-add-login` | `PROJ-42 feat: ログイン機能を追加` |
| `fix/PAYMENT-123-amount-calc` | `PAYMENT-123 fix: 金額計算の丸め誤差を修正` |
| `main` | `feat: ログイン機能を追加` |
| `refactor/cleanup-utils` | `refactor: utilsの不要な関数を削除` |
