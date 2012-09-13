" easybuffer.vim - plugin to quickly switch between buffers
" Maintainer: Dmitry "troydm" Geurkov <d.geurkov@gmail.com>
" Version: 0.1
" Description: easybuffer.vim is a simple plugin to quickly
" switch between buffers by just pressing keys 
" Last Change: 9 September, 2012
" License: Vim License (see :help license)
" Website: https://github.com/troydm/asyncfinder.vim
"
" See easybuffer.vim for help.  This can be accessed by doing:
" :help easybuffer

let s:save_cpo = &cpo
set cpo&vim

if !exists("g:easybuffer_chars")
    let g:easybuffer_chars = ['a','s','f','q','w','e','z','x','c','v']
endif

function! s:StrCenter(s,l)
    if len(a:s) > a:l
        return a:s
    else
        let i = (a:l - len(a:s))/2
        let s = repeat(' ',i).a:s.repeat(' ',i)
        if len(s) > a:l
            let s = s[: -(len(s)-a:l+1)]
        elseif a:l > len(s)
            let s .= repeat(' ',a:l-len(s))
        endif
        return s
endfunction

function! s:SelectBuf(bnr)
    if !(getbufvar('%','win') =~ ' edit')
        bwipeout!
    endif
    exe ''.a:bnr.'buffer'
endfunction

function! s:DelBuffer()
    if line('.') > 2
        let bnr = str2nr(split(getline('.'),'\s\+')[1])
        if bufexists(bnr)
            if !getbufvar(bnr, "&modified")
                exe ''.bnr.'bdelete'
                setlocal modifiable
                normal! dd
                setlocal nomodifiable
            else
                echo "buffer is modified"
            endif
        else
            echo "no such buffer"
        endif
    endif
endfunction

function! s:WipeoutBuffer()
    if line('.') > 2
        let bnr = str2nr(split(getline('.'),'\s\+')[1])
        if bufexists(bnr)
            exe ''.bnr.'bwipeout!'
            setlocal modifiable
            normal! dd
            setlocal nomodifiable
        else
            echo "no such buffer"
        endif
    endif
endfunction

function! s:GotoBuffer(bnr)
    if line('$') > 2
        for i in range(3,line('$'))
            let bnr = str2nr(split(getline(i),'\s\+')[1])
            if bnr == a:bnr
                exe 'normal! '.i.'G0^'
                break
            endif
        endfor
    endif
endfunction

function! s:ClearInput()
    call setbufvar('%','inputn','')
    call setbufvar('%','inputk','')
endfunction

function! s:EnterPressed()
    let input = getbufvar('%','inputn')
    let inputk = getbufvar('%','inputk')
    if !empty(inputk)
        let inputkl = tolower(inputk)
        let keydict = getbufvar('%','keydict')
        for k in keys(keydict)
            if k == inputkl
                if char2nr(inputk[len(inputk)-1]) == char2nr(inputkl[len(inputkl)-1])
                    call s:SelectBuf(keydict[k])
                else
                    let inputk = ''
                    call setbufvar('%','inputk',inputk)
                    call s:GotoBuffer(keydict[k])
                endif
                return
            endif
        endfor
        let inputk = ''
        call setbufvar('%','inputk',input)
    elseif !empty(input)
        let bnrlist = getbufvar('%','bnrlist')
        for bnr in bnrlist
            if (''.bnr) == input
                call s:SelectBuf(bnr)
                return
            endif
        endfor
        let input = ''
        call setbufvar('%','inputn',input)
    elseif line('.') > 2
        let bnr = str2nr(split(getline('.'),'\s\+')[1])
        call s:SelectBuf(bnr)
    endif
endfunction

function! s:KeyPressed(k)
    let input = getbufvar('%','inputk').a:k
    let inputl = tolower(input)
    let keydict = getbufvar('%','keydict')
    let matches = 0
    let matchedk = 0
    for k in keys(keydict)
        if match(k,inputl) != -1
            let matches += 1
            let matchedk = k
        endif
    endfor
    if matches == 1
        if char2nr(input[len(input)-1]) == char2nr(inputl[len(inputl)-1])
            call s:SelectBuf(keydict[matchedk])
        else
            let input = ''
            call setbufvar('%','inputk',input)
            call s:GotoBuffer(keydict[matchedk])
        endif
        return
    elseif matches == 0
        let input = ''
    endif
    if len(input) > 0
        echo 'select key: '.input
    endif
    call setbufvar('%','inputk',input)
endfunction

function! s:NumberPressed(n)
    let input = getbufvar('%','inputn').a:n
    let bnrlist = getbufvar('%','bnrlist')
    let matches = 0
    let matchedbnr = 0
    for bnr in bnrlist
        if match(''.bnr,input) != -1
            let matches += 1
            let matchedbnr = bnr
        endif
    endfor
    if matches == 1
        call s:SelectBuf(matchedbnr)
        return
    elseif matches == 0
        let input = ''
    endif
    if len(input) > 0
        echo 'select bufnr: '.input
    endif
    call setbufvar('%','inputn',input)
endfunction

function! s:ListBuffers(unlisted)
    call setline(1, 'easybuffer - buffer list (press key or bufnr to select the buffer, press d to delete or D to wipeout buffer)')
    call append(1,'<Key> <BufNr> <Mode>  <Filetype>  <BufName>')
    let bnrlist = filter(range(1,bufnr("$")), "bufexists(v:val)")
    if !a:unlisted
        let bnrlist = filter(bnrlist, "buflisted(v:val)")
    endif
    let keydict = {}
    call setbufvar('%','bnrlist',bnrlist)
    for bnr in bnrlist
        let key = ''
        let keyok = 0
        while !keyok 
            for k in g:easybuffer_chars
                if !has_key(keydict, key.k)
                    let key = key.k
                    let keyok = 1
                    break
                endif
            endfor
            if !keyok
                if len(key) == 0
                    let key = g:easybuffer_chars[0]
                else
                    let kb = key[len(key)-1]
                    let kn = 0
                    for k in g:easybuffer_chars
                        if kn
                            let key = keydict[:-2].k
                            let kn = 0
                            break
                        endif
                        if k == kb
                            let kn = 1
                        endif
                    endfor
                    if kn 
                        let key .= g:easybuffer_chars[0]
                    endif
                endif
            endif
        endwhile
        let keydict[key] = bnr
        let key = s:StrCenter(key,5)
        let bnrs = s:StrCenter(''.bnr,7)
        let mode = ''
        let bufmodified = getbufvar(bnr, "&mod")
        if !buflisted(bnr)
            let mode .= 'u'
        endif
        if bufwinnr('%') == bufwinnr(bnr)
            let mode .= '%'
        endif
        if bufnr('#') == bnr
            let mode .= '#'
        endif
        if winbufnr(bufwinnr(bnr)) == bnr
            let mode .= 'a'
        else
            let mode .= 'h'
        endif
        if !getbufvar(bnr, "&modifiable")
            let mode .= '-'
        endif
        if getbufvar(bnr, "&readonly")
            let mode .= '='
        endif
        if getbufvar(bnr, "&modified")
            let mode .= '+'
        endif
        let mode = s:StrCenter(mode,6)
        if len(bufname(bnr)) > 0
            let bname = expand('#'.bnr.':t').'  '.expand('#'.bnr.':p')
            let bufft = s:StrCenter(getbufvar(bnr,'&filetype'),10)
        else
            let bname = '[No Name]'
            let bufft = s:StrCenter('-',10)
        endif
        if bufft != 'easybuffer'
            call append(line('$'),key.' '.bnrs.' '.mode.'  '.bufft.'  '.bname)
        endif
    endfor
    call setbufvar('%','keydict',keydict)
endfunction

function! s:Refresh()
    setlocal modifiable
    silent! normal! ggdGG
    call s:ListBuffers(getbufvar('%','unlisted'))
    setlocal nomodifiable
endfunction

function! s:OpenEasyBuffer(bang,win)
    let winnr = bufwinnr('^easybuffer$')
    let unlisted = 0
    if a:bang == '!'
        let unlisted = 1
    endif
    if winnr < 0
        execute a:win . ' easybuffer'
        setlocal filetype=easybuffer buftype=nofile bufhidden=wipe nobuflisted noswapfile nowrap
        call setbufvar('%','win',a:win)
        call setbufvar('%','unlisted',unlisted)
        call s:ListBuffers(unlisted)
        setlocal nomodifiable
        nnoremap <buffer> <Esc> :echo '' \| call <SID>ClearInput()<CR>
        nnoremap <buffer> d :echo '' \| call <SID>DelBuffer()<CR>
        nnoremap <buffer> D :echo '' \| call <SID>WipeoutBuffer()<CR>
        nnoremap <buffer> R :echo '' \| call <SID>Refresh()<CR>
        nnoremap <buffer> <Enter> :echo '' \| call <SID>EnterPressed()<CR>
        for i in range(10)
            exe 'nnoremap <buffer> '.i." :echo '' \\| call <SID>NumberPressed(".i.")<CR>"
        endfor
        for k in g:easybuffer_chars
            exe 'nnoremap <buffer> '.k." :echo '' \\| call <SID>KeyPressed('".k."')<CR>"
            exe 'nnoremap <buffer> '.toupper(k)." :echo '' \\| call <SID>KeyPressed('".toupper(k)."')<CR>"
        endfor
    else
        exe 'keepjumps '.winnr . 'wincmd w'
        call setbufvar('%','win',a:win)
        call setbufvar('%','unlisted',unlisted)
        call s:Refresh()
    endif
endfunction

command! -bang EasyBuffer call <SID>OpenEasyBuffer('<bang>','keepalt keepjumps edit')
command! -bang EasyBufferHorizontal call <SID>OpenEasyBuffer('<bang>','keepalt keepjumps '.(&lines/2).'sp')
command! -bang EasyBufferHorizontalBelow call <SID>OpenEasyBuffer('<bang>','keepalt keepjumps belowright '.(&lines/2).'sp')
command! -bang EasyBufferVertical call <SID>OpenEasyBuffer('<bang>','keepalt keepjumps '.(&columns/2).'vs')
command! -bang EasyBufferVerticalRight call <SID>OpenEasyBuffer('<bang>','keepalt keepjumps belowright '.(&columns/2).'vs')

let &cpo = s:save_cpo
unlet s:save_cpo

