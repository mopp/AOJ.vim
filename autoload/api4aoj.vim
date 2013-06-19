"-----------------------------------------------------------------------------
" autoload/api4aoj.vim
"   http://judge.u-aizu.ac.jp/onlinejudge/api.jsp
"-----------------------------------------------------------------------------



"-----------------------------------------------------------------------------
" Variables
"-----------------------------------------------------------------------------
if !exists('g:api4aoj#can_use_lang_lst')
    let g:api4aoj#can_use_lang_lst = [ 'C', 'C++', 'JAVA', 'C++11', 'C#', 'D', 'Ruby', 'Python', 'PHP', 'JavaScript' ]
    lockvar 2 g:api4aoj#can_use_lang_lst
endif


"-----------------------------------------------------------------------------
" AOJ API
"-----------------------------------------------------------------------------
" Get Problem Description API (original)
" @return (List) each elements contains each line
function! api4aoj#get_problem_description_lst(p_id)
    if type("") != type(a:p_id)
        throw 'ERROR - Type is mismatch @search_problem in api4aoj'
    endif

    let get_response = webapi#http#get(printf('http://judge.u-aizu.ac.jp/onlinejudge/description.jsp?id=%s&lang=jp', a:p_id))

    " 文字エンコードを修正
    let encoded_html = api4aoj#utils#fix_encoding_http_content(get_response.content)

    " 不要な要素を削除
    let encoded_html = substitute(encoded_html, '<!--.\{-}-->', '', 'g')
    let encoded_html = substitute(encoded_html, '<script[^>]*>.\{-}<\/script>', '', 'g')
    let encoded_html = substitute(encoded_html, '.*\(<body[^>]*>.*</body>\).*', '\1', '')
    let encoded_html = substitute(encoded_html, '<\(br\|meta\|link\|hr\)\s*>', '<\1/>', 'g')

    " 文字列からhtmlとしてパース
    let dom_obj = webapi#html#parse(encoded_html)

    " 問題文の書いてあるクラス名を指定
    " それ以下の子のリストを取得
    let descript_lst = dom_obj.find({'class' : 'description'}).child

    " 文字列型が混じっているとループで型エラーが起きるため削除
    call filter(descript_lst, 'type(v:val) != type("")')

    let decoded_lst = []

    for d_c in descript_lst
        " 場合分けで文字整形
        if -1 != match(string(d_c.attr), 'navi')
            let str = d_c.value()
        elseif -1 != match(d_c.toString(), '<\(p\|pre\)\s*>')
            let str = '    '.d_c.value()
        elseif -1 != match(string(d_c.toString()), '<h[1-9]\s*>')
            let str  = "--" . api4aoj#utils#remove_cr_eof(d_c.value()) . '--'
        elseif -1 != match(string(d_c.attr), 'dat')
            let str = substitute(d_c.value(), '\s*', '', 'g')
        else
            let str = d_c.value()
        endif

        " 記号類をもとに戻す
        let str = webapi#html#decodeEntityReference(str)
        let str = substitute(str, '&le;', '<=', 'g')
        let str = substitute(str, '&ge;', '>=', 'g')
        " let str = api4aoj#utils#remove_cr_eof(str)
        let str_lst = split(str, "\r")

        if 0 != len(str_lst)
            call extend(decoded_lst, str_lst)
        endif
    endfor

    " NUL文字を削除
    call map(decoded_lst, 'substitute(v:val, "\n", "", "g")')

    " 空白のみの行を削除
    " call filter(decoded_lst, 'len(substitute(v:val, "\s", "", "g"))')

    return decoded_lst
endfunction


" Submit Your Source Code (original)
function! api4aoj#submit_code(u_id, password, code, p_id, lang)
    if index(g:api4aoj#can_use_lang_lst, a:lang) == -1
        throw 'ERROR - Set Language is Nothing @submit_code in api4aoj'
    endif

    let param = {
                \ 'userID'     : a:u_id,
                \ 'password'   : a:password,
                \ 'sourceCode' : a:code,
                \ 'problemNO'  : a:p_id,
                \ 'language'   : a:lang,
                \ }

    return webapi#http#post('http://judge.u-aizu.ac.jp/onlinejudge/servlet/Submit', param)
endfunction


" Search User (http://judge.u-aizu.ac.jp/onlinejudge/api.jsp#user_api)
function! api4aoj#get_user_info(u_id)
    if type("") != type(a:u_id)
        throw 'ERROR - Type is mismatch @search_user in api4aoj'
    endif

    return webapi#xml#parseURL(printf('http://judge.u-aizu.ac.jp/onlinejudge/webservice/user?id=%s', a:u_id))
endfunction


" Search Problem (http://judge.u-aizu.ac.jp/onlinejudge/api.jsp#problem_api)
function! api4aoj#get_problem_info(p_id, isStatus)
    if (type("") != type(a:p_id)) || (type(0) != type(a:isStatus))
        throw 'ERROR - Type is mismatch @search_problem in api4aoj'
    endif

    return webapi#xml#parseURL(printf('http://judge.u-aizu.ac.jp/onlinejudge/webservice/problem?id=%s&status=%s', a:p_id, (a:isStatus == 0)?('false'):('true')))
endfunction


" Problem List Search (http://judge.u-aizu.ac.jp/onlinejudge/webservice/problem_list)
" @return (Dictionary) id, name, time_limit, memory_limit
function! api4aoj#get_problem_lst(volume_num)
    let parsed_xml = webapi#xml#parseURL(printf('http://judge.u-aizu.ac.jp/onlinejudge/webservice/problem_list?volume=%s', a:volume_num))

    let problem_lst = []
    for problem in parsed_xml.childNodes('problem')
        call add(problem_lst, {
                    \ 'id'           : api4aoj#utils#remove_cr_eof(problem.childNode('id').value()),
                    \ 'name'         : api4aoj#utils#remove_cr_eof(problem.childNode('name').value()),
                    \ 'time_limit'   : api4aoj#utils#remove_cr_eof(problem.childNode('problemtimelimit').value()),
                    \ 'memory_limit' : api4aoj#utils#remove_cr_eof(problem.childNode('problemmemorylimit').value()),
                    \ })
    endfor

    return problem_lst
endfunction


" Get User Solved Info List (http://judge.u-aizu.ac.jp/onlinejudge/webservice/solved_record)
function! api4aoj#get_user_solved_info_lst(u_id, ...)
    if a:0 == 0
        let parsed_xml = webapi#xml#parseURL(printf('http://judge.u-aizu.ac.jp/onlinejudge/webservice/solved_record?user_id=%s', a:u_id))
    elseif a:0 == 1
        " 第二引数があるとき
        if index(g:api4aoj#can_use_lang_lst, a:000[0]) == -1
            throw 'ERROR - Set Language is Nothing @get_user_solved_info_lst in api4aoj'
        endif

        let parsed_xml = webapi#xml#parseURL(printf('http://judge.u-aizu.ac.jp/onlinejudge/webservice/solved_record?user_id=%s&language=%s', a:u_id, a:000[0]))
    endif

    if len(parsed_xml.child) <= 1
        return []
    endif

    let solved_lst = []
    for solve in parsed_xml.childNodes('solved')
        call add(solved_lst, {
                    \ 'run_id'      : api4aoj#utils#remove_cr_eof(solve.childNode('run_id').value()),
                    \ 'problem_id'  : api4aoj#utils#remove_cr_eof(solve.childNode('problem_id').value()),
                    \ 'date'        : api4aoj#utils#remove_cr_eof(solve.childNode('date').value()),
                    \ 'language'    : api4aoj#utils#remove_cr_eof(solve.childNode('language').value()),
                    \ 'cputime'     : api4aoj#utils#remove_cr_eof(solve.childNode('cputime').value()),
                    \ 'used_memory' : api4aoj#utils#remove_cr_eof(solve.childNode('memory').value()),
                    \ 'code_size'   : api4aoj#utils#remove_cr_eof(solve.childNode('code_size').value()),
                    \ })
    endfor

    return solved_lst
endfunction


" Get Judge Status Log List (http://judge.u-aizu.ac.jp/onlinejudge/webservice/status_log)
function! api4aoj#get_judge_status_log_lst(...)
    if a:0 == 0
        let parsed_xml = webapi#xml#parseURL('http://judge.u-aizu.ac.jp/onlinejudge/webservice/status_log?limit=50')
    elseif a:0 == 1
        " 第二引数があるとき
        " let parsed_xml = webapi#xml#parseURL(printf('http://judge.u-aizu.ac.jp/onlinejudge/webservice/status_log?user_id=%s', a:000[0]))
        throw 'reserved!'
    endif

    if len(parsed_xml.child) <= 1
        return []
    endif

    let status_lst = []
    for status in parsed_xml.childNodes('status')
        call add(status_lst, {
                    \ 'run_id'              : api4aoj#utils#remove_cr_eof(status.childNode('run_id').value()),
                    \ 'user_id'             : api4aoj#utils#remove_cr_eof(status.childNode('user_id').value()),
                    \ 'problem_id'          : api4aoj#utils#remove_cr_eof(status.childNode('problem_id').value()),
                    \ 'submission_date'     : api4aoj#utils#remove_cr_eof(status.childNode('submission_date').value()),
                    \ 'submission_date_str' : api4aoj#utils#remove_cr_eof(status.childNode('submission_date_str').value()),
                    \ 'status'              : api4aoj#utils#remove_cr_eof(status.childNode('status').value()),
                    \ 'language'            : api4aoj#utils#remove_cr_eof(status.childNode('language').value()),
                    \ 'cputime'             : api4aoj#utils#remove_cr_eof(status.childNode('cputime').value()),
                    \ 'memory'              : api4aoj#utils#remove_cr_eof(status.childNode('memory').value()),
                    \ 'code_size'           : api4aoj#utils#remove_cr_eof(status.childNode('code_size').value()),
                    \ })
    endfor

    return status_lst
endfunction


function! api4aoj#get_judge_detail(run_id)
    let info = webapi#xml#parseURL('http://judge.u-aizu.ac.jp/onlinejudge/webservice/judge?id=' . a:run_id)

    return {
                \ 'judge_id'                : api4aoj#utils#remove_cr_eof(info.childNode('judge_id').value()),
                \ 'judge_type_code'         : api4aoj#utils#remove_cr_eof(info.childNode('judge_type_code').value()),
                \ 'judge_type'              : api4aoj#utils#remove_cr_eof(info.childNode('judge_type').value()),
                \ 'submissiondate'          : api4aoj#utils#remove_cr_eof(info.childNode('submissiondate').value()),
                \ 'judgedate'               : api4aoj#utils#remove_cr_eof(info.childNode('judgedate').value()),
                \ 'submissiondate_locale'   : api4aoj#utils#remove_cr_eof(info.childNode('submissiondate_locale').value()),
                \ 'judgedate_locale'        : api4aoj#utils#remove_cr_eof(info.childNode('judgedate_locale').value()),
                \ 'language'                : api4aoj#utils#remove_cr_eof(info.childNode('language').value()),
                \ 'server'                  : api4aoj#utils#remove_cr_eof(info.childNode('server').value()),
                \ 'cuptime'                 : api4aoj#utils#remove_cr_eof(info.childNode('cuptime').value()),
                \ 'memory'                  : api4aoj#utils#remove_cr_eof(info.childNode('memory').value()),
                \ 'code_size'               : api4aoj#utils#remove_cr_eof(info.childNode('code_size').value()),
                \ 'status'                  : api4aoj#utils#remove_cr_eof(info.childNode('status').value()),
                \ 'accuracy'                : api4aoj#utils#remove_cr_eof(info.childNode('accuracy').value()),
                \ 'problem_id'              : api4aoj#utils#remove_cr_eof(info.childNode('problem_id').value()),
                \ 'problem_title'           : api4aoj#utils#remove_cr_eof(info.childNode('problem_title').value()),
                \ 'submissions'             : api4aoj#utils#remove_cr_eof(info.childNode('submissions').value()),
                \ 'accepted'                : api4aoj#utils#remove_cr_eof(info.childNode('accepted').value()),
                \ 'solved'                  : api4aoj#utils#remove_cr_eof(info.childNode('solved').value()),
                \ 'user_id'                 : api4aoj#utils#remove_cr_eof(info.childNode('user_id').value()),
                \ 'user_name'               : api4aoj#utils#remove_cr_eof(info.childNode('user_name').value()),
                \ 'affiliation'             : api4aoj#utils#remove_cr_eof(info.childNode('affiliation').value()),
                \ }
endfunction
