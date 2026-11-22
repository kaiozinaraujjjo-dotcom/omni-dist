-- Nexus Module — HvH (Hacker vs Hacker)
-- Anti Aim, Desync, Fake Lag, Resolver
-- @version 1.0.0

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

local HvH = {}
HvH.__index = HvH
HvH.Name = "HvH"

local RAW_BASE = "https://raw.githubusercontent.com/kaiozinaraujjjo-dotcom/omni-dist/main/src/"
local function req(path)
    return loadstring(game:HttpGet(RAW_BASE .. path))()
end

-- ============================================================
-- HELPERS
-- ============================================================

local function getCharacter()
    return LocalPlayer.Character
end

local function getHRP()
    local c = getCharacter()
    return c and c:FindFirstChild("HumanoidRootPart")
end

-- ============================================================
-- INIT
-- ============================================================

function HvH:Init(UI, Config, Signals, Scheduler)
    self._ui        = UI
    self._config    = Config
    self._signals   = Signals
    self._scheduler = Scheduler
    self._aaConn    = nil
    self._flConn    = nil
    self._resolverData = {}

    local tab = UI:AddTab("HvH", "🤺")
    self:_buildUI(tab)

    print("[Nexus:HvH] Módulo iniciado.")
end

-- ============================================================
-- UI
-- ============================================================

function HvH:_buildUI(tab)
    local Toggle   = req("ui/components/toggle.luau")
    local Slider   = req("ui/components/slider.luau")
    local Dropdown = req("ui/components/dropdown.luau")
    local Separator = req("ui/components/separator.luau")
    local Label    = req("ui/components/label.luau")

    Separator.new(tab, { text = "Anti Aim" })

    Toggle.new(tab, {
        label       = "Anti Aim",
        description = "Manipula rotação para enganar airbots adversários",
        configKey   = "antiaim_enabled",
        default     = false,
        onChange    = function(val)
            if val then self:EnableAntiAim() else self:DisableAntiAim() end
        end,
    })

    Dropdown.new(tab, {
        label     = "Modo Anti Aim",
        configKey = "antiaim_mode",
        options   = { "spin", "jitter", "static_180", "random", "backwards" },
        default   = "spin",
        onChange  = function(val)
            if self._config:Get("antiaim_enabled") then
                self:DisableAntiAim()
                self:EnableAntiAim()
            end
        end,
    })

    Slider.new(tab, {
        label     = "Spin Speed",
        configKey = "antiaim_spin_speed",
        min       = 1, max = 30, step = 1,
        default   = 10,
    })

    Slider.new(tab, {
        label     = "Jitter Range",
        configKey = "antiaim_jitter_range",
        min       = 10, max = 180, step = 5,
        default   = 90, suffix = "°",
    })

    Separator.new(tab, { text = "Desync" })

    Toggle.new(tab, {
        label       = "Desync",
        description = "Separa rotação visual da real no servidor",
        configKey   = "desync_enabled",
        default     = false,
        onChange    = function(val)
            if val then self:EnableDesync() else self:DisableDesync() end
        end,
    })

    Slider.new(tab, {
        label     = "Desync Offset",
        configKey = "desync_offset",
        min       = 0, max = 180, step = 5,
        default   = 90, suffix = "°",
    })

    Separator.new(tab, { text = "Fake Lag" })

    Toggle.new(tab, {
        label       = "Fake Lag",
        description = "Simula lag artificial para dificultar predição adversária",
        configKey   = "fakelag_enabled",
        default     = false,
        onChange    = function(val)
            if val then self:EnableFakeLag() else self:DisableFakeLag() end
        end,
    })

    Slider.new(tab, {
        label     = "Intensidade",
        configKey = "fakelag_ticks",
        min       = 1, max = 15, step = 1,
        default   = 3,
    })

    Separator.new(tab, { text = "Resolver" })

    Toggle.new(tab, {
        label       = "Resolver",
        description = "Tenta calcular e corrigir o anti-aim adversário",
        configKey   = "resolver_enabled",
        default     = false,
        onChange    = function(val)
            if val then self:EnableResolver() else self:DisableResolver() end
        end,
    })

    Label.new(tab, {
        text  = "O resolver monitora padrões de rotação e corrige a mira automaticamente.",
        wrap  = true,
        height = 30,
    })
end

-- ============================================================
-- ANTI AIM
-- ============================================================

function HvH:EnableAntiAim()
    local mode      = self._config:Get("antiaim_mode") or "spin"
    local spinSpeed = self._config:Get("antiaim_spin_speed") or 10
    local jitterRange = self._config:Get("antiaim_jitter_range") or 90
    local angle     = 0

    self._aaConn = RunService.RenderStepped:Connect(function(dt)
        if not self._config:Get("antiaim_enabled") then return end

        local hrp = getHRP()
        if not hrp then return end

        local cam    = workspace.CurrentCamera
        local camY   = cam.CFrame.Rotation

        if mode == "spin" then
            angle = (angle + spinSpeed) % 360
            hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, math.rad(angle), 0)

        elseif mode == "jitter" then
            local offset = math.random(-jitterRange, jitterRange)
            hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, math.rad(offset), 0)

        elseif mode == "static_180" then
            hrp.CFrame = CFrame.new(hrp.Position) * camY * CFrame.Angles(0, math.pi, 0)

        elseif mode == "backwards" then
            hrp.CFrame = CFrame.new(hrp.Position) * camY * CFrame.Angles(0, math.pi, 0)

        elseif mode == "random" then
            local modes = { 0, math.pi, math.pi / 2, -math.pi / 2 }
            local idx   = math.random(1, #modes)
            hrp.CFrame  = CFrame.new(hrp.Position) * CFrame.Angles(0, modes[idx], 0)
        end
    end)
end

function HvH:DisableAntiAim()
    if self._aaConn then
        self._aaConn:Disconnect()
        self._aaConn = nil
    end
end

-- ============================================================
-- DESYNC
-- ============================================================

function HvH:EnableDesync()
    local offset = self._config:Get("desync_offset") or 90

    self._dsConn = RunService.RenderStepped:Connect(function()
        if not self._config:Get("desync_enabled") then return end

        local hrp = getHRP()
        if not hrp then return end

        local cam    = workspace.CurrentCamera
        local visual = cam.CFrame.Rotation

        -- Rotação real: o que o servidor vê
        -- Rotação visual: câmera normal
        -- Offset cria discrepância
        hrp.CFrame = CFrame.new(hrp.Position)
            * visual
            * CFrame.Angles(0, math.rad(self._config:Get("desync_offset") or 90), 0)
    end)
end

function HvH:DisableDesync()
    if self._dsConn then
        self._dsConn:Disconnect()
        self._dsConn = nil
    end
end

-- ============================================================
-- FAKE LAG
-- ============================================================

function HvH:EnableFakeLag()
    local ticks   = self._config:Get("fakelag_ticks") or 3
    local counter = 0

    self._flConn = RunService.Stepped:Connect(function()
        if not self._config:Get("fakelag_enabled") then return end

        counter = counter + 1
        local maxTicks = self._config:Get("fakelag_ticks") or 3

        if counter >= maxTicks then
            counter = 0
            -- Libera updates normalmente
        else
            -- Bloqueia movimento por um tick
            local hrp = getHRP()
            if hrp then
                hrp.AssemblyLinearVelocity = hrp.AssemblyLinearVelocity * 0.1
            end
        end
    end)
end

function HvH:DisableFakeLag()
    if self._flConn then
        self._flConn:Disconnect()
        self._flConn = nil
    end
end

-- ============================================================
-- RESOLVER
-- ============================================================

function HvH:EnableResolver()
    self._resolverConn = RunService.Heartbeat:Connect(function()
        if not self._config:Get("resolver_enabled") then return end

        for _, player in ipairs(Players:GetPlayers()) do
            if player == LocalPlayer then continue end
            if not player.Character then continue end

            local tHRP = player.Character:FindFirstChild("HumanoidRootPart")
            if not tHRP then continue end

            local name = player.Name
            if not self._resolverData[name] then
                self._resolverData[name] = { history = {}, resolvedAngle = 0 }
            end

            local data = self._resolverData[name]
            local curAngle = math.deg(select(2, tHRP.CFrame:ToEulerAnglesYXZ()))

            -- Mantém histórico dos últimos 10 ângulos
            table.insert(data.history, curAngle)
            if #data.history > 10 then
                table.remove(data.history, 1)
            end

            -- Calcula média dos ângulos para inferir padrão
            local sum = 0
            for _, a in ipairs(data.history) do sum = sum + a end
            data.resolvedAngle = sum / #data.history
        end
    end)
end

function HvH:GetResolvedAngle(playerName)
    local data = self._resolverData[playerName]
    return data and data.resolvedAngle or 0
end

function HvH:DisableResolver()
    if self._resolverConn then
        self._resolverConn:Disconnect()
        self._resolverConn = nil
    end
    self._resolverData = {}
end

-- ============================================================
-- UNLOAD
-- ============================================================

function HvH:Unload()
    self:DisableAntiAim()
    self:DisableDesync()
    self:DisableFakeLag()
    self:DisableResolver()
end

return HvH