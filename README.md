# dotfiles

## 設定方法

1. ダウンロード

   ```sh
   $ git clone https://github.com/pine18/dotfiles.git
   ```

2. （必要に応じて）etc内のスクリプトを使って環境構築
3. dotfiles設置

   ```sh
   $ make deploy
   ```

## 設定解除

- 下記コマンドでdotfilesのシンボリックリンクを全て解除

  ```sh
  $ make clean
  ```

## 対象dotfiles

- zsh
- tmux
- vim
