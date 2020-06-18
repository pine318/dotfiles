# 環境構築用スクリプト

## 処理内容

1. zshのインストール
2. [prezto](https://github.com/sorin-ionescu/prezto)のインストール
   - インストール後，makeコマンドでdotfilesのシンボリックリンク作成
3. 日本語設定
4. [Homebrew](https://brew.sh/)のインストール
   - [rmtree](https://github.com/beeftornado/homebrew-rmtree)インストール
     - 依存関係を考慮して，不要なformulaを削除をしてくれる
     - [zsh-completions](https://github.com/zsh-users/zsh-completions)のインストール
5. [pyenv](https://github.com/pyenv/pyenv)のインストール（Homebrew使用）
6. pyenvを用いてpython3系の最新版をインストール
7. pip関連の処理
   - パッケージ更新
   - [pip-autoremove](https://github.com/invl/pip-autoremove)のインストール
     - 依存関係を考慮して，不要なパッケージを削除をしてくれる
   - [pipenv](https://github.com/pypa/pipenv)のインストール

## 動作確認済み

- Ubuntu Server 20.04 LTS

## 実行手順

- 1., 2.以外は必要に応じて実行

```sh
$ chmod +x ./*sh
# 順番通りに実行
$ ./01-zsh_setup.sh
...
$ ./02-zprezto_setup.zsh
...
# dotfilesのシンボリックリンク作成
$ cd ~/dotfiles
$ make deploy
# 一度ログアウトし，ログインしなおす

# 必要に応じて以降のスクリプトを順番通りに実行
$ cd etc
$ ./03-ja_setup.sh
...

$ rm -f ~/.zcompdump; compinit
# 最後に再起動
$ sudo shutdown -r now
```
