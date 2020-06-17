#!/usr/bin/env zsh

sudo apt -y install build-essential curl file git
sudo -K
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
source "${HOME}/.zshrc"
brew tap beeftornado/rmtree
exit