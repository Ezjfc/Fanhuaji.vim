" Fanhuaji.vim - Conversion between Chinese writing systems and styles via 繁化姬.
" Maintainer: EndermanbugZJFC <endermanbugzjfc@gmail.com>
" Version:    1.0
"
" Credits:
" zhcovert.org              - 小斐
" export_script_function()  - Tim Pope
" url_encode()              - Bhupesh Varshney
" json_decode()             - Mickael Daniel, Tim Pope
"
" Distributed under terms of the MIT license.
"
scriptencoding utf-8
if !has("multi_byte")
    call s:i18n({ 'en_GB': 'Fanhuaji.vim cannot operate as the "multi_byte" feature is disabled.
                \ You may run :version to see a list of enabled features.
                \ Please consider enabling "multi_byte" while recompiling Vim
                \ or use the online version: https://zhconvert.org/', 'zh_TW': "
                \
                \Fanhuaji.vim 無法運行，因為多位元組功能（ multi_byte ）已停用。
                \ 您可以執行 :version 來查看已啟用功能的清單。
                \ 請考慮重新編譯 Vim 時啟用多位元組功能
                \或使用線上繁化姬： https://zhconvert.org" })
    " TODO: test convert + Chinese simplified
    finish
endif

if !has("lua") && !executable("curl")
    call s:i18n({ 'en_GB': 'Fanhuaji.vim cannot operate as "curl" is missing on your system.
                \ If Neovim is available to you,
                \ please consider using it to run the Lua version of this plugin.
                \ Otherwise, please install "curl"
                \ or use the online Fanhuaji: https://zhconvert.org/', 'zh_TW': "
                \
                \Fanhuaji.vim 無法運行，因為您的系統缺少 curl 。
                \ 如果您能夠使用 Neovim ，請考慮使用它來運行該插件的 Lua 版本。
                \ 否則，請安裝 curl 或使用線上繁化姬： https://zhconvert.org/" })
    " TODO: test convert + Chinese simplified
    finish
endif

if exists("g:loaded_fanhuaji")
    finish
endif
let g:loaded_fanhuaji = 1

if !exists("g:fanhuaji_debug")
    let g:fanhuaji_debug = 0
endif

if !exists("g:fanhuaji_server")
    let g:fanhuaji_server = "https://api.zhconvert.org"
endif

if !exists("g:fanhuaji_key")
    let g:fanhuaji_key = "" " Reserved for forward compatibility.
endif

if !exists("g:fanhuaji_fallback_register")
    let g:fanhuaji_fallback_register = "f" " If the buffer changed during conversion.
endif

" export_script_function() allows script functions to be called externally, i.e. in Lua.
"
" https://github.com/tpope/vim-abolish/blob/dcbfe065297d31823561ba787f51056c147aa682/plugin/abolish.vim#L26-L28
function! s:export_script_function(name) abort
    return function(substitute(a:name,'^s:',matchstr(expand('<sfile>'), '.*\zs<SNR>\d\+_'),''))
endfunction

" url_encode() makes strings safe to be embebdded in a shell command.
"
" https://gist.github.com/atripes/15372281209daf5678cded1d410e6c16
function! s:url_encode(mystring) abort
    let urlsafe = ""
    for char in split(join(lines, "\n"), '.\zs')
        if matchend(char, '[-_.~a-zA-Z0-9]') >= 0
            let urlsafe = urlsafe . char
        else
            let decimal = char2nr(char)
            let urlsafe = urlsafe . "%" . printf("%02x", decimal)
        endif
    endfor
    return urlsafe
endfunction

" json_decode() turns JSON strings into dictionaries.
"
" https://github.com/vimlab/vim-json/blob/3792dbe83835579b8959448ca3f066f04a934688/autoload/JSON.vim
function! s:json_decode(string) abort
    let [null, false, true] = ['', 0, 1]
    let stripped = substitute(a:string,'\C"\(\\.\|[^"\\]\)*"','','g')
    if stripped !~# "[^,:{}\\[\\]0-9.\\-+Eaeflnr-u \n\r\t]"
        try
            return eval(substitute(a:string,"[\r\n]"," ",'g'))
        catch
        endtry
    endif
    call s:throw("invalid JSON: ".stripped)
endfunction


" Fanhuaji#ConvertVisualSelected() acts depending on whether user's Vim has the Lua feature enabled.
" If so, it invokes convert.lua with a fallback function.
" Otherwise, it calls curl().
"
function! Fanhuaji#ConvertVisualSelected(converter)
    " TODO: let data
    if has("lua")
        " TODO: warn if convert.lua doesn't exist.
        let callback = "err_no_curl"
        if executable("curl")
            let callback = "curl"
        endif
        let exported = s:export_script_function(callback)
        call luaeval('require("convert.lua").ConvertVisualSelected(a:converter, "' . exported . '")')
        return
    endif

    s:curl()
    " TODO: set data
endfunction

" err_no_curl() is used as a callback function passed to convert.lua
"
function! s:err_no_curl()
    call s:i18n({ 'en_GB': 'Fanhuaji.vim cannot operate as Lua HTTP failed
                \ while "curl" is missing on your system.
                \ Please consider installing "curl"
                \ or use the online Fanhuaji: https://zhconvert.org/', 'zh_TW': "
                \
                \Fanhuaji.vim 無法運行，因為 Lua HTTP 失效了，而您的系統上缺少 curl 。
                \ 請考慮安裝 curl 或使用線上繁化姬： https://zhconvert.org/" })
    " TODO: test convert + Chinese simplified
endfunction

" i18n() acts depending on whether user's Vim has the "multi_lang" feature enabled.
" If so, it displays the message corresponding to g:langmenu.
" Otherwise, it displays all languages together in which the order should be:
" en_GB -> zh_TW -> zh_CN
"
function! s:i18n(msgs)
    if has("multi_lang")
        echom get(a:msgs, &langmenu, a:msgs['en_GB'])
        return
    endif

    echom join(a:msgs, "\n\n")
endfunction

" curl() builds a HTTP request with the selected content in visual mode and
" returns the downloaded data as a dictionary.
"
" Example converter: "Taiwan"
"
function! s:curl(converter)
    let debug_flag = ""
    if g:fanhuaji_debug
        let debug_flag = "-v "
    endif

    let cmd = 'curl --header "Content-Type: application/json"
                \ --header "Accept: application/json"
                \ --get --data "converter=' . a:converter . '" '
    let cmd .= '--data "apiKey=' . g:fanhuaji_key . '" '
    let cmd .= '--data "text=' . s:url_encode(text) . '" '
    let cmd .= debug_flag . g:fanhuaji_server
    let raw = system(cmd)
    if g:fanhuaji_debug
        echom cmd
        echom raw
    endif

    return s:json_decode(raw)
endfunction
