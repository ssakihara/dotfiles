# パフォーマンス詳細パターン

## データベース最適化

### 統合テクニック

```sql
-- ❌ 複数クエリ
SELECT COUNT(*) FROM users WHERE status = 'active';
SELECT COUNT(*) FROM users WHERE status = 'pending';

-- ✓ 1クエリに統合
SELECT
  COUNT(*) FILTER (WHERE status = 'active') AS active_count,
  COUNT(*) FILTER (WHERE status = 'pending') AS pending_count
FROM users;
```

```sql
-- ❌ 複数UPDATE
UPDATE users SET status = 'active' WHERE id = 1;
UPDATE users SET status = 'active' WHERE id = 2;

-- ✓ 1クエリに統合
UPDATE users
SET status = CASE
  WHEN id = 1 THEN 'active'
  WHEN id = 2 THEN 'active'
END
WHERE id IN (1, 2);
```

### N+1問題の解決

```typescript
// ❌ N+1 クエリ
const users = await db.user.findMany();
for (const user of users) {
  const posts = await db.post.findMany({ where: { userId: user.id } });
  user.posts = posts;
}

// ✓ JOIN で解決（Prisma）
const users = await db.user.findMany({
  include: { posts: true }
});
```

### インデックス設計

```sql
-- 複合インデックスのカラム順序（選択性の高い順）
CREATE INDEX idx_user_status_created ON users(status, created_at);

-- カバリングインデックス（必要なカラムのみ）
CREATE INDEX idx_user_list ON users(status, created_at) INCLUDE (name, email);
```

### カーソルベースページネーション

```typescript
// ❌ OFFSET が深いと遅い
const users = await db.user.findMany({
  skip: 10000,
  take: 20,
  orderBy: { created_at: 'desc' }
});

// ✓ カーソルベース
const users = await db.user.findMany({
  take: 20,
  cursor: { id: lastUserId },
  orderBy: { id: 'asc' }
});
```

## キャッシュ戦略

### キャッシュキー命名規則

```typescript
// パターン: {resource}:{id}:{sub-resource}
const keys = {
  userProfile: `user:${userId}:profile`,
  userPermissions: `user:${userId}:permissions`,
  productDetails: `product:${productId}:details`,
  searchResults: `search:${queryHash}:page:${page}`
}
```

### キャッシュ実装例

```typescript
// Redis + TTL
async function getUser(id: string) {
  const cacheKey = `user:${id}:profile`
  const cached = await redis.get(cacheKey)
  if (cached) return JSON.parse(cached)

  const user = await db.user.findUnique({ where: { id } })
  await redis.setex(cacheKey, 3600, JSON.stringify(user)) // 1時間
  return user
}

// 明示的無効化
async function updateUser(id: string, data: any) {
  const user = await db.user.update({ where: { id }, data })
  await redis.del(`user:${id}:profile`)
  await redis.del(`user:${id}:permissions`)
  return user
}
```

## API並列化

```typescript
// ❌ 逐次実行
const user = await fetchUser(userId)
const posts = await fetchUserPosts(userId)
const comments = await fetchUserComments(userId)

// ✓ 並列実行
const [user, posts, comments] = await Promise.all([
  fetchUser(userId),
  fetchUserPosts(userId),
  fetchUserComments(userId)
])
```

## ストリーム処理

```typescript
// ❌ 全体をメモリに載せる
const file = fs.readFileSync('large-file.json')
const data = JSON.parse(file)

// ✓ ストリームで処理
const stream = fs.createReadStream('large-file.json')
const data = await JSONStream.stream('*')
```

## コネクションプール設定

```typescript
// Prisma プール設定
const prisma = new PrismaClient({
  datasources: {
    db: {
      url: process.env.DATABASE_URL
    }
  }
})

// プールサイズ（コネクション制限/計算インスタンス数 - 2）
// 例: RDS max_connections = 100、インスタンス = 10 → プールサイズ = 8
```
