" Basic settings
set nocompatible
syntax on
filetype plugin indent on

" Colorscheme
set background=dark
colorscheme nord

" UI
set number
set relativenumber
set cursorline
set signcolumn=yes
set laststatus=2
set showcmd
set showmode

" Search
set hlsearch
set incsearch
set ignorecase
set smartcase

" Indentation
set expandtab
set tabstop=2
set shiftwidth=2
set autoindent
set smartindent

" Editor behavior
set backspace=indent,eol,start
set scrolloff=8
set encoding=utf-8
set nowrap

" No swap/backup files
set noswapfile
set nobackup
set nowritebackup

" Git commit message settings
autocmd FileType gitcommit setlocal spell spelllang=en_us
autocmd FileType gitcommit setlocal textwidth=72
