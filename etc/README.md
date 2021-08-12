# 環境構築用スクリプト

## 処理内容

1. 必須パッケージインストール

## 動作確認済み

- Ubuntu 20.04 LTS

## 実行手順

```sh
$ cd ~/dotfiles
# aptが使用可能なら
$ ./etc/01-system_setup.sh
...
# dotfilesのシンボリックリンク作成
$ make deploy
# 一度ログアウトし，ログインしなおす

# aptが使用可能なら
$ ./etc/02-ja_setup.sh
```
