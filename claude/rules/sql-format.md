# SQL フォーマット規約

テンプレートリテラル内のSQLは以下のルールに従うこと:

- SQLキーワード（`SELECT`, `FROM`, `WHERE`, `ORDER BY`, `INSERT INTO`, `UPDATE`, `SET`, `VALUES`, `RETURNING`）はバッククォート開始位置より左に出さない
- キーワードの後は改行し、対象（テーブル名・カラム名・式）を2スペースインデントで記述
- カラムリストは1カラム1行
- WHERE条件が短い場合は1行にまとめてよい
- `const sql = \`...\`` の変数代入時は先頭改行 + コード側インデントに揃えるスタイルを許容

コード例と詳細な判断基準は references/sql-format.md を参照
