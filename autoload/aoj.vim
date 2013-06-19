function! aoj#submit_code()
    if bufname('%') == '==AOJ=='
        echoerr 'Invalid buffer'
        return
    endif

    if !exists('g:aoj#now_selected_problem_id')
        echoerr 'Problem ID is Nothing !'
        return
    endif

    let ft = &filetype
    let submit_lang = ''
    for lang in g:api4aoj#can_use_lang_lst
        if lang ==? ft
            let submit_lang = lang
            break
        endif
    endfor

    if submit_lang == ''
        echoerr 'Invalid Submit Language !'
        return
    endif

    if !exists('g:aoj#user_id')
        call aoj#user#set_id_to_variable()
    endif

    if !exists('g:aoj#password')
        call aoj#user#set_password_to_variable()
    endif

    let code = join(getline(1, line('$')), "\n")

    " echomsg g:aoj#user_id
    " echomsg g:aoj#password
    " echomsg code
    " echomsg g:aoj#now_selected_problem_id
    " echomsg submit_lang
    " echomsg s:urlencode_char(code)

    call api4aoj#submit_code(
    \ g:aoj#user_id,
    \ g:aoj#password,
    \ code,
    \ g:aoj#now_selected_problem_id,
    \ submit_lang,
    \ )
endfunction
