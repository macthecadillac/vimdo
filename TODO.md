- [ ] FIXME: issues with interoperability between 'in_term' and
  'exe_in_proj_root'
- [ ] Add support for per buffer local settings
- [ ] Refactor code
  - [ ] split `vimdo#execute_subcmd` into something like `vimdo#execute`
  and `vimdo#parse_alias` then we can use `vimdo#execute` to implement `VimdoBangx`
- [ ] rename subcommand to aliased commands which is more appropriate given the
  current scope of the plugin
- [ ] terminal placement options
- [ ] give the same configurability to `stderr` output as `stdout`
- [ ] `stdout` float option for output that use a different geometries/placements
  instead of fitting to content/determined by the cursor
- [ ] More `VimdoBangx` commands for different presets
  - [ ] ability to launch a `VimdoBangx` command to a terminal like a predefined
    terminal task
- [ ] Ability to hide/unhide/list terminals
- [ ] use exit code instead of checking `stderr` to determine whether to show
  `stderr`
- [ ] vim8 support
