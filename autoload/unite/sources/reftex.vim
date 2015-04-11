let s:save_cpo = &cpo
set cpo&vim

let s:HEADINGS = {
            \ 'chapter': 0,
            \ 'section': 1,
            \ 'subsection': 2,
            \ 'subsubsection': 3,
            \ }

let s:supported_label_type = ['figure', 'section', 'table']

let s:unite_source = {
            \ 'default_action': 'append',
            \ 'hooks': {},
            \ 'name': 'reftex',
            \ }


function! s:unite_source.complete(args, context, arglead, cmdline, cursorpos) "{{{
    return s:supported_label_type
endfunction "}}}

function! s:unite_source.gather_candidates(args, context) "{{{
    let label_type = a:context.source__label_type

    let candidates = []

    " init source__*
    let a:context.source__environment_stack = []
    let a:context.source__bufnr = bufnr('%')
    let a:context.source__path = expand(bufname(a:context.source__bufnr))
    let lines = getbufline(a:context.source__bufnr, 1, '$')
    let a:context.source__used_headings = unite#sources#reftex#collect_used_headings(lines)

    let a:context.source__heading_counts = {}
    for h in a:context.source__used_headings
        let key = string(unite#sources#reftex#get_heading_level(h))
        let a:context.source__heading_counts[key] = 0
    endfor

    " gather_candidates
    let linenr = 1
    for line in lines
        let cands = call('unite#sources#reftex#converter#' . label_type . '#convert', [linenr, line, a:context])
        if cands != []
            call extend(candidates, cands)
        endif
        let linenr += 1
    endfor

    return candidates
endfunction "}}}

function! s:unite_source.hooks.on_init(args, context) "{{{
    let options = filter(copy(a:args), "v:val != '!'")
    let label_type = get(options, 0, '')
    if label_type ==# ''
        let label_type = 'all'

    elseif index(s:supported_label_type, label_type) == -1
        let label_type = 'all'
    endif

    let a:context.source__label_type = label_type
endfunction "}}}

function! unite#sources#reftex#collect_used_headings(lines) "{{{
    let headings = []
    for h in keys(s:HEADINGS)
        let idx = match(a:lines, h)
        if idx != -1
            call add(headings, h)
        endif
    endfor
    return headings
endfunction "}}}

function! unite#sources#reftex#define() "{{{
    return s:unite_source
endfunction "}}}

function! unite#sources#reftex#get_heading_level(heading) "{{{
    return s:HEADINGS[a:heading]
endfunction "}}}

function! unite#sources#reftex#heading_counts2str(context) "{{{
    let counts = sort(map(copy(a:context.source__used_headings),
                \       'unite#sources#reftex#get_heading_level(v:val)'))
    let counts = map(counts, 'a:context.source__heading_counts[v:val]')
    let last_nonzero_idx = match(reverse(copy(counts)), '[^0]')
    return join(counts[:len(counts) - (last_nonzero_idx + 1)], '.')
endfunction "}}}

function! unite#sources#reftex#update_heading_counts(heading, context) "{{{
    let level = unite#sources#reftex#get_heading_level(a:heading)
    let a:context.source__heading_counts[string(level)] += 1

    let idxs = sort(map(copy(a:context.source__used_headings),
                \       'unite#sources#reftex#get_heading_level(v:val)'))

    for lvl in filter(idxs, 'v:val > level')
        if has_key(a:context.source__heading_counts, string(lvl))
            let a:context.source__heading_counts[string(lvl)] = 0
        endif
    endfor
endfunction "}}}

let &cpo = s:save_cpo
unlet s:save_cpo
" vim: expandtab:ts=4:sts=4:sw=4 foldmethod=marker
