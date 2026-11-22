-- Nexus Theme — Default (Black & Purple)
-- Todas as cores e espaçamentos do tema padrão
-- @version 1.0.0

return {
    -- === BACKGROUNDS ===
    Background      = Color3.fromHex("0A0A0F"),   -- janela principal
    BackgroundAlt   = Color3.fromHex("0F0F18"),   -- sidebar / header
    Surface         = Color3.fromHex("13131E"),   -- cards, toggles, inputs
    SurfaceHover    = Color3.fromHex("1A1A28"),   -- hover em elementos
    SurfaceActive   = Color3.fromHex("1F1F30"),   -- elemento ativo/selecionado

    -- === BORDAS ===
    Border          = Color3.fromHex("2A2A45"),   -- borda padrão
    BorderAccent    = Color3.fromHex("7B2FBE"),   -- borda accent roxa
    BorderSubtle    = Color3.fromHex("1E1E30"),   -- borda muito sutil

    -- === ACCENT ===
    Accent          = Color3.fromHex("7B2FBE"),   -- roxo principal
    AccentHover     = Color3.fromHex("9B4FDE"),   -- roxo hover
    AccentDim       = Color3.fromHex("4A1A80"),   -- roxo escuro (trilha toggle off)
    AccentGlow      = Color3.fromHex("7B2FBE"),   -- cor do glow (UIStroke)

    -- === TEXTO ===
    TextPrimary     = Color3.fromHex("FFFFFF"),   -- texto principal
    TextSecondary   = Color3.fromHex("9090B0"),   -- texto secundário / labels
    TextDisabled    = Color3.fromHex("4A4A6A"),   -- texto desabilitado
    TextAccent      = Color3.fromHex("B060FF"),   -- texto accent

    -- === STATUS ===
    Success         = Color3.fromHex("3EBE6A"),
    Warning         = Color3.fromHex("E0A83E"),
    Error           = Color3.fromHex("E03E3E"),
    Info            = Color3.fromHex("3E9EE0"),

    -- === COMPONENTES ===
    ToggleOn        = Color3.fromHex("7B2FBE"),
    ToggleOff       = Color3.fromHex("2A2A45"),
    ToggleThumb     = Color3.fromHex("FFFFFF"),
    SliderTrack     = Color3.fromHex("2A2A45"),
    SliderFill      = Color3.fromHex("7B2FBE"),
    SliderThumb     = Color3.fromHex("FFFFFF"),
    InputBackground = Color3.fromHex("0F0F18"),
    InputBorder     = Color3.fromHex("2A2A45"),
    InputBorderFocus= Color3.fromHex("7B2FBE"),
    ButtonBackground= Color3.fromHex("7B2FBE"),
    ButtonHover     = Color3.fromHex("9B4FDE"),
    ButtonText      = Color3.fromHex("FFFFFF"),
    TabActive       = Color3.fromHex("7B2FBE"),
    TabInactive     = Color3.fromHex("13131E"),
    TabText         = Color3.fromHex("9090B0"),
    TabTextActive   = Color3.fromHex("FFFFFF"),
    ScrollBar       = Color3.fromHex("2A2A45"),
    ScrollBarHover  = Color3.fromHex("7B2FBE"),

    -- === DIMENSÕES ===
    WindowWidth     = 580,
    WindowHeight    = 400,
    SidebarWidth    = 130,
    HeaderHeight    = 36,
    CornerRadius    = UDim.new(0, 8),
    ElementPadding  = 6,
    ElementHeight   = 32,
    SectionPadding  = 12,

    -- === FONTES ===
    FontTitle       = Enum.Font.GothamBold,
    FontBody        = Enum.Font.Gotham,
    FontMono        = Enum.Font.Code,
    FontSizeTitle   = 15,
    FontSizeBody    = 13,
    FontSizeMono    = 12,
    FontSizeSmall   = 11,

    -- === TRANSPARÊNCIA / GLOW ===
    GlowTransparency    = 0.6,
    GlowSize            = 4,
    BackgroundTransparency = 0,
}