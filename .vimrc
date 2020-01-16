"unmap internal vim keybindings"
map s <Nop>
map sa <Nop>
map sca <Nop>
map scb <Nop>
map scc <Nop>
map scd <Nop>
map sce <Nop>
map sg <Nop>
map sc <Nop>
map sr <Nop>
map <S-s> <Nop>
map <C-f> <Nop>
map <C-b> <Nop>

set history=1000
" start vim in full-screen mode
set lines=999 columns=1000
syntax on
set number
"set relativenumber
" hidden allows buffer switching while current buffer is dirty
set hidden
" highlight search matches"
set hlsearch
" ignorecase when searched with lowercase, preserve case(smartcase) when search string contains upper-case letters"
set ignorecase
set smartcase
"highlight current line"
set cursorline
"set font"
set guifont=Courier\ New\ 12
"do not thrown warning when file has been edited"
set autoread



" task: identing autosmartly
" enable indent plugins
filetype plugin indent on
" show existing tab with 4 spaces width
set tabstop=4
" when indenting with '>', use 4 spaces width
set shiftwidth=4
" On pressing tab, insert 4 spaces
set expandtab
"set autoindent "is not recommented
"set smartindent "is not recommended way

"task: comment"

"autocmd FileType matlab nnoremap <buffer> sc I% <esc>j
"autocmd FileType matlab nnoremap <buffer> scr I<ESC>xxxi <ESC>lj
"autocmd FileType matlab vnoremap <buffer> sc I% <esc>
"autocmd FileType matlab vnoremap <buffer> scr xx<esc>

autocmd FileType cpp,cc,hpp,h,javascript nnoremap <buffer> si I// <esc>==
autocmd FileType cpp,cc,hpp,h,javascript nnoremap <buffer> sir I<ESC>xxxi <ESC>==
"autocmd FileType cpp,cc,hpp,h,javascript vnoremap <buffer> sc I// <esc>
"autocmd FileType cpp,cc,hpp,h,javascript vnoremap <buffer> scr xxx<esc>


""autocmd FileType python nnoremap <buffer> sc I# <esc>
""autocmd FileType python nnoremap <buffer> scr I<ESC>xxxi <ESC>l

" task: Automatically closing braces " 
"inoremap { {<CR>}<Esc>ko<tab>
"inoremap [ []<Esc>i
"inoremap ( ()<Esc>i
"inoremap < <><Esc>i
"inoremap " ""<ESC>i
"inoremap ' ''<ESC>i

" edit/add file to p4"
map sp :!p4 edit \<C-r>%  <ENTER>:p4 add \<C-r>% <ENTER>
"copy current line, paste contents into next newline and go there"
map sd VyjP
"save with force (for read-only files)"
map sa :up!<ENTER> 
"source vimrc changes in the current session a "
map sso :source ~/.vimrc<ENTER>
"move through matlab function foward and backward"
map smf /function <ENTER>
map smb ?function <ENTER>
" compile current file using clang++"
map scc :!cd /mathworks/devel/sandbox/ppatil/misc/ContinuousLearning/cpp;make clean;make;<CR>
map scd :!clang++ -fno-elide-constructors %<CR>
map scg :!g++ %<CR>
map sca yiw:!rm temp1.log;clang-check -ast-dump -ast-dump-filter=<C-r>" % > temp1.log<CR>:vs temp1.log<CR>
map scb yiw:!rm temp1.log;clang-check -ast-dump % > temp1.log<CR>:vs temp1.log<CR>
map sce :!rm temp1.log;clang++ -cc1 -ast-dump % >temp1.log<CR>:vs temp1.log<CR>
map scf :!rm temp1.log;clang++ -Xclang -ast-print -fsyntax-only % >temp1.log<CR>:vs temp1.log<CR>
map se :!./bin/exe1<CR>
map sg :!cd /mathworks/devel/sandbox/ppatil/misc/githubroot/documents;rm learning.pdf;pdflatex learning.tex;rm *aux;rm *dvi;rm *log;rm *toc;git add -u; git commit -m "no message";git push -u origin master;<CR>;cd -;<CR>
"open vimrc
map svi :e $s/misc/configurations/.vimrc<CR>
map sbash :e ~/.bashrc<CR>
"replace inner word"
map sr yiw:%s/<C-r>"//gc<left><left><left>
"dirview"
map sdir :vsplit<ENTER><C-w>w:setlocal previewwindow<ENTER><C-w>w:Ex<ENTER>
"delete current buffer
map sh :hide<ENTER>
map so :only<ENTER>
map sb :b #<ENTER>
map -  :Ex<ENTER>
map sf <Leader><Leader>s

function MyGDB()
    :GDB start
    sleep 4 
    :let mypid = $mypid
    :let gdbstring = 'GDB attach ' . mypid
    :execute gdbstring 
endfunction
"au VimEnter * call MyGDB()

