-- Nexus Memory
-- Leitura e escrita de configuração persistente via writefile/readfile
-- Serialização em JSON com validação e fallback
-- @version 1.0.0

local HttpService = game:GetService("HttpService")

local Memory = {}
Memory._path    = "nexus_config.json"
Memory._saveTimer = nil
Memory._dirty   = false
Memory._debounce = 2 -- segundos antes de salvar após mudança

function Memory:SetPath(path)
    self._path = path
end

function Memory:Save(config)
    local ok, data = pcall(function()
        return HttpService:JSONEncode(config)
    end)

    if not ok then
        warn("[Nexus:Memory] Falha ao serializar config: " .. tostring(data))
        return false
    end

    local writeOk, writeErr = pcall(function()
        writefile(self._path, data)
    end)

    if not writeOk then
        warn("[Nexus:Memory] Falha ao salvar no disco: " .. tostring(writeErr))
        return false
    end

    self._dirty = false
    return true
end

-- Salva com debounce — evita thrash no disco ao mudar múltiplos toggles seguidos
function Memory:SaveDeferred(config)
    self._dirty = true
    if self._saveTimer then
        task.cancel(self._saveTimer)
    end
    self._saveTimer = task.delay(self._debounce, function()
        if self._dirty then
            self:Save(config)
        end
    end)
end

function Memory:Load()
    local exists = pcall(function()
        return isfile(self._path)
    end)

    if not exists then return {} end

    local ok, raw = pcall(function()
        return readfile(self._path)
    end)

    if not ok or not raw or raw == "" then return {} end

    local parseOk, data = pcall(function()
        return HttpService:JSONDecode(raw)
    end)

    if not parseOk or type(data) ~= "table" then
        warn("[Nexus:Memory] Config corrompida, usando padrão.")
        return {}
    end

    return data
end

function Memory:Delete()
    pcall(function()
        if isfile(self._path) then
            delfile(self._path)
        end
    end)
end

function Memory:Exists()
    local ok, result = pcall(function()
        return isfile(self._path)
    end)
    return ok and result
end

return Memory