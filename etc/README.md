# 環境構築用スクリプト

## 処理内容

1. 必須パッケージインストール
2. 日本語設定

## 動作確認済み

- Ubuntu 22.04 LTS

## 実行手順

```sh
$ cd ~/dotfiles
$ ./etc/01-system_setup.sh
...
# dotfilesのシンボリックリンク作成
$ make deploy
# 一度ログアウトし，ログインしなおす

# 必要に応じて日本語設定
$ ./etc/02-ja_setup.sh
...
```
