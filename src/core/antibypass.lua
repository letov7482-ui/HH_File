-- src/core/antibypass.lua
-- Меры защиты от ACE в контексте Lua-PAK подхода
local M = {}

local FormatLog = FuncUtil.FormatLog

-- === 1. тихий лог ===
-- Не пишем в логкат ничего с "HH", "cheat", "esp", "aim".
-- Только нейтральные префиксы, похожие на игровые.
local function silent_log(msg)
    -- отключено: оставляем только для отладки
    -- FormatLog("[PerfStat] %s", msg)
end
M.log = silent_log

-- === 2. очистка следов в runtime ===
function M.scrub_traces()
    -- чистим наш loader из package.loaded — если кто-то дампит require-кеш
    if package and package.loaded then
        package.loaded["HH_loader"] = nil
        for k, _ in pairs(package.loaded) do
            if type(k) == "string" and k:find("HH_", 1, true) then
                package.loaded[k] = nil
            end
        end
    end

    -- чистим _G от наших глобалов
    _G._HH_CTX = nil

    -- подменяем наш require-путь на пустышку
    if _G.require then
        local _orig_req = _G.require
        _G.require = function(name)
            if type(name) == "string" and name:find("HH_", 1, true) then
                return nil
            end
            return _orig_req(name)
        end
    end
end

-- === 3. маскировка имён ===
-- Перехватываем функцию LogIf у SecurityCommonUtils — если ACE читает
-- через неё, он видит только наши нейтральные сообщения.
function M.mask_logs()
    local Security = require("GameLua.Mod.BaseMod.Common.Security.SecurityCommonUtils")
    if Security and Security.LogIf then
        local _orig = Security.LogIf
        Security.LogIf = function(cond, msg)
            if type(msg) == "string" and msg:find("HH", 1, true) then
                return false
            end
            return _orig(cond, msg)
        end
    end
end

-- === 4. защита от deletion при старте ===
-- Если игра удаляет наш PAK из puffer_temp, мы не можем это изменить из Lua.
-- Но можем проверить и записать маркер — если PAK удалён, loader не стартует,
-- значит ситуация не изменится. Обходится только на уровне PAK-упаковки:
--   - имя совпадает с ожидаемым game_patch_*.pak
--   - .sig либо отсутствует, либо валиден
-- Это должно быть настроено в build/pack.py, не в runtime.

-- === 5. рандомизация поведения ===
-- Aim: добавляем микро-джиттер в углы, чтобы не было идеально прямых линий
function M.jitter_rotation(rot, strength)
    strength = strength or 0.15
    local function j() return (math.random() - 0.5) * strength end
    return FRotator(rot.Pitch + j(), rot.Yaw + j(), rot.Roll + j())
end

-- Задержка перед первым действием (aimbot) — чтобы не "включился" сразу
local _activated_at = nil
function M.can_act()
    if not _activated_at then
        _activated_at = os.clock()
        return false
    end
    return (os.clock() - _activated_at) > 3.0
end

-- === 6. anti-screenshot / anti-detection ===
-- Если в процессе появляется подозрение, что ACE сканирует —
-- можем временно отключить фичи. Признаки:
--   - внезапный профайлинг (много вызовов GetComponentsByClass)
--   - чанки памяти игры сбрасываются
-- Простая эвристика: если >10 раз за секунду вызывают наш код извне — стоп.
local _external_calls = 0
local _last_reset = os.time()
function M.tick_guard()
    if os.time() - _last_reset > 1 then
        _external_calls = 0
        _last_reset = os.time()
    end
    _external_calls = _external_calls + 1
    if _external_calls > 500 then
        -- что-то не так, вырубаемся
        _G._HH_PANIC = true
    end
end

function M.install(ctx)
    M.mask_logs()
    M.scrub_traces()
    FuncUtil.FormatLog("[PerfStat] init ok")  -- нейтральный текст
end

return M
