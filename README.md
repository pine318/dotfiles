# dotfiles

- [masterブランチ](https://github.com/pine318/dotfiles): デフォルト
- [miniブランチ](https://github.com/pine318/dotfiles/tree/mini): 最小限の機能のみ

## 設定方法

1. ダウンロード

   ```sh
   $ git clone https://github.com/pine18/dotfiles.git
   ```

2. `etc/01-system_setup.sh`で必要なパッケージをインストール
3. 必要な環境変数を`~/.zshenv`に設定
   - （WSLを使用する場合）Windows側のユーザ名`$WIN_USER`
   - プロキシ情報`$PROXY_HOST`, `$PROXY_PORT`, `$NO_PROXY_HOSTS`
   - 設定例

     ```shell
     export WIN_USER="username"
     export PROXY_HOST="proxy.example.com"
     export PROXY_PORT="8080"
     export NO_PROXY_HOSTS="127.0.0.1,localhost,192.168.11.1"
     ```

4. `make deploy`でdotfiles配置
5. （必要に応じて）etc内のスクリプトを使って環境構築

## dotfiles削除

- `make clean`でdotfilesのシンボリックリンクをすべて解除

## 注意

- `.zsh`のスクリプトを修正した場合には、`zinit update`による手動適用が必要

## 対象dotfiles

- .p10k.zsh
- .tmux.conf
- .vimrc
- .zshrc
- .zsh(自作スクリプト)
