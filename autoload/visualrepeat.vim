" visualrepeat.vim: Repeat command extended to visual mode.
"
" DEPENDENCIES:
"   - ingo/selection.vim autoload script (optional; for blockwise repeat only)
"
" Copyright: (C) 2011-2013 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS
"   1.30.014	14-Nov-2013	ENH: When repeating over multiple lines / a
"				blockwise selection, keep track of added or
"				deleted lines, and only repeat exactly on the
"				selected lines. Thanks to Israel Chauca for
"				sending a patch!
"				When a repeat on a blockwise selection has
"				introduced additional lines, append those
"				properly indented instead of omitting them.
"				With linewise and blockwise repeat, set the
"				change marks '[,'] to the changed selection.
"				With the latter, one previously got "E19:
"				Mark has invalid line number" due to the removed
"				temporary range.
"   1.20.013	05-Sep-2013	ENH: Implement blockwise repeat through
"				temporarily moving the block to a temporary
"				range at the end of the buffer, like the vis.vim
"				plugin.
"   1.10.012	04-Sep-2013	ENH: Use the current cursor virtual column when
"				repeating in linewise visual mode. Add
"				visualrepeat#CaptureVirtCol() and
"				visualrepeat#repeatOnVirtCol() for that.
"				Minor: Also catch Vim echoerr exceptions and
"				anything else.
"				Move the error handling to the mapping itself
"				and do it with echoerr so that further commands
"				are properly aborted. Implement
"				visualrepeat#ErrorMsg() to avoid a dependency to
"				ingo#err#Get().
"   1.10.011	14-Jun-2013	Minor: Make substitute() robust against
"				'ignorecase'.
"   1.10.010	18-Apr-2013	Check for existence of actual visual mode
"				mapping; do not accept a select mode mapping,
"				because we're applying it to a visual selection.
"				Pass through a [count] to the :normal . command.
"   1.03.009	21-Feb-2013	REGRESSION: Fix in 1.02 does not repeat recorded
"				register when the mappings in repeat.vim and
"				visualrepeat.vim differ. We actually need to
"				always check g:repeat_sequence, since that is
"				also installed in g:repeat_reg[0]. Caught by
"				tests/ReplaceWithRegister/repeatLineAsVisual001.vim;
"				if only I had executed the tests sooner :-(
"				Fix by checking for the variable's existence
"				instead of using l:repeat_sequence.
"   1.02.008	27-Dec-2012	BUG: "E121: Undefined variable:
"				g:repeat_sequence" when using visual repeat
"				of a mapping using registers without having used
"				repeat.vim beforehand.
"   1.01.007	05-Apr-2012	FIX: Avoid error about undefined g:repeat_reg
"				when (a proper version of) repeat.vim isn't
"				available.
"   1.00.006	12-Dec-2011	Catch any errors from the :normal . repetitions
"				instead of causing function errors. Also use
"				exceptions for the internal error signaling.
"	005	06-Dec-2011	Retire visualrepeat#set_also(); it's the same as
"				visualrepeat#set() since we've dropped the
"				forced increment of b:changedtick.
"	004	22-Oct-2011	BUG: Must initialize g:visualrepeat_tick on load
"				to avoid "Undefined variable" error in autocmds
"				on BufWrite. It can happen that this autoload
"				script is loaded without having a repetition
"				registered at the same time.
"	003	21-Oct-2011	Also apply the same-register repeat enhancement
"				to repeat.vim here.
"	002	17-Oct-2011	Increment b:changedtick without clobbering the
"				expression register.
"				Must also adapt g:visualrepeat_tick on buffer
"				save to allow repetition after a save and buffer
"				switch (without relying on g:repeat_sequence
"				being identical to g:visualrepeat_sequence,
"				which has formerly often saved us).
"				Omit own increment of b:changedtick, let the
"				mapping do that (or not, in case of a
"				non-modifying mapping). It seems to work without
"				it, and avoids setting the 'modified' flag on
"				unmodified buffers, which is not expected.
"	001	17-Mar-2011	file creation
let s:save_cpo = &cpo
set cpo&vim

let g:visualrepeat_tick = -1

function! visualrepeat#set( sequence, ... )
    let g:visualrepeat_sequence = a:sequence
    let g:visualrepeat_count = a:0 ? a:1 : v:count
    let g:visualrepeat_tick = b:changedtick
endfunction


let s:virtcol = 1
function! visualrepeat#CaptureVirtCol()
    let s:virtcol = virtcol('.')
    return ''
endfunction
function! visualrepeat#repeatOnVirtCol( virtcol, count )
    execute 'normal!' a:virtcol . '|'
    if virtcol('.') >= a:virtcol
	execute 'normal' a:count . '.'
    endif
endfunction
function! s:RepeatOnRange( range, command )
    " The use of :global keeps track of lines added or deleted by the repeat, so
    " that we apply exactly to the selected lines.
    execute a:range . "global/^/" . a:command
    call histdel('search', -1)
endfunction
function! visualrepeat#repeat()
    if g:visualrepeat_tick == b:changedtick
	" visualrepeat.vim should handle the repeat.
	let l:repeat_sequence = g:visualrepeat_sequence
	let l:repeat_count = g:visualrepeat_count
    elseif exists('g:repeat_tick') && g:repeat_tick == b:changedtick
	" repeat.vim is enabled and would handle a normal-mode repeat.
	let l:repeat_sequence = g:repeat_sequence
	let l:repeat_count = g:repeat_count
    endif

    if exists('l:repeat_sequence')
	" A mapping for visualrepeat.vim or repeat.vim to repeat has been set.
	" Ensure that a corresponding visual mode mapping exists; some plugins
	" that only use repeat.vim may not have this.
	if ! empty(maparg(substitute(l:repeat_sequence, '^.\{3}', '<Plug>', 'g'), 'x'))
	    " Handle mappings that use a register and want the same register
	    " used on repetition.
	    let l:reg = ''
	    if exists('g:repeat_reg') && exists('g:repeat_sequence') &&
	    \   g:repeat_reg[0] ==# g:repeat_sequence && ! empty(g:repeat_reg[1])
		if g:repeat_reg[1] ==# '='
		    " This causes a re-evaluation of the expression on repeat, which
		    " is what we want.
		    let l:reg = '"=' . getreg('=', 1) . "\<CR>"
		else
		    let l:reg = '"' . g:repeat_reg[1]
		endif
	    endif

	    " The normal mode mapping to be repeated has a corresponding visual
	    " mode mapping. Use this so that the repetition will affect the
	    " current selection. With this we also avoid the clumsy application
	    " of the normal mode command to the visual selection, and can
	    " support blockwise visual mode.
	    let l:cnt = l:repeat_count == -1 ? '' : (v:count ? v:count : (l:repeat_count ? l:repeat_count : ''))

	    call feedkeys('gv' . l:reg . l:cnt, 'n')
	    call feedkeys(l:repeat_sequence)
	    return 1
	endif
    endif

    try
	" Note: :normal has no bang to allow a remapped '.' command here to
	" enable repeat.vim functionality.

	if visualmode() ==# 'v'
	    " Repeat the last change starting from the current cursor position.
	    execute 'normal' (v:count ? v:count : '') . '.'
	elseif visualmode() ==# 'V'
	    let [l:changeStart, l:changeEnd] = [getpos("'<"), getpos("'>")]

	    " For all selected lines, repeat the last change in the line.
	    if s:virtcol == 1
		" The cursor is set to the first column.
		call s:RepeatOnRange("'<,'>", 'normal ' . (v:count ? v:count : '') . '.')
	    else
		" The cursor is set to the cursor column; the last change is
		" only applied to lines that have at least that many characters.
		call s:RepeatOnRange("'<,'>", printf('call visualrepeat#repeatOnVirtCol(%d, %s)',
		\   s:virtcol,
		\   string(v:count ? v:count : '')
		\))
	    endif

	    call setpos("'[", l:changeStart)
	    call setpos("']", l:changeEnd)
	else
	    " Yank the selected block and repeat the last change in scratch
	    " lines at the end of the buffer (using a different buffer would be
	    " easier, but the repeated command may depend on the current
	    " buffer's settings), so that the change is limited to the
	    " selection. The vis.vim plugin does the same, but we cannot use it,
	    " because it performs the movement (to the bottom of the current
	    " buffer) via regular paste commands (which clobber the repeat
	    " command). We need to be careful to avoid doing that, using only
	    " lower level functions.
	    let l:changeStart = getpos("'<")
	    let l:startVirtCol = virtcol("'<")
	    let [l:count, l:startColPattern, l:startLnum, l:endLnum, l:finalLnum] = [v:count, ('\%>' . (l:startVirtCol - 1) . 'v'), line("'<"), line("'>"), line('$')]
	    let l:selection = split(ingo#selection#Get(), '\n', 1)

	    " Save the view after the yank so that the cursor resides at the
	    " beginning of the selected block, just as we would expect after the
	    " repeat. (The :normal / :delete of the temporary range later
	    " modifies the cursor position.)
	    let l:save_view = winsaveview()

	    let l:tempRange = (l:finalLnum + 1) . ',$'
	    call append(l:finalLnum, l:selection)
	    " The cursor is set to the first column.
	    call s:RepeatOnRange(l:tempRange, 'normal ' . (l:count ? l:count : '') . '.')
	    let l:result = getline(l:finalLnum + 1, '$')
	    try
		" Using :undo to roll back the append and repeat is safer,
		" because any potential modification outside the temporary range
		" is also eliminated. Only explicitly delete the temporary range
		" as a fallback.
		silent undo
	    catch /^Vim\%((\a\+)\)\=:E/
		silent! execute l:tempRange . 'delete _'
	    endtry

	    for l:lnum in range(l:startLnum, l:endLnum)
		let l:idx = l:lnum - l:startLnum
		let l:line = getline(l:lnum)
		let l:startCol = match(l:line, l:startColPattern)
		let l:endCol = l:startCol + len(l:selection[l:idx])
		let l:resultLine = get(l:result, l:idx, '') " Replace the line part with an empty string if there are less lines after the repeat.
		let l:newLine = strpart(l:line, 0, l:startCol) . l:resultLine . strpart(l:line, l:endCol)
		call setline(l:lnum, l:newLine)
	    endfor

	    let l:addedNum = len(l:result) - l:idx - 1
	    if l:addedNum == 0
		let l:changeEnd = [0, l:lnum, l:startCol + len(l:resultLine), 0]
	    else
		" The repeat has introduced additional lines; append those (as
		" new lines) properly indented to the start of the blockwise
		" selection.
		let l:indent = repeat(' ', l:startVirtCol - 1)

		" To use the buffer's indent settings, first insert spaces and
		" have :retab convert those to the proper indent. Then, append
		" the additional lines.
		call append(l:lnum, repeat([l:indent], l:addedNum))

		silent execute printf('%d,%dretab!', l:lnum + 1, l:lnum + l:addedNum + 1)

		for l:addedIdx in range(l:addedNum)
		    let l:addedLnum = l:lnum + 1 + l:addedIdx
		    call setline(l:addedLnum, getline(l:addedLnum) . l:result[l:idx + 1 + l:addedIdx])
		endfor

		let l:changeEnd = [0, l:addedLnum, len(getline(l:addedLnum)) + 1, 0]
	    endif

	    " The change marks still point to the (removed) temporary range.
	    " Make them valid by setting them to the changed selection.
	    call setpos("'[", l:changeStart)
	    call setpos("']", l:changeEnd)

	    call winrestview(l:save_view)
	endif
	return 1
    catch /^Vim\%((\a\+)\)\=:E117:.*ingo#selection#Get/ " E117: Unknown function: ingo#selection#Get
	let s:errorMsg = 'For blockwise repeat, you need to install the ingo-library dependency'
    catch /^Vim\%((\a\+)\)\=:/
	" v:exception contains what is normally in v:errmsg, but with extra
	" exception source info prepended, which we cut away.
	let s:errorMsg = substitute(v:exception, '^\CVim\%((\a\+)\)\=:', '', '')
    catch
	let s:errorMsg = v:exception
    endtry

    return 0
endfunction

let s:errorMsg = ''
function! visualrepeat#ErrorMsg()
    return s:errorMsg
endfunction

augroup visualrepeatPlugin
    autocmd!
    autocmd BufLeave,BufWritePre,BufReadPre * let g:visualrepeat_tick = (g:visualrepeat_tick == b:changedtick || g:visualrepeat_tick == 0) ? 0 : -1
    autocmd BufEnter,BufWritePost * if g:visualrepeat_tick == 0|let g:visualrepeat_tick = b:changedtick|endif
augroup END

let &cpo = s:save_cpo
unlet s:save_cpo
" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
