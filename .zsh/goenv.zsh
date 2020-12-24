# goenv setting
export GOENV_ROOT="${HOME}/.goenv"
export GOPATH="${HOME}/go"
export PATH="${GOENV_ROOT}/bin:$GOPATH/bin:$PATH"
if command -v goenv 1>/dev/null 2>&1; then
  eval "$(goenv init -)"
fi