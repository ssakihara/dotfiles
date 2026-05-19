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

## 変数代入時のスタイル

`const sql = \`...\`` のように変数へ代入する場合、バッククォート開始位置がインデントの深い場所になり、キーワードと揃えるとSQL本体が右側に大きくずれて読みづらくなる。
このケースに限り、**先頭改行 + コード側のインデントに合わせたSQLブロック**を許容する。

判断基準:

- 関数引数として直接渡す（`db.query(\`...\`)` 形式）: 上記の標準スタイルを使う
- `const` で変数に代入してから渡す: 下記の代入スタイルを使ってよい

```typescript
// ✅ Good: 変数代入スタイル（先頭改行 + コードインデントに揃える）
export const buildUserSearchQuery = (
  validFields: FieldId[],
  filters: QueryFilters,
): QueryResult => {
  const {conditions, params} = buildFilterConditions(filters);

  const selectColumns = validFields.map((f) => `${FIELD_TO_COLUMN_MAP[f]} AS ${f}`);

  const sql = `
    SELECT
      ${selectColumns.join(', ')}
    FROM
      users
    INNER JOIN
      profiles
      ON users.id = profiles.user_id
    WHERE 1=1
      AND users.status IS NOT NULL
      ${conditions.join(' ')}
    ORDER BY
      users.created_at DESC
  `;

  return {sql, params};
};
```

このスタイルでは:

- 開始バッククォート直後に改行を入れる（先頭の `\n` は実行時のSQLに含まれるが空白として無視される）
- SQLキーワード・カラム・JOIN句などはコード側のインデントレベル（関数内なら 4 スペース、ネストが深ければさらに +2）に揃える
- カラム/テーブル名はキーワードからさらに 2 スペース内側
- 終了バッククォートはコードのインデントに合わせる

変数代入スタイルを使う場合の注意:

- ログ出力時にSQL先頭・末尾に余分な空白が入る。デバッグ時に整形が必要なら `.trim()` を併用する
- 関数引数として直接渡せる場合は標準スタイルを優先する（中間変数を作らない方が読みやすい）

```typescript
// ❌ Bad: 変数代入スタイルなのにキーワードを左端に貼り付ける（コードと SQL の階層が混在し読みにくい）
const sql = `SELECT
  id,
  name
FROM users
WHERE id = $1`;
```
