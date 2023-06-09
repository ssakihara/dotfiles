#!/bin/bash

cd "$(dirname "${BASH_SOURCE:-$0}")";

git pull origin main;

function doIt() {
  rsync --exclude ".git/" \
        --exclude ".DS_Store" \
        --exclude "macos.sh" \
        --exclude "brew.sh" \
        --exclude "install.sh" \
        --exclude "bootstrap.sh" \
        --exclude "Brewfile" \
        --exclude "README.md" \
        -avh --no-perms . ~;
  # source ~/.zshrc;
  touch .credentials;
}

if [ "$1" == "--force" -o "$1" == "-f" ]; then
  doIt;
else
  read -p "This may overwrite existing files in your home directory. Are you sure? (y/n) " -n 1;
  echo "";
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    doIt;
  fi;
fi;
unset doIt;
