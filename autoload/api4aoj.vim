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
function! api4aoj#get_problem_discription_lst(p_id)
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
            let str  = "\n**" . substitute(d_c.value(), '\r\|\n', '', 'g') . '**'
        elseif -1 != match(string(d_c.attr), 'dat')
            let str = substitute(d_c.value(), '\s*', '', 'g')
        else
            let str = d_c.value()
        endif

        " 記号類をもとに戻す
        let str = webapi#html#decodeEntityReference(str)

        if 0 != len(str)
            call add(decoded_lst, str)
        endif
    endfor

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
function! api4aoj#get_problem_lst(volume_num)
    let  parsed_xml = webapi#xml#parseURL(printf('http://judge.u-aizu.ac.jp/onlinejudge/webservice/problem_list?volume=%s', a:volume_num))

    let problem_lst = []
    for problem in parsed_xml.childNodes('problem')
        call add(problem_lst, {
                    \ 'id' : problem.childNode('id').value(),
                    \ 'name' : problem.childNode('name').value(),
                    \ 'time_limit' : problem.childNode('problemtimelimit').value(),
                    \ 'memory_limit' : problem.childNode('problemmemorylimit').value(),
                    \ })
    endfor

    return problem_lst
endfunction
