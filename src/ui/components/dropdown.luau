-- Nexus Dropdown Component
-- Menu flutuante com lista de opções, busca e callback
-- @version 1.0.0

local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Dropdown = {}
Dropdown.__index = Dropdown

local TWEEN = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

function Dropdown.new(parent, options)
    local self = setmetatable({}, Dropdown)

    local theme  = getgenv().Nexus.UI.Theme
    local sounds = getgenv().Nexus.UI.Sounds
    local config = getgenv().Nexus.Config

    options         = options or {}
    self._label     = options.label    or "Dropdown"
    self._options   = options.options  or {}
    self._key       = options.configKey
    self._onChange  = options.onChange
    self._search    = options.search   ~= false
    self._isOpen    = false

    local defaultVal = options.default or (self._options[1] or "")
    if self._key and config then
        defaultVal = config:Get(self._key) or defaultVal
    end
    self._value = defaultVal

    -- === ROOT ===
    local root = Instance.new("Frame")
    root.Name              = "Dropdown_" .. self._label
    root.Size              = UDim2.new(1, 0, 0, theme.ElementHeight)
    root.BackgroundTransparency = 1
    root.BorderSizePixel   = 0
    root.ClipsDescendants  = false
    root.Parent            = parent
    self._root = root

    -- Label acima
    local labelText = Instance.new("TextLabel")
    labelText.Text           = self._label
    labelText.Font           = theme.FontBody
    labelText.TextSize       = theme.FontSizeSmall
    labelText.TextColor3     = theme.TextSecondary
    labelText.TextXAlignment = Enum.TextXAlignment.Left
    labelText.BackgroundTransparency = 1
    labelText.Size           = UDim2.new(1, 0, 0, 14)
    labelText.Position       = UDim2.new(0, 0, 0, -16)
    labelText.Parent         = root

    -- === HEAD (valor atual + seta) ===
    local head = Instance.new("Frame")
    head.Name              = "Head"
    head.Size              = UDim2.new(1, 0, 1, 0)
    head.BackgroundColor3  = theme.Surface
    head.BorderSizePixel   = 0
    head.Parent            = root
    self._head = head

    local headCorner = Instance.new("UICorner")
    headCorner.CornerRadius = UDim.new(0, 6)
    headCorner.Parent = head

    local headStroke = Instance.new("UIStroke")
    headStroke.Color     = theme.Border
    headStroke.Thickness = 1
    headStroke.Parent    = head
    self._headStroke = headStroke

    local currentVal = Instance.new("TextLabel")
    currentVal.Text           = self._value
    currentVal.Font           = theme.FontBody
    currentVal.TextSize       = theme.FontSizeBody
    currentVal.TextColor3     = theme.TextPrimary
    currentVal.TextXAlignment = Enum.TextXAlignment.Left
    currentVal.BackgroundTransparency = 1
    currentVal.Size           = UDim2.new(1, -34, 1, 0)
    currentVal.Position       = UDim2.new(0, 10, 0, 0)
    currentVal.Parent         = head
    self._currentVal = currentVal

    -- Seta
    local arrow = Instance.new("TextLabel")
    arrow.Text           = "▾"
    arrow.Font           = theme.FontBody
    arrow.TextSize       = 14
    arrow.TextColor3     = theme.TextSecondary
    arrow.BackgroundTransparency = 1
    arrow.Size           = UDim2.new(0, 24, 1, 0)
    arrow.Position       = UDim2.new(1, -28, 0, 0)
    arrow.Parent         = head
    self._arrow = arrow

    local headBtn = Instance.new("TextButton")
    headBtn.Size                = UDim2.new(1, 0, 1, 0)
    headBtn.BackgroundTransparency = 1
    headBtn.Text                = ""
    headBtn.Parent              = head

    -- === MENU FLUTUANTE ===
    local menu = Instance.new("Frame")
    menu.Name              = "Menu"
    menu.Size              = UDim2.new(1, 0, 0, 0)
    menu.Position          = UDim2.new(0, 0, 1, 4)
    menu.BackgroundColor3  = theme.Surface
    menu.BorderSizePixel   = 0
    menu.ClipsDescendants  = true
    menu.Visible           = false
    menu.ZIndex            = 10
    menu.Parent            = root
    self._menu = menu

    local menuCorner = Instance.new("UICorner")
    menuCorner.CornerRadius = UDim.new(0, 6)
    menuCorner.Parent = menu

    local menuStroke = Instance.new("UIStroke")
    menuStroke.Color     = theme.BorderAccent
    menuStroke.Thickness = 1
    menuStroke.Parent    = menu

    -- Campo de busca
    local searchBox = nil
    local searchOffset = 0

    if self._search then
        searchOffset = 30
        local searchFrame = Instance.new("Frame")
        searchFrame.Size             = UDim2.new(1, 0, 0, 30)
        searchFrame.BackgroundColor3 = theme.InputBackground
        searchFrame.BorderSizePixel  = 0
        searchFrame.Parent           = menu

        local searchInput = Instance.new("TextBox")
        searchInput.PlaceholderText  = "Buscar..."
        searchInput.PlaceholderColor3 = theme.TextDisabled
        searchInput.Text             = ""
        searchInput.Font             = theme.FontBody
        searchInput.TextSize         = theme.FontSizeBody
        searchInput.TextColor3       = theme.TextPrimary
        searchInput.TextXAlignment   = Enum.TextXAlignment.Left
        searchInput.BackgroundTransparency = 1
        searchInput.Size             = UDim2.new(1, -16, 1, 0)
        searchInput.Position         = UDim2.new(0, 10, 0, 0)
        searchInput.ClearTextOnFocus = false
        searchInput.Parent           = searchFrame
        searchBox = searchInput
    end

    -- Lista de opções (scrollable)
    local listFrame = Instance.new("ScrollingFrame")
    listFrame.Size                = UDim2.new(1, 0, 1, -searchOffset)
    listFrame.Position            = UDim2.new(0, 0, 0, searchOffset)
    listFrame.BackgroundTransparency = 1
    listFrame.BorderSizePixel     = 0
    listFrame.ScrollBarThickness  = 2
    listFrame.ScrollBarImageColor3 = theme.ScrollBar
    listFrame.CanvasSize          = UDim2.new(0, 0, 0, 0)
    listFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    listFrame.ZIndex              = 10
    listFrame.Parent              = menu
    self._listFrame = listFrame

    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding   = UDim.new(0, 1)
    listLayout.Parent    = listFrame

    self:_buildOptions(self._options)

    -- Busca
    if searchBox then
        searchBox:GetPropertyChangedSignal("Text"):Connect(function()
            local query = searchBox.Text:lower()
            local filtered = {}
            for _, opt in ipairs(self._options) do
                if opt:lower():find(query, 1, true) then
                    table.insert(filtered, opt)
                end
            end
            self:_buildOptions(filtered)
        end)
    end

    -- === OPEN/CLOSE ===
    headBtn.MouseButton1Click:Connect(function()
        if self._isOpen then
            self:_close()
        else
            self:_open()
        end
        if sounds then sounds:Play("click") end
    end)

    -- Fecha ao clicar fora
    UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if self._isOpen then
                local mousePos = UserInputService:GetMouseLocation()
                local menuPos  = menu.AbsolutePosition
                local menuSize = menu.AbsoluteSize
                local inMenu   = mousePos.X >= menuPos.X and mousePos.X <= menuPos.X + menuSize.X
                             and mousePos.Y >= menuPos.Y and mousePos.Y <= menuPos.Y + menuSize.Y
                local inHead   = mousePos.X >= head.AbsolutePosition.X
                             and mousePos.Y >= head.AbsolutePosition.Y

                if not inMenu and not inHead then
                    self:_close()
                end
            end
        end
    end)

    return self
end

function Dropdown:_buildOptions(opts)
    local theme = getgenv().Nexus.UI.Theme

    -- Limpa lista atual
    for _, child in ipairs(self._listFrame:GetChildren()) do
        if child:IsA("Frame") or child:IsA("TextButton") then
            child:Destroy()
        end
    end

    local maxVisible = 5
    local itemH      = 28

    for _, opt in ipairs(opts) do
        local item = Instance.new("TextButton")
        item.Size              = UDim2.new(1, 0, 0, itemH)
        item.BackgroundColor3  = opt == self._value and theme.SurfaceActive or theme.Surface
        item.BorderSizePixel   = 0
        item.Text              = opt
        item.Font              = theme.FontBody
        item.TextSize          = theme.FontSizeBody
        item.TextColor3        = opt == self._value and theme.TextAccent or theme.TextPrimary
        item.TextXAlignment    = Enum.TextXAlignment.Left
        item.AutoButtonColor   = false
        item.ZIndex            = 11
        item.Parent            = self._listFrame

        local itemPad = Instance.new("UIPadding")
        itemPad.PaddingLeft = UDim.new(0, 10)
        itemPad.Parent = item

        item.MouseEnter:Connect(function()
            if opt ~= self._value then
                item.BackgroundColor3 = theme.SurfaceHover
            end
        end)

        item.MouseLeave:Connect(function()
            if opt ~= self._value then
                item.BackgroundColor3 = theme.Surface
            end
        end)

        item.MouseButton1Click:Connect(function()
            self:SetValue(opt)
            self:_close()
        end)
    end

    -- Ajusta altura do menu
    local listH = math.min(#opts, maxVisible) * itemH
    local searchOffset = self._search and 30 or 0
    self._targetH = listH + searchOffset
end

function Dropdown:_open()
    local theme = getgenv().Nexus.UI.Theme
    self._isOpen = true
    self._menu.Visible = true

    TweenService:Create(self._menu, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(1, 0, 0, self._targetH or 140)
    }):Play()

    TweenService:Create(self._headStroke, TweenInfo.new(0.15), {
        Color = theme.BorderAccent
    }):Play()

    self._arrow.Text = "▴"
end

function Dropdown:_close()
    local theme = getgenv().Nexus.UI.Theme
    self._isOpen = false

    TweenService:Create(self._menu, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Size = UDim2.new(1, 0, 0, 0)
    }):Play()

    task.delay(0.15, function()
        if not self._isOpen then
            self._menu.Visible = false
        end
    end)

    TweenService:Create(self._headStroke, TweenInfo.new(0.15), {
        Color = theme.Border
    }):Play()

    self._arrow.Text = "▾"
end

function Dropdown:SetValue(value)
    self._value = value
    self._currentVal.Text = value

    if self._key and getgenv().Nexus.Config then
        getgenv().Nexus.Config:Set(self._key, value)
    end

    if self._onChange then
        task.spawn(self._onChange, value)
    end

    -- Atualiza visual dos itens
    for _, item in ipairs(self._listFrame:GetChildren()) do
        if item:IsA("TextButton") then
            local theme = getgenv().Nexus.UI.Theme
            local isSelected = item.Text == value
            item.BackgroundColor3 = isSelected and theme.SurfaceActive or theme.Surface
            item.TextColor3       = isSelected and theme.TextAccent or theme.TextPrimary
        end
    end
end

function Dropdown:GetValue()
    return self._value
end

function Dropdown:SetOptions(opts)
    self._options = opts
    self:_buildOptions(opts)
end

function Dropdown:Destroy()
    if self._root then self._root:Destroy() end
end

return Dropdown