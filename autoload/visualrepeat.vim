" visualrepeat.vim: Repeat command extended to visual mode. 
"
"   Operator-pending mappings end with "g@" and repeat naturally; i.e. Vim
"   re-applies the 'opfunc' on the equivalent text (but at the current cursor
"   position). But without a call to repeat#set(), it is impossible to repeat
"   this operator-pending mapping to the current visual selection. Plugins
"   cannot call repeat#set() in their operator-pending mapping, because then
"   Vim's built-in repeat would be circumvented, the full mapping ending with g@
"   would be re-executed, and the repetition would then wait for the {motion},
"   what is not wanted. 
"   Therefore, this plugin offers a separate visualrepeat#set() function that
"   can be invoked for operator-pending mappings (and visualrepeat#set_also for
"   normal-mode mappings that have already called repeat#set(), and may override
"   that mapping with a special repeat mapping for visual mode repeats). 
"   Together with the remapped {Visual}. command, this allows repetition - similar
"   to what the built-in Vim commands do - across normal, operator-pending and
"   visual mode.  
"
" DEPENDENCIES:
"
" Copyright: (C) 2011 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'. 
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS 
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

" Use this when you do NOT also invoke repeat#set(). 
function! visualrepeat#set( sequence, ... )
    let g:visualrepeat_sequence = a:sequence
    let g:visualrepeat_count = a:0 ? a:1 : v:count
    let g:visualrepeat_tick = b:changedtick
endfunction

" Use this when you do have already invoked repeat#set(). 
" Always call repeat#set() first! 
function! visualrepeat#set_also( sequence, ... )
    let g:visualrepeat_sequence = a:sequence
    let g:visualrepeat_count = a:0 ? a:1 : v:count
    let g:visualrepeat_tick = b:changedtick
endfunction


function! visualrepeat#repeat()
    if exists('g:visualrepeat_tick') && g:visualrepeat_tick == b:changedtick
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
	if ! empty(maparg(substitute(l:repeat_sequence, '^.\{3}', '<Plug>', 'g'), 'v'))
	    " Handle mappings that use a register and want the same register
	    " used on repetition. 
	    let l:reg = ''
	    if g:repeat_reg[0] ==# g:repeat_sequence && ! empty(g:repeat_reg[1])
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

    " Note: :normal has no bang to allow a remapped '.' command here to enable
    " repeat.vim functionality. 

    if visualmode() ==# 'v'
	" Repeat the last change starting from the current cursor position. 
	normal .
    elseif visualmode() ==# 'V'
	" For all selected lines, repeat the last change in the line; the cursor
	" is set to the first column. 
	'<,'>normal .
    else
	let v:errmsg = 'Cannot repeat in this visual mode!'
	echohl ErrorMsg
	echomsg v:errmsg
	echohl None
	sleep 500m
	normal! gv
    endif
endfunction

augroup visualrepeatPlugin
    autocmd!
    autocmd BufLeave,BufWritePre,BufReadPre * let g:visualrepeat_tick = (g:visualrepeat_tick == b:changedtick || g:visualrepeat_tick == 0) ? 0 : -1
    autocmd BufEnter,BufWritePost * if g:visualrepeat_tick == 0|let g:visualrepeat_tick = b:changedtick|endif
augroup END

" vim: set sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
