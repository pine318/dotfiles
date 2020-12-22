# nodenv
export NODENV_ROOT="${HOME}/.nodenv"
export PATH="${NODENV_ROOT}/bin:$PATH"

if command -v nodenv 1>/dev/null 2>&1; then
  eval "$(nodenv init -)"
  # remove PATH of nodenv from PATH of brew
  alias brew="env PATH='${PATH/\/home\/${USER}\/\.nodenv\/shims:/}' brew"
fi
