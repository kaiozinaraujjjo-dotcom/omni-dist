-- Nexus Signals
-- Sistema de eventos interno leve, sem BindableEvents
-- Comunicação entre módulos sem criar instâncias Roblox
-- @version 1.0.0

local Signal = {}
Signal.__index = Signal

function Signal.new()
    return setmetatable({
        _handlers = {},
        _nextId   = 0,
    }, Signal)
end

function Signal:Connect(fn)
    assert(type(fn) == "function", "[Signal] Esperado função em Connect")
    self._nextId = self._nextId + 1
    local id = self._nextId
    self._handlers[id] = fn

    return {
        id = id,
        Connected = true,
        Disconnect = function(self)
            self.Connected = false
            Signal._handlers[id] = nil
        end,
    }
end

function Signal:Once(fn)
    local conn
    conn = self:Connect(function(...)
        conn:Disconnect()
        fn(...)
    end)
    return conn
end

function Signal:Fire(...)
    for _, handler in pairs(self._handlers) do
        task.spawn(handler, ...)
    end
end

function Signal:FireDeferred(...)
    local args = { ... }
    task.defer(function()
        self:Fire(table.unpack(args))
    end)
end

function Signal:DisconnectAll()
    self._handlers = {}
    self._nextId   = 0
end

function Signal:GetConnectionCount()
    local count = 0
    for _ in pairs(self._handlers) do count = count + 1 end
    return count
end

-- Registry global de signals nomeados
local SignalRegistry = {}

function SignalRegistry:Get(name)
    if not self._signals then self._signals = {} end
    if not self._signals[name] then
        self._signals[name] = Signal.new()
    end
    return self._signals[name]
end

function SignalRegistry:Fire(name, ...)
    if self._signals and self._signals[name] then
        self._signals[name]:Fire(...)
    end
end

function SignalRegistry:Connect(name, fn)
    return self:Get(name):Connect(fn)
end

function SignalRegistry:DestroyAll()
    if self._signals then
        for _, sig in pairs(self._signals) do
            sig:DisconnectAll()
        end
        self._signals = {}
    end
end

SignalRegistry.new = function()
    return Signal.new()
end

return SignalRegistry