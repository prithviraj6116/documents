
set swapfile
set dir=~/tmp
set history=1000
set lines=999 columns=1000
syntax on
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

let g:netrw_preview = 1
filetype plugin indent on


map s <Nop>
map sr <Nop>
map sr yiw:,$s/<C-r>"//gc<left><left><left>
map srf <Nop>
map srf yiw:%s/<C-r>"//gc<left><left><left>
map sd <Nop>
map sd VyjP




