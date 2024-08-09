let s:fixture = utest#NewFixture()

function! s:fixture.TestCurl() abort
    let test_basic = s:curl("Taiwan", "U盤")["data"]["text"]
    call utest#ExpectEqual("隨身碟", test_basic)

    let test_multibyte = "
                \# Test cases for string library
                \
                \ # ASCII characters (1 byte)
                \ \"Hello, World!\"
                \ \"abcdefghijklmnopqrstuvwxyz\"
                \ \"ABCDEFGHIJKLMNOPQRSTUVWXYZ\"
                \ \"0123456789\"
                \ \"!@#$%^&*()_+-=[]{}\\|;:'\"<,>.?/\"
                \
                \ # Extended ASCII characters (1 byte)
                \ \"áéíóúñÑçÇ\"
                \ \"àèìòùÀÈÌÒÙ\"
                \ \"äëïöüÄËÏÖÜ\"
                \
                \ # Unicode characters (2-4 bytes)
                \ \"中文字符\"
                \ \"日本語の文字\"
                \ \"ᐃᓄᒃᑎᑐᓕᕆᓂᖅ\"
                \ \"𝐀𝐁𝐂𝐃𝐄𝐅𝐆𝐇𝐈𝐉𝐊𝐋𝐌𝐍𝐎𝐏𝐐𝐑𝐒𝐓𝐔𝐕𝐖𝐗𝐘𝐙\"
                \
                \# System control characters
                \\"\t\" # Tab
                \\"\n\" # Newline
                \\"\r\" # Carriage return
                \\"\f\" # Form feed
                \\"\v\" # Vertical tab"
    " TODO: assert.
endfunction
