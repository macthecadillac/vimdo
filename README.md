# External-tools

A configurable plugin to run custom commands based on the filetype.

## Requirements

Neovim > 0.2

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
command associated to the filetype, and the second entry is the "verb" you would
like vim to display as part of the execution buffer name.

```vim
let g:external_tools#envs = {
      \ 'python': ['/usr/bin/env python', 'Executing'],
      \ 'sh': ['/bin/sh', 'Executing'],
      \ 'tex': ['/usr/bin/latexmk -gg silent', 'Compiling'],
      \ }
```

Additional options should be quite self-explanatory.

```vim
let g:external_tools#split_direction = 'down'
let g:external_tools#exit_message = '\n-------------------------\nPress ENTER to exit'
let g:external_tools#term_height = 15
let g:external_tools#term_width = 79
```

### Local Configurations

Same as the global configuration but instead of being in your `init.vim`, these
options live in `.external-tools.vim` in a directory within your project. Place
it in the root directory (the directory where `.git` is) for it to take effect
over the entire project or place it in the same folder as the file being edited
for it to take effect in that directory. Global configurations will be
overwritten if local configurations are found.

## License

MIT
