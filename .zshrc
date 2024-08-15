dotfiles_home="$HOME/dotfiles"

if test -n "$(git -C ${dotfiles_home} status --porcelain)" ||
  ! git -C ${dotfiles_home} diff --exit-code --stat --cached origin/main > /dev/null ; then
  echo -e "\e[36m=== DOTFILES IS DIRTY ===\e[m"
  echo -e "\e[33mThe dotfiles have been changed.\e[m"
  echo -e "\e[33mPlease update them with the following command.\e[m"
  echo "  cd ${dotfiles_home}"
  echo "  git add ."
  echo "  git commit -m \"update dotfiles\""
  echo "  git push origin main"
  echo -e "\e[33mor\e[m"
  echo "  git push origin main"
  echo -e "\e[36m=========================\e[m"
fi

### Added by Zinit's installer
if [[ ! -f $HOME/.zinit/bin/zinit.zsh ]]; then
    print -P "%F{33}▓▒░ %F{220}Installing %F{33}DHARMA%F{220} Initiative Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})…%f"
    command mkdir -p "$HOME/.zinit" && command chmod g-rwX "$HOME/.zinit"
    command git clone https://github.com/zdharma-continuum/zinit "$HOME/.zinit/bin" && \
        print -P "%F{33}▓▒░ %F{34}Installation successful.%f%b" || \
        print -P "%F{160}▓▒░ The clone has failed.%f%b"
fi

source "$HOME/.zinit/bin/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# Load a few important annexes, without Turbo
# (this is currently required for annexes)
zinit light-mode for \
    zdharma-continuum/z-a-rust \
    zdharma-continuum/z-a-as-monitor \
    zdharma-continuum/z-a-patch-dl \
    zdharma-continuum/z-a-bin-gem-node

### End of Zinit's installer chunk

# 補完
zinit light zsh-users/zsh-autosuggestions

# シンタックスハイライト
zinit light zdharma-continuum/fast-syntax-highlighting

# Gitの変更状態がわかる
zinit light supercrabtree/k

# alias
alias lg="ll | grep "
alias ..="cd .."
alias ..2="cd ../.."
alias ..3="cd ../../.."
alias c="pbcopy"
alias d="docker"
alias m="mkdir"
alias r="source ~/.zshrc && echo 'zshrc reload'"
alias g="git"
alias grm="git branch --merged | grep -v master | xargs git branch -d"
alias grmm="git branch --merged | grep -v main | xargs git branch -d"
alias dc="docker-compose"
alias flutter="fvm flutter"
alias dart="fvm dart"
alias -g A='| awk'
alias -g C='| pbcopy'
alias -g G='| grep --color=auto'

if [[ $(command -v eza) ]]; then
    alias e='eza --icons --git'
    alias l=e
    alias ls=e
    alias ea='eza -a --icons --git'
    alias la=ea
    alias ee='eza -aahl --icons --git'
    alias ll=ee
    alias et='eza -T -L 3 -a -I "node_modules|.git|.cache" --icons'
    alias lt=et
    alias eta='eza -T -a -I "node_modules|.git|.cache" --color=always --icons | less -r'
    alias lta=eta
    alias l='clear && ls'
fi

# zsh
# メモリに保存される履歴の件数
export HISTSIZE=1000
# 履歴ファイルに保存される履歴の件数
export SAVEHIST=100000
# 重複を記録しない
setopt hist_ignore_dups
# 開始と終了を記録
setopt EXTENDED_HISTORY

# 自作コマンド
export PATH="$HOME/.bin":$PATH

# flutter
export PATH="$HOME/.pub-cache/bin:$PATH"

# java
export PATH="$(brew --prefix)/opt/openjdk/bin:$PATH"
export CPPFLAGS="-I$(brew --prefix)/opt/openjdk/include"

# gcloud
source "$(brew --prefix)/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.zsh.inc"
source "$(brew --prefix)/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.zsh.inc"

# starship
eval "$(starship init zsh)"

# volta
export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin":$PATH

# Go
export PATH="$HOME/go/bin:$PATH"

# ruby
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"

# python3
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
export npm_config_python="$HOME/.pyenv/shims/python3"
eval "$(pyenv init -)"

# GitHub
export NODE_AUTH_TOKEN=`gh auth token`

# 機密情報
source "$HOME/.credentials"
