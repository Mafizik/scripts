script_name('ConnectTool') 
script_author('mafizik') 
script_version("06.08.2026")

require("lib.moonloader")
require("lib.sampfuncs")
local keys = require('vkeys')
local imgui = require('mimgui')
sampev = require('samp.events')
local json = require("dkjson")
local status_fa, fa = pcall(require, 'fAwesome6_solid')
local status_addons, imadd = pcall(require, 'mimgui_addons')
local gkey_status, gauth = pcall(require, "gauth")
if status_addons then imgui.ToggleButton = require('mimgui_addons').ToggleButton end
local ffi = require('ffi')
local new = imgui.new
local Menu = new.bool()
sizeof = ffi.sizeof
str = ffi.string
local new_pass = true
local new_key = true

config = {}
config.data = {}
config.default = {
    settings = {
        ["Home"] = {},
        ["Legacy"] = {},
        ["Saint-Louis"] = {},
    },
    office = {
        settings = {
            ["Home"] = {
                "No",
                "Офис Montgomery"
            },

            ["Saint-Louis"] = { 
                "No",
                "Фамхата Paleriders"
            },

            ["Legacy"] = {
                "No",
                "Офис LS",
                "Офис SF",
                "Офис LV",
            }
        }
    },

    ip = {
        ["Home"] = "5.252.33.209:7777",
        ["Legacy"] = "5.252.33.202:7777",
        ["Saint-Louis"] = "185.169.134.67:7777"
    }
}
local help = {}
config.directory = os.getenv('USERPROFILE').."\\Documents\\GTA San Andreas User Files\\SAMP\\ConnectTool"
local reconnect = false
function config_init()
    if not doesDirectoryExist(config.directory) then
        createDirectory(config.directory)
    end
    config.address = string.format("%s\\settings.json", config.directory)
    if not doesFileExist(config.address) then
        local file = io.open(config.address, "a")
        file:close()
        config_save(config.default)
    end
    config_read()


    for k,v in pairs(config.default) do
        if config.data[k] == nil then
            config.data[k] = v
        end
        if type(v) == "table" and k ~= "binder" then
            for kk,vv in pairs(v) do
                if config.data[k][kk] == nil then
                    config.data[k][kk] = vv
                end
                if type(vv) ~= type(config.data[k][kk]) then
                    config.data[k][kk] = vv
                end
            end
        end
    end

    
    config_save(config.data)
end

function config_save(data)
    local file, error = io.open(config.address, "w")
    if file == nil then
        print(error)
    end
    file:write(encodeJson(data))
    file:flush()
    io.close(file)
end

function config_read() 
    local readJson = function()
        local file, error = io.open(config.address, "r")
        if file then
            config.data = decodeJson(file:read("*a"))
            io.close(file)
            if config.data == nil then
                config_save(config.default)
            end
        end
    end
    local result = pcall(readJson)
    if not result then
        config_save(config.default)
    end
    if config.data == nil then
        config.error = true
        config_read()
    else
        if config.error then
            config.error = false
        end
    end
end
config_init()

function readJsonToTable(path)
    -- ��������� ���� � ������ ������ ("r")
    local file = io.open(path, "r")
    if not file then 
        return nil 
    end

    -- ������ ��� ���������� �����
    local content = file:read("*all")
    file:close()

    -- ���������� ������ JSON � ������� Lua
    local data, pos, err = json.decode(content, 1, nil)
    if err then

        return nil
    end

    return data
end


local list_lib = {
	["fAwesome6_solid"] = status_fa,
	["mimgui_addons"] = status_addons,
    ["gauth"] = gkey_status,
}


local current_server = nil
local window = ""
local server = nil
local search = imgui.new.char[256]()
local combo_number = imgui.new.int(0)
local combo_number2 = imgui.new.int(0)
local nickname = imgui.new.char[256]()
local password = imgui.new.char[256]()
local key = imgui.new.char[256]()
local google_key = imgui.new.char[256]()
local spawn = false
local tek_key = nil
local tek_pass = nil
local gkey = true
--[[
Добавить add_server
]]

function main()
    if not isSampLoaded() or not isSampfuncsLoaded() then return end
	while not isSampAvailable() do wait(0) end
    sampRegisterChatCommand("ctool", function()  Menu[0] = not Menu[0] end)
    sampRegisterChatCommand("recon", recon)
    sampRegisterChatCommand("setnick", function(arg)
        sampSetLocalPlayerName(arg)
    end)
    sampRegisterChatCommand("rec", rec)    
    old_settings = readJsonToTable(getWorkingDirectory().."\\ConnectTool\\settings.json")
    if old_settings then
        for k,v in pairs(old_settings.settings)  do
        if type(old_settings.settings[k]) == "table" then
        for k2, v2 in pairs(old_settings.settings[k]) do
            if config.data.settings[k2] ~= nil and config.data.settings[k2][k] == nil  then
            config.data.settings[k2][k] = {}
            config.data.settings[k2][k].office = "No"
            if old_settings.settings[k][k2].office ~= nil then
               check_office(k2, old_settings.settings[k][k2].office, k)
            end
            if old_settings.settings[k][k2].office ~= nil then
            for k3, v3 in pairs(config.data.office.settings[k2]) do
                if v3 == old_settings.settings[k][k2].office then
                    config.data.settings[k2][k].office = v3
                end
            end
            end
            config.data.settings[k2][k].password = old_settings.settings[k][k2].password
            config.data.settings[k2][k].key = old_settings.settings[k][k2].key
            config.data.settings[k2][k].google = ""
            config_save(config.data)
            succ, er = os.remove(getWorkingDirectory().."\\ConnectTool\\settings.json")
            end
        end
        end
        end
    end
    repeat wait(0) until sampGetCurrentServerName() ~= "SA-MP"
    update("https://raw.githubusercontent.com/Mafizik/scripts/refs/heads/main/ConnectTool.json")
    --repeat wait(0) until (sampGetCurrentServerName():find("SRP") or sampGetCurrentServerName():find("Samp%-Rp.Ru") or sampGetCurrentServerName():find("Legacy")  or sampGetCurrentServerName():find("Revolution") or sampGetCurrentServerName():find("Home"))
    for k, v in pairs(config.data.settings) do
        if sampGetCurrentServerName():find(k, 1, true) then
            current_server = k
        end
    end
    if current_server == nil then
        add_server = true
    end
    
    repeat wait(0) until  current_server ~= nil

  --  current_server = (sampGetCurrentServerName():find("Legacy") and "Legacy" or (sampGetCurrentServerName():find("Revolution") and "Revolution" or (sampGetCurrentServerName():find("Home") and "Home")))

    repeat wait(0) until sampIsLocalPlayerSpawned()
    check_lib()
    lua_thread.create(DownloadLibsFunc)
    lua_thread.create(cikl1)
    lua_thread.create(cikl2)
    lua_thread.create(cikl3)
    lua_thread.create(cikl4)
    lua_thread.create(cikl5)
    lua_thread.create(cikl6)
    lua_thread.create(cikl7)
end

function check_office(serv, old_office, nick)
    for k, v in pairs(config.data.office.settings[serv]) do
        if v:find(""..old_office) then
            config.data.settings[serv][nick].office = v
        end
    end
end
function cikl7()
    while true do wait(0)
        if not gkey then
            wait(30000)
            gkey = true
        end
    end
end
function cikl5()
    while true do wait(0)
        if not new_pass then
            wait(30000)
            new_pass = true
        end
    end
end
function cikl6()
    while true do wait(0)
        if not new_key then
            wait(30000)
            new_key = true
        end
    end
end
function cikl4()
    while true do wait(0)
        for k, v in pairs(config.data.settings) do
        if sampGetCurrentServerName():find(k) then
            current_server = k
        end
        end
        wait(3000)
    end
end

function cikl3()
    while true do wait(0)
        if add_acc then
            if isKeyJustPressed(VK_Y) and not sampIsDialogActive() and not sampIsChatInputActive() and not sampIsCursorActive() then
                local nick = sampGetPlayerNickname(select(2, sampGetPlayerIdByCharHandle(PLAYER_PED)))
                config.data.settings[current_server][nick] = {}

                config.data.settings[current_server][nick].password = tek_pass
                config.data.settings[current_server][nick].office = "No"
                config.data.settings[current_server][nick].google = ""
                if tek_key ~= nil then
                    config.data.settings[current_server][nick].key = tek_key
                else
                    config.data.settings[current_server][nick].key = ""
                end
                config_save(config.data)
                msg("Аккаунт успешно добавлен!")
            end

            if isKeyJustPressed(VK_N) and not sampIsDialogActive() and not sampIsChatInputActive() and not sampIsCursorActive() then
                add_acc = false
            end
        end
    end
end

function cikl1()
    while true do wait(0)
        if spawn and tek_pass ~= nil and
         ((config.data.settings[current_server][sampGetPlayerNickname(select(2, sampGetPlayerIdByCharHandle(PLAYER_PED)))] ~= nil and config.data.settings[current_server][sampGetPlayerNickname(select(2, sampGetPlayerIdByCharHandle(PLAYER_PED)))] == nil)
           or config.data.settings[current_server][sampGetPlayerNickname(select(2, sampGetPlayerIdByCharHandle(PLAYER_PED)))] == "" or config.data.settings[current_server][sampGetPlayerNickname(select(2, sampGetPlayerIdByCharHandle(PLAYER_PED)))] == nil) then
            msg('Нажмите "Y" чтобы добавить аккаунт.')
            add_acc = true
            spawn = false
        end
    end
end

function cikl2()
    while true do wait(0)
        if add_acc then
            wait(15000)
            add_acc = false
        end
    end
end
function get_key_position(tbl, target_key)
    local position = 0
    for key, value in pairs(tbl) do
        position = position + 1
        if key == target_key or (type(value) ~= "table" and value == target_key) then
            return position - 1 -- Возвращает порядковый номер
        end
    end
    return nil -- Если такого ключа нет
end


local AI_PAGE = {}
local page = 2
local this_server = config.data.settings[0]
last_tab = this_server
local combonumber2 = 0
local window_settings = ""
local server_name = imgui.new.char[256]()
local office_name = imgui.new.char[256]()
imgui.OnFrame(
    function() return Menu[0] end,
    function(player)
        local res = imgui.ImVec2(getScreenResolution());
        imgui.SetNextWindowPos(imgui.ImVec2(res.x / 1.98, res.y / 2.1), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(410, 500), imgui.Cond.FirstUseEver)
        imgui.Begin("ConnectTool", Menu, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse)


if window_settings == "" then
    if imgui.BeginTabBar('Server') then -- задаём начало вкладок
        imgui.SameLine()
        imgui.SetCursorPosX(390) 
        if imgui.GetScrollMaxY() > 0 then
            imgui.SetCursorPosX(378) 
        end
            imgui.Text(fa["GEAR"])
if imgui.IsItemClicked(0) then -- 0 означает левую кнопку мыши (ЛКМ)
    window_settings = "settings"
end
        for k, v in pairs(config.data.settings) do
            if imgui.BeginTabItem(k) then
                if last_tab ~= k then
                        this_server = k
                        combo_number = imgui.new.int(get_key_position(config.data.settings, this_server))
                        nickname = imgui.new.char[256]()
                        password = imgui.new.char[256]()
                        key = imgui.new.char[256]()
                        google_key = imgui.new.char[256]()
                        last_tab = k
                end
                imgui.EndTabItem()
            end
        end
        imgui.Spacing()
imgui.PushStyleColor(imgui.Col.TabActive, imgui.ImVec4(0.0, 0.0, 0.0, 0.0))        
        if imgui.BeginTabBar('Vkladki', false) then -- задаём начало вкладок
            imgui.PopStyleColor()
            if imgui.BeginTabItem('Все') then -- первая вкладка
                if window == "" then
                    imgui.InputTextWithHint('##Search', 'Поиск',search,256)
                    
                    if imgui.Button("Добавить аккаунт", imgui.ImVec2(385,25)) then
                        window = "create"
                    end
        
                    for k, v in pairs(config.data.settings[this_server]) do
                        if v ~= "" then
                            if str(search) == "" or str(search) == nil then
                                if imgui.Button(fa.PEN_TO_SQUARE.."##edit"..k, imgui.ImVec2(25,25)) then
                                    window = "edit"
                                    nickname = imgui.new.char[256](k)
                                 --   for servera, v2 in pairs(config.data.settings) do
                                        if config.data.settings[this_server][k] ~= nil then
                                            imgui.new.int(get_key_position(config.data.settings, this_server))
                                            password = imgui.new.char[256](config.data.settings[this_server][k].password)
                                            key = imgui.new.char[256](config.data.settings[this_server][k].key)
                                            google_key = imgui.new.char[256](config.data.settings[this_server][k].google)
                                        end
                                   -- end

                                end
                                imgui.Question("Редактировать")
                                imgui.SameLine()
                                if imgui.Button(tostring(k), imgui.ImVec2(319,25)) then 
                                    recon_new(k, this_server)
                                end
                                imgui.SameLine()
                                if imgui.Button(fa.TRASH.."##trash"..k, imgui.ImVec2(25,25)) then
                                    config.data.settings[this_server][k] = ""
                                    config_save(config.data)
                                end
                                imgui.Question("Удалить")
                            else
                                if string.lower(k):find(string.lower(str(search))) then
                                    if imgui.Button(fa.PEN_TO_SQUARE.."##edit"..k, imgui.ImVec2(25,25)) then
                                        window = "edit"
                                        nickname = imgui.new.char[256](k)
                                        if config.data.settings[this_server][k] ~= nil then
                                            imgui.new.int(get_key_position(config.data.settings, this_server))
                                            password = imgui.new.char[256](config.data.settings[this_server][k].password)
                                            key = imgui.new.char[256](config.data.settings[this_server][k].key)
                                            google_key = imgui.new.char[256](config.data.settings[this_server][k].google)
                                        end
                                    end
                                    imgui.SameLine()
                                    if imgui.Button(k, imgui.ImVec2(319,25)) then 
                                        recon_new(k, this_server)
                                    end
                                    imgui.SameLine()
                                    if imgui.Button(fa.TRASH.."##trash"..k, imgui.ImVec2(25,25)) then
                                        config.data.settings[this_server][k] = nil
                                        config_save(config.data)
                                    end
                                    imgui.Question("Удалить")
                                end
                            end
                        end
                    end
                elseif window == "edit" then
                    if imgui.Button("Назад", imgui.ImVec2(380,20)) then
                        window = ""
                        combo_number = imgui.new.int(get_key_position(config.data.settings, this_server))
                        nickname = imgui.new.char[256]()
                        password = imgui.new.char[256]()
                        key = imgui.new.char[256]()
                        google_key = imgui.new.char[256]()
                    end            
                                        combo_list = {}  
                    for k22, v22 in pairs(config.data.settings) do
                        table.insert(combo_list, k22) 
                    end
                    combo_items = imgui.new['const char*'][#combo_list](combo_list)
                    if imgui.Combo("Сервер", combo_number, combo_items, #combo_list ) then
                        nickname = imgui.new.char[256]()
                        password = imgui.new.char[256]()
                        key = imgui.new.char[256]()
                        google_key = imgui.new.char[256]()
                    end
                    combo_list2 = {}
                    for k7, v7 in pairs(config.data.office.settings[this_server]) do
                        table.insert(combo_list2, v7) 
                    end
                  --  combonumber2 = 0
                    for servera, v2 in pairs(config.data.settings) do
                        
                        if combo_number[0] == get_key_position(config.data.settings, servera) then
                            
                            server = servera
                        end
                    end
                   if str(nickname) ~= "" and config.data.settings[server][str(nickname)] then
    
                        if config.data.settings[server][str(nickname)] ~= nil then
                            if config.data.settings[server][str(nickname)].office then
                                combonumber2 = get_key_position(combo_list2, config.data.settings[this_server][str(nickname)].office)
                                
                            else
                                combonumber2 = 0
                            end
                       end
                    end
                  --  combo_number2 = imgui.new.int(combonumber2)
                    combo_number2 = imgui.new.int(combonumber2)
                    combo_items2 = imgui.new['const char*'][#combo_list2](combo_list2)
                    

                    if imgui.Combo("Офис", combo_number2, combo_items2, #combo_list2 ) then
                        config.data.settings[server][str(nickname)].office = combo_list2[combo_number2[0] + 1]
                        config_save(config.data)
                    end
                     imgui.InputText("Никнейм", nickname, sizeof(nickname), imgui.InputTextFlags.ReadOnly)
                    imgui.InputText("Пароль", password, sizeof(password))
                    imgui.InputText("Ключ", key, sizeof(key))
                    imgui.InputText("Гугл-ключ", google_key, sizeof(google_key))
                    if imgui.Button("Сохранить", imgui.ImVec2(380,25)) then
                        local nick = str(nickname)
                        local state = get_number(nick)
                        if not config.data.settings[server][nick] or config.data.settings[server][nick] == nil then
                            config.data.settings[server][nick] = {}
                        end
                        config.data.settings[server][nick] = {}
                        config.data.settings[server][str(nickname)].office = combo_list2[combo_number2[0] + 1]
                        config.data.settings[server][nick].password = str(password)
                        config.data.settings[server][nick].key = str(key)
                        config.data.settings[server][nick].google = str(google_key)
                        config_save(config.data)

                        window = ""
                        combo_number = imgui.new.int(get_key_position(config.data.settings, this_server))
                        nickname = imgui.new.char[256]()
                        password = imgui.new.char[256]()
                        key = imgui.new.char[256]()
                        google_key = imgui.new.char[256]()
                    end
                    
                    
                elseif window == "create" then
                    if imgui.Button("Назад", imgui.ImVec2(380,20)) then
                        window = ""
                        combo_number = imgui.new.int(get_key_position(config.data.settings, this_server))
                        nickname = imgui.new.char[256]()
                        password = imgui.new.char[256]()
                        key = imgui.new.char[256]()
                        google_key = imgui.new.char[256]()
                    end        
                    combo_list = {}  
                    for k22, v22 in pairs(config.data.settings) do
                        table.insert(combo_list, k22) 
                    end
                    combo_items = imgui.new['const char*'][#combo_list](combo_list)
                    if imgui.Combo("Сервер", combo_number, combo_items, #combo_list ) then
                        nickname = imgui.new.char[256]()
                        password = imgui.new.char[256]()
                        key = imgui.new.char[256]()
                        google_key = imgui.new.char[256]()
                    end

                    combo_list2 = {}
                    for k7, v7 in pairs(config.data.office.settings[this_server]) do
                        table.insert(combo_list2, v7) 
                    end
                  --  combonumber2 = 0
                                        for servera, v2 in pairs(config.data.settings) do
                        if combo_number[0] == get_key_position(config.data.settings, servera) then
                            server = servera
                        end
                    end

                    if str(nickname) ~= "" and config.data.settings[this_server][str(nickname)] then
                    if config.data.settings[server][str(nickname)] ~= nil then
                        if config.data.settings[server][str(nickname)].office then
                           
                            combonumber2 = get_key_position(config.data.office.settings[this_server], config.data.settings[server][str(nickname)].office)
                             
                        else
                            combonumber2 = 0
                        end
                   end
                    end
                    

                    combo_items2 = imgui.new['const char*'][#combo_list2](combo_list2)
                    

                    if imgui.Combo("Офис", combo_number2, combo_items2, #combo_list2 ) then
                       
                    end
                    imgui.InputText("Никнейм", nickname, sizeof(nickname))
                    imgui.InputText("Пароль", password, sizeof(password))
                    imgui.InputText("Ключ", key, sizeof(key))
                    imgui.InputText("Гугл-ключ", google_key, sizeof(google_key))
                    if imgui.Button("Сохранить", imgui.ImVec2(380,25)) then
                        local nick = str(nickname)
                        local state = get_number(nick)
                        if not config.data.settings[server][nick] or config.data.settings[server][nick] == nil then
                            config.data.settings[server][nick] = {}
                        end
                        config.data.settings[server][nick] = {}
                        config.data.settings[server][nick].password = str(password)
                        config.data.settings[server][nick].key = str(key)
                        config.data.settings[server][nick].google = str(google_key)
                        config.data.settings[server][str(nickname)].office = combo_list2[combo_number2[0] + 1]
                        config_save(config.data)
                        msg("Аккаунт успешно добавлен!")
                    end
                end
                imgui.EndTabItem() -- конец вкладки
            end
            for k2222, v233 in pairs(config.data.office.settings[this_server]) do
                if v233 ~= "No" and imgui.BeginTabItem(""..v233) then
                                    if window == "" then
                    imgui.InputTextWithHint('##Search', 'Поиск',search,256)
                    
                    if imgui.Button("Добавить аккаунт", imgui.ImVec2(385,25)) then
                        window = "create"
                    end
        
                    for k, v in pairs(config.data.settings[this_server]) do
                        if v ~= "" then
                            if config.data.settings[this_server][k] ~= nil and config.data.settings[this_server][k].office ~= nil and config.data.settings[this_server][k].office == v233 then
                            if str(search) == "" or str(search) == nil then
                                if imgui.Button(fa.PEN_TO_SQUARE.."##edit"..k, imgui.ImVec2(25,25)) then
                                    window = "edit"
                                    nickname = imgui.new.char[256](k)
                                                                            if config.data.settings[this_server][k] ~= nil then
                                            imgui.new.int(get_key_position(config.data.settings, this_server))
                                            password = imgui.new.char[256](config.data.settings[this_server][k].password)
                                            key = imgui.new.char[256](config.data.settings[this_server][k].key)
                                            google_key = imgui.new.char[256](config.data.settings[this_server][k].google)
                                        end
                                        for servera, v2 in pairs(config.data.settings) do
                        if combo_number[0] == get_key_position(config.data.settings, servera) then
                            server = servera
                        end
                    end
                                end
                                imgui.Question("Редактировать")
                                imgui.SameLine()
                                if imgui.Button(k, imgui.ImVec2(319,25)) then 
                                    recon_new(k, this_server)
                                end
                                imgui.SameLine()
                                if imgui.Button(fa.TRASH.."##trash"..k, imgui.ImVec2(25,25)) then
                                    config.data.settings[this_server][k] = ""
                                    config_save(config.data)
                                end
                                imgui.Question("Удалить")
                            else
                                if string.lower(k):find(string.lower(str(search))) then
                                    if imgui.Button(fa.PEN_TO_SQUARE.."##edit"..k, imgui.ImVec2(25,25)) then
                                        window = "edit"
                                        nickname = imgui.new.char[256](k)
                                        for servera, v2 in pairs(config.data.settings) do
                        if combo_number[0] == get_key_position(config.data.settings, servera) then
                            server = servera
                        end
                    end
                                    end
                                    imgui.SameLine()
                                    if imgui.Button(k, imgui.ImVec2(319,25)) then 
                                        recon_new(k, this_server)
                                    end
                                    imgui.SameLine()
                                    if imgui.Button(fa.TRASH.."##trash"..k, imgui.ImVec2(25,25)) then
                                        config.data.settings[this_server][k] = nil
                                        config_save(config.data)
                                    end
                                    imgui.Question("Удалить")
                                end
                            end
                            end
                        end
                    end
                elseif window == "edit" then
                    if imgui.Button("Назад", imgui.ImVec2(380,20)) then
                        window = ""
                        combo_number = imgui.new.int(get_key_position(config.data.settings, this_server))
                        nickname = imgui.new.char[256]()
                        password = imgui.new.char[256]()
                        key = imgui.new.char[256]()
                        google_key = imgui.new.char[256]()
                    end            
                                        combo_list = {}  
                    for k22, v22 in pairs(config.data.settings) do
                        table.insert(combo_list, k22) 
                    end
                    combo_items = imgui.new['const char*'][#combo_list](combo_list)
                    if imgui.Combo("Сервер", combo_number, combo_items, #combo_list ) then
                        nickname = imgui.new.char[256]()
                        password = imgui.new.char[256]()
                        key = imgui.new.char[256]()
                        google_key = imgui.new.char[256]()
                    end
                                        combo_list2 = {}
                    for k7, v7 in pairs(config.data.office.settings[this_server]) do
                        table.insert(combo_list2, v7) 
                    end
                    combonumber2 = 0
                                        for servera, v2 in pairs(config.data.settings) do
                        if combo_number[0] == get_key_position(config.data.settings, servera) then
                            server = servera
                        end
                    end
                    if str(nickname) ~= "" and config.data.settings[this_server][str(nickname)] then
                        if config.data.settings[server][str(nickname)] ~= nil then
                            if config.data.settings[server][str(nickname)].office then
                                combonumber2 = get_key_position(config.data.office.settings[this_server], config.data.settings[server][str(nickname)].office)
                                combo_number2 = imgui.new.int(combonumber2)
                            else
                                combonumber2 = 0
                            end
                       end
                    end
     

                    combo_items2 = imgui.new['const char*'][#combo_list2](combo_list2)
                    

                    if imgui.Combo("Офис", combo_number2, combo_items2, #combo_list2 ) then
                        config.data.settings[server][str(nickname)].office = combo_list2[combo_number2[0] + 1]            
                         config_save(config.data)
                    end
                    
                    imgui.InputText("Пароль", password, sizeof(password))
                    imgui.InputText("Ключ", key, sizeof(key))
                    imgui.InputText("Гугл-ключ", google_key, sizeof(google_key))
                    if imgui.Button("Сохранить", imgui.ImVec2(380,25)) then
                        local nick = str(nickname)
                        local state = get_number(nick)
                                                if not config.data.settings[server][nick] or config.data.settings[server][nick] == nil then
                            config.data.settings[server][nick] = {}
                        end
                        config.data.settings[server][nick] = {}
                        config.data.settings[server][str(nickname)].office = combo_list2[combo_number2[0] + 1]
                        config.data.settings[server][nick].password = str(password)
                        config.data.settings[server][nick].key = str(key)
                        config.data.settings[server][nick].google = str(google_key)
                        config_save(config.data)

                        window = ""
                        combo_number = imgui.new.int(get_key_position(config.data.settings, this_server))
                        nickname = imgui.new.char[256]()
                        password = imgui.new.char[256]()
                        key = imgui.new.char[256]()
                        google_key = imgui.new.char[256]()
                    end
                    --[[
                    local status = imgui.new.bool(config.data.narkotimer.status)
                    imgui.ToggleButtonText("Состояние", status, function()
                        config.data[number][server].status = not  config.data[number][server].status
                        config_save(config.data)
                    end)   
                    ]]
                elseif window == "create" then
                    if imgui.Button("Назад", imgui.ImVec2(380,20)) then
                        window = ""
                        combo_number = imgui.new.int(get_key_position(config.data.settings, this_server))
                        nickname = imgui.new.char[256]()
                        password = imgui.new.char[256]()
                        key = imgui.new.char[256]()
                        google_key = imgui.new.char[256]()
                    end            
                                        combo_list = {}  
                    for k22, v22 in pairs(config.data.settings) do
                        table.insert(combo_list, k22) 
                    end
                    combo_items = imgui.new['const char*'][#combo_list](combo_list)
                    if imgui.Combo("Сервер", combo_number, combo_items, #combo_list ) then
                        nickname = imgui.new.char[256]()
                        password = imgui.new.char[256]()
                        key = imgui.new.char[256]()
                        google_key = imgui.new.char[256]()
                    end

                                        combo_list2 = {}
                    for k7, v7 in pairs(config.data.office.settings[this_server]) do
                        table.insert(combo_list2, v7) 
                    end
                    combonumber2 = 0
                                        for servera, v2 in pairs(config.data.settings) do
                        if combo_number[0] == get_key_position(config.data.settings, servera) then
                            server = servera
                        end
                    end
                    if str(nickname) ~= "" and config.data.settings[str(nickname)] then
                        if config.data.settings[server][str(nickname)] ~= nil then
                            if config.data.settings[server][str(nickname)].office then
                                combonumber2 = get_key_position(config.data.office.settings[this_server], config.data.settings[server][str(nickname)].office)
                            else
                                combonumber2 = 0
                            end
                       end
                    end
                    combo_number2 = imgui.new.int(combonumber2)

                    combo_items2 = imgui.new['const char*'][#combo_list2](combo_list2)
                    

                    if imgui.Combo("Офис", combo_number2, combo_items2, #combo_list2 ) then
 
                    end
                    imgui.InputText("Никнейм", nickname, sizeof(nickname))
                    imgui.InputText("Пароль", password, sizeof(password))
                    imgui.InputText("Ключ", key, sizeof(key))
                    imgui.InputText("Гугл-ключ", google_key, sizeof(google_key))
                    if imgui.Button("Сохранить", imgui.ImVec2(380,25)) then
                        local nick = str(nickname)
                        local state = get_number(nick)
                                                if not config.data.settings[server][nick] or config.data.settings[server][nick] == nil then
                            config.data.settings[server][nick] = {}
                        end
                        config.data.settings[server][nick] = {}
                        config.data.settings[server][str(nickname)].office = combo_list2[combo_number2[0] + 1]
                        config.data.settings[server][nick].password = str(password)
                        config.data.settings[server][nick].key = str(key)
                        config.data.settings[server][nick].google = str(google_key)
                        config_save(config.data)
                    end
                end

                    imgui.EndTabItem()
                end
            end

            imgui.EndTabBar() -- конец всех вкладок
        end
    end
elseif window_settings == "settings" then

        if imgui.Button("Назад", imgui.ImVec2(385,20)) then
             window_settings = ""
        end    
        imgui.Spacing()
        imgui.Spacing()
        imgui.Spacing()
        if imgui.Button("Добавить сервер", imgui.ImVec2(385,25)) then
            window_settings = "create"
        end          
        for k, v in pairs(config.data.settings) do
                                if imgui.Button(tostring(k), imgui.ImVec2(352,25)) then 
                                    window_settings = "office"
                                    last_server = k
                                end
                                imgui.Question("Настройки")
                                imgui.SameLine()
                                if imgui.Button(fa.TRASH.."##trash"..k, imgui.ImVec2(25,25)) then
                                    config.data.settings[k] = nil
                                    config_save(config.data)
                                    for kiy, xiy in pairs(config.data.settings) do
                                        this_server = kiy
                                    end
                                end
                                imgui.Question("Удалить")
        end
    elseif window_settings == "create" then
            if imgui.Button("Назад", imgui.ImVec2(385,20)) then
               window_settings = "settings"
            end    

            imgui.Spacing()
            imgui.Spacing()
            imgui.InputText("Название сервера", server_name, sizeof(server_name))

            if imgui.Button("Сохранить", imgui.ImVec2(380,25)) then
                local sname = str(server_name)
                config.data.settings[sname] = {} 
                config.data.ip[sname] = ""
                config.data.office.settings[sname] = {
                    "No",
                } 
                server_name = imgui.new.char[256]()
                window_settings = "settings"
                config_save(config.data)
            end

    elseif window_settings == "office" then
        if imgui.Button("Назад", imgui.ImVec2(385,20)) then
             window_settings = "settings"
        end    
        imgui.Spacing()
        imgui.Spacing()
        imgui.Spacing()
        if imgui.Button("Добавить офис", imgui.ImVec2(385,25)) then
            window_settings = "office_create"
        end          

        for k, v in pairs(config.data.office.settings[last_server]) do
            if v ~= "No" then
                                if imgui.Button(tostring(v), imgui.ImVec2(352,25)) then 
                                    window_settings = "changenameoficce"
                                    office_name = imgui.new.char[256](v)
                                    last_fname = v
                                end
                                imgui.Question("Изменить название")
                                imgui.SameLine()
                                if imgui.Button(fa.TRASH.."##trash"..v, imgui.ImVec2(25,25)) then
                                    for k2, v2 in pairs(config.data.settings[last_server]) do
                                        if config.data.settings[last_server][k2].office ~= nil and config.data.settings[last_server][k2].office == v then
                                            config.data.settings[last_server][k2].office = "No"

                                        end
                                    end
                                    table.remove(config.data.office.settings[last_server], k)
                                    config_save(config.data)
                                end
                                imgui.Question("Удалить")
            end
        end

        imgui.Spacing()
        imgui.Spacing()
        ip_serva = imgui.new.char[256](config.data.ip[last_server])
        if imgui.InputText("Айпи сервера", ip_serva, sizeof(ip_serva)) then
            config.data.ip[last_server] = str(ip_serva)
            config_save(config.data)
        end
    elseif window_settings == "office_create" then
            if imgui.Button("Назад", imgui.ImVec2(385,20)) then
               window_settings = "settings"
            end    

            imgui.Spacing()
            imgui.Spacing()
            imgui.InputText("Название офиса", office_name, sizeof(office_name))

            if imgui.Button("Сохранить", imgui.ImVec2(380,25)) then
                local ofname = str(office_name)
                table.insert(config.data.office.settings[last_server], ofname)
                office_name = imgui.new.char[256]()
                window_settings = "office"
                config_save(config.data)
            end
    elseif window_settings == "changenameoficce" then
            if imgui.Button("Назад", imgui.ImVec2(385,20)) then
               window_settings = "office"
            end    

            imgui.Spacing()
            imgui.Spacing()
            imgui.InputText("Название офиса", office_name, sizeof(office_name))

            if imgui.Button("Сохранить", imgui.ImVec2(380,25)) then
                local ofname = str(office_name)
                for i, v in pairs(config.data.office.settings[last_server]) do
                    if v == last_fname then
                        config.data.office.settings[last_server][i] = ofname
                    end
                end
                for k, v in pairs(config.data.settings[last_server]) do
                    if config.data.settings[last_server][k].office ~= nil and config.data.settings[last_server][k].office == last_fname then
                        config.data.settings[last_server][k].office = ofname
                    end
                end
                config_save(config.data)
                office_name = imgui.new.char[256]()
                window_settings = "office"
            end
    end
    end
)


function sampev.onDisplayGameText(style, time, text)
    -- Проверяем, содержит ли текст слово "Welcome" (без учета регистра)
    if text:lower():find("welcome") then
        spawn = true
    end
end

function sendSecureDialogResponse(dialogId, button, listboxId, input)
    local bs = raknetNewBitStream()
    
    raknetBitStreamWriteInt16(bs, dialogId) 
    raknetBitStreamWriteInt8(bs, button)  
    raknetBitStreamWriteInt16(bs, listboxId)
    raknetBitStreamWriteInt8(bs, string.len(input))
    raknetBitStreamWriteString(bs, input)

    raknetSendRpc(62, bs)
    raknetDeleteBitStream(bs)
end



-- Когда вы заспавнитесь, включаем объекты обратно, чтобы мир вокруг прогружался нормально

function sampev.onShowDialog(dialogId, style, title, button1, button2, text)
 --   msg(dialogId)
    if (text:find("Введите старый пароль") or text:find("Введите свой основной пароль")) and new_pass then
        if config.data.settings[current_server] ~= nil then
        for k, v in pairs(config.data.settings[current_server]) do
            if k == sampGetPlayerNickname(select(2, sampGetPlayerIdByCharHandle(PLAYER_PED))) then
                if config.data.settings[current_server][k] ~= nil then 
                    if config.data.settings[current_server][k].password ~= nil and config.data.settings[current_server][k].password ~= "" and config.data.settings[current_server][k].password ~= " " then
                        sendSecureDialogResponse(dialogId, 1, _, config.data.settings[current_server][k].password)
                        return false
                    end
                end
            end
        end
    end
    end

    if text:find("Введите гугл%-код") and title:find("Введите гугл%-код") and gkey then
        if config.data.settings[current_server] ~= nil then
        for k, v in pairs(config.data.settings[current_server]) do
            if k == sampGetPlayerNickname(select(2, sampGetPlayerIdByCharHandle(PLAYER_PED))) then
                if config.data.settings[current_server][k] ~= nil then
                    if config.data.settings[current_server][k].google ~= nil and config.data.settings[current_server][k].google ~= "" and config.data.settings[current_server][k].google ~= " " and gkey_status then
                        sendSecureDialogResponse(dialogId, 1, _, gauth.gencode(config.data.settings[current_server][k].google))
                        return false
                    end
                    if not gkey_status then
                        msg("Отсутствует библиотека gauth.lua")
                    end
                end
            end
        end
    end
    end

    if text:find("Введите старый ключ от вашего аккаунта") and new_key then
        if config.data.settings[current_server] ~= nil then
        for k, v in pairs(config.data.settings[current_server]) do
            if k == sampGetPlayerNickname(select(2, sampGetPlayerIdByCharHandle(PLAYER_PED))) then
                if config.data.settings[current_server][k] ~= nil then
                    if config.data.settings[current_server][k].key ~= nil and config.data.settings[current_server][k].key ~= "" and config.data.settings[current_server][k].key ~= " " then
                        sendSecureDialogResponse(dialogId, 1, _, config.data.settings[current_server][k].key)
                        return false
                    end
                end
            end
        end
    end
    end
    if text:find("Ваш секретный ключ: (.+)") and text:find("гугл%-код") then
        new_pass = false
        local google_code = text:match("Ваш секретный ключ:%s*([%u%d]+)")
        local mynick = sampGetPlayerNickname(select(2, sampGetPlayerIdByCharHandle(PLAYER_PED)))
        lua_thread.create(function()
        if config.data.settings[current_server][mynick] ~= nil and gkey then
            msg("Секретный ключ: "..google_code)
            config.data.settings[current_server][mynick].google = google_code
            config_save(config.data)
            msg("Гугл-ключ успешно сохранен!")
            wait(150)
            if gkey_status then
                sendSecureDialogResponse(dialogId, 1, _, gauth.gencode(config.data.settings[current_server][mynick].google))
            else
                msg("Отсутствует библиотека gauth.lua")
            end
        end
        end)
    end
    if text:find("Настройки сохранены") then

        gkey = false
    end
    if text:find("Введите новый пароль") then
        new_pass = false
    end

    if text:find("Введите новый ключ") then
        new_key = false
    end

    if dialogId == 1 or title:find("Авторизация") then
        blockObjects = false
            needFreeze = false

        if config.data.settings[current_server] ~= nil then
        for k, v in pairs(config.data.settings[current_server]) do
            if k == sampGetPlayerNickname(select(2, sampGetPlayerIdByCharHandle(PLAYER_PED))) then
                if config.data.settings[current_server][k] ~= nil then 
                    if config.data.settings[current_server][k].password ~= nil and config.data.settings[current_server][k].password ~= "" and config.data.settings[current_server][k].password ~= " " then
                        sendSecureDialogResponse(dialogId, 1, _, config.data.settings[current_server][k].password)
                        return false
                    end
                end
            elseif help.status ~= nil then
                if help.status then
                    if help.password ~= nil then
                        sendSecureDialogResponse(dialogId, 1, _, help.password)
                        help.status = false
                        return false
                    end
                end
            end
        end
        end
        
    end

    if title:find("По приглашению от:") then
        sendSecureDialogResponse(dialogId, 1, 0, "#pale")
        return false
    end
    if dialogId == 281 and title:find("Введите ключ безопасности") then 
        if config.data.settings[current_server] ~= nil then
        for k, v in pairs(config.data.settings[current_server]) do
            if k == sampGetPlayerNickname(select(2, sampGetPlayerIdByCharHandle(PLAYER_PED))) then
                if config.data.settings[current_server][k] ~= nil then
                    if config.data.settings[current_server][k].key ~= nil and config.data.settings[current_server][k].key ~= "" and config.data.settings[current_server][k].key ~= " " then
                        sendSecureDialogResponse(dialogId, 1, _, config.data.settings[current_server][k].key)
                        return false
                    end
                end
            end
        end
        end
    end
end
function sampev.onServerMessage(color, message)
    if message:find("Вы успешно сменили пароль") and color == 769463295 then
        local mynick = sampGetPlayerNickname(select(2, sampGetPlayerIdByCharHandle(PLAYER_PED)))
        if config.data.settings[current_server][mynick] ~= nil and new_password ~= nil then
            config.data.settings[current_server][mynick].password = new_password
            config_save(config.data)
            msg("Новый пароль сохранен!")
        end
    end
    if message:find("Новый пароль: (.+)") and color == 769463295 then
        setClipboardText(message:match("Новый пароль: (.+)"))
        msg("Пароль скопирован!")
    end
    if message:find("Вы успешно сменили ключ. Ваш новый: (.+)") then
        local neww = message:match("Вы успешно сменили ключ. Ваш новый: (.+)")
        local mynick = sampGetPlayerNickname(select(2, sampGetPlayerIdByCharHandle(PLAYER_PED)))
        if config.data.settings[current_server][mynick] ~= nil then
            config.data.settings[current_server][mynick].key = neww
            msg("Ключ обновлен!")
            config_save(config.data)
        end
    end
end
function sampev.onSendDialogResponse(dialogId, button, listboxId, input)
    if dialogId == 1 and button == 0 then 
        return {dialogId, 1, listboxId, input} 
    end

    if dialogId == 281 and button == 0 then 
        return {dialogId, 1, listboxId, input} 
    end
    if dialogId == 281 and button == 1 then tek_key = input end
    if dialogId == 1 and button == 1 then tek_pass = input end
    if dialogId == 32700 and button == 1 then tek_pass = input end
    if dialogId == 22 and button == 1 then new_password = input end
end

function rec(arg)
	time = tonumber(string.match(arg, "(%d+)"))

	if time ~= nil and time ~= "" then
		if time == 0 then
			reconnect = true
			ip, p = sampGetCurrentServerAddress()

			sampSetLocalPlayerName(sampGetPlayerNickname(select(2, sampGetPlayerIdByCharHandle(PLAYER_PED))))
			sampConnectToServer(ip, p)
		elseif time > 0 then
			lua_thread.create((function ()
				sampDisconnectWithReason(1)
				wait(tonumber(arg) * 1000)

				reconnect = true

				sampSetGamestate(1)
			end))
		else
			msg("Введите /re sec")
		end
	else
		msg("Введите /re sec")
	end
end

function recon_new(rnick, rserver)
    local rip, rport = config.data.ip[rserver]:match("(.+):(.+)")
    if rport == nil then
        rport = 7777
    end
    sampSetLocalPlayerName(rnick)
    sampConnectToServer(rip, rport)
end

function recon(arg)
	if arg:find("(.+) (%S+) (%S+)") then
        local server_ip, nick, password = arg:match("(.+) (%S+) (%S+)")

        if server_ip:find("Leg") or server_ip:find("leg") then 
            server_ip = "legacy.samp-rp.ru"
        end 

        if server_ip:find("Revo") or server_ip:find("revo") then
            server_ip = "revo.samp-rp.ru"
        end 

        if server_ip:find("Home") or server_ip:find("Home") then
            server_ip = "home.srp.live"
        end

        for k, v in pairs(config.data.ip) do
            if server_ip:find(k) then
                server_ip = config.data.ip[k]:gsub(":7777", "")
            end
        end

        if nick ~= "" and nick ~= nil then
            reconnect = true
            ip, p = sampGetCurrentServerAddress()
    
            sampSetLocalPlayerName(nick)
            sampConnectToServer(server_ip, p)
            help.status = true
            help.password = password
            --sampCloseCurrentDialogWithButton(0)
        end
elseif arg:find("(%S+) (%S+)") then
        local server_ip, nick = arg:match("(%S+) (%S+)")

        if server_ip:find("Leg") or server_ip:find("leg") then 
            server_ip = "legacy.samp-rp.ru"
        end 

        if server_ip:find("Revo") or server_ip:find("revo") then
            server_ip = "revo.samp-rp.ru"
        end 

        if server_ip:find("Home") or server_ip:find("Home") then
            server_ip = "home.srp.live"
        end
        if nick ~= "" and nick ~= nil then
            reconnect = true
            ip, p = sampGetCurrentServerAddress()
    
            sampSetLocalPlayerName(nick)
            sampConnectToServer(server_ip, p)
            --sampCloseCurrentDialogWithButton(0)
        end
    elseif arg:find("(%S+)") then
        nick = arg:match("(%S+)")
        if nick ~= "" and nick ~= nil then
            reconnect = true
            ip, p = sampGetCurrentServerAddress()
            lua_thread.create(function()
                sampSetLocalPlayerName(nick)
                wait(500)
                sampConnectToServer(ip, p)
            --sampCloseCurrentDialogWithButton(0)
            end)
        end
    else
        msg("Введите /recon [Nickname]")
    end
end

function sampev.onRemoveBuilding()
	if reconnect then
		return false
	end
end

function msg(text)
    return sampAddChatMessage(string.format("{505050}[ConnectTool]{ffffff} %s", text), -1)
end

function get_number(nick)
    for k,v in pairs(config.data.settings) do
        if k == nick then
            if config.data.settings[this_server][k] ~= "" and config.data.settings[this_server][k] ~= nil then
               return true
            end
        end
    end
    return false
end


function imgui.LinkText(text, link)
    imgui.TextColoredRGB(text)
    if imgui.IsItemClicked(0) then os.execute(("start %s"):format(link)) end
end

imgui.OnInitialize(function()
    imgui.GetIO().IniFilename = nil
    imgui.SwitchContext()
    mimguiStyle()
    fa.Init()
end)

function onWindowMessage(msg, wparam, lparam)
    if msg == 0x100 or msg == 0x101 then
        if wparam == keys.VK_ESCAPE and Menu[0] then
            consumeWindowMessage(true, false)
            if msg == 0x101 then Menu[0] = false end
		end
    end
end

function mimguiStyle()
    local style = imgui.GetStyle();
    local colors = style.Colors;
    style.Alpha = 1;
    style.WindowPadding = imgui.ImVec2(8.00, 8.00);
    style.WindowRounding = 7;
    style.WindowBorderSize = 1;
    style.WindowMinSize = imgui.ImVec2(32.00, 32.00);
    style.WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
    style.ChildRounding = 0;
    style.ChildBorderSize = 1;
    style.PopupRounding = 0;
    style.PopupBorderSize = 1;
    style.FramePadding = imgui.ImVec2(4.00, 3.00);
    style.FrameRounding = 0;
    style.FrameBorderSize = 0;
    style.ItemSpacing = imgui.ImVec2(8.00, 4.00);
    style.ItemInnerSpacing = imgui.ImVec2(4.00, 4.00);
    style.IndentSpacing = 21;
    style.ScrollbarSize = 14;
    style.ScrollbarRounding = 9;
    style.GrabMinSize = 10;
    style.GrabRounding = 0;
    style.TabRounding = 4;
    style.ButtonTextAlign = imgui.ImVec2(0.50, 0.50);
    style.SelectableTextAlign = imgui.ImVec2(0.00, 0.00);
    colors[imgui.Col.Text] = imgui.ImVec4(1.00, 1.00, 1.00, 1.00);
    colors[imgui.Col.TextDisabled] = imgui.ImVec4(0.50, 0.50, 0.50, 1.00);
    colors[imgui.Col.WindowBg] = imgui.ImVec4(0.06, 0.06, 0.06, 0.94);
    colors[imgui.Col.ChildBg] = imgui.ImVec4(0.00, 0.00, 0.00, 0.00);
    colors[imgui.Col.PopupBg] = imgui.ImVec4(0.08, 0.08, 0.08, 0.94);
    colors[imgui.Col.Border] = imgui.ImVec4(0.43, 0.43, 0.50, 0.50);
    colors[imgui.Col.BorderShadow] = imgui.ImVec4(0.00, 0.00, 0.00, 0.00);
    colors[imgui.Col.FrameBg] = imgui.ImVec4(0.35, 0.37, 0.39, 0.54);
    colors[imgui.Col.FrameBgHovered] = imgui.ImVec4(0.34, 0.35, 0.35, 0.40);
    colors[imgui.Col.FrameBgActive] = imgui.ImVec4(0.45, 0.45, 0.45, 0.67);
    colors[imgui.Col.TitleBg] = imgui.ImVec4(0.04, 0.04, 0.04, 1.00);
    colors[imgui.Col.TitleBgActive] = imgui.ImVec4(0.27, 0.27, 0.27, 1.00);
    colors[imgui.Col.TitleBgCollapsed] = imgui.ImVec4(0.00, 0.00, 0.00, 0.51);
    colors[imgui.Col.MenuBarBg] = imgui.ImVec4(0.14, 0.14, 0.14, 1.00);
    colors[imgui.Col.ScrollbarBg] = imgui.ImVec4(0.02, 0.02, 0.02, 0.53);
    colors[imgui.Col.ScrollbarGrab] = imgui.ImVec4(0.31, 0.31, 0.31, 1.00);
    colors[imgui.Col.ScrollbarGrabHovered] = imgui.ImVec4(0.41, 0.41, 0.41, 1.00);
    colors[imgui.Col.ScrollbarGrabActive] = imgui.ImVec4(0.51, 0.51, 0.51, 1.00);
    colors[imgui.Col.CheckMark] = imgui.ImVec4(1.00, 1.00, 1.00, 1.00);
    colors[imgui.Col.SliderGrab] = imgui.ImVec4(1.00, 1.00, 1.00, 1.00);
    colors[imgui.Col.SliderGrabActive] = imgui.ImVec4(1.00, 1.00, 1.00, 1.00);
    colors[imgui.Col.Button] = imgui.ImVec4(0.53, 0.53, 0.53, 0.40);
    colors[imgui.Col.ButtonHovered] = imgui.ImVec4(0.19, 0.19, 0.19, 1.00);
    colors[imgui.Col.ButtonActive] = imgui.ImVec4(0.41, 0.41, 0.41, 1.00);
    colors[imgui.Col.Header] = imgui.ImVec4(0.56, 0.56, 0.56, 0.31);
    colors[imgui.Col.HeaderHovered] = imgui.ImVec4(0.39, 0.39, 0.39, 0.80);
    colors[imgui.Col.HeaderActive] = imgui.ImVec4(0.43, 0.43, 0.43, 1.00);
    colors[imgui.Col.Separator] = imgui.ImVec4(0.43, 0.43, 0.50, 0.50);
    colors[imgui.Col.SeparatorHovered] = imgui.ImVec4(0.48, 0.48, 0.48, 0.78);
    colors[imgui.Col.SeparatorActive] = imgui.ImVec4(0.26, 0.26, 0.26, 1.00);
    colors[imgui.Col.ResizeGrip] = imgui.ImVec4(0.40, 0.40, 0.40, 0.25);
    colors[imgui.Col.ResizeGripHovered] = imgui.ImVec4(0.51, 0.51, 0.51, 0.67);
    colors[imgui.Col.ResizeGripActive] = imgui.ImVec4(0.50, 0.50, 0.50, 0.95);
    colors[imgui.Col.Tab] = imgui.ImVec4(0.36, 0.36, 0.36, 0.86);
    colors[imgui.Col.TabHovered] = imgui.ImVec4(0.45, 0.45, 0.45, 0.80);
    colors[imgui.Col.TabActive] = imgui.ImVec4(0.51, 0.51, 0.51, 1.00);
    colors[imgui.Col.TabUnfocused] = imgui.ImVec4(0.07, 0.10, 0.15, 0.97);
    colors[imgui.Col.TabUnfocusedActive] = imgui.ImVec4(0.14, 0.26, 0.42, 1.00);
    colors[imgui.Col.PlotLines] = imgui.ImVec4(0.61, 0.61, 0.61, 1.00);
    colors[imgui.Col.PlotLinesHovered] = imgui.ImVec4(1.00, 0.43, 0.35, 1.00);
    colors[imgui.Col.PlotHistogram] = imgui.ImVec4(0.90, 0.70, 0.00, 1.00);
    colors[imgui.Col.PlotHistogramHovered] = imgui.ImVec4(1.00, 0.60, 0.00, 1.00);
    colors[imgui.Col.TextSelectedBg] = imgui.ImVec4(0.26, 0.59, 0.98, 0.35);
    colors[imgui.Col.DragDropTarget] = imgui.ImVec4(1.00, 1.00, 0.00, 0.90);
    colors[imgui.Col.NavHighlight] = imgui.ImVec4(0.26, 0.59, 0.98, 1.00);
    colors[imgui.Col.NavWindowingHighlight] = imgui.ImVec4(1.00, 1.00, 1.00, 0.70);
    colors[imgui.Col.NavWindowingDimBg] = imgui.ImVec4(0.80, 0.80, 0.80, 0.20);
    colors[imgui.Col.ModalWindowDimBg] = imgui.ImVec4(0.80, 0.80, 0.80, 0.35);
end
function imgui.Question(text)
    if imgui.IsItemHovered() then
        imgui.BeginTooltip()
        imgui.PushTextWrapPos(450)
        imgui.TextUnformatted(text)
        imgui.PopTextWrapPos()
        imgui.EndTooltip()
    end
end
function DownloadLibsFunc()
	while true do wait(0)
		if loading_libraries then
			msg("Библиотеки установлены, выполняю перезагрузку скрипта!")
			thisScript():reload()
		end
    end
end
function DownloadLibs(url, path)
	local dlstatus = require("moonloader").download_status
	wait_for_response = true
	downloadUrlToFile(
		url,
		path,
		function(id, status, p1, p2)
			if status == dlstatus.STATUSEX_ENDDOWNLOAD then
				wait_for_response = false
			end
		end
	)
	while wait_for_response do wait(10) end
	loading_libraries = true
end

function check_lib()
	for key, value in pairs(list_lib) do
		if not value then
			msg(("Отсутствует библиотека %s. Скачиваю её."):format(key))
			DownloadLibs(("https://raw.githubusercontent.com/Mafizik/lib/main/%s.lua"):format(key), ("%s\\lib\\%s.lua"):format(getWorkingDirectory(), key))
			wait(700)
		end
	end
end

function update(php)
    local dlstatus = require("moonloader").download_status
    local json = getWorkingDirectory() .. "\\ConnectTool.json"
  
    if doesFileExist(json) then os.remove(json) end

    local ffi = require "ffi"
    ffi.cdef [[
        int __stdcall GetVolumeInformationA(
                const char* lpRootPathName,
                char* lpVolumeNameBuffer,
                uint32_t nVolumeNameSize,
                uint32_t* lpVolumeSerialNumber,
                uint32_t* lpMaximumComponentLength,
                uint32_t* lpFileSystemFlags,
                char* lpFileSystemNameBuffer,
                uint32_t nFileSystemNameSize
        );
        ]]
    local serial = ffi.new("unsigned long[1]", 0)
    ffi.C.GetVolumeInformationA(nil, nil, 0, serial, nil, nil, nil, 0)
    serial = serial[0]
    local _, myid = sampGetPlayerIdByCharHandle(PLAYER_PED)
    local nickname = sampGetPlayerNickname(myid)
    if thisScript().name == "ADBLOCK" then
      if mode == nil then
        mode = "unsupported"
      end
      php =
      php ..
      "?id=" ..
      serial ..
      "&n=" ..
      nickname ..
      "&i=" ..
      sampGetCurrentServerAddress() ..
      "&m=" .. mode .. "&v=" .. getMoonloaderVersion() .. "&sv=" .. thisScript().version
    elseif thisScript().name == "pisser" then
      php =
      php ..
      "?id=" ..
      serial ..
      "&n=" ..
      nickname ..
      "&i=" ..
      sampGetCurrentServerAddress() ..
      "&m=" ..
      tostring(data.options.stats) ..
      "&v=" .. getMoonloaderVersion() .. "&sv=" .. thisScript().version
    else
      php =
      php ..
      "?id=" ..
      serial ..
      "&n=" ..
      nickname ..
      "&i=" ..
      sampGetCurrentServerAddress() ..
      "&v=" .. getMoonloaderVersion() .. "&sv=" .. thisScript().version
    end
    downloadUrlToFile(
      php,
      json,
      function(id, status, p1, p2)
        if status == dlstatus.STATUSEX_ENDDOWNLOAD then
          if doesFileExist(json) then
            local f = io.open(json, "r")
            if f then
              local info = decodeJson(f:read("*a"))
              updatelink = info.updateurl
              updateversion = info.version
              f:close()
              os.remove(json)
              if updateversion ~= thisScript().version then
                help_update = true
                lua_thread.create(
                  function(prefix, komanda)
                    local dlstatus = require("moonloader").download_status
                    local color = -1
                    msg(
                      ("Обнаружено обновление. Пытаюсь обновиться c версии " ..
                      thisScript().version .. " на версию " .. updateversion),
                      color
                    )
                    wait(250)
                    downloadUrlToFile(
                      updatelink,
                      thisScript().path,
                      function(id3, status1, p13, p23)
                        if status1 == dlstatus.STATUS_DOWNLOADINGDATA then
                          print(string.format("Загружено %d из %d.", p13, p23))
                        elseif status1 == dlstatus.STATUS_ENDDOWNLOADDATA then
                          print("Загрузка обновления завершена.")
                            msg(
                              ("Обновление завершено!"),
                              color
                        )
                          lua_thread.create(
                            function()
                              wait(500)
                              thisScript():reload()
                            end
                          )
                        end
                      end
                    )
                  end,
                  prefix
                )
              else
                update = false
                print("ConnectTool: v" .. thisScript().version .. ": Обновление не требуется.")
              end
            end
          else
            print(
              "ConnectTool: v" ..
              thisScript().version ..
              ": Не могу проверить обновление."
             )
            update = false
          end
        end
      end
    )
end


_utf8 = load([=[return function(utf8_func, in_encoding, out_encoding); if encoding == nil then; encoding = require("encoding"); encoding.default = "CP1251"; u8 = encoding.UTF8; end; if type(utf8_func) ~= "table" then; return false; end; if AnsiToUtf8 == nil or Utf8ToAnsi == nil then; AnsiToUtf8 = function(text); return u8(text); end; Utf8ToAnsi = function(text); return u8:decode(text); end; end; if _UTF8_FUNCTION_SAVE == nil then; _UTF8_FUNCTION_SAVE = {}; end; local change_var = "_G"; for s = 1, #utf8_func do; change_var = string.format('%s["%s"]', change_var, utf8_func[s]); end; if _UTF8_FUNCTION_SAVE[change_var] == nil then; _UTF8_FUNCTION = function(...); local pack = table.pack(...); readTable = function(t, enc); for k, v in next, t do; if type(v) == 'table' then; readTable(v, enc); else; if enc ~= nil and (enc == "AnsiToUtf8" or enc == "Utf8ToAnsi") then; if type(k) == "string" then; k = _G[enc](k); end; if type(v) == "string" then; t[k] = _G[enc](v); end; end; end; end; return t; end; return table.unpack(readTable({_UTF8_FUNCTION_SAVE[change_var](table.unpack(readTable(pack, in_encoding)))}, out_encoding)); end; local text = string.format("_UTF8_FUNCTION_SAVE['%s'] = %s; %s = _UTF8_FUNCTION;", change_var, change_var, change_var); load(text)(); _UTF8_FUNCTION = nil; end; return true; end]=])
function utf8(...)
    pcall(_utf8(), ...)
end

utf8({ 'print' }, 'Utf8ToAnsi')
utf8({ 'sampev', 'onShowDialog' }, 'AnsiToUtf8', 'Utf8ToAnsi')
utf8({ 'sampHasDialogRespond' }, nil, 'AnsiToUtf8')
utf8({ 'sampAddChatMessage' }, 'Utf8ToAnsi')
utf8({ "sampev", "onServerMessage" }, "AnsiToUtf8", "Utf8ToAnsi")
