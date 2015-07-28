setlocal spell spelllang=en_us
autocmd FileType rb,md,vim autocmd BufWritePre * !bash mkdot.sh
