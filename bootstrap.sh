#!/bin/bash

cd "$(dirname "${BASH_SOURCE:-$0}")";

git pull origin main;

stow -t ~ bin claude ghostty git starship zsh;
