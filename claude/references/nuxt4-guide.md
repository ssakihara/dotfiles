# Nuxt 4 チーム固有ガイド

公式ドキュメントにある一般的な API 仕様・パターンは本ファイルに記載しない。
必要な場合は **WebFetch ツール**で https://nuxt.com/llms.txt から該当ドキュメントの URL を特定し、同じく WebFetch で取得して参照すること（curl 等のシェルコマンドは使わない）。
本ファイルには**公式にない、または公式と異なるチーム固有パターンのみ**を記載する。

## サーバーAPIバリデーション

agents/coder.md の「サーバーAPIバリデーション（CRITICAL）」が正である。

公式ドキュメントの例には `readValidatedBody` / `getValidatedRouterParams` / `.parse()` を使うものがあるが、**チームでは使用禁止**。
`readBody` / `getQuery` / `getRouterParams` + Zod の `safeParse` + `createError` で統一する。

## Composables（useState パターン）

状態は `useState` で持ち、外部には `readonly` で公開する。

```typescript
// composables/use-user.ts
export function useUser() {
  const user = useState<User | null>('user', () => null)
  const isLoggedIn = computed(() => user.value !== null)

  async function login(credentials: LoginCredentials) {
    const data = await $fetch<User>('/api/auth/login', {
      method: 'POST',
      body: credentials
    })
    user.value = data
  }

  return { user: readonly(user), isLoggedIn, login, logout }
}
```

## DBユーティリティ（Prisma シングルトン）

開発時のホットリロードで PrismaClient が増殖しないよう、globalThis に保持する。

```typescript
// server/utils/db.ts
import { PrismaClient } from '@prisma/client'

declare global {
  var prisma: PrismaClient | undefined
}

export const db = globalThis.prisma ?? new PrismaClient()

if (process.env.NODE_ENV !== 'production') {
  globalThis.prisma = db
}
```
