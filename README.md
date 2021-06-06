# dotfiles

## 設定方法

1. ダウンロード

   ```sh
   $ git clone https://github.com/pine18/dotfiles.git
   ```

2. `make deploy`でdotfiles配置
3. （必要に応じて）etc内のスクリプトを使って環境構築

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
