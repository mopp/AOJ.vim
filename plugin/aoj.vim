" enable Language
let g:api4aoj#can_use_lang_lst = [ 'C', 'C++', 'JAVA', 'C++11', 'C#', 'D', 'Ruby', 'Python', 'PHP', 'JavaScript' ]


" Command
command! AOJSubmit call aoj#submit_code()
command! AOJViewProblems :Unite AOJ/ProblemList
command! AOJViewStaticticsLogs :Unite AOJ/StatisticsList
