let s:save_cpo = &cpo
set cpo&vim

let s:PAIRS = [
            \ '{:}',
            \ ]

function! unite#sources#reftex#util#find_commands(line, cmd_pat) "{{{
    " cmd_pat is 'section', '\(sub\)\+section, 'label', ['begin', 'end'], and so on

    let line_length = strlen(a:line)
    let cmds = []

    if type(a:cmd_pat) == type([])
        let patterns = a:cmd_pat
    else
        let patterns = [a:cmd_pat]
    endif

    for pat in patterns
        let i = 0
        while i < line_length
            let idx = match(a:line, '\\\@<!\\' . pat, i)
            if idx == -1
                break
            endif

            let cmd_content_begin = match(a:line, '{', idx + strlen('\' . pat) - 1)
            " if command doesn't have '{' (e.g. \section$)
            if cmd_content_begin == -1
                break
            endif

            let cmd_content_end = unite#sources#reftex#util#find_closing(a:line, cmd_content_begin, '{')
            let content = a:line[cmd_content_begin + 1 : cmd_content_end - 1]

            call add(cmds, {
                        \ 'idx': idx,
                        \ 'name': pat,
                        \ 'content': content,
                        \})

            " update i
            let i = cmd_content_end + 1
        endwhile
    endfor
    return cmds
endfunction "}}}

function! unite#sources#reftex#util#find_closing(line, startcol, opening) "{{{
    let closing = ''
    for pair in s:PAIRS
        if stridx(pair, a:opening) != -1
            let closing = split(pair, ':')[1]
        endif
    endfor
    if closing ==# ''
        return 0
    endif

    let unmatch_count = 0
    let is_escaped = 0
    for idx in range(a:startcol, strlen(a:line))
        if is_escaped
            let is_escaped = 0
            continue
        elseif a:line[idx] ==# '\'
            is_escaped = 1
            continue
        elseif a:line[idx] ==# a:opening
            let unmatch_count += 1
            continue
        elseif a:line[idx] ==# closing
            if unmatch_count == 1
                return idx
            else
                let unmatch_count -= 1
                continue
            endif
        endif
    endfor
    return return 0
endfunction "}}}

function! unite#sources#reftex#util#sort_command_list(cmd_list) "{{{
    call sort(a:cmd_list, 's:command_list_sorter')
endfunction "}}}

function! s:command_list_sorter(l, r) "{{{
    return a:l.idx - a:r.idx
endfunc "}}}

let &cpo = s:save_cpo
unlet s:save_cpo
" vim: expandtab:ts=4:sts=4:sw=4 foldmethod=marker
