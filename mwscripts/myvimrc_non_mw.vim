function! BufferSelect()
    execute("buffers")
    :call BufferSelectBase()
endfunction
function! BufferSelectAll()
    execute("buffers!")
    :call BufferSelectBase()
endfunction
function! BufferSelectBase()
    let chr = input("Enter Buffer Number: ")
    execute(":silent b " . chr)
endfunction

map sb <nop>
map sb :call BufferSelect()<CR>
map s1b <nop>
map s1b :call BufferSelectAll()<CR>



