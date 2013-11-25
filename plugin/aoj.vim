if exists('g:loaded_aoj') || 1 == &compatible
    finish
endif
let g:loaded_aoj= 1

" Enable Language
let g:api4aoj#can_use_lang_dict = get(g:, 'api4aoj#can_use_lang_dict', { 'c' : 'C', 'cpp' : 'C++', 'java' : 'JAVA', 'cs' : 'C#','d' : 'D', 'rb' : 'Ruby', 'python' : 'Python', 'php' : 'PHP', 'js' : 'JavaScript' })


" Command
command! AOJSubmit call aoj#submit_code()
command! -nargs=1 AOJSubmitByProblemID call aoj#submit_code(<args>)
command! AOJViewProblems :Unite AOJ_Problems
command! AOJViewStaticticsLogs :Unite AOJ_Statictics
