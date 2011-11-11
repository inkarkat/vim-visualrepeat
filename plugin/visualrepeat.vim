" visualrepeat.vim: Repeat command extended to visual mode. 
"
" {Visual}.		Repeat last change in all visually selected lines. 
"			- characterwise: Start from cursor position. 
" 			- linewise: Each line separately, starting from first column. 
" 			- blockwise: Not supported. 
" Source: vimtip #1142, http://vim.wikia.com/wiki/Repeat_last_command_and_put_cursor_at_start_of_change
" Note: If the last normal mode command included a {motion} (e.g. g~e), the
" repetition will also move exactly over this {motion}, NOT the visual
" selection! It is thus best to repeat commands that work on the entire line
" (e.g. g~$). 
"
" DEPENDENCIES:
"
" Copyright: (C) 2011 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'. 
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS 
"	001	18-Mar-2011	file creation from ingomappings.vim. 

" Avoid installing twice or when in unsupported Vim version. 
if exists('g:loaded_visualrepeat') || (v:version < 700)
    finish
endif
let g:loaded_visualrepeat = 1

xnoremap <silent> . :<C-U>call visualrepeat#repeat()<CR>

" vim: set sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
