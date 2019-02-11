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

let b:file_path = getcwd()

" We define the root directory as the one that contains the git folder
function! s:find_root()
  if globpath('.', '.git') ==# './.git'
    let l:gitdir = getcwd()
    " Return working directory to the original value
    execute 'cd' fnameescape(b:file_path)
    return l:gitdir
  elseif getcwd() ==# '/'
    execute 'cd' fnameescape(b:file_path)
    return 'Reached filesystem boundary'
  else
    execute 'cd' fnameescape('..')
    return s:find_root()
  endif
endfunction

" Find local environmental configuration and overwrites the system-wide
" configuration, if any
function! s:source_local_configuration()
  if filereadable('./.external_tools.vim')
    execute 'source .external_tools.vim'
  else
    let l:root = s:find_root()
    if filereadable('./.external_tools.vim')
      execute 'source .external_tools.vim'
    endif
  endif
endfunction

call s:source_local_configuration()

command! FileTypeCmd call external_tools#filetype_cmd()
