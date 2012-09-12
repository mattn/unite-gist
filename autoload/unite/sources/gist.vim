let s:save_cpo = &cpo
set cpo&vim

function! s:format_gist(gist)
  let files = sort(keys(a:gist.files))
  if empty(files)
    return ""
  endif
  let file = a:gist.files[files[0]]
  if has_key(file, "content")
    let code = file.content
    let code = "\n".join(map(split(code, "\n"), '"  ".v:val'), "\n")
  else
    let code = ""
  endif
  return printf("%s %s%s", a:gist.id, type(a:gist.description)==0?"": a:gist.description, code)
endfunction

function! unite#sources#gist#define()
  return s:source
endfunction

let s:source = {
\  "name" : "gist",
\  "description" : "manipulate your gists",
\  "default_action" : "open",
\  "action_table" : {
\    "open" : {
\      "description" : "open with gist with vim",
\      "is_selectable" : 0,
\    },
\    "browser" : {
\      "description" : "open with browser",
\      "is_selectable" : 0,
\    },
\  }
\}

function! s:source.gather_candidates(args, context)
  let gists = gist#list("mine")
  if len(gists) == 0
    if !exists('g:github_user')
      let user = substitute(s:system('git config --get github.user'), "\n", '', '')
      if strlen(user) == 0
        let user = $GITHUB_USER
      end
    else
      let user = g:github_user
    endif
    let gists = gist#list(user)
  endif
  return map(gists, '{
        \ "abbr": s:format_gist(v:val),
        \ "word": v:val["id"],
        \ "action__config": v:val["id"],
        \ "action__gist": v:val["id"],
        \ }')
endfunction

function! s:source.action_table.open.func(candidate)
  exe "Gist" a:candidate.action__gist
endfunction

function! s:source.action_table.browser.func(candidate)
  let url = printf("https://gist.github.com/%s", a:candidate.action__gist)
  if has('win32')
    exe "!start rundll32 url.dll,FileProtocolHandler " . url
  elseif has('mac')
    call system("open '" . url . "' &")
  elseif executable('xdg-open')
    call system("xdg-open '" . url  . "' &")
  else
    call system("firefox '" . url . "' &")
  endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
