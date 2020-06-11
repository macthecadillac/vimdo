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

function! s:name_buffer(subtitle, with_subtitle)
    let l:bufnr = 0
    let l:bufname = a:with_subtitle ? 'AXE: ' . a:subtitle : 'Axe'

    while bufname(l:bufname) ==# l:bufname
      let l:bufnr = l:bufnr + 1
      if a:with_subtitle
        let l:bufname = 'AXE: ' . a:subtitle . ' (' . l:bufnr . ')'
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
  let l:stderr = g:axe#background_jobs[a:job_id][1].stderr
  if l:stderr ==# ['']
    echom 'AXE: "' . g:axe#background_jobs[a:job_id][0] . '" exited successfully'
  elseif g:axe#background_jobs[a:job_id][1].show_stderr
    " redirect stderr output to a temporary buffer and show
    call s:print_to_split('stderr', l:stderr)
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

  let l:filetype_defaults = get(g:axe#filetype_defaults, &filetype, {})
  let l:cmd = extend(l:filetype_defaults, l:extcmds[a:subcmd], 'force')
  return extend(g:axe#global_defaults, l:cmd, 'force')
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

function! s:print_to_cmdline(text)
  echom a:text
endfunction

function! s:print_to_float(text, fitcontent)
  let l:scratch = nvim_create_buf(v:false, v:true)
  let l:opts = {
        \ 'anchor': 'NW',
        \ 'style': 'minimal',
        \ }
  if a:fitcontent
    " `max . map len` in the handicapped language of vimscript
    let l:widths = []
    let l:i = 0
    while l:i < len(a:text)
      let l:widths = add(l:widths, len(a:text[l:i]))
      let l:i += 1
    endwhile

    let l:opts.relative = 'cursor'
    let l:opts.width = max(l:widths)
    let l:opts.height = len(a:text)
    let l:opts.row = 1
    let l:opts.col = 0
    let l:opts.focusable = v:false
  else
    let l:opts.relative = 'editor'
    let l:opts.width = g:axe#float_width * winwidth(0) / 100
    let l:opts.height = g:axe#float_height * winheight(0) / 100
    let l:opts.row = (winheight(0) - l:opts.height) / 2
    let l:opts.col = (winwidth(0) - l:opts.width) / 2
    let l:opts.focusable = v:true
  endif
  call nvim_buf_set_lines(l:scratch, 0, -1, v:true, a:text)
  return nvim_open_win(l:scratch, 0, l:opts)
endfunction

function! s:print_to_split(subcmd, text)
  new
  call append(0, a:text)
  setlocal buftype=nofile bufhidden=wipe nobuflisted nolist noswapfile readonly nospell nonumber
  call s:name_buffer(a:subcmd, 1)
  resize 10
endfunction

function! axe#execute_subcmd(subcmd)
  let b:file_path = getcwd()
  let l:filename = expand('%:f')

  call s:source_local_configuration()

  try
    let l:cmd_opts = s:extract_cmd_opt(a:subcmd)

    let l:cmd = s:build_cmd(l:cmd_opts.cmd)
    let l:cmd = l:cmd_opts.in_term ? s:create_term_cmd(l:cmd) : l:cmd

    let l:root = ''
    if l:cmd_opts.exe_in_proj_root
      let l:root = axe#util#root()
      if l:root !=# ''
        execute 'cd' axe#util#root()
      endif
    endif

    let l:job = s:new_job(l:cmd_opts.in_term, l:cmd_opts.show_stderr_on_error)
    if !(l:cmd_opts.exe_in_proj_root && l:root ==# '')
      if l:cmd_opts.in_term
        call s:new_split()
        let l:job_id = termopen(l:cmd, l:job)
        call s:name_buffer(l:filename, l:cmd_opts.with_filename)
        let l:bufnr = bufnr('%')
        let g:axe#terminal_jobs[l:job_id] = [l:job, l:bufnr]
      else
        let l:job_id = jobstart(l:cmd, l:job)
        let g:axe#background_jobs[l:job_id] = [a:subcmd, l:job]
      endif
    endif

    if l:cmd_opts.exe_in_proj_root
      execute 'cd' b:file_path
    endif
  catch /Key not present in Dictionary: cmd/
    echohl ErrorMsg
    echom 'Invalid configuration entry.'
    echohl NONE
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
