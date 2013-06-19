"-----------------------------------------------------------------------------
" Util Functions
"-----------------------------------------------------------------------------
let s:save_cpo = &cpo
set cpo&vim



function! api4aoj#utils#fix_encoding_http_content(content)
    let charset = matchstr(a:content, '<meta[^>]\+content=["''][^;"'']\+;\s*charset=\zs[^;"'']\+\ze["''][^>]*>')

    if len(charset) == 0
        let charset = matchstr(a:content, '<meta\s\+charset=["'']\?\zs[^"'']\+\ze["'']\?[^>]*>')
    endif

    return iconv(a:content, charset, &enc)
endfunction



function! api4aoj#utils#convert_file2str(file_path)
    let e_file_path = expand(a:file_path)

    if !filereadable(e_file_path)
        throw 'ERROR - cannot read file ' . e_file_path
    endif

    let file = readfile(e_file_path)

    let str = ''
    for line in file
        let str .= line."\n"
    endfor

    return str
endfunction


function! api4aoj#utils#remove_cr_eof(str)
    return substitute(a:str, '\r\|\n', '', 'g')
endfunction



let &cpo = s:save_cpo
unlet s:save_cpo
