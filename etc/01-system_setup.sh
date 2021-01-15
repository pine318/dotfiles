#!/bin/bash

set -e

sudo apt update
sudo apt -y upgrade
sudo apt -y install zsh peco make subversion
# python
sudo apt -y install build-essential libffi-dev libssl-dev zlib1g-dev liblzma-dev libbz2-dev libreadline-dev libsqlite3-dev git
chsh -s /usr/bin/zsh
exit
