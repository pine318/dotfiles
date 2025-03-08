function set_proxy() {
  local PROXY_HOST=$1
  local PROXY_PORT=$2
  local NO_PROXY=$3
  local PROXY="http://${PROXY_HOST}:${PROXY_PORT}"

  export http_proxy=${PROXY}
  export https_proxy=${PROXY}
  export all_proxy=${PROXY}
  export no_proxy=${NO_PROXY}
  export HTTP_PROXY=${PROXY}
  export HTTPS_PROXY=${PROXY}
  export ALL_PROXY=${PROXY}
  export NO_PROXY=${NO_PROXY}

  local SVN_CONFIG=~/.subversion/servers
  if [ -e "$SVN_CONFIG" ] && ! grep -q "^http-proxy-host = " "$SVN_CONFIG"; then
    {
      echo "http-proxy-host = ${PROXY_HOST}"
      echo "http-proxy-port = ${PROXY_PORT}"
      echo "http-proxy-exception = ${NO_PROXY}"
    } >> "$SVN_CONFIG"
  fi
}

function unset_proxy() {
  unset http_proxy https_proxy all_proxy no_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY NO_PROXY
  
  local SVN_CONFIG=~/.subversion/servers
  if [ -e "$SVN_CONFIG" ]; then
    sed -i -e '/^http-proxy-host = .*/d' -e '/^http-proxy-port = [0-9]*/d' -e '/^http-proxy-exception = .*/d' "$SVN_CONFIG"
  fi
}

### Export the variable(${PROXY_HOST}, ${PROXY_PORT} and ${NO_PROXY_HOSTS}) in ".zshenv" when running in a proxy environment
# export PROXY_HOST="proxy.example.com"
# export PROXY_PORT="8080"
# export NO_PROXY_HOSTS="127.0.0.1,localhost,192.168.11.1"