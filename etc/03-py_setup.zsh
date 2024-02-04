#!/usr/bin/env zsh

sudo apt -y install build-essential libffi-dev libssl-dev zlib1g-dev liblzma-dev libbz2-dev libreadline-dev libsqlite3-dev pipx

PY_VER=$(pyenv install -l | grep -v '[a-zA-Z]' | grep -e '\s3\.?*' | tail -1 | tr -d ' ')

pyenv install $PY_VER
pyenv global $PY_VER
pip install -U pip
pipx ensurepath
pipx install pip-autoremove
pipx install poetry
exit