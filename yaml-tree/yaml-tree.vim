" ============================================================================
" YAML Tree Viewer — with toggle (F5 opens & closes)
" ============================================================================

command! YamlTree call YAMLTreeToggle()
nnoremap <F5> :YamlTree<CR>

" --------------------------------------------------------------------------
" Toggle: open if missing, close if exists
" --------------------------------------------------------------------------
function! YAMLTreeToggle() abort
	" Prevent use outside YAML
	if &filetype !=# 'yaml'
    echo "Not a YAML file"
    return
	endif

	" If tree is open, close it
  if exists("g:yaml_tree_win") && win_gotoid(g:yaml_tree_win)
    " Tree window exists: close it
    execute "close"
    unlet g:yaml_tree_win
    return
  endif

  " Otherwise open new tree
  call YAMLTreeOpen()
endfunction


" --------------------------------------------------------------------------
" Open the tree panel
" --------------------------------------------------------------------------
function! YAMLTreeOpen() abort
  let g:yaml_tree_main_win = win_getid()
  let g:yaml_tree_main_buf = bufnr('%')

  let tree = YAMLTreeParse(g:yaml_tree_main_buf)

  topleft 30vsplit
  enew
  setlocal buftype=nofile bufhidden=wipe noswapfile
  setlocal filetype=yaml-tree

  let g:yaml_tree_win = win_getid()

  call YAMLTreeDraw(g:yaml_tree_win, tree)
endfunction


" --------------------------------------------------------------------------
" Parse top-level YAML keys
" --------------------------------------------------------------------------
function! YAMLTreeParse(buf) abort
  let lines = getbufline(a:buf, 1, '$')
  let root = []

  for idx in range(len(lines))
    let line = lines[idx]

    if line =~# '^\s*$'      | continue | endif
    if line =~# '^\s*#'      | continue | endif
    if line =~# '^\s*---'    | continue | endif
    if line =~# '^\s*\.\.\.' | continue | endif

    let norm = substitute(line, '\t', '    ', 'g')
    let indent = match(norm, '\S')

    if indent != 0
      continue
    endif

    let key = matchstr(norm, '\v^[[:space:]]*\zs[^:]+')
    if empty(key)
      continue
    endif

    call add(root, {
          \ 'key': key,
          \ 'line': idx + 1
          \ })
  endfor

  return root
endfunction


" --------------------------------------------------------------------------
" Render the tree panel
" --------------------------------------------------------------------------
function! YAMLTreeDraw(win, nodes) abort
  call win_execute(a:win, 'setlocal modifiable')
  call win_execute(a:win, ':%d')

  let buf = winbufnr(a:win)
  let lines = []
  let g:yaml_tree_index = []

  for node in a:nodes
    call add(lines, '• ' . node.key)
    call add(g:yaml_tree_index, node)
  endfor

  call setbufline(buf, 1, lines)
  call win_execute(a:win, 'setlocal nomodifiable')

  nnoremap <buffer> <CR> :call YAMLTreeJumpAndClose()<CR>
endfunction


" --------------------------------------------------------------------------
" Jump to YAML and close tree
" --------------------------------------------------------------------------
function! YAMLTreeJumpAndClose() abort
  let tree_lnum = line('.')
  let target = g:yaml_tree_index[tree_lnum - 1].line

  " Close tree
  if exists("g:yaml_tree_win")
    execute "close"
    unlet g:yaml_tree_win
  endif

  " Go to YAML
  call win_gotoid(g:yaml_tree_main_win)
  execute target
  normal! zz
endfunction

