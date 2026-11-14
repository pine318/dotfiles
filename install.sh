#!/usr/bin/env bash
#
# dotfiles インストーラ
#
#   新しい環境で（何度実行してもよい）:
#     curl -fsSL https://raw.githubusercontent.com/pine318/dotfiles/master/install.sh | bash
#
#   オプションを付ける場合:
#     curl -fsSL https://raw.githubusercontent.com/pine318/dotfiles/master/install.sh | bash -s -- --no-ja
#
#   リポジトリ内から:
#     ./install.sh [install]    すべて実行（パッケージ → 日本語環境 → clone → リンク → mise → zsh プラグイン → ログインシェル）
#                               VS Code は対象外（make vscode で配置する）
#     ./install.sh update       リポジトリ・mise・CLI ツール・zsh プラグインを更新（VS Code は対象外）
#     ./install.sh link         シンボリックリンクを作成（既存の実ファイルは *.bak.<日時> に退避）
#     ./install.sh unlink       このリポジトリを指すシンボリックリンクだけを削除
#     ./install.sh list         管理しているファイルの一覧
#     ./install.sh vscode       VS Code の設定・スニペット・拡張機能を配置（make vscode から呼ぶ。既存の設定は *.bak.<日時> に退避）
#     ./install.sh vscode-pull  VS Code の現在の設定・拡張機能一覧をリポジトリに取り込む（端末ごとの設定は除く）
#
#   オプション:
#     --no-ja      日本語環境（ロケール・タイムゾーン・日本語 man）を設定しない
#     --upgrade    apt upgrade も実行する
#
#   環境変数:
#     DOTFILES_DIR     配置先（既定: ~/dotfiles）
#     DOTFILES_REPO    clone 元（既定: https://github.com/pine318/dotfiles.git）
#     DOTFILES_BRANCH  ブランチ（既定: master）

set -euo pipefail

DOTFILES_REPO=${DOTFILES_REPO:-https://github.com/pine318/dotfiles.git}
DOTFILES_BRANCH=${DOTFILES_BRANCH:-master}
CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}
MISE_BIN=$HOME/.local/bin/mise
USER=${USER:-$(id -un)}

# パッケージ（apt: Ubuntu / dnf: Rocky Linux などの RHEL 系）
APT_PACKAGES=(zsh git curl ca-certificates make tmux vim tar gzip xz-utils unzip openssh-client)
APT_PACKAGES_JA=(language-pack-ja manpages-ja manpages-ja-dev tzdata)
DNF_PACKAGES=(zsh git curl ca-certificates make tmux vim-enhanced tar gzip xz unzip openssh-clients)
DNF_PACKAGES_JA=(glibc-langpack-ja tzdata) # 日本語 man は RHEL 系では提供されていない

# リンクの一覧（リポジトリ内のパス → 配置先）
link_pairs() {
  local d=$DOTFILES_DIR
  printf '%s\t%s\n' \
    "$d/config/zsh/zshrc" "$HOME/.zshrc" \
    "$d/config/zsh/plugins.txt" "$CONFIG_HOME/zsh/plugins.txt" \
    "$d/config/zsh/proxy.zsh" "$CONFIG_HOME/zsh/proxy.zsh" \
    "$d/config/tmux/tmux.conf" "$CONFIG_HOME/tmux/tmux.conf" \
    "$d/config/vim/vimrc" "$HOME/.vimrc" \
    "$d/config/starship.toml" "$CONFIG_HOME/starship.toml" \
    "$d/config/mise/config.toml" "$CONFIG_HOME/mise/config.toml"
}

# ---------------------------------------------------------------- ユーティリティ

info() { printf '\033[1;34m==>\033[0m \033[1m%s\033[0m\n' "$*"; }
ok()   { printf '\033[1;32m  ✓\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m  !\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31mエラー:\033[0m %s\n' "$*" >&2; exit 1; }

has() { command -v "$1" >/dev/null 2>&1; }

# /proc/version は Docker Desktop のコンテナ内でも "microsoft" を含むので、WSL にしかないものを見る
is_wsl() { [[ -d /run/WSL || -e /proc/sys/fs/binfmt_misc/WSLInterop ]]; }

# ~ 付きの短い表記にする
short() { echo "${1/#$HOME/\~}"; }

# パッケージマネージャ（apt / dnf / 空）
detect_pm() {
  if has apt-get; then
    PM=apt
  elif has dnf; then
    PM=dnf
  else
    PM=''
  fi
}

# パッケージ一覧のうち未インストールのものを出力する
missing_packages() {
  local p
  for p in "$@"; do
    case $PM in
      apt) [[ $(dpkg-query -W -f='${Status}' "$p" 2>/dev/null) == *'ok installed'* ]] || echo "$p" ;;
      # --whatprovides: Rocky 9 の curl-minimal のように、別名のパッケージで提供済みなら入れない（入れると競合する）
      dnf) rpm -q --quiet --whatprovides "$p" || echo "$p" ;;
    esac
  done
}

# パッケージマネージャを sudo で実行する。sudo は環境変数を引き継がないので、プロキシの設定だけ渡す
#   （渡さないとプロキシ経由でしか外に出られない環境で apt / dnf が失敗する）
sudo_pm() {
  sudo --preserve-env=http_proxy,https_proxy,no_proxy,HTTP_PROXY,HTTPS_PROXY,NO_PROXY "$@" </dev/null
}

# 足りないパッケージだけ入れる（全部入っていれば sudo も使わない）
pkg_install() {
  local missing
  mapfile -t missing < <(missing_packages "$@")
  ((${#missing[@]} > 0)) || return 0
  has sudo || die "sudo がありません。root で ${missing[*]} をインストールしてから再実行してください"
  case $PM in
    apt)
      sudo_pm apt-get update
      sudo_pm env DEBIAN_FRONTEND=noninteractive apt-get install -y "${missing[@]}"
      ;;
    dnf) sudo_pm dnf install -y "${missing[@]}" ;;
  esac
}

pkg_upgrade() {
  case $PM in
    apt)
      sudo_pm apt-get update
      sudo_pm env DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
      ;;
    dnf) sudo_pm dnf upgrade -y ;;
  esac
}

# 既存のファイルを <名前>.bak.<日時> に退避する
backup() {
  local bak
  bak="$1.bak.$(date +%Y%m%d%H%M%S)"
  mv "$1" "$bak"
  warn "既存のファイルを退避しました: $(short "$bak")"
}

# シンボリックリンクを作る（既存の実ファイルは退避する）
link_one() {
  local src=$1 dst=$2
  [[ -e $src ]] || die "リポジトリにファイルがありません: $src"
  [[ -L $dst && $(readlink "$dst") == "$src" ]] && return 0
  [[ -e $dst && ! -L $dst ]] && backup "$dst"
  mkdir -p "$(dirname "$dst")"
  ln -sfn "$src" "$dst"
}

# Windows の環境変数を取得する（WSL のみ）
win_env() {
  (cd /mnt/c && /mnt/c/Windows/System32/cmd.exe /d /c "echo %$1%" 2>/dev/null | tr -d '\r') || true
}

# ---------------------------------------------------------------- 各手順

# 1. パッケージ
install_packages() {
  info "パッケージ"
  local pkgs
  case $PM in
    apt) pkgs=("${APT_PACKAGES[@]}") ;;
    dnf) pkgs=("${DNF_PACKAGES[@]}") ;;
    *)
      warn "apt / dnf が無い環境です。zsh git curl make tmux vim tar gzip xz unzip を手動で入れてください"
      return 0
      ;;
  esac
  [[ $OPT_UPGRADE == 1 ]] && pkg_upgrade
  pkg_install "${pkgs[@]}"
  ok "インストール済み: ${pkgs[*]}"
}

# 2. 日本語環境
setup_japanese() {
  [[ $OPT_JA == 1 ]] || return 0
  info "日本語環境"
  case $PM in
    apt)
      pkg_install "${APT_PACKAGES_JA[@]}"
      if ! grep -qsiE '^LANG="?ja_JP\.UTF-?8' /etc/default/locale; then
        sudo update-locale LANG=ja_JP.UTF-8
      fi
      ;;
    dnf)
      pkg_install "${DNF_PACKAGES_JA[@]}"
      if ! grep -qsiE '^LANG="?ja_JP\.UTF-?8' /etc/locale.conf; then
        echo 'LANG=ja_JP.UTF-8' | sudo tee /etc/locale.conf >/dev/null
      fi
      ;;
    *)
      warn "apt / dnf が無い環境のためスキップします"
      return 0
      ;;
  esac
  if [[ $(readlink -f /etc/localtime) != /usr/share/zoneinfo/Asia/Tokyo ]]; then
    sudo ln -fs /usr/share/zoneinfo/Asia/Tokyo /etc/localtime
    if [[ $PM == apt ]]; then
      sudo DEBIAN_FRONTEND=noninteractive dpkg-reconfigure tzdata </dev/null
    fi
  fi
  ok "ロケール ja_JP.UTF-8 / タイムゾーン Asia/Tokyo$([[ $PM == apt ]] && echo ' / 日本語 man')"
}

# 3. リポジトリ
setup_repo() {
  info "dotfiles リポジトリ"
  if [[ -d $DOTFILES_DIR/.git ]]; then
    if [[ -n $(git -C "$DOTFILES_DIR" status --porcelain) ]]; then
      warn "$(short "$DOTFILES_DIR") に未コミットの変更があるため更新をスキップします"
    else
      git -C "$DOTFILES_DIR" pull --ff-only --quiet || warn "git pull に失敗しました（そのまま続行します）"
      ok "更新しました: $(short "$DOTFILES_DIR")"
    fi
  else
    git clone --quiet --branch "$DOTFILES_BRANCH" "$DOTFILES_REPO" "$DOTFILES_DIR" </dev/null
    ok "clone しました: $(short "$DOTFILES_DIR")"
  fi
}

# 4. シンボリックリンク
link_files() {
  info "シンボリックリンク"
  local src dst
  while IFS=$'\t' read -r src dst; do
    link_one "$src" "$dst"
    ok "$(short "$dst")"
  done < <(link_pairs)
  remove_stale_links
}

# 配置先が変わって不要になったリンク（このリポジトリを指していて、一覧に無いもの）を削除する
remove_stale_links() {
  local l
  while IFS= read -r -d '' l; do
    [[ $(readlink "$l") == "$DOTFILES_DIR"/* ]] || continue
    # パイプ（list_files | grep -q）だと pipefail で誤判定するので、プロセス置換で渡す
    grep -qxF "$l" < <(list_files) && continue
    rm "$l"
    ok "不要になったリンクを削除: $(short "$l")"
  done < <(find "$HOME" "$CONFIG_HOME" -maxdepth 2 -type l -print0 2>/dev/null)
}

unlink_files() {
  info "シンボリックリンクの削除"
  local src dst
  while IFS=$'\t' read -r src dst; do
    if [[ -L $dst && $(readlink "$dst") == "$src" ]]; then
      rm "$dst"
      ok "削除: $(short "$dst")"
    fi
  done < <(link_pairs)
}

list_files() {
  local src dst
  while IFS=$'\t' read -r src dst; do echo "$dst"; done < <(link_pairs)
}

# プロキシの設定ファイル（端末ごと。リポジトリでは管理しない）
#   インストーラをプロキシ環境で実行した（https_proxy などが設定されている）ときは、その値を既定のプロキシとして保存する
#   WSL では Windows のプロキシ設定が自動で使われる（proxy.zsh の "system"）ので保存しない
setup_proxy_config() {
  local conf=$CONFIG_HOME/proxy url=${https_proxy:-${HTTPS_PROXY:-${http_proxy:-${HTTP_PROXY:-}}}}
  [[ -n $url && ! -e $conf ]] && ! is_wsl || return 0
  info "プロキシ"
  mkdir -p "$(dirname "$conf")"
  (
    umask 077
    printf '%s\n' '# 名前  URL（先頭が既定のプロキシ）。追加・切り替えは proxy help を参照' \
      "main  $url" "no_proxy  ${no_proxy:-${NO_PROXY:-localhost,127.0.0.1,::1}}" >"$conf"
  )
  ok "現在のプロキシを保存しました: $(short "$conf")（main = $url）"
}

# 5. mise と CLI ツール
setup_mise() {
  info "mise と CLI ツール"
  if [[ ! -x $MISE_BIN ]]; then
    curl -fsSL https://mise.run | MISE_INSTALL_PATH=$MISE_BIN sh
  fi
  "$MISE_BIN" install --yes </dev/null
  ok "$("$MISE_BIN" --version | cut -d' ' -f1) / $("$MISE_BIN" ls --current --no-header 2>/dev/null | awk '{print $1}' | paste -sd' ')"
}

# 6. zsh プラグイン（antidote・プラグインの clone とキャッシュ生成のため、一度 zsh を起動する）
setup_zsh() {
  info "zsh プラグイン"
  # tty が無いと出る zle の警告は無害なので除外して表示する。
  # 起動中に常駐する wsl2-ssh-agent が出力先を開いたままにするため、パイプではなくファイルで受ける
  local log
  log=$(mktemp)
  zsh -i -c 'exit' </dev/null >/dev/null 2>"$log" || true
  grep -v "can't change option: zle" "$log" >&2 || true
  rm -f "$log"
  ok "antidote とプラグインを準備しました"
}

# VS Code（install では実行しない。make vscode / make vscode-pull から呼ぶ）
#   設定ファイルはコピーで配置し、既存の設定は *.bak.<日時> に退避する。シンボリックリンクにしない理由:
#     - WSL では Windows 側の VS Code が WSL のリンクを辿れない
#     - リンクだと、VS Code が書き込む端末ごとの設定（remote.SSH.* など）がリポジトリに入ってしまう
#   settings.json の端末ごとの設定はリポジトリで管理しない（取り込まず、配置時も各端末の値を残す）
#   拡張機能は一覧に足りないものだけ入れる（一覧に無いものは削除しない）

# settings.json のうち端末ごとに管理する設定（トップレベルのキーの正規表現）
#   remote.SSH.*  : SSH の接続先（自宅・職場のホスト名）
#   http.proxy*   : プロキシ（http.proxy, http.proxyStrictSSL, http.proxyAuthorization, http.proxySupport）
#   http.noProxy  : プロキシの除外先
VSCODE_LOCAL_KEYS='(remote\.SSH\.|http\.proxy|http\.noProxy)'

# VS Code の設定ディレクトリと CLI を調べる。見つからなければ 1 を返す
find_vscode() {
  VSCODE_USER_DIR='' VSCODE_CLI=()
  if is_wsl; then
    local appdata localappdata vsdir cli c
    appdata=$(win_env APPDATA)
    localappdata=$(win_env LOCALAPPDATA)
    [[ -n $appdata && -n $localappdata ]] || return 1
    vsdir="$(wslpath -u "$localappdata")/Programs/Microsoft VS Code"
    [[ -f $vsdir/Code.exe ]] || return 1
    VSCODE_USER_DIR="$(wslpath -u "$appdata")/Code/User"
    # WSL 用の code コマンドは WSL 側（VS Code Server）を操作するので、Windows 側の CLI を直接呼ぶ
    for c in "$vsdir"/*/resources/app/out/cli.js; do
      [[ -f $c && ( -z ${cli:-} || $c -nt $cli ) ]] && cli=$c
    done
    [[ -n ${cli:-} ]] && VSCODE_CLI=(env "WSLENV=ELECTRON_RUN_AS_NODE/w" ELECTRON_RUN_AS_NODE=1 "$vsdir/Code.exe" "$(wslpath -m "$cli")")
  else
    has code || return 1
    VSCODE_USER_DIR=$CONFIG_HOME/Code/User
    VSCODE_CLI=(code)
  fi
  return 0
}

vscode_cli() { (cd /mnt/c 2>/dev/null || true; "${VSCODE_CLI[@]}" "$@" </dev/null 2>/dev/null | tr -d '\r'); }

# リポジトリで管理している VS Code の設定ファイル（config/vscode からの相対パス）
vscode_files() {
  (cd "$DOTFILES_DIR/config/vscode" && find . -type f \( -name '*.json' -o -name '*.code-snippets' \) | sed 's|^\./||' | sort)
}

# settings.json（標準入力）から端末ごとの設定のブロックを取り除く（strip）/ 抜き出す（extract）
#   VS Code が書き出す形式（トップレベルのキーは 4 スペースのインデント）を前提にする
vscode_local_settings() {
  RE="^    \"$VSCODE_LOCAL_KEYS" awk -v mode="$1" '
    /\r$/       { crlf = 1 }
    /^    "/    { is_local = ($0 ~ ENVIRON["RE"]) }
    /^    \/\// { is_local = 0 }
    /^}/        { is_local = 0 }
    (mode == "strip" && !is_local) || (mode == "extract" && is_local) { out[++n] = $0 }
    END {
      # strip: 配置時に付けたカンマが残らないよう、最後の閉じ括弧の直前の要素の末尾カンマを外す
      if (mode == "strip") {
        for (c = n; c > 0 && out[c] !~ /^}/; c--) ;
        for (p = c - 1; p > 0 && out[p] ~ /^[ \t\r]*$/; p--) ;
        if (p > 0) sub(/,\r?$/, crlf ? "\r" : "", out[p])
      }
      for (i = 1; i <= n; i++) {
        # 末尾に改行の無いファイルでも、最後の行の改行コードを他の行（CRLF）に揃える
        if (crlf && out[i] !~ /\r$/) out[i] = out[i] "\r"
        print out[i]
      }
    }
  '
}

# リポジトリの settings.json に、配置先にある端末ごとの設定を加えたものを出力する
vscode_merge_settings() {
  local repo=$1 current=$2 extra=''
  [[ -f $current ]] && extra=$(vscode_local_settings extract <"$current")
  if [[ -z $extra ]]; then
    cat "$repo"
    return 0
  fi
  EXTRA=$extra awk '
    { line[NR] = $0 }
    END {
      for (c = NR; c > 0 && line[c] !~ /^}/; c--) ;           # 最後の閉じ括弧
      for (p = c - 1; p > 0 && line[p] ~ /^[ \t\r]*$/; p--) ;  # その直前の空でない行
      if (line[p] !~ /[,{[]\r?$/) sub(/\r?$/, ",&", line[p])  # 直前の要素の後ろにカンマを付ける
      for (i = 1; i < c; i++) print line[i]
      print ENVIRON["EXTRA"]
      for (i = c; i <= NR; i++) print line[i]
    }' "$repo"
}

setup_vscode() {
  info "VS Code"
  if ! find_vscode; then
    ok "VS Code が見つからないためスキップします"
    return 0
  fi
  local src=$DOTFILES_DIR/config/vscode f dst tmp
  tmp=$(mktemp)
  while IFS= read -r f; do
    dst=$VSCODE_USER_DIR/$f
    if [[ $f == settings.json ]]; then
      vscode_merge_settings "$src/$f" "$dst" >"$tmp"
    else
      cp "$src/$f" "$tmp"
    fi
    if [[ ! -f $dst || -L $dst ]] || ! cmp -s "$tmp" "$dst"; then
      mkdir -p "$(dirname "$dst")"
      [[ -e $dst || -L $dst ]] && backup "$dst"
      cp "$tmp" "$dst"
      ok "配置しました: $f"
    fi
  done < <(vscode_files)
  rm -f "$tmp"
  ok "設定: $(vscode_files | paste -sd' ')"

  if ((${#VSCODE_CLI[@]} == 0)); then
    warn "VS Code の CLI が見つからないため拡張機能のインストールをスキップします"
    return 0
  fi
  local installed ext missing=()
  installed=$(vscode_cli --list-extensions)
  if [[ -z $installed ]]; then
    warn "拡張機能の一覧を取得できないためスキップします"
    return 0
  fi
  while IFS= read -r ext; do
    ext=${ext%$'\r'}
    [[ -z $ext || $ext == \#* ]] && continue
    grep -qixF "$ext" <<<"$installed" || missing+=("$ext")
  done <"$src/extensions.txt"
  for ext in "${missing[@]}"; do
    if vscode_cli --install-extension "$ext" >/dev/null; then
      ok "拡張機能をインストールしました: $ext"
    else
      warn "拡張機能のインストールに失敗しました: $ext"
    fi
  done
  ok "拡張機能: 一覧 $(grep -c . "$src/extensions.txt") 件のうち ${#missing[@]} 件を新たにインストール"
}

# VS Code の現在の設定・拡張機能一覧をリポジトリに取り込む（画面で変えた設定はこれでリポジトリに戻す）
#   端末ごとの設定（VSCODE_LOCAL_KEYS）は取り込まない
vscode_pull() {
  info "VS Code の設定をリポジトリに取り込む"
  find_vscode || die "VS Code が見つかりません"
  local dst=$DOTFILES_DIR/config/vscode f tmp
  tmp=$(mktemp)
  while IFS= read -r f; do
    if [[ $f == settings.json ]]; then
      vscode_local_settings strip <"$VSCODE_USER_DIR/$f" >"$tmp"
    else
      cp "$VSCODE_USER_DIR/$f" "$tmp"
    fi
    mkdir -p "$(dirname "$dst/$f")"
    cmp -s "$tmp" "$dst/$f" || { cp "$tmp" "$dst/$f"; ok "取り込みました: $f"; }
  done < <(cd "$VSCODE_USER_DIR" && find settings.json keybindings.json snippets -maxdepth 1 -type f \( -name '*.json' -o -name '*.code-snippets' \) 2>/dev/null | sort)
  rm -f "$tmp"
  if ((${#VSCODE_CLI[@]} > 0)); then
    local list
    list=$(vscode_cli --list-extensions | sort -f)
    if [[ -n $list ]]; then
      printf '%s\n' "$list" >"$dst/extensions.txt"
      ok "拡張機能の一覧を更新しました（$(grep -c . <<<"$list") 件）"
    fi
  fi
  ok "差分は git -C $(short "$DOTFILES_DIR") diff で確認できます"
}

# 7. ログインシェル
change_shell() {
  info "ログインシェル"
  local zsh_path current
  zsh_path=$(command -v zsh)
  current=$(getent passwd "$USER" | cut -d: -f7)
  if [[ $current != "$zsh_path" && $current != */zsh ]]; then
    # chsh は RHEL 系の最小構成に無いので usermod を使う
    sudo usermod -s "$zsh_path" "$USER"
    ok "zsh に変更しました（再ログイン後に有効）"
  else
    ok "zsh です"
  fi
}

update_all() {
  setup_repo
  link_files
  info "mise と CLI ツールの更新"
  "$MISE_BIN" self-update --yes </dev/null || warn "mise self-update に失敗しました"
  "$MISE_BIN" upgrade --yes </dev/null
  info "zsh プラグインの更新"
  zsh -c "source ${XDG_DATA_HOME:-$HOME/.local/share}/antidote/antidote.zsh && antidote update" </dev/null
}

usage() { sed -n '3,/^$/p' "${BASH_SOURCE[0]}" 2>/dev/null | sed 's/^# \{0,1\}//' || true; }

# ---------------------------------------------------------------- メイン

main() {
  local cmd=install
  OPT_JA=1
  OPT_UPGRADE=0
  while (($# > 0)); do
    case $1 in
      install | update | link | unlink | list | vscode | vscode-pull) cmd=$1 ;;
      --no-ja) OPT_JA=0 ;;
      --upgrade) OPT_UPGRADE=1 ;;
      -h | --help) usage; exit 0 ;;
      *) die "不明な引数: $1（--help を参照）" ;;
    esac
    shift
  done

  ((EUID != 0)) || die "root ではなく一般ユーザーで実行してください"

  # リポジトリ内のスクリプトとして実行された場合はそのリポジトリを使う
  local self=${BASH_SOURCE[0]:-}
  if [[ -z ${DOTFILES_DIR:-} && -f $self && -d $(dirname "$self")/.git ]]; then
    DOTFILES_DIR=$(cd "$(dirname "$self")" && pwd)
  fi
  DOTFILES_DIR=${DOTFILES_DIR:-$HOME/dotfiles}
  detect_pm

  case $cmd in
    link) link_files ;;
    unlink) unlink_files ;;
    list) list_files ;;
    update) update_all ;;
    vscode) setup_vscode ;;
    vscode-pull) vscode_pull ;;
    install)
      install_packages
      setup_japanese
      setup_repo
      link_files
      setup_proxy_config
      setup_mise
      setup_zsh
      change_shell
      echo
      info "完了しました。新しいターミナルを開くか、exec zsh -l を実行してください"
      ;;
  esac
}

# curl | bash で実行されたとき、スクリプト全体を読み込んでから実行するために最後の行で呼ぶ
main "$@"
