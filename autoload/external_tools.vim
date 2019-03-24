" TODO: make composite commands out of configuration files

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
    if filereadable(l:root . '/.external_tools.vim')
      execute 'source ' . l:root . '/.external_tools.vim'
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

function! s:term_job_exit(job_id, data, event) dict
  let l:bufnr = g:external_tools#jobs[a:job_id][1]
  unlet g:external_tools#jobs[a:job_id]
  if g:external_tools#remove_term_buffer_when_done
    execute 'bd! ' . l:bufnr
  else
    close
  endif
endfunction

function! s:bg_job_exit(job_id, data, event) dict
  " Do nothing
endfunction

function! s:new_job(term)
  let exit_func = a:term ? 's:term_job_exit' : 's:bg_job_exit'
  return {
        \ 'stdout': [],
        \ 'stderr': [],
        \ 'on_stdout': function('s:job_stdout'),
        \ 'on_stderr': function('s:job_stderr'),
        \ 'on_exit': function(exit_func)
        \ }
endfunction

function! s:create_term_cmd(cmd)
  let l:subcmd = a:cmd . ';'
  " This is basically a shell script.
  "   trap : INT catches Ctrl-C and enables to the command to exit gracefully
  let l:cmd = '/bin/bash -c "' .
        \ 'trap : INT;' .
        \ l:subcmd .
        \ 'printf \"' . g:external_tools#exit_message . '\"' .
        \ ';read -p \"\""'
  return l:cmd
endfunction

function! s:extract_cmd_opt(filetype, subcmd)
  " file type specific commands trump catch-all commands
  if has_key(g:external_tools#cmds, a:filetype) && has_key(g:external_tools#cmds, '*')
    let l:ft_extcmds = g:external_tools#cmds[a:filetype]
    let l:default_extcmds = g:external_tools#cmds['*']
    if has_key(l:ft_extcmds, a:subcmd)
      let l:cmdstr = l:ft_extcmds[a:subcmd]['cmd']
      let l:with_filename = l:ft_extcmds[a:subcmd]['with_filename']
      let l:in_term = l:ft_extcmds[a:subcmd]['in_term']
    elseif has_key(l:default_extcmds, a:subcmd)
      let l:cmdstr = l:default_extcmds[a:subcmd]['cmd']
      let l:with_filename = l:default_extcmds[a:subcmd]['with_filename']
      let l:in_term = l:default_extcmds[a:subcmd]['in_term']
    endif
  elseif has_key(g:external_tools#cmds, a:filetype)
    let l:extcmds = g:external_tools#cmds[a:filetype]
    if has_key(l:extcmds, a:subcmd)
      let l:cmdstr = l:extcmds[a:subcmd]['cmd']
      let l:with_filename = l:extcmds[a:subcmd]['with_filename']
      let l:in_term = l:extcmds[a:subcmd]['in_term']
    endif
  elseif has_key(g:external_tools#cmds, '*')
    let l:extcmds = g:external_tools#cmds['*']
    if has_key(l:extcmds, a:subcmd)
      let l:cmdstr = l:extcmds[a:subcmd]['cmd']
      let l:with_filename = l:extcmds[a:subcmd]['with_filename']
      let l:in_term = l:extcmds[a:subcmd]['in_term']
    endif
  endif

  return [l:cmdstr, l:with_filename, l:in_term]
endfunction

function! external_tools#external_cmd(bang, ...)
  let b:file_path = getcwd()
  let l:filename = expand('%:f')
  let l:filetype = &filetype

  let subcmd = a:1

  call s:source_local_configuration()

  try
    let l:cmd_opts = s:extract_cmd_opt(l:filetype, l:subcmd)
    let l:cmdstr = l:cmd_opts[0]
    let l:with_filename = l:cmd_opts[1]
    let l:in_term = l:cmd_opts[2]

    let l:cmd = l:with_filename ? l:cmdstr . ' ' . l:filename : l:cmdstr
    let l:cmd = l:in_term ? s:create_term_cmd(l:cmd) : l:cmd

    let l:job = s:new_job(l:in_term)
    if l:in_term
      call s:new_split()
      let l:job_id = termopen(l:cmd, l:job)
      call s:name_buffer(l:filename, l:with_filename)
      let l:bufnr = bufnr('%')
      let g:external_tools#jobs[l:job_id] = [l:job, l:bufnr]
    else
      let l:job_id = jobstart(l:cmd, l:job)
    endif
  catch /l:cmdstr/
    echohl ErrorMsg
    echom 'Sub-command not defined.'
    echohl NONE
  endtry
endfunction
