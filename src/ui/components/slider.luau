-- Nexus Slider Component
-- Slider arrastável com valor em tempo real, step e callback
-- @version 1.0.0

local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")

local Slider = {}
Slider.__index = Slider

local TWEEN_INFO = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

function Slider.new(parent, options)
    local self = setmetatable({}, Slider)

    local theme  = getgenv().Nexus.UI.Theme
    local config = getgenv().Nexus.Config

    options       = options or {}
    self._min     = options.min     or 0
    self._max     = options.max     or 100
    self._step    = options.step    or 1
    self._key     = options.configKey
    self._onChange = options.onChange
    self._label   = options.label or "Slider"
    self._suffix  = options.suffix or ""
    self._dragging = false

    local defaultVal = options.default or self._min
    if self._key and config then
        defaultVal = config:Get(self._key) or defaultVal
    end
    self._value = defaultVal

    -- === ROOT ===
    local root = Instance.new("Frame")
    root.Name             = "Slider_" .. self._label
    root.Size             = UDim2.new(1, 0, 0, theme.ElementHeight + 10)
    root.BackgroundColor3 = theme.Surface
    root.BorderSizePixel  = 0
    root.Parent           = parent

    local rootCorner = Instance.new("UICorner")
    rootCorner.CornerRadius = UDim.new(0, 6)
    rootCorner.Parent = root

    -- === LABEL + VALOR ===
    local labelText = Instance.new("TextLabel")
    labelText.Text           = self._label
    labelText.Font           = theme.FontBody
    labelText.TextSize       = theme.FontSizeBody
    labelText.TextColor3     = theme.TextPrimary
    labelText.TextXAlignment = Enum.TextXAlignment.Left
    labelText.BackgroundTransparency = 1
    labelText.Size           = UDim2.new(0.7, -10, 0, 16)
    labelText.Position       = UDim2.new(0, 10, 0, 6)
    labelText.Parent         = root

    local valueText = Instance.new("TextLabel")
    valueText.Font           = theme.FontMono
    valueText.TextSize       = theme.FontSizeMono
    valueText.TextColor3     = theme.TextAccent
    valueText.TextXAlignment = Enum.TextXAlignment.Right
    valueText.BackgroundTransparency = 1
    valueText.Size           = UDim2.new(0.3, -10, 0, 16)
    valueText.Position       = UDim2.new(0.7, 0, 0, 6)
    valueText.Parent         = root

    -- === TRACK ===
    local track = Instance.new("Frame")
    track.Name            = "Track"
    track.Size            = UDim2.new(1, -20, 0, 4)
    track.Position        = UDim2.new(0, 10, 1, -14)
    track.BackgroundColor3 = theme.SliderTrack
    track.BorderSizePixel  = 0
    track.Parent           = root

    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(1, 0)
    trackCorner.Parent = track

    -- === FILL ===
    local fill = Instance.new("Frame")
    fill.Name             = "Fill"
    fill.Size             = UDim2.new(0, 0, 1, 0)
    fill.BackgroundColor3 = theme.SliderFill
    fill.BorderSizePixel  = 0
    fill.Parent           = track

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent = fill

    -- === THUMB ===
    local thumbSize = 12
    local thumb = Instance.new("Frame")
    thumb.Name             = "Thumb"
    thumb.Size             = UDim2.new(0, thumbSize, 0, thumbSize)
    thumb.Position         = UDim2.new(0, -thumbSize / 2, 0.5, -thumbSize / 2)
    thumb.BackgroundColor3 = theme.SliderThumb
    thumb.BorderSizePixel  = 0
    thumb.ZIndex           = 2
    thumb.Parent           = track

    local thumbCorner = Instance.new("UICorner")
    thumbCorner.CornerRadius = UDim.new(1, 0)
    thumbCorner.Parent = thumb

    -- === DETECTOR ===
    local btn = Instance.new("TextButton")
    btn.Size                = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text                = ""
    btn.ZIndex              = 3
    btn.Parent              = track

    self._root      = root
    self._fill      = fill
    self._thumb     = thumb
    self._valueText = valueText

    -- Aplica valor inicial
    self:_updateVisual(defaultVal)

    -- === DRAG ===
    local function getValueFromMouse()
        local mouseX    = UserInputService:GetMouseLocation().X
        local trackPos  = track.AbsolutePosition.X
        local trackSize = track.AbsoluteSize.X
        local pct = math.clamp((mouseX - trackPos) / trackSize, 0, 1)
        local raw = self._min + pct * (self._max - self._min)

        -- Aplica step
        local stepped = math.round(raw / self._step) * self._step
        return math.clamp(stepped, self._min, self._max)
    end

    btn.MouseButton1Down:Connect(function()
        self._dragging = true
        self:SetValue(getValueFromMouse())
    end)

    -- Clique na trilha
    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            self._dragging = true
            self:SetValue(getValueFromMouse())
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            self._dragging = false
        end
    end)

    RunService.RenderStepped:Connect(function()
        if self._dragging then
            self:SetValue(getValueFromMouse())
        end
    end)

    -- Hover no thumb
    btn.MouseEnter:Connect(function()
        TweenService:Create(thumb, TweenInfo.new(0.1), {
            Size = UDim2.new(0, thumbSize + 3, 0, thumbSize + 3),
            Position = UDim2.new(0, -(thumbSize + 3) / 2, 0.5, -(thumbSize + 3) / 2),
        }):Play()
    end)

    btn.MouseLeave:Connect(function()
        if not self._dragging then
            TweenService:Create(thumb, TweenInfo.new(0.1), {
                Size = UDim2.new(0, thumbSize, 0, thumbSize),
                Position = UDim2.new(0, -thumbSize / 2, 0.5, -thumbSize / 2),
            }):Play()
        end
    end)

    return self
end

function Slider:_updateVisual(value)
    local pct = (value - self._min) / (self._max - self._min)

    self._fill.Size = UDim2.new(pct, 0, 1, 0)

    local thumbSize = self._thumb.Size.X.Offset
    self._thumb.Position = UDim2.new(pct, -thumbSize / 2, 0.5, -thumbSize / 2)

    local display = math.floor(value * 100 + 0.5) / 100
    self._valueText.Text = tostring(display) .. self._suffix
end

function Slider:SetValue(value)
    value = math.clamp(value, self._min, self._max)
    value = math.round(value / self._step) * self._step
    self._value = value

    self:_updateVisual(value)

    if self._key and getgenv().Nexus.Config then
        getgenv().Nexus.Config:Set(self._key, value)
    end

    if self._onChange then
        task.spawn(self._onChange, value)
    end
end

function Slider:GetValue()
    return self._value
end

function Slider:Destroy()
    if self._root then self._root:Destroy() end
end

return Slider