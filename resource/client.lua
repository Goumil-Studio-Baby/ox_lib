--[[
    https://github.com/overextended/ox_lib

    This file is licensed under LGPL-3.0 or higher <https://www.gnu.org/licenses/lgpl-3.0.en.html>

    Copyright © 2025 Linden <https://github.com/thelindat>
]]

local _registerCommand = RegisterCommand

---@param commandName string
---@param callback fun(source, args, raw)
---@param restricted boolean?
function RegisterCommand(commandName, callback, restricted)
	_registerCommand(commandName, function(source, args, raw)
		if not restricted or lib.callback.await('ox_lib:checkPlayerAce', 100, ('command.%s'):format(commandName)) then
			callback(source, args, raw)
		end
	end)
end

-- Read a theme sub-key from KVP (stored as JSON under 'ox_theme')
local function getThemeKvp()
    local raw = GetResourceKvpString('ox_theme')
    if raw and raw ~= '' then
        local ok, data = pcall(json.decode, raw)
        if ok and type(data) == 'table' then
            return data
        end
    end
    return {}
end

RegisterNUICallback('getConfig', function(_, cb)
    local darkMode = GetResourceKvpInt('dark_mode') == 1

    if GetResourceKvpInt('dark_mode') == nil then
        local convarValue = GetConvar('ox:darkMode', '0')
        if convarValue == 'true' or convarValue == '1' or convarValue == 'yes' then
            darkMode = true
        elseif convarValue == 'false' or convarValue == '0' or convarValue == 'no' then
            darkMode = false
        else
            local numValue = tonumber(convarValue)
            darkMode = numValue and numValue ~= 0 or false
        end
    end

    local theme = getThemeKvp()
    local primaryColor = theme.primaryColor
    if not primaryColor or primaryColor == '' then
        primaryColor = GetConvar('ox:primaryColor', '#ec4899')
    end

    cb({
        primaryColor      = primaryColor,
        primaryShade      = GetConvarInt('ox:primaryShade', 8),
        darkMode          = darkMode,
        disableAnimations = GetResourceKvpInt('disable_animations') == 1,
        theme             = theme,
    })
end)

RegisterCommand('checkfocus', function()
    local currentFocus = IsNuiFocused()
    local currentKeepInput = IsNuiFocusKeepingInput()
    local oxLibHasFocus = lib._oxLibHasFocus or false
    print("=== NUI Focus Debug ===")
    print(string.format("IsNuiFocused: %s", tostring(currentFocus)))
    print(string.format("IsNuiFocusKeepingInput: %s", tostring(currentKeepInput)))
    print(string.format("ox_lib has focus flag: %s", tostring(oxLibHasFocus)))
    print("=====================")
end, false)
