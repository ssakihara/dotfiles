# ローカル DB アクセス規約

ローカルの PostgreSQL（Docker コンテナ）には、Bash から psql で接続する。
MCP サーバーは使わない。

## 接続方法

`~/.pg_service.conf` の `claude` サービスを使う。
接続先・ユーザーはサービス定義に、パスワードは `~/.pgpass` にあるので、コマンドに直接書かない。

```sh
# 既定の DB（postgres）
psql service=claude -c "SELECT ..."

# DB を切り替える
psql "service=claude dbname=<DB名>" -c "SELECT ..."
```

- DB の一覧は `psql service=claude -Atc "SELECT datname FROM pg_database WHERE NOT datistemplate"` で調べる
- スキーマの一覧は `psql service=claude -c '\dn'` で調べる
- 機械的に処理する結果は `-At`（区切りなし・ヘッダーなし）で取得する
- `PGPASSWORD` などの環境変数を上書き・設定しない

## 権限

`claude` ユーザーに許可されているのは SELECT・UPDATE・DELETE だけである。
INSERT・TRUNCATE・DDL は権限エラーになる。
権限が足りない操作が必要な場合は、`postgres` ユーザーで実行せず、ユーザーに依頼する。

## 更新・削除の手順

UPDATE・DELETE はデータを直接変えるので、次の手順を守る。

1. 実行前に、同じ WHERE 句の SELECT で対象件数と内容を確認する
2. 実行する SQL と対象件数をユーザーに示し、承認を得る
3. `BEGIN` 〜 `COMMIT` のトランザクションで実行し、影響件数が想定と違えば `ROLLBACK` する

WHERE 句のない UPDATE・DELETE は実行しない。
