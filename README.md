# dotfiles

- [masterブランチ](https://github.com/pine318/dotfiles): デフォルト
- [miniブランチ](https://github.com/pine318/dotfiles/tree/mini): 最小限の機能のみ

## 設定方法

1. ダウンロード

   ```sh
   $ git clone -b mini https://github.com/pine18/dotfiles.git
   ```

2. （可能なら）`etc/01-system_setup.sh`で必要なパッケージをインストール
3. `make deploy`でdotfiles配置
4. （必要に応じて）etc内のスクリプトを使って環境構築

## dotfiles削除

- 下記コマンドでdotfilesのシンボリックリンクをすべて解除

  ```sh
  $ make clean
  ```

## 対象dotfiles

- .p10k.zsh
- .tmux.conf
- .vimrc
- .zshrc
