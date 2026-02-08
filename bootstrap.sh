#!/bin/bash

cd "$(dirname "${BASH_SOURCE:-$0}")";

git pull origin main;

stow -t ~ bin claude editorconfig ghostty git starship zsh;
