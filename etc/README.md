# 環境構築用スクリプト

## 処理内容

1. 必須パッケージインストール
2. 日本語設定
3. pythonに必要なパッケージインストール．pyenvを用いてpython3系の最新版をインストール
4. [Homebrew](https://brew.sh/)のインストール

## 動作確認済み

- Ubuntu 20.04 LTS

## 実行手順

```sh
$ cd ~/dotfiles
$ ./etc/01-system_setup.sh
...
# dotfilesのシンボリックリンク作成
$ make deploy
# 一度ログアウトし，ログインしなおす

# 必要に応じて以降のスクリプトを順番通りに実行
$ ./etc/02-ja_setup.sh
...
$ ./etc/03-py_setup.zsh
...
$ ./etc/04-brew_setup.zsh
...
$ brew bundle ./etc/Brewfile
...
```
