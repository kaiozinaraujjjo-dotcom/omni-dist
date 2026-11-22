-- Nexus Button Component
-- Botão com efeito ripple roxo, hover, som e callback
-- @version 1.0.0

local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Button = {}
Button.__index = Button

function Button.new(parent, options)
    local self = setmetatable({}, Button)

    local theme  = getgenv().Nexus.UI.Theme
    local sounds = getgenv().Nexus.UI.Sounds

    options       = options or {}
    self._label   = options.label   or "Button"
    self._onClick = options.onClick
    self._danger  = options.danger  or false

    local bgColor  = self._danger and theme.Error or theme.ButtonBackground
    local bgHover  = self._danger and Color3.fromHex("C02020") or theme.ButtonHover

    -- === ROOT ===
    local root = Instance.new("Frame")
    root.Name              = "Button_" .. self._label
    root.Size              = UDim2.new(1, 0, 0, theme.ElementHeight)
    root.BackgroundColor3  = bgColor
    root.BorderSizePixel   = 0
    root.ClipsDescendants  = true
    root.Parent            = parent
    self._root = root

    local rootCorner = Instance.new("UICorner")
    rootCorner.CornerRadius = UDim.new(0, 6)
    rootCorner.Parent = root

    -- Label
    local label = Instance.new("TextLabel")
    label.Text           = self._label
    label.Font           = theme.FontTitle
    label.TextSize       = theme.FontSizeBody
    label.TextColor3     = theme.ButtonText
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.BackgroundTransparency = 1
    label.Size           = UDim2.new(1, 0, 1, 0)
    label.ZIndex         = 2
    label.Parent         = root
    self._label_obj = label

    -- === DETECTOR ===
    local btn = Instance.new("TextButton")
    btn.Size                = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text                = ""
    btn.ZIndex              = 3
    btn.Parent              = root

    -- === HOVER ===
    btn.MouseEnter:Connect(function()
        TweenService:Create(root, TweenInfo.new(0.15), {
            BackgroundColor3 = bgHover
        }):Play()
        if sounds then sounds:Play("hover") end
    end)

    btn.MouseLeave:Connect(function()
        TweenService:Create(root, TweenInfo.new(0.15), {
            BackgroundColor3 = bgColor
        }):Play()
    end)

    -- === RIPPLE ===
    btn.MouseButton1Down:Connect(function(x, y)
        -- Calcula posição relativa ao frame
        local relX = x - root.AbsolutePosition.X
        local relY = y - root.AbsolutePosition.Y

        local ripple = Instance.new("Frame")
        ripple.Size              = UDim2.new(0, 0, 0, 0)
        ripple.AnchorPoint       = Vector2.new(0.5, 0.5)
        ripple.Position          = UDim2.new(0, relX, 0, relY)
        ripple.BackgroundColor3  = Color3.fromRGB(255, 255, 255)
        ripple.BackgroundTransparency = 0.7
        ripple.BorderSizePixel   = 0
        ripple.ZIndex            = 1
        ripple.Parent            = root

        local rippleCorner = Instance.new("UICorner")
        rippleCorner.CornerRadius = UDim.new(1, 0)
        rippleCorner.Parent = ripple

        -- Expande e some
        local maxSize = math.max(root.AbsoluteSize.X, root.AbsoluteSize.Y) * 2.5

        TweenService:Create(ripple, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, maxSize, 0, maxSize),
            BackgroundTransparency = 1,
        }):Play()

        task.delay(0.5, function()
            if ripple and ripple.Parent then
                ripple:Destroy()
            end
        end)

        if sounds then sounds:Play("click") end
    end)

    btn.MouseButton1Click:Connect(function()
        if self._onClick then
            task.spawn(self._onClick)
        end
    end)

    return self
end

function Button:SetLabel(text)
    self._label_obj.Text = text
end

function Button:SetEnabled(enabled)
    local theme = getgenv().Nexus.UI.Theme
    self._root.BackgroundTransparency = enabled and 0 or 0.5
    self._label_obj.TextColor3 = enabled and theme.ButtonText or theme.TextDisabled
end

function Button:Destroy()
    if self._root then self._root:Destroy() end
end

return Button