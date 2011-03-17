" visualrepeat.vim: summary
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
"	001	17-Mar-2011	file creation

" Use this when you do NOT also invoke repeat#set(). 
function! visualrepeat#set( sequence, ... )
    silent exe "norm! \"=''\<CR>p"
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

" vim: set sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
