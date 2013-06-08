"-----------------------------------------------------------------------------
" autoload/api4aoj.vim
"   http://judge.u-aizu.ac.jp/onlinejudge/api.jsp
"-----------------------------------------------------------------------------
" {'childNode': function('386'),
"  'name': 'problemmemorylimit',
"  'findAll': function('390'),
"  'attr': {},
"  'find': function('389'),
"  'child': ['^@65536^@'],
"  'childNodes': function('387'),
"  'toString': function('391'),
"  'value': function('388')}
" echomsg string(webapi#xml#parseURI('http://judge.u-aizu.ac.jp/onlinejudge/webservice/problem?id=0002&status=false'))


"-----------------------------------------------------------------------------
" Utils
"-----------------------------------------------------------------------------
function! s:fix_encoding_http_content(content)
    let charset = matchstr(a:content, '<meta[^>]\+content=["''][^;"'']\+;\s*charset=\zs[^;"'']\+\ze["''][^>]*>')

    if len(charset) == 0
        let charset = matchstr(a:content, '<meta\s\+charset=["'']\?\zs[^"'']\+\ze["'']\?[^>]*>')
    endif

    return iconv(a:content, charset, &enc)
endfunction



"-----------------------------------------------------------------------------
" AOJ API
"-----------------------------------------------------------------------------
" User Search API
" http://judge.u-aizu.ac.jp/onlinejudge/api.jsp#user_api
function! api4aoj#search_user(u_id)
    if type("") != type(a:u_id)
        throw 'ERROR - Type is mismatch @search_user in api4aoj'
    endif

    echomsg printf('http://judge.u-aizu.ac.jp/onlinejudge/webservice/user?id=%s', a:u_id)
    return webapi#xml#parseURL(printf('http://judge.u-aizu.ac.jp/onlinejudge/webservice/user?id=%s', a:u_id))
endfunction

" 以下、同じ物が返った
" echomsg string(api4aoj#search_user('s1200007').find('id'))
" echomsg string(api4aoj#search_user('s1200007').childNode('id')
" echomsg string(api4aoj#search_user('s1200007').childNode('status').childNode('submission').value())


" Problem Search API
" http://judge.u-aizu.ac.jp/onlinejudge/api.jsp#problem_api
function! api4aoj#search_problem(p_id, isStatus)
    if (type("") != type(a:p_id)) || (type(0) != type(a:isStatus))
        throw 'ERROR - Type is mismatch @search_problem in api4aoj'
    endif

    return webapi#xml#parseURL(printf('http://judge.u-aizu.ac.jp/onlinejudge/webservice/problem?id=%s&status=%s', a:p_id, (a:isStatus == 0)?('false'):('true')))
endfunction
" echomsg string(api4aoj#search_problem('0002', 0).childNode('name').value())

function! api4aoj#get_problem_discription_lst(p_id)
    if type("") != type(a:p_id)
        throw 'ERROR - Type is mismatch @search_problem in api4aoj'
    endif

    " httpでgetした問題ページのデータを取得
    let res = webapi#http#get(printf('http://judge.u-aizu.ac.jp/onlinejudge/description.jsp?id=%s', a:p_id))

    " 文字エンコードを修正
    let s:encoded_html = s:fix_encoding_http_content(res.content)

    " 不要な要素を削除
    let s:encoded_html = substitute(s:encoded_html, '<!--.\{-}-->', '', 'g')
    let s:encoded_html = substitute(s:encoded_html, '<script[^>]*>.\{-}<\/script>', '', 'g')
    let s:encoded_html = substitute(s:encoded_html, '.*\(<body[^>]*>.*</body>\).*', '\1', '')
    let s:encoded_html = substitute(s:encoded_html, '<\(br\|meta\|link\|hr\)\s*>', '<\1/>', 'g')


    " 文字列からhtmlとしてパース
    let parsed = webapi#html#parse(s:encoded_html)

    let desc_parts = parsed.find({'class' : 'description'}).child

    " 文字列型が混じっているとループで型エラーが起きるため削除
    call filter(desc_parts, 'type(v:val) != type("")')

    let decoded_lst = []
    let is_replace = 0

    " 整形してリストへ
    for d_c in desc_parts
        if -1 != match(string(d_c.attr), 'navi')
            let str = d_c.value()
            let is_replace = 1
        elseif -1 != match(d_c.toString(), '<\(p\|pre\)\s*>')
            let str = '    '.d_c.value()
        elseif -1 != match(string(d_c.attr), 'dat')
            let str = d_c.value()
            let str =  substitute(str, '\s*', '', 'g')
            let is_replace = 1
        else
            let str = d_c.value()
        endif

        if is_replace == 0
            " 改行を削除
            let str  = substitute(str, '\r\|\n', '', 'g')
            let is_replace = 0
        endif

        let str = webapi#html#decodeEntityReference(str)

        if 0 != len(str)
            call add(decoded_lst, str)
        endif
    endfor

    return decoded_lst
endfunction
call s:debug()
