" Fanhuaji.vim - Conversion between Chinese writing systems and styles via 繁化姬.
" Maintainer: EndermanbugZJFC <endermanbugzjfc@gmail.com>
" Version:    1.0
"
" Credits:
" export_script_function()  - Tim Pope
" zhcovert.org           - 小斐
" url_encode()           - Bhupesh Varshney
" get_visual_selection() - xolox, FocusedWolf
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

" TODO: Windows
" if !executable("PowerShell") && !executable("curl")
if !executable("curl")
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
    let g:fanhuaji_server = "https://api.zhconvert.org/convert"
endif

if !exists("g:fanhuaji_key")
    let g:fanhuaji_key = "" " Reserved for forward compatibility.
endif

if !exists("g:fanhuaji_fallback_register")
    " If the buffer changed during conversion.
    " @see Fanhuaji#AsyncConvertVisualSelected()
    "
    let g:fanhuaji_fallback_register = "f"
endif

if !exists("g:fanhuaji_highlight_when_convert")
    let g:fanhuaji_highlight_when_convert = 1
endif

let s:has_user_timeout = 1
if !exists("g:fanhuaji_timeout")
    let s:has_user_timeout = 0 " Configuration hint will be displayed for long requests.
    let g:fanhuaji_timeout = 60
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
function! s:url_encode(text) abort
    let urlsafe = ""
    for index in range(strcharlen(a:text))
        let char = strcharpart(a:text, index, 1)
        if matchend(char, '[-_.~a-zA-Z0-9]') >= 0
            let urlsafe = urlsafe . char
        else
            let decimal = char2nr(char)
            let urlsafe = urlsafe . "%" . printf("%02x", decimal)
        endif
    endfor
    return urlsafe
endfunction

" TODO: test under normal mode
function! s:get_visual_selection()
    let [line_start, column_start] = getpos("'<")[1:2]
    let [line_end, column_end] = getpos("'>")[1:2]
    let lines = getline(line_start, line_end)
    if len(lines) == 0
        return ''
    endif
    let lines[-1] = lines[-1][: column_end - (&selection == 'inclusive' ? 1 : 2)]
    let lines[0] = lines[0][column_start - 1:]
    return join(lines, "\n")
endfunction

function! Fanhuaji#AsyncConvertVisualSelected()
    " TODO
endfunction

" Fanhuaji#ConvertVisualSelected() acts depending on whether user's Vim has the Lua feature enabled.
" If so, it invokes convert.lua with a fallback function.
" Otherwise, it calls curl().
"
" Example converter: "Taiwan"
"
function! Fanhuaji#ConvertVisualSelected(converter)
    let text = s:get_visual_selection()

    " let last_search = "" " pending feature.
    if g:fanhuaji_highlight_when_convert == 1
        exe "/" . text
    endif

    if has("lua")
        " TODO: warn if convert.lua doesn't exist.
        let expression = 'pcall(require("convert.lua").ConvertVisualSelected(_A[1], _A[2]))'
        let result = luaeval(expression, converter, text)
        " TODO: error handle
        return
    endif

    let decoded = s:curl(converter, text)
    exe decoded["data"]["text"]
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

" invoke_web_request() builds and executes an HTTP request with Windows
" PowerShell Cmdlet Invoke-WebRequest and returns the downloaded data as a dictionary.
"
function! s:invoke_web_request(converter, text)
    " TODO
endfunction

" curl() builds and executes an HTTP request with cURL
" and returns the downloaded data as a dictionary.
"
function! s:curl(converter, text)
    let debug_flag = ""
    if g:fanhuaji_debug
        let debug_flag = "-v "
    endif

    let cmd = 'curl --header "Content-Type: application/json"
                \ --header "Accept: application/json"
                \ --get --data "converter=' . a:converter . '" '
    let cmd .= '--data "apiKey=' . g:fanhuaji_key . '" '
    let cmd .= '--data "text=' . s:url_encode(a:text) . '" '
    let cmd .= debug_flag . g:fanhuaji_server
    let raw = system(cmd)
    if g:fanhuaji_debug
        echom cmd
        echom raw
    endif

    return json_decode(raw)
endfunction
