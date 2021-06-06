#!/bin/bash

set -e

sudo apt update
sudo apt -y upgrade
sudo apt -y install zsh peco make subversion curl wget git
chsh -s /usr/bin/zsh
exit
