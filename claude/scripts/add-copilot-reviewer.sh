#!/bin/bash
# PR のレビュワーに GitHub Copilot を追加する。
# 使い方: add-copilot-reviewer.sh [<PR番号> | <PR URL> | <ブランチ名>]
# 引数を省略すると現在のブランチの PR が対象になる (gh pr view と同じ解決規則)。
set -euo pipefail

readonly BOT_LOGIN='copilot-pull-request-reviewer'

# gh pr edit --add-reviewer や REST API では成功扱いのまま追加されないため GraphQL を使う
bot_id=$(gh api "users/${BOT_LOGIN}[bot]" --jq '.node_id')
pr_id=$(gh pr view "$@" --json id --jq '.id')

# union: true を省略すると既存のレビュワーが置き換えられる
# shellcheck disable=SC2016 # $pr / $bot は GraphQL の変数
logins=$(gh api graphql \
  -f query='
    mutation($pr: ID!, $bot: ID!) {
      requestReviews(input: { pullRequestId: $pr, botIds: [$bot], union: true }) {
        pullRequest {
          reviewRequests(first: 20) {
            nodes { requestedReviewer { ... on Bot { login } } }
          }
        }
      }
    }' \
  -f pr="$pr_id" \
  -f bot="$bot_id" \
  --jq '.data.requestReviews.pullRequest.reviewRequests.nodes[].requestedReviewer.login // empty')

if ! grep -qx "$BOT_LOGIN" <<<"$logins"; then
  echo "レビュー依頼に ${BOT_LOGIN} が含まれていない (Copilot レビューが無効なリポジトリや GitHub Enterprise Server では追加できない)" >&2
  exit 1
fi

echo "Copilot をレビュワーに追加した: $(gh pr view "$@" --json url --jq '.url')"
