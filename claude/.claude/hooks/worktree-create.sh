#!/bin/bash
set -euo pipefail

# 汎用 WorktreeCreate hook
# - 既存のworktree/ブランチがあればそのまま再利用（削除・変更しない）
# - 新規の場合のみ git worktree作成 + .envコピー + 依存インストール
# stdin からJSON入力を受け取り、stdoutにworktreeパスを出力する

INPUT=$(cat)

# --- 入力バリデーション ---
if ! NAME=$(echo "$INPUT" | jq -r -e '.name // empty' 2>/dev/null); then
  echo "ERROR: Invalid JSON input or missing 'name' field" >&2
  exit 1
fi
if ! CWD=$(echo "$INPUT" | jq -r -e '.cwd // empty' 2>/dev/null); then
  echo "ERROR: Invalid JSON input or missing 'cwd' field" >&2
  exit 1
fi
if [ -z "$NAME" ] || [ "$NAME" = "null" ] || [ "$NAME" = "." ] || [ "$NAME" = ".." ] || [[ "$NAME" == *"/"* ]]; then
  echo "ERROR: Invalid worktree name: '$NAME'" >&2
  exit 1
fi
if [ ! -d "$CWD" ] || ! git -C "$CWD" rev-parse --git-dir >/dev/null 2>&1; then
  echo "ERROR: cwd is not a valid git repository: $CWD" >&2
  exit 1
fi

# リポジトリルートを取得
REPO_ROOT=$(git -C "$CWD" rev-parse --show-toplevel)

# Worktreeディレクトリ
WORKTREE_DIR="$REPO_ROOT/.claude/worktrees/$NAME"

BRANCH_NAME="claude/$NAME"

# --- 既存チェック: worktreeが既にあればそのまま返す ---
if git -C "$REPO_ROOT" worktree list --porcelain | grep -qxF "worktree $WORKTREE_DIR"; then
  if [ ! -d "$WORKTREE_DIR" ]; then
    echo "ERROR: Git knows about worktree at '$WORKTREE_DIR' but directory is missing. Run 'git worktree prune'." >&2
    exit 1
  fi
  echo "Reusing existing worktree '$NAME'" >&2
  echo "$WORKTREE_DIR"
  exit 0
fi

# --- 既存チェック: ブランチが既にあればエラー ---
if git -C "$REPO_ROOT" show-ref --verify --quiet "refs/heads/$BRANCH_NAME" 2>/dev/null; then
  echo "ERROR: branch '$BRANCH_NAME' already exists. Delete it manually if you want to recreate." >&2
  exit 1
fi

# --- 新規作成 ---
git -C "$REPO_ROOT" worktree add -b "$BRANCH_NAME" "$WORKTREE_DIR" HEAD >&2

# .envファイルコピー（パーミッション保持）
if [ -f "$REPO_ROOT/.env" ] && [ ! -f "$WORKTREE_DIR/.env" ]; then
  cp -p "$REPO_ROOT/.env" "$WORKTREE_DIR/"
  echo "Copied .env to worktree" >&2
fi

# パッケージマネージャー自動検出・依存インストール
install_dependencies() {
  local dir="$1"

  if [ -d "$dir/node_modules" ]; then
    echo "[OK] node_modules already exists, skipping install" >&2
    return
  fi

  pushd "$dir" >/dev/null || return 1

  if [ -f "bun.lockb" ] || [ -f "bun.lock" ]; then
    echo "[INFO] Running bun install..." >&2
    bun install --no-progress >&2
  elif [ -f "pnpm-lock.yaml" ]; then
    echo "[INFO] Running pnpm install..." >&2
    pnpm install --reporter=silent >&2
  elif [ -f "yarn.lock" ]; then
    echo "[INFO] Running yarn install..." >&2
    yarn install --silent >&2
  elif [ -f "package-lock.json" ] || [ -f "package.json" ]; then
    echo "[INFO] Running npm install..." >&2
    npm install --no-progress --prefer-offline >&2
  else
    popd >/dev/null
    return
  fi

  popd >/dev/null
  echo "[OK] Dependencies installed" >&2
}

install_dependencies "$WORKTREE_DIR"

# worktreeパスを出力（これがClaude Codeに返される）
echo "$WORKTREE_DIR"
