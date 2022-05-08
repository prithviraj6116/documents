"function VundleInit()
"    set rtp+=~/.vim/bundle/Vundle.vim
"    call vundle#begin()
"    Plugin 'VundleVim/Vundle.vim'
"    Plugin 'gcmt/taboo.vim'
"    " Plugin 'vim-scripts/Conque-GDB'
"    Plugin 'easymotion/vim-easymotion'
"    call vundle#end()
"endfunction
"

set swapfile
set dir=/tmp
set history=1000
set lines=999 columns=1000
syntax on
highlight cursor guifg=red guibg=yellow
highlight statusline guifg=green guibg=red
set laststatus=2
set number
set hidden
set hlsearch
set ignorecase
set smartcase
set cursorline
set guifont=Courier\ New\ 12
set autoread
set tabstop=4
set shiftwidth=4
set expandtab
set tags=./tags;,./gems.tags;
set showcmd
set ruler
set incsearch
filetype plugin indent on
set verbose=5
"let g:netrw_preview = 1



"map - :Ex<ENTER>
"map s <Nop>
"map sv <Leader><Leader>s
"map sr yiw:,$s/<C-r>"//gc<left><left><left>
"map srf yiw:%s/<C-r>"//gc<left><left><left>
"map sd VyjP
"map sa :up!<ENTER>
"map sg :!g++ cpp1.cpp -std=c++17;./a.out;<ENTER>
"map s1g :!g++ -E cpp1.cpp;<ENTER>
"map sm 0f<SPACE>f<SPACE>f<SPACE>lvf:h"ay<ESC>f:lvf<SPACE>"by<C-W>w:e +<C-R>b <C-R>a<CR><C-W>w<C-W>w
"map s2g :!git add -u;git commit -m "abc";git push<ENTER>
"
"ident whole file 
"map si gg=G`'<ENTER> 
"map sg F<SPACE>"byf:f:l"cyf<SPACE><C-w>w:e<C-R>b<BACKSPACE><CR>:<C-R>c<CR>
"
"map d <Nop>
"map sc <C-]>
"map df <C-t>
"
"map f <Nop>
"map fd [m
"map ff ]m
"map fD ]M
"map gg <C-t>
"
"
":call VundleInit()

