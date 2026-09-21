-- src/core/main.lua
local M = {}

function M.start(manifest, loader)
    local sdk    = loader.load("core/sdk.lua",    manifest)
    local hook   = loader.load("core/hook.lua",   manifest)
    local config = loader.load("core/config.lua", manifest)
    local esp    = loader.load("features/esp.lua",   manifest)
    local chams  = loader.load("features/chams.lua", manifest)
    local aim    = loader.load("features/aim.lua",   manifest)

    if not (sdk and hook and config) then
        FuncUtil.FormatLog("[HH] core modules failed")
        return
    end

    local ctx = {sdk = sdk, config = config, esp = esp, chams = chams, aim = aim}
    _G._HH_CTX = ctx

    config.init()
    if esp   and esp.init   then esp.init(ctx)   end
    if chams and chams.init then chams.init(ctx) end
    if aim   and aim.init   then aim.init(ctx)   end

    hook.install(ctx)

    FuncUtil.FormatLog("[HH] loaded ok")
end

return M
