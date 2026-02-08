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

1. 作業停止
2. code-reviewer エージェントで調査
3. CRITICAL問題を修正
4. 漏洩シークレットをローテーション
5. コードベース全体をレビュー

詳細なセキュリティパターンは @rules/references/security-patterns.md を参照
