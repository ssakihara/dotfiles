---
name: e2e-testing
description: エージェントが「修正完了」と報告した後に、その修正が本当に効いているかを agent-browser CLI でローカルの開発サーバーをブラウザ操作して検証する。完了報告と git diff から確認項目を作り、項目ごとの OK / NG とデグレの有無、NG の原因と修正案をチャットで報告する。/e2e-testing コマンドで明示的に呼び出したときだけ使う。
argument-hint: '[URL | ポート番号]'
disable-model-invocation: true
allowed-tools: Bash Read Grep Glob AskUserQuestion
---

# 修正後のブラウザ検証

エージェントの「修正完了」報告を鵜呑みにせず、ローカルの開発サーバーを agent-browser で実際に操作して**直っているかを確かめる**。
コードの修正は行わない。
NG の報告はそのまま修正担当のエージェントに渡される想定なので、推測ではなく観測した事実（エラー文・ステータスコード・該当コード行）を根拠に書くこと。

## 1. 確認項目を作る

「何を直したはずか」を次の2つから集める。

- **完了報告**: この会話の中にあるエージェントの完了報告・ユーザーが最初に伝えた不具合や要望
- **差分**: `git diff HEAD` で未コミットの変更を見る。
  空なら `git log -1 --stat` と `git show HEAD` で直近のコミットを見る

完了報告と差分の内容が食い違う場合（報告にある修正が差分にない等）は、それ自体を NG 候補として記録する。
報告だけを信じると、実際には入っていない修正を OK と判定してしまうため。

集めた内容を、ブラウザで判定できる確認項目に落とす。
1項目は「どの画面で・何をすると・どうなるべきか」が明確な粒度にする。

```text
1. /login でメールとパスワードを入力して送信すると /mypage に遷移する
2. /login で空のまま送信するとエラーメッセージが表示される
```

会話にも差分にも手がかりがなく確認項目を作れない場合は、`AskUserQuestion` で何を確認したいかを聞く。

## 2. デグレ確認の対象を決める

変更したファイル（コンポーネント・composable・API ハンドラ・ストア等）を `rg` で検索し、それを使っている他の画面を洗い出す。
確認項目の画面とは別に、それらの画面もデグレ確認の対象にする。
対象が多すぎる場合は、変更箇所に近いものから最大5画面程度に絞り、残りは報告の「未確認」に書く。

## 3. 対象サーバーを決める

引数 `$ARGUMENTS` からベース URL を決める。

| 引数 | 扱い |
| --- | --- |
| `http://localhost:3000/login` などの URL | そのオリジンをベース URL にする |
| `3000` / `:3000` などのポート番号 | `http://localhost:<ポート>` にする |
| 省略 | 起動中のサーバーを検出する（下記） |

省略時は `lsof -nP -iTCP -sTCP:LISTEN` で LISTEN 中のポートを列挙し、node / bun / deno / python / ruby / php / java など開発サーバーらしいプロセスに絞る。
候補が1つならそれを使い、複数あれば `AskUserQuestion` で選んでもらう。
候補がなければ「サーバーが起動していない」と報告して終了する。
起動コマンドを勝手に実行しないのは、ユーザーが意図した環境変数やモードで起動しているかがわからないため。

引数で指定された場合も `lsof -nP -iTCP:<ポート> -sTCP:LISTEN` で LISTEN しているかを確認する。
LISTEN していなければブラウザ操作に進まず、その旨を報告して終了する。
応答の確認は手順4の `agent-browser open` の結果で行う（curl はユーザー設定で禁止されているため使わない）。

修正がホットリロードされず古いコードのまま動いていると、正しい修正でも NG に見える。
NG が出たときに疑えるよう、サーバーの起動時刻（`ps -o lstart= -p <PID>`）と変更ファイルの更新時刻を控えておく。

## 4. ブラウザを開く

他のエージェントや人が使っているブラウザを奪わないよう、必ず専用セッションで操作する。

```bash
agent-browser session id --scope worktree --prefix e2e-testing   # 例: e2e-testing-11fe14a563f7
agent-browser --session <セッション名> open <URL>
```

Bash の呼び出しをまたぐと環境変数は消えるため、以降のすべてのコマンドに `--session <セッション名>` を直接書く。
以下のコマンド例では `--session` を省略しているが、実行時は必ず付ける。

コマンドの詳細が必要になったら `agent-browser skills get core` を参照する。
フラグを推測で組み立てるより確実なため。

### 認証が必要な場合（Firebase 等）

ログイン画面に飛ばされたら、認証状態を保存したプロファイルで開き直す。
`--profile` は起動時にしか効かないため、先にセッションを閉じる。

```bash
agent-browser close
agent-browser --profile ~/.chrome-profiles/developer open <URL>
```

それでもログイン画面なら、認証が必要な項目は「未確認」とし、ユーザーに以下で手動ログインしてもらうよう報告で案内する。

```bash
agent-browser --profile ~/.chrome-profiles/developer --headed open <URL>
```

## 5. 確認項目を検証する

項目ごとに、操作前にバッファを空にしてから操作する。
どの項目でエラーが出たかを切り分けるため。

```bash
agent-browser console --clear
agent-browser errors --clear
agent-browser network requests --clear
```

操作は snapshot で ref を取ってから行う。
ref はページが変わると無効になるので、遷移や送信のたびに取り直す。

```bash
agent-browser snapshot -i
agent-browser fill @e2 "test@example.com"
agent-browser click @e3
agent-browser snapshot -i
```

操作後、次の観点を確認して OK / NG を判定する。
期待どおりの画面になっていても、JS エラーや 4xx / 5xx のリクエストが出ていれば NG とする。

| 観点 | コマンド |
| --- | --- |
| 期待した結果になったか | `agent-browser get url` / `agent-browser get text <sel>` / `agent-browser snapshot -i` |
| 画面の見た目 | `agent-browser screenshot <scratchpad>/xxx.png` を撮り、Read で確認する |
| JS 例外・未捕捉エラー | `agent-browser errors` |
| console の warn / error | `agent-browser console` |
| 失敗したリクエスト | `agent-browser network requests --status 400-599`、詳細は `agent-browser network request <id>` |
| 状態 | `agent-browser eval '<js>'` / `agent-browser storage local` |

スクリーンショットはプロジェクトを汚さないよう scratchpad ディレクトリに保存する。

## 6. デグレを確認する

手順2で決めた画面を開き、表示・JS エラー・失敗したリクエストを確認する。
変更した部品が使われている箇所に操作があれば、それも1回は動かす。

## 7. NG の原因を調べる

NG の項目だけ、観測したエラーを手がかりに原因箇所を特定する。

- エラーメッセージ・スタックトレースのファイル名や関数名を `rg` で検索する
- 失敗した API のパスを `rg` で検索し、サーバー側のハンドラを読む
- 手順1の差分と照らし、修正が不足しているのか・修正が別の箇所を壊したのかを切り分ける
- 手順3で控えた時刻から、古いコードのまま動いている可能性がないか確認する

サーバー側のエラーが疑われ、ログが自分から見えないときは、ターミナルのログを貼ってもらうよう報告の中でお願いする。
原因を断定できない場合は、可能性の高い順に仮説を挙げ、それぞれの根拠と確かめ方を書く。

## 8. 後片付け

報告の前にブラウザを閉じる。

```bash
agent-browser close
```

## 9. 報告

チャットで以下の形式で報告する。
OK の項目も一覧に残すのは、ユーザーが「どこまで確認済みか」を判断できるようにするため。

```markdown
## 検証結果: NG あり（OK 2 / NG 1 / 未確認 1）

- 対象: http://localhost:3000
- 検証した修正: ログイン後に /mypage へ遷移しない不具合の修正

### 確認項目

| # | 確認項目 | 結果 | 根拠 |
| --- | --- | --- | --- |
| 1 | /login で送信すると /mypage に遷移する | OK | 遷移後 URL が /mypage |
| 2 | 空送信でエラーメッセージが出る | NG | メッセージが出ず、console に TypeError |
| 3 | /signup が従来どおり表示される（デグレ確認） | OK | エラー・失敗リクエストなし |
| 4 | /mypage のプロフィール編集 | 未確認 | 要ログイン（プロファイルが期限切れ） |

### NG の原因と修正案

#### #2 空送信でエラーメッセージが出る
- 再現手順: 1. /login を開く 2. 何も入力せず「ログイン」を押す
- 観測: `TypeError: Cannot read properties of undefined (reading 'trim')`
- 原因箇所: `components/LoginForm.vue:42` で email が undefined のまま trim している
- 修正案: 初期値を空文字にする、または trim 前に undefined を判定する

### 未確認・要ユーザー確認

- #4: `agent-browser --profile ~/.chrome-profiles/developer --headed open http://localhost:3000/login` で手動ログインしてから再実行してください
```

見出しの判定は、NG が1件でもあれば「NG あり」、NG がなく未確認があれば「未確認あり」、すべて OK なら「すべて OK」とする。
該当がないセクションは `- なし` と書く。
