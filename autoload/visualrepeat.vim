" visualrepeat.vim: Repeat command extended to visual mode.
"
" DEPENDENCIES:
"
" Copyright: (C) 2011-2013 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS
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
	    return
	endif
    endif

    try
	" Note: :normal has no bang to allow a remapped '.' command here to
	" enable repeat.vim functionality.

	if visualmode() ==# 'v'
	    " Repeat the last change starting from the current cursor position.
	    execute 'normal' (v:count ? v:count : '') . '.'
	elseif visualmode() ==# 'V'
	    " For all selected lines, repeat the last change in the line.
	    if s:virtcol == 1
		" The cursor is set to the first column.
		execute "'<,'>normal" (v:count ? v:count : '') . '.'
	    else
		" The cursor is set to the cursor column; the last change is
		" only applied to lines that have at least that many characters.
		execute printf("'<,'>call visualrepeat#repeatOnVirtCol(%d, %s)",
		\   s:virtcol,
		\   string(v:count ? v:count : '')
		\)
	    endif
	else
	    throw 'visualrepeat: Cannot repeat in this visual mode!'
	endif
	return 1
    catch /^Vim\%((\a\+)\)\=:/
	" v:exception contains what is normally in v:errmsg, but with extra
	" exception source info prepended, which we cut away.
	let s:errorMsg = substitute(v:exception, '^\CVim\%((\a\+)\)\=:', '', '')
    catch /^visualrepeat:/
	let s:errorMsg = substitute(v:exception, '^\Cvisualrepeat:\s*', '', '')
    catch
	let s:errorMsg = v:exception
    endtry

    return 0
endfunction

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
