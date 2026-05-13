-- [[ OMNI LOADER - PUBLIC GATEWAY ]] --
local function Load()
    -- Link para a versao ofuscada no repositorio publico
    local URL = "https://raw.githubusercontent.com/kaiozinaraujjjo-dotcom/omni-dist/main/Omni_protected.lua"
    
    local ok, content = pcall(function() return game:HttpGet(URL) end)
    if ok and content and #content > 500 then
        local func, err = loadstring(content)
        if func then
            task.spawn(func)
        else
            warn("[OMNI] Erro de carregamento.")
        end
    else
        warn("[OMNI] Falha ao conectar ao servidor.")
    end
end

if getgenv().OMNI_LOADED then return end
getgenv().OMNI_LOADED = true
task.spawn(Load)
