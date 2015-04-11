let s:save_cpo = &cpo
set cpo&vim

function! unite#sources#reftex#converter#figure#convert(linenr, line, context) "{{{
    let commands = []
    call extend(commands, unite#sources#reftex#util#find_commands(a:line, a:context.source__used_headings))
    call extend(commands, unite#sources#reftex#util#find_commands(a:line, ['begin', 'end']))
    call extend(commands, unite#sources#reftex#util#find_commands(a:line, 'label'))

    let candidates = []
    " sort by index
    call unite#sources#reftex#util#sort_command_list(commands)

    for cmd in commands
        if cmd.name ==# 'begin'
            call add(a:context.source__environment_stack, cmd.content)

        elseif cmd.name ==# 'end'
            if !empty(a:context.source__environment_stack)
                call remove(a:context.source__environment_stack, -1)
            endif

        elseif cmd.name ==# 'label'
            if !empty(a:context.source__environment_stack)
                        \    && a:context.source__environment_stack[-1] ==# 'figure')
                call add(candidates, {
                            \ 'kind': 'jump_list',
                            \ 'source': 'reftex',
                            \ 'word': cmd.content,
                            \ 'action__line': a:linenr,
                            \ 'action__path': a:context.source__path,
                            \ 'action__text': '\ref{' . cmd.content . '}',
                            \ })
            endif

        " heading
        else
            call unite#sources#reftex#update_heading_counts(cmd.name, a:context)
            call add(candidates, {
                        \ 'is_dummy': 1,
                        \ 'kind': 'jump_list',
                        \ 'source': 'reftex',
                        \ 'word': unite#sources#reftex#heading_counts2str(a:context) . "  " . cmd.content,
                        \ 'action__line': a:linenr,
                        \ 'action__path': a:context.source__path,
                        \ })
        endif
    endfor
    return candidates
endfunction "}}}

let &cpo = s:save_cpo
unlet s:save_cpo
" vim: expandtab:ts=4:sts=4:sw=4 foldmethod=marker
