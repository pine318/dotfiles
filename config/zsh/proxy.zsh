# プロキシ（zshrc から読み込む）
#
# 設定ファイル: ~/.config/proxy（端末ごと。リポジトリでは管理しない）
#     # 名前  URL（先頭が既定のプロキシ）
#     main   http://proxy1.corp.example:8080
#     alt    http://proxy2.corp.example:8080
#     no_proxy  localhost,127.0.0.1,.corp.example
#   ログイン時の環境にプロキシ（WSL では Windows の設定 = autoProxy）があれば、"system" として候補の最後に加える
#   設定ファイルが無ければ "system" が既定になる
#
# 状態: 全シェル共通。$XDG_RUNTIME_DIR/proxy/state に保存し、再起動すると自動に戻る
#   自動 : 既定のプロキシに接続できれば使い、できなければ使わない（判定結果は 60 秒キャッシュ）
#   off  : 使わない
#   名前 : そのプロキシを使う
#   各シェルはプロンプトを表示するたびに状態を確認して追従する
#
# コマンド: proxy [status|list|use 名前|on|off|auto|run 名前 -- コマンド|test [URL]|edit]

typeset -g PROXY_CONFIG=${XDG_CONFIG_HOME:-$HOME/.config}/proxy
typeset -g PROXY_STATE_DIR=${XDG_RUNTIME_DIR:-${TMPDIR:-/tmp}/proxy-$UID}/proxy
typeset -g PROXY_AUTO_TTL=60
typeset -g PROXY_TEST_URL=https://github.com
zmodload -F zsh/datetime p:EPOCHSECONDS

# ログイン時の環境にあったプロキシを、最初のシェルで一度だけ記録する（子シェルには環境変数で引き継ぐ）
if (( ! ${+PROXY_SYSTEM} )); then
  export PROXY_SYSTEM=${HTTPS_PROXY:-${https_proxy:-${HTTP_PROXY:-${http_proxy:-}}}}
  export PROXY_SYSTEM_NO_PROXY=${NO_PROXY:-${no_proxy:-}}
fi

# 設定を読み込む: _proxy_names（順序付きの名前）・_proxy_url（名前 → URL）・_proxy_no（除外先）
function _proxy_load() {
  typeset -ga _proxy_names=()
  typeset -gA _proxy_url=()
  typeset -g _proxy_no=''
  local name url rest
  if [[ -r $PROXY_CONFIG ]]; then
    while read -r name url rest; do
      [[ -z $name || $name == \#* || -z $url ]] && continue
      if [[ $name == no_proxy ]]; then
        _proxy_no=$url
      else
        _proxy_names+=($name)
        _proxy_url[$name]=$url
      fi
    done <$PROXY_CONFIG
  fi
  if [[ -n $PROXY_SYSTEM ]] && (( ! ${+_proxy_url[system]} )); then
    _proxy_names+=(system)
    _proxy_url[system]=$PROXY_SYSTEM
    [[ -z $_proxy_no ]] && _proxy_no=$PROXY_SYSTEM_NO_PROXY
  fi
  [[ -n $_proxy_no ]] || _proxy_no=localhost,127.0.0.1,::1
}

# URL からホストとポートを取り出す（reply=(ホスト ポート)）
function _proxy_hostport() {
  local hp=${${1#*://}%%/*}
  hp=${hp##*@}
  reply=(${hp%:*} ${${hp##*:}:-8080})
}

# 環境変数に反映する（名前が空なら解除）
function _proxy_apply() {
  local name=$1
  if [[ -n $name && -n ${_proxy_url[$name]:-} ]]; then
    local url=${_proxy_url[$name]}
    export http_proxy=$url https_proxy=$url HTTP_PROXY=$url HTTPS_PROXY=$url
    export no_proxy=$_proxy_no NO_PROXY=$_proxy_no
    export PROXY_NAME=$name
    # 既定以外のプロキシを使っているときだけプロンプトに表示する（starship の env_var.PROXY_LABEL）
    if [[ $name != $_proxy_names[1] ]]; then
      export PROXY_LABEL=$name
    else
      unset PROXY_LABEL
    fi
    # sudo 経由のコマンド（apt など）にもプロキシ設定だけを引き継ぐ
    alias sudo='sudo --preserve-env=http_proxy,https_proxy,no_proxy,HTTP_PROXY,HTTPS_PROXY,NO_PROXY '
  else
    unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY no_proxy NO_PROXY PROXY_NAME PROXY_LABEL
    alias sudo='sudo '
  fi
}

# 自動判定: 既定のプロキシに接続できればその名前を出力する
function _proxy_auto() {
  local cache=$PROXY_STATE_DIR/auto now=$EPOCHSECONDS line
  if [[ -r $cache ]]; then
    line=$(<$cache)
    if (( now - ${line%% *} < PROXY_AUTO_TTL )); then
      print -r -- ${line#* }
      return
    fi
  fi
  local name=$_proxy_names[1] result=''
  if [[ -n $name ]]; then
    if [[ $name == system ]]; then
      result=system   # ログイン時の環境（Windows など）が決めたプロキシなので、そのまま使う
    else
      _proxy_hostport ${_proxy_url[$name]}
      timeout 0.5 bash -c 'exec 3<>"/dev/tcp/$1/$2"' _ $reply[1] $reply[2] 2>/dev/null && result=$name
    fi
  fi
  mkdir -p -m 700 $PROXY_STATE_DIR 2>/dev/null
  print -r -- "$now $result" >| $cache
  print -r -- $result
}

# 状態をこのシェルに反映する（precmd から毎回呼ぶ。状態が変わっていなければ何もしない）
function _proxy_sync() {
  local state=''
  [[ -r $PROXY_STATE_DIR/state ]] && state=$(<$PROXY_STATE_DIR/state)
  [[ -n ${_proxy_synced:-} && $state == ${_proxy_applied_state:-} ]] && return
  typeset -g _proxy_synced=1 _proxy_applied_state=$state
  _proxy_load
  case $state in
    '')
      # 候補が無い端末（プロキシ不要の環境）では判定もしない
      if (( $#_proxy_names )); then _proxy_apply "$(_proxy_auto)"; else _proxy_apply ''; fi
      ;;
    off) _proxy_apply '' ;;
    *)
      if (( ${+_proxy_url[$state]} )); then
        _proxy_apply $state
      else
        print -u2 "proxy: 設定に無いプロキシです: $state（自動に戻します）"
        rm -f $PROXY_STATE_DIR/state
        _proxy_apply "$(_proxy_auto)"
      fi
      ;;
  esac
}

# 状態を変更して全シェルに伝える（このシェルにはすぐ反映、他のシェルは次のプロンプトで反映）
function _proxy_set_state() {
  mkdir -p -m 700 $PROXY_STATE_DIR
  if [[ -z $1 ]]; then
    rm -f $PROXY_STATE_DIR/state $PROXY_STATE_DIR/auto
  else
    print -r -- $1 >| $PROXY_STATE_DIR/state
  fi
  _proxy_synced=''
  _proxy_sync
  proxy status
}

function proxy() {
  local cmd=${1:-status}
  (( $# )) && shift
  _proxy_load
  case $cmd in
    status)
      local state='' mode
      [[ -r $PROXY_STATE_DIR/state ]] && state=$(<$PROXY_STATE_DIR/state)
      case $state in
        '')  mode='自動' ;;
        off) mode='手動で無効（全シェル）' ;;
        *)   mode='手動で切り替え中（全シェル）' ;;
      esac
      if [[ -n ${PROXY_NAME:-} ]]; then
        print -r -- "proxy: $PROXY_NAME (${_proxy_url[$PROXY_NAME]:-?})  [$mode]"
      else
        print -r -- "proxy: なし  [$mode]"
      fi
      if (( $#_proxy_names )); then
        print -r -- "  候補: ${_proxy_names[1]}（既定） ${_proxy_names[2,-1]}"
        print -r -- "  除外: $_proxy_no"
      else
        print -r -- "  候補: なし（$PROXY_CONFIG に書く）"
      fi
      ;;
    list)
      local n mark note
      for n in $_proxy_names; do
        mark=' ' note=''
        [[ $n == ${PROXY_NAME:-} ]] && mark='*'
        [[ $n == $_proxy_names[1] ]] && note='（既定）'
        printf '%s %-8s %s %s\n' $mark $n ${_proxy_url[$n]} $note
      done
      ;;
    use)
      [[ -n ${1:-} ]] || { print -u2 "使い方: proxy use 名前（候補: $_proxy_names）"; return 1; }
      (( ${+_proxy_url[$1]} )) || { print -u2 "proxy: 設定に無いプロキシです: $1（候補: $_proxy_names）"; return 1; }
      _proxy_set_state $1
      ;;
    on)
      (( $#_proxy_names )) || { print -u2 "proxy: プロキシが設定されていません（$PROXY_CONFIG）"; return 1; }
      _proxy_set_state $_proxy_names[1]
      ;;
    off)  _proxy_set_state off ;;
    auto) _proxy_set_state '' ;;
    run)
      local name=${1:-}
      (( ${+_proxy_url[$name]} )) || { print -u2 "使い方: proxy run 名前 -- コマンド（候補: $_proxy_names）"; return 1; }
      shift
      [[ ${1:-} == -- ]] && shift
      (( $# )) || { print -u2 "proxy run: 実行するコマンドがありません"; return 1; }
      ( _proxy_apply $name; "$@" )
      ;;
    test)
      _proxy_test "${1:-$PROXY_TEST_URL}"
      ;;
    edit)
      if [[ ! -e $PROXY_CONFIG ]]; then
        mkdir -p ${PROXY_CONFIG:h}
        print -r -- "# 名前  URL（先頭が既定のプロキシ）
# main  http://proxy.example.com:8080
# alt   http://proxy2.example.com:8080
no_proxy  localhost,127.0.0.1,::1" >$PROXY_CONFIG
        chmod 600 $PROXY_CONFIG
      fi
      ${=EDITOR:-vi} $PROXY_CONFIG
      _proxy_synced=''
      _proxy_sync
      ;;
    -h|--help|help)
      print -r -- "使い方: proxy [コマンド]
  status            現在の状態（既定）
  list              設定されているプロキシの一覧
  use 名前          全シェルをそのプロキシに切り替える（再起動するまで有効）
  on / off          全シェルで既定のプロキシを使う / 使わない
  auto              自動判定に戻す（既定のプロキシに接続できれば使う）
  run 名前 -- cmd   そのコマンドだけ指定のプロキシで実行する
  test [URL]        全プロキシと直接接続で URL に接続を試す（既定: $PROXY_TEST_URL）
  edit              設定ファイル（$PROXY_CONFIG）を編集する"
      ;;
    *)
      print -u2 "proxy: 不明なコマンドです: $cmd（proxy help を参照）"
      return 1
      ;;
  esac
}

# 全プロキシと直接接続で URL への接続を並列に試す
function _proxy_test() {
  emulate -L zsh
  setopt no_monitor no_notify
  local url=$1 tmp n i
  local -a targets=($_proxy_names direct)
  tmp=$(mktemp -d) || return 1
  print -r -- "接続テスト: $url"
  i=0
  for n in $targets; do
    (( i++ ))
    {
      local -a opt
      if [[ $n == direct ]]; then opt=(--noproxy '*'); else opt=(-x ${_proxy_url[$n]}); fi
      env -u no_proxy -u NO_PROXY -u http_proxy -u https_proxy -u HTTP_PROXY -u HTTPS_PROXY \
        curl -sS -o /dev/null --connect-timeout 5 --max-time 10 -w '%{http_code} %{time_total}' $opt $url \
        >$tmp/$i.out 2>$tmp/$i.err
      print -r -- $? >$tmp/$i.rc
    } &
  done
  wait
  i=0
  local rc out code time msg mark err
  local -a errl
  for n in $targets; do
    (( i++ ))
    rc=$(<$tmp/$i.rc) out=$(<$tmp/$i.out)
    code=${out%% *} time=${out##* }
    # curl のエラーメッセージ（"curl: (56) CONNECT tunnel failed, response 403" → "CONNECT tunnel failed, response 403"）
    errl=(${(f)"$(<$tmp/$i.err)"})
    err=${${errl[1]:-}#curl: }
    err=${err#\(<->\) }
    if (( rc == 0 )); then
      msg=$(printf 'OK   HTTP %s  %.2fs' $code $time)
    else
      case $rc in
        5)  msg='NG   プロキシの名前解決に失敗' ;;
        6)  msg='NG   宛先の名前解決に失敗' ;;
        7)  msg='NG   接続できない' ;;
        28) msg='NG   タイムアウト' ;;
        35|60) msg='NG   TLS/証明書のエラー' ;;
        56) msg="NG   プロキシが拒否（$err）" ;;
        *)  msg="NG   curl エラー $rc（$err）" ;;
      esac
    fi
    mark=' '
    [[ $n == ${PROXY_NAME:-direct} ]] && mark='*'
    printf '%s %-8s %-36s %s\n' $mark $n ${_proxy_url[$n]:--} $msg
  done
  rm -rf $tmp
}

# 補完
function _proxy_complete() {
  local -a cmds=(
    'status:現在の状態' 'list:プロキシの一覧' 'use:全シェルを切り替える' 'on:既定のプロキシを使う'
    'off:プロキシを使わない' 'auto:自動判定に戻す' 'run:そのコマンドだけ別のプロキシで実行'
    'test:接続テスト' 'edit:設定ファイルを編集' 'help:使い方'
  )
  if (( CURRENT == 2 )); then
    _describe 'command' cmds
  elif (( CURRENT == 3 )) && [[ $words[2] == (use|run) ]]; then
    _proxy_load
    compadd -a _proxy_names
  elif [[ $words[2] == run ]] && (( CURRENT >= 4 )); then
    if [[ $words[4] == -- ]]; then
      (( CURRENT == 4 )) && return
      shift 4 words; (( CURRENT -= 4 ))
    else
      shift 3 words; (( CURRENT -= 3 ))
    fi
    _normal
  fi
}

# svn は環境変数のプロキシを使わないので、起動時にこのシェルのプロキシを渡す
if (( $+commands[svn] )); then
  function svn() {
    if [[ -n ${PROXY_NAME:-} ]]; then
      _proxy_hostport $https_proxy
      local -a ex=(${(s:,:)no_proxy})
      ex=(${ex/#./*.})
      command svn \
        --config-option "servers:global:http-proxy-host=$reply[1]" \
        --config-option "servers:global:http-proxy-port=$reply[2]" \
        --config-option "servers:global:http-proxy-exceptions=${(j:,:)ex}" "$@"
    else
      command svn "$@"
    fi
  }
fi

autoload -Uz add-zsh-hook
add-zsh-hook precmd _proxy_sync
_proxy_sync
