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
alias flutter="fvm flutter"
alias dart="fvm dart"
alias dclaude="docker sandbox run claude"
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

# ghq
function ghq-fzf() {
  local src=$(ghq list | fzf --preview "bat --color=always --style=header,grid --line-range :80 $(ghq root)/{}/README.*")
  if [ -n "$src" ]; then
    BUFFER="code $(ghq root)/$src"
    zle accept-line
  fi
  zle -R -c
}
zle -N ghq-fzf
bindkey '^g' ghq-fzf

# zsh
# メモリに保存される履歴の件数
export HISTSIZE=1000
# 履歴ファイルに保存される履歴の件数
export SAVEHIST=100000
# GSSAPI認証を無効化(psqlの起動を速くするため)
export PGGSSENCMODE=disable
# 重複を記録しない
setopt hist_ignore_dups
# 開始と終了を記録
setopt EXTENDED_HISTORY

# 自作コマンド
export PATH="$HOME/.bin":$PATH

# Claude Code
export PATH="$HOME/.local/bin:$PATH"

# flutter
export PATH="$HOME/.pub-cache/bin:$PATH"

# java
# export PATH="$(brew --prefix)/opt/openjdk@17/bin:$PATH"
# export CPPFLAGS="-I$(brew --prefix)/opt/openjdk/include"
# export JAVA_HOME="$(brew --prefix)/opt/openjdk/"
export JAVA_HOME="$HOME/OpenJDK/jdk-18.0.2.jdk/Contents/Home"

# gcloud
export CLOUDSDK_PYTHON="$HOME/.local/bin/python3"
source "$(brew --prefix)/Caskroom/gcloud-cli/latest/google-cloud-sdk/path.zsh.inc"
source "$(brew --prefix)/Caskroom/gcloud-cli/latest/google-cloud-sdk/completion.zsh.inc"

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

# psql
export PATH="/opt/homebrew/opt/libpq/bin:$PATH"

# 機密情報
source "$HOME/.credentials"
