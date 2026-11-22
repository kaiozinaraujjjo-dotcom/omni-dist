-- Nexus Module — Visual (ESP)
-- Player ESP, World ESP, Chams, Tracers, Health Bar, Fullbright
-- @version 1.0.0

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Camera      = workspace.CurrentCamera

local Visual = {}
Visual.__index = Visual
Visual.Name = "Visual"
Visual._drawings = {}

local RAW_BASE = "https://raw.githubusercontent.com/kaiozinaraujjjo-dotcom/omni-dist/main/src/"
local function req(path)
    return loadstring(game:HttpGet(RAW_BASE .. path))()
end

-- ============================================================
-- DRAWING HELPERS
-- ============================================================

local function newBox()
    local box = Drawing.new("Square")
    box.Visible     = false
    box.Color       = Color3.fromHex("7B2FBE")
    box.Thickness   = 1.5
    box.Filled      = false
    box.Transparency = 1
    return box
end

local function newLine()
    local line = Drawing.new("Line")
    line.Visible     = false
    line.Color       = Color3.fromHex("7B2FBE")
    line.Thickness   = 1
    line.Transparency = 1
    return line
end

local function newText()
    local text = Drawing.new("Text")
    text.Visible     = false
    text.Color       = Color3.new(1, 1, 1)
    text.Size        = 13
    text.Font        = Drawing.Fonts.Plex
    text.Center      = true
    text.Outline     = true
    text.OutlineColor = Color3.new(0, 0, 0)
    text.Transparency = 1
    return text
end

local function newTriangle()
    local t = Drawing.new("Triangle")
    t.Visible = false
    t.Filled  = true
    t.Color   = Color3.fromHex("7B2FBE")
    t.Transparency = 1
    return t
end

local function worldToScreen(pos)
    local screenPos, onScreen = Camera:WorldToViewportPoint(pos)
    return Vector2.new(screenPos.X, screenPos.Y), onScreen, screenPos.Z
end

local function getBox2D(char)
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local head    = char:FindFirstChild("Head")
    local topPos  = head and head.Position + Vector3.new(0, head.Size.Y / 2, 0) or hrp.Position + Vector3.new(0, 3, 0)
    local botPos  = hrp.Position - Vector3.new(0, 3, 0)

    local top2D,    topOn  = worldToScreen(topPos)
    local bot2D,    botOn  = worldToScreen(botPos)

    if not topOn and not botOn then return nil end

    local height = math.abs(bot2D.Y - top2D.Y)
    local width  = height * 0.5

    return {
        x      = top2D.X - width / 2,
        y      = top2D.Y,
        width  = width,
        height = height,
        top2D  = top2D,
        bot2D  = bot2D,
    }
end

-- ============================================================
-- INIT
-- ============================================================

function Visual:Init(UI, Config, Signals, Scheduler)
    self._ui        = UI
    self._config    = Config
    self._signals   = Signals
    self._scheduler = Scheduler
    self._espData   = {}
    self._worldESP  = {}

    local tab = UI:AddTab("Visuals", "👁️")
    self:_buildUI(tab)
    self:_startESPLoop()

    print("[Nexus:Visual] Módulo iniciado.")
end

-- ============================================================
-- UI
-- ============================================================

function Visual:_buildUI(tab)
    local Toggle    = req("ui/components/toggle.luau")
    local Separator = req("ui/components/separator.luau")
    local ColorPicker = req("ui/components/colorpicker.luau")

    Separator.new(tab, { text = "Player ESP" })

    Toggle.new(tab, {
        label     = "ESP Ativado",
        configKey = "esp_enabled",
        default   = false,
    })

    Toggle.new(tab, {
        label     = "Boxes",
        configKey = "esp_boxes",
        default   = true,
    })

    Toggle.new(tab, {
        label     = "Nomes",
        configKey = "esp_names",
        default   = true,
    })

    Toggle.new(tab, {
        label     = "Health Bar",
        configKey = "esp_health",
        default   = true,
    })

    Toggle.new(tab, {
        label     = "Distância",
        configKey = "esp_distance",
        default   = true,
    })

    Toggle.new(tab, {
        label     = "Tracers",
        configKey = "esp_tracers",
        default   = false,
    })

    Toggle.new(tab, {
        label     = "Chams",
        description = "Destaca personagens através de paredes",
        configKey = "esp_chams",
        default   = false,
        onChange  = function(val)
            if val then self:EnableChams() else self:DisableChams() end
        end,
    })

    ColorPicker.new(tab, {
        label     = "Cor ESP",
        configKey = "esp_color",
        default   = Color3.fromHex("7B2FBE"),
    })

    Separator.new(tab, { text = "World ESP" })

    Toggle.new(tab, {
        label     = "Frutas no Chão",
        configKey = "wesp_fruits",
        default   = false,
    })

    Toggle.new(tab, {
        label     = "Baús",
        configKey = "wesp_chests",
        default   = false,
    })

    Toggle.new(tab, {
        label     = "Bosses",
        configKey = "wesp_bosses",
        default   = false,
    })

    Toggle.new(tab, {
        label     = "Mobs",
        configKey = "wesp_mobs",
        default   = false,
    })

    Separator.new(tab, { text = "Misc Visual" })

    Toggle.new(tab, {
        label     = "Full Bright",
        configKey = "fullbright",
        default   = false,
        onChange  = function(val)
            if val then self:EnableFullBright() else self:DisableFullBright() end
        end,
    })
end

-- ============================================================
-- ESP LOOP
-- ============================================================

function Visual:_startESPLoop()
    -- Cria ESP para jogador ao entrar
    local function setupPlayer(player)
        if player == LocalPlayer then return end

        local data = {
            box      = newBox(),
            nameText = newText(),
            distText = newText(),
            healthBar = newLine(),
            tracer   = newLine(),
            hpBg     = newLine(),
        }

        self._espData[player] = data

        player.CharacterRemoving:Connect(function()
            for _, d in pairs(data) do
                if typeof(d) == "userdata" then
                    d.Visible = false
                end
            end
        end)
    end

    for _, player in ipairs(Players:GetPlayers()) do
        setupPlayer(player)
    end

    Players.PlayerAdded:Connect(setupPlayer)

    Players.PlayerRemoving:Connect(function(player)
        local data = self._espData[player]
        if data then
            for _, d in pairs(data) do
                if typeof(d) == "userdata" then
                    pcall(d.Remove, d)
                end
            end
            self._espData[player] = nil
        end
    end)

    -- Loop de atualização
    self._scheduler:Add("esp_update", function()
        local espEnabled  = self._config:Get("esp_enabled")
        local showBoxes   = self._config:Get("esp_boxes")
        local showNames   = self._config:Get("esp_names")
        local showHealth  = self._config:Get("esp_health")
        local showDist    = self._config:Get("esp_distance")
        local showTracers = self._config:Get("esp_tracers")

        local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

        for player, data in pairs(self._espData) do
            local char = player.Character
            local visible = espEnabled and char ~= nil

            if not visible then
                data.box.Visible      = false
                data.nameText.Visible = false
                data.distText.Visible = false
                data.healthBar.Visible = false
                data.tracer.Visible   = false
                continue
            end

            local hrp = char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChildOfClass("Humanoid")
            if not hrp or not hum then continue end

            local boxData = getBox2D(char)
            if not boxData then
                data.box.Visible = false
                continue
            end

            -- Box
            if showBoxes then
                data.box.Visible   = true
                data.box.Position  = Vector2.new(boxData.x, boxData.y)
                data.box.Size      = Vector2.new(boxData.width, boxData.height)
                data.box.Color     = Color3.fromHex(self._config:Get("esp_color") or "7B2FBE")
            else
                data.box.Visible = false
            end

            -- Nome
            if showNames then
                data.nameText.Visible   = true
                data.nameText.Text      = player.Name
                data.nameText.Position  = Vector2.new(boxData.top2D.X, boxData.y - 16)
            else
                data.nameText.Visible = false
            end

            -- Distância
            if showDist and myHRP then
                local dist = math.floor((myHRP.Position - hrp.Position).Magnitude)
                data.distText.Visible  = true
                data.distText.Text     = dist .. "m"
                data.distText.Position = Vector2.new(boxData.top2D.X, boxData.y + boxData.height + 2)
            else
                data.distText.Visible = false
            end

            -- Health Bar
            if showHealth then
                local hpPct = hum.Health / hum.MaxHealth
                local barH  = boxData.height * hpPct
                local barX  = boxData.x - 5

                data.hpBg.Visible  = true
                data.hpBg.From     = Vector2.new(barX, boxData.y)
                data.hpBg.To       = Vector2.new(barX, boxData.y + boxData.height)
                data.hpBg.Color    = Color3.fromRGB(50, 50, 50)
                data.hpBg.Thickness = 3

                data.healthBar.Visible  = true
                data.healthBar.From     = Vector2.new(barX, boxData.y + boxData.height)
                data.healthBar.To       = Vector2.new(barX, boxData.y + boxData.height - barH)
                data.healthBar.Color    = Color3.fromHSV(hpPct * 0.33, 1, 1)
                data.healthBar.Thickness = 3
            else
                data.healthBar.Visible = false
                data.hpBg.Visible      = false
            end

            -- Tracers
            if showTracers then
                local center = Camera.ViewportSize
                data.tracer.Visible   = true
                data.tracer.From      = Vector2.new(center.X / 2, center.Y)
                data.tracer.To        = boxData.bot2D
                data.tracer.Color     = Color3.fromHex(self._config:Get("esp_color") or "7B2FBE")
                data.tracer.Thickness = 1
            else
                data.tracer.Visible = false
            end
        end

        -- World ESP
        self:_updateWorldESP()

    end, 0, false)
end

-- ============================================================
-- WORLD ESP
-- ============================================================

function Visual:_updateWorldESP()
    local showFruits  = self._config:Get("wesp_fruits")
    local showChests  = self._config:Get("wesp_chests")
    local showBosses  = self._config:Get("wesp_bosses")
    local showMobs    = self._config:Get("wesp_mobs")

    -- Limpa world esp antigo
    for _, d in pairs(self._worldESP) do
        if typeof(d) == "table" then
            for _, obj in pairs(d) do
                if typeof(obj) == "userdata" then
                    obj.Visible = false
                end
            end
        end
    end

    if not (showFruits or showChests or showBosses or showMobs) then return end

    for _, obj in ipairs(workspace:GetDescendants()) do
        local name  = obj.Name:lower()
        local isFruit  = showFruits  and (name:find("fruit") or name:find("_fruit"))
        local isChest  = showChests  and name:find("chest")
        local isBoss   = showBosses  and obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") and (
            obj.Name:find("Don") or obj.Name:find("Swan") or obj.Name:find("Beast")
            or obj.Name:find("Rip") or obj.Name:find("Bobby") or obj.Name:find("Diamond")
        )
        local isMob    = showMobs    and obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid")
                      and not isBoss and obj ~= LocalPlayer.Character

        local category = isFruit and "fruit" or isChest and "chest" or isBoss and "boss" or isMob and "mob"
        if not category then continue end

        local pos
        if obj:IsA("Model") then
            local pivot = pcall(function() return obj:GetPivot() end) and obj:GetPivot()
            pos = pivot and pivot.Position
        elseif obj:IsA("BasePart") then
            pos = obj.Position
        end

        if not pos then continue end

        local screen, onScreen = worldToScreen(pos)
        if not onScreen then continue end

        local colors = {
            fruit = Color3.fromHex("FFDD44"),
            chest = Color3.fromHex("44BBFF"),
            boss  = Color3.fromHex("FF4444"),
            mob   = Color3.fromHex("AAAAAA"),
        }

        local t = newText()
        t.Text     = "[" .. category:upper() .. "] " .. obj.Name
        t.Position = screen
        t.Color    = colors[category]
        t.Visible  = true

        table.insert(self._worldESP, { text = t })

        task.delay(0, function()
            t.Visible = false
            pcall(t.Remove, t)
        end)
    end
end

-- ============================================================
-- CHAMS
-- ============================================================

function Visual:EnableChams()
    self._chamsConn = RunService.RenderStepped:Connect(function()
        for _, player in ipairs(Players:GetPlayers()) do
            if player == LocalPlayer then continue end
            local char = player.Character
            if not char then continue end

            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    local existing = part:FindFirstChild("NexusCham")
                    if not existing then
                        local highlight = Instance.new("SelectionBox")
                        highlight.Name         = "NexusCham"
                        highlight.Adornee      = part
                        highlight.Color3       = Color3.fromHex("7B2FBE")
                        highlight.SurfaceColor3 = Color3.fromHex("7B2FBE")
                        highlight.SurfaceTransparency = 0.7
                        highlight.LineThickness = 0.02
                        highlight.Parent       = part
                    end
                end
            end
        end
    end)
end

function Visual:DisableChams()
    if self._chamsConn then
        self._chamsConn:Disconnect()
        self._chamsConn = nil
    end
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character then
            for _, part in ipairs(player.Character:GetDescendants()) do
                local cham = part:FindFirstChild("NexusCham")
                if cham then cham:Destroy() end
            end
        end
    end
end

-- ============================================================
-- FULLBRIGHT
-- ============================================================

function Visual:EnableFullBright()
    local lighting = game:GetService("Lighting")
    self._prevBrightness   = lighting.Brightness
    self._prevAmbient      = lighting.Ambient
    self._prevOutdoor      = lighting.OutdoorAmbient

    lighting.Brightness    = 2
    lighting.Ambient       = Color3.new(1, 1, 1)
    lighting.OutdoorAmbient = Color3.new(1, 1, 1)

    -- Desativa efeitos de pós-processamento
    for _, effect in ipairs(lighting:GetChildren()) do
        if effect:IsA("BlurEffect") or effect:IsA("ColorCorrectionEffect")
        or effect:IsA("SunRaysEffect") or effect:IsA("BloomEffect") then
            effect.Enabled = false
        end
    end
end

function Visual:DisableFullBright()
    local lighting = game:GetService("Lighting")
    lighting.Brightness    = self._prevBrightness   or 2
    lighting.Ambient       = self._prevAmbient       or Color3.new(0.5, 0.5, 0.5)
    lighting.OutdoorAmbient = self._prevOutdoor     or Color3.new(0.5, 0.5, 0.5)

    for _, effect in ipairs(lighting:GetChildren()) do
        if effect:IsA("BlurEffect") or effect:IsA("ColorCorrectionEffect")
        or effect:IsA("SunRaysEffect") or effect:IsA("BloomEffect") then
            effect.Enabled = true
        end
    end
end

-- ============================================================
-- UNLOAD
-- ============================================================

function Visual:Unload()
    self._scheduler:Stop("esp_update")
    self:DisableChams()

    if self._config:Get("fullbright") then
        self:DisableFullBright()
    end

    for _, data in pairs(self._espData) do
        for _, d in pairs(data) do
            if typeof(d) == "userdata" then
                pcall(d.Remove, d)
            end
        end
    end
    self._espData = {}
end

return Visual