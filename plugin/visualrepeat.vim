" visualrepeat.vim: Repeat command extended to visual mode.
"
" DEPENDENCIES:
"   - visualrepeat.vim autoload script
"
" Copyright: (C) 2011-2019 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>

" Avoid installing twice or when in unsupported Vim version.
if exists('g:loaded_visualrepeat') || (v:version < 700)
    finish
endif
let g:loaded_visualrepeat = 1
let s:save_cpo = &cpo
set cpo&vim

" In linewise visual mode, after entering the command line with :, the current
" cursor position is lost. Therefore, capture the cursor's virtual column via a
" no-op expression mapping.
xnoremap <expr> <SID>(CaptureVirtCol) visualrepeat#CaptureVirtCol()

xnoremap <script> <silent> . <SID>(CaptureVirtCol):<C-u>
\if ! visualrepeat#repeat()<Bar>
\   echoerr visualrepeat#ErrorMsg()<Bar>
\   if &cmdheight == 1<Bar>
\       sleep 500m<Bar>
\   endif<Bar>
\   execute 'normal! gv'<Bar>
\endif<CR>
" In visual mode, the mode message will override the error message. Therefore,
" sleep() for a short while to allow the user to notice it.

vnoremap <script> <silent> <Plug>(visualrepeatForceBuiltInRepeat) <SID>(CaptureVirtCol):<C-u>
\if ! visualrepeat#repeat(1)<Bar>
\   echoerr visualrepeat#ErrorMsg()<Bar>
\   if &cmdheight == 1<Bar>
\       sleep 500m<Bar>
\   endif<Bar>
\   execute 'normal! gv'<Bar>
\endif<CR>
if ! hasmapto('<Plug>(visualrepeatForceBuiltInRepeat)', 'x')
    xmap g. <Plug>(visualrepeatForceBuiltInRepeat)
endif

let &cpo = s:save_cpo
unlet s:save_cpo
" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
