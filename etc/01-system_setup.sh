#!/bin/bash

set -e

sudo apt update
sudo apt -y upgrade
sudo apt -y install zsh make curl wget git
chsh -s /usr/bin/zsh
exit
