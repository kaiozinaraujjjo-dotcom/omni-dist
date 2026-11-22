-- Nexus Separator Component
-- Linha divisória com texto opcional no centro
-- @version 1.0.0

local Separator = {}
Separator.__index = Separator

function Separator.new(parent, options)
    local self = setmetatable({}, Separator)

    local theme = getgenv().Nexus.UI.Theme

    options     = options or {}
    self._text  = options.text or ""

    local root = Instance.new("Frame")
    root.Name              = "Separator"
    root.Size              = UDim2.new(1, 0, 0, 20)
    root.BackgroundTransparency = 1
    root.BorderSizePixel   = 0
    root.Parent            = parent
    self._root = root

    if self._text == "" then
        -- Linha simples
        local line = Instance.new("Frame")
        line.Size              = UDim2.new(1, 0, 0, 1)
        line.Position          = UDim2.new(0, 0, 0.5, 0)
        line.BackgroundColor3  = theme.BorderSubtle
        line.BorderSizePixel   = 0
        line.Parent            = root
    else
        -- Linha com texto no centro
        local leftLine = Instance.new("Frame")
        leftLine.Size              = UDim2.new(0.35, -6, 0, 1)
        leftLine.Position          = UDim2.new(0, 0, 0.5, 0)
        leftLine.BackgroundColor3  = theme.BorderSubtle
        leftLine.BorderSizePixel   = 0
        leftLine.Parent            = root

        local label = Instance.new("TextLabel")
        label.Text              = self._text
        label.Font              = theme.FontBody
        label.TextSize          = theme.FontSizeSmall
        label.TextColor3        = theme.TextDisabled
        label.TextXAlignment    = Enum.TextXAlignment.Center
        label.BackgroundTransparency = 1
        label.Size              = UDim2.new(0.3, 0, 1, 0)
        label.Position          = UDim2.new(0.35, 0, 0, 0)
        label.Parent            = root

        local rightLine = Instance.new("Frame")
        rightLine.Size             = UDim2.new(0.35, -6, 0, 1)
        rightLine.Position         = UDim2.new(0.65, 6, 0.5, 0)
        rightLine.BackgroundColor3 = theme.BorderSubtle
        rightLine.BorderSizePixel  = 0
        rightLine.Parent           = root
    end

    return self
end

function Separator:Destroy()
    if self._root then self._root:Destroy() end
end

return Separator