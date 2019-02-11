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

function! s:new_split()
  let l:split_directions = {
        \ 'up': 'topleft split',
        \ 'down':  'botright split',
        \ 'right': 'botright vsplit',
        \ 'left': 'topleft vsplit',
        \ }
  if has_key(l:split_directions, g:external_tools#split_direction)
    " ' Execute' creates a new buffer for the execution to take place,
    " otherwise the current buffer will be replaced by the terminal
    execute l:split_directions[g:external_tools#split_direction] . ' Execute'
    if g:external_tools#split_direction ==# 'up' || g:external_tools#split_direction ==# 'down'
      execute 'resize ' . g:external_tools#term_height
    elseif g:external_tools#split_direction ==# 'left' || g:external_tools#split_direction ==# 'right'
      execute 'vertical resize ' . g:external_tools#term_width
    endif
  endif

  setlocal nonumber
  setlocal nospell
endfunction

function! s:name_buffer(filename, with_filename)
    let l:bufnr = 0
    let l:bufname = a:with_filename ? 'FileTypeCmd: ' . a:filename : 'FileTypeCmd'

    while bufname(l:bufname) ==# l:bufname
      let l:bufnr = l:bufnr + 1
      if a:with_filename
        let l:bufname = 'FileTypeCmd: ' . a:filename . ' (' . l:bufnr . ')'
      else
        let l:bufname = 'FileTypeCmd (' . l:bufnr . ')'
      endif
    endwhile

    execute "file " . l:bufname
endfunction

function! s:job_stdout(job_id, data, event) dict
  let l:self.stdout = l:self.stdout + a:data
endfunction

function! s:job_stderr(job_id, data, event) dict
  let l:self.stderr = l:self.stderr + a:data
endfunction

function! s:job_exit(job_id, data, event) dict
  let l:bufnr = g:external_tools#jobs[a:job_id][1]
  unlet g:external_tools#jobs[a:job_id]
  if g:external_tools#remove_term_buffer_when_done
    execute 'bd! ' . l:bufnr
  else
    close
  endif
endfunction

function! external_tools#filetype_cmd()
  let l:filename = expand('%:f')
  let l:filetype = &filetype

  call s:source_local_configuration()

  let l:with_filename = g:external_tools#envs[l:filetype][1]
  if l:with_filename
    let l:executer = g:external_tools#envs[l:filetype][0]
    let l:subcmd = l:executer . ' ' . l:filename . ';'
  else
    let l:subcmd = g:external_tools#envs[l:filetype][0] . ';'
  endif

  if has_key(g:external_tools#envs, l:filetype)
    " This is basically a shell script.
    "   trap : INT catches Ctrl-C and enables to the command to exit gracefully
    let l:cmd = '/bin/bash -c "' .
          \ 'trap : INT;' .
          \ l:subcmd .
          \ 'printf \"' . g:external_tools#exit_message . '\"' .
          \ ';read -p \"\""'
    let l:job = {
          \ 'stdout': [],
          \ 'stderr': [],
          \ 'on_stdout': function('s:job_stdout'),
          \ 'on_stderr': function('s:job_stderr'),
          \ 'on_exit': function('s:job_exit')
          \ }

    call s:new_split()
    let l:job_id = termopen(l:cmd, l:job)
    call s:name_buffer(l:filename, l:with_filename)
    let l:bufnr = bufnr('%')
    let g:external_tools#jobs[l:job_id] = [l:job, l:bufnr]
  endif
endfunction
