# External-tools

A configurable plugin to run external commands in the built-in terminal based on
file type.

## Requirements

Neovim >= 0.2

## Installation

[vim-plug](https://github.com/junegunn/vim-plug)

Add the following line to your `init.vim`

```vim
Plug 'macthecadillac/external-tools.nvim'
```

## Features

- Command structure
  - [x] Single command
  - [ ] Composite commands
  - [ ] File type based commands
  - [ ] Non file type based commands
  - [ ] Terminal based commands
  - [ ] Background commands

- Other TODOs
  - [ ] Add vim8 support
  - [ ] Terminate non-terminal based commands
  - [ ] Process manager

## Usage

Set up hooks for different file types (see below). The command `FileTypeCmd`
will execute the external command in the neovim built-in terminal. You can
optionally register a key binding to invoke the command:

```vim
autocmd FileType python nnoremap <buffer> <A-r> :FileTypeCmd<CR>
```

## Configuration

### Global configuration options

By far, the most important configuration option is the `g:external_tools#envs`
option. This sets up hooks for each file type to external commands.
`g:external_tools#envs` is a dictionary. The keys are the file types that neovim
recognizes, and their associated value is a list, in which the first entry is
the command to be executed in the built-in terminal, and the second a boolean
that tells external-tools whether to pass the file name on to the external
command.

Example:

```vim
let g:external_tools#envs = {
      \ 'python': [$HOME . '/anaconda3/bin/python', 1],
      \ 'tex': ['/usr/bin/latexmk -gg -silent', 1],
      \ 'rust': ['cargo build', 0],
      \ }
```

Additional options should be quite self-explanatory. Shown here are their
default values.

```vim
" Available directions are 'up', 'down', 'left' and 'right'.
let g:external_tools#split_direction = 'down'
let g:external_tools#exit_message = '\n-------------------------\nPress ENTER to exit'
let g:external_tools#term_height = 15
let g:external_tools#term_width = 79
let g:external_tools#remove_term_buffer_when_done = 1
```

### Local Configurations

Local configuration lets you tailor the behavior of the extension to specific
projects. The configuration works the same way it does for global
configurations, except that the configurations reside in `.external_tools.vim`
in the local directory or the root of your git project. External-tools will pick
up your local configurations and override the global settings (if any) with
them.

## License

MIT
