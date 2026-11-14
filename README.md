# dotfiles

WSL2（Ubuntu）向けの zsh 環境。Linux（Ubuntu / Rocky Linux などの RHEL 系）でも動作する。

| 動作確認済み | 備考 |
| --- | --- |
| WSL2 Ubuntu 24.04 | メイン環境 |
| Ubuntu 24.04 / 22.04 | Docker コンテナで確認 |
| Rocky Linux 9 / 10 | Docker コンテナで確認。日本語 man は提供されていないため入らない |

## インストール

```sh
curl -fsSL https://raw.githubusercontent.com/pine318/dotfiles/master/install.sh | bash
```

これだけで次がすべて完了する（何度実行してもよい。済んでいる手順はスキップされる）。

1. 必要なパッケージ（zsh, git, tmux, vim など）のインストール（apt / dnf）
2. 日本語環境（ロケール・タイムゾーン・日本語 man）の設定（`--no-ja` で省略）
3. このリポジトリを `~/dotfiles` に clone
4. シンボリックリンクの作成（既存の実ファイルは `*.bak.<日時>` に退避）
5. mise と CLI ツール（fzf, uv, starship, wsl2-ssh-agent など）のインストール
6. antidote と zsh プラグインのインストール
7. ログインシェルを zsh に変更

VS Code の設定はインストーラでは配置しない。必要な端末で `make vscode` を実行する（後述）。

マシン固有の設定ファイルは不要（WSL の Windows ユーザー名などは自動で取得する）。

オプションは `bash -s --` の後ろに付ける。

```sh
curl -fsSL https://raw.githubusercontent.com/pine318/dotfiles/master/install.sh | bash -s -- --no-ja
```

| オプション | 内容 |
| --- | --- |
| `--no-ja` | 日本語環境を設定しない |
| `--upgrade` | `apt upgrade` も実行する |

プロキシ環境では、実行前にプロキシを設定する（次節）。

### プロキシ環境でのインストール

#### 手順

1. **プロキシを環境変数に設定する**（WSL で Windows のプロキシ設定が自動で渡されている場合は不要。後述の「WSL の場合」を参照）

   ```sh
   export https_proxy=http://proxy.corp.example:8080
   export http_proxy=$https_proxy
   export no_proxy=localhost,127.0.0.1,.corp.example   # プロキシを通さない宛先（社内のホストなど）
   ```

2. **インストーラを実行する**（手順 1 と同じシェルで実行する）

   ```sh
   curl -fsSL https://raw.githubusercontent.com/pine318/dotfiles/master/install.sh | bash
   ```

   `curl` が無い最小構成の Ubuntu では、先に入れておく（`sudo` は環境変数を引き継がないので、プロキシの変数を明示的に渡す）。

   ```sh
   sudo --preserve-env=http_proxy,https_proxy apt-get update
   sudo --preserve-env=http_proxy,https_proxy apt-get install -y curl
   ```

3. **新しいターミナルを開いて確認する**

   ```sh
   proxy        # proxy: main (http://proxy.corp.example:8080) [自動] と出れば OK
   proxy test   # main で github.com に接続できるか
   ```

4. （プロキシが複数ある場合）`proxy edit` で他のプロキシを追加する（[プロキシ（proxy コマンド）](#プロキシproxy-コマンド)）

#### インストーラがプロキシ環境で行うこと

| 処理 | プロキシの使い方 |
| --- | --- |
| apt / dnf | `sudo` にプロキシの環境変数だけを引き継いで実行する |
| git clone・mise・antidote | 環境変数のプロキシを使う |
| `~/.config/proxy` | 手順 1 のプロキシを `main` として保存する（権限 600。WSL では保存しない）。以降のシェルはこのファイルから自動でプロキシを設定するので、`export` を `.zshrc` などに書く必要は無い |

#### WSL の場合

- Windows でプロキシを設定していれば、WSL の **autoProxy**（WSL 2.0 以降・Windows 11 22H2 以降。既定で有効）が `HTTP_PROXY` などを自動で設定する。
  `env | grep -i proxy` で値が入っていれば手順 1 は不要で、インストール後も `system` という名前で自動的に使われる
- Windows の設定が **PAC ファイル（自動構成スクリプト）** の場合は `WSL_PAC_URL` しか渡されず、Linux 側では使えない。手順 1 を行い、インストール後に `proxy edit` でプロキシを書く
- 職場のプロキシが複数ある場合も `proxy edit` で書く（設定ファイルがあれば Windows の設定より優先される）

#### 認証が必要なプロキシ

URL にユーザー名とパスワードを含める。記号は URL エンコードする（`@` → `%40`、`:` → `%3A`、`#` → `%23` など）。
パスワードがシェルの履歴に残らないよう、入力させて組み立てるとよい（bash の例）。

```sh
read -rsp 'プロキシのパスワード: ' PROXY_PASS; echo
export https_proxy="http://user:${PROXY_PASS}@proxy.corp.example:8080"
export http_proxy=$https_proxy
```

インストーラはこの URL（パスワードを含む）を `~/.config/proxy` に保存する（権限 600）。

#### TLS を検査するプロキシ（社内 CA の証明書が必要な場合）

`proxy test` で「TLS/証明書のエラー」になる場合や、`curl` が証明書のエラー（`SSL certificate problem`）を出す場合は、**インストーラの実行前に**社内 CA の証明書を OS に登録する。

```sh
# Ubuntu
sudo cp corp-ca.crt /usr/local/share/ca-certificates/ && sudo update-ca-certificates
# Rocky Linux
sudo cp corp-ca.crt /etc/pki/ca-trust/source/anchors/ && sudo update-ca-trust
```

OS の証明書を使わないツールもある。例えば Node.js は `NODE_EXTRA_CA_CERTS=/path/to/corp-ca.crt`、uv は `UV_NATIVE_TLS=true` で OS の証明書を使うようになる。
（この節の手順は、TLS を検査するプロキシ環境では未検証）

#### うまくいかないとき

| 症状 | 対処 |
| --- | --- |
| `curl` で install.sh を取得できない | 手順 1 の `export` を同じシェルで実行したか確認する。`curl -x http://proxy:8080 ...` でプロキシを直接指定してもよい |
| 社内のサーバーにつながらなくなった | `no_proxy` にそのホストやドメイン（`.corp.example` のように先頭に `.`）を加える。インストール後は `proxy edit` |
| 後から自分で実行した `sudo apt` / `dnf` が失敗する | zsh で `sudo` と打った場合はプロキシの変数が引き継がれる。スクリプトから呼ぶ場合などは、apt なら `/etc/apt/apt.conf.d/95proxy` に `Acquire::http::Proxy "http://proxy:8080";` と `Acquire::https::Proxy "http://proxy:8080";`、dnf なら `/etc/dnf/dnf.conf` に `proxy=http://proxy:8080` を書いて恒久的に設定する |
| 宛先によってつながらない | `proxy test <URL>` でつながるプロキシを探し、`proxy run 名前 -- コマンド` か `proxy use 名前` で切り替える |

## 日常の操作

| 操作 | コマンド |
| --- | --- |
| すべて更新（リポジトリ・mise・CLI ツール・zsh プラグイン） | `make update` |
| シンボリックリンクを作り直す | `make deploy` |
| シンボリックリンクを削除（実ファイルには触れない） | `make clean` |
| 管理しているファイルの一覧 | `make list` |
| VS Code の設定・拡張機能をリポジトリから配置 | `make vscode` |
| VS Code で変えた設定・拡張機能をリポジトリに取り込む | `make vscode-pull` |

`make` は `install.sh` のラッパー（`~/dotfiles/install.sh update` などでも同じ）。

## 構成

```text
dotfiles/
├── install.sh            インストーラ（make はこのラッパー）
└── config/
    ├── zsh/zshrc         zsh 本体                → ~/.zshrc
    ├── zsh/proxy.zsh     proxy コマンド           → ~/.config/zsh/proxy.zsh
    ├── zsh/plugins.txt   antidote のプラグイン一覧 → ~/.config/zsh/plugins.txt
    ├── tmux/tmux.conf                            → ~/.config/tmux/tmux.conf
    ├── vim/vimrc                                 → ~/.vimrc
    ├── starship.toml     プロンプト              → ~/.config/starship.toml
    ├── mise/config.toml  CLI ツールのバージョン    → ~/.config/mise/config.toml
    └── vscode/           VS Code の設定・スニペット・拡張機能一覧
```

| 役割 | ツール |
| --- | --- |
| zsh プラグイン管理 | [antidote](https://github.com/mattmc3/antidote) |
| CLI ツールのバージョン管理（fzf, uv, starship など） | [mise](https://mise.jdx.dev/) |
| プロンプト | [starship](https://starship.rs/) |

端末ごとに使うツール（リポジトリでは管理しない）は `~/.config/mise/config.local.toml` に書く。

```toml
[tools]
yt-dlp = "latest"
```

`.zshrc` と `.vimrc` だけはホーム直下に置く（zsh は `~/.zshenv` で `ZDOTDIR` を指定しないと `~/.config` を読まず、
Ubuntu 24.04 の vim 9.1 は `~/.config/vim` に未対応のため）。

### VS Code（`config/vscode/`）

| 環境 | 配置先 |
| --- | --- |
| WSL | Windows 側の `%APPDATA%\Code\User` |
| Linux | `~/.config/Code/User` |

- **`make vscode` を実行したときだけ**配置する（インストーラ・`make update` では配置しない）
- どの環境でも**コピー**で配置する（WSL の Windows 側はリンクを辿れない。また、リンクだと VS Code が書き込む端末ごとの設定がリポジトリに入ってしまう）
- 既存の設定と内容が違う場合は `*.bak.<日時>` に退避してから配置する
- `settings.json` の **`remote.SSH.*`（SSH の接続先）と `http.proxy*`・`http.noProxy`（プロキシ）は端末ごとの設定**として扱う。リポジトリには入れず（`make vscode-pull` でも取り込まない）、配置時も各端末の値を残す。
  Settings Sync でも `remote.SSH.remotePlatform` は同期しない（`settingsSync.ignoredSettings`）。端末ごとにする設定を増やすときは `install.sh` の `VSCODE_LOCAL_KEYS` に追加する
- 拡張機能は `extensions.txt` のうち足りないものだけインストールする（一覧に無いものは削除しない）
- VS Code の画面で変えた設定は、`make vscode-pull` でリポジトリに取り込んでからコミットする

### zsh（`config/zsh/zshrc`）

上から順に読み込む（基本 → WSL の Windows 側のパス → プロキシ → mise → antidote・prezto → 補完 → 環境 → ssh-agent → プロンプト）。

| 内容 | 説明 |
| --- | --- |
| WSL の Windows 側のパス | `appendWindowsPath=false` 前提で必要なものだけ追加。Windows のユーザー名は初回に自動取得してキャッシュ |
| 環境 | ロケール、`EDITOR`（VS Code があれば `code --wait`）、`time` の出力形式、`ls` の色 |
| ssh-agent | WSL では wsl2-ssh-agent 経由で Windows の agent を使う。それ以外は `~/.ssh/agent.sock` で起動して使い回す |

### プロキシ（`proxy` コマンド）

プロキシの一覧を端末ごとの `~/.config/proxy`（リポジトリでは管理しない）に書く。先頭が既定のプロキシ。
`proxy edit` で雛形を作って編集できる。インストーラをプロキシ環境（`https_proxy` を設定した状態）で実行した場合は自動で作られる（WSL 以外）。

```sh
# 名前  URL（先頭が既定のプロキシ）
main  http://proxy1.corp.example:8080
alt   http://proxy2.corp.example:8080
no_proxy  localhost,127.0.0.1,.corp.example
```

- **自動**: シェルの起動時に既定のプロキシへ接続できれば使い、できなければ使わない（社内・VPN では有効、自宅では無効）。判定結果は 60 秒キャッシュする
- **WSL**: 設定ファイルが無ければ、Windows のプロキシ設定（WSL の autoProxy が渡す環境変数）を `system` として使う
- **切り替えは全シェル一斉**。他のシェルは次のプロンプトで追従する。手動の切り替えは再起動（WSL の再起動）まで有効
- 既定以外のプロキシを使っているときは、プロンプトに `proxy:名前` と表示する
- 環境変数（`http_proxy` など大文字・小文字）に加えて、`sudo`（プロキシの変数だけ引き継ぐ）と `svn`（起動時に設定を渡す）にも効く

| コマンド | 動作 |
| --- | --- |
| `proxy` | 現在の状態 |
| `proxy list` | 設定されているプロキシの一覧 |
| `proxy use alt` | 全シェルを alt に切り替える |
| `proxy on` / `proxy off` | 全シェルで既定のプロキシを使う / 使わない |
| `proxy auto` | 自動判定に戻す |
| `proxy run alt -- git clone ...` | そのコマンドだけ alt で実行する |
| `proxy test [URL]` | 全プロキシと直接接続で URL に接続を試す（つながらない宛先で、どのプロキシなら通るかを調べる） |
| `proxy edit` | 設定ファイルを編集する |

プロキシ環境でのインストール方法は [プロキシ環境でのインストール](#プロキシ環境でのインストール) を参照。

### クリップボード

tmux・vim ともに OSC52 で端末（Windows Terminal など）のクリップボードへコピーする。
WSL・SSH 先でも追加ツールなしで動く。

## トラブルシューティング

- 補完やプロンプトの表示がおかしい: `rm -rf ~/.cache/zsh` してから zsh を再起動（キャッシュが再生成される）
- CLI ツールが見つからない: `mise install` を実行
