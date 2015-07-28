setlocal spell spelllang=en_us
autocmd FileType dot autocmd BufWritePre * !bash mkdot.sh ./dot
