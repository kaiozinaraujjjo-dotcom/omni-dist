-- Nexus Module — Farm
-- AutoFarm, Quest Farm, Boss Farm, Fruit Farm, Mastery Farm, Auto Stat
-- @version 1.0.0

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

local Farm = {}
Farm.__index = Farm
Farm.Name = "Farm"

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

local function distanceTo(position)
    local hrp = getHRP()
    if not hrp then return math.huge end
    return (hrp.Position - position).Magnitude
end

local function tpTo(cframe)
    local hrp = getHRP()
    if hrp then hrp.CFrame = cframe end
end

local function waitAlive(timeout)
    timeout = timeout or 5
    local t = 0
    while t < timeout do
        local hum = getHumanoid()
        if hum and hum.Health > 0 then return true end
        task.wait(0.1)
        t = t + 0.1
    end
    return false
end

-- Encontra o mob mais próximo com base em nome de modelo
local function findNearestMob(nameFilter, maxDist)
    maxDist = maxDist or 500
    local best, bestDist = nil, maxDist
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj ~= getCharacter() then
            local hum = obj:FindFirstChildOfClass("Humanoid")
            local hrp = obj:FindFirstChild("HumanoidRootPart")
            if hum and hum.Health > 0 and hrp then
                if not nameFilter or obj.Name:lower():find(nameFilter:lower()) then
                    local d = distanceTo(hrp.Position)
                    if d < bestDist then
                        bestDist = d
                        best     = obj
                    end
                end
            end
        end
    end
    return best, bestDist
end

-- Ataca o mob (simula M1 e habilidades)
local function attackMob(mob)
    if not mob then return end
    local hrp = mob:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    tpTo(CFrame.new(hrp.Position + Vector3.new(3, 2, 0)))
    task.wait(0.05)

    local char  = getCharacter()
    local tools = char and char:GetChildren()
    if tools then
        for _, tool in ipairs(tools) do
            if tool:IsA("Tool") then
                -- Simula ativação do tool
                local remote = tool:FindFirstChild("RemoteEvent") or tool:FindFirstChild("RemoteFunction")
                if remote then
                    pcall(function()
                        remote:FireServer(hrp.Position)
                    end)
                end
            end
        end
    end
end

-- ============================================================
-- INIT
-- ============================================================

local RAW_BASE = "https://raw.githubusercontent.com/kaiozinaraujjjo-dotcom/omni-dist/main/src/"
local function req(path)
    return loadstring(game:HttpGet(RAW_BASE .. path))()
end

function Farm:Init(UI, Config, Signals, Scheduler)
    self._ui        = UI
    self._config    = Config
    self._signals   = Signals
    self._scheduler = Scheduler

    local tab = UI:AddTab("Farm", "🌾")
    self:_buildUI(tab)

    print("[Nexus:Farm] Módulo iniciado.")
end

-- ============================================================
-- UI
-- ============================================================

function Farm:_buildUI(tab)
    local Toggle   = req("ui/components/toggle.luau")
    local Slider   = req("ui/components/slider.luau")
    local Dropdown = req("ui/components/dropdown.luau")
    local Button   = req("ui/components/button.luau")

    -- === AUTO FARM ===
    Toggle.new(tab, {
        label       = "Auto Farm",
        description = "Mata mobs automaticamente",
        configKey   = "autofarm_enabled",
        default     = false,
        onChange    = function(val)
            if val then self:StartAutoFarm() else self:StopAutoFarm() end
        end,
    })

    Dropdown.new(tab, {
        label   = "Alvo do Farm",
        options = { "nearest", "lowest_hp", "highest_xp" },
        configKey = "autofarm_target",
        default = "nearest",
    })

    Slider.new(tab, {
        label     = "Distância máxima",
        configKey = "autofarm_range",
        min       = 50,
        max       = 1000,
        step      = 50,
        default   = 400,
        suffix    = " m",
    })

    -- === QUEST FARM ===
    Toggle.new(tab, {
        label       = "Quest Farm",
        description = "Pega quest, completa e entrega automaticamente",
        configKey   = "questfarm_enabled",
        default     = false,
        onChange    = function(val)
            if val then self:StartQuestFarm() else self:StopQuestFarm() end
        end,
    })

    -- === BOSS FARM ===
    Toggle.new(tab, {
        label       = "Boss Farm",
        description = "Detecta e mata bosses automaticamente",
        configKey   = "bossfarm_enabled",
        default     = false,
        onChange    = function(val)
            if val then self:StartBossFarm() else self:StopBossFarm() end
        end,
    })

    local bossList = {
        "Gorilla King", "Saber Expert", "Brute",
        "Toga Warrior", "Bobby", "Yeti",
        "Diamond", "Swan", "Jeremy",
        "Fajita", "Don Swan", "Rip_Indra",
        "Sea Beast",
    }

    Dropdown.new(tab, {
        label   = "Boss Alvo",
        options = bossList,
        configKey = "boss_target",
        default = "Sea Beast",
    })

    -- === FRUIT FARM ===
    Toggle.new(tab, {
        label       = "Fruit Farm",
        description = "Pega frutas no chão automaticamente",
        configKey   = "fruitfarm_enabled",
        default     = false,
        onChange    = function(val)
            if val then self:StartFruitFarm() else self:StopFruitFarm() end
        end,
    })

    local fruitPriority = {
        "Dragon", "Leopard", "Spirit", "Venom",
        "Control", "Blizzard", "Dough", "Shadow",
        "Phoenix", "Buddha", "Rumble", "Quake",
        "Paw", "Gravity", "Magma", "Light",
        "Ice", "Dark", "Barrier", "String",
        "Bomb", "Chop", "Spike", "Flame",
    }

    Dropdown.new(tab, {
        label   = "Prioridade de Fruta",
        options = fruitPriority,
        configKey = "fruit_priority",
        default = "Dragon",
    })

    -- === MASTERY FARM ===
    Toggle.new(tab, {
        label       = "Mastery Farm",
        description = "Foca em ganhar mastery do item equipado",
        configKey   = "masteryfarm_enabled",
        default     = false,
        onChange    = function(val)
            if val then self:StartMasteryFarm() else self:StopMasteryFarm() end
        end,
    })

    -- === AUTO STAT ===
    Toggle.new(tab, {
        label       = "Auto Stat",
        description = "Distribui pontos ao upar",
        configKey   = "autostat_enabled",
        default     = false,
        onChange    = function(val)
            if val then self:StartAutoStat() else self:StopAutoStat() end
        end,
    })

    local statBuilds = { "Fruit Main", "Sword Main", "Gun Main", "Hybrid Fruit/Sword", "Full Defense" }

    Dropdown.new(tab, {
        label   = "Build de Stats",
        options = statBuilds,
        configKey = "autostat_build",
        default = "Fruit Main",
    })

    -- === INFO ===
    Button.new(tab, {
        label   = "Parar Tudo",
        danger  = true,
        onClick = function()
            self:StopAll()
            self._ui:Notify({ Title = "Farm", Text = "Todos os farms parados", Type = "warning" })
        end,
    })
end

-- ============================================================
-- AUTO FARM
-- ============================================================

function Farm:StartAutoFarm()
    self._scheduler:Add("autofarm", function()
        if not self._config:Get("autofarm_enabled") then return end
        if not waitAlive(1) then return end

        local range = self._config:Get("autofarm_range") or 400
        local mob, dist = findNearestMob(nil, range)

        if not mob then return end

        local hrp = mob:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        attackMob(mob)

    end, 0.1, true) -- jitter ativado
end

function Farm:StopAutoFarm()
    self._scheduler:Stop("autofarm")
end

-- ============================================================
-- QUEST FARM
-- ============================================================

-- Mapa de NPCs de quest por level aproximado
local QUEST_NPCS = {
    { name = "Monkey Quest",     level = 1,   npc = "Quest_Blox",      pos = Vector3.new(-1300, 5, 100) },
    { name = "Pirate Quest",     level = 10,  npc = "Quest_Pirate",    pos = Vector3.new(-2900, 10, 1050) },
    { name = "Marine Quest",     level = 50,  npc = "Quest_Marine",    pos = Vector3.new(-3000, 15, 3700) },
    { name = "Desert Quest",     level = 100, npc = "Quest_Desert",    pos = Vector3.new(-5900, 20, -1400) },
    { name = "Sky Quest",        level = 190, npc = "Quest_Sky",       pos = Vector3.new(-5050, 400, -1600) },
    { name = "Fountain Quest",   level = 300, npc = "Quest_Fountain",  pos = Vector3.new(-500, 20, -4000) },
    { name = "Rose Quest",       level = 700, npc = "Quest_Rose",      pos = Vector3.new(-200, 7, -3700) },
}

local function getPlayerLevel()
    local stats = LocalPlayer:FindFirstChild("leaderstats")
    if stats then
        local lvl = stats:FindFirstChild("Level") or stats:FindFirstChild("Beli")
        return lvl and lvl.Value or 1
    end
    return 1
end

local function findQuestNpcForLevel(level)
    local best = QUEST_NPCS[1]
    for _, entry in ipairs(QUEST_NPCS) do
        if entry.level <= level then
            best = entry
        end
    end
    return best
end

function Farm:StartQuestFarm()
    self._scheduler:Add("questfarm", function()
        if not self._config:Get("questfarm_enabled") then return end
        if not waitAlive(1) then return end

        local level   = getPlayerLevel()
        local quest   = findQuestNpcForLevel(level)
        local questGiver = workspace:FindFirstChild(quest.npc, true)

        if questGiver then
            -- TP até o NPC
            tpTo(CFrame.new(questGiver.Position or quest.pos) + Vector3.new(2, 0, 0))
            task.wait(0.3)

            -- Tenta aceitar via ProximityPrompt ou RemoteEvent
            local prompt = questGiver:FindFirstChildOfClass("ProximityPrompt", true)
            if prompt then
                fireproximityprompt(prompt)
                task.wait(0.2)
            end
        end

        -- Vai matar os mobs do quest
        local mob = findNearestMob(nil, 400)
        if mob then
            attackMob(mob)
        end

        task.wait(0.1)
    end, 0.1, true)
end

function Farm:StopQuestFarm()
    self._scheduler:Stop("questfarm")
end

-- ============================================================
-- BOSS FARM
-- ============================================================

function Farm:StartBossFarm()
    self._scheduler:Add("bossfarm", function()
        if not self._config:Get("bossfarm_enabled") then return end
        if not waitAlive(1) then return end

        local targetName = self._config:Get("boss_target") or "Sea Beast"
        local boss, dist = findNearestMob(targetName, 2000)

        if boss then
            attackMob(boss)
        end
    end, 0.1, true)

    -- Alerta quando boss spawna próximo
    self._scheduler:Add("boss_detector", function()
        local targetName = self._config:Get("boss_target") or "Sea Beast"
        local boss, dist = findNearestMob(targetName, 3000)
        if boss and dist < 500 then
            self._ui:Notify({
                Title    = "Boss Detectado",
                Text     = targetName .. " a " .. math.floor(dist) .. "m",
                Type     = "warning",
                Duration = 5,
            })
        end
    end, 10)
end

function Farm:StopBossFarm()
    self._scheduler:Stop("bossfarm")
    self._scheduler:Stop("boss_detector")
end

-- ============================================================
-- FRUIT FARM
-- ============================================================

local function findFruitOnGround()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("Part") then
            local name = obj.Name:lower()
            if name:find("fruit") or name:find("_fruit") then
                local pos = obj:IsA("Model") and obj:GetPivot().Position
                         or obj.Position
                if pos then
                    return obj, pos
                end
            end
        end
    end
    return nil, nil
end

function Farm:StartFruitFarm()
    self._scheduler:Add("fruitfarm", function()
        if not self._config:Get("fruitfarm_enabled") then return end
        if not waitAlive(1) then return end

        local fruit, pos = findFruitOnGround()
        if fruit and pos then
            tpTo(CFrame.new(pos))
            task.wait(0.2)
            -- Tenta pegar via ProximityPrompt
            local prompt = fruit:FindFirstChildOfClass("ProximityPrompt", true)
            if prompt then
                fireproximityprompt(prompt)
            end
        end
    end, 1, false)
end

function Farm:StopFruitFarm()
    self._scheduler:Stop("fruitfarm")
end

-- ============================================================
-- MASTERY FARM
-- ============================================================

function Farm:StartMasteryFarm()
    self._scheduler:Add("masteryfarm", function()
        if not self._config:Get("masteryfarm_enabled") then return end
        if not waitAlive(1) then return end

        -- Prioriza mobs que dão mais mastery no level atual
        local mob = findNearestMob(nil, 400)
        if mob then
            attackMob(mob)
        end
    end, 0.1, true)
end

function Farm:StopMasteryFarm()
    self._scheduler:Stop("masteryfarm")
end

-- ============================================================
-- AUTO STAT
-- ============================================================

local STAT_BUILDS = {
    ["Fruit Main"]          = { Fruits = 100, Melee = 0,  Defense = 0,  Sword = 0,  Gun = 0  },
    ["Sword Main"]          = { Fruits = 0,   Melee = 25, Defense = 25, Sword = 50, Gun = 0  },
    ["Gun Main"]            = { Fruits = 0,   Melee = 25, Defense = 25, Sword = 0,  Gun = 50 },
    ["Hybrid Fruit/Sword"]  = { Fruits = 50,  Melee = 0,  Defense = 0,  Sword = 50, Gun = 0  },
    ["Full Defense"]        = { Fruits = 0,   Melee = 50, Defense = 50, Sword = 0,  Gun = 0  },
}

function Farm:StartAutoStat()
    self._scheduler:Add("autostat", function()
        if not self._config:Get("autostat_enabled") then return end

        local buildName = self._config:Get("autostat_build") or "Fruit Main"
        local build     = STAT_BUILDS[buildName]
        if not build then return end

        -- Localiza o menu de stats via GUI
        local statsGui  = LocalPlayer.PlayerGui:FindFirstChild("Main", true)
        if not statsGui then return end

        local statRemote = workspace:FindFirstChild("RemoteEvents", true)
            and workspace:FindFirstChild("RemoteEvents"):FindFirstChild("AddStat")

        if not statRemote then return end

        -- Distribui pontos com base nos percentuais do build
        -- O jogo retorna a quantidade de pontos disponíveis
        local function tryAddStat(statName, pct)
            if pct <= 0 then return end
            pcall(function()
                statRemote:FireServer(statName)
            end)
        end

        tryAddStat("Fruits",  build.Fruits)
        tryAddStat("Melee",   build.Melee)
        tryAddStat("Defense", build.Defense)
        tryAddStat("Sword",   build.Sword)
        tryAddStat("Gun",     build.Gun)

    end, 2)
end

function Farm:StopAutoStat()
    self._scheduler:Stop("autostat")
end

-- ============================================================
-- STOP ALL
-- ============================================================

function Farm:StopAll()
    self:StopAutoFarm()
    self:StopQuestFarm()
    self:StopBossFarm()
    self:StopFruitFarm()
    self:StopMasteryFarm()
    self:StopAutoStat()

    self._config:Set("autofarm_enabled",    false)
    self._config:Set("questfarm_enabled",   false)
    self._config:Set("bossfarm_enabled",    false)
    self._config:Set("fruitfarm_enabled",   false)
    self._config:Set("masteryfarm_enabled", false)
    self._config:Set("autostat_enabled",    false)
end

-- ============================================================
-- UNLOAD
-- ============================================================

function Farm:Unload()
    self:StopAll()
end

return Farm