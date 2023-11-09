
syntax on
filetype plugin indent on
set swapfile
set dir=/tmp
set history=1000
set lines=999 columns=1000
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
set verbose=0

highlight DiffAdd    cterm=bold ctermfg=10 ctermbg=17 gui=bold guifg=blue guibg=green
highlight DiffDelete cterm=bold ctermfg=10 ctermbg=17 gui=bold guifg=blue guibg=red
highlight DiffChange cterm=bold ctermfg=10 ctermbg=17 gui=bold guifg=blue guibg=yellow
highlight DiffText   cterm=bold ctermfg=10 ctermbg=88 gui=bold guifg=blue guibg=pink


map sr yiw:,$s/<C-r>"//gc<left><left><left>
map srf yiw:%s/<C-r>"//gc<left><left><left>
map sa :up!<ENTER>
map s1g :!cd ~/Downloads/stu1;rm cpp1;g++ cpp1.cpp -o cpp1 -std=c++17;./cpp1;cd -<ENTER>
map s2g :!git add -u;git commit -m "incremental changes sfcoverage";git push<ENTER>
map s3g :!cd ~/Downloads/langcpp/;rm ./ro;rustc  % -o ro;./ro<ENTER>
map sb <C-w><C-w><C-d><C-w><C-w>
map sc <C-w><C-w><C-u><C-w><C-w>

function VundleInit()
    set rtp+=~/.vim/bundle/Vundle.vim
    call vundle#begin()
    Plugin 'VundleVim/Vundle.vim'
    Plugin 'ycm-core/YouCompleteMe'
    "Plugin 'SirVer/ultisnips'
    "Plugin 'honza/vim-snippets'
    Plugin 'easymotion/vim-easymotion'
    Plugin 'machakann/vim-Verdin'
    call vundle#end()
endfunction


:call VundleInit()
set completeopt-=preview
let g:ycm_auto_hover='' "CursorHold
let g:Verdin#autocomplete = 1











"highlight cursor guifg=red guibg=blue
"highlight statusline guifg=green guibg=red
"let g:netrw_preview = 1
"
"map - :Ex<ENTER>
"map sh <Nop>
"map sv <Leader><Leader>s
"map sd VyjP
"map sn <C-w>w<C-n><ENTER>
"map s1g :!g++ -E cpp1.cpp;<ENTER>
"map sm 0f<SPACE>f<SPACE>f<SPACE>lvf:h"ay<ESC>f:lvf<SPACE>"by<C-W>w:e +<C-R>b <C-R>a<CR><C-W>w<C-W>w
"map s2g :!git add -u;git commit -m "abc";git push<ENTER>
"ident whole file 
"map si gg=G`'<ENTER> 
"map sg F<SPACE>"byf:f:l"cyf<SPACE><C-w>w:e<C-R>b<BACKSPACE><CR>:<C-R>c<CR>
"map d <Nop>
"map sc <C-]>
"map df <C-t>
"map f <Nop>
"map fd [m
"map ff ]m
"map fD ]M
"map gg <C-t>
"
