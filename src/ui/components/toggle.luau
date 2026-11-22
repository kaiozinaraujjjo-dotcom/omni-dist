-- Nexus Toggle Component
-- Switch animado com spring, som, label e callback
-- @version 1.0.0

local TweenService = game:GetService("TweenService")

local Toggle = {}
Toggle.__index = Toggle

local TWEEN_INFO = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

function Toggle.new(parent, options)
    local self = setmetatable({}, Toggle)

    local theme    = getgenv().Nexus.UI.Theme
    local sounds   = getgenv().Nexus.UI.Sounds
    local config   = getgenv().Nexus.Config

    options = options or {}
    self._value    = options.default or false
    self._key      = options.configKey
    self._onChange = options.onChange
    self._label    = options.label or "Toggle"
    self._desc     = options.description

    -- Se tem configKey, pega valor salvo
    if self._key and config then
        self._value = config:Get(self._key)
    end

    -- === ROOT ===
    local root = Instance.new("Frame")
    root.Name              = "Toggle_" .. self._label
    root.Size              = UDim2.new(1, 0, 0, theme.ElementHeight)
    root.BackgroundColor3  = theme.Surface
    root.BorderSizePixel   = 0
    root.Parent            = parent

    local rootCorner = Instance.new("UICorner")
    rootCorner.CornerRadius = UDim.new(0, 6)
    rootCorner.Parent       = root

    -- === LABEL ===
    local labelFrame = Instance.new("Frame")
    labelFrame.Size             = UDim2.new(1, -60, 1, 0)
    labelFrame.BackgroundTransparency = 1
    labelFrame.Position         = UDim2.new(0, 10, 0, 0)
    labelFrame.Parent           = root

    local labelText = Instance.new("TextLabel")
    labelText.Text              = self._label
    labelText.Font              = theme.FontBody
    labelText.TextSize          = theme.FontSizeBody
    labelText.TextColor3        = theme.TextPrimary
    labelText.TextXAlignment    = Enum.TextXAlignment.Left
    labelText.BackgroundTransparency = 1
    labelText.Size              = UDim2.new(1, 0, self._desc and 0.55 or 1, 0)
    labelText.Parent            = labelFrame

    if self._desc then
        local descText = Instance.new("TextLabel")
        descText.Text           = self._desc
        descText.Font           = theme.FontBody
        descText.TextSize       = theme.FontSizeSmall
        descText.TextColor3     = theme.TextSecondary
        descText.TextXAlignment = Enum.TextXAlignment.Left
        descText.BackgroundTransparency = 1
        descText.Size           = UDim2.new(1, 0, 0.45, 0)
        descText.Position       = UDim2.new(0, 0, 0.55, 0)
        descText.Parent         = labelFrame
    end

    -- === SWITCH TRACK ===
    local trackW, trackH = 40, 20
    local track = Instance.new("Frame")
    track.Name             = "Track"
    track.Size             = UDim2.new(0, trackW, 0, trackH)
    track.Position         = UDim2.new(1, -(trackW + 10), 0.5, -(trackH / 2))
    track.BackgroundColor3 = self._value and theme.ToggleOn or theme.ToggleOff
    track.BorderSizePixel  = 0
    track.Parent           = root

    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(1, 0)
    trackCorner.Parent       = track

    -- === SWITCH THUMB ===
    local thumbSize = trackH - 6
    local thumb = Instance.new("Frame")
    thumb.Name             = "Thumb"
    thumb.Size             = UDim2.new(0, thumbSize, 0, thumbSize)
    thumb.Position         = self._value
        and UDim2.new(1, -(thumbSize + 3), 0.5, -(thumbSize / 2))
        or  UDim2.new(0, 3, 0.5, -(thumbSize / 2))
    thumb.BackgroundColor3 = theme.ToggleThumb
    thumb.BorderSizePixel  = 0
    thumb.Parent           = track

    local thumbCorner = Instance.new("UICorner")
    thumbCorner.CornerRadius = UDim.new(1, 0)
    thumbCorner.Parent       = thumb

    -- === BUTTON DETECTOR ===
    local btn = Instance.new("TextButton")
    btn.Size                = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text                = ""
    btn.Parent              = root

    -- === HOVER ===
    btn.MouseEnter:Connect(function()
        TweenService:Create(root, TWEEN_INFO, {
            BackgroundColor3 = theme.SurfaceHover
        }):Play()
        if sounds then sounds:Play("hover") end
    end)

    btn.MouseLeave:Connect(function()
        TweenService:Create(root, TWEEN_INFO, {
            BackgroundColor3 = theme.Surface
        }):Play()
    end)

    -- === CLICK ===
    btn.MouseButton1Click:Connect(function()
        self:SetValue(not self._value)
        if sounds then sounds:Play(self._value and "toggle_on" or "toggle_off") end
    end)

    self._root  = root
    self._track = track
    self._thumb = thumb

    return self
end

function Toggle:SetValue(value)
    self._value = value

    local theme   = getgenv().Nexus.UI.Theme
    local thumbSize = self._thumb.Size.X.Offset

    -- Anima track
    TweenService:Create(self._track, TWEEN_INFO, {
        BackgroundColor3 = value and theme.ToggleOn or theme.ToggleOff
    }):Play()

    -- Anima thumb
    TweenService:Create(self._thumb, TWEEN_INFO, {
        Position = value
            and UDim2.new(1, -(thumbSize + 3), 0.5, -(thumbSize / 2))
            or  UDim2.new(0, 3, 0.5, -(thumbSize / 2))
    }):Play()

    -- Salva na config
    if self._key and getgenv().Nexus.Config then
        getgenv().Nexus.Config:Set(self._key, value)
    end

    -- Callback
    if self._onChange then
        task.spawn(self._onChange, value)
    end
end

function Toggle:GetValue()
    return self._value
end

function Toggle:Destroy()
    if self._root then
        self._root:Destroy()
    end
end

return Toggle