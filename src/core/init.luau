-- Nexus Core Init
-- Inicializa subsistemas na ordem correta de dependência
-- @version 1.0.0

local RAW_BASE = "https://raw.githubusercontent.com/kaiozinaraujjjo-dotcom/omni-dist/main/src/"

local function req(path)
    local ok, result = pcall(function()
        return loadstring(game:HttpGet(RAW_BASE .. path))()
    end)
    if not ok then
        warn("[Nexus:Core] Falha ao carregar: " .. path)
        return nil
    end
    return result
end

local Core = {}

function Core:Boot()
    print("[Nexus] Iniciando core v" .. getgenv().Nexus.Version)

    local N = getgenv().Nexus

    -- 1. Signals (base de comunicação entre módulos)
    N.Signals = req("core/signals.luau")

    -- 2. Scheduler (gerencia todas as tasks e loops)
    N.Scheduler = req("core/scheduler.luau")

    -- 3. Memory (leitura/escrita de config no disco)
    N.Memory = req("core/memory.luau")

    -- 4. Config (estado atual das configurações)
    N.Config = req("core/config.luau")

    -- Aplica configurações salvas anteriormente
    if N.Memory and N.Config then
        local saved = N.Memory:Load()
        N.Config:Apply(saved)
    end

    -- 5. UI
    local UI = req("ui/init.luau")
    if not UI then
        warn("[Nexus:Core] UI falhou ao carregar. Abortando.")
        return
    end
    N.UI = UI
    UI:Init()

    -- 6. Módulos de funcionalidade
    local moduleList = {
        "modules/player/init.luau",
        "modules/visual/init.luau",
        "modules/farm/init.luau",
        "modules/pvp/init.luau",
        "modules/hvh/init.luau",
        "modules/trade/init.luau",
        "modules/sea/init.luau",
        "modules/world/init.luau",
        "modules/misc/init.luau",
    }

    for _, path in ipairs(moduleList) do
        local ok, err = pcall(function()
            local mod = req(path)
            if mod and mod.Init then
                mod:Init(UI, N.Config, N.Signals, N.Scheduler)
                table.insert(N.Modules, mod)
                print("[Nexus] Módulo carregado: " .. path)
            end
        end)
        if not ok then
            warn("[Nexus] Falha no módulo " .. path .. ": " .. tostring(err))
        end
    end

    N.Loaded = true
    print("[Nexus] Carregamento completo.")

    UI:Notify({
        Title    = "Nexus",
        Text     = "v" .. N.Version .. " pronto",
        Type     = "success",
        Duration = 4,
    })
end

function Core:Unload()
    local N = getgenv().Nexus
    if N.Scheduler then N.Scheduler:StopAll() end
    if N.UI then N.UI:Destroy() end
    for _, mod in ipairs(N.Modules or {}) do
        if mod.Unload then pcall(mod.Unload, mod) end
    end
    getgenv().Nexus = nil
    print("[Nexus] Descarregado.")
end

return Core
