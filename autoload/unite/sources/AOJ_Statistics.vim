let s:save_cpo = &cpo
set cpo&vim

let s:judge_status_lst = [ 'Compile Error', 'Wrong Answer', 'Time Limit Exceeded', 'Memory Limit Exceeded', 'Accepted', 'Output Limit Exceeded', 'Runtime Error', 'Presentation Error', ]


function! unite#sources#AOJ_Statistics#define()
    return s:source
endfunction


let s:source = {
            \ 'name' : 'AOJ_Statictics',
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
    let judge_info_dict = api4aoj#get_judge_detail(selected_log.run_id)

    if bufexists('==AOJ_Log==')
        execute 'bwipeout! ==AOJ_Log=='
    endif
    execute 'botright split ==AOJ_Log=='
    resize 12

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

    let format = '%14s - %10s'
    let str_lst = []
    call add(str_lst, printf(format, 'Run ID',          judge_info_dict.judge_id))
    call add(str_lst, printf(format, 'Status',          s:judge_status_lst[judge_info_dict.status]))
    call add(str_lst, printf(format, 'Problem ID',      judge_info_dict.problem_id))
    call add(str_lst, printf(format, 'Problem Title',   judge_info_dict.problem_title))
    call add(str_lst, printf(format, 'User ID',         judge_info_dict.user_id))
    call add(str_lst, printf(format, 'Judge Type',      judge_info_dict.judge_type))
    call add(str_lst, printf(format, 'Submition Date',  strftime("%Y-%m-%d %H:%M:%S", judge_info_dict.language)))
    call add(str_lst, printf(format, 'Language',        judge_info_dict.submissiondate_locale))
    call add(str_lst, printf(format, 'CPU Time',        judge_info_dict.cputime))
    call add(str_lst, printf(format, 'Memory',          judge_info_dict.memory))
    call add(str_lst, printf(format, 'Code Size',       judge_info_dict.code_size))

    setlocal modifiable
    call append(0, str_lst)
    setlocal nomodifiable
    call cursor(1, 1)

    noremap <buffer><silent> q :q!<CR>

    wincmd w
endfunction



let &cpo = s:save_cpo
unlet s:save_cpo
