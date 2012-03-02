if exists('g:loaded_coffee_tools') || &cp
  finish
endif

let g:loaded_coffee_tools = '0.0.1' " version number
let s:keepcpo             = &cpo
set cpo&vim

if !exists('g:coffee_tools_split_command')
  let g:coffee_tools_split_command = 'split'
endif

if !exists('g:coffee_tools_autojump')
  let g:coffee_tools_autojump = 0
endif

if !exists('g:coffee_tools_default_mappings')
  let g:coffee_tools_default_mappings = 0
endif

command! CoffeePreviewOpen   call coffee_tools#OpenPreview()
command! CoffeePreviewClose  call coffee_tools#ClosePreview()
command! CoffeePreviewToggle call coffee_tools#TogglePreview()

nnoremap <Plug>CoffeeToolsDeleteAndDedent   :     call coffee_tools#DeleteAndDedent(0)<cr>
xnoremap <Plug>CoffeeToolsDeleteAndDedent   :<c-u>call coffee_tools#DeleteAndDedent(1)<cr>
xnoremap <Plug>CoffeeToolsOpenLineAndIndent :<c-u>call coffee_tools#OpenLineAndIndent()<cr>

if g:coffee_tools_default_mappings
  autocmd FileType coffee nmap <buffer> dd <Plug>CoffeeToolsDeleteAndDedent
  autocmd FileType coffee xmap <buffer> d <Plug>CoffeeToolsDeleteAndDedent
endif
