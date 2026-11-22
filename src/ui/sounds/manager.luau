-- Nexus Sound Manager
-- Gerencia todos os sons da UI com volume global e toggles individuais
-- @version 1.0.0

local SoundService = game:GetService("SoundService")

local SoundManager = {}
SoundManager._sounds  = {}
SoundManager._volume  = 0.6
SoundManager._enabled = true

-- IDs dos sons (Roblox asset IDs)
-- Substitua pelos IDs reais que você quiser usar
local SOUND_IDS = {
    hover      = "rbxassetid://6026984224",
    click      = "rbxassetid://6026984224",
    toggle_on  = "rbxassetid://6042053626",
    toggle_off = "rbxassetid://6042053626",
    open       = "rbxassetid://6026984224",
    close      = "rbxassetid://6026984224",
    notify     = "rbxassetid://6042053626",
    success    = "rbxassetid://6042053626",
    warning    = "rbxassetid://6042053626",
    error      = "rbxassetid://6042053626",
}

-- Configurações individuais por som
local SOUND_CONFIG = {
    hover      = { volume = 0.3, pitch = 1.0  },
    click      = { volume = 0.5, pitch = 1.0  },
    toggle_on  = { volume = 0.5, pitch = 1.1  },
    toggle_off = { volume = 0.4, pitch = 0.9  },
    open       = { volume = 0.5, pitch = 1.0  },
    close      = { volume = 0.4, pitch = 0.95 },
    notify     = { volume = 0.5, pitch = 1.0  },
    success    = { volume = 0.5, pitch = 1.2  },
    warning    = { volume = 0.5, pitch = 0.9  },
    error      = { volume = 0.5, pitch = 0.8  },
}

function SoundManager:Init(config)
    if config then
        self._volume  = config:Get("ui_volume") or 0.6
        self._enabled = true
    end

    -- Pré-carrega todos os sons numa pasta oculta
    local folder = Instance.new("Folder")
    folder.Name   = "NexusSounds"
    folder.Parent = SoundService

    for name, id in pairs(SOUND_IDS) do
        local cfg   = SOUND_CONFIG[name] or { volume = 0.5, pitch = 1.0 }
        local sound = Instance.new("Sound")
        sound.Name        = name
        sound.SoundId     = id
        sound.Volume      = cfg.volume * self._volume
        sound.PlaybackSpeed = cfg.pitch
        sound.RollOffMaxDistance = 0
        sound.Parent      = folder
        self._sounds[name] = sound
    end

    self._folder = folder

    -- Observa mudanças de volume na config
    if config then
        config:OnChange("ui_volume", function(val)
            self:SetVolume(val)
        end)
    end
end

function SoundManager:Play(name)
    if not self._enabled then return end

    local config = getgenv().Nexus and getgenv().Nexus.Config
    if config and config:Get("sound_" .. name) == false then return end

    local sound = self._sounds[name]
    if not sound then return end

    -- Clona e toca para evitar sobreposição
    local clone = sound:Clone()
    clone.Parent = sound.Parent
    clone:Play()

    task.delay(clone.TimeLength + 0.1, function()
        if clone and clone.Parent then
            clone:Destroy()
        end
    end)
end

function SoundManager:SetVolume(vol)
    self._volume = math.clamp(vol, 0, 1)

    for name, sound in pairs(self._sounds) do
        local cfg = SOUND_CONFIG[name] or { volume = 0.5 }
        sound.Volume = cfg.volume * self._volume
    end
end

function SoundManager:SetEnabled(enabled)
    self._enabled = enabled
end

function SoundManager:Destroy()
    if self._folder then
        self._folder:Destroy()
    end
    self._sounds = {}
end

return SoundManager