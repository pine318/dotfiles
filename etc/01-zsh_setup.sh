#!/bin/bash

set -e

sudo apt update
sudo apt -y upgrade
sudo apt -y install zsh peco
chsh -s /usr/bin/zsh
exit
