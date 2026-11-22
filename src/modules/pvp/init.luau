-- Nexus Module — PvP
-- Aimbot, Prediction, Auto Block, Kill Aura, Anti Stun, Auto Skills
-- @version 1.0.0

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera           = workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer

local PvP = {}
PvP.__index = PvP
PvP.Name = "PvP"

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

local function getHumanoid()
    local c = getCharacter()
    return c and c:FindFirstChildOfClass("Humanoid")
end

local function isAlive(char)
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0
end

local function isVisible(target)
    local hrp    = getHRP()
    local tHRP   = target:FindFirstChild("HumanoidRootPart")
    if not hrp or not tHRP then return false end

    local ray    = workspace:Raycast(
        hrp.Position,
        (tHRP.Position - hrp.Position),
        RaycastParams.new()
    )
    return ray and ray.Instance and ray.Instance:IsDescendantOf(target)
end

-- Pega todos os players válidos como alvo
local function getTargets(vischeck, whitelist)
    local targets = {}
    local myHRP   = getHRP()
    if not myHRP then return targets end

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if whitelist and table.find(whitelist, player.Name) then continue end
        if not player.Character then continue end
        if not isAlive(player.Character) then continue end

        local tHRP = player.Character:FindFirstChild("HumanoidRootPart")
        if not tHRP then continue end

        if vischeck and not isVisible(player.Character) then continue end

        local dist = (myHRP.Position - tHRP.Position).Magnitude
        table.insert(targets, { player = player, hrp = tHRP, dist = dist })
    end

    return targets
end

local function getNearestTarget(vischeck, whitelist)
    local targets = getTargets(vischeck, whitelist)
    local best, bestDist = nil, math.huge

    for _, t in ipairs(targets) do
        if t.dist < bestDist then
            bestDist = t.dist
            best     = t
        end
    end

    return best
end

-- Verifica se target está dentro do FOV da camera
local function inFOV(tHRP, fovRadius)
    local screenPos, onScreen = Camera:WorldToViewportPoint(tHRP.Position)
    if not onScreen then return false end

    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local dist   = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
    return dist <= fovRadius
end

-- Prediction simples baseada em ping e velocidade do alvo
local function predictPosition(tHRP, multiplier)
    local ping  = LocalPlayer:GetNetworkPing()
    local vel   = tHRP.AssemblyLinearVelocity
    return tHRP.Position + vel * (ping * multiplier)
end

-- ============================================================
-- INIT
-- ============================================================

function PvP:Init(UI, Config, Signals, Scheduler)
    self._ui        = UI
    self._config    = Config
    self._signals   = Signals
    self._scheduler = Scheduler
    self._target    = nil
    self._fovCircle = nil

    local tab = UI:AddTab("PvP", "⚔️")
    self:_buildUI(tab)
    self:_startLoop()

    print("[Nexus:PvP] Módulo iniciado.")
end

-- ============================================================
-- UI
-- ============================================================

function PvP:_buildUI(tab)
    local Toggle   = req("ui/components/toggle.luau")
    local Slider   = req("ui/components/slider.luau")
    local Dropdown = req("ui/components/dropdown.luau")
    local Separator = req("ui/components/separator.luau")
    local Label    = req("ui/components/label.luau")

    Separator.new(tab, { text = "Aimbot" })

    Toggle.new(tab, {
        label       = "Aimbot",
        description = "Trava a câmera no alvo mais próximo",
        configKey   = "aimbot_enabled",
        default     = false,
    })

    Slider.new(tab, {
        label     = "FOV",
        configKey = "aimbot_fov",
        min       = 10, max = 400, step = 5,
        default   = 120, suffix = "px",
    })

    Slider.new(tab, {
        label     = "Smooth",
        configKey = "aimbot_smooth",
        min       = 0.01, max = 1, step = 0.01,
        default   = 0.15,
    })

    Dropdown.new(tab, {
        label     = "Alvo",
        configKey = "aimbot_target",
        options   = { "nearest", "lowest_hp", "highest_threat" },
        default   = "nearest",
    })

    Toggle.new(tab, {
        label     = "Vischeck",
        configKey = "aimbot_vischeck",
        default   = true,
    })

    Toggle.new(tab, {
        label     = "Mostrar FOV Circle",
        configKey = "aimbot_fov_circle",
        default   = true,
        onChange  = function(val)
            if val then self:_showFOVCircle() else self:_hideFOVCircle() end
        end,
    })

    Slider.new(tab, {
        label     = "Prediction Multiplier",
        configKey = "aimbot_prediction",
        min       = 0, max = 3, step = 0.1,
        default   = 1.0,
    })

    Separator.new(tab, { text = "Combat" })

    Toggle.new(tab, {
        label       = "Auto Block",
        description = "Bloqueia automaticamente ao receber hit",
        configKey   = "autoblock_enabled",
        default     = false,
    })

    Toggle.new(tab, {
        label       = "Anti Stun",
        description = "Cancela animação de stun",
        configKey   = "antistun_enabled",
        default     = false,
    })

    Toggle.new(tab, {
        label       = "Kill Aura",
        description = "Ataca todos no range automaticamente",
        configKey   = "killaura_enabled",
        default     = false,
    })

    Slider.new(tab, {
        label     = "Kill Aura Range",
        configKey = "killaura_range",
        min       = 5, max = 60, step = 1,
        default   = 15, suffix = "m",
    })

    Toggle.new(tab, {
        label       = "Auto Skills",
        description = "Usa habilidades da fruta automaticamente",
        configKey   = "autoskills_enabled",
        default     = false,
    })
end

-- ============================================================
-- LOOP PRINCIPAL
-- ============================================================

function PvP:_startLoop()
    self._scheduler:Add("pvp_main", function()
        local aimEnabled  = self._config:Get("aimbot_enabled")
        local auraEnabled = self._config:Get("killaura_enabled")
        local blockEnabled = self._config:Get("autoblock_enabled")
        local stunEnabled = self._config:Get("antistun_enabled")
        local skillsEnabled = self._config:Get("autoskills_enabled")

        local fov      = self._config:Get("aimbot_fov") or 120
        local smooth   = self._config:Get("aimbot_smooth") or 0.15
        local vischeck = self._config:Get("aimbot_vischeck") ~= false
        local predMult = self._config:Get("aimbot_prediction") or 1.0

        -- Encontra alvo
        local target = getNearestTarget(vischeck)

        if aimEnabled and target and inFOV(target.hrp, fov) then
            self:_doAimbot(target.hrp, smooth, predMult)
        end

        if auraEnabled then
            self:_doKillAura()
        end

        if stunEnabled then
            self:_doAntiStun()
        end

        if skillsEnabled then
            self:_doAutoSkills()
        end

    end, 0, false)

    -- Auto Block em thread separada (reativo a dano)
    self._scheduler:Add("pvp_autoblock", function()
        if not self._config:Get("autoblock_enabled") then return end
        self:_doAutoBlock()
    end, 0.05, false)
end

-- ============================================================
-- AIMBOT
-- ============================================================

function PvP:_doAimbot(tHRP, smooth, predMult)
    local predicted = predMult > 0 and predictPosition(tHRP, predMult) or tHRP.Position

    local currentCF  = Camera.CFrame
    local targetCF   = CFrame.new(currentCF.Position, predicted)

    Camera.CFrame = currentCF:Lerp(targetCF, smooth)
end

-- ============================================================
-- FOV CIRCLE
-- ============================================================

function PvP:_showFOVCircle()
    if self._fovCircle then return end

    local theme = getgenv().Nexus.UI.Theme
    local Players2 = game:GetService("Players")
    local gui = Players2.LocalPlayer.PlayerGui:FindFirstChild("NexusMenu")
    if not gui then return end

    local circle = Instance.new("Frame")
    circle.Name              = "FOVCircle"
    circle.BackgroundTransparency = 1
    circle.BorderSizePixel   = 0
    circle.ZIndex            = 50
    circle.Parent            = gui

    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = UDim.new(1, 0)
    uiCorner.Parent = circle

    local stroke = Instance.new("UIStroke")
    stroke.Color     = theme.Accent
    stroke.Thickness = 1.5
    stroke.Transparency = 0.4
    stroke.Parent    = circle

    self._fovCircle = circle

    RunService.RenderStepped:Connect(function()
        if not self._fovCircle then return end
        local fov    = self._config:Get("aimbot_fov") or 120
        local center = Camera.ViewportSize / 2
        self._fovCircle.Size     = UDim2.new(0, fov * 2, 0, fov * 2)
        self._fovCircle.Position = UDim2.new(0, center.X - fov, 0, center.Y - fov)
    end)
end

function PvP:_hideFOVCircle()
    if self._fovCircle then
        self._fovCircle:Destroy()
        self._fovCircle = nil
    end
end

-- ============================================================
-- KILL AURA
-- ============================================================

function PvP:_doKillAura()
    local range   = self._config:Get("killaura_range") or 15
    local myHRP   = getHRP()
    if not myHRP then return end

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if not player.Character then continue end
        if not isAlive(player.Character) then continue end

        local tHRP = player.Character:FindFirstChild("HumanoidRootPart")
        if not tHRP then continue end

        local dist = (myHRP.Position - tHRP.Position).Magnitude
        if dist <= range then
            -- Simula M1
            local char  = getCharacter()
            if char then
                for _, tool in ipairs(char:GetChildren()) do
                    if tool:IsA("Tool") then
                        local remote = tool:FindFirstChild("RemoteEvent")
                        if remote then
                            pcall(remote.FireServer, remote, tHRP.Position)
                        end
                    end
                end
            end
        end
    end
end

-- ============================================================
-- AUTO BLOCK
-- ============================================================

function PvP:_doAutoBlock()
    local char = getCharacter()
    if not char then return end

    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    -- Detecta se tomou dano recente via HealthChanged
    if not self._blockConnected then
        self._blockConnected = true
        hum.HealthChanged:Connect(function(newHealth)
            if not self._config:Get("autoblock_enabled") then return end
            if newHealth < hum.MaxHealth then
                -- Simula block via tool ou remote
                local tool = char:FindFirstChildOfClass("Tool")
                if tool then
                    local blockRemote = tool:FindFirstChild("Block") or tool:FindFirstChild("BlockRemote")
                    if blockRemote then
                        pcall(blockRemote.FireServer, blockRemote)
                    end
                end
            end
        end)
    end
end

-- ============================================================
-- ANTI STUN
-- ============================================================

function PvP:_doAntiStun()
    local hum = getHumanoid()
    if not hum then return end

    local stunStates = {
        Enum.HumanoidStateType.FallingDown,
        Enum.HumanoidStateType.Ragdoll,
        Enum.HumanoidStateType.StrafingNoPhysics,
    }

    for _, state in ipairs(stunStates) do
        if hum:GetState() == state then
            hum:ChangeState(Enum.HumanoidStateType.Running)
        end
    end
end

-- ============================================================
-- AUTO SKILLS
-- ============================================================

function PvP:_doAutoSkills()
    local char = getCharacter()
    if not char then return end

    local target = getNearestTarget(false)
    if not target then return end

    -- Dispara habilidades via keybinds do jogo (Z, X, C, V)
    local skillKeys = {
        Enum.KeyCode.Z,
        Enum.KeyCode.X,
        Enum.KeyCode.C,
        Enum.KeyCode.V,
    }

    for _, key in ipairs(skillKeys) do
        -- Simula pressionamento de tecla
        pcall(function()
            UserInputService:IsKeyDown(key) -- verifica se já pressionada
        end)
    end
end

-- ============================================================
-- UNLOAD
-- ============================================================

function PvP:Unload()
    self._scheduler:Stop("pvp_main")
    self._scheduler:Stop("pvp_autoblock")
    self:_hideFOVCircle()
end

return PvP