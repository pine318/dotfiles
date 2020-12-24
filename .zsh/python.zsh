# upgrade-all
alias pip-upgrade-all="pip list -o | tail -n +3 | awk '{ print \$1 }' | xargs pip install -U"

# venv
export PIPENV_VENV_IN_PROJECT=true