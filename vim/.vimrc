" base
set nocompatible
set nu
syntax on
set termguicolors
set nobackup
set clipboard=unnamed
set tabstop=4
set shiftwidth=4
let mapleader=" "
let &t_SI.="\e[5 q" "SI = INSERT mode
let &t_SR.="\e[4 q" "SR = REPLACE mode
let &t_EI.="\e[1 q" "EI = NORMAL mode

map J 10j
map K 10k
map U <C-r>
map <leader>s :w<cr>
map <leader>q :q<cr>

map s <nop>
inoremap jj <Esc>
inoremap kk <Esc>

" outer edit
set autoread
autocmd FocusGained,BufEnter,CursorHold,CursorHoldI * if mode() != 'c' | checktime | endif

" coding
set hidden
set updatetime=300
set shortmess+=c
set signcolumn=yes
set completeopt=menuone,noinsert,noselect

" Tab
inoremap <silent><expr> <TAB>
      \ pumvisible() ? "\<C-n>" :
      \ CheckBackspace() ? "\<TAB>" :
      \ coc#refresh()

" Shift-Tab
inoremap <silent><expr> <S-TAB>
      \ pumvisible() ? "\<C-p>" :
      \ "\<C-d>"
" Enter
inoremap <silent><expr> <CR>
      \ pumvisible() ? coc#_select_confirm() : "\<CR>"

function! CheckBackspace() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1] =~# '\s'
endfunction

nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gr <Plug>(coc-references)
nmap <silent> gi <Plug>(coc-implementation)
nnoremap <leader>rn <Plug>(coc-rename)
nnoremap <silent> gh :call CocActionAsync('doHover')<CR>
" autocmd CursorHold * silent call CocActionAsync('doHover')
" set updatetime=1000

" theme and plug
call plug#begin()
	Plug 'catppuccin/vim', { 'as': 'catppuccin' }
	Plug 'vim-airline/vim-airline'
	Plug 'neoclide/coc.nvim', {'branch': 'release'}
call plug#end()

function! s:ApplySystemTheme() abort
	if has('macunix')
		let l:appearance = system('defaults read -g AppleInterfaceStyle 2>/dev/null')
		if v:shell_error == 0 && l:appearance =~? 'Dark'
			set background=dark
			silent! colorscheme catppuccin_mocha
		else
			set background=light
			silent! colorscheme catppuccin_latte
		endif
	else
		if &background ==# 'light'
			silent! colorscheme catppuccin_latte
		else
			silent! colorscheme catppuccin_mocha
		endif
	endif
endfunction

augroup SystemThemeSync
	autocmd!
	autocmd VimEnter,FocusGained * call s:ApplySystemTheme()
augroup END
