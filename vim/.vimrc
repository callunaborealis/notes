"                                                                                        
"               ,--.,--.                                      ,--.                        
"  ,---. ,--,--.|  ||  |,--.,--.,--,--,  ,--,--.    ,--.  ,--.`--',--,--,--.,--.--. ,---. 
" | .--'' ,-.  ||  ||  ||  ||  ||      \' ,-.  |     \  `'  / ,--.|        ||  .--'| .--' 
" \ `--.\ '-'  ||  ||  |'  ''  '|  ||  |\ '-'  |      \    /  |  ||  |  |  ||  |   \ `--. 
"  `---' `--`--'`--'`--' `----' `--''--' `--`--'       `--'   `--'`--`--`--'`--'    `---' 
"  __                             _       _                         _      
" / _|                           | |     | |                       | |     
" | |_ ___  _ __    __ _ _ __ ___| |__   | | _____  _ __  ___  ___ | | ___ 
" |  _/ _ \| '__|  / _` | '__/ __| '_ \  | |/ / _ \| '_ \/ __|/ _ \| |/ _ \
" | || (_) | |    | (_| | | | (__| | | | |   < (_) | | | \__ \ (_) | |  __/
" |_| \___/|_|     \__,_|_|  \___|_| |_| |_|\_\___/|_| |_|___/\___/|_|\___|
"                                                                          
"
syntax on
set number
set autoindent
set title
set laststatus=2

"disable compatibility with vi which can cause issues
set nocompatible

"enable type file detection
filetype on
filetype plugin on
filetype indent on

"set shift and tab widths to 4 chars long
set shiftwidth=4
set tabstop=4
"use tabs when tabbing
set expandtab

" show partial command typed in the last line of the screen
set showcmd

" show mode on last line
set showmode

"highlight text when searching
set hlsearch
"highlight while typing
set incsearch

"file name only
set statusline=%t\ \|

"file encoding
set statusline+=\ %{strlen(&fenc)?&fenc:'none'},
"file format
set statusline+=\ %{&ff}\ \|

"help file flag
set statusline+=\ %h

"modified flag
set statusline+=%m

"readonly flag
set statusline+=%r

"filetype
set statusline+=%y

"left/right separator
set statusline+=%=

"cursor column
set statusline+=C%c\ \|

"left/right separator
set statusline+=\ L%l/%L\ \|

"cursor column
set statusline+=\ %p%{'%'}\ of\ lines\ \|

"percentage through file
set statusline+=\ 1st\ line\ range\ start%{':'}\ %P\ 
