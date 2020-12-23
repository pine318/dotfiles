# upgrade-all
alias pip-upgrade-all="pip list -o | tail -n +3 | awk '{ print \$1 }' | xargs pip install -U"

# pipenv
if command -v pipenv 1>/dev/null 2>&1; then
  # venv location
  export PIPENV_VENV_IN_PROJECT=true

  # completion
  eval "$(pipenv --completion)"
fi
