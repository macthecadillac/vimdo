set encoding=utf8
scriptencoding "utf-8"

function! s:source_path_while_preserving_cmds(path)
  " make a copy the global cmds
  let l:cmds = deepcopy(g:vimdo#cmds)
  " read local config, overwriting any global configs in conflict
  execute 'source ' . a:path
  " merge the cmds configured locally with the copy of the global cmds
  let l:cmds = extend(deepcopy(l:cmds), g:vimdo#cmds)
  " set the result as cmds
  let g:vimdo#cmds = l:cmds
endfunction

" Find local environmental configuration and overwrite the system-wide
" configuration, if any
function! vimdo#source_local_configuration()
  let b:file_path = getcwd()
  if filereadable('./.vimdo.vim')
    call s:source_path_while_preserving_cmds('.vimdo.vim')
  else
    let l:root = vimdo#util#root()
    if l:root !=# ''
      if filereadable(l:root . '/.vimdo.vim')
        call s:source_path_while_preserving_cmds(l:root . '/.vimdo.vim')
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
  if has_key(l:split_directions, g:vimdo#split_direction)
    " ' Execute' creates a new buffer for the execution to take place,
    " otherwise the current buffer will be replaced by the terminal
    execute l:split_directions[g:vimdo#split_direction] . ' Execute'
    if g:vimdo#split_direction ==# 'up' || g:vimdo#split_direction ==# 'down'
      execute 'resize ' . g:vimdo#term_height
    elseif g:vimdo#split_direction ==# 'left' || g:vimdo#split_direction ==# 'right'
      execute 'vertical resize ' . g:vimdo#term_width
    endif
  endif

  setlocal nonumber nospell
endfunction

function! s:name_buffer(subtitle, with_subtitle)
    let l:bufnr = 0
    let l:bufname = a:with_subtitle ? 'Vimdo: ' . a:subtitle : 'Vimdo'

    while bufname(l:bufname) ==# l:bufname
      let l:bufnr = l:bufnr + 1
      if a:with_subtitle
        let l:bufname = 'Vimdo: ' . a:subtitle . ' (' . l:bufnr . ')'
      else
        let l:bufname = 'Vimdo (' . l:bufnr . ')'
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
  let l:bufnr = g:vimdo#terminal_jobs[a:job_id][1]
  if !g:vimdo#terminal_jobs[a:job_id][0].opts.open_term_in_float
    if g:vimdo#remove_term_buffer_when_done
      try
        execute 'bd! ' . l:bufnr
      catch /No buffers were deleted/
      endtry
    else
      close
    endif
  endif
  unlet g:vimdo#terminal_jobs[a:job_id]

  " remove float from the list of float-terms if possible
  let l:win_ids = []
  for l:float_attr in items(g:vimdo#floats)
    if l:float_attr[1].job_id ==# a:job_id
      let l:win_ids = add(l:win_ids, l:float_attr[0])
    endif
  endfor
  for l:win_id in l:win_ids
    try
      call vimdo#close_win(l:win_id)
    catch /Invalid window id/
    endtry
  endfor
endfunction

function! s:bg_job_exit(job_id, data, event) dict
  let l:job_info = g:vimdo#background_jobs[a:job_id][1]
  let l:stderr = l:job_info.stderr
  let l:stdout = l:job_info.stdout
  let l:opts = l:job_info.opts
  if l:stderr ==# ['']
    let l:callback = l:job_info.callback

    try
      let l:text = function(l:callback, [l:stdout])()
    catch /.*/
      let l:text = l:stdout
    endtry

    if l:opts.show_stdout_in_split
      call s:print_to_split(g:vimdo#background_jobs[a:job_id][0], l:text)
    elseif l:opts.show_stdout_in_float
      call s:print_to_float(l:text, l:opts.float_term_width_pct,
            \               l:opts.float_term_height_pct)
    elseif l:opts.show_stdout_in_cmdline
      call s:print_to_cmdline(l:text)
    else
      echom 'Vimdo: "' . g:vimdo#background_jobs[a:job_id][0] . '" exited successfully'
    endif
  elseif l:opts.show_stderr_on_error
    " redirect stderr output to a temporary buffer and show
    call s:print_to_split('stderr', l:stderr)
  else
    echom 'Vimdo: "' . g:vimdo#background_jobs[a:job_id][0] . '" exited with error'
  endif
  unlet g:vimdo#background_jobs[a:job_id]
endfunction

function! s:new_job(opts, callback)
  let l:exit_func = a:opts.in_term ? 's:term_job_exit' : 's:bg_job_exit'
  return {
        \ 'stdout': [],
        \ 'stderr': [],
        \ 'on_stdout': function('s:job_stdout'),
        \ 'on_stderr': function('s:job_stderr'),
        \ 'on_exit': function(l:exit_func),
        \ 'opts': a:opts,
        \ 'callback': a:callback
        \ }
endfunction

function! s:create_term_cmd(cmd)
  let l:subcmd = a:cmd . ';'
  " This is basically a shell script.
  "   trap : INT catches Ctrl-C and enables to the command to exit gracefully
  let l:cmd = '/bin/bash -c "' .
        \ 'trap : INT;' .
        \ l:subcmd .
        \ 'printf \"' . g:vimdo#exit_message . '\"' .
        \ ';read -p \"\""'
  return l:cmd
endfunction

function! s:read_global_config()
  return {
        \ 'exit_message': g:vimdo#exit_message,
        \ 'term_height': g:vimdo#term_height,
        \ 'term_width': g:vimdo#term_width,
        \ 'remove_term_buffer_when_done': g:vimdo#remove_term_buffer_when_done,
        \ 'with_filename': g:vimdo#with_filename,
        \ 'in_term': g:vimdo#in_term,
        \ 'exe_in_proj_root': g:vimdo#exe_in_proj_root,
        \ 'show_stderr_on_error': g:vimdo#show_stderr_on_error,
        \ 'show_stdout_in_split': g:vimdo#show_stdout_in_split,
        \ 'show_stdout_in_float': g:vimdo#show_stdout_in_float,
        \ 'show_stdout_in_cmdline': g:vimdo#show_stdout_in_cmdline,
        \ 'float_term_height_pct': g:vimdo#float_term_height_pct,
        \ 'float_term_width_pct': g:vimdo#float_term_width_pct,
        \ 'float_term_height_max': g:vimdo#float_term_height_max,
        \ 'float_term_width_max': g:vimdo#float_term_width_max,
        \ 'float_term_height_min': g:vimdo#float_term_height_min,
        \ 'float_term_width_min': g:vimdo#float_term_width_min,
        \ 'float_term_relative': g:vimdo#float_term_relative,
        \ 'open_term_in_float': g:vimdo#open_term_in_float,
        \ }
endfunction

function! s:extract_cmd_opt(subcmd)
  " file type specific commands trump catch-all commands
  if has_key(g:vimdo#cmds, &filetype) && has_key(g:vimdo#cmds, '*')
    let l:extcmds = extend(deepcopy(g:vimdo#cmds['*']), g:vimdo#cmds[&filetype])
  elseif has_key(g:vimdo#cmds, &filetype)
    let l:extcmds = g:vimdo#cmds[&filetype]
  elseif has_key(g:vimdo#cmds, '*')
    let l:extcmds = g:vimdo#cmds['*']
  else
    let l:extcmds = {}
  endif

  let l:filetype_defaults = get(g:vimdo#filetype_defaults, &filetype, {})
  let l:cmd = extend(deepcopy(l:filetype_defaults), l:extcmds[a:subcmd], 'force')
  return extend(s:read_global_config(), l:cmd, 'force')
endfunction

function! s:build_cmd(cmd)
  try
    let l:cmd = a:cmd[0]
  catch /list index out of range/
    let l:cmd = ''
  endtry

  for l:item in a:cmd[1:]
    " try to treat the element as a function reference and call it
    try
      let l:cmd .= ' ' . function(l:item)()
    " if the element can't be called, it must be an ordinary command line
    " argument
    catch /.*/
      let l:cmd .= ' ' . l:item
    endtry
  endfor

  return l:cmd
endfunction

function! s:print_to_cmdline(text)
  echo join(a:text, "\n")
endfunction

function! s:print_to_float(text, width_pct, height_pct)
  let l:scratch = nvim_create_buf(v:false, v:true)
  let l:opts = {
        \ 'anchor': 'NW',
        \ 'style': 'minimal',
        \ }
  " `max . map len` in the handicapped language of vimscript
  let l:widths = []
  for l:line in a:text
    let l:widths = add(l:widths, len(l:line))
  endfor

  let l:opts.relative = 'cursor'
  let l:width = max(l:widths)
  let l:opts.width = l:width > 0 ? l:width : 1
  let l:opts.height = len(a:text)
  let l:opts.row = 1
  let l:opts.col = 0
  let l:opts.focusable = v:false
  call nvim_buf_set_lines(l:scratch, 0, -1, v:true, a:text)
  let l:win_id =  nvim_open_win(l:scratch, 0, l:opts)

  let l:close_win = printf('s:close_stdout_float(%s)', l:win_id)
  augroup VimdoCloseStdoutFloat
    autocmd!
    execute 'autocmd CursorMoved,CursorMovedI,InsertEnter <buffer> call ' . l:close_win
    execute 'autocmd BufEnter * call ' . l:close_win
  augroup END
endfunction

function! s:close_stdout_float(win_id)
  call nvim_win_close(str2nr(a:win_id), v:true)
  augroup VimdoCloseStdoutFloat
    autocmd!
  augroup END
endfunction

function! vimdo#close_win(win_id)
  if has_key(g:vimdo#floats, a:win_id) && has('nvim-0.4')
    try
      call nvim_win_close(str2nr(a:win_id), v:true)
    catch /Invalid window id/
    endtry
    call nvim_win_close(str2nr(g:vimdo#floats[a:win_id].bg_id), v:true)
    unlet g:vimdo#floats[a:win_id]
  else
    echom 'No matching floating window found'
  endif
endfunction

function! s:open_float_term(cmd, term_opts, configs)
  let l:buf = nvim_create_buf(v:false, v:true)
  let l:bg_buf = nvim_create_buf(v:false, v:true)

  let l:width = (a:configs.float_term_width_pct * winwidth(0)) / 100
  let l:width = min([max([l:width, a:configs.float_term_width_min]),
        \            a:configs.float_term_width_max])
  let l:height = (g:vimdo#float_term_height_pct * winheight(0)) / 100
  let l:height = min([max([l:height, a:configs.float_term_height_min]),
        \             a:configs.float_term_height_max])

  let l:bg_top = '╭' . repeat('─', l:width) . '╮'
  let l:bg_side = '│' . repeat(' ', l:width) . '│'
  let l:bg_bottom = '╰' . repeat('─', l:width) . '╯'
  let l:bg_row = winheight(0)
  let l:bg_col = winwidth(0)

  " set up the background
  let l:bg_opts = {
        \ 'anchor': 'SE',
        \ 'style': 'minimal',
        \ 'relative': g:vimdo#float_term_relative,
        \ 'width': l:width + 2,
        \ 'height': l:height + 2,
        \ 'row': l:bg_row,
        \ 'col': l:bg_col,
        \ 'focusable': v:false,
        \ }
  let l:bg = [l:bg_top] + repeat([l:bg_side], l:height) + [l:bg_bottom]
  call nvim_buf_set_lines(l:bg_buf, 0, -1, v:true, l:bg)
  let l:bg_id = nvim_open_win(l:bg_buf, 0, l:bg_opts)
  " set border region highlight color
  call nvim_win_set_option(l:bg_id, 'winhl', 'Normal:Normal,NormalNC:NormalNC')

  " set up the main terminal
  let l:opts = {
        \ 'anchor': 'SE',
        \ 'style': 'minimal',
        \ 'relative': a:configs.float_term_relative,
        \ 'width': l:width,
        \ 'height': l:height,
        \ 'row': l:bg_row - 1,
        \ 'col': l:bg_col - 1,
        \ 'focusable': v:true,
        \ }
  let l:win_id = nvim_open_win(l:buf, 0, l:opts)
  " set terminal highlight color
  call nvim_win_set_option(l:win_id, 'winhl', 'Normal:Normal,NormalNC:NormalNC')
  call nvim_set_current_win(l:win_id)
  call setbufvar(l:buf, 'vimdo_float_term_border_win_id', l:bg_id)

  return {
      \ 'win_id': l:win_id,
      \ 'job_id': termopen(a:cmd, a:term_opts),
      \ 'bg_id': l:bg_id
      \ }
endfunction

augroup VimdoFloatTermExit
  autocmd!
  autocmd QuitPre * call s:close_float_term(0)
augroup END

function! s:close_float_term(win_id)
  if has_key(b:, 'vimdo_float_term_border_win_id')
    call nvim_win_close(b:vimdo_float_term_border_win_id, v:true)
  endif
endfunction

function! s:print_to_split(subcmd, text)
  new
  call append(0, a:text)
  setlocal buftype=nofile bufhidden=wipe nobuflisted nolist noswapfile readonly nospell nonumber
  call s:name_buffer(a:subcmd, 1)
  resize 10
endfunction

function! s:cd_root(opts)
  let l:root = ''
  if a:opts.exe_in_proj_root
    let l:root = vimdo#util#root()
    if l:root !=# ''
      execute 'cd' vimdo#util#root()
    endif
  endif
  return l:root
endfunction

function! s:restore_path(opts)
  if a:opts.exe_in_proj_root
    execute 'cd' b:file_path
  endif
endfunction

function! vimdo#execute_subcmd(subcmd)
  let l:filename = expand('%:f')

  try
    let l:cmd_opts = s:extract_cmd_opt(a:subcmd)

    let l:raw_cmd = s:build_cmd(l:cmd_opts.cmd)
    let l:cmd = l:cmd_opts.in_term ? s:create_term_cmd(l:raw_cmd) : l:raw_cmd

    let l:root = s:cd_root(l:cmd_opts)

    if has_key(l:cmd_opts, 'callback')
      let l:callback = l:cmd_opts.callback
    else
      let l:callback = ''
    endif

    let l:job = s:new_job(
          \ l:cmd_opts,
          \ l:callback
          \ )

    if has('nvim')
      if !(l:cmd_opts.exe_in_proj_root && l:root ==# '')
        if l:cmd_opts.in_term
          if has('nvim-0.2')
            if g:vimdo#open_term_in_float && has('nvim-0.4')
              let l:job_attr = s:open_float_term(l:cmd, l:job, l:cmd_opts)
              let l:job_id = l:job_attr.job_id
              let g:vimdo#floats[l:job_attr.win_id] = {
                    \ 'job_id': l:job_attr.job_id,
                    \ 'cmd': l:raw_cmd,
                    \ 'bg_id': l:job_attr.bg_id
                    \ }
            else
              call s:new_split()
              let l:job_id = termopen(l:cmd, l:job)
            endif
            let l:bufnr = bufnr('%')
            let g:vimdo#terminal_jobs[l:job_id] = [l:job, l:bufnr]
            call s:name_buffer(l:filename, l:cmd_opts.with_filename)
          else
            echom 'Terminal execution requires neovim >= 0.2'
          endif
        else
          let l:job_id = jobstart(l:cmd, l:job)
          let g:vimdo#background_jobs[l:job_id] = [a:subcmd, l:job]
        endif
      endif
    endif

    call s:restore_path(l:cmd_opts)
  catch /Key not present in Dictionary: cmd/
    echohl ErrorMsg
    echom 'Invalid configuration entry.'
    echohl NONE
  catch /Key not present in Dictionary/
    echohl ErrorMsg
    echom 'Command not defined.'
    echohl NONE
  endtry
endfunction

" returns a list of defined commands
function! s:list_commands()
  let l:filetype = &filetype
  if has_key(g:vimdo#cmds, l:filetype) && has_key(g:vimdo#cmds, '*')
    let l:cmd_dicts = extend(deepcopy(g:vimdo#cmds['*']), g:vimdo#cmds[l:filetype])
    let l:cmds = keys(l:cmd_dicts)
  elseif has_key(g:vimdo#cmds, l:filetype)
    let l:cmds = keys(g:vimdo#cmds[l:filetype])
  elseif has_key(g:vimdo#cmds, '*')
    let l:cmds = keys(g:vimdo#cmds['*'])
  else
    let l:cmds = []
  endif
  return l:cmds
endfunction

" List all currently defined commands for this file type
function! vimdo#list_commands()
  echom ':VimdoListCmds'
  for cmd in s:list_commands()
    echom '  ' . cmd
  endfor
endfunction

" completion function for Vimdo
function! vimdo#complete_commands(ArgLead, CmdLine, CursorPos)
  return join(s:list_commands(), "\n")
endfunction

function! vimdo#complete_procs(ArgLead, CmdLine, CursorPos)
  let l:procs = []
  for l:proc in items(g:vimdo#background_jobs)
    let l:job_id = l:proc[0]
    let l:procs = add(l:procs, l:job_id)
  endfor
  return join(l:procs, "\n")
endfunction

function! vimdo#complete_floats(ArgLead, CmdLine, CursorPos)
  let l:floats = []
  for l:win in items(g:vimdo#floats)
    let l:win_id = l:win[0]
    let l:floats = add(l:floats, l:win_id)
  endfor
  return join(l:floats, "\n")
endfunction

" TODO: Make output adapt to id length
" TODO: Merge list_floats and list_background_processes
function! vimdo#list_floats()
  if g:vimdo#floats !=# {}
    echom ':VimdoListFloats'
    echom '  #      Command'
    for l:win in items(g:vimdo#floats)
      let l:win_id = l:win[0]
      let l:cmd = l:win[1].cmd
      echom '  ' . l:win_id . '   ' . l:cmd
    endfor
  else
    echom 'Nothing to show'
  endif
endfunction

function! vimdo#list_background_processes()
  if g:vimdo#background_jobs !=# {}
    echom ':VimdoListProcs'
    echom '  #   Command'
    for l:proc in items(g:vimdo#background_jobs)
      let l:job_id = l:proc[0]
      let l:cmd = l:proc[1][0]
      echom '  ' . l:job_id . '   ' . l:cmd
    endfor
  else
    echom 'Nothing to show'
  endif
endfunction

function! vimdo#stop_process(job_id)
  if has('nvim')
    if has_key(g:vimdo#background_jobs, a:job_id)
      call jobstop(str2nr(a:job_id))
    else
      echom 'No matching process found'
    endif
  endif
endfunction

function! vimdo#bang(opts, ...)
  let l:opts = extend(s:read_global_config(), a:opts, 'force')
  let l:opts.cmd = a:000
  let l:job = s:new_job(l:opts, '')
  let l:root = s:cd_root(l:opts)
  let l:job_id = jobstart(a:000, l:job)
  let g:vimdo#background_jobs[l:job_id] = [join(a:000, ' '), l:job]
  call s:restore_path(l:opts)
endfunction
