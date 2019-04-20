let g:axe#split_direction = get(g:, 'axe#split_direction', 'down')
let g:axe#terminal_jobs = {}
let g:axe#background_jobs = {}
let g:axe#exit_message = get(
      \ g:,
      \ 'axe#exit_message',
      \ '\n-------------------------\nPress ENTER to exit'
      \ )
let g:axe#term_height = get(g:, 'axe#term_height', 15)
let g:axe#term_width = get(g:, 'axe#term_width', 79)
let g:axe#remove_term_buffer_when_done = get(g:, 'axe#remove_term_buffer_when_done', 1)
let g:axe#cmds = get(g:, 'axe#cmds', {})

command! -nargs=1 -complete=custom,axe#complete_commands Axe call axe#call(<f-args>)
command! AxeProcs call axe#list_background_processes()
command! -nargs=1 AxeStop call axe#stop_process(<f-args>)
command! AxeList call axe#list_commands()
