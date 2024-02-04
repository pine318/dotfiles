# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi


### Added by matsu
### Export the variable (${PROXY_HOST}, ${PROXY_PORT} and ${NO_PROXY_HOSTS}) in ".zshenv" when running in a proxy environment
if [ -v PROXY_HOST ] && [ -v PROXY_PORT ] && [ -v NO_PROXY_HOSTS ]; then
    source "${ZDOTDIR:-$HOME}/.zsh/proxy.zsh"
    set_proxy ${PROXY_HOST} ${PROXY_PORT} ${NO_PROXY_HOSTS}
fi

### Added by Zinit's installer
if [[ ! -f $HOME/.zinit/bin/zinit.zsh ]]; then
    print -P "%F{33}▓▒░ %F{220}Installing %F{33}DHARMA%F{220} Initiative Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})…%f"
    command mkdir -p "$HOME/.zinit" && command chmod g-rwX "$HOME/.zinit"
    command git clone https://github.com/zdharma-continuum/zinit "$HOME/.zinit/bin" && \
        print -P "%F{33}▓▒░ %F{34}Installation successful.%f%b" || \
        print -P "%F{160}▓▒░ The clone has failed.%f%b"
fi

source "$HOME/.zinit/bin/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# Load a few important annexes, without Turbo
# (this is currently required for annexes)
zinit light-mode for \
    zdharma-continuum/z-a-rust \
    zdharma-continuum/z-a-as-monitor \
    zdharma-continuum/z-a-patch-dl \
    zdharma-continuum/z-a-bin-gem-node

### End of Zinit's installer chunk

# .zsh
ZSHHOME="${ZDOTDIR:-$HOME}/.zsh"
if [ -d $ZSHHOME -a -r $ZSHHOME -a \
	-x $ZSHHOME ]; then
 	for i in $ZSHHOME/*; do
		[[ ${i##*/} = *.zsh ]] &&
		[ \( -f $i -o -h $i \) -a -r $i ] &&
        zinit snippet $i
	done
fi

zinit light-mode for \
    zsh-users/zsh-autosuggestions \
    zdharma-continuum/fast-syntax-highlighting

# powerlevel10k
zinit ice depth=1; zinit light romkatv/powerlevel10k
# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# prezto
zstyle ':prezto:*:*' color 'yes'
zstyle ':prezto:module:terminal' auto-title 'yes'
zstyle ':prezto:module:terminal:window-title' format '%m: %s'
zstyle ':prezto:module:terminal:tab-title' format '%m: %s'
zstyle ':prezto:module:terminal:multiplexer-title' format '%s'
zinit is-snippet for \
    PZT::modules/utility \
    PZT::modules/history \
    PZT::modules/directory \
    PZT::modules/command-not-found \
    PZT::modules/editor \
    PZT::modules/completion/init.zsh \
    PZT::modules/terminal
if type svn > /dev/null 2>&1; then
    zinit ice svn wait as=null lucid; zinit snippet PZTM::archive
fi

# peco
if type peco > /dev/null 2>&1; then
    zinit light mollifier/anyframe
    bindkey '^r' anyframe-widget-put-history
fi

# compleions
zinit wait lucid is-snippet as"completion" for \
    OMZP::docker/completions/_docker \
    OMZP::docker-compose/_docker-compose
zinit wait lucid atload"zicompinit; zicdreplay" blockf for \
    zsh-users/zsh-completions \
    OMZP::kubectl

if [ -z "$ZINIT_LIGHT_MODE" ];then
    # python
    zinit ice atclone'PYENV_ROOT="$PWD" ./libexec/pyenv init - > zpyenv.zsh' \
        atinit'export PYENV_ROOT="$PWD"' atpull"%atclone" \
        as'command' pick'bin/pyenv' src"zpyenv.zsh" nocompile'!'
    zinit light pyenv/pyenv
    zinit wait lucid is-snippet for \
        OMZP::pip
    # added by pipx (https://github.com/pipxproject/pipx)
    export PATH="/home/matsu/.local/bin:$PATH"
    # added by matsu
    export PIPENV_VENV_IN_PROJECT=true

    # nodejs
    zinit ice atclone'NODENV_ROOT="$PWD" ./libexec/nodenv init - > znodenv.zsh' \
        atinit'export NODENV_ROOT="$PWD"' atpull"%atclone" \
        as'command' pick'bin/nodenv' src"znodenv.zsh" nocompile'!'
    zinit light nodenv/nodenv
    zinit ice cloneonly atclone'mkdir -p ${NODENV_ROOT}/plugins && ln -s $PWD ${NODENV_ROOT}/plugins/node-build'
    zinit light nodenv/node-build

    # direnv
    zinit from"gh-r" as"program" mv"direnv* -> direnv" \
        atclone'./direnv hook zsh > zhook.zsh' atpull'%atclone' \
        pick"direnv" src="zhook.zsh" for \
            direnv/direnv

    # compleions
    zinit wait lucid is-snippet as"completion" for \
        OMZP::pip/_pip \
        https://github.com/Homebrew/brew/blob/master/completions/zsh/_brew \
        https://github.com/srijanshetty/zsh-pandoc-completion/blob/master/_pandoc
    zinit wait lucid atload"zicompinit; zicdreplay" blockf for \
        darvid/zsh-poetry \
        sudosubin/zsh-poetry
fi