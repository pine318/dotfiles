# linux brew
if [ -d ${HOME}/.linuxbrew ]; then
  eval $(${HOME}/.linuxbrew/bin/brew shellenv)
  umask 002
elif [ -d /home/linuxbrew ]; then
  eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv)
  umask 002
fi

# PATH for linuxbrew
alias brew="PATH=/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games: brew"