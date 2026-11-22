-- Nexus UI Init
-- Monta a janela principal, sidebar de tabs, área de conteúdo
-- Gerencia abertura/fechamento, notificações e tema
-- @version 1.0.0

local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players          = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

local RAW_BASE = "https://raw.githubusercontent.com/kaiozinaraujjjo-dotcom/omni-dist/main/src/"

local function req(path)
    return loadstring(game:HttpGet(RAW_BASE .. path))()
end

local UI = {}
UI.Theme       = nil
UI.Sounds      = nil
UI.Open        = false
UI.Tabs        = {}
UI.ActiveTab   = nil
UI.Notifications = {}

local OPEN_TWEEN  = TweenInfo.new(0.35, Enum.EasingStyle.Back,  Enum.EasingDirection.Out)
local CLOSE_TWEEN = TweenInfo.new(0.25, Enum.EasingStyle.Quad,  Enum.EasingDirection.In)
local NOTIF_TWEEN = TweenInfo.new(0.3,  Enum.EasingStyle.Quad,  Enum.EasingDirection.Out)

function UI:Init()
    -- Carrega tema
    self.Theme  = req("ui/theme/default.luau")
    local theme = self.Theme

    -- ScreenGui raiz
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name               = "NexusMenu"
    screenGui.ResetOnSpawn       = false
    screenGui.ZIndexBehavior     = Enum.ZIndexBehavior.Sibling
    screenGui.IgnoreGuiInset     = true
    screenGui.Parent             = PlayerGui
    self._screenGui = screenGui

    -- Janela principal
    local window = Instance.new("Frame")
    window.Name              = "Window"
    window.Size              = UDim2.new(0, theme.WindowWidth, 0, theme.WindowHeight)
    window.Position          = UDim2.new(0.5, -theme.WindowWidth / 2, 0.5, -theme.WindowHeight / 2)
    window.BackgroundColor3  = theme.Background
    window.BorderSizePixel   = 0
    window.AnchorPoint       = Vector2.new(0.5, 0.5)
    window.Visible           = false
    window.Parent            = screenGui
    self._window = window

    -- Cantos arredondados
    local windowCorner = Instance.new("UICorner")
    windowCorner.CornerRadius = theme.CornerRadius
    windowCorner.Parent = window

    -- Borda accent
    local stroke = Instance.new("UIStroke")
    stroke.Color     = theme.BorderAccent
    stroke.Thickness = 1.5
    stroke.Transparency = 0.4
    stroke.Parent    = window
    self._stroke = stroke

    -- Glow pulsante (loop de tween)
    task.spawn(function()
        while window and window.Parent do
            TweenService:Create(stroke, TweenInfo.new(1.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                Transparency = 0.7
            }):Play()
            task.wait(1.8)
            TweenService:Create(stroke, TweenInfo.new(1.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                Transparency = 0.2
            }):Play()
            task.wait(1.8)
        end
    end)

    -- === HEADER ===
    local header = Instance.new("Frame")
    header.Name             = "Header"
    header.Size             = UDim2.new(1, 0, 0, theme.HeaderHeight)
    header.BackgroundColor3 = theme.BackgroundAlt
    header.BorderSizePixel  = 0
    header.Parent           = window

    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = theme.CornerRadius
    headerCorner.Parent = header

    -- Bloco inferior do header (fica por cima do radius do footer)
    local headerFix = Instance.new("Frame")
    headerFix.Size            = UDim2.new(1, 0, 0, theme.CornerRadius.Offset)
    headerFix.Position        = UDim2.new(0, 0, 1, -theme.CornerRadius.Offset)
    headerFix.BackgroundColor3 = theme.BackgroundAlt
    headerFix.BorderSizePixel  = 0
    headerFix.Parent          = header

    -- Título
    local title = Instance.new("TextLabel")
    title.Text           = "NEXUS"
    title.Font           = theme.FontTitle
    title.TextSize       = theme.FontSizeTitle
    title.TextColor3     = theme.TextPrimary
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.BackgroundTransparency = 1
    title.Size           = UDim2.new(0.5, 0, 1, 0)
    title.Position       = UDim2.new(0, 14, 0, 0)
    title.Parent         = header

    -- Versão
    local version = Instance.new("TextLabel")
    version.Text           = "v" .. getgenv().Nexus.Version
    version.Font           = theme.FontBody
    version.TextSize       = theme.FontSizeSmall
    version.TextColor3     = theme.TextSecondary
    version.TextXAlignment = Enum.TextXAlignment.Right
    version.BackgroundTransparency = 1
    version.Size           = UDim2.new(0.5, -14, 1, 0)
    version.Position       = UDim2.new(0.5, 0, 0, 0)
    version.Parent         = header

    -- Drag
    local dragging, dragStart, windowStart = false, nil, nil

    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging    = true
            dragStart   = input.Position
            windowStart = window.Position
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            window.Position = UDim2.new(
                windowStart.X.Scale,
                windowStart.X.Offset + delta.X,
                windowStart.Y.Scale,
                windowStart.Y.Offset + delta.Y
            )
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    -- === SIDEBAR ===
    local sidebar = Instance.new("Frame")
    sidebar.Name             = "Sidebar"
    sidebar.Size             = UDim2.new(0, theme.SidebarWidth, 1, -theme.HeaderHeight)
    sidebar.Position         = UDim2.new(0, 0, 0, theme.HeaderHeight)
    sidebar.BackgroundColor3 = theme.BackgroundAlt
    sidebar.BorderSizePixel  = 0
    sidebar.Parent           = window
    self._sidebar = sidebar

    -- Separador vertical
    local divider = Instance.new("Frame")
    divider.Size            = UDim2.new(0, 1, 1, -theme.HeaderHeight)
    divider.Position        = UDim2.new(0, theme.SidebarWidth, 0, theme.HeaderHeight)
    divider.BackgroundColor3 = theme.Border
    divider.BorderSizePixel  = 0
    divider.Parent          = window

    local sidebarList = Instance.new("UIListLayout")
    sidebarList.Padding         = UDim.new(0, 2)
    sidebarList.SortOrder       = Enum.SortOrder.LayoutOrder
    sidebarList.Parent          = sidebar

    local sidebarPad = Instance.new("UIPadding")
    sidebarPad.PaddingTop    = UDim.new(0, 8)
    sidebarPad.PaddingLeft   = UDim.new(0, 6)
    sidebarPad.PaddingRight  = UDim.new(0, 6)
    sidebarPad.Parent        = sidebar

    -- === CONTENT AREA ===
    local content = Instance.new("ScrollingFrame")
    content.Name                 = "Content"
    content.Size                 = UDim2.new(1, -theme.SidebarWidth - 2, 1, -theme.HeaderHeight)
    content.Position             = UDim2.new(0, theme.SidebarWidth + 2, 0, theme.HeaderHeight)
    content.BackgroundTransparency = 1
    content.BorderSizePixel      = 0
    content.ScrollBarThickness   = 3
    content.ScrollBarImageColor3 = theme.ScrollBar
    content.CanvasSize           = UDim2.new(0, 0, 0, 0)
    content.AutomaticCanvasSize  = Enum.AutomaticSize.Y
    content.Parent               = window
    self._content = content

    local contentPad = Instance.new("UIPadding")
    contentPad.PaddingTop    = UDim.new(0, 10)
    contentPad.PaddingLeft   = UDim.new(0, 12)
    contentPad.PaddingRight  = UDim.new(0, 12)
    contentPad.PaddingBottom = UDim.new(0, 10)
    contentPad.Parent        = content

    local contentList = Instance.new("UIListLayout")
    contentList.Padding   = UDim.new(0, theme.ElementPadding)
    contentList.SortOrder = Enum.SortOrder.LayoutOrder
    contentList.Parent    = content

    -- === NOTIFICAÇÕES ===
    local notifHolder = Instance.new("Frame")
    notifHolder.Name                = "Notifications"
    notifHolder.Size                = UDim2.new(0, 280, 1, 0)
    notifHolder.Position            = UDim2.new(1, -290, 0, 0)
    notifHolder.BackgroundTransparency = 1
    notifHolder.Parent              = screenGui

    local notifList = Instance.new("UIListLayout")
    notifList.VerticalAlignment = Enum.VerticalAlignment.Bottom
    notifList.Padding           = UDim.new(0, 6)
    notifList.SortOrder         = Enum.SortOrder.LayoutOrder
    notifList.Parent            = notifHolder
    self._notifHolder = notifHolder

    -- === KEYBIND ABERTURA ===
    local config = getgenv().Nexus.Config
    local openKey = config and config:Get("ui_open_key") or "Insert"

    UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == Enum.KeyCode[openKey] then
            self:Toggle()
        end
    end)

    -- Carrega config de posição salva
    if config then
        local sx = config:Get("ui_x")
        local sy = config:Get("ui_y")
        if sx and sy then
            window.Position = UDim2.new(0, sx, 0, sy)
        end
    end

    self._sidebar  = sidebar
    self._content  = content
    self._sidebarList = sidebarList

    print("[Nexus:UI] Interface montada.")
end

function UI:AddTab(name, icon)
    local theme = self.Theme

    -- Botão de tab na sidebar
    local btn = Instance.new("TextButton")
    btn.Name             = "Tab_" .. name
    btn.Size             = UDim2.new(1, 0, 0, 30)
    btn.BackgroundColor3 = theme.TabInactive
    btn.BorderSizePixel  = 0
    btn.Text             = (icon and icon .. "  " or "") .. name
    btn.Font             = theme.FontBody
    btn.TextSize         = theme.FontSizeBody
    btn.TextColor3       = theme.TabText
    btn.TextXAlignment   = Enum.TextXAlignment.Left
    btn.AutoButtonColor  = false
    btn.Parent           = self._sidebar

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = btn

    local btnPad = Instance.new("UIPadding")
    btnPad.PaddingLeft = UDim.new(0, 10)
    btnPad.Parent = btn

    -- Área de conteúdo da tab (fica escondida até ser ativada)
    local tabContent = Instance.new("Frame")
    tabContent.Name                = "TabContent_" .. name
    tabContent.Size                = UDim2.new(1, 0, 0, 0)
    tabContent.AutomaticSize       = Enum.AutomaticSize.Y
    tabContent.BackgroundTransparency = 1
    tabContent.Visible             = false
    tabContent.BorderSizePixel     = 0
    tabContent.Parent              = self._content

    local tab = {
        name    = name,
        button  = btn,
        content = tabContent,
    }

    btn.MouseButton1Click:Connect(function()
        self:SelectTab(name)
    end)

    btn.MouseEnter:Connect(function()
        if self.ActiveTab ~= name then
            TweenService:Create(btn, TweenInfo.new(0.15), {
                BackgroundColor3 = theme.SurfaceHover
            }):Play()
        end
    end)

    btn.MouseLeave:Connect(function()
        if self.ActiveTab ~= name then
            TweenService:Create(btn, TweenInfo.new(0.15), {
                BackgroundColor3 = theme.TabInactive
            }):Play()
        end
    end)

    self.Tabs[name] = tab

    -- Seleciona automaticamente a primeira tab
    if not self.ActiveTab then
        self:SelectTab(name)
    end

    return tabContent
end

function UI:SelectTab(name)
    local theme = self.Theme

    for tabName, tab in pairs(self.Tabs) do
        local isActive = tabName == name
        tab.content.Visible = isActive

        TweenService:Create(tab.button, TweenInfo.new(0.2), {
            BackgroundColor3 = isActive and theme.TabActive or theme.TabInactive,
            TextColor3       = isActive and theme.TabTextActive or theme.TabText,
        }):Play()
    end

    self.ActiveTab = name
end

function UI:Toggle()
    if self.Open then
        self:Close()
    else
        self:Show()
    end
end

function UI:Show()
    local theme = self.Theme
    self._window.Visible = true
    self._window.Size = UDim2.new(0, theme.WindowWidth * 0.85, 0, theme.WindowHeight * 0.85)

    TweenService:Create(self._window, OPEN_TWEEN, {
        Size = UDim2.new(0, theme.WindowWidth, 0, theme.WindowHeight),
    }):Play()

    self.Open = true
    if self.Sounds then self.Sounds:Play("open") end
end

function UI:Close()
    local theme = self.Theme

    local tween = TweenService:Create(self._window, CLOSE_TWEEN, {
        Size = UDim2.new(0, theme.WindowWidth * 0.85, 0, theme.WindowHeight * 0.85),
    })
    tween:Play()
    tween.Completed:Connect(function()
        self._window.Visible = false
    end)

    self.Open = false
    if self.Sounds then self.Sounds:Play("close") end

    -- Salva posição da janela
    local config = getgenv().Nexus.Config
    if config then
        config:Set("ui_x", self._window.Position.X.Offset)
        config:Set("ui_y", self._window.Position.Y.Offset)
    end
end

function UI:Notify(opts)
    local theme = self.Theme
    opts = opts or {}

    local typeColors = {
        success = theme.Success,
        warning = theme.Warning,
        error   = theme.Error,
        info    = theme.Info,
    }
    local accent = typeColors[opts.Type or "info"] or theme.Info

    local notif = Instance.new("Frame")
    notif.Size             = UDim2.new(1, 0, 0, 56)
    notif.BackgroundColor3 = theme.Surface
    notif.BorderSizePixel  = 0
    notif.Position         = UDim2.new(1, 10, 0, 0)
    notif.Parent           = self._notifHolder

    local notifCorner = Instance.new("UICorner")
    notifCorner.CornerRadius = UDim.new(0, 8)
    notifCorner.Parent = notif

    local notifStroke = Instance.new("UIStroke")
    notifStroke.Color     = accent
    notifStroke.Thickness = 1
    notifStroke.Parent    = notif

    local bar = Instance.new("Frame")
    bar.Size             = UDim2.new(0, 3, 1, 0)
    bar.BackgroundColor3 = accent
    bar.BorderSizePixel  = 0
    bar.Parent           = notif

    local barCorner = Instance.new("UICorner")
    barCorner.CornerRadius = UDim.new(0, 6)
    barCorner.Parent = bar

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Text           = opts.Title or "Nexus"
    titleLbl.Font           = theme.FontTitle
    titleLbl.TextSize       = theme.FontSizeBody
    titleLbl.TextColor3     = theme.TextPrimary
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.BackgroundTransparency = 1
    titleLbl.Size           = UDim2.new(1, -18, 0, 20)
    titleLbl.Position       = UDim2.new(0, 14, 0, 8)
    titleLbl.Parent         = notif

    local bodyLbl = Instance.new("TextLabel")
    bodyLbl.Text            = opts.Text or ""
    bodyLbl.Font            = theme.FontBody
    bodyLbl.TextSize        = theme.FontSizeSmall
    bodyLbl.TextColor3      = theme.TextSecondary
    bodyLbl.TextXAlignment  = Enum.TextXAlignment.Left
    bodyLbl.TextWrapped     = true
    bodyLbl.BackgroundTransparency = 1
    bodyLbl.Size            = UDim2.new(1, -18, 0, 20)
    bodyLbl.Position        = UDim2.new(0, 14, 0, 28)
    bodyLbl.Parent          = notif

    -- Slide in
    TweenService:Create(notif, NOTIF_TWEEN, {
        Position = UDim2.new(0, 0, 0, 0)
    }):Play()

    if self.Sounds then self.Sounds:Play("notify") end

    -- Auto dismiss
    task.delay(opts.Duration or 4, function()
        if notif and notif.Parent then
            local out = TweenService:Create(notif, TweenInfo.new(0.3), {
                Position = UDim2.new(1, 10, 0, 0)
            })
            out:Play()
            out.Completed:Connect(function()
                notif:Destroy()
            end)
        end
    end)
end

function UI:Destroy()
    if self._screenGui then
        self._screenGui:Destroy()
    end
end

return UI