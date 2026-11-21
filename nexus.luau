-- ███╗   ██╗███████╗██╗  ██╗██╗   ██╗███████╗
-- ████╗  ██║██╔════╝╚██╗██╔╝██║   ██║██╔════╝
-- ██╔██╗ ██║█████╗   ╚███╔╝ ██║   ██║███████╗
-- ██║╚██╗██║██╔══╝   ██╔██╗ ██║   ██║╚════██║
-- ██║ ╚████║███████╗██╔╝ ██╗╚██████╔╝███████║
-- ╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝
-- Nexus Menu — Blox Fruits | v1.0.0
-- @version 1.0.0

local NEXUS_VERSION = "1.0.0"
local NEXUS_CHANNEL = "stable"
local RAW_BASE      = "https://raw.githubusercontent.com/kaiozinaraujjjo-dotcom/omni-dist/main/"
local UPDATE_URL    = RAW_BASE .. "nexus_bundle.luau"

local function req(path)
    local ok, result = pcall(function()
        return loadstring(game:HttpGet(RAW_BASE .. path))()
    end)
    if not ok then
        warn("[Nexus] Falha ao carregar: " .. path .. "\n" .. tostring(result))
        return nil
    end
    return result
end

local function checkExecutor()
    local fns = { "getgenv", "writefile", "readfile", "isfile", "loadstring" }
    for _, fn in ipairs(fns) do
        if not (getfenv()[fn] or _G[fn]) then
            warn("[Nexus] Executor não suporta: " .. fn)
        end
    end
end

local function checkUpdate()
    local ok, remote = pcall(function()
        return game:HttpGet(UPDATE_URL)
    end)
    if not ok or not remote or remote == "" then return false end

    local remoteVer = remote:match("@version%s+([%d%.]+)")
    if remoteVer and remoteVer ~= NEXUS_VERSION then
        print("[Nexus] Atualizando para v" .. remoteVer)
        local bundle = loadstring(remote)
        if bundle then bundle() return true end
    end
    return false
end

local function boot()
    checkExecutor()

    getgenv().Nexus = {
        Version   = NEXUS_VERSION,
        Channel   = NEXUS_CHANNEL,
        Loaded    = false,
        Modules   = {},
        UI        = nil,
        Config    = nil,
        Signals   = nil,
        Scheduler = nil,
    }

    if checkUpdate() then return end

    local Core = req("src/core/init.luau")
    if Core then Core:Boot() end
end

local ok, err = pcall(boot)
if not ok then
    warn("[Nexus] Erro fatal no boot: " .. tostring(err))
end
