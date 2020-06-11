" Find local environmental configuration and overwrite the system-wide
" configuration, if any
function! s:source_local_configuration()
  if filereadable('./.axe.vim')
    execute 'source .axe.vim'
  else
    let l:root = axe#util#root()
    if l:root !=# ''
      if filereadable(l:root . '/.axe.vim')
        execute 'source ' . l:root . '/.axe.vim'
      endif
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
  if has_key(l:split_directions, g:axe#split_direction)
    " ' Execute' creates a new buffer for the execution to take place,
    " otherwise the current buffer will be replaced by the terminal
    execute l:split_directions[g:axe#split_direction] . ' Execute'
    if g:axe#split_direction ==# 'up' || g:axe#split_direction ==# 'down'
      execute 'resize ' . g:axe#term_height
    elseif g:axe#split_direction ==# 'left' || g:axe#split_direction ==# 'right'
      execute 'vertical resize ' . g:axe#term_width
    endif
  endif

  setlocal nonumber nospell
endfunction

function! s:name_buffer(filename, with_filename)
    let l:bufnr = 0
    let l:bufname = a:with_filename ? 'AXE: ' . a:filename : 'Axe'

    while bufname(l:bufname) ==# l:bufname
      let l:bufnr = l:bufnr + 1
      if a:with_filename
        let l:bufname = 'AXE: ' . a:filename . ' (' . l:bufnr . ')'
      else
        let l:bufname = 'AXE (' . l:bufnr . ')'
      endif
    endwhile

    execute 'file '  . l:bufname
endfunction

function! s:job_stdout(job_id, data, event) dict
  let l:self.stdout = l:self.stdout + a:data
endfunction

function! s:job_stderr(job_id, data, event) dict
  let l:self.stderr = l:self.stderr + a:data
endfunction

function! s:term_job_exit(job_id, data, event) dict
  let l:bufnr = g:axe#terminal_jobs[a:job_id][1]
  unlet g:axe#terminal_jobs[a:job_id]
  if g:axe#remove_term_buffer_when_done
    execute 'bd! ' . l:bufnr
  else
    close
  endif
endfunction

function! s:bg_job_exit(job_id, data, event) dict
  let l:stderr = g:axe#background_jobs[a:job_id][1]['stderr']
  if l:stderr ==# ['']
    echom 'AXE: "' . g:axe#background_jobs[a:job_id][0] . '" exited successfully'
  elseif g:axe#background_jobs[a:job_id][1]['show_stderr']
    " redirect stderr output to a temporary buffer and show
    new
    call append(line('$'), l:stderr)
    setlocal buftype=nofile bufhidden=wipe nobuflisted nolist noswapfile readonly nospell
    file stderr    " name the temporary buffer as 'stderr'
    resize 10
  else
    echom 'AXE: "' . g:axe#background_jobs[a:job_id][0] . '" exited with error'
  endif
  unlet g:axe#background_jobs[a:job_id]
endfunction

function! s:new_job(term, show_stderr)
  let l:exit_func = a:term ? 's:term_job_exit' : 's:bg_job_exit'
  return {
        \ 'stdout': [],
        \ 'stderr': [],
        \ 'on_stdout': function('s:job_stdout'),
        \ 'on_stderr': function('s:job_stderr'),
        \ 'on_exit': function(l:exit_func),
        \ 'show_stderr': a:show_stderr,
        \ }
endfunction

function! s:create_term_cmd(cmd)
  let l:subcmd = a:cmd . ';'
  " This is basically a shell script.
  "   trap : INT catches Ctrl-C and enables to the command to exit gracefully
  let l:cmd = '/bin/bash -c "' .
        \ 'trap : INT;' .
        \ l:subcmd .
        \ 'printf \"' . g:axe#exit_message . '\"' .
        \ ';read -p \"\""'
  return l:cmd
endfunction

function! s:default(opt)
  let l:global_default = get(g:, 'axe#' . a:opt)
  let l:filetype_default = get(g:axe#filetype_defaults, &filetype, {})
  return get(l:filetype_default, a:opt, l:global_default)
endfunction

function! s:extract_cmd_opt(subcmd)
  " file type specific commands trump catch-all commands
  if has_key(g:axe#cmds, &filetype) && has_key(g:axe#cmds, '*')
    let l:extcmds = extend(deepcopy(g:axe#cmds['*']), g:axe#cmds[&filetype])
  elseif has_key(g:axe#cmds, &filetype)
    let l:extcmds = g:axe#cmds[&filetype]
  elseif has_key(g:axe#cmds, '*')
    let l:extcmds = g:axe#cmds['*']
  else
    let l:extcmds = {}
  endif

  if has_key(l:extcmds, a:subcmd)
    try
      let l:cmd_list = l:extcmds[a:subcmd]['cmd']
      let l:in_term = get(l:extcmds[a:subcmd], 'in_term', s:default('in_term'))
      let l:with_filename = get(l:extcmds[a:subcmd], 'with_filename',
            \                   s:default('with_filename'))
      let l:exe_in_proj_root = get(l:extcmds[a:subcmd], 'exe_in_proj_root',
            \                      s:default('exe_in_proj_root'))
      let l:show_stderr = get(l:extcmds[a:subcmd], 'show_stderr_on_error',
            \                 s:default('show_stderr_on_error'))
    catch /Key not present in Dictionary: cmd/
      echohl ErrorMsg
      echom 'Invalid configuration entry.'
      echohl NONE
    endtry
  endif

  return [l:cmd_list, l:with_filename, l:in_term, l:exe_in_proj_root, l:show_stderr]
endfunction

function! s:build_cmd(cmd)
  try
    let l:cmd = a:cmd[0]
  catch /list index out of range/
    let l:cmd = ''
  endtry

  let l:i = 1
  while l:i < len(a:cmd)
    " try to treat the element as a function reference and call it
    try
      let l:cmd .= ' ' . function(a:cmd[l:i])()
    " if the element can't be called, it must be an ordinary command line
    " argument
    catch /.*/
      let l:cmd .= ' ' . a:cmd[l:i]
    endtry
    let l:i += 1
  endwhile

  return l:cmd
endfunction

function! axe#execute_subcmd(subcmd)
  let b:file_path = getcwd()
  let l:filename = expand('%:f')

  call s:source_local_configuration()

  try
    let l:cmd_opts = s:extract_cmd_opt(a:subcmd)
    let l:cmd_list = l:cmd_opts[0]
    let l:with_filename = l:cmd_opts[1]
    let l:in_term = l:cmd_opts[2]
    let l:exe_in_proj_root = l:cmd_opts[3]
    let l:show_stderr = l:cmd_opts[4]

    let l:cmd = s:build_cmd(l:cmd_list)
    let l:cmd = l:in_term ? s:create_term_cmd(l:cmd) : l:cmd

    let l:root = ''
    if l:exe_in_proj_root
      let l:root = axe#util#root()
      if l:root !=# ''
        execute 'cd' axe#util#root()
      endif
    endif

    let l:job = s:new_job(l:in_term, l:show_stderr)
    if !(l:exe_in_proj_root && l:root ==# '')
      if l:in_term
        call s:new_split()
        let l:job_id = termopen(l:cmd, l:job)
        call s:name_buffer(l:filename, l:with_filename)
        let l:bufnr = bufnr('%')
        let g:axe#terminal_jobs[l:job_id] = [l:job, l:bufnr]
      else
        let l:job_id = jobstart(l:cmd, l:job)
        let g:axe#background_jobs[l:job_id] = [a:subcmd, l:job]
      endif
    endif

    if l:exe_in_proj_root
      execute 'cd' b:file_path
    endif
  catch /l:cmd/
    echohl ErrorMsg
    echom 'Command not defined.'
    echohl NONE
  endtry
endfunction

" returns a list of defined commands
function! s:list_commands()
  let l:filetype = &filetype
  if has_key(g:axe#cmds, l:filetype) && has_key(g:axe#cmds, '*')
    let l:cmd_dicts = extend(deepcopy(g:axe#cmds['*']), g:axe#cmds[l:filetype])
    let l:cmd = keys(l:cmd_dicts)
  elseif has_key(g:axe#cmds, l:filetype)
    let l:cmds = keys(g:axe#cmds[l:filetype])
  elseif has_key(g:axe#cmds, '*')
    let l:cmds = keys(g:axe#cmds['*'])
  else
    let l:cmds = []
  endif
  return l:cmds
endfunction

" List all currently defined commands for this file type
function! axe#list_commands()
  echom ':ExtCmdListCmds'
  for cmd in s:list_commands()
    echom '  ' . cmd
  endfor
endfunction

" completion function for Axe
function! axe#complete_commands(ArgLead, CmdLine, CursorPos)
  return join(s:list_commands(), "\n")
endfunction

" TODO: Make output adapt to job-id length
function! axe#list_background_processes()
  if g:axe#background_jobs !=# {}
    echom ':ExtCmdListProcs'
    echom '  #   Command'
    for l:proc in items(g:axe#background_jobs)
      let l:job_id = l:proc[0]
      let l:cmd = l:proc[1][0]
      echom '  ' . l:job_id . '   ' . l:cmd
    endfor
  else
    echom 'Nothing to show'
  endif
endfunction

function! axe#stop_process(job_id)
  if has_key(g:axe#background_jobs, a:job_id)
    call jobstop(str2nr(a:job_id))
  else
    echom 'No matching process found'
  endif
endfunction
