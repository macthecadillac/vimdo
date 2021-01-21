let g:vimdo#split_direction = get(g:, 'vimdo#split_direction', 'down')
let g:vimdo#terminal_jobs = {}
let g:vimdo#background_jobs = {}
let g:vimdo#floats = {}
let g:vimdo#exit_message = get(
      \ g:,
      \ 'vimdo#exit_message',
      \ '\n-------------------------\nPress ENTER to exit'
      \ )
let g:vimdo#term_height = get(g:, 'vimdo#term_height', 15)
let g:vimdo#term_width = get(g:, 'vimdo#term_width', 79)
let g:vimdo#remove_term_buffer_when_done = get(g:, 'vimdo#remove_term_buffer_when_done', 1)
let g:vimdo#cmds = get(g:, 'vimdo#cmds', {})
let g:vimdo#with_filename = get(g:, 'vimdo#with_filename', 1)
let g:vimdo#in_term = get(g:, 'vimdo#in_term', 0)
let g:vimdo#exe_in_proj_root = get(g:, 'vimdo#exe_in_proj_root', 0)
let g:vimdo#show_stderr_on_error = get(g:, 'vimdo#show_stderr_on_error', 1)
let g:vimdo#show_stdout_in_split = get(g:, 'vimdo#show_stdout_in_split', 0)
let g:vimdo#show_stdout_in_float = get(g:, 'vimdo#show_stdout_in_float', 0)
let g:vimdo#show_stdout_in_cmdline = get(g:, 'vimdo#show_stdout_in_cmdline', 0)
let g:vimdo#filetype_defaults = get(g:, 'vimdo#filetype_defaults', {})

let g:vimdo#float_term_height_pct = get(g:, 'vimdo#float_term_height_pct', 30)
let g:vimdo#float_term_width_pct = get(g:, 'vimdo#float_term_width_pct', 75)
let g:vimdo#float_term_height_max = get(g:, 'vimdo#float_term_height_max', 30)
let g:vimdo#float_term_width_max = get(g:, 'vimdo#float_term_width_max', 80)
let g:vimdo#float_term_height_min = get(g:, 'vimdo#float_term_height_min', 15)
let g:vimdo#float_term_width_min = get(g:, 'vimdo#float_term_width_min', 40)

let g:vimdo#float_term_relative = get(g:, 'vimdo#float_term_relative', 'win')
let g:vimdo#open_term_in_float = get(g:, 'vimdo#open_term_in_float', 0)

command! -nargs=1 -complete=custom,vimdo#complete_commands Vimdo call vimdo#execute_subcmd(<f-args>)
command! VimdoProcs call vimdo#list_background_processes()
command! VimdoFloats call vimdo#list_floats()
command! -nargs=1 -complete=custom,vimdo#complete_procs VimdoStop call vimdo#stop_process(<f-args>)
command! -nargs=1 -complete=custom,vimdo#complete_floats VimdoCloseFloat call vimdo#close_win(<f-args>)
command! VimdoList call vimdo#list_commands()
command! -nargs=+ VimdoBang call vimdo#bang({}, <f-args>)
command! -nargs=+ VimdoBangS call vimdo#bang({'show_stdout_in_split': 1}, <f-args>)
command! -nargs=+ VimdoBangT call vimdo#bang({'in_term': 1}, <f-args>)
