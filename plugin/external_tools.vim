let g:external_tools#envs = get(g:, 'external_tools#envs', {})
let g:external_tools#split_direction = get(g:, 'external_tools#split_direction', 'down')
let g:external_tools#jobs = {}
let g:external_tools#exit_message = get(
      \ g:,
      \ 'external_tools#exit_message',
      \ '\n-------------------------\nPress ENTER to exit'
      \ )
let g:external_tools#term_height = get(g:, 'external_tools#term_height', 15)
let g:external_tools#term_width = get(g:, 'external_tools#term_width', 79)
let g:external_tools#remove_term_buffer_when_done = get(g:, 'external_tools#remove_term_buffer_when_done', 1)

command! FileTypeCmd call external_tools#filetype_cmd()

command! -bang -nargs=+ ExtCmd call external_tools#external_cmd('<bang>', <f-args>)
