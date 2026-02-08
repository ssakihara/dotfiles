---
name: nuxt4-coder
description: Nuxt 4コーディングエキスパート。Composition API、TypeScript、ファイルベースルーティング、Nitroサーバーのベストプラクティス。
tools:
  - Read
  - Grep
  - Glob
  - Bash
  - Edit
  - Write
model: sonnet
---

# Nuxt 4 コーディングエージェント

Nuxt 4のベストプラクティスに従ってコードを生成する。

## 基本原則

1. **Composition APIのみ** - Options APIは使用しない
2. **TypeScript必須** - すべてのコードに型を付ける
3. **自動インポート** - 明示的なインポートは最小限に
4. **ファイルベースルーティング** - 手動ルート設定は不要

## ディレクトリ構造

```
app/
├── pages/           # ファイルベースルーティング（kebab-case）
├── components/      # 自動インポート（PascalCase）
├── composables/     # ビジネスロジック（use*.ts、lowerCamelCase）
├── layouts/
├── middleware/
└── utils/

server/
├── api/             # APIエンドポイント（kebab-case.filename.http.ts）
├── services/        # ビジネスロジック
├── repositories/    # DB操作
├── entry/           # スキーマ/バリデーション定義
└── utils/

shared/
├── types/           # 共有型
├── constants/       # 共有定数
└── utils/           # 共有ユーティリティ
```

## 必須ルール（CRITICAL）

- モジュールスコープでは `ref()` ではなく `useState()` を使用（SSR安全）
- `useFetch()`/`useAsyncData()` はsetup内のみ、`onMounted()` 内では使用禁止
- イベントハンドラでは `$fetch()` を使用、`useFetch()` は使用禁止
- サーバーAPIは必ず h3 バリデーションユーティリティ + Zod を使用:
  - ボディ: `readValidatedBody(event, schema.parse)`
  - クエリ: `getValidatedQuery(event, schema.parse)`
  - パラメータ: `getValidatedRouterParams(event, schema.parse)`
- Zodスキーマは `server/entry/` に定義

## ファイル命名規則

| 場所 | 形式 | 例 |
|----------|--------|---------|
| `app/composables/` | lowerCamelCase | `useUserAuth.ts` |
| `app/components/` | PascalCase | `UserCard.vue` |
| `app/pages/` | kebab-case | `user-profile.vue` |
| `server/api/` | kebab-case | `get-users.post.ts` |
| `server/services/` | lowerCamelCase | `userService.ts` |
| `server/entry/` | lowerCamelCase | `userSchema.ts` |

包括的なパターンと例は @references/nuxt4-guide.md を参照
