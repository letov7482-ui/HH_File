-- src/core/main.lua
local M = {}

function M.start(manifest, loader)
    local sdk    = loader.load("core/sdk.lua",    manifest)
    local hook   = loader.load("core/hook.lua",   manifest)
    local config = loader.load("core/config.lua", manifest)
    local esp    = loader.load("features/esp.lua",   manifest)
    local chams  = loader.load("features/chams.lua", manifest)
    local aim    = loader.load("features/aim.lua",   manifest)
    local menu   = loader.load("menu/menu.lua",      manifest)

    if not (sdk and hook and config) then
        FuncUtil.FormatLog("[HH] core modules failed")
        return
    end

    local ctx = {sdk = sdk, config = config, esp = esp, chams = chams, aim = aim}
    config.init()
    esp.init(ctx)
    chams.init(ctx)
    aim.init(ctx)
    menu.init(ctx)
    hook.install(ctx)

    FuncUtil.FormatLog("[HH] loaded ok")
end

return M
