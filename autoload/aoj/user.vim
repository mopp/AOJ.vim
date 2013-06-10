function! aoj#user#set_password_to_variable()
    let password = input('Prease Input Your AOJ Login Passward:')

    if len(password) <= 1
        throw 'ERROR - Passward is too short'
    endif

    let g:aoj#password = password
endfunction


function! aoj#user#set_id_to_variable()
    let id = input('Prease Input Your AOJ Login ID:')

    if len(id) <= 1
        throw 'ERROR - ID is too short'
    endif

    let g:aoj#user_id = id
endfunction
