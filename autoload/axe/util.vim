function! axe#util#filename()
  return expand('%:p')
endfunction

function! axe#util#path()
  return getcwd()
endfunction

function! axe#util#line()
  return line('.')
endfunction

function! axe#util#col()
  return col('.')
endfunction

function! axe#util#root()
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
    return axe#util#root()
  endif
endfunction
