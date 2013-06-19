let s:save_cpo = &cpo
set cpo&vim



function! unite#sources#aoj_statistics_list#define()
    return s:source
endfunction


let s:source = {
            \ 'name' : 'AOJ/StatisticsList',
            \ 'description' : 'candidates from AOJ Statistics List',
            \ 'is_volatile' : 0,
            \ 'action_table' : {
            \   'openable' : {
            \       'vsplit' : {
            \           'description' : 'get Problem Description',
            \           'is_selectable' : 0,
            \       },
            \   },
            \ },
            \ 'default_action' : {
            \   'openable' : 'vsplit'
            \ },
            \}


function! s:source.gather_candidates(args, context)
    let candidates = []
    let statistics = api4aoj#get_judge_status_log_lst()

    for s_log in statistics
        call add(candidates, {
                    \ 'word' : '[' . printf('%5d', s_log.problem_id) . '] '. printf('%24s', s_log.status) . ' : ' . '(' . printf('%3s', s_log.language) . ')' . ' - ' . s_log.user_id,
                    \ 'kind' : 'openable',
                    \ 'source__selected_statistics_log' : [s_log],
                    \ })
    endfor

    return candidates
endfunction


" kind openableの各action実行関数
function! s:source.action_table.openable.vsplit.func(candidate)
    let selected_log = a:candidate.source__selected_statistics_log[0]
    let description_lst = api4aoj#get_problem_description_lst(selected_problem.id)

    if bufexists('==AOJ_Log==')
        execute 'bwipeout! ==AOJ=='
    endif
    execute 'topleft vsplit ==AOJ=='

    setlocal buftype=nowrite
    setlocal noswapfile
    setlocal bufhidden=wipe
    setlocal buftype=nofile
    setlocal nolist
    setlocal nofoldenable
    setlocal textwidth=0
    setlocal wrap
    setlocal fileencodings=utf-8 fileencoding=utf-8
    setlocal filetype=text

    setlocal modifiable
    call append(0, selected_problem.id . ' - ' . selected_problem.name)
    call append(1, '')
    call append(2, description_lst)
    setlocal nomodifiable
    call cursor(1, 1)

    let g:aoj#now_selected_problem_id = selected_problem.id
    " let b:aoj_now_selected_problem_id = selected_problem.id
endfunction



let &cpo = s:save_cpo
unlet s:save_cpo
