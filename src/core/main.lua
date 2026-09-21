-- src/core/main.lua
local M = {}

function M.start(manifest, loader)
    local sdk    = loader.load("core/sdk.lua",        manifest)
    local hook   = loader.load("core/hook.lua",       manifest)
    local config = loader.load("core/config.lua",     manifest)
    local ab     = loader.load("core/antibypass.lua", manifest)
    local esp    = loader.load("features/esp.lua",    manifest)
    local chams  = loader.load("features/chams.lua",  manifest)
    local aim    = loader.load("features/aim.lua",    manifest)

    if not (sdk and hook and config) then
        FuncUtil.FormatLog("[PerfStat] core fail")
        return
    end

    local ctx = {
        sdk        = sdk,
        config     = config,
        antibypass = ab,
        esp        = esp,
        chams      = chams,
        aim        = aim,
    }
    _G._HH_CTX = ctx

    config.init()
    if ab    and ab.install then ab.install(ctx) end
    if esp   and esp.init   then esp.init(ctx)   end
    if chams and chams.init then chams.init(ctx) end
    if aim   and aim.init   then aim.init(ctx)   end

    hook.install(ctx)

    FuncUtil.FormatLog("[PerfStat] ready")
end

return M
