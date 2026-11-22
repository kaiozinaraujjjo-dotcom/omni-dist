-- Nexus ColorPicker Component
-- Seletor HSV com caixa 2D, barra de hue, barra de alpha, campo hex e preview
-- @version 1.0.0

local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")

local ColorPicker = {}
ColorPicker.__index = ColorPicker

-- HSV <-> Color3
local function hsvToColor3(h, s, v)
    return Color3.fromHSV(h, s, v)
end

local function color3ToHsv(c)
    return Color3.toHSV(c)
end

local function color3ToHex(c)
    return string.format("%02X%02X%02X",
        math.floor(c.R * 255 + 0.5),
        math.floor(c.G * 255 + 0.5),
        math.floor(c.B * 255 + 0.5)
    )
end

local function hexToColor3(hex)
    hex = hex:gsub("#", "")
    if #hex ~= 6 then return nil end
    local ok, r, g, b = pcall(function()
        return tonumber(hex:sub(1,2), 16),
               tonumber(hex:sub(3,4), 16),
               tonumber(hex:sub(5,6), 16)
    end)
    if not ok or not r then return nil end
    return Color3.fromRGB(r, g, b)
end

function ColorPicker.new(parent, options)
    local self = setmetatable({}, ColorPicker)

    local theme  = getgenv().Nexus.UI.Theme
    local config = getgenv().Nexus.Config

    options       = options or {}
    self._label   = options.label   or "Cor"
    self._key     = options.configKey
    self._onChange = options.onChange
    self._alpha   = options.alpha   ~= false
    self._isOpen  = false

    local defaultColor = options.default or Color3.fromHex("7B2FBE")
    if self._key and config then
        local saved = config:Get(self._key)
        if saved then
            defaultColor = hexToColor3(saved) or defaultColor
        end
    end

    self._h, self._s, self._v = color3ToHsv(defaultColor)
    self._a = 1

    -- === ROOT ===
    local root = Instance.new("Frame")
    root.Name              = "ColorPicker_" .. self._label
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
    labelText.Size           = UDim2.new(1, -50, 1, 0)
    labelText.Position       = UDim2.new(0, 10, 0, 0)
    labelText.Parent         = root

    -- Preview swatch (clicável)
    local swatch = Instance.new("TextButton")
    swatch.Size             = UDim2.new(0, 28, 0, 20)
    swatch.Position         = UDim2.new(1, -38, 0.5, -10)
    swatch.BackgroundColor3 = defaultColor
    swatch.BorderSizePixel  = 0
    swatch.Text             = ""
    swatch.Parent           = root
    self._swatch = swatch

    local swatchCorner = Instance.new("UICorner")
    swatchCorner.CornerRadius = UDim.new(0, 4)
    swatchCorner.Parent = swatch

    local swatchStroke = Instance.new("UIStroke")
    swatchStroke.Color     = theme.Border
    swatchStroke.Thickness = 1
    swatchStroke.Parent    = swatch

    -- === PAINEL FLUTUANTE ===
    local panel = Instance.new("Frame")
    panel.Name             = "Panel"
    panel.Size             = UDim2.new(0, 220, 0, 220)
    panel.Position         = UDim2.new(1, 4, 0, 0)
    panel.BackgroundColor3 = theme.Surface
    panel.BorderSizePixel  = 0
    panel.Visible          = false
    panel.ZIndex           = 20
    panel.Parent           = root
    self._panel = panel

    local panelCorner = Instance.new("UICorner")
    panelCorner.CornerRadius = UDim.new(0, 8)
    panelCorner.Parent = panel

    local panelStroke = Instance.new("UIStroke")
    panelStroke.Color     = theme.BorderAccent
    panelStroke.Thickness = 1
    panelStroke.Parent    = panel

    local pad = Instance.new("UIPadding")
    pad.PaddingTop    = UDim.new(0, 10)
    pad.PaddingLeft   = UDim.new(0, 10)
    pad.PaddingRight  = UDim.new(0, 10)
    pad.PaddingBottom = UDim.new(0, 10)
    pad.Parent        = panel

    -- === CAIXA SV (Saturation / Value) ===
    local svBox = Instance.new("ImageLabel")
    svBox.Name             = "SVBox"
    svBox.Size             = UDim2.new(1, 0, 0, 140)
    svBox.BackgroundColor3 = Color3.new(1, 0, 0)
    svBox.BorderSizePixel  = 0
    svBox.Image            = "rbxassetid://6523286724" -- gradiente S/V
    svBox.ImageColor3      = hsvToColor3(self._h, 1, 1)
    svBox.Parent           = panel
    self._svBox = svBox

    local svCorner = Instance.new("UICorner")
    svCorner.CornerRadius = UDim.new(0, 4)
    svCorner.Parent = svBox

    -- Thumb SV
    local svThumb = Instance.new("Frame")
    svThumb.Size             = UDim2.new(0, 10, 0, 10)
    svThumb.AnchorPoint      = Vector2.new(0.5, 0.5)
    svThumb.BackgroundColor3 = Color3.new(1, 1, 1)
    svThumb.BorderSizePixel  = 0
    svThumb.ZIndex           = 21
    svThumb.Position         = UDim2.new(self._s, 0, 1 - self._v, 0)
    svThumb.Parent           = svBox
    self._svThumb = svThumb

    local svThumbCorner = Instance.new("UICorner")
    svThumbCorner.CornerRadius = UDim.new(1, 0)
    svThumbCorner.Parent = svThumb

    local svThumbStroke = Instance.new("UIStroke")
    svThumbStroke.Color     = Color3.new(1, 1, 1)
    svThumbStroke.Thickness = 1.5
    svThumbStroke.Parent    = svThumb

    -- === BARRA HUE ===
    local hueBar = Instance.new("ImageLabel")
    hueBar.Name             = "HueBar"
    hueBar.Size             = UDim2.new(1, 0, 0, 14)
    hueBar.Position         = UDim2.new(0, 0, 0, 148)
    hueBar.Image            = "rbxassetid://6523291402"
    hueBar.BorderSizePixel  = 0
    hueBar.Parent           = panel
    self._hueBar = hueBar

    local hueCorner = Instance.new("UICorner")
    hueCorner.CornerRadius = UDim.new(0, 4)
    hueCorner.Parent = hueBar

    local hueThumb = Instance.new("Frame")
    hueThumb.Size             = UDim2.new(0, 6, 1, 4)
    hueThumb.AnchorPoint      = Vector2.new(0.5, 0.5)
    hueThumb.BackgroundColor3 = Color3.new(1, 1, 1)
    hueThumb.BorderSizePixel  = 0
    hueThumb.ZIndex           = 21
    hueThumb.Position         = UDim2.new(self._h, 0, 0.5, 0)
    hueThumb.Parent           = hueBar
    self._hueThumb = hueThumb

    local hueThumbCorner = Instance.new("UICorner")
    hueThumbCorner.CornerRadius = UDim.new(0, 2)
    hueThumbCorner.Parent = hueThumb

    -- === CAMPO HEX + PREVIEW ===
    local bottomRow = Instance.new("Frame")
    bottomRow.Size             = UDim2.new(1, 0, 0, 28)
    bottomRow.Position         = UDim2.new(0, 0, 0, 170)
    bottomRow.BackgroundTransparency = 1
    bottomRow.Parent           = panel

    local previewNew = Instance.new("Frame")
    previewNew.Size            = UDim2.new(0, 24, 1, 0)
    previewNew.BackgroundColor3 = hsvToColor3(self._h, self._s, self._v)
    previewNew.BorderSizePixel  = 0
    previewNew.Parent           = bottomRow
    self._previewNew = previewNew

    local previewCorner = Instance.new("UICorner")
    previewCorner.CornerRadius = UDim.new(0, 4)
    previewCorner.Parent = previewNew

    local hexInput = Instance.new("TextBox")
    hexInput.Text              = "#" .. color3ToHex(defaultColor)
    hexInput.Font              = theme.FontMono
    hexInput.TextSize          = theme.FontSizeMono
    hexInput.TextColor3        = theme.TextPrimary
    hexInput.BackgroundColor3  = theme.InputBackground
    hexInput.BorderSizePixel   = 0
    hexInput.Size              = UDim2.new(1, -32, 1, 0)
    hexInput.Position          = UDim2.new(0, 30, 0, 0)
    hexInput.PlaceholderText   = "#RRGGBB"
    hexInput.PlaceholderColor3 = theme.TextDisabled
    hexInput.ClearTextOnFocus  = false
    hexInput.Parent            = bottomRow
    self._hexInput = hexInput

    local hexCorner = Instance.new("UICorner")
    hexCorner.CornerRadius = UDim.new(0, 4)
    hexCorner.Parent = hexInput

    -- === DRAG LÓGICA ===
    local draggingSV  = false
    local draggingHue = false

    local function updateFromSV()
        local color = hsvToColor3(self._h, self._s, self._v)
        self._previewNew.BackgroundColor3 = color
        self._swatch.BackgroundColor3     = color
        self._svThumb.Position = UDim2.new(self._s, 0, 1 - self._v, 0)
        self._hexInput.Text = "#" .. color3ToHex(color)
        if self._onChange then task.spawn(self._onChange, color) end
        if self._key and getgenv().Nexus.Config then
            getgenv().Nexus.Config:Set(self._key, color3ToHex(color))
        end
    end

    local function readSVMouse()
        local mp  = UserInputService:GetMouseLocation()
        local ap  = svBox.AbsolutePosition
        local as  = svBox.AbsoluteSize
        self._s   = math.clamp((mp.X - ap.X) / as.X, 0, 1)
        self._v   = 1 - math.clamp((mp.Y - ap.Y) / as.Y, 0, 1)
        updateFromSV()
    end

    local function readHueMouse()
        local mp = UserInputService:GetMouseLocation()
        local ap = hueBar.AbsolutePosition
        local as = hueBar.AbsoluteSize
        self._h  = math.clamp((mp.X - ap.X) / as.X, 0, 1)
        self._hueThumb.Position  = UDim2.new(self._h, 0, 0.5, 0)
        self._svBox.ImageColor3  = hsvToColor3(self._h, 1, 1)
        updateFromSV()
    end

    local svBtn = Instance.new("TextButton")
    svBtn.Size = UDim2.new(1, 0, 1, 0)
    svBtn.BackgroundTransparency = 1
    svBtn.Text = ""
    svBtn.ZIndex = 22
    svBtn.Parent = svBox

    local hueBtn = Instance.new("TextButton")
    hueBtn.Size = UDim2.new(1, 0, 1, 0)
    hueBtn.BackgroundTransparency = 1
    hueBtn.Text = ""
    hueBtn.ZIndex = 22
    hueBtn.Parent = hueBar

    svBtn.MouseButton1Down:Connect(function() draggingSV = true readSVMouse() end)
    hueBtn.MouseButton1Down:Connect(function() draggingHue = true readHueMouse() end)

    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            draggingSV  = false
            draggingHue = false
        end
    end)

    RunService.RenderStepped:Connect(function()
        if draggingSV  then readSVMouse()  end
        if draggingHue then readHueMouse() end
    end)

    -- Hex input confirmado
    hexInput.FocusLost:Connect(function()
        local raw = hexInput.Text:gsub("#", "")
        local color = hexToColor3(raw)
        if color then
            self._h, self._s, self._v = color3ToHsv(color)
            self._svBox.ImageColor3 = hsvToColor3(self._h, 1, 1)
            self._hueThumb.Position = UDim2.new(self._h, 0, 0.5, 0)
            updateFromSV()
        end
    end)

    -- === OPEN/CLOSE SWATCH ===
    swatch.MouseButton1Click:Connect(function()
        if self._isOpen then
            panel.Visible = false
            self._isOpen  = false
        else
            panel.Visible = true
            self._isOpen  = true
        end
    end)

    -- Fecha ao clicar fora
    UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and self._isOpen then
            local mp = UserInputService:GetMouseLocation()
            local pp = panel.AbsolutePosition
            local ps = panel.AbsoluteSize
            local inPanel = mp.X >= pp.X and mp.X <= pp.X + ps.X
                        and mp.Y >= pp.Y and mp.Y <= pp.Y + ps.Y
            local sp2 = swatch.AbsolutePosition
            local inSwatch = mp.X >= sp2.X and mp.X <= sp2.X + 28
                         and mp.Y >= sp2.Y and mp.Y <= sp2.Y + 20
            if not inPanel and not inSwatch then
                panel.Visible = false
                self._isOpen  = false
            end
        end
    end)

    return self
end

function ColorPicker:GetColor()
    return hsvToColor3(self._h, self._s, self._v)
end

function ColorPicker:SetColor(color)
    self._h, self._s, self._v = color3ToHsv(color)
    self._swatch.BackgroundColor3   = color
    self._previewNew.BackgroundColor3 = color
    self._svBox.ImageColor3 = hsvToColor3(self._h, 1, 1)
    self._svThumb.Position  = UDim2.new(self._s, 0, 1 - self._v, 0)
    self._hueThumb.Position = UDim2.new(self._h, 0, 0.5, 0)
    self._hexInput.Text = "#" .. color3ToHex(color)
end

function ColorPicker:Destroy()
    if self._root then self._root:Destroy() end
end

return ColorPicker