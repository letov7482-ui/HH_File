-- src/core/hook.lua
-- Перехват игрового цикла и игровых функций
local M = {}

local FormatLog = FuncUtil.FormatLog
local _installed = false

-- === утилита обёртки ===
function M.wrap(tbl, name, post)
    if not tbl or not tbl[name] then return false end
    local orig = tbl[name]
    tbl[name] = function(self, ...)
        local ok, err = pcall(orig, self, ...)
        if not ok then
            FormatLog("[PerfStat] wrap orig fail %s: %s", name, tostring(err))
        end
        return post(self, ...)
    end
    return true
end

-- === главный тик ===
local function tick_all(ctx)
    -- паника — стоп всему
    if _G._HH_PANIC then return end

    local ok, err = pcall(function()
        -- guard: следим за аномальной активностью
        if ctx.antibypass and ctx.antibypass.tick_guard then
            ctx.antibypass.tick_guard()
        end

        -- после guard мог сработать паника
        if _G._HH_PANIC then return end

        if ctx.esp   and ctx.esp.tick   then ctx.esp.tick()   end
        if ctx.chams and ctx.chams.tick then ctx.chams.tick() end
        if ctx.aim   and ctx.aim.tick   then ctx.aim.tick()   end
    end)

    if not ok then
        FormatLog("[PerfStat] tick fail: %s", tostring(err))
    end
end

-- === установка хука ===
function M.install(ctx)
    if _installed then
        FormatLog("[PerfStat] hook already installed")
        return
    end

    -- 1. ReceiveTick на PlayerController (лучший — каждый кадр)
    local PC = import("/Script/ShadowTrackerExtra.STExtraPlayerController")
    if PC and PC.ReceiveTick then
        local ok = M.wrap(PC, "ReceiveTick", function()
            tick_all(ctx)
        end)
        if ok then
            _installed = true
            FormatLog("[PerfStat] hooked PC.ReceiveTick")
            return
        end
    end

    -- 2. ReceiveTick на PlayerCharacter
    local PCh = import("STExtraPlayerCharacter")
    if PCh and PCh.ReceiveTick then
        local ok = M.wrap(PCh, "ReceiveTick", function()
            tick_all(ctx)
        end)
        if ok then
            _installed = true
            FormatLog("[PerfStat] hooked Character.ReceiveTick")
            return
        end
    end

    -- 3. Через HawkEyeDistanceUI:_RefreshUI (3 раза в секунду)
    local ok_req, HawkEyeDistanceUI = pcall(require,
        "GameLua.Mod.BaseMod.Client.Security.UI.HawkEyeDistanceUI")
    if ok_req and HawkEyeDistanceUI and HawkEyeDistanceUI._RefreshUI then
        local ok = M.wrap(HawkEyeDistanceUI, "_RefreshUI", function()
            tick_all(ctx)
        end)
        if ok then
            _installed = true
            FormatLog("[PerfStat] hooked HawkEyeDistanceUI")
            return
        end
    end

    -- 4. Через SubsystemMgr (таймер 30мс — медленно, но работает)
    local sub = SubsystemMgr:Get("ClientHawkEyePatrolSubsystem")
    if sub then
        sub:AddGameTimer(0.033, true, function()
            tick_all(ctx)
        end)
        _installed = true
        FormatLog("[PerfStat] hooked subsystem timer")
        return
    end

    FormatLog("[PerfStat] hook install failed — no path")
end

return M
