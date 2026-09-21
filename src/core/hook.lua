-- src/core/hook.lua
local M = {}

function M.wrap(tbl, name, post)
    local orig = tbl[name]
    tbl[name] = function(self, ...)
        if orig then orig(self, ...) end
        return post(self, ...)
    end
end

function M.install(ctx)
    local PC = import("/Script/ShadowTrackerExtra.STExtraPlayerController")
    if PC and PC.ReceiveTick then
        M.wrap(PC, "ReceiveTick", function()
            ctx.esp.tick()
            ctx.chams.tick()
            ctx.aim.tick()
        end)
        FuncUtil.FormatLog("[HH] hooked ReceiveTick")
    else
        local sub = SubsystemMgr:Get("ClientHawkEyePatrolSubsystem")
        if sub then
            sub:AddGameTimer(0.016, true, function()
                ctx.esp.tick()
                ctx.chams.tick()
                ctx.aim.tick()
            end)
            FuncUtil.FormatLog("[HH] hooked via subsystem timer")
        end
    end
end

return M
