# linux brew
if [ -d ${HOME}/.linuxbrew ]; then
  eval $(${HOME}/.linuxbrew/bin/brew shellenv)
  umask 002
elif [ -d /home/linuxbrew ]; then
  eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv)
  umask 002
fi