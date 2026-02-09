# TypeScript 包括的ガイド

汎用TypeScriptプロジェクトの詳細なパターン、型安全、ベストプラクティス。

## 型安全

### 型ガード

```typescript
// ❌ any にキャスト
function processValue(value: any) {
  return value.name
}

// ✓ unknown + 型ガード
function isUser(value: unknown): value is User {
  return (
    typeof value === 'object' &&
    value !== null &&
    'name' in value &&
    typeof (value as Record<string, unknown>).name === 'string'
  )
}

function processValue(value: unknown): string {
  if (!isUser(value)) {
    throw new Error('Invalid user data')
  }
  return value.name
}
```

### 判別共用体

```typescript
// ✓ タグ付きユニオンで型を安全に分岐
type Shape =
  | { kind: 'circle'; radius: number }
  | { kind: 'rectangle'; width: number; height: number }

function area(shape: Shape): number {
  switch (shape.kind) {
    case 'circle':
      return Math.PI * shape.radius ** 2
    case 'rectangle':
      return shape.width * shape.height
  }
}
```

### ブランド型

```typescript
// ✓ プリミティブに意味を付与して混同を防止
type UserId = string & { readonly __brand: 'UserId' }
type OrderId = string & { readonly __brand: 'OrderId' }

function createUserId(id: string): UserId {
  return id as UserId
}

function getUser(id: UserId): User { /* ... */ }

// コンパイルエラー: OrderId を UserId に渡せない
// getUser(orderId)
```

## ジェネリクス

### 制約付きジェネリクス

```typescript
// ❌ any で受ける
function getProperty(obj: any, key: string) {
  return obj[key]
}

// ✓ 制約で型安全を保証
function getProperty<T, K extends keyof T>(obj: T, key: K): T[K] {
  return obj[key]
}
```

### ユーティリティ型の活用

```typescript
// 部分更新
function updateUser(id: UserId, data: Partial<Omit<User, 'id'>>): Promise<User> {
  // ...
}

// 読み取り専用
type Config = Readonly<{
  host: string
  port: number
  debug: boolean
}>

// Pick / Omit で必要なフィールドのみ
type UserSummary = Pick<User, 'id' | 'name' | 'email'>
type UserWithoutPassword = Omit<User, 'password'>
```

## エラーハンドリング

### Result パターン

```typescript
// ✓ エラーを値として扱う
type Result<T, E = Error> =
  | { ok: true; value: T }
  | { ok: false; error: E }

function ok<T>(value: T): Result<T, never> {
  return { ok: true, value }
}

function err<E>(error: E): Result<never, E> {
  return { ok: false, error }
}

// 使用例
async function findUser(id: string): Promise<Result<User, 'NOT_FOUND' | 'DB_ERROR'>> {
  try {
    const user = await db.user.findUnique({ where: { id } })
    if (!user) return err('NOT_FOUND')
    return ok(user)
  } catch {
    return err('DB_ERROR')
  }
}

// 呼び出し側
const result = await findUser(id)
if (!result.ok) {
  switch (result.error) {
    case 'NOT_FOUND':
      // 404 処理
      break
    case 'DB_ERROR':
      // 500 処理
      break
  }
  return
}
const user = result.value // 型安全
```

### カスタムエラークラス

```typescript
// ✓ エラーの種類を型で区別
class AppError extends Error {
  constructor(
    message: string,
    public readonly code: string,
    public readonly statusCode: number = 500,
  ) {
    super(message)
    this.name = 'AppError'
  }
}

class NotFoundError extends AppError {
  constructor(resource: string, id: string) {
    super(`${resource} not found: ${id}`, 'NOT_FOUND', 404)
    this.name = 'NotFoundError'
  }
}

class ValidationError extends AppError {
  constructor(
    message: string,
    public readonly fields: Record<string, string>,
  ) {
    super(message, 'VALIDATION_ERROR', 400)
    this.name = 'ValidationError'
  }
}
```

### async エラーハンドリング

```typescript
// ❌ reject をハンドリングしない
async function fetchData() {
  const data = await fetch('/api/data')
  return data.json()
}

// ✓ エラーを適切にハンドリング
async function fetchData(): Promise<Result<Data>> {
  try {
    const response = await fetch('/api/data')
    if (!response.ok) {
      return err(new AppError(`HTTP ${response.status}`, 'HTTP_ERROR', response.status))
    }
    const data = await response.json()
    return ok(data)
  } catch (error) {
    return err(new AppError('Network error', 'NETWORK_ERROR'))
  }
}
```

## 外部データバリデーション

### Zod によるスキーマ定義

```typescript
import { z } from 'zod'

// スキーマ定義
const userSchema = z.object({
  id: z.string().uuid(),
  email: z.string().email(),
  name: z.string().min(1).max(100),
  age: z.number().int().min(0).max(150).optional(),
  role: z.enum(['admin', 'user', 'guest']),
  createdAt: z.coerce.date(),
})

// 型を自動導出
type User = z.infer<typeof userSchema>

// 部分スキーマ
const updateUserSchema = userSchema.pick({ name: true, email: true }).partial()
type UpdateUser = z.infer<typeof updateUserSchema>
```

### バリデーション適用

```typescript
// ❌ 外部データを信頼
async function handleRequest(body: unknown) {
  const user = body as User  // 危険
  await db.user.create({ data: user })
}

// ✓ バリデーションしてから使用
async function handleRequest(body: unknown): Promise<Result<User>> {
  const parsed = userSchema.safeParse(body)
  if (!parsed.success) {
    return err(new ValidationError('Invalid input', formatZodError(parsed.error)))
  }
  const user = await db.user.create({ data: parsed.data })
  return ok(user)
}

// Zodエラーのフォーマット
function formatZodError(error: z.ZodError): Record<string, string> {
  const fields: Record<string, string> = {}
  for (const issue of error.issues) {
    fields[issue.path.join('.')] = issue.message
  }
  return fields
}
```

## モジュール設計

### 名前付きエクスポート

```typescript
// ❌ default export
export default function createUser() { /* ... */ }

// ✓ 名前付きエクスポート
export function createUser(): Result<User> { /* ... */ }
export function deleteUser(id: UserId): Promise<Result<void>> { /* ... */ }
```

### バレルエクスポート

```typescript
// src/index.ts - 公開APIのみエクスポート
export { createUser, deleteUser } from './userService'
export { type User, type UserId } from './types/user'
export { AppError, NotFoundError } from './errors'
```

### 依存性注入

```typescript
// ✓ インターフェースに依存
interface UserRepository {
  findById(id: string): Promise<User | null>
  save(user: User): Promise<void>
}

interface Logger {
  info(message: string, meta?: Record<string, unknown>): void
  error(message: string, error?: Error): void
}

// 実装は注入
function createUserService(deps: {
  userRepo: UserRepository
  logger: Logger
}) {
  return {
    async getUser(id: string): Promise<Result<User>> {
      const user = await deps.userRepo.findById(id)
      if (!user) return err('NOT_FOUND' as const)
      deps.logger.info('User fetched', { id })
      return ok(user)
    },
  }
}
```

## enum の代替

```typescript
// ❌ enum はツリーシェイキングされない
enum Status {
  Active = 'active',
  Inactive = 'inactive',
}

// ✓ as const + ユニオン型
const STATUS = {
  Active: 'active',
  Inactive: 'inactive',
} as const

type Status = (typeof STATUS)[keyof typeof STATUS]
// => 'active' | 'inactive'

// ✓ シンプルなユニオン型
type Status = 'active' | 'inactive'
```

## テストパターン

### Vitest 基本

```typescript
import { describe, expect, it, vi } from 'vitest'
import { createUser } from './userService'

describe('createUser', () => {
  it('should create a valid user', async () => {
    const result = await createUser({ name: 'Alice', email: 'alice@example.com' })
    expect(result.ok).toBe(true)
    if (result.ok) {
      expect(result.value.name).toBe('Alice')
    }
  })

  it('should return error for invalid email', async () => {
    const result = await createUser({ name: 'Alice', email: 'invalid' })
    expect(result.ok).toBe(false)
  })
})
```

### モック

```typescript
import { describe, expect, it, vi } from 'vitest'

// 依存性のモック
const mockRepo: UserRepository = {
  findById: vi.fn(),
  save: vi.fn(),
}

const mockLogger: Logger = {
  info: vi.fn(),
  error: vi.fn(),
}

describe('UserService', () => {
  const service = createUserService({ userRepo: mockRepo, logger: mockLogger })

  it('should return NOT_FOUND when user does not exist', async () => {
    vi.mocked(mockRepo.findById).mockResolvedValue(null)
    const result = await service.getUser('123')
    expect(result).toEqual({ ok: false, error: 'NOT_FOUND' })
  })
})
```

### 型テスト

```typescript
import { assertType, expectTypeOf, it } from 'vitest'

it('should infer correct types', () => {
  expectTypeOf(createUserId('abc')).toEqualTypeOf<UserId>()
  expectTypeOf(ok(42)).toEqualTypeOf<Result<number, never>>()
})
```

## tsconfig.json 推奨設定

```jsonc
{
  "compilerOptions": {
    // 厳密性（必須）
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "exactOptionalPropertyTypes": true,

    // モジュール
    "module": "Node16",
    "moduleResolution": "Node16",
    "target": "ES2022",

    // 出力
    "outDir": "dist",
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true,

    // パス
    "baseUrl": ".",
    "paths": {
      "~/*": ["./src/*"]
    },

    // その他
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "isolatedModules": true,
    "verbatimModuleSyntax": true
  },
  "include": ["src"],
  "exclude": ["node_modules", "dist"]
}
```

## ビルドツール選択

| ツール | 用途 | 特徴 |
|--------|------|------|
| `tsc` | ライブラリ | 型チェック + 型定義生成 |
| `tsx` | 開発 / スクリプト | esbuild ベース、即時実行 |
| `vitest` | テスト | esbuild ベース、型テスト対応 |

```jsonc
// package.json スクリプト例
{
  "scripts": {
    "build": "tsc",
    "dev": "tsx watch src/index.ts",
    "test": "vitest run",
    "test:watch": "vitest",
    "typecheck": "tsc --noEmit",
    "lint": "eslint ."
  }
}
```
