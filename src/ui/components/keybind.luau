-- Nexus Keybind Component
-- Caixa de captura de tecla com modo de escuta ativo
-- @version 1.0.0

local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Keybind = {}
Keybind.__index = Keybind

-- Teclas que nunca são aceitas como keybind
local BLACKLIST = {
    Enum.KeyCode.Unknown,
    Enum.KeyCode.Return,
    Enum.KeyCode.Escape,
}

local function isBlacklisted(keyCode)
    for _, k in ipairs(BLACKLIST) do
        if keyCode == k then return true end
    end
    return false
end

function Keybind.new(parent, options)
    local self = setmetatable({}, Keybind)

    local theme  = getgenv().Nexus.UI.Theme
    local sounds = getgenv().Nexus.UI.Sounds
    local config = getgenv().Nexus.Config

    options       = options or {}
    self._label   = options.label   or "Keybind"
    self._key     = options.configKey
    self._onChange = options.onChange
    self._listening = false

    local defaultKey = options.default or "None"
    if self._key and config then
        defaultKey = config:Get(self._key) or defaultKey
    end
    self._value = defaultKey

    -- === ROOT ===
    local root = Instance.new("Frame")
    root.Name              = "Keybind_" .. self._label
    root.Size              = UDim2.new(1, 0, 0, theme.ElementHeight)
    root.BackgroundColor3  = theme.Surface
    root.BorderSizePixel   = 0
    root.Parent            = parent
    self._root = root

    local rootCorner = Instance.new("UICorner")
    rootCorner.CornerRadius = UDim.new(0, 6)
    rootCorner.Parent = root

    -- Label
    local labelText = Instance.new("TextLabel")
    labelText.Text           = self._label
    labelText.Font           = theme.FontBody
    labelText.TextSize       = theme.FontSizeBody
    labelText.TextColor3     = theme.TextPrimary
    labelText.TextXAlignment = Enum.TextXAlignment.Left
    labelText.BackgroundTransparency = 1
    labelText.Size           = UDim2.new(1, -100, 1, 0)
    labelText.Position       = UDim2.new(0, 10, 0, 0)
    labelText.Parent         = root

    -- Caixa da tecla
    local keyBox = Instance.new("Frame")
    keyBox.Size              = UDim2.new(0, 80, 0, 22)
    keyBox.Position          = UDim2.new(1, -88, 0.5, -11)
    keyBox.BackgroundColor3  = theme.InputBackground
    keyBox.BorderSizePixel   = 0
    keyBox.Parent            = root
    self._keyBox = keyBox

    local keyBoxCorner = Instance.new("UICorner")
    keyBoxCorner.CornerRadius = UDim.new(0, 4)
    keyBoxCorner.Parent = keyBox

    local keyBoxStroke = Instance.new("UIStroke")
    keyBoxStroke.Color     = theme.Border
    keyBoxStroke.Thickness = 1
    keyBoxStroke.Parent    = keyBox
    self._keyBoxStroke = keyBoxStroke

    local keyLabel = Instance.new("TextLabel")
    keyLabel.Text           = self._value
    keyLabel.Font           = theme.FontMono
    keyLabel.TextSize       = theme.FontSizeMono
    keyLabel.TextColor3     = theme.TextAccent
    keyLabel.TextXAlignment = Enum.TextXAlignment.Center
    keyLabel.BackgroundTransparency = 1
    keyLabel.Size           = UDim2.new(1, 0, 1, 0)
    keyLabel.Parent         = keyBox
    self._keyLabel = keyLabel

    -- === DETECTOR ===
    local btn = Instance.new("TextButton")
    btn.Size                = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text                = ""
    btn.Parent              = keyBox

    btn.MouseButton1Click:Connect(function()
        if self._listening then
            self:_stopListen()
        else
            self:_startListen()
        end
        if sounds then sounds:Play("click") end
    end)

    -- Input global enquanto ouvindo
    UserInputService.InputBegan:Connect(function(input, gp)
        if not self._listening then return end

        if input.UserInputType == Enum.UserInputType.Keyboard then
            if isBlacklisted(input.KeyCode) then
                self:_stopListen()
                return
            end
            local name = input.KeyCode.Name
            self:SetValue(name)
            self:_stopListen()

        elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
            -- Clique fora cancela
            local mp  = UserInputService:GetMouseLocation()
            local kbp = keyBox.AbsolutePosition
            local inBox = mp.X >= kbp.X and mp.X <= kbp.X + keyBox.AbsoluteSize.X
                      and mp.Y >= kbp.Y and mp.Y <= kbp.Y + keyBox.AbsoluteSize.Y
            if not inBox then
                self:_stopListen()
            end
        end
    end)

    return self
end

function Keybind:_startListen()
    local theme = getgenv().Nexus.UI.Theme
    self._listening = true
    self._keyLabel.Text      = "..."
    self._keyLabel.TextColor3 = theme.Warning

    TweenService:Create(self._keyBoxStroke, TweenInfo.new(0.15), {
        Color = theme.Warning
    }):Play()
end

function Keybind:_stopListen()
    local theme = getgenv().Nexus.UI.Theme
    self._listening = false
    self._keyLabel.Text      = self._value
    self._keyLabel.TextColor3 = theme.TextAccent

    TweenService:Create(self._keyBoxStroke, TweenInfo.new(0.15), {
        Color = theme.Border
    }):Play()
end

function Keybind:SetValue(key)
    self._value         = key
    self._keyLabel.Text = key

    if self._key and getgenv().Nexus.Config then
        getgenv().Nexus.Config:Set(self._key, key)
    end

    if self._onChange then
        task.spawn(self._onChange, key)
    end
end

function Keybind:GetValue()
    return self._value
end

function Keybind:Destroy()
    if self._root then self._root:Destroy() end
end

return Keybind