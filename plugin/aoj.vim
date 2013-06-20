" enable Language
let g:api4aoj#can_use_lang_lst = [ 'C', 'C++', 'JAVA', 'C++11', 'C#', 'D', 'Ruby', 'Python', 'PHP', 'JavaScript' ]


" Command
command! AOJSubmit call aoj#submit_code()
command! -nargs=1 AOJSubmitByProblemID call aoj#submit_code(<args>)
command! AOJViewProblems :Unite AOJ_Problems
command! AOJViewStaticticsLogs :Unite AOJ_Statictics
