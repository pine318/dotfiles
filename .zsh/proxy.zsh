# proxy setting
function set_proxy() {
  PROXY_HOST=$1
  PROXY_PORT=$2
  PROXY="http://${PROXY_HOST}:${PROXY_PORT}"
  NO_PROXY=$3
  export http_proxy=${PROXY}
  export https_proxy=${PROXY}
  export all_proxy=${PROXY}
  export no_proxy=${NO_PROXY}
  export HTTP_PROXY=${PROXY}
  export HTTPS_PROXY=${PROXY}
  export ALL_PROXY=${PROXY}
  export NO_PROXY=${NO_PROXY}
  if [ -e ~/.subversion/servers ] && ! grep "^http-proxy-host = " ~/.subversion/servers >/dev/null; then
    echo -e "http-proxy-host = ${PROXY_HOST}\nhttp-proxy-port = ${PROXY_PORT}\nhttp-proxy-exception = ${NO_PROXY}" >>~/.subversion/servers
  fi
}

function unset_proxy() {
  unset http_proxy
  unset https_proxy
  unset all_proxy
  unset no_proxy
  unset HTTP_PROXY
  unset HTTPS_PROXY
  unset ALL_PROXY
  unset NO_PROXY
  if [ -e ~/.subversion/servers ]; then
    sed -i -e '/^http-proxy-host = .*/d' ~/.subversion/servers
    sed -i -e '/^http-proxy-port = \d*/d' ~/.subversion/servers
    sed -i -e '/^http-proxy-exception = .*/d' ~/.subversion/servers
  fi
}

### Export the variable(${PROXY_HOST}, ${PROXY_PORT} and ${NO_PROXY_HOSTS}) in ".zshenv" when running in a proxy environment
# export PROXY_HOST="proxy.example.com"
# export PROXY_PORT="8080"
# export NO_PROXY_HOSTS="127.0.0.1,localhost,192.168.11.1"