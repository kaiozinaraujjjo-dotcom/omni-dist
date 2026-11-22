-- Nexus Tooltip Component
-- Aparece após 0.4s de hover em qualquer elemento
-- @version 1.0.0

local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local Players          = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

local Tooltip = {}
Tooltip._instance = nil
Tooltip._hoverTimer = 0
Tooltip._hoverDelay = 0.4
Tooltip._active = false

-- Tooltip singleton — só um na tela de cada vez
function Tooltip:_ensureInstance()
    if self._instance and self._instance.Parent then return end

    local theme = getgenv().Nexus.UI.Theme

    local screenGui = PlayerGui:FindFirstChild("NexusMenu")
    if not screenGui then return end

    local frame = Instance.new("Frame")
    frame.Name              = "Tooltip"
    frame.BackgroundColor3  = theme.Surface
    frame.BorderSizePixel   = 0
    frame.AutomaticSize     = Enum.AutomaticSize.XY
    frame.Visible           = false
    frame.ZIndex            = 100
    frame.Parent            = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 5)
    corner.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.Color     = theme.Border
    stroke.Thickness = 1
    stroke.Parent    = frame

    local pad = Instance.new("UIPadding")
    pad.PaddingTop    = UDim.new(0, 5)
    pad.PaddingBottom = UDim.new(0, 5)
    pad.PaddingLeft   = UDim.new(0, 8)
    pad.PaddingRight  = UDim.new(0, 8)
    pad.Parent        = frame

    local text = Instance.new("TextLabel")
    text.Text              = ""
    text.Font              = getgenv().Nexus.UI.Theme.FontBody
    text.TextSize          = getgenv().Nexus.UI.Theme.FontSizeSmall
    text.TextColor3        = getgenv().Nexus.UI.Theme.TextSecondary
    text.TextWrapped       = true
    text.BackgroundTransparency = 1
    text.AutomaticSize     = Enum.AutomaticSize.XY
    text.Parent            = frame

    self._instance   = frame
    self._textLabel  = text

    -- Segue o mouse
    RunService.RenderStepped:Connect(function()
        if not self._instance or not self._instance.Visible then return end
        local mp = UserInputService:GetMouseLocation()
        self._instance.Position = UDim2.new(0, mp.X + 14, 0, mp.Y + 14)
    end)
end

function Tooltip:Attach(element, text)
    self:_ensureInstance()

    local hoverTimer  = 0
    local hovering    = false

    element.MouseEnter:Connect(function()
        hovering   = true
        hoverTimer = 0

        task.spawn(function()
            while hovering do
                task.wait(0.05)
                hoverTimer = hoverTimer + 0.05
                if hoverTimer >= self._hoverDelay then
                    self:Show(text)
                    break
                end
            end
        end)
    end)

    element.MouseLeave:Connect(function()
        hovering = false
        self:Hide()
    end)
end

function Tooltip:Show(text)
    self:_ensureInstance()
    if not self._instance then return end
    self._textLabel.Text    = text
    self._instance.Visible  = true
    self._instance.BackgroundTransparency = 1

    TweenService:Create(self._instance, TweenInfo.new(0.15), {
        BackgroundTransparency = 0
    }):Play()
end

function Tooltip:Hide()
    if not self._instance then return end
    self._instance.Visible = false
end

return Tooltip