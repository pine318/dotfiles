#!/usr/bin/env zsh

source $ZSH_RC

PY_VER=$(pyenv install -l | grep -v '[a-zA-Z]' | grep -e '\s3\.?*' | tail -1 | tr -d ' ')
ZSH_RC=${HOME}/.zshrc

pyenv install $PY_VER
pyenv global $PY_VER
source $ZSH_RC
pip install -U pip
exit