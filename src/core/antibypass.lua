-- src/core/antibypass.lua
-- Меры защиты от ACE в контексте Lua-PAK подхода
local M = {}

local FormatLog = FuncUtil.FormatLog

-- === 1. тихий лог ===
-- Ничего узнаваемого в логкат. Только нейтральные префиксы.
function M.log(msg)
    -- отключено в релизе
    -- FormatLog("[PerfStat] %s", tostring(msg))
end

-- === 2. чистка следов в runtime ===
function M.scrub_traces()
    -- чистим наш loader и все HH_* из require-кеша
    if package and package.loaded then
        for k, _ in pairs(package.loaded) do
            if type(k) == "string" and k:find("HH_", 1, true) then
                package.loaded[k] = nil
            end
        end
    end

    -- убираем глобал с ctx
    _G._HH_CTX = nil

    -- отключаем прямой require по нашим путям
    if _G.require then
        local _orig = _G.require
        _G.require = function(name)
            if type(name) == "string" and name:find("HH_", 1, true) then
                return nil
            end
            return _orig(name)
        end
    end
end

-- === 3. маскировка логов ===
-- Перехватываем SecurityCommonUtils.LogIf — если ACE читает через неё,
-- видит только нейтральные сообщения.
function M.mask_logs()
    local ok, Security = pcall(require, "GameLua.Mod.BaseMod.Common.Security.SecurityCommonUtils")
    if not ok or not Security or not Security.LogIf then return end
    local _orig = Security.LogIf
    Security.LogIf = function(cond, msg)
        if type(msg) == "string" and msg:find("HH", 1, true) then
            return false
        end
        return _orig(cond, msg)
    end
end

-- === 4. джиттер углов ===
-- Aim: микро-отклонения, чтобы не было идеально прямых линий.
function M.jitter_rotation(rot, strength)
    strength = strength or 0.15
    local function j() return (math.random() - 0.5) * strength end
    return FRotator(rot.Pitch + j(), rot.Yaw + j(), rot.Roll + j())
end

-- === 5. задержка активации ===
-- Не "включается" сразу после старта. Первые 3 секунды — только наблюдение.
local _activated_at = nil
function M.can_act()
    if not _activated_at then
        _activated_at = os.clock()
        return false
    end
    return (os.clock() - _activated_at) > 3.0
end

-- === 6. guard на аномальную активность ===
-- Если за секунду вызывают наш код >500 раз — что-то не так, вырубаемся.
local _external_calls = 0
local _last_reset = os.time()
function M.tick_guard()
    if os.time() - _last_reset > 1 then
        _external_calls = 0
        _last_reset = os.time()
    end
    _external_calls = _external_calls + 1
    if _external_calls > 500 then
        _G._HH_PANIC = true
    end
end

-- === 7. анти-снап детектор ===
-- Следим за резкими изменениями углов. Если aimbot даёт слишком резкий
-- поворот — глушим его на 2 секунды.
local _last_rot = nil
local _snap_punish_until = 0
function M.check_snap(cur_rot)
    if not cur_rot or not _last_rot then
        _last_rot = cur_rot
        return true
    end
    local d_pitch = math.abs(cur_rot.Pitch - _last_rot.Pitch)
    local d_yaw   = math.abs(cur_rot.Yaw   - _last_rot.Yaw)
    if d_yaw > 180 then d_yaw = 360 - d_yaw end
    local delta = math.sqrt(d_pitch * d_pitch + d_yaw * d_yaw)

    _last_rot = cur_rot

    -- если за кадр повернулись больше 25 градусов — это снап
    if delta > 25 then
        _snap_punish_until = os.clock() + 2.0
        return false
    end
    if os.clock() < _snap_punish_until then
        return false
    end
    return true
end

-- === 8. рандомизация таймингов ===
-- Цели не переключаются каждые N кадров ровно — с небольшим разбросом.
function M.rand_delay(base)
    base = base or 0.3
    return base + (math.random() * 0.2 - 0.1)
end

-- === 9. проверка состояния ===
function M.is_panicked()
    return _G._HH_PANIC == true
end

-- === 10. установка ===
function M.install(ctx)
    M.mask_logs()
    M.scrub_traces()
    FormatLog("[PerfStat] init ok")
end

return M
