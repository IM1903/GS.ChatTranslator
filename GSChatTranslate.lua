local http = require "gamesense/http"
local inspect = require "gamesense/inspect"
local md5 = require "md5"

ui.new_label("LUA","A","What you wanna say")
local Speech = ui.new_textbox("LUA","A","text")
ui.new_label("LUA","A","What language should it be")
local LangType = ui.new_textbox("LUA","A","LangType")

-- forward declare this func
local ChatTranslate

local translate = ui.new_button("LUA","A","Say it",function()
    ChatTranslate()
end)

function ChatTranslate()

    --If translator can't recognize your language, manually input it below
    --This list can also be used to specify the target language
    --If your language doesn't in this list which means it is not supported
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
    ]]--

    local from = "auto"
    local LangTarget=ui.get(LangType)
    local Query=ui.get(Speech)

    --dev app ID
    local appid = "20200711000517176"

    --Random num
    local random = math.random()
    local salt = tostring(random):reverse():sub(1, 10)

    --dev API key
    local Pkey = "PQIzHcancHLCVSR6Z5UA"

    --how a sign group up
    local signRaw = (appid..Query..salt..Pkey)

    --generate sign
    local sign =md5.sumhexa(signRaw)

    --debug info
    --print("App ID : "..appid)
    --print("RAW text : "..Query)
    --print("Random code : "..salt)
    --print("API key : "..Pkey)
    --print("Pre MD5 32-bit lowercase : "..signRaw)
    --print("Sign : "..sign)
    
    local params = {
        q = Query,
        from = from,
        to = LangTarget,
        appid = appid,
        salt = salt,
        sign = sign
    }

    http.get("http://api.fanyi.baidu.com/api/trans/vip/translate", {params = params}, function(success, response)
        if not success or response.status ~= 200 then
            client.error("Network error.")
            print(response.status)
            return
        end

        --print("RAW data: ", response.body)
        --print("Parsed data: ", inspect(data))
        
        local data = json.parse(response.body)
        client.exec("say ",inspect(data.trans_result[1].dst))

  
    end)
end
