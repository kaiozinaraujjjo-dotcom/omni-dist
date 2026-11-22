-- Nexus Spring
-- Motor de spring physics para animações orgânicas da UI
-- Baseado em modelo massa-mola amortecido
-- @version 1.0.0

local RunService = game:GetService("RunService")

local Spring = {}
Spring.__index = Spring

-- Cria uma nova spring
-- stiffness: tensão (100-300 típico)
-- damping:   amortecimento (0 = oscilar para sempre, 1 = crítico, >1 = overdamped)
-- mass:      massa (geralmente 1)
function Spring.new(initial, stiffness, damping, mass)
    local self = setmetatable({}, Spring)
    self.value      = initial
    self.target     = initial
    self.velocity   = type(initial) == "number" and 0 or initial * 0
    self.stiffness  = stiffness or 170
    self.damping    = damping   or 26
    self.mass       = mass      or 1
    self._type      = type(initial)
    return self
end

function Spring:SetTarget(target)
    self.target = target
end

function Spring:Step(dt)
    local s = self.stiffness
    local d = self.damping
    local m = self.mass

    if self._type == "number" then
        local force    = -s * (self.value - self.target) - d * self.velocity
        self.velocity  = self.velocity + (force / m) * dt
        self.value     = self.value + self.velocity * dt

    elseif self._type == "userdata" then
        -- Suporte a Vector2, Vector3, UDim2, Color3
        local tv = self.target
        local cv = self.value
        local vv = self.velocity

        if typeof(tv) == "Vector2" then
            local fx = -s * (cv.X - tv.X) - d * vv.X
            local fy = -s * (cv.Y - tv.Y) - d * vv.Y
            self.velocity = Vector2.new(
                vv.X + (fx / m) * dt,
                vv.Y + (fy / m) * dt
            )
            self.value = Vector2.new(
                cv.X + self.velocity.X * dt,
                cv.Y + self.velocity.Y * dt
            )

        elseif typeof(tv) == "Color3" then
            local fr = -s * (cv.R - tv.R) - d * vv.X
            local fg = -s * (cv.G - tv.G) - d * vv.Y
            local fb = -s * (cv.B - tv.B) - d * vv.Z
            self.velocity = Vector3.new(
                vv.X + (fr / m) * dt,
                vv.Y + (fg / m) * dt,
                vv.Z + (fb / m) * dt
            )
            self.value = Color3.new(
                math.clamp(cv.R + self.velocity.X * dt, 0, 1),
                math.clamp(cv.G + self.velocity.Y * dt, 0, 1),
                math.clamp(cv.B + self.velocity.Z * dt, 0, 1)
            )
        end
    end

    return self.value
end

function Spring:IsResting(threshold)
    threshold = threshold or 0.001
    local diff

    if self._type == "number" then
        diff = math.abs(self.value - self.target)
        return diff < threshold and math.abs(self.velocity) < threshold

    elseif typeof(self.value) == "Vector2" then
        diff = (self.value - self.target).Magnitude
        return diff < threshold and self.velocity.Magnitude < threshold

    elseif typeof(self.value) == "Color3" then
        return true -- simplificado
    end

    return true
end

function Spring:Reset(value)
    self.value    = value or self.target
    self.velocity = self._type == "number" and 0 or self.velocity * 0
end

-- Utilitário: anima uma propriedade de um objeto com spring, para quando chegar
-- Retorna uma função de cancelamento
function Spring.animate(obj, prop, target, stiffness, damping, onDone)
    local initial = obj[prop]
    local sp = Spring.new(initial, stiffness, damping)
    sp:SetTarget(target)

    local conn
    conn = RunService.RenderStepped:Connect(function(dt)
        local val = sp:Step(dt)
        obj[prop] = val

        if sp:IsResting() then
            obj[prop] = target
            conn:Disconnect()
            if onDone then onDone() end
        end
    end)

    return function()
        conn:Disconnect()
    end
end

return Spring