-- Nexus Label Component
-- Texto simples com suporte a cor, tamanho e alinhamento customizáveis
-- @version 1.0.0

local Label = {}
Label.__index = Label

function Label.new(parent, options)
    local self = setmetatable({}, Label)

    local theme = getgenv().Nexus.UI.Theme

    options         = options or {}
    self._text      = options.text      or ""
    self._color     = options.color     or theme.TextSecondary
    self._size      = options.size      or theme.FontSizeSmall
    self._font      = options.font      or theme.FontBody
    self._align     = options.align     or Enum.TextXAlignment.Left
    self._height    = options.height    or 20

    local root = Instance.new("TextLabel")
    root.Name                = "Label"
    root.Text                = self._text
    root.Font                = self._font
    root.TextSize            = self._size
    root.TextColor3          = self._color
    root.TextXAlignment      = self._align
    root.TextWrapped         = options.wrap ~= false
    root.BackgroundTransparency = 1
    root.BorderSizePixel     = 0
    root.Size                = UDim2.new(1, 0, 0, self._height)
    root.AutomaticSize       = options.autoSize and Enum.AutomaticSize.Y or Enum.AutomaticSize.None
    root.Parent              = parent
    self._root = root

    return self
end

function Label:SetText(text)
    self._root.Text = text
end

function Label:SetColor(color)
    self._root.TextColor3 = color
end

function Label:Destroy()
    if self._root then self._root:Destroy() end
end

return Label