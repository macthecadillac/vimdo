function! s:job_stdout(job_id, data, event) dict
  let l:self.stdout = l:self.stdout + a:data
endfunction

function! s:job_stderr(job_id, data, event) dict
  let l:self.stderr = l:self.stderr + a:data
endfunction

function! s:job_exit(job_id, data, event) dict
  unlet g:external_tools#jobs[a:job_id]
  close
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

function! s:name_buffer(filetype, filename)
    let l:verb = g:external_tools#envs[a:filetype][1]
    let l:bufnr = 0
    let l:bufname = l:verb . ' ' . a:filename

    while bufname(l:bufname) ==# l:bufname
      let l:bufnr = l:bufnr + 1
      let l:bufname = l:verb . ' ' . a:filename . ' (' . l:bufnr . ')'
    endwhile

    execute "file " . l:bufname
endfunction

function! external_tools#filetype_cmd()
  let l:filename = expand('%:f')
  let l:filetype = &filetype
  if has_key(g:external_tools#envs, l:filetype)
    let l:executer = g:external_tools#envs[l:filetype][0]
    " This is basically a shell script.
    "   trap : INT catches Ctrl-C and enables to the command to exit gracefully
    let l:cmd = '/bin/bash -c "' .
          \ 'trap : INT;' .
          \ 'printf \"Executing ' . l:filename . ':\n\";' .
          \ l:executer . ' ' . l:filename . ';' .
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
    call s:name_buffer(l:filetype, l:filename)
    let g:external_tools#jobs[l:job_id] = l:job
  endif
endfunction
