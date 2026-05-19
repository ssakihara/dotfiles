# セキュリティ詳細パターン

## OWASP Top 10 対策

### SQLインジェクション

```typescript
// ❌ 脆弱性あり
const query = `SELECT * FROM users WHERE id = ${userId}`
await db.query(query)

// ✓ パラメータ化クエリ
await db.query('SELECT * FROM users WHERE id = $1', [userId])

// ✓ ORM（Prisma）
await db.user.findUnique({ where: { id: userId } })
```

### XSS（クロスサイトスクリプティング）

```vue
<!-- ❌ 脆弱性あり -->
<div>{{ userInput }}</div>

<!-- ❌ v-htmlはサニタイズ必須 -->
<div v-html="userInput"></div>

<!-- ✓ 自動エスケープ（デフォルト） -->
<div>{{ userInput }}</div>

<!-- ✓ サニタイズ済み -->
<div v-html="DOMPurify.sanitize(userInput)"></div>
```

### CSRF対策

```typescript
// Nuxt 3/4 でCSRF保護
// nuxt.config.ts
export default defineNuxtConfig({
  modules: ['@sidebase/nuxt-csrf']
})

// サーバー側で検証
import { validateCsrfToken } from '#imports'

export default defineEventHandler(async (event) => {
  await validateCsrfToken(event)
  // 安全に処理続行
})
```

### 認証/認可

```typescript
// ❌ 認証チェックなし
export default defineEventHandler(async (event) => {
  return await db.user.findAll()
})

// ✓ 認証ミドルウェア
export default defineEventHandler(async (event) => {
  const user = await getUserFromSession(event)
  if (!user) {
    throw createError({ statusCode: 401, message: 'Unauthorized' })
  }
  return await db.user.findAll()
})

// ✓ 認可チェック（管理者のみ）
export default defineEventHandler(async (event) => {
  const user = await getUserFromSession(event)
  if (!user?.isAdmin) {
    throw createError({ statusCode: 403, message: 'Forbidden' })
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
import { z } from 'zod'

const userSchema = z.object({
  email: z.string().email(),
  age: z.number().min(0).max(150),
  name: z.string().min(1).max(100)
})

export default defineEventHandler(async (event) => {
  const data = await readValidatedBody(event, userSchema.parse)
  await db.user.create({ data })
})
```

### レート制限

```typescript
// Nitro レート制限
import { defineRateLimiter } from '#imports'

const limiter = defineRateLimiter({
  interval: 60000,  // 1分
  requests: 100     // 100リクエスト
})

export default defineEventHandler(async (event) => {
  await limiter(event)
  // レート制限後の処理
})
```

### エラーメッセージ

```typescript
// ❌ 機密情報を露出
throw createError({
  statusCode: 500,
  message: `Database connection failed: ${process.env.DB_PASSWORD}`
})

// ❌ データベース構造を露出
throw createError({
  statusCode: 500,
  message: `Table users does not exist in database production_db`
})

// ✓ 安全なエラーメッセージ
if (process.env.NODE_ENV === 'production') {
  throw createError({
    statusCode: 500,
    message: 'Internal server error'
  })
} else {
  throw createError({
    statusCode: 500,
    message: debugMessage  // 開発環境のみ詳細
  })
}
```

## シークレット管理

### Nuxt ランタイム設定

```typescript
// nuxt.config.ts
export default defineNuxtConfig({
  runtimeConfig: {
    // サーバーのみ（クライアントJSに含まれない）
    databaseUrl: process.env.DATABASE_URL,
    apiSecret: process.env.API_SECRET,

    public: {
      // クライアントJSに含まれる（安全なもののみ）
      apiBase: '/api',
      appName: 'MyApp'
    }
  }
})

// 使用時
const config = useRuntimeConfig()
console.log(config.databaseUrl)  // サーバーのみOK
console.log(config.apiBase)      // どこでもOK
```

### 環境変数検証

```typescript
// server/utils/env.ts
import { z } from 'zod'

const envSchema = z.object({
  DATABASE_URL: z.string().url(),
  API_SECRET: z.string().min(32),
  REDIS_URL: z.string().url().optional()
})

export const env = envSchema.parse(process.env)
```

## 一般的な脆弱性

| 脆弱性 | 例 | 対策 |
|--------|-----|------|
| eval() | `eval(userInput)` | 絶対に使用禁止 |
| innerHTML | `el.innerHTML = input` | DOMPurify でサニタイズ |
| パストラバーサル | `../../../etc/passwd` | 許可リストでパス検証 |
| ReDoS | `^([a-z]+)+$` | タイムアウト設定 |
| プロトタイプ汚染 | `JSON.parse(input)` | スキーマ検証 |

## セキュリティヘッダー

```typescript
// server/api/hello.ts
export default defineEventHandler((event) => {
  setHeader(event, 'X-Content-Type-Options', 'nosniff')
  setHeader(event, 'X-Frame-Options', 'DENY')
  setHeader(event, 'X-XSS-Protection', '1; mode=block')
  setHeader(event, 'Strict-Transport-Security', 'max-age=31536000; includeSubDomains')
  setHeader(event, 'Content-Security-Policy', "default-src 'self'")

  return { hello: 'world' }
})
```
