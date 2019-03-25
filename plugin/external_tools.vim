let g:external_tools#split_direction = get(g:, 'external_tools#split_direction', 'down')
let g:external_tools#terminal_jobs = {}
let g:external_tools#background_jobs = {}
let g:external_tools#exit_message = get(
      \ g:,
      \ 'external_tools#exit_message',
      \ '\n-------------------------\nPress ENTER to exit'
      \ )
let g:external_tools#term_height = get(g:, 'external_tools#term_height', 15)
let g:external_tools#term_width = get(g:, 'external_tools#term_width', 79)
let g:external_tools#remove_term_buffer_when_done = get(g:, 'external_tools#remove_term_buffer_when_done', 1)
let g:external_tools#cmds = get(g:, 'external_tools#cmds', {})

command! -nargs=1 ExtCmd call external_tools#call(<f-args>)
command! ExtCmdListProcs call external_tools#list_background_processes()
command! -nargs=1 ExtCmdStop call external_tools#stop_process(<f-args>)
command! ExtCmdListCmds call external_tools#list_commands()
