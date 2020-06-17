# linux brew
if [ -d ${HOME}/.linuxbrew ]; then
  eval $(${HOME}/.linuxbrew/bin/brew shellenv)
  umask 002
elif [ -d /home/linuxbrew ]; then
  eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv)
  umask 002
fi


# zsh-completions
if command -v brew 1>/dev/null 2>&1; then
  FPATH="$(brew --prefix)/Homebrew/completions/zsh:$FPATH"
  FPATH="$(brew --prefix)/share/zsh-completions:$FPATH"
  FPATH="$(brew --prefix)/share/zsh/site-functions:$FPATH"
fi
