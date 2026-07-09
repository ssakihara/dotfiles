# SQL フォーマット規約 — 詳細ガイド

## 標準スタイル（関数引数に直接渡す場合）

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

## 動的に組み立てる部分のスタイル

`.join()` 等で動的にSQL条件を組み立てる場合、結合文字列に改行やインデント用のスペースを含めない。
`' AND '` のようにスペース区切りで結合すること。
キーワード後の改行・インデントの規約は**テンプレートリテラルに直書きするSQLにのみ適用**し、動的に組み立てる部分には適用しない。

理由:

- 結合文字列に改行やインデントを埋め込むと、呼び出し側のインデント深度に依存した整形になり壊れやすい
- 実行時のSQLの見た目を整える効果は薄く、コードの可読性を下げる

```typescript
// ✅ Good: スペース区切りで結合する
const whereClause = conditions.join(' AND ');
const orderByClause = sortColumns.join(', ');

const sql = `
  SELECT
    id,
    name
  FROM
    users
  WHERE ${whereClause}
  ORDER BY ${orderByClause}
`;

// ❌ Bad: 結合文字列に改行・インデントを含める
const whereClause = conditions.join('\n      AND ');
const orderByClause = sortColumns.join(',\n      ');
```
