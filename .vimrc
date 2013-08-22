syntax on
set hidden
set title
set ruler
set hlsearch
set incsearch
set expandtab
set smartindent
set shiftwidth=2
set tabstop=4
set softtabstop=2
set t_Co=256
"set t_AB=^[[48;5;%dm
"set t_AF=^[[38;5;%dm

" :sum command
cnoreabbrev sum ! python -c 'import sys;print sum([int(x) for x in sys.stdin.read().split() if x])'

" 4-space tab widths for python (and pyrex)
autocmd FileType py* setlocal shiftwidth=4 tabstop=8 softtabstop=4

" # key toggle comments in python
function! TogglePythonComments()
 if match(getline("."), '^ *#') >= 0
   execute ':s+#++' |
 else
   execute ':s+^+#+' |
 endif
endfunction
autocmd FileType python map # :call TogglePythonComments()<cr>

" highlight lines over 79 cols, spaces at the end of lines and tab characters
highlight BadStyle ctermbg=darkred ctermfg=darkgray
match BadStyle "\(\%>79v.\+\|\t\| \+$\)"

