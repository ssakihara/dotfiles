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
    echo "error: #$number に対応するworktreeが見つかりません ($repo)" >&2
    return 1
  fi

  if [[ ${#match_paths[@]} -eq 1 ]]; then
    echo "→ ${match_branches[1]}"
    cd "${match_paths[1]}"
  else
    local selected
    selected=$(for i in {1..${#match_paths[@]}}; do
      printf "%s\t%s\n" "${match_paths[$i]}" "${match_branches[$i]}"
    done | fzf --delimiter='\t' --with-nth=2 --prompt="#$number > " | cut -f1)

    if [[ -n "$selected" ]]; then
      cd "$selected"
    fi
  fi
}
