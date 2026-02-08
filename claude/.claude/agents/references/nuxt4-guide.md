# Nuxt 4 包括的ガイド

Nuxt 4の詳細なパターン、API、ベストプラクティス。

## データ取得

### useFetch（推奨）

SSR対応のデータ取得。

```typescript
// 基本形
const { data, status, error, refresh } = await useFetch('/api/users')

// オプション付き
const { data } = await useFetch('/api/users', {
  query: { page: 1, limit: 10 },
  pick: ['id', 'name'],           // フィールド選択
  transform: (data) => data.items, // 変換
  default: () => [],               // デフォルト値
  lazy: true,                      // 遅延ロード
  server: false,                   // クライアントのみ
  watch: [page],                   // リアクティブ監視
})
```

### useAsyncData（細粒度）

カスタムフェッチロジック。

```typescript
const { data } = await useAsyncData(
  'users',
  () => fetchUsersFromCustomAPI(),
  { getCachedData: (key) => nuxtApp.payload.data[key] }
)
```

### $fetch（クライアント側）

イベントハンドラや非SSR処理。

```typescript
async function submitForm() {
  const result = await $fetch('/api/submit', {
    method: 'POST',
    body: formData.value
  })
}
```

### アンチパターン

```typescript
// ❌ ライフサイクルフック内でuseFetch
onMounted(async () => {
  const { data } = await useFetch('/api/data')
})

// ❌ グローバルref（SSR非安全）
const globalState = ref(0)  // リクエスト間で共有される

// ✓ 正しい使い方
const { data } = await useFetch('/api/data')
const state = useState('key', () => null)
```

## Composables

```typescript
// composables/useUser.ts
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

## ページ

```vue
<script setup lang="ts">
const route = useRoute()
const userId = computed(() => route.params.id as string)

definePageMeta({
  layout: 'default',
  middleware: ['auth'],
  validate: async (route) => /^\d+$/.test(route.params.id)
})

useSeoMeta({
  title: () => `User ${user.value?.name}`,
  description: () => user.value?.bio
})

const { data: user } = await useFetch<User>(
  () => `/api/users/${userId.value}`
)
</script>

<template>
  <div v-if="user">
    <h1>{{ user.name }}</h1>
  </div>
</template>
```

## サーバーAPI（Nitro）

### Zod + h3 によるバリデーション

```typescript
// server/entry/userSchema.ts
import { z } from 'zod'

export const userIdParamSchema = z.object({
  id: z.coerce.number().int().positive()
})

export const createUserSchema = z.object({
  email: z.string().email(),
  name: z.string().min(1).max(100)
})

export type CreateUserInput = z.infer<typeof createUserSchema>
```

```typescript
// server/api/users/[id].get.ts
import { userIdParamSchema } from '~/server/entry/userSchema'

export default defineEventHandler(async (event) => {
  const { id } = await getValidatedRouterParams(event, userIdParamSchema.parse)
  const user = await db.user.findUnique({ where: { id } })
  if (!user) throw createError({ statusCode: 404 })
  return user
})
```

### DBユーティリティ

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

## 設定

```typescript
// nuxt.config.ts
export default defineNuxtConfig({
  typescript: { strict: true, typeCheck: true },

  runtimeConfig: {
    apiSecret: process.env.API_SECRET,  // サーバーのみ
    public: {
      apiBase: '/api'  // クライアントアクセス可能
    }
  },

  modules: ['@nuxt/ui', '@pinia/nuxt', '@vueuse/nuxt'],

  compatibilityDate: '2024-11-01'  // Nuxt 4で必須
})
```

## ミドルウェア

```typescript
// middleware/auth.ts
export default defineNuxtRouteMiddleware((to) => {
  const { isLoggedIn } = useUser()
  if (!isLoggedIn.value) {
    return navigateTo('/login', { redirectCode: 302 })
  }
})
```

## エラーハンドリング

```typescript
// クライアント側
const { data, error } = await useFetch('/api/users')

if (error.value) {
  throw createError({
    statusCode: error.value.statusCode,
    fatal: true
  })
}

// error.vue
<script setup lang="ts">
const props = defineProps<{ error: NuxtError }>()
const handleError = () => clearError({ redirect: '/' })
</script>

<template>
  <div>
    <h1>{{ error.statusCode }}</h1>
    <button @click="handleError">ホーム</button>
  </div>
</template>
```

## ユーティリティ

```typescript
// ランタイム設定
const config = useRuntimeConfig()
console.log(config.apiSecret)  // サーバーのみ
console.log(config.public.apiBase)  // どこでも使用可能

// Cookie
const token = useCookie<string>('auth-token', {
  maxAge: 60 * 60 * 24 * 7,
  secure: true,
  httpOnly: false
})

// データキャッシュ
clearNuxtData('users')
await refreshNuxtData('users')
```

## NuxtLink

```vue
<template>
  <!-- 基本 -->
  <NuxtLink to="/about">About</NuxtLink>

  <!-- 外部リンク -->
  <NuxtLink to="https://example.com" external>External</NuxtLink>

  <!-- プリフェッチなし -->
  <NuxtLink to="/heavy" :prefetch="false">Heavy</NuxtLink>

  <!-- アクティブクラス -->
  <NuxtLink to="/users" active-class="text-primary">Users</NuxtLink>
</template>
```
