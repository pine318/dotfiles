" 基本設定
" OSのクリップボードと連動
set clipboard+=unnamed
" 字下げ・行頭・行末を削除可能に
set backspace=indent,eol,start
" 文字コードをUFT-8に設定
set fenc=utf-8
" バックアップファイルを作らない
set nobackup
" スワップファイルを作らない
set noswapfile
" 編集中のファイルが変更されたら自動で読み直す
set autoread
" バッファが編集中でもその他のファイルを開けるように
set hidden
" 入力中のコマンドをステータスに表示する
set showcmd
" Ctrl-aで行頭に移動
nnoremap <C-a> ^
inoremap <C-a> <C-o>^
" Ctrl-eで行末に移動
nnoremap <C-e> $
inoremap <C-e> <C-o>$
" Ctrl-tでターミナル起動
nnoremap <C-t> :bo terminal<CR>
" ターミナルモード時，Ctrl-qでターミナル終了
tnoremap <C-t> <C-w><C-c><C-w><C-q>


" 表示設定
" 行番号を表示
set number
" Ctrl-nで行番号の表示/非表示切り替え
nnoremap <C-n> :set invnumber<CR>
" 現在の行を強調表示
set cursorline
" 行末の1文字先までカーソルを移動できるように
set virtualedit=onemore
" インデントはスマートインデント
set smartindent
" 括弧入力時の対応する括弧を表示
set showmatch
" ステータスラインを常に表示
set laststatus=2
" コマンドラインの補完
set wildmode=list:longest
" 折り返し時に表示行単位での移動できるようにする
nnoremap j gj
nnoremap k gk
nnoremap <Down> gj
nnoremap <Up> gk
" シンタックスハイライトの有効化
syntax enable


" TAB設定
" 不可視文字を可視化(タブが「▸-」と表示される)
" set list listchars=tab:\▸\-
" Tab文字を半角スペースにする
set expandtab
" 行頭以外のTab文字の表示幅（スペースいくつ分）
set tabstop=2
" 行頭でのTab文字の表示幅
set shiftwidth=2


" 検索設定
" 検索文字列が小文字の場合は大文字小文字を区別なく検索する
set ignorecase
" 検索文字列に大文字が含まれている場合は区別して検索する
set smartcase
" 検索文字列入力時に順次対象文字列にヒットさせる
set incsearch
" 検索時に最後まで行ったら最初に戻る
set wrapscan
" 検索語をハイライト表示
set hlsearch
" ESC連打でハイライト解除
nmap <Esc><Esc> :nohlsearch<CR><Esc>
