function! s:debug()
    call api4aoj#utils#set2val_user_passward()
endfunction

command! ExeAOJ call s:debug()
