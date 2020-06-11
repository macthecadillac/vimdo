let g:axe#split_direction = get(g:, 'axe#split_direction', 'down')
let g:axe#terminal_jobs = {}
let g:axe#background_jobs = {}
let g:axe#floats = []
let g:axe#exit_message = get(
      \ g:,
      \ 'axe#exit_message',
      \ '\n-------------------------\nPress ENTER to exit'
      \ )
let g:axe#term_height = get(g:, 'axe#term_height', 15)
let g:axe#term_width = get(g:, 'axe#term_width', 79)
let g:axe#remove_term_buffer_when_done = get(g:, 'axe#remove_term_buffer_when_done', 1)
let g:axe#cmds = get(g:, 'axe#cmds', {})
let g:axe#with_filename = get(g:, 'axe#with_filename', 1)
let g:axe#in_term = get(g:, 'axe#in_term', 0)
let g:axe#exe_in_proj_root = get(g:, 'axe#exe_in_proj_root', 0)
let g:axe#show_stderr_on_error = get(g:, 'axe#show_stderr_on_error', 1)
let g:axe#show_stderr_in_split = get(g:, 'axe#show_stderr_in_split', 1)
let g:axe#show_stderr_in_float = get(g:, 'axe#show_stderr_in_float', 0)
let g:axe#show_stderr_in_cmdline = get(g:, 'axe#show_stderr_in_cmdline', 0)
let g:axe#show_stdout = get(g:, 'axe#show_stdout_on_error', 0)
let g:axe#show_stdout_in_split = get(g:, 'axe#show_stdout_in_split', 0)
let g:axe#show_stdout_in_float = get(g:, 'axe#show_stdout_in_float', 0)
let g:axe#show_stdout_in_cmdline = get(g:, 'axe#show_stdout_in_cmdline', 1)
let g:axe#filetype_defaults = get(g:, 'axe#filetype_defaults', {})
let g:axe#float_width = get(g:, 'axe#float_width', 67)
let g:axe#float_height = get(g:, 'axe#float_height', 67)

let g:axe#global_defaults = {
      \ 'with_filename': g:axe#with_filename,
      \ 'in_term': g:axe#in_term,
      \ 'exe_in_proj_root': g:axe#exe_in_proj_root,
      \ 'show_stderr_on_error': g:axe#show_stderr_on_error,
      \ 'show_stderr_in_split': g:axe#show_stderr_in_split,
      \ 'show_stderr_in_float': g:axe#show_stderr_in_float,
      \ 'show_stderr_in_cmdline': g:axe#show_stderr_in_cmdline,
      \ 'show_stdout': g:axe#show_stdout,
      \ 'show_stdout_in_split': g:axe#show_stdout_in_split,
      \ 'show_stdout_in_float': g:axe#show_stdout_in_float,
      \ 'show_stdout_in_cmdline': g:axe#show_stdout_in_cmdline,
      \ 'float_width': g:axe#float_width,
      \ 'float_height': g:axe#float_height,
      \ }

command! -nargs=1 -complete=custom,axe#complete_commands Axe call axe#execute_subcmd(<f-args>)
command! AxeProcs call axe#list_background_processes()
command! -nargs=1 AxeStop call axe#stop_process(<f-args>)
command! AxeList call axe#list_commands()
