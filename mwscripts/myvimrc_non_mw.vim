function! BufferSelect()
    execute("buffers")
    :call BufferSelectBase()
endfunction
function! BufferSelectAll()
    execute("buffers!")
    :call BufferSelectBase()
endfunction
function! BufferSelectBase()
    echo "Enter buffer number: "
    let chr = getchar()
    echo "opening " . nr2char(chr)
    execute("b " . nr2char(chr))
endfunction

map sb <nop>
map sb :call BufferSelect()<CR>
map s1b <nop>
map s1b :call BufferSelectAll()<CR>



