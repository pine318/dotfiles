#!/usr/bin/env zsh

brew install zsh-completions
rm -f "${HOME}/.zcompdump"; compinit
exit