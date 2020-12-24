# port forwarding
function pf() {
  ssh -D1080 -N -f $1 >& /dev/null
}
compdef _host pf
function pfkill() {
  pf_pid=$(ps -ef | grep "ssh -D1080 -N -f $1" | grep -v grep | awk '{print $2}')
  kill $pf_pid
}
compdef _host pfkill

# ssh-agent
SSH_DIR="${HOME}/.ssh"
SSH_AGENT_FILE="${SSH_DIR}/ssh_agent"

# WSLでない，かつssh-agentが存在するならば
if [ ! -f /proc/sys/fs/binfmt_misc/WSLInterop ] && command -v ssh-agent 1>/dev/null 2>&1; then
  # ssh-agent プロセスが存在しないならば、これを起動しつつ、設定をファイルに出力
  if [ -d $SSH_DIR ] && [ $( ps -ef | grep ssh-agent | grep -v grep | wc -l ) -eq 0 ]; then
    ssh-agent >| $SSH_AGENT_FILE
    # SSH経由のログインでないならば，設定ファイルを読み込み，SSH_DIR 配下にある id_rsa という名前のファイルを ssh-add
    if [ ! -n "$SSH_CONNECTION" ]; then
      source $SSH_AGENT_FILE >& /dev/null
      find $SSH_DIR -name id_rsa | xargs ssh-add >& /dev/null
    fi
  fi

  # プロセス存在時についても，SSH経由のログインでないならば，設定ファイルを読み込む
  if [ ! -n "$SSH_CONNECTION" ]; then
    [ -f $SSH_AGENT_FILE ] && source $SSH_AGENT_FILE >& /dev/null
  fi
fi