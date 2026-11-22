-- Nexus Config
-- Estado global de todas as configurações do menu
-- Suporte a Apply (carregar do disco), Get, Set, Reset
-- @version 1.0.0

local Config = {}
Config._data     = {}
Config._defaults = {}
Config._onChange = {} -- callbacks por chave

-- Padrões globais do menu
Config._defaults = {
    -- UI
    ui_open_key       = "Insert",
    ui_volume         = 0.6,
    ui_transparency   = 0,
    ui_x              = 100,
    ui_y              = 80,

    -- Sounds
    sound_hover       = true,
    sound_click       = true,
    sound_toggle      = true,
    sound_notify      = true,
    sound_open        = true,

    -- Theme
    theme_name        = "default",
    theme_accent      = "7B2FBE",

    -- Player
    speed_enabled     = false,
    speed_value       = 16,
    jump_enabled      = false,
    jump_value        = 50,
    fly_enabled       = false,
    fly_speed         = 60,
    noclip_enabled    = false,
    inf_jump_enabled  = false,
    reach_enabled     = false,
    reach_value       = 6,

    -- Visual
    esp_enabled       = false,
    esp_boxes         = true,
    esp_names         = true,
    esp_health        = true,
    esp_distance      = true,
    esp_tracers       = false,
    esp_chams         = false,
    fullbright        = false,

    -- Farm
    autofarm_enabled  = false,
    autofarm_target   = "nearest",
    questfarm_enabled = false,
    bossfarm_enabled  = false,
    fruitfarm_enabled = false,

    -- PvP
    aimbot_enabled    = false,
    aimbot_fov        = 120,
    aimbot_smooth     = 0.15,
    aimbot_target     = "nearest",
    autoblock_enabled = false,
    killaura_enabled  = false,
    killaura_range    = 10,

    -- HvH
    antiaim_enabled   = false,
    antiaim_mode      = "spin",
    fakelag_enabled   = false,
    fakelag_ticks     = 3,

    -- Misc
    autorejoin        = false,
    serverhop_min     = 2,
    serverhop_max     = 20,
}

function Config:Apply(saved)
    -- Começa com defaults, sobrescreve com o que foi salvo
    self._data = {}
    for k, v in pairs(self._defaults) do
        self._data[k] = v
    end
    if type(saved) == "table" then
        for k, v in pairs(saved) do
            if self._defaults[k] ~= nil then
                self._data[k] = v
            end
        end
    end
end

function Config:Get(key)
    if self._data[key] ~= nil then
        return self._data[key]
    end
    return self._defaults[key]
end

function Config:Set(key, value)
    local old = self._data[key]
    self._data[key] = value

    -- Notifica callbacks registrados para essa chave
    if self._onChange[key] then
        for _, fn in pairs(self._onChange[key]) do
            task.spawn(fn, value, old)
        end
    end

    -- Salva com debounce
    if getgenv().Nexus and getgenv().Nexus.Memory then
        getgenv().Nexus.Memory:SaveDeferred(self._data)
    end
end

function Config:OnChange(key, fn)
    if not self._onChange[key] then
        self._onChange[key] = {}
    end
    local id = #self._onChange[key] + 1
    self._onChange[key][id] = fn
    return function()
        self._onChange[key][id] = nil
    end
end

function Config:Reset()
    self._data = {}
    for k, v in pairs(self._defaults) do
        self._data[k] = v
    end
    if getgenv().Nexus and getgenv().Nexus.Memory then
        getgenv().Nexus.Memory:Save(self._data)
    end
end

function Config:GetAll()
    local copy = {}
    for k, v in pairs(self._data) do
        copy[k] = v
    end
    return copy
end

return Config