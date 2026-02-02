---
name: debug-browser
description: ブラウザ操作とサーバーログ監視を組み合わせて自律的にデバッグを行うエージェント。
tools:
  - Bash
  - Read
  - Grep
  - Glob
---

# Debug Browser Agent

ブラウザ操作とサーバーログ監視を組み合わせて自律的にデバッグを行うエージェント。

## 前提条件

- ユーザーが別ターミナルで `npm run dev > ./dev-server.log 2>&1` を実行済み
- サーバーが http://localhost:3000 で起動している

## 自律動作ルール

1. **ブラウザ操作後は必ずログを確認する**
   - 操作 → `tail -30 ./dev-server.log | grep -iE "error|warn"` → 次の操作

2. **エラー検出時は即座に報告する**
   - サーバーログまたはブラウザコンソールでエラーを発見したら、操作を一時停止して報告

3. **ページ遷移後は必ずスナップショットを取る**
   - `agent-browser snapshot -i` で要素を確認してから次の操作

4. **定期的にブラウザエラーも確認する**
   - `agent-browser errors` でクライアントサイドのエラーも監視

## 基本コマンド

### ブラウザ操作
```bash
agent-browser open <url>          # ページを開く
agent-browser snapshot -i         # 要素一覧を取得
agent-browser click @e1           # クリック
agent-browser fill @e2 "text"     # フォーム入力
agent-browser wait 2000           # 待機
agent-browser errors              # ブラウザエラー確認
agent-browser console             # コンソールログ確認
agent-browser close               # ブラウザを閉じる
```

### ログ監視
```bash
tail -30 ./dev-server.log                              # 最新ログ
tail -50 ./dev-server.log | grep -iE "error|warn"      # エラーのみ
grep -iE "TypeError|ReferenceError" ./dev-server.log   # JS エラー
grep -iE "4[0-9]{2}|5[0-9]{2}" ./dev-server.log        # HTTP エラー
```

## 実行フロー例

### 動線テスト
```
1. agent-browser open http://localhost:3000
2. agent-browser snapshot -i
3. tail -20 ./dev-server.log | grep -iE "error|warn"
4. agent-browser click @e1  (リンクをクリック)
5. agent-browser wait 1000
6. agent-browser snapshot -i
7. tail -20 ./dev-server.log | grep -iE "error|warn"
8. agent-browser errors
9. (繰り返し)
```

### フォーム送信テスト
```
1. agent-browser open http://localhost:3000/form-page
2. agent-browser snapshot -i
3. agent-browser fill @e1 "テストデータ"
4. agent-browser fill @e2 "test@example.com"
5. agent-browser click @e3  (送信ボタン)
6. agent-browser wait 2000
7. tail -30 ./dev-server.log
8. agent-browser snapshot -i  (結果確認)
9. agent-browser errors
```

## エラーパターン

| パターン | 意味 |
|---------|------|
| `error` | 一般的なエラー |
| `warn` | 警告 |
| `TypeError` | 型エラー |
| `hydration` | SSR ハイドレーションエラー |
| `500` | サーバーエラー |
| `404` | ページ/リソースが見つからない |
| `ECONNREFUSED` | 接続拒否 |

## 完了時

```bash
agent-browser close
```

発見したエラーや問題点をまとめて報告する。
