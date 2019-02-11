# External-tools

A configurable plugin to run custom commands based on the filetype.

## Requirements

Neovim >= 0.2

## Installation

[vim-plug](https://github.com/junegunn/vim-plug)

Add the following line to your `init.vim`

```vim
Plug 'macthecadillac/external-tools.nvim'
```

## Configuration

### Global configuration options

The most important configuration is the `envs` option, which registers filetype
hooks to a command. The dictionary key is a filetype that vim recognizes. The
value of the dictionary consists of a list, with the first entry being the
command associated to the filetype, and the second a boolean that tells the
script whether to pass the file name on to the command as an argument. No hooks
are set out of the box.

Example:

```vim
let g:external_tools#envs = {
      \ 'python': ['/usr/bin/env python', 1],
      \ 'tex': ['/usr/bin/latexmk -gg -silent', 1],
      \ 'rust': ['/usr/bin/cargo build', 0],
      \ }
```

Additional options should be quite self-explanatory. Shown here are the default
values.

```vim
" Available directions are `up`, `down`, `left` and `right`.
let g:external_tools#split_direction = 'down'
let g:external_tools#exit_message = '\n-------------------------\nPress ENTER to exit'
let g:external_tools#term_height = 15
let g:external_tools#term_width = 79
let g:external_tools#remove_term_buffer_when_done = 1
```

### Local Configurations

Same as the global configuration but instead of being in your `init.vim`, these
options live in `.external_tools.vim` in a directory within your project. Place
it in the root directory (the directory where `.git` is) for it to take effect
over the entire project or place it in the same folder as the file being edited
for it to take effect in that directory. Global configurations will be
overwritten if local configurations are found.

## License

MIT
