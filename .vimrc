autocmd FileType md setlocal spell spelllang=en_us
autocmd FileType dot autocmd BufWritePre <buffer> !bash mkdot.sh ./dot
