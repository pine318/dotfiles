#!/usr/bin/env zsh

ZSH_RC="${HOME}/.zshrc"

source $ZSH_RC
brew install pyenv
source $ZSH_RC
sudo apt install -y zlib1g-dev libbz2-dev libsqlite3-dev libffi-dev liblzma-dev
exit
