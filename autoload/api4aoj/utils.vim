"-----------------------------------------------------------------------------
" Util Functions
"-----------------------------------------------------------------------------

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


function! api4aoj#utils#set_user_passward_to_variable()
    let password = input('Prease Input Your AOJ Login Passward:')

    if len(password) <= 1
        throw 'ERROR - Passward is too short'
    endif

    let g:api4aoj#password = password
endfunction


function! api4aoj#utils#set_user_id_to_variable()
    let id = input('Prease Input Your AOJ Login ID:')

    if len(id) <= 1
        throw 'ERROR - ID is too short'
    endif

    let g:api4aoj#user_id = id
endfunction
