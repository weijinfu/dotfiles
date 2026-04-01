set nocompatible
set nu
syntax on
set nobackup
set clipboard=unnamed
set tabstop=4
set shiftwidth=4

let mapleader=" "
let &t_SI.="\e[5 q" "SI = INSERT mode
let &t_SR.="\e[4 q" "SR = REPLACE mode
let &t_EI.="\e[1 q" "EI = NORMAL mode (ELSE)let mapleader=" "

map J 10j
map K 10k
map U <C-r>
map <leader>s :w<cr>
map <leader>q :q<cr>
nnoremap <leader>n :NERDTreeToggle<CR>
nnoremap <leader>f :NERDTreeFind<CR>

map s <nop>
inoremap jj <Esc>
inoremap kk <Esc>
call plug#begin()
	Plug 'vim-airline/vim-airline'
	Plug 'neoclide/coc.nvim', {'branch': 'release'}
	Plug 'preservim/nerdtree'
call plug#end()

