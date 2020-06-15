function! vimdo#util#filename()
  return expand('%:p')
endfunction

function! vimdo#util#path()
  return getcwd()
endfunction

function! vimdo#util#line()
  return line('.')
endfunction

function! vimdo#util#col()
  return col('.')
endfunction

function! vimdo#util#root()
  if globpath('.', '.git') ==# './.git'
    let l:gitdir = getcwd()
    " Return working directory to the original value
    execute 'cd' fnameescape(b:file_path)
    return l:gitdir
  elseif getcwd() ==# '/'
    execute 'cd' fnameescape(b:file_path)
    return ''
  else
    execute 'cd' fnameescape('..')
    return vimdo#util#root()
  endif
endfunction
