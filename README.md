# Axe -- Asynchronous Executor

A configurable plugin to execute external commands in the built-in terminal
based on file type. This is a rewrite of an unpublished plugin I wrote during
the vim 7.4 days before async was around. The old incarnation was written in a
mixture of python and shell to bypass the inability of vim to launch processes
off the main thread, a situation that has since been ameliorated by the launch
of neovim, and later, the release of vim version 8.

## Requirements

Neovim >= 0.2

## Installation

[vim-plug](https://github.com/junegunn/vim-plug)

Add the following line to your `init.vim`

```vim
Plug 'macthecadillac/axe'
```
## Usage

The following commands are available:

`Axe`: `Axe {cmd}` where `cmd` is the sub-command you defined (see the
section below). This will execute the command you configured.

`AxeList`: List all the defined sub-commands available for the current file
type

`AxeProcs`: List all background processes launched through `Axe`
(those that run not in the terminal but in the background)

`AxeStop`: Terminate process with the provided process number.  `AxeStop
{#}` where `#` is the process number listed by `AxeListProcs`.

## Configuration

Configurations can be global or local. Global configurations reside in your
global configuration (usually in `init.vim`) whereas local configurations live
in `.axe.vim` in your local directory (either in the same folder as the file in
buffer or in the root of the `git` repository). Local configurations, if found,
always have precedence over global configurations.

### Hooks to shell commands

All hooks reside in `g:axe#cmds`. It is a dictionary that maps
`Axe` sub-commands to shell commands. The dictionary must contain keys (as
`string`'s) that are vim `filetype`'s. The value of the each entry is another
dictionary that contains the following four entries:

  - `cmd`: `string` The command to be invoked
  - `with_filename`: `boolean` Supply the command with the file name (append to
    the command) if set to `1`, run the command without the file name if set to
    `0`. (Default is 1)
  - `in_term`: `boolean` Run the command in the terminal if set to `1`, run in the
    background if set to `0`. (Default is 0)
  - `exe_in_proj_root`: `boolean` Execute in the root of the project where the
    `.git` directory is found. (Default is 0)
  - `show_stderr_on_error`: `boolean` Show the stderr output in a split if the
    process exits with error. (Default is 1)

Of all the entries, `cmd` is mandatory (for obvious reasons). The rest are
optional. When they are not specified, the default values are used (see above).
New defaults could be set (see the documentation).

Instead of being specific file types, the first level keys could optionally be a
wildcard, in this case `*` that serves as a catch-all, and all its commands will
be available for all file types. Notice that file type specific commands will
override catch-all commands if conflicts arise.

Example:

```vim
let g:axe#cmds = {
      \ '*': {
      \     'update-ctags': {
      \       'cmd': 'ctags -R -h --exclude={.git}',
      \       'with_filename': 0,
      \     },
      \   },
      \ 'python': {
      \     'run': {
      \       'cmd': '$HOME/anaconda3/bin/python',
      \       'in_term': 1
      \     },
      \     'background-run': {'cmd': '$HOME/anaconda3/bin/python'},
      \   },
      \ 'tex': {
      \     'build': {
      \       'cmd': 'latexmk -silent',
      \       'in_term': 1
      \     },
      \     'continuous-build': {'cmd': 'latexmk -pvc -interaction=nonstopmode'},
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
      \       'in_term': 1
      \     },
      \   },
      \ }
```

For further configuration options, please refer to the documentation.

## License

MIT
