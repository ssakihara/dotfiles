# SQL フォーマット規約

テンプレートリテラル内のSQLは以下のルールに従うこと:

- SQLキーワード（`SELECT`, `FROM`, `WHERE`, `ORDER BY`, `INSERT INTO`, `UPDATE`, `SET`, `VALUES`, `RETURNING`）はバッククォート開始位置より左に出さない
- キーワードの後は改行し、対象（テーブル名・カラム名・式）を2スペースインデントで記述
- カラムリストは1カラム1行
- WHERE条件が短い場合は1行にまとめてよい

```typescript
// ✅ Good: SELECT
const result = await db.query(
  `SELECT
    id,
    name,
    email,
    status
  FROM users
  WHERE id = $1 AND status = $2`,
  [id, status],
);

// ✅ Good: UPDATE
const result = await db.query(
  `UPDATE
    users
  SET
    name = $2,
    email = $3,
    updated_at = NOW()
  WHERE id = $1
  RETURNING *`,
  [id, name, email],
);

// ✅ Good: INSERT
const result = await db.query(
  `INSERT INTO
    users (
      name,
      email,
      status,
      created_at
    )
  VALUES ($1, $2, $3, NOW())
  RETURNING *`,
  [name, email, status],
);

// ❌ Bad: カラムが左端に貼り付いている
const result = await db.query(
  `SELECT
id,
name
FROM users
WHERE id = $1`,
  [id],
);

// ❌ Bad: キーワードとテーブル名が同じ行
const result = await db.query(
  `UPDATE users
  SET name = $2
  WHERE id = $1`,
  [id, name],
);
```
