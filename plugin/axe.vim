let g:axe#split_direction = get(g:, 'axe#split_direction', 'down')
let g:axe#terminal_jobs = {}
let g:axe#background_jobs = {}
let g:axe#floats = {}
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
let g:axe#show_stdout_in_split = get(g:, 'axe#show_stdout_in_split', 0)
let g:axe#show_stdout_in_float = get(g:, 'axe#show_stdout_in_float', 0)
let g:axe#show_stdout_in_cmdline = get(g:, 'axe#show_stdout_in_cmdline', 0)
let g:axe#filetype_defaults = get(g:, 'axe#filetype_defaults', {})
let g:axe#float_fit_to_content = get(g:, 'axe#float_fit_to_content', 1)
let g:axe#float_width = get(g:, 'axe#float_width', 67)
let g:axe#float_height = get(g:, 'axe#float_height', 67)

let g:axe#float_term_height_pct = get(g:, 'axe#float_term_height_pct', 30)
let g:axe#float_term_width_pct = get(g:, 'axe#float_term_width_pct', 75)
let g:axe#float_term_height_max = get(g:, 'axe#float_term_height_max', 30)
let g:axe#float_term_width_max = get(g:, 'axe#float_term_width_max', 80)
let g:axe#float_term_height_min = get(g:, 'axe#float_term_height_min', 15)
let g:axe#float_term_width_min = get(g:, 'axe#float_term_width_min', 40)

let g:axe#float_term_anchor = get(g:, 'axe#float_term_anchor', 'SE')
let g:axe#float_term_relative = get(g:, 'axe#float_term_relative', 'win')
let g:axe#open_term_in_float = get(g:, 'axe#open_term_in_float', 0)

command! -nargs=1 -complete=custom,axe#complete_commands Axe call axe#execute_subcmd(<f-args>)
command! AxeProcs call axe#list_background_processes()
command! AxeFloats call axe#list_floats()
command! -nargs=1 -complete=custom,axe#complete_procs AxeStop call axe#stop_process(<f-args>)
command! -nargs=1 -complete=custom,axe#complete_floats AxeCloseFloat call axe#close_win(<f-args>)
command! AxeList call axe#list_commands()
