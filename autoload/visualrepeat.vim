" visualrepeat.vim: Repeat command extended to visual mode.
"
" DEPENDENCIES:
"   - ingo/register.vim autoload script (optional; for register override only)
"   - ingo/selection.vim autoload script (optional; for blockwise repeat only)
"   - ingo/buffer/temprange.vim autoload script (optional; for blockwise repeat only)
"
" Copyright: (C) 2011-2019 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
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
function! visualrepeat#repeatOnVirtCol( virtcol, count, normalCmd )
    execute 'normal!' a:virtcol . '|'
    if virtcol('.') >= a:virtcol
	execute a:normalCmd a:count . '.'
    endif
endfunction
function! visualrepeat#RepeatOnRange( range, command )
    " The use of :global keeps track of lines added or deleted by the repeat, so
    " that we apply exactly to the selected lines.
    execute a:range . "global/^/" . a:command
    call histdel('search', -1)
endfunction
function! visualrepeat#repeat( ... )
    let l:isForceBuildInRepeat = (a:0 && a:1)

    " Note: Unless forced, :normal has no bang to allow a remapped '.' command
    " here to enable repeat.vim functionality.
    let l:normalCmd = 'normal' . (l:isForceBuildInRepeat ? '!' : '')

    if g:visualrepeat_tick == b:changedtick
	" visualrepeat.vim should handle the repeat.
	let l:repeat_sequence = g:visualrepeat_sequence
	let l:repeat_count = g:visualrepeat_count
    elseif exists('g:repeat_tick') && g:repeat_tick == b:changedtick
	" repeat.vim is enabled and would handle a normal-mode repeat.
	let l:repeat_sequence = g:repeat_sequence
	let l:repeat_count = g:repeat_count
    endif

    if ! l:isForceBuildInRepeat && exists('l:repeat_sequence')
	" A mapping for visualrepeat.vim or repeat.vim to repeat has been set.
	" Ensure that a corresponding visual mode mapping exists; some plugins
	" that only use repeat.vim may not have this.
	if ! empty(maparg(substitute(l:repeat_sequence, '^.\{3}', '<Plug>', 'g'), 'x'))
	    " Handle mappings that use a register and want the same register
	    " used on repetition.
	    let l:reg = ''
	    if exists('g:repeat_reg') && exists('g:repeat_sequence') &&
	    \   g:repeat_reg[0] ==# g:repeat_sequence && ! empty(g:repeat_reg[1])
		" Take the original register, unless another (non-default, we
		" unfortunately cannot detect no vs. a given default register)
		" register has been supplied to the repeat command (as an
		" explicit override).
		let l:regName = g:repeat_reg[1]
		silent! let l:regName = (v:register ==# ingo#register#Default() ? g:repeat_reg[1] : v:register) " Register override needs the optional ingo-library dependency.
		if l:regName ==# '='
		    " This causes a re-evaluation of the expression on repeat, which
		    " is what we want.
		    let l:reg = '"=' . getreg('=', 1) . "\<CR>"
		else
		    let l:reg = '"' . l:regName
		endif
	    endif

	    " The normal mode mapping to be repeated has a corresponding visual
	    " mode mapping. Use this so that the repetition will affect the
	    " current selection. With this we also avoid the clumsy application
	    " of the normal mode command to the visual selection, and can
	    " support blockwise visual mode.
	    let l:cnt = l:repeat_count == -1 ? '' : (v:count ? v:count : (l:repeat_count ? l:repeat_count : ''))

	    if ((v:version == 703 && has('patch100')) || (v:version == 704 && !has('patch601')))
                exe 'normal gv' . l:reg . l:cnt . l:repeat_sequence
	    elseif v:version <= 703
		call feedkeys('gv' . l:reg . l:cnt, 'n')
		call feedkeys(l:repeat_sequence, '')
	    else
		call feedkeys(l:repeat_sequence, 'i')
		call feedkeys('gv' . l:reg . l:cnt, 'ni')
	    endif
	    return 1
	endif
    endif

    try
	if visualmode() ==# 'v'
	    " Repeat the last change starting from the current cursor position.
	    execute l:normalCmd . ' ' . (v:count ? v:count : '') . '.'
	elseif visualmode() ==# 'V'
	    let [l:changeStart, l:changeEnd] = [getpos("'<"), getpos("'>")]

	    " For all selected lines, repeat the last change in the line.
	    if s:virtcol == 1
		" The cursor is set to the first column.
		call visualrepeat#RepeatOnRange("'<,'>", l:normalCmd . ' ' . (v:count ? v:count : '') . '.')
	    else
		" The cursor is set to the cursor column; the last change is
		" only applied to lines that have at least that many characters.
		call visualrepeat#RepeatOnRange("'<,'>", printf('call visualrepeat#repeatOnVirtCol(%d, %s, %s)',
		\   s:virtcol,
		\   string(v:count ? v:count : ''),
		\   string(l:normalCmd)
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
	    let [l:count, l:startColPattern, l:startLnum, l:endLnum] = [v:count, ('\%>' . (l:startVirtCol - 1) . 'v'), line("'<"), line("'>")]
	    let l:selection = split(ingo#selection#Get(), '\n', 1)

	    let l:result = ingo#buffer#temprange#Call(l:selection, function('visualrepeat#RepeatOnRange'), ['.,$', l:normalCmd . ' ' . (l:count ? l:count : '') . '.'], 1)

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
