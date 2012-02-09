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
map <C-n> :bn<cr>
map <C-p> :bp<cr>
map <C-t> :E<cr>

highlight SpecialKey term=bold ctermfg=16
highlight NonText term=bold ctermfg=16
highlight Directory term=bold ctermfg=253
highlight ErrorMsg term=standout ctermfg=246 ctermbg=1
highlight IncSearch term=reverse ctermfg=16 ctermbg=240
highlight Search term=reverse ctermfg=16 ctermbg=253
highlight MoreMsg term=bold ctermfg=253
highlight ModeMsg term=bold ctermfg=246
highlight LineNr term=underline ctermfg=16 ctermbg=16
highlight Question term=standout ctermfg=246
highlight StatusLine term=bold,reverse ctermfg=246 ctermbg=16
highlight StatusLineNC term=reverse ctermfg=16 ctermbg=246
highlight VertSplit term=reverse ctermfg=16 ctermbg=246
highlight Title term=bold ctermfg=246
highlight Visual term=reverse ctermfg=16 ctermbg=237
highlight VisualNOS ctermfg=253
highlight WarningMsg term=standout ctermfg=253
highlight WildMenu term=standout ctermfg=246 ctermbg=16
highlight Folded term=standout ctermfg=246 ctermbg=16
highlight FoldColumn term=standout ctermfg=253 ctermbg=242
highlight DiffAdd term=bold ctermfg=246 ctermbg=4
highlight DiffChange term=bold ctermfg=246 ctermbg=5
highlight DiffDelete term=bold ctermfg=246 ctermbg=6
highlight DiffText term=reverse ctermfg=253 ctermbg=9
highlight SignColumn term=standout ctermfg=253 ctermbg=248
highlight Conceal ctermfg=7 ctermbg=242
highlight SpellBad term=reverse ctermfg=253 ctermbg=224
highlight SpellCap term=reverse ctermfg=253 ctermbg=81
highlight SpellRare term=reverse ctermfg=253 ctermbg=225
highlight SpellLocal term=underline ctermfg=253 ctermbg=14
highlight Pmenu ctermfg=246 ctermbg=16
highlight PmenuSel ctermfg=16 ctermbg=246
highlight PmenuSbar ctermfg=246 ctermbg=16
highlight PmenuThumb ctermfg=246 ctermbg=16
highlight TabLine term=underline ctermfg=246 ctermbg=16
highlight TabLineSel term=bold ctermfg=253
highlight TabLineFill term=reverse ctermfg=253
highlight CursorColumn term=reverse ctermfg=253 ctermbg=16
highlight CursorLine term=underline ctermfg=253 ctermbg=16
highlight ColorColumn term=reverse ctermbg=224
highlight MatchParen term=reverse ctermfg=253 ctermbg=6
highlight Comment term=bold ctermfg=4
highlight Constant term=underline ctermfg=1
highlight Special term=bold ctermfg=240
highlight Identifier term=underline ctermfg=6
highlight Statement term=bold ctermfg=240
highlight PreProc term=underline ctermfg=240
highlight Type term=underline ctermfg=240
highlight Underlined term=underline cterm=bold,underline ctermfg=253
highlight Ignore ctermfg=15
highlight Error term=reverse ctermfg=15 ctermbg=9
highlight Todo term=standout ctermfg=253 ctermbg=16
highlight String ctermfg=88
highlight Character ctermfg=253
highlight Number ctermfg=23
highlight Boolean ctermfg=253
highlight Float ctermfg=253
highlight Function ctermfg=240
highlight Conditional ctermfg=240
highlight Repeat ctermfg=240
highlight Label ctermfg=240
highlight Operator ctermfg=240
highlight Keyword ctermfg=240
highlight Exception ctermfg=240
highlight Include ctermfg=240
highlight Define ctermfg=240
highlight Macro ctermfg=240
highlight PreCondit ctermfg=240
highlight StorageClass ctermfg=240
highlight Structure ctermfg=240
highlight Typedef ctermfg=240
highlight Tag ctermfg=240
highlight SpecialChar ctermfg=240
highlight Delimiter ctermfg=240
highlight SpecialComment ctermfg=237
highlight Debug ctermfg=240
highlight CTagsClass ctermfg=253
highlight CTagsGlobalConstant ctermfg=253
highlight CTagsGlobalVariable ctermfg=253
highlight CTagsImport ctermfg=253
highlight CTagsMember ctermfg=253
highlight Cursor ctermfg=16 ctermbg=246
highlight DefinedName ctermfg=253
highlight EnumerationName ctermfg=253
highlight EnumerationValue ctermfg=253
highlight LocalVariable ctermfg=253
highlight Normal ctermfg=246 ctermbg=16
highlight Union ctermfg=253
highlight pythonBuiltin ctermfg=246
highlight JavaScriptStrings ctermfg=253
highlight phpStringSingle ctermfg=253
highlight phpStringDouble ctermfg=253
highlight htmlString ctermfg=246
highlight htmlTagName ctermfg=246

" highlight lines over 79 cols, spaces at the end of lines and tab characters
highlight BadStyle ctermbg=darkred ctermfg=darkgray
match BadStyle "\(\%>78v.\+\|\t\| \+$\)"

