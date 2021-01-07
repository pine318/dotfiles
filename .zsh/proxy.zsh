# proxy setting
function set_proxy() {
  PROXY_HOST=$1
  PROXY_PORT=$2
  PROXY="${PROXY_HOST}:${PROXY_PORT}"
  NO_PROXY=$3
  export http_proxy=${PROXY}
  export https_proxy=${PROXY}
  export all_proxy=${PROXY}
  export no_proxy=${NO_PROXY}
  export HTTP_PROXY=${PROXY}
  export HTTPS_PROXY=${PROXY}
  export ALL_PROXY=${PROXY}
  export NO_PROXY=${NO_PROXY}
  echo "proxy=${PROXY}" >|~/.curlrc
  echo "http_proxy: ${PROXY}" >|~/.gemrc
  echo -e "use_proxy=on\nhttp_proxy=${PROXY}\nhttps_proxy=${PROXY}\nftp_proxy=${PROXY}" >|~/.wgetrc
  if [ -e ~/.subversion/servers ] && ! grep "^http-proxy-host = " ~/.subversion/servers >/dev/null; then
    echo -e "http-proxy-host = ${PROXY_HOST}\nhttp-proxy-port = ${PROXY_PORT}" >>~/.subversion/servers
  fi
  git config --global http.proxy ${PROXY}
  git config --global https.proxy ${PROXY}
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
  rm -f ~/.curlrc
  rm -f ~/.gemrc
  rm -f ~/.wgetrc
  if [ -e ~/.subversion/servers ]; then
    sed -i -e '/^http-proxy-host = .*/d' ~/.subversion/servers
    sed -i -e '/^http-proxy-port = \d*/d' ~/.subversion/servers
  fi
  git config --get http.proxy &>/dev/null && git config --global --remove-section http
  git config --get https.proxy &>/dev/null && git config --global --remove-section https
}

function set_uec_proxy() {
  UEC_PROXY_HOST="http://proxy.uec.ac.jp"
  UEC_PROXY_PORT="8080"
  YOSHIULAB_NO_PROXY="localhost,192.168.11.1,192.168.11.11"
  set_proxy ${UEC_PROXY_HOST} ${UEC_PROXY_PORT} ${YOSHIULAB_NO_PROXY}
  git config --get http.http://192.168.11.11/gitbucket/.proxy &>/dev/null && git config --global --remove-section http.http://192.168.11.11/gitbucket/
  git config --global http.http://192.168.11.11/gitbucket/.proxy ""
}

function unset_uec_proxy() {
  unset_proxy
  git config --get http.http://192.168.11.11/gitbucket/.proxy &>/dev/null && git config --global --remove-section http.http://192.168.11.11/gitbucket/
  git config --global http.http://192.168.11.11/gitbucket/.proxy socks5://localhost:1080
}