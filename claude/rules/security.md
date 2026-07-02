# セキュリティガイドライン

## コミット前チェック

- ハードコードされたシークレットなし
- すべてのユーザー入力が検証されている
- SQLインジェクション対策（パラメータ化クエリ）
- XSS対策（HTMLサニタイズ）
- CSRF保護有効
- 認証/認可検証済み
- レート制限あり
- エラーメッセージに機密データなし

## シークレット管理

```typescript
// ❌ ハードコード
const apiKey = "sk-proj-xxxxx"

// ✓ 環境変数
const apiKey = process.env.API_KEY
if (!apiKey) throw new Error('API_KEY not configured')
```

## セキュリティ問題発見時

rules/code-review.md の「セキュリティ重大問題検出時」の手順に従うこと。
作業を停止してユーザーに報告し、独断で修正を進めない。

詳細なセキュリティパターンは references/security-patterns.md を参照（必要に応じて読み込むこと）
