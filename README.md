VISUALREPEAT
===============================================================================
_by Ingo Karkat_

DESCRIPTION
------------------------------------------------------------------------------

This plugin defines repetition of Vim built-in normal mode commands via .
for visual mode. Additionally, it offers functions like the popular repeat.vim
plugin that allow mappings to be repeated in visual mode, too.

### VISUAL MODE REPETITION

This extends the built-in normal mode repeat . to visual mode.

### VISUAL MODE MAPPING REPETITION

Like with repeat.vim for normal mode, visual mode mappings can register a
&lt;Plug&gt; mapping to be used for visual mode repetition.

Likewise, normal mode mappings can (in addition to the repeat.vim registration
of a normal mode mapping) register a visual mode mapping with visualrepeat.vim
that will be repeated in visual mode.

Operator-pending mappings end with g@ and repeat naturally; i.e. Vim
re-applies the 'opfunc' on the equivalent text (but at the current cursor
position). But without a call to repeat#set(), it is impossible to repeat this
operator-pending mapping to the current visual selection. Plugins cannot call
repeat#set() in their operator-pending mapping, because then Vim's built-in
repeat would be circumvented, the full mapping ending with g@ would be
re-executed, and the repetition would then wait for the {motion}, what is not
wanted.
Therefore, this plugin offers a separate visualrepeat#set() function that can
be invoked for operator-pending mappings. It can also be invoked for
normal-mode mappings that have already called repeat#set(), and may override
that mapping with a special repeat mapping for visual mode repeats. Together
with the remapped {Visual}. command, this allows repetition - similar to what
the built-in Vim commands do - across normal, operator-pending and visual
mode.

### SOURCE

- [Based on vimtip #1142, Repeat last command and put cursor at start of change](http://vim.wikia.com/wiki/Repeat_last_command_and_put_cursor_at_start_of_change)
- The client interface and implementation has been based on repeat.vim
  ([vimscript #2136](http://www.vim.org/scripts/script.php?script_id=2136)) by Tim Pope.

### RELATED WORKS

- repeat.vim ([vimscript #2136](http://www.vim.org/scripts/script.php?script_id=2136)) has been the basis for this plugin and should
  be used in conjunction with visualrepeat.vim. (Otherwise, you'd have visual
  mode repeat, but no repeat in normal mode.)

USAGE
------------------------------------------------------------------------------

    {Visual}.               Repeat last change in all visually selected lines.
                            - characterwise: Start from cursor position.
                            - linewise: Each line separately, starting from the
                              current column (usually the first in this mode).
                            - blockwise: Only the selected text. This is
                              implemented by temporarily duplicating the selection
                              to separate lines and repeating over those, starting
                              from the first column.

                            Note: If the last normal mode command included a
                            {motion} (e.g. g~e), the repetition will also move
                            exactly over this {motion}, NOT the visual selection!
                            It is thus best to repeat commands that work on the
                            entire line (e.g. g~$).

    {Visual}g.              Repeat last built-in command in all visually selected
                            lines. Skips any plugin repeat actions; only repeats
                            the last Vim command.

INSTALLATION
------------------------------------------------------------------------------

The code is hosted in a Git repo at
    https://github.com/inkarkat/vim-visualrepeat
You can use your favorite plugin manager, or "git clone" into a directory used
for Vim packages. Releases are on the "stable" branch, the latest unstable
development snapshot on "master".

This script is also packaged as a vimball. If you have the "gunzip"
decompressor in your PATH, simply edit the \*.vmb.gz package in Vim; otherwise,
decompress the archive first, e.g. using WinZip. Inside Vim, install by
sourcing the vimball or via the :UseVimball command.

    vim visualrepeat*.vmb.gz
    :so %

To uninstall, use the :RmVimball command.

### DEPENDENCIES

- Requires Vim 7.0 or higher.
- repeat.vim ([vimscript #2136](http://www.vim.org/scripts/script.php?script_id=2136)) plugin (highly recommended)
- ingo-library.vim plugin ([vimscript #4433](http://www.vim.org/scripts/script.php?script_id=4433)), version 1.013 or higher;
  optional, for blockwise repeat only

INTEGRATION
------------------------------------------------------------------------------

This plugin is meant to be used together with repeat.vim.

This plugin has helper functions that plugins with cross-repeat functionality
can use in their normal mode repeat mappings of repeated visual mode mappings.
With this, you save work and allow for a consistent user experience.
Define your normal mode repeat mapping like this:

    nnoremap <silent> <Plug>(MyPluginVisual)
    \ :<C-u>execute 'normal!' visualrepeat#reapply#VisualMode(0)<Bar>
    \call MyPlugin#Operator('visual', "\<lt>Plug>(MyPluginVisual)")<CR>

If your plugin uses a passed [count] (i.e. the count is not only used to
determine the text area the mapping is applied to), you need to define a
mapping:

    vnoremap <silent> <expr> <SID>(ReapplyRepeatCount) visualrepeat#reapply#RepeatCount()

and apply the function followed by the mapping like this:

    nnoremap <silent> <script> <Plug>(MyPluginVisual)
    \ :<C-u>execute 'normal!' visualrepeat#reapply#VisualMode(1)<CR>
    \<SID>(ReapplyRepeatCount)
    \:<C-u>call MyPlugin#Operator('visual', v:count, "\<lt>Plug>(MyPluginVisual)")<CR>

If you want to support running without visualrepeat.vim, too, provide a
wrapper that defaults to 1v:

    function! s:VisualMode()
        let l:keys = "1v\<Esc>"
        silent! let l:keys = visualrepeat#reapply#VisualMode(0)
        return l:keys
    endfunction
    nnoremap <silent> <Plug>(MyPluginVisual)
    \ :<C-u>execute 'normal!' <SID>VisualMode()<Bar>
    \call MyPlugin#Operator('visual', "\<lt>Plug>(MyPluginVisual)")<CR>

CONTRIBUTING
------------------------------------------------------------------------------

Report any bugs, send patches, or suggest features via the issue tracker at
https://github.com/inkarkat/vim-visualrepeat/issues or email (address below).

HISTORY
------------------------------------------------------------------------------

##### 1.33    12-Nov-2024
- Adapt: Compatibility: Adding one character to previous exclusive selection
  not needed since Vim 9.0.1172 in visualrepeat#reapply#VisualMode().

##### 1.32    23-Feb-2020
- BUG: visualrepeat#reapply#VisualMode() mistakenly adds the next full line
  when restoring a linewise visual selection (to a smaller target).
- Use :normal for Vim 7.3.100..7.4.601 and feedkeys(..., 'i') for newer
  versions, aligning the used mechanism with what repeat.vim uses.

##### 1.31    17-Mar-2019
- ENH: Add g. mapping that forces built-in repeat; i.e. skips any custom
  repeat.vim or visualrepeat.vim actions. This can be useful if a plugin
  offers a special repeat for visual mode, but a built-in repeat on each
  selected line may make sense, too. For example, my KeepText.vim plugin would
  keep the entire linewise selection; forcing a built-in repeat (of the custom
  operator) would reapply e.g. a &lt;Leader&gt;ka" to all selected lines instead.
- Factor out ingo#buffer#temprange#Call() into ingo-library. !!! You need to
  update the optional dependency to ingo-library ([vimscript #4433](http://www.vim.org/scripts/script.php?script_id=4433)) version
  1.018! !!!
- ENH: Make an explicit register on repeat override g:repeat\_reg. As with
  built-in commands, this allows to override the original register on repeat,
  e.g. "a. uses register a instead of the original one. One limitation is that
  we cannot detect whether no or the default register has been given, so an
  override from a non-default to the default register (e.g. via "".) is not
  possible.

##### 1.30    15-Nov-2013
- ENH: When repeating over multiple lines / a blockwise selection, keep track
  of added or deleted lines, and only repeat exactly on the selected lines.
  Thanks to Israel Chauca for sending a patch!
- When a repeat on a blockwise selection has introduced additional lines,
  append those properly indented instead of omitting them.
- With linewise and blockwise repeat, set the change marks '[,'] to the
  changed selection. With the latter, one previously got "E19: Mark has
  invalid line number" due to the removed temporary range.

##### 1.20    14-Nov-2013
- ENH: Implement blockwise repeat through temporarily moving the block to a
  temporary range at the end of the buffer, like the vis.vim plugin. This
  feature requires the ingo-library.

__You need to separately install
  ingo-library ([vimscript #4433](http://www.vim.org/scripts/script.php?script_id=4433)) version 1.013 (or higher)!__

##### 1.10    05-Sep-2013
- Check for existence of actual visual mode mapping; do not accept a select
  mode mapping, because we're applying it to a visual selection.
- Pass through a [count] to the :normal . command.
- Add visualrepeat#reapply#VisualMode() and visualrepeat#reapply#RepeatCount()
  helper functions that plugins can use in their normal mode repeat mappings
  of repeated visual mode mappings.
- Minor: Make substitute() robust against 'ignorecase'.
- ENH: Use the current cursor virtual column when repeating in linewise visual
  mode. Inspired by
  http://stackoverflow.com/questions/18610564/vim-is-possible-to-use-dot-command-in-visual-block-mode
- Abort further commands on error by using echoerr inside the mapping.

##### 1.03    21-Feb-2013
- REGRESSION: Fix in 1.02 does not repeat recorded register when the mappings in
repeat.vim and visualrepeat.vim differ.

##### 1.02    27-Dec-2012
- BUG: "E121: Undefined variable: g:repeat\_sequence" when using visual repeat of
a mapping using registers without having used repeat.vim beforehand.

##### 1.01    05-Apr-2012
- FIX: Avoid error about undefined g:repeat\_reg when (a proper version of)
repeat.vim isn't available.

##### 1.00    14-Dec-2011
- First published version.

##### 0.01    17-Mar-2011
- Split off into dedicated plugin.

##### 0.00    30-Jul-2008
- Started development.

------------------------------------------------------------------------------
Copyright: (C) 2008-2024 Ingo Karkat -
The [VIM LICENSE](http://vimdoc.sourceforge.net/htmldoc/uganda.html#license) applies to this plugin.

Maintainer:     Ingo Karkat &lt;ingo@karkat.de&gt;
