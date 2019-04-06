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

## TODOS

- Main features
  - [x] Configurable commands (using a dictionary)
  - [x] File type based commands
  - [x] Non file type based commands
  - [x] Terminal based commands
  - [x] Background commands

- Other TODOs
  - [ ] Perhaps integration with quickfix/location list
  - [x] Write documentation
  - [ ] Error handling for failed background commands (show a simple message and perhaps redirect output from `stderr` to a temporary buffer and display)
  - [ ] Command auto-completion (if possible)
  - [x] List available commands
  - [x] Process manager/Terminate commands

## Usage

The following commands are made available:

`ExtCmd`: `ExtCmd {cmd}` where `cmd` is the sub-command you defined (see the
section below). This will execute the command you configured.

`ExtCmdList`: List all the defined sub-commands available for the current file
type

`ExtCmdProcs`: List all background processes launched through `ExtCmd`
(those that run not in the terminal but in the background)

`ExtCmdStop`: Terminate process with the provided process number.  `ExtCmdStop
{#}` where `#` is the process number listed by `ExtCmdListProcs`.

## Configuration

Configurations can be global or local. Global configurations reside in your
`init.vim` whereas local configurations live in `.external_tools.vim` in your
local directory (either in the same folder as the file in buffer or in the root
of the `git` repository). Local configurations, if found, always have precedence
over global configurations.

### Hooks to shell commands

All hooks reside in `g:external_tools#cmds`. It is a dictionary that maps
`ExtCmd` sub-commands to shell commands. The dictionary must contain keys (as
`string`'s) that are vim `filetype`'s. The value of the each entry is another
dictionary that contains the following three entries:

  - `cmd`: `string` The command to be invoked
  - `with_filename`: `boolean` Supply the command with the file name (append to
    the command) if set to `1`, run the command without the file name if set to
    `0`.
  - `in_term`: `boolean` Run the command in the terminal if set to `1`, run in the
    background if set to `0`.

Instead of being specific file types, the first level keys could optionally be a
wildcard, in this case `*` that serves as a catch-all, and all its commands will
be available for all file types. Notice that file type specific commands will
override catch-all commands if conflicts arise.

Example:

```vim
let g:external_tools#cmds = {
      \ '*': {
      \     'update-ctags': {
      \       'cmd': 'ctags -R -h --exclude={.git,__pycache,__init__.py}',
      \       'with_filename': 0,
      \       'in_term': 0
      \     },
      \   },
      \ 'python': {
      \     'run': {
      \       'cmd': '$HOME/anaconda3/bin/python',
      \       'with_filename': 1,
      \       'in_term': 1
      \     },
      \     'background-run': {
      \       'cmd': '$HOME/anaconda3/bin/python',
      \       'with_filename': 1,
      \       'in_term': 0
      \     },
      \   },
      \ 'tex': {
      \     'build': {
      \       'cmd': 'latexmk -silent',
      \       'with_filename': 1,
      \       'in_term': 1
      \     },
      \     'continuous-build': {
      \       'cmd': 'latexmk -pvc -interaction=nonstopmode',
      \       'with_filename': 1,
      \       'in_term': 0
      \     },
      \   },
      \ 'rust': {
      \     'run': {'cmd': 'cargo run', 'with_filename': 0, 'in_term': 1},
      \     'quick-build': {
      \       'cmd': 'cargo build',
      \       'with_filename': 0,
      \       'in_term': 1
      \     },
      \     'release-build': {
      \       'cmd': 'cargo build --release',
      \       'with_filename': 0,
      \       'in_term': 1
      \     },
      \   },
      \ }
```

For further configuration options, please refer to the documentation.

## License

MIT
