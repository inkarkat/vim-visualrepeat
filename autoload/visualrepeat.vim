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
"	002	17-Oct-2011	Increment b:changedtick without clobbering the
"				expression register. 
"	001	17-Mar-2011	file creation

" Use this when you do NOT also invoke repeat#set(). 
function! visualrepeat#set( sequence, ... )
    call setline(1, getline(1)) " Increment b:changedtick
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
	let l:repeat_sequence = g:visualrepeat_sequence
	let l:repeat_count = g:visualrepeat_count
    elseif exists('g:repeat_tick') && g:repeat_tick == b:changedtick
	let l:repeat_sequence = g:repeat_sequence
	let l:repeat_count = g:repeat_count
    endif

    if exists('l:repeat_sequence')
	" repeat.vim is enabled and responsible for handling the next repeat.  
	if ! empty(maparg(substitute(l:repeat_sequence, '^.\{3}', '<Plug>', 'g'), 'v'))
	    " The normal mode mapping to be repeated has a corresponding visual
	    " mode mapping. Use this so that the repetition will affect the
	    " current selection. With this we also avoid the clumsy application
	    " of the normal mode command to the visual selection, and can
	    " support blockwise visual mode. 
	    let l:cnt = l:repeat_count == -1 ? '' : (v:count ? v:count : (l:repeat_count ? l:repeat_count : ''))
	    call feedkeys('gv' . l:cnt . l:repeat_sequence)
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

" vim: set sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
