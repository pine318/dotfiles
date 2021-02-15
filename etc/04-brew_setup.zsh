#!/usr/bin/env zsh

sudo apt -y install build-essential curl file git
sudo localedef -f UTF-8 -i en_US en_US
sudo localedef -f UTF-8 -i ja_JP ja_JP
sudo -K
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
source ${HOME}/.zshrc
brew bundle
exit