-- Some users have locale set from ox_lib v2
if GetResourceKvpInt('reset_locale') ~= 1 then
    DeleteResourceKvp('locale')
    SetResourceKvpInt('reset_locale', 1)
end

---@generic T
---@param fn fun(key): unknown
---@param key string
---@param default? T
---@return T
local function safeGetKvp(fn, key, default)
    local ok, result = pcall(fn, key)
    if not ok then return DeleteResourceKvp(key) end
    return result or default
end

local function getDarkModeConvar()
    local v = GetConvar('ox:darkMode', '0')
    if v == 'true' or v == '1' or v == 'yes' then return 1 end
    if v == 'false' or v == '0' or v == 'no' then return 0 end
    local n = tonumber(v)
    return n and (n ~= 0 and 1 or 0) or 0
end

-- ─── Base settings (KVP) ──────────────────────────────────────────────────────
local settings = {
    default_locale       = GetConvar('ox:locale', 'en'),
    notification_position = safeGetKvp(GetResourceKvpString, 'notification_position', 'top-right'),
    notification_audio   = safeGetKvp(GetResourceKvpInt, 'notification_audio') == 1,
    dark_mode            = safeGetKvp(GetResourceKvpInt, 'dark_mode', getDarkModeConvar()) == 1,
    disable_animations   = safeGetKvp(GetResourceKvpInt, 'disable_animations') == 1,
}

local userLocales = GetConvarInt('ox:userLocales', 1) == 1
settings.locale = userLocales and safeGetKvp(GetResourceKvpString, 'locale') or settings.default_locale

-- ─── Theme store (JSON in KVP 'ox_theme') ────────────────────────────────────
local function getTheme()
    local raw = GetResourceKvpString('ox_theme')
    if raw and raw ~= '' then
        local ok, data = pcall(json.decode, raw)
        if ok and type(data) == 'table' then return data end
    end
    return {}
end

local function saveTheme(theme)
    SetResourceKvp('ox_theme', json.encode(theme))
end

-- ─── Color helpers ────────────────────────────────────────────────────────────
local function hexToRgba(hex, opacity)
    if not hex or hex == '' then return '' end
    hex = tostring(hex):gsub('#', '')
    if #hex ~= 6 then return '#' .. hex end
    local r = tonumber(hex:sub(1, 2), 16)
    local g = tonumber(hex:sub(3, 4), 16)
    local b = tonumber(hex:sub(5, 6), 16)
    if not r or not g or not b then return '#' .. hex end
    local a = math.max(0, math.min(100, tonumber(opacity) or 100))
    return ('rgba(%d, %d, %d, %.2f)'):format(r, g, b, a / 100)
end

local function rgbaToHex(rgba)
    if not rgba or rgba == '' then return '#141414' end
    if tostring(rgba):sub(1, 1) == '#' then return tostring(rgba) end
    local r, g, b = tostring(rgba):match('rgba?%((%d+),%s*(%d+),%s*(%d+)')
    if r then return ('#%02x%02x%02x'):format(tonumber(r), tonumber(g), tonumber(b)) end
    return '#141414'
end

local function rgbaToOpacity(rgba)
    if not rgba or rgba == '' then return 100 end
    if tostring(rgba):sub(1, 1) == '#' then return 100 end
    local a = tostring(rgba):match('rgba?%([^,]+,[^,]+,[^,]+,%s*([%d%.]+)')
    if not a then return 100 end
    return math.floor(tonumber(a) * 100 + 0.5)
end

-- ─── Generic KVP setter ──────────────────────────────────────────────────────
local function set(key, value)
    if settings[key] == value then return false end
    settings[key] = value
    local t = type(value)
    if t == 'nil' then         DeleteResourceKvp(key)
    elseif t == 'string' then  SetResourceKvp(key, value)
    elseif t == 'table' then   SetResourceKvp(key, json.encode(value))
    elseif t == 'number' then  SetResourceKvpInt(key, value)
    elseif t == 'boolean' then SetResourceKvpInt(key, value and 1 or 0)
    else return false end
    return true
end

-- ─── Broadcast updated config to NUI ─────────────────────────────────────────
local function refreshNUI()
    local theme = getTheme()
    local primaryColor = theme.primaryColor
    if not primaryColor or primaryColor == '' then
        primaryColor = GetConvar('ox:primaryColor', '#ec4899')
    end
    SendNUIMessage({
        action = 'refreshConfig',
        data   = {
            primaryColor      = primaryColor,
            primaryShade      = 6,
            darkMode          = settings.dark_mode,
            disableAnimations = settings.disable_animations,
            theme             = theme,
        }
    })
end

-- ─── Context menu: PRESETS ───────────────────────────────────────────────────
local PRESET_KEYS = { 'glass', 'solid', 'neon', 'compact' }
local PRESET_LABELS = {
    glass   = 'Glassmorphisme',
    solid   = 'Moderne Solide',
    neon    = 'Néon Épuré',
    compact = 'Compact Flat',
}

AddEventHandler('ox_lib_settings:openPresets', function()
    local currentTheme = getTheme()
    local current = currentTheme.activePreset or 'glass'

    local options = {}
    for _, k in ipairs(PRESET_KEYS) do
        table.insert(options, {
            title       = PRESET_LABELS[k],
            description = k == current and '✓ Preset actif' or '',
            event       = 'ox_lib_settings:applyPreset',
            args        = k,
        })
    end
    table.insert(options, {
        title = '← Retour',
        icon  = 'arrow-left',
        event = 'ox_lib_settings:openMain',
    })

    lib.registerContext({ id = 'ox_lib_presets', title = 'Presets de style', options = options })
    lib.showContext('ox_lib_presets')
end)

AddEventHandler('ox_lib_settings:applyPreset', function(preset)
    local t = getTheme()
    t.activePreset = preset
    -- Reset all overrides so preset defaults take effect
    local keys = {
        'primaryColor',
        'bgPrimary','bgSecondary','bgInput','borderColor',
        'borderRadius','shadowEnabled',
        'textPrimary','textSecondary',
        'itemBg','itemBgHover',
        'notifBg','notifBorder','notifTextTitle','notifTextBody',
        'progressColor','circleProgressColor','skillCheckColor',
        'circleProgressPosition',
        'animationStyle','animationSpeed',
    }
    for _, k in ipairs(keys) do t[k] = nil end
    saveTheme(t)
    refreshNUI()
    lib.notify({ title = 'Preset appliqué', description = PRESET_LABELS[preset], type = 'success', duration = 3000 })
    TriggerEvent('ox_lib_settings:openPresets')
end)

-- ─── Context menu: COULEURS — BOUTONS & ACCENTS ───────────────────────────────
AddEventHandler('ox_lib_settings:openColorsBoutons', function()
    local t = getTheme()
    local input = lib.inputDialog('Couleurs — Boutons & Accents', {
        {
            type        = 'color',
            label       = 'Couleur principale (boutons, accents)',
            description = 'Rose par défaut · choisir le hex de la couleur',
            default     = t.primaryColor or '#ec4899',
        },
        {
            type        = 'color',
            label       = 'Barre de progression',
            description = 'Vide (#000000) = utilise la couleur principale',
            default     = t.progressColor or '#000000',
        },
        {
            type        = 'color',
            label       = 'Cercle de progression',
            description = 'Vide (#000000) = utilise la couleur principale',
            default     = t.circleProgressColor or '#000000',
        },
        {
            type    = 'color',
            label   = 'Skill Check',
            default = t.skillCheckColor or '#ffffff',
        },
    })
    if not input then
        TriggerEvent('ox_lib_settings:openMain')
        return
    end
    local theme = getTheme()
    theme.primaryColor   = tostring(input[1])
    local progressHex    = tostring(input[2] or '')
    theme.progressColor  = (progressHex == '#000000' or progressHex == '') and '' or progressHex
    local circleHex      = tostring(input[3] or '')
    theme.circleProgressColor = (circleHex == '#000000' or circleHex == '') and '' or circleHex
    theme.skillCheckColor = tostring(input[4])
    saveTheme(theme)
    refreshNUI()
    lib.notify({ title = 'Boutons sauvegardés', type = 'success', duration = 2500 })
    TriggerEvent('ox_lib_settings:openMain')
end)

-- ─── Context menu: COULEURS — MENUS ──────────────────────────────────────────
AddEventHandler('ox_lib_settings:openColorsMenus', function()
    local t = getTheme()
    local input = lib.inputDialog('Couleurs — Menus', {
        {
            type    = 'color',
            label   = 'Fond menu (couleur)',
            default = rgbaToHex(t.bgPrimary or 'rgba(20,20,20,0.82)'),
        },
        {
            type    = 'slider',
            label   = 'Fond menu (opacité %)',
            default = rgbaToOpacity(t.bgPrimary or 'rgba(20,20,20,0.82)'),
            min = 0, max = 100, step = 5,
        },
        {
            type    = 'color',
            label   = 'Fond secondaire (couleur)',
            default = rgbaToHex(t.bgSecondary or 'rgba(30,30,30,0.72)'),
        },
        {
            type    = 'slider',
            label   = 'Fond secondaire (opacité %)',
            default = rgbaToOpacity(t.bgSecondary or 'rgba(30,30,30,0.72)'),
            min = 0, max = 100, step = 5,
        },
        {
            type    = 'color',
            label   = 'Fond des inputs',
            default = rgbaToHex(t.bgInput or 'rgba(255,255,255,0.05)'),
        },
        {
            type    = 'color',
            label   = 'Bordure (couleur)',
            default = rgbaToHex(t.borderColor or 'rgba(255,255,255,0.12)'),
        },
        {
            type    = 'slider',
            label   = 'Bordure (opacité %)',
            default = rgbaToOpacity(t.borderColor or 'rgba(255,255,255,0.12)'),
            min = 0, max = 100, step = 5,
        },
        {
            type    = 'color',
            label   = 'Texte principal',
            default = t.textPrimary or '#ffffff',
        },
        {
            type    = 'color',
            label   = 'Texte secondaire',
            default = t.textSecondary or '#a3a3a3',
        },
        {
            type        = 'color',
            label       = 'Item normal (fond)',
            description = 'Fond des boutons du menu au repos',
            default     = rgbaToHex(t.itemBg or 'rgba(0,0,0,0.32)'),
        },
        {
            type        = 'color',
            label       = 'Item survol (fond)',
            description = 'Fond des boutons au survol / sélection',
            default     = rgbaToHex(t.itemBgHover or 'rgba(255,255,255,0.10)'),
        },
    })
    if not input then
        TriggerEvent('ox_lib_settings:openMain')
        return
    end
    local theme = getTheme()
    theme.bgPrimary    = hexToRgba(input[1], input[2])
    theme.bgSecondary  = hexToRgba(input[3], input[4])
    theme.bgInput      = tostring(input[5])
    theme.borderColor  = hexToRgba(input[6], input[7])
    theme.textPrimary  = tostring(input[8])
    theme.textSecondary = tostring(input[9])
    theme.itemBg       = tostring(input[10])
    theme.itemBgHover  = tostring(input[11])
    saveTheme(theme)
    refreshNUI()
    lib.notify({ title = 'Menus sauvegardés', type = 'success', duration = 2500 })
    TriggerEvent('ox_lib_settings:openMain')
end)

-- ─── Context menu: COULEURS — NOTIFICATIONS ──────────────────────────────────
AddEventHandler('ox_lib_settings:openColorsNotifs', function()
    local t = getTheme()
    -- Defaults fall back to menu values
    local defBg     = t.notifBg     ~= '' and t.notifBg     or t.bgPrimary   or 'rgba(20,20,20,0.82)'
    local defBorder = t.notifBorder ~= '' and t.notifBorder or t.borderColor or 'rgba(255,255,255,0.12)'
    local defTitle  = t.notifTextTitle ~= '' and t.notifTextTitle or t.textPrimary  or '#ffffff'
    local defBody   = t.notifTextBody  ~= '' and t.notifTextBody  or t.textSecondary or '#a3a3a3'
    local input = lib.inputDialog('Couleurs — Notifications', {
        {
            type    = 'color',
            label   = 'Fond notification (couleur)',
            default = rgbaToHex(defBg),
        },
        {
            type    = 'slider',
            label   = 'Fond notification (opacité %)',
            default = rgbaToOpacity(defBg),
            min = 0, max = 100, step = 5,
        },
        {
            type    = 'color',
            label   = 'Bordure notification',
            default = rgbaToHex(defBorder),
        },
        {
            type    = 'slider',
            label   = 'Bordure (opacité %)',
            default = rgbaToOpacity(defBorder),
            min = 0, max = 100, step = 5,
        },
        {
            type    = 'color',
            label   = 'Texte titre',
            default = defTitle,
        },
        {
            type    = 'color',
            label   = 'Texte corps',
            default = defBody,
        },
    })
    if not input then
        TriggerEvent('ox_lib_settings:openMain')
        return
    end
    local theme = getTheme()
    theme.notifBg        = hexToRgba(input[1], input[2])
    theme.notifBorder    = hexToRgba(input[3], input[4])
    theme.notifTextTitle = tostring(input[5])
    theme.notifTextBody  = tostring(input[6])
    saveTheme(theme)
    refreshNUI()
    lib.notify({ title = 'Notifications sauvegardées', type = 'success', duration = 2500 })
    TriggerEvent('ox_lib_settings:openMain')
end)

-- ─── Context menu: FORMES & EFFETS ───────────────────────────────────────────
AddEventHandler('ox_lib_settings:openShapes', function()
    local t = getTheme()
    local input = lib.inputDialog('Formes & Effets', {
        {
            type    = 'slider',
            label   = 'Coins arrondis (px)',
            description = '0 = angles droits · 24 = très arrondi',
            default = t.borderRadius or 12,
            min = 0, max = 24, step = 1,
        },
        {
            type    = 'checkbox',
            label   = 'Activer les ombres portées',
            checked = t.shadowEnabled ~= false,
        },
    })
    if not input then
        TriggerEvent('ox_lib_settings:openMain')
        return
    end
    local theme = getTheme()
    theme.borderRadius  = input[1]
    theme.shadowEnabled = input[2]
    saveTheme(theme)
    refreshNUI()
    lib.notify({ title = 'Formes sauvegardées', type = 'success', duration = 2500 })
    TriggerEvent('ox_lib_settings:openMain')
end)

-- ─── Context menu: POSITIONS ─────────────────────────────────────────────────
AddEventHandler('ox_lib_settings:openPositions', function()
    local t = getTheme()
    local input = lib.inputDialog('Positions (prioritaires sur les scripts)', {
        {
            type    = 'select',
            label   = 'Notifications',
            icon    = 'bell',
            default = t.notificationPosition or 'top-right',
            options = {
                { label = 'Haut droite',   value = 'top-right'    },
                { label = 'Haut centre',   value = 'top-center'   },
                { label = 'Haut gauche',   value = 'top-left'     },
                { label = 'Centre droite', value = 'center-right' },
                { label = 'Centre gauche', value = 'center-left'  },
                { label = 'Bas droite',    value = 'bottom-right' },
                { label = 'Bas centre',    value = 'bottom-center'},
                { label = 'Bas gauche',    value = 'bottom-left'  },
            },
        },
        {
            type    = 'select',
            label   = 'Barre de progression',
            icon    = 'bars-progress',
            default = t.progressPosition or 'bottom',
            options = {
                { label = 'Bas',    value = 'bottom' },
                { label = 'Centre', value = 'center' },
                { label = 'Haut',   value = 'top'    },
            },
        },
        {
            type    = 'select',
            label   = 'Cercle de progression',
            icon    = 'circle-notch',
            default = t.circleProgressPosition or 'bottom',
            options = {
                { label = 'Centre (défaut)', value = 'middle' },
                { label = 'Bas',             value = 'bottom' },
            },
        },
        {
            type    = 'select',
            label   = 'TextUI (auto = suit le script)',
            icon    = 'message',
            default = t.textUiPosition or 'auto',
            options = {
                { label = 'Auto (suit le script)', value = 'auto'          },
                { label = 'Droite centre',         value = 'right-center'  },
                { label = 'Gauche centre',         value = 'left-center'   },
                { label = 'Haut centre',           value = 'top-center'    },
                { label = 'Bas centre',            value = 'bottom-center' },
                { label = 'Centre',                value = 'center'        },
            },
        },
    })
    if not input then
        TriggerEvent('ox_lib_settings:openMain')
        return
    end
    local theme = getTheme()
    theme.notificationPosition  = tostring(input[1])
    theme.progressPosition      = tostring(input[2])
    theme.circleProgressPosition = tostring(input[3])
    theme.textUiPosition        = tostring(input[4])
    saveTheme(theme)
    set('notification_position', tostring(input[1]))
    refreshNUI()
    lib.notify({ title = 'Positions sauvegardées', type = 'success', duration = 2500 })
    TriggerEvent('ox_lib_settings:openMain')
end)

-- ─── Context menu: OPTIONS GÉNÉRALES ────────────────────────────────────────
AddEventHandler('ox_lib_settings:openOptions', function()
    local inputSettings = {
        {
            type    = 'checkbox',
            label   = locale('ui.settings.notification_audio'),
            checked = settings.notification_audio,
        },
        {
            type        = 'checkbox',
            label       = 'Dark Mode',
            description = 'Active le mode sombre pour tous les composants ox_lib',
            checked     = settings.dark_mode,
        },
    }

    if userLocales then
        table.insert(inputSettings, {
            type        = 'select',
            label       = locale('ui.settings.locale'),
            searchable  = true,
            description = locale('ui.settings.locale_description', settings.locale),
            options     = GlobalState['ox_lib:locales'],
            default     = settings.locale,
            required    = true,
            icon        = 'book',
        })
    end

    local input = lib.inputDialog('Options générales', inputSettings)
    if not input then
        TriggerEvent('ox_lib_settings:openMain')
        return
    end

    local notification_audio, dark_mode = input[1], input[2]
    if userLocales and set('locale', tostring(input[3] or '')) then lib.setLocale(tostring(input[3])) end

    set('notification_audio', notification_audio)
    set('dark_mode', dark_mode)
    refreshNUI()
    TriggerEvent('ox_lib_settings:openMain')
end)

-- ─── Reset notifications only ────────────────────────────────────────────────
AddEventHandler('ox_lib_settings:resetNotifs', function()
    local theme = getTheme()
    theme.notifBg        = nil
    theme.notifBorder    = nil
    theme.notifTextTitle = nil
    theme.notifTextBody  = nil
    saveTheme(theme)
    refreshNUI()
    lib.notify({ title = 'Notifications réinitialisées', description = 'Les couleurs héritent maintenant des menus.', type = 'success', duration = 3000 })
    TriggerEvent('ox_lib_settings:openMain')
end)

-- ─── Reset to defaults ───────────────────────────────────────────────────────
AddEventHandler('ox_lib_settings:resetAll', function()
    DeleteResourceKvp('ox_theme')
    set('dark_mode', getDarkModeConvar() == 1)
    set('disable_animations', false)
    set('notification_position', 'top-right')
    refreshNUI()
    lib.notify({ title = 'Réinitialisé', description = 'Tous les paramètres remis aux valeurs par défaut.', type = 'success', duration = 3000 })
    TriggerEvent('ox_lib_settings:openMain')
end)

-- ─── Context menu: MAIN ──────────────────────────────────────────────────────
AddEventHandler('ox_lib_settings:openMain', function()
    local t      = getTheme()
    local preset = PRESET_LABELS[t.activePreset or 'glass'] or 'Glassmorphisme'

    lib.registerContext({
        id    = 'ox_lib_main',
        title = 'OX Lib — Personnalisation',
        options = {
            {
                title       = 'Preset de style',
                description = 'Actuel : ' .. preset,
                icon        = 'palette',
                event       = 'ox_lib_settings:openPresets',
            },
            {
                title       = 'Couleurs — Boutons & Accents',
                description = 'Couleur principale · barre de progression · skill check',
                icon        = 'star',
                event       = 'ox_lib_settings:openColorsBoutons',
            },
            {
                title       = 'Couleurs — Menus',
                description = 'Fond · bordure · texte · items',
                icon        = 'droplet',
                event       = 'ox_lib_settings:openColorsMenus',
            },
            {
                title       = 'Couleurs — Notifications',
                description = 'Fond · bordure · texte (indépendants des menus)',
                icon        = 'bell',
                event       = 'ox_lib_settings:openColorsNotifs',
            },
            {
                title       = 'Réinitialiser — Notifications',
                description = 'Remet les notifications aux couleurs des menus',
                icon        = 'bell-slash',
                event       = 'ox_lib_settings:resetNotifs',
            },
            {
                title       = 'Formes & Effets',
                description = 'Coins arrondis · ombres',
                icon        = 'shapes',
                event       = 'ox_lib_settings:openShapes',
            },
            {
                title       = 'Positions',
                description = 'Notifications · TextUI · Progress (prioritaire sur les scripts)',
                icon        = 'arrows-up-down-left-right',
                event       = 'ox_lib_settings:openPositions',
            },
            {
                title       = 'Options générales',
                description = 'Audio · dark mode · langue',
                icon        = 'gear',
                event       = 'ox_lib_settings:openOptions',
            },
            {
                title       = 'Réinitialiser tout',
                description = 'Remet tous les paramètres aux valeurs par défaut',
                icon        = 'rotate-left',
                event       = 'ox_lib_settings:resetAll',
            },
        }
    })
    lib.showContext('ox_lib_main')
end)

-- ─── Entry point ─────────────────────────────────────────────────────────────
RegisterCommand('ox_lib', function()
    TriggerEvent('ox_lib_settings:openMain')
end, false)

-- ─── Export for other resources ──────────────────────────────────────────────
---@diagnostic disable-next-line: lowercase-global
function getCurrentSettings()
    return {
        darkMode             = settings.dark_mode,
        notificationAudio    = settings.notification_audio,
        disableAnimations    = settings.disable_animations,
        notificationPosition = settings.notification_position,
        locale               = settings.locale,
        theme                = getTheme(),
    }
end

return settings
