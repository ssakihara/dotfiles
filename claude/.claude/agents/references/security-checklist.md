# セキュリティチェックリスト

コードレビュー用の詳細なセキュリティパターン。

## OWASP Top 10 パターン

### SQLインジェクション

```typescript
// ❌ 脆弱性あり
const query = `SELECT * FROM users WHERE id = ${userId}`

// ✓ 安全 - パラメータ化クエリ
const query = 'SELECT * FROM users WHERE id = $1'
await db.query(query, [userId])
```

### XSS（クロスサイトスクリプティング）

```vue
<!-- ❌ 脆弱性あり -->
<div>{{ rawHtml }}</div>

<!-- ✓ 安全 -->
<div v-html="sanitizedHtml"></div>

<script setup>
import DOMPurify from 'dompurify'
const sanitizedHtml = computed(() => DOMPurify.sanitize(rawHtml.value))
</script>
```

### 認証/認可

```typescript
// ❌ 認証チェックなし
export default defineEventHandler(async (event) => {
  return await db.user.findAll()
})

// ✓ 認証チェックあり
export default defineEventHandler(async (event) => {
  const user = await requireUser(event)
  if (!user.isAdmin) {
    throw createError({ statusCode: 403 })
  }
  return await db.user.findAll()
})
```

### 入力バリデーション

```typescript
// ❌ バリデーションなし
export default defineEventHandler(async (event) => {
  const body = await readBody(event)
  await db.user.create({ data: body })
})

// ✓ Zod + h3 バリデーション
import { createUserSchema } from '~/server/entry/userSchema'
export default defineEventHandler(async (event) => {
  const data = await readValidatedBody(event, createUserSchema.parse)
  await db.user.create({ data })
})
```

## シークレット管理

### 環境変数のみ使用

```typescript
// ❌ ハードコード
const apiKey = "sk-proj-xxxxx"

// ✓ 環境変数
const apiKey = process.env.API_KEY
if (!apiKey) throw new Error('API_KEY not configured')
```

### ランタイム設定（Nuxt）

```typescript
// ❌ シークレットをpublicに
runtimeConfig: {
  public: {
    apiSecret: process.env.API_SECRET  // クライアントに公開！
  }
}

// ✓ private設定
runtimeConfig: {
  apiSecret: process.env.API_SECRET,  // サーバーのみ
  public: {
    apiBase: '/api'  // クライアント公開は安全
  }
}
```

## 一般的な脆弱性

| パターン | リスク | 修正 |
|---------|------|-----|
| `eval()` | コードインジェクション | 絶対に使用禁止 |
| `innerHTML` + ユーザー入力 | XSS | DOMPurifyでサニタイズ |
| `require()` + ユーザーパス | パストラバーサル | 許可リストで検証 |
| Regex + タイムアウトなし | ReDoS | タイムアウト設定 |
| `JSON.parse()` + 無検証 | プロトタイプ汚染 | スキーマ検証先に |
