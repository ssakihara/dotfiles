# ghw の cd 後に、リモートと差分がある全ローカルブランチを fast-forward 更新する
_ghw_sync_branches() {
  local repo_dir="$1"

  echo "fetch: リモートとの差分を確認中..."
  if ! git -C "$repo_dir" fetch --all --prune --quiet 2>/dev/null; then
    echo "warning: fetch に失敗したためブランチ更新をスキップします" >&2
    return 0
  fi

  # ブランチ名 → チェックアウト中の worktree パス
  local -A branch_wt=()
  local current_path=""
  local line
  while IFS= read -r line; do
    if [[ "$line" =~ ^worktree\ (.+) ]]; then
      current_path="${match[1]}"
    elif [[ "$line" =~ ^branch\ refs/heads/(.+) ]]; then
      branch_wt[${match[1]}]="$current_path"
    fi
  done < <(git -C "$repo_dir" worktree list --porcelain 2>/dev/null)

  local branch upstream behind ahead wt
  while read -r branch upstream; do
    [[ -z "$upstream" ]] && continue
    behind=$(git -C "$repo_dir" rev-list --count "$branch..$upstream" 2>/dev/null) || continue
    (( behind == 0 )) && continue
    ahead=$(git -C "$repo_dir" rev-list --count "$upstream..$branch" 2>/dev/null) || continue
    if (( ahead > 0 )); then
      echo "skip: $branch はリモートと分岐しています (ahead $ahead / behind $behind)"
      continue
    fi

    wt="${branch_wt[$branch]:-}"
    if [[ -n "$wt" ]]; then
      if [[ -n "$(git -C "$wt" status --porcelain 2>/dev/null)" ]]; then
        echo "skip: $branch は未コミットの変更があります ($wt)"
        continue
      fi
      if git -C "$wt" merge --ff-only --quiet "$upstream" 2>/dev/null; then
        echo "pull: $branch (${behind} commits)"
      else
        echo "skip: $branch の更新に失敗しました"
      fi
    else
      # チェックアウトされていないブランチは、fetch 済みの upstream から
      # 自リポジトリ(.)への refspec 指定で fast-forward 更新する
      if git -C "$repo_dir" fetch . "$upstream:$branch" --quiet 2>/dev/null; then
        echo "pull: $branch (${behind} commits)"
      else
        echo "skip: $branch の更新に失敗しました"
      fi
    fi
  done < <(git -C "$repo_dir" for-each-ref refs/heads --format='%(refname:short) %(upstream:short)')
}

# ghw - GitHub Issue/PR URL から対応する git worktree に cd する
ghw() {
  local url="$1"
  local base_dir="$HOME/workspaces/github.com"

  if [[ ! "$url" =~ ^https://github\.com/([^/]+)/([^/]+)/(issues|pull|pulls)/([0-9]+) ]]; then
    echo "Usage: ghw <github-issue-or-pr-url>" >&2
    return 1
  fi

  local org="${match[1]}"
  local repo="${match[2]}"
  local type="${match[3]}"
  local number="${match[4]}"
  local repo_dir="$base_dir/$org/$repo"

  if [[ ! -d "$repo_dir" ]]; then
    echo "error: リポジトリが見つかりません: $repo_dir" >&2
    return 1
  fi

  local -a wt_paths=()
  local -a wt_branches=()
  local current_path=""

  while IFS= read -r line; do
    if [[ "$line" =~ ^worktree\ (.+) ]]; then
      current_path="${match[1]}"
    elif [[ "$line" =~ ^branch\ refs/heads/(.+) ]]; then
      wt_branches+=("${match[1]}")
      wt_paths+=("$current_path")
    fi
  done < <(git -C "$repo_dir" worktree list --porcelain 2>/dev/null)

  local -a match_paths=()
  local -a match_branches=()

  if [[ "$type" == "pull" || "$type" == "pulls" ]]; then
    local pr_branch
    pr_branch=$(gh pr view "$number" --repo "$org/$repo" --json headRefName --jq '.headRefName' 2>/dev/null)
    if [[ -n "$pr_branch" ]]; then
      for i in {1..${#wt_paths[@]}}; do
        if [[ "${wt_branches[$i]}" == "$pr_branch" ]]; then
          match_paths+=("${wt_paths[$i]}")
          match_branches+=("${wt_branches[$i]}")
        fi
      done
    fi
  fi

  if [[ ${#match_paths[@]} -eq 0 ]]; then
    for i in {1..${#wt_paths[@]}}; do
      if [[ "${wt_branches[$i]}" =~ (^|[^0-9])${number}($|[^0-9]) ]]; then
        match_paths+=("${wt_paths[$i]}")
        match_branches+=("${wt_branches[$i]}")
      fi
    done
  fi

  if [[ ${#match_paths[@]} -eq 0 ]]; then
    if [[ ("$type" == "pull" || "$type" == "pulls") && -n "$pr_branch" ]]; then
      echo "worktreeが見つかりません。git gtr new で作成します: $pr_branch"
      git -C "$repo_dir" gtr new "$pr_branch" --yes || return 1

      local new_path=""
      while IFS= read -r line; do
        if [[ "$line" =~ ^worktree\ (.+) ]]; then
          current_path="${match[1]}"
        elif [[ "$line" =~ ^branch\ refs/heads/(.+) && "${match[1]}" == "$pr_branch" ]]; then
          new_path="$current_path"
          break
        fi
      done < <(git -C "$repo_dir" worktree list --porcelain 2>/dev/null)

      if [[ -n "$new_path" ]]; then
        echo "→ $pr_branch"
        cd "$new_path"
        _ghw_sync_branches "$repo_dir"
        return 0
      fi
      echo "error: worktreeの作成後にパスを取得できませんでした" >&2
      return 1
    fi
    echo "error: #$number に対応するworktreeが見つかりません ($repo)" >&2
    return 1
  fi

  if [[ ${#match_paths[@]} -eq 1 ]]; then
    echo "→ ${match_branches[1]}"
    cd "${match_paths[1]}"
    _ghw_sync_branches "$repo_dir"
  else
    local selected
    selected=$(for i in {1..${#match_paths[@]}}; do
      printf "%s\t%s\n" "${match_paths[$i]}" "${match_branches[$i]}"
    done | fzf --delimiter='\t' --with-nth=2 --prompt="#$number > " | cut -f1)

    if [[ -n "$selected" ]]; then
      cd "$selected"
      _ghw_sync_branches "$repo_dir"
    fi
  fi
}
