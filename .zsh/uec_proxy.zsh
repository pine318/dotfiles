# proxy setting
function set_uec_proxy() {
  UEC_PROXY=proxy.uec.ac.jp:8080
  export http_proxy="http://${UEC_PROXY}"
  export https_proxy="http://${UEC_PROXY}"
  export all_proxy="http://${UEC_PROXY}"
  export no_proxy="localhost,192.168.11.11"
  export HTTP_PROXY="http://${UEC_PROXY}"
  export HTTPS_PROXY="http://${UEC_PROXY}"
  export ALL_PROXY="http://${UEC_PROXY}"
  export NO_PROXY="localhost,192.168.11.11"
  echo "proxy=http://${UEC_PROXY}" >| ~/.curlrc
  echo "http_proxy: http://${UEC_PROXY}" >| ~/.gemrc
  echo -e "use_proxy=on\nhttp_proxy=http://${UEC_PROXY}\nhttps_proxy=http://${UEC_PROXY}\nftp_proxy=http://${UEC_PROXY}" >| ~/.wgetrc
  git config --global http.proxy proxy.uec.ac.jp:8080/
  git config --global https.proxy proxy.uec.ac.jp:8080/
  git config --global url."https://".insteadOf git://
  git config --get http.http://192.168.11.11/gitbucket/.proxy &> /dev/null && git config --global --remove-section http.http://192.168.11.11/gitbucket/
  git config --global http.http://192.168.11.11/gitbucket/.proxy ""
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
  rm -f ~/.gemrc
  rm -f ~/.wgetrc
  rm -f ~/.curlrc
  git config --get http.proxy &> /dev/null && git config --global --remove-section http
  git config --get https.proxy &> /dev/null && git config --global --remove-section https
  git config --get url."https://".insteadOf &> /dev/null && git config --global --remove-section url."https://"
  git config --get http.http://192.168.11.11/gitbucket/.proxy &> /dev/null && git config --global --remove-section http.http://192.168.11.11/gitbucket/
  git config --global http.http://192.168.11.11/gitbucket/.proxy socks5://localhost:1080
}
