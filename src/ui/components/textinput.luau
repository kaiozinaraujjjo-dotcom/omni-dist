-- Nexus TextInput Component
-- Campo de texto com placeholder, focus border, clear e callback
-- @version 1.0.0

local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local TextInput = {}
TextInput.__index = TextInput

function TextInput.new(parent, options)
    local self = setmetatable({}, TextInput)

    local theme  = getgenv().Nexus.UI.Theme
    local sounds = getgenv().Nexus.UI.Sounds
    local config = getgenv().Nexus.Config

    options         = options or {}
    self._label     = options.label       or "Input"
    self._key       = options.configKey
    self._onChange  = options.onChange
    self._onSubmit  = options.onSubmit
    self._numeric   = options.numeric     or false
    self._maxLen    = options.maxLength    or 100
    self._placeholder = options.placeholder or ""

    local defaultVal = options.default or ""
    if self._key and config then
        defaultVal = config:Get(self._key) or defaultVal
    end

    -- === ROOT ===
    local root = Instance.new("Frame")
    root.Name              = "TextInput_" .. self._label
    root.Size              = UDim2.new(1, 0, 0, theme.ElementHeight + 6)
    root.BackgroundTransparency = 1
    root.BorderSizePixel   = 0
    root.Parent            = parent
    self._root = root

    local labelText = Instance.new("TextLabel")
    labelText.Text           = self._label
    labelText.Font           = theme.FontBody
    labelText.TextSize       = theme.FontSizeSmall
    labelText.TextColor3     = theme.TextSecondary
    labelText.TextXAlignment = Enum.TextXAlignment.Left
    labelText.BackgroundTransparency = 1
    labelText.Size           = UDim2.new(1, 0, 0, 14)
    labelText.Position       = UDim2.new(0, 0, 0, 0)
    labelText.Parent         = root

    local inputFrame = Instance.new("Frame")
    inputFrame.Size            = UDim2.new(1, 0, 0, theme.ElementHeight)
    inputFrame.Position        = UDim2.new(0, 0, 0, 16)
    inputFrame.BackgroundColor3 = theme.InputBackground
    inputFrame.BorderSizePixel  = 0
    inputFrame.Parent          = root
    self._inputFrame = inputFrame

    local inputCorner = Instance.new("UICorner")
    inputCorner.CornerRadius = UDim.new(0, 6)
    inputCorner.Parent = inputFrame

    local inputStroke = Instance.new("UIStroke")
    inputStroke.Color     = theme.InputBorder
    inputStroke.Thickness = 1
    inputStroke.Parent    = inputFrame
    self._inputStroke = inputStroke

    local textBox = Instance.new("TextBox")
    textBox.Text              = defaultVal
    textBox.PlaceholderText   = self._placeholder
    textBox.PlaceholderColor3 = theme.TextDisabled
    textBox.Font              = theme.FontBody
    textBox.TextSize          = theme.FontSizeBody
    textBox.TextColor3        = theme.TextPrimary
    textBox.TextXAlignment    = Enum.TextXAlignment.Left
    textBox.BackgroundTransparency = 1
    textBox.Size              = UDim2.new(1, -36, 1, 0)
    textBox.Position          = UDim2.new(0, 10, 0, 0)
    textBox.ClearTextOnFocus  = false
    textBox.TextTruncate      = Enum.TextTruncate.AtEnd
    textBox.Parent            = inputFrame
    self._textBox = textBox

    -- Botão clear
    local clearBtn = Instance.new("TextButton")
    clearBtn.Size              = UDim2.new(0, 24, 0, 24)
    clearBtn.Position          = UDim2.new(1, -28, 0.5, -12)
    clearBtn.BackgroundTransparency = 1
    clearBtn.Text              = "✕"
    clearBtn.Font              = theme.FontBody
    clearBtn.TextSize          = 11
    clearBtn.TextColor3        = theme.TextDisabled
    clearBtn.Parent            = inputFrame

    clearBtn.MouseButton1Click:Connect(function()
        textBox.Text = ""
        self:_onChange_("")
    end)

    clearBtn.MouseEnter:Connect(function()
        clearBtn.TextColor3 = theme.TextPrimary
    end)
    clearBtn.MouseLeave:Connect(function()
        clearBtn.TextColor3 = theme.TextDisabled
    end)

    -- Focus
    textBox.Focused:Connect(function()
        TweenService:Create(inputStroke, TweenInfo.new(0.15), {
            Color = theme.InputBorderFocus
        }):Play()
        if sounds then sounds:Play("click") end
    end)

    textBox.FocusLost:Connect(function(enterPressed)
        TweenService:Create(inputStroke, TweenInfo.new(0.15), {
            Color = theme.InputBorder
        }):Play()
        if enterPressed and self._onSubmit then
            task.spawn(self._onSubmit, textBox.Text)
        end
    end)

    textBox:GetPropertyChangedSignal("Text"):Connect(function()
        local text = textBox.Text

        -- Limita caracteres
        if #text > self._maxLen then
            textBox.Text = text:sub(1, self._maxLen)
            return
        end

        -- Só números
        if self._numeric then
            local clean = text:gsub("[^%d%.%-]", "")
            if clean ~= text then
                textBox.Text = clean
                return
            end
        end

        self:_onChange_(text)
    end)

    return self
end

function TextInput:_onChange_(text)
    if self._key and getgenv().Nexus.Config then
        getgenv().Nexus.Config:Set(self._key, text)
    end
    if self._onChange then
        task.spawn(self._onChange, text)
    end
end

function TextInput:SetValue(text)
    self._textBox.Text = text
end

function TextInput:GetValue()
    return self._textBox.Text
end

function TextInput:Destroy()
    if self._root then self._root:Destroy() end
end

return TextInput