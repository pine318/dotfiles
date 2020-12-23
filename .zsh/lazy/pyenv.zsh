# pyenv
export PYENV_ROOT="${HOME}/.pyenv"
export PATH="${PYENV_ROOT}/bin:$PATH"
if command -v pyenv 1>/dev/null 2>&1; then
  eval "$(pyenv init -)"
  # remove PATH of pyenv from PATH of brew
  alias brew="env PATH='${PATH/\/home\/${USER}\/\.pyenv\/shims:/}' brew"

  # pip
  if command -v pip 1>/dev/null 2>&1; then
    # zsh completion
    eval "$(pip completion --zsh)"

    # upgrade-all
    alias pip-upgrade-all="pip list -o | tail -n +3 | awk '{ print \$1 }' | xargs pip install -U"

    # pipenv
    if command -v pipenv 1>/dev/null 2>&1; then
      # venv location
      export PIPENV_VENV_IN_PROJECT=true

      # completion
      eval "$(pipenv --completion)"
    fi
  fi
fi