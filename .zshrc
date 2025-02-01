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
# wsl2-ssh-agent
if [[ "$(uname -r)" == *microsoft* ]]; then
    if [ ! -d $HOME/.local/bin/ ]; then
        mkdir -p $HOME/.local/bin/
    fi
    if [ ! -e $HOME/.local/bin/wsl2-ssh-agent ]; then
        curl -L https://github.com/mame/wsl2-ssh-agent/releases/latest/download/wsl2-ssh-agent -o $HOME/.local/bin/wsl2-ssh-agent
        chmod u+x $HOME/.local/bin/wsl2-ssh-agent
    fi
    eval $($HOME/.local/bin/wsl2-ssh-agent)
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

# ohmyzsh
zinit is-snippet for \
    OMZP::universalarchive \
    OMZP::extract

# peco
zinit ice from"gh-r" as"program" pick"*/peco"
    zinit light "peco/peco"
zinit light mollifier/anyframe
bindkey '^r' anyframe-widget-put-history

# mise
zinit ice from"gh-r" as"program" pick"mise" mv"mise* -> mise" \
    atclone"~/.zinit/plugins/jdx---mise/mise activate zsh > zmise.zsh; ~/.zinit/plugins/jdx---mise/mise ./mise completion zsh > _mise" \
    atpull"%atclone" src"zmise.zsh"
    zinit light "jdx/mise"

# compleions
zinit wait lucid is-snippet as"completion" for \
    https://github.com/docker/cli/blob/master/contrib/completion/zsh/_docker \
    OMZP::docker-compose/_docker-compose
zinit wait lucid atload"zicompinit; zicdreplay" blockf for \
    zsh-users/zsh-completions \
    OMZP::kubectl

if [ -z "$ZINIT_LIGHT_MODE" ] || [ "$ZINIT_LIGHT_MODE" != "true" ];then
    # uv(python)
    zinit ice from"gh-r" as"program" pick"*/uv" mv"uv* -> uv" atclone"./uv/uv generate-shell-completion zsh > _uv" atpull"%atclone"
        zinit light "astral-sh/uv"
    export PATH="/home/matsu/.local/bin:$PATH"
    zinit light matthiasha/zsh-uv-env

    # compleions
    zinit wait lucid is-snippet as"completion" for \
        https://github.com/Homebrew/brew/blob/master/completions/zsh/_brew \
        https://github.com/srijanshetty/zsh-pandoc-completion/blob/master/_pandoc
fi