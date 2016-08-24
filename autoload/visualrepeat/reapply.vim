" visualrepeat/reapply.vim: Functions to cross-apply a visual mode mapping in a normal mode repeat.
"
" DEPENDENCIES:
"
" Copyright: (C) 2013 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS
"   1.10.001	18-Apr-2013	file creation

function! visualrepeat#reapply#VisualMode( isStayInVisualMode )
"****D echomsg '****' v:count g:repeat_count
    let l:appendix = (a:isStayInVisualMode ? '' : "\<Esc>")
    let l:isOnlyRepeatCount = (g:repeat_count == v:count)
    let l:count = (l:isOnlyRepeatCount ? 1 : v:count1)
    if ! l:isOnlyRepeatCount && visualmode() ==# 'V'
	" Select [count] lines, not [count] times the previously selected lines.
	" It would be more correct to do this for the other selection modes,
	" too, but it's difficult to multiply their size.
	return 'V' . (l:count > 1 ? l:count . '_' : '') . l:appendix
    else
	" A normal-mode repeat of the visual mapping is triggered by repeat.vim.
	" It establishes a new selection at the cursor position, of the same
	" mode and size as the last selection.
	"   If [count] is given, the size is multiplied accordingly. This has
	"   the side effect that a repeat with [count] will persist the expanded
	"   size, which is different from what the normal-mode repeat does (it
	"   keeps the scope of the original command).
	return l:count . 'v' . (&selection ==# 'exclusive' ? ' ' : '') . l:appendix
	" For ':set selection=exclusive', the final character must be
	" re-included with <Space>, but only if this is not linewise visual
	" mode; in that case, the <Space> would add the next line in case the
	" last selected line is empty.
    endif
endfunction
function! visualrepeat#reapply#RepeatCount()
    return (g:repeat_count ? g:repeat_count : '')
endfunction
" Note: We don't need to check for the existence of g:repeat_count here; the
" normal mode repeat mapping of a visual mode mapping can only be triggered
" through an installed repeat.vim.


finish
" Note: The count cannot be injected inside the :normal; it is ignored:
nmap <F12> :<C-u>execute 'normal! gv32'<CR>:<C-u>echomsg '****' v:count<CR>
" What works is prepending via a map-expr:
nmap <F12> :<C-u>execute 'normal! gv'<CR>32:<C-u>echomsg '****' v:count<CR>
" But somehow only when used with : Ex commands, not normal-mode commands; this
" fails:
nmap <F12> :<C-u>execute 'normal! gv'<CR>32A$<Esc>
" But this works again:
nmap <F12> :<C-u>execute 'normal! gv'<CR>32:<C-u>execute 'normal! gv' . v:count . "A$\<lt>Esc>"<CR>

" This is how you would use this in your plugin; we don't define a
" <Plug>-mapping here, as you probably want to keep using :noremap (now with
" <script> argument and below <SID>-mapping).
vnoremap <silent> <expr> <SID>(ReapplyRepeatCount) visualrepeat#reapply#RepeatCount()

" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
