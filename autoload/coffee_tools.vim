function! coffee_tools#OpenPreview()
  if !exists('b:preview_file')
    call coffee_tools#InitPreview()
  endif

  if bufwinnr(b:preview_file) < 0
    exe g:coffee_tools_split_command.' '.b:preview_file
    let b:original_file = expand('#')

    doautocmd User CoffeeToolsPreviewOpened

    if !g:coffee_tools_autojump
      call coffee_tools#SwitchWindow(b:original_file)
    endif
  endif

  call coffee_tools#UpdatePreview()
endfunction

function! coffee_tools#ClosePreview()
  if exists('b:preview_file') && bufwinnr(b:preview_file) >= 0
    call coffee_tools#SwitchWindow(b:preview_file)
    quit!
  endif
endfunction

function! coffee_tools#TogglePreview()
  if !exists('b:preview_file') || bufwinnr(b:preview_file) < 0
    call coffee_tools#OpenPreview()
  else
    call coffee_tools#ClosePreview()
  endif
endfunction

function! coffee_tools#InitPreview()
  let b:preview_file    = tempname().'.js'
  let b:preview_command = printf('coffee -p %s > %s 2>&1', shellescape(expand('%')), b:preview_file)

  autocmd BufWritePost <buffer>
        \ if bufwinnr(b:preview_file) >= 0    |
        \   call coffee_tools#UpdatePreview() |
        \ endif
endfunction

function! coffee_tools#UpdatePreview()
  if !exists('b:preview_file') || bufwinnr(b:preview_file) < 0
    return
  endif

  call system(b:preview_command)

  call coffee_tools#SwitchWindow(b:preview_file)
  let b:original_file = expand('#')
  silent edit!
  syntax on " workaround for weird lack of syntax
  normal! zR
  call coffee_tools#SwitchWindow(b:original_file)
endfunction

function! coffee_tools#SwitchWindow(bufname)
  let window = bufwinnr(a:bufname)
  exe window.'wincmd w'
endfunction

function! coffee_tools#OpenWrappingLineAbove(mode)
  if a:mode ==# 'v'
    let start = line("'<")
    let end   = line("'>")
  else
    let start = line('.')
    let end   = s:LowerIndentLimit(start)
  endif

  let indent = indent(start)

  call s:IncreaseIndent(start, end, 1)
  normal! O
  call s:SetIndent(line('.'), line('.'), indent)
  call feedkeys('A')

  undojoin
endfunction

function! coffee_tools#DeleteWrappingLine(mode)
  if a:mode ==# 'v'
    let start_line       = line("'<")
    let end_line         = line("'>")
    let new_current_line = nextnonblank(end_line + 1)

    if end_line == line('$')
      let indent = 0
    else
      let indent = indent(new_current_line) - indent(start_line)
    endif

    let amount = indent / &sw
    exe "'<,'>delete"
  else
    let amount = 1
    normal! dd
  endif

  let start = line('.')
  let end   = s:LowerIndentLimit(start)

  call s:DecreaseIndent(start, end, amount)
endfunction

function! coffee_tools#Paste(paste_key, register)
  let whitespace_pattern = '^\(\s*\).*$'
  let pasted_text        = getreg(a:register)
  let register_type      = getregtype(a:register)
  let local_whitespace   = substitute(getline('.'), whitespace_pattern, '\1', '')
  let pasted_whitespace  = substitute(pasted_text, whitespace_pattern, '\1', '')

  let formatted_lines = []
  for line in split(pasted_text, "\n")
    let line = substitute(line, '^'.pasted_whitespace, local_whitespace, '')
    call add(formatted_lines, line)
  endfor

  call setreg(a:register, join(formatted_lines, "\n"), register_type)
  exe 'normal! "'.a:register.a:paste_key
endfunction

function! coffee_tools#FunctionTextObject(type)
  let function_start = search('\((.\{-})\)\=\s*[-=]>$', 'Wbc')
  if function_start <= 0
    return
  endif

  let body_start = function_start + 1
  if body_start > line('$') || indent(nextnonblank(body_start)) <= indent(function_start)
    if a:type == 'a'
      normal! vg_
    endif

    return
  endif

  let indent_limit = s:LowerIndentLimit(body_start)

  if a:type == 'i'
    let start = body_start
  else
    let start = function_start
  endif

  call s:MarkVisual('v', start, indent_limit)
endfunction

function! coffee_tools#ToggleFunctionArrow()
  let line = getline('.')
  let double_arrow_pattern = '\s\zs=>\ze\%(\s\|$\)'
  let single_arrow_pattern = '\s\zs->\ze\%(\s\|$\)'

  let saved_cursor = getpos('.')

  if line =~ double_arrow_pattern
    exe 's/'.double_arrow_pattern.'/->/'
  elseif line =~ single_arrow_pattern
    exe 's/'.single_arrow_pattern.'/=>/'
  endif

  call setpos('.', saved_cursor)
endfunction

function! s:LowerIndentLimit(lineno)
  let base_indent  = indent(a:lineno)
  let current_line = a:lineno
  let next_line    = nextnonblank(current_line + 1)

  while current_line < line('$') && indent(next_line) >= base_indent
    let current_line = next_line
    let next_line    = nextnonblank(current_line + 1)
  endwhile

  return current_line
endfunction

function! s:UpperIndentLimit(lineno)
  let base_indent  = indent(a:lineno)
  let current_line = a:lineno
  let prev_line    = prevnonblank(current_line - 1)

  while current_line > 0 && indent(prev_line) >= base_indent
    let current_line = prev_line
    let prev_line    = prevnonblank(current_line - 1)
  endwhile

  return current_line
endfunction

function! s:MarkVisual(command, start_line, end_line)
  if a:start_line != line('.')
    exe a:start_line
  endif

  if a:end_line > a:start_line
    exe 'normal! '.a:command.(a:end_line - a:start_line).'jg_'
  else
    exe 'normal! '.a:command.'g_'
  endif
endfunction

function! s:SetIndent(from, to, indent)
  let saved_cursor = getpos('.')
  exe a:from.','.a:to.'s/^\s*/'.repeat(' ', a:indent)
  call setpos('.', saved_cursor)
endfunction

function! s:IncreaseIndent(from, to, amount)
  let saved_cursor = getpos('.')
  let command = repeat('>', a:amount)
  exe a:from.','.a:to.command
  call setpos('.', saved_cursor)
endfunction

function! s:DecreaseIndent(from, to, amount)
  let saved_cursor = getpos('.')
  let command = repeat('<', a:amount)
  exe a:from.','.a:to.command
  call setpos('.', saved_cursor)
endfunction
