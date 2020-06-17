#
# Executes commands at the start of an interactive session.
#
# Authors:
#   Sorin Ionescu <sorin.ionescu@gmail.com>
#

# Source Prezto.
if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
fi

# Customize to your needs...

ZSHHOME="${ZDOTDIR:-$HOME}/.zsh"

if [ -d $ZSHHOME -a -r $ZSHHOME -a \
	-x $ZSHHOME ]; then
 	for i in $ZSHHOME/*; do
		[[ ${i##*/} = *.zsh ]] &&
		[ \( -f $i -o -h $i \) -a -r $i ] && . $i
	done
fi

# completion
autoload -Uz compinit && compinit -u