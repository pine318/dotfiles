#!/usr/bin/env zsh

pip list -o | tail -n +3 | awk '{ print $1 }' | xargs pip install -U
pip install pip-autoremove
pip install pipenv
exit