-- Nexus Module — Player
-- Speed, Jump, Fly, Noclip, InfJump, Reach, Anti Ragdoll, Teleport
-- @version 1.0.0

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

local Player = {}
Player.__index = Player
Player.Name = "Player"

-- ============================================================
-- HELPERS
-- ============================================================

local function getCharacter()
    return LocalPlayer.Character
end

local function getHRP()
    local char = getCharacter()
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid()
    local char = getCharacter()
    return char and char:FindFirstChildOfClass("Humanoid")
end

-- ============================================================
-- INIT
-- ============================================================

function Player:Init(UI, Config, Signals, Scheduler)
    self._ui        = UI
    self._config    = Config
    self._signals   = Signals
    self._scheduler = Scheduler
    self._flying    = false
    self._flyConn   = nil
    self._noclipConn = nil

    -- Monta a tab na UI
    local tab = UI:AddTab("Player", "🧍")
    self:_buildUI(tab)

    -- Restaura estado salvo
    if Config:Get("speed_enabled")    then self:SetSpeed(Config:Get("speed_value"))    end
    if Config:Get("jump_enabled")     then self:SetJump(Config:Get("jump_value"))      end
    if Config:Get("fly_enabled")      then self:EnableFly()                            end
    if Config:Get("noclip_enabled")   then self:EnableNoclip()                         end
    if Config:Get("inf_jump_enabled") then self:EnableInfJump()                        end
    if Config:Get("reach_enabled")    then self:SetReach(Config:Get("reach_value"))    end

    -- Respawn: restaura tudo ao respawnar
    LocalPlayer.CharacterAdded:Connect(function()
        task.wait(0.5)
        if Config:Get("speed_enabled")  then self:SetSpeed(Config:Get("speed_value"))  end
        if Config:Get("jump_enabled")   then self:SetJump(Config:Get("jump_value"))    end
        if Config:Get("fly_enabled")    then self:EnableFly()                          end
        if Config:Get("noclip_enabled") then self:EnableNoclip()                       end
        if Config:Get("inf_jump_enabled") then self:EnableInfJump()                    end
        if Config:Get("reach_enabled")  then self:SetReach(Config:Get("reach_value"))  end
    end)

    print("[Nexus:Player] Módulo iniciado.")
end

-- ============================================================
-- UI
-- ============================================================

local RAW_BASE = "https://raw.githubusercontent.com/kaiozinaraujjjo-dotcom/omni-dist/main/src/"

local function req(path)
    return loadstring(game:HttpGet(RAW_BASE .. path))()
end

function Player:_buildUI(tab)
    local Toggle  = req("ui/components/toggle.luau")
    local Slider  = req("ui/components/slider.luau")
    local Button  = req("ui/components/button.luau")
    local Dropdown = req("ui/components/dropdown.luau")

    -- === SPEED ===
    Toggle.new(tab, {
        label       = "Speed",
        description = "Aumenta a velocidade de movimento",
        configKey   = "speed_enabled",
        default     = false,
        onChange    = function(val)
            if val then
                self:SetSpeed(self._config:Get("speed_value"))
            else
                self:SetSpeed(16)
            end
        end,
    })

    Slider.new(tab, {
        label     = "Velocidade",
        configKey = "speed_value",
        min       = 16,
        max       = 500,
        step      = 1,
        default   = 100,
        suffix    = " wu/s",
        onChange  = function(val)
            if self._config:Get("speed_enabled") then
                self:SetSpeed(val)
            end
        end,
    })

    -- === JUMP ===
    Toggle.new(tab, {
        label     = "Jump Power",
        configKey = "jump_enabled",
        default   = false,
        onChange  = function(val)
            if val then
                self:SetJump(self._config:Get("jump_value"))
            else
                self:SetJump(50)
            end
        end,
    })

    Slider.new(tab, {
        label     = "Altura do Pulo",
        configKey = "jump_value",
        min       = 50,
        max       = 500,
        step      = 5,
        default   = 100,
        onChange  = function(val)
            if self._config:Get("jump_enabled") then
                self:SetJump(val)
            end
        end,
    })

    -- === FLY ===
    Toggle.new(tab, {
        label       = "Fly",
        description = "Voar livremente com WASD + Space/Ctrl",
        configKey   = "fly_enabled",
        default     = false,
        onChange    = function(val)
            if val then self:EnableFly() else self:DisableFly() end
        end,
    })

    Slider.new(tab, {
        label     = "Velocidade de Voo",
        configKey = "fly_speed",
        min       = 10,
        max       = 300,
        step      = 5,
        default   = 60,
        suffix    = " wu/s",
    })

    -- === NOCLIP ===
    Toggle.new(tab, {
        label       = "Noclip",
        description = "Atravessa paredes e colisões",
        configKey   = "noclip_enabled",
        default     = false,
        onChange    = function(val)
            if val then self:EnableNoclip() else self:DisableNoclip() end
        end,
    })

    -- === INF JUMP ===
    Toggle.new(tab, {
        label       = "Infinite Jump",
        description = "Pula infinitamente no ar",
        configKey   = "inf_jump_enabled",
        default     = false,
        onChange    = function(val)
            if val then self:EnableInfJump() else self:DisableInfJump() end
        end,
    })

    -- === REACH ===
    Toggle.new(tab, {
        label       = "Reach",
        description = "Aumenta o alcance dos M1s e skills",
        configKey   = "reach_enabled",
        default     = false,
        onChange    = function(val)
            if val then
                self:SetReach(self._config:Get("reach_value"))
            else
                self:SetReach(6)
            end
        end,
    })

    Slider.new(tab, {
        label     = "Distância de Reach",
        configKey = "reach_value",
        min       = 6,
        max       = 60,
        step      = 0.5,
        default   = 12,
        suffix    = " m",
        onChange  = function(val)
            if self._config:Get("reach_enabled") then
                self:SetReach(val)
            end
        end,
    })

    -- === ANTI RAGDOLL ===
    Toggle.new(tab, {
        label       = "Anti Ragdoll",
        description = "Bloqueia animação de ragdoll ao tomar dano",
        configKey   = "anti_ragdoll",
        default     = false,
        onChange    = function(val)
            if val then self:EnableAntiRagdoll() else self:DisableAntiRagdoll() end
        end,
    })

    -- === TELEPORT ===
    local islands = {
        "Starter Island", "Marine Starter Island",
        "Middle Town", "Jungle", "Pirate Village",
        "Desert", "Frozen Village", "Marine Fortress",
        "Skylands", "Fountain City",
        -- Segundo mar
        "Kingdom of Rose", "Green Zone", "Graveyard",
        "Snow Mountain", "Hot and Cold", "Cursed Ship",
        "Ice Castle", "Forgotten Island",
        -- Terceiro mar
        "Port Town", "Hydra Island", "Great Tree",
        "Floating Turtle", "Haunted Castle",
    }

    Dropdown.new(tab, {
        label     = "Teleport para Ilha",
        options   = islands,
        onChange  = function(island)
            self:TeleportToIsland(island)
        end,
    })

    Button.new(tab, {
        label   = "TP para você mesmo",
        onClick = function()
            local hrp = getHRP()
            if hrp then
                self._lastPos = hrp.CFrame
            end
        end,
    })

    Button.new(tab, {
        label   = "Voltar Última Posição",
        onClick = function()
            if self._lastPos then
                local hrp = getHRP()
                if hrp then hrp.CFrame = self._lastPos end
            end
        end,
    })
end

-- ============================================================
-- SPEED
-- ============================================================

function Player:SetSpeed(value)
    local hum = getHumanoid()
    if hum then
        hum.WalkSpeed = value
    end

    self._scheduler:Add("speed_refresh", function()
        local h = getHumanoid()
        if h and self._config:Get("speed_enabled") then
            h.WalkSpeed = self._config:Get("speed_value")
        end
    end, 1)
end

-- ============================================================
-- JUMP
-- ============================================================

function Player:SetJump(value)
    local hum = getHumanoid()
    if hum then
        hum.JumpPower = value
    end

    self._scheduler:Add("jump_refresh", function()
        local h = getHumanoid()
        if h and self._config:Get("jump_enabled") then
            h.JumpPower = self._config:Get("jump_value")
        end
    end, 1)
end

-- ============================================================
-- FLY
-- ============================================================

function Player:EnableFly()
    self._flying = true
    local speed  = self._config:Get("fly_speed") or 60

    local BodyVel = Instance.new("BodyVelocity")
    BodyVel.Name          = "NexusFlyVelocity"
    BodyVel.Velocity      = Vector3.zero
    BodyVel.MaxForce      = Vector3.new(1e5, 1e5, 1e5)

    local BodyGyr = Instance.new("BodyGyro")
    BodyGyr.Name          = "NexusFlyGyro"
    BodyGyr.MaxTorque     = Vector3.new(1e5, 1e5, 1e5)
    BodyGyr.P             = 1e4

    local function attachToChar()
        local hrp = getHRP()
        if not hrp then return end
        BodyVel.Parent = hrp
        BodyGyr.Parent = hrp
    end

    attachToChar()

    self._flyConn = RunService.RenderStepped:Connect(function()
        if not self._flying then return end

        local hrp = getHRP()
        if not hrp then return end

        local cam    = workspace.CurrentCamera
        local spd    = self._config:Get("fly_speed") or speed
        local moving = Vector3.zero

        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            moving = moving + cam.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            moving = moving - cam.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            moving = moving - cam.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            moving = moving + cam.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            moving = moving + Vector3.new(0, 1, 0)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
            moving = moving - Vector3.new(0, 1, 0)
        end

        if moving.Magnitude > 0 then
            moving = moving.Unit * spd
        end

        BodyVel.Velocity = moving
        BodyGyr.CFrame   = cam.CFrame
    end)
end

function Player:DisableFly()
    self._flying = false
    if self._flyConn then
        self._flyConn:Disconnect()
        self._flyConn = nil
    end
    local hrp = getHRP()
    if hrp then
        local bv = hrp:FindFirstChild("NexusFlyVelocity")
        local bg = hrp:FindFirstChild("NexusFlyGyro")
        if bv then bv:Destroy() end
        if bg then bg:Destroy() end
    end
end

-- ============================================================
-- NOCLIP
-- ============================================================

function Player:EnableNoclip()
    self._noclipConn = RunService.Stepped:Connect(function()
        local char = getCharacter()
        if not char then return end
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end)
end

function Player:DisableNoclip()
    if self._noclipConn then
        self._noclipConn:Disconnect()
        self._noclipConn = nil
    end
    local char = getCharacter()
    if char then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
    end
end

-- ============================================================
-- INFINITE JUMP
-- ============================================================

function Player:EnableInfJump()
    self._infJumpConn = UserInputService.JumpRequest:Connect(function()
        local hum = getHumanoid()
        if hum and self._config:Get("inf_jump_enabled") then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end)
end

function Player:DisableInfJump()
    if self._infJumpConn then
        self._infJumpConn:Disconnect()
        self._infJumpConn = nil
    end
end

-- ============================================================
-- REACH
-- ============================================================

function Player:SetReach(value)
    -- Hook no tool equipado — expande hitbox de M1
    local char = getCharacter()
    if not char then return end

    self._scheduler:Add("reach_hook", function()
        local c = getCharacter()
        if not c then return end
        for _, tool in ipairs(c:GetChildren()) do
            if tool:IsA("Tool") then
                local handle = tool:FindFirstChild("Handle")
                if handle then
                    handle.Size = Vector3.new(value, value, value)
                end
            end
        end
    end, 0.5)
end

-- ============================================================
-- ANTI RAGDOLL
-- ============================================================

function Player:EnableAntiRagdoll()
    self._ragdollConn = RunService.Stepped:Connect(function()
        local hum = getHumanoid()
        if not hum then return end
        if hum:GetState() == Enum.HumanoidStateType.FallingDown
        or hum:GetState() == Enum.HumanoidStateType.Ragdoll then
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
    end)
end

function Player:DisableAntiRagdoll()
    if self._ragdollConn then
        self._ragdollConn:Disconnect()
        self._ragdollConn = nil
    end
end

-- ============================================================
-- TELEPORT
-- ============================================================

function Player:TeleportToPlayer(targetName)
    local target = Players:FindFirstChild(targetName)
    if not target or not target.Character then return end
    local hrp    = getHRP()
    local tHRP   = target.Character:FindFirstChild("HumanoidRootPart")
    if hrp and tHRP then
        hrp.CFrame = tHRP.CFrame + Vector3.new(3, 0, 0)
    end
end

function Player:TeleportToIsland(islandName)
    -- Mapa de coordenadas aproximadas das ilhas do Blox Fruits
    local islandCoords = {
        ["Starter Island"]       = Vector3.new(-1300, 5, 100),
        ["Middle Town"]          = Vector3.new(-500, 20, -1700),
        ["Jungle"]               = Vector3.new(-1900, 25, -40),
        ["Pirate Village"]       = Vector3.new(-3000, 15, 1000),
        ["Desert"]               = Vector3.new(-5900, 20, -1400),
        ["Frozen Village"]       = Vector3.new(-4700, 50, 4000),
        ["Marine Fortress"]      = Vector3.new(-3000, 15, 3800),
        ["Skylands"]             = Vector3.new(-5100, 400, -1600),
        ["Fountain City"]        = Vector3.new(-500, 20, -4000),
        ["Kingdom of Rose"]      = Vector3.new(-200, 7, -3700),
        ["Green Zone"]           = Vector3.new(-2700, 15, -4200),
        ["Graveyard"]            = Vector3.new(1100, 15, -3000),
        ["Snow Mountain"]        = Vector3.new(-1100, 300, -6000),
        ["Hot and Cold"]         = Vector3.new(-5000, 100, -6000),
        ["Port Town"]            = Vector3.new(5500, 10, -2800),
        ["Hydra Island"]         = Vector3.new(5000, 10, -1000),
        ["Great Tree"]           = Vector3.new(4500, 10, 2500),
        ["Floating Turtle"]      = Vector3.new(-8000, 100, 2000),
    }

    local coords = islandCoords[islandName]
    if not coords then
        self._ui:Notify({ Title = "Teleport", Text = "Coordenadas não mapeadas: " .. islandName, Type = "warning" })
        return
    end

    local hrp = getHRP()
    if hrp then
        hrp.CFrame = CFrame.new(coords)
        self._ui:Notify({ Title = "Teleport", Text = "→ " .. islandName, Type = "success", Duration = 3 })
    end
end

function Player:TeleportToCoords(x, y, z)
    local hrp = getHRP()
    if hrp then
        hrp.CFrame = CFrame.new(x, y, z)
    end
end

-- ============================================================
-- UNLOAD
-- ============================================================

function Player:Unload()
    self:DisableFly()
    self:DisableNoclip()
    self:DisableInfJump()
    self:DisableAntiRagdoll()
    self._scheduler:Stop("speed_refresh")
    self._scheduler:Stop("jump_refresh")
    self._scheduler:Stop("reach_hook")

    local hum = getHumanoid()
    if hum then
        hum.WalkSpeed = 16
        hum.JumpPower = 50
    end
end

return Player