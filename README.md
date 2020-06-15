# Axe -- Asynchronous Executor

A configurable plugin to execute external commands in the built-in terminal
based on file type. This is a rewrite of an unpublished plugin I wrote before
async was around. The old incarnation was written in a mixture of python and
shell to bypass the inability of vim to launch processes off the main thread, a
situation that has since been ameliorated by the launch of neovim.

## Requirements

Neovim >= `0.2` for most of the stuff to work. Version `0.4` or above
recommended.

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

`AxeFloats`: List all the float terminals opened by `Axe`.

`AxeCloseFloat`: Close the floating window with the provided window ID.
`AxeCloseFloat {#}` where `#` is the window ID listed by `AxeFloats`.

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
dictionary that must contain this entry:

  - `cmd`: `string` The command to be invoked

Aside from `cmd`, you can include any valid configuration keys in the dictionary
and these will have precedence over the global/file type configurations.

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
