-- Nexus Scheduler
-- Gerencia todas as tasks, loops e coroutines do menu
-- Suporte a pause, resume, jitter (anti-detecção)
-- @version 1.0.0

local Scheduler = {}
Scheduler.__index = Scheduler
Scheduler._tasks = {}

-- Adiciona jitter aleatório ao intervalo para imitar comportamento humano
local function jitter(interval, pct)
    pct = pct or 0.1
    local delta = interval * pct
    return interval + (math.random() * delta * 2 - delta)
end

function Scheduler:Add(name, fn, interval, useJitter)
    if self._tasks[name] then
        self:Stop(name)
    end

    local task_data = {
        fn         = fn,
        interval   = interval or 0,
        useJitter  = useJitter or false,
        running    = true,
        paused     = false,
        thread     = nil,
        callCount  = 0,
    }

    task_data.thread = task.spawn(function()
        while task_data.running do
            if not task_data.paused then
                local ok, err = pcall(task_data.fn)
                if not ok then
                    warn("[Nexus:Scheduler] Erro na task '" .. name .. "': " .. tostring(err))
                end
                task_data.callCount = task_data.callCount + 1
            end

            local wait_time = task_data.interval
            if task_data.useJitter and wait_time > 0 then
                wait_time = jitter(wait_time)
            end

            task.wait(math.max(wait_time, 0))
        end
    end)

    self._tasks[name] = task_data
    return name
end

function Scheduler:AddOnce(name, fn, delay)
    local task_data = {
        running = true,
        thread  = nil,
    }
    task_data.thread = task.delay(delay or 0, function()
        if task_data.running then
            pcall(fn)
        end
        self._tasks[name] = nil
    end)
    self._tasks[name] = task_data
end

function Scheduler:Stop(name)
    local t = self._tasks[name]
    if not t then return end
    t.running = false
    if t.thread then
        pcall(task.cancel, t.thread)
    end
    self._tasks[name] = nil
end

function Scheduler:Pause(name)
    local t = self._tasks[name]
    if t then t.paused = true end
end

function Scheduler:Resume(name)
    local t = self._tasks[name]
    if t then t.paused = false end
end

function Scheduler:IsRunning(name)
    local t = self._tasks[name]
    return t ~= nil and t.running and not t.paused
end

function Scheduler:GetCallCount(name)
    local t = self._tasks[name]
    return t and t.callCount or 0
end

function Scheduler:StopAll()
    for name in pairs(self._tasks) do
        self:Stop(name)
    end
end

function Scheduler:PauseAll()
    for _, t in pairs(self._tasks) do
        t.paused = true
    end
end

function Scheduler:ResumeAll()
    for _, t in pairs(self._tasks) do
        t.paused = false
    end
end

function Scheduler:List()
    local list = {}
    for name, t in pairs(self._tasks) do
        table.insert(list, {
            name    = name,
            running = t.running,
            paused  = t.paused,
            calls   = t.callCount,
        })
    end
    return list
end

return Scheduler