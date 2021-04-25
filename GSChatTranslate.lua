local http = require 'gamesense/http'
local inspect = require 'gamesense/inspect'
local md5 = require 'md5'

local function chat_print_ffi()
    -- code from Aviarita: print_to_hudchat.lua
    local ffi = require 'ffi'

    ffi.cdef [[
		typedef void***(__thiscall* FindHudElement_t)(void*, const char*);
		typedef void(__cdecl* ChatPrintf_t)(void*, int, int, const char*, ...);
	]]

    local signature_gHud = '\xB9\xCC\xCC\xCC\xCC\x88\x46\x09'
    local signature_FindElement = '\x55\x8B\xEC\x53\x8B\x5D\x08\x56\x57\x8B\xF9\x33\xF6\x39\x77\x28'

    local match = client.find_signature('client_panorama.dll', signature_gHud) or error('sig1 not found')
    local char_match = ffi.cast('char*', match) + 1
    local hud = ffi.cast('void**', char_match)[0] or error('hud is nil')

    match = client.find_signature('client_panorama.dll', signature_FindElement) or error('FindHudElement not found')
    local find_hud_element = ffi.cast('FindHudElement_t', match)
    local hudchat = find_hud_element(hud, 'CHudChat') or error('CHudChat not found')
    local chudchat_vtbl = hudchat[0] or error('CHudChat instance vtable is nil')
    local raw_print_to_chat = chudchat_vtbl[27]
    local print_to_chat = ffi.cast('ChatPrintf_t', raw_print_to_chat) --

    -- This list is use for specify the target language( or the source language )
    -- If translator cannot recognize your language, manually define it in line 94
    -- If your language doesn't in this list, which means it is not supported

    --[[
    Arabic: ara	    Bulgarian: bul
    Cantonese: yue  Chinese: zh / cht
    Czech: cs       Danish: dan
    Dutch: nl       English: en
    Finnish: fin    France: fra
    Estonian: est   German: de
    Greek: el	    Hungarian: hu
    Italian: it     Japanese: jp
    Korean: kor	    Polish:	pl
    Portuguese: pt	Romanian: rom
    Russian: ru     Slovenian: slo	
    Spanish:spa     Swedish: swe
    Thai:th         Vietnamese: vie
    ]]
    local function print(text)
        print_to_chat(hudchat, 0, 0, text)
    end

    return print
end

local print_to_chat = chat_print_ffi()

local TargetLang = ''
local TranslateStr = ''

client.set_event_callback(
    'string_cmd',
    function(cmd)
        repeat
            local cmd = cmd.text

            if not cmd:match('^say') then
                break
            end

            local msg = cmd:match('^say (.*)')
            if not msg then
                break
            end

            if cmd:sub(5, 9) == '!tsay' then
                if cmd:sub(13, 13) == ' ' then
                    TargetLang = cmd:sub(11, 12)
                    TranslateStr = cmd:sub(14, cmd.length)
                    ChatTranslate(TargetLang, TranslateStr)
                else
                    TargetLang = cmd:sub(11, 13)
                    TranslateStr = cmd:sub(15, cmd.length)
                    ChatTranslate(TargetLang, TranslateStr)
                end

                return true
            end
        until true
    end
)

function ChatTranslate(TargetLang, TranslateStr)
    local from = 'auto'

    -- dev app ID
    local appid = '20200711000517176'

    -- Random num
    local random = math.random()
    local salt = tostring(random):reverse():sub(1, 10)

    -- dev API key
    local Pkey = 'PQIzHcancHLCVSR6Z5UA'

    -- how a sign group up
    local signRaw = (appid .. TranslateStr .. salt .. Pkey)

    -- generate sign
    local sign = md5.sumhexa(signRaw)

    local params = {
        q = TranslateStr,
        from = from,
        to = TargetLang,
        appid = appid,
        salt = salt,
        sign = sign
    }

    http.post(
        'http://api.fanyi.baidu.com/api/trans/vip/translate',
        {
            params = params
        },
        function(success, response)
            if not success or response.status ~= 200 then
                client.error('Network error.')
                print(response.status)
                return
            end

            local data = json.parse(response.body)
            client.exec('say ', inspect(data.trans_result[1].dst))
        end
    )
end
