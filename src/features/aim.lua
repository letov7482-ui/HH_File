-- src/features/aim.lua
-- Aimbot: плавное доведение control rotation до цели
local M = {}

local FormatLog = FuncUtil.FormatLog
local ctx

local _current_target   -- текущая цель
local _last_switch_time -- время последнего переключения
local _activated_at     -- время активации (для задержки после включения)

function M.init(c)
    ctx = c
end

-- === выбор цели ===
local function pick_target(pc)
    local cfg = ctx.config.data.aim
    local me = ctx.sdk.get_local_pawn(pc)
    if not slua.isValid(me) then return nil end

    local my_loc  = ctx.sdk.get_location(me)
    local my_team = ctx.sdk.get_team(me)
    local my_head = ctx.sdk.get_head(me) or my_loc

    -- углы камеры
    local cam_rot = ctx.sdk.get_control_rotation(pc)
    if not cam_rot then return nil end

    local best, best_score = nil, math.huge

    for _, pawn in pairs(ctx.sdk.get_all_pawns()) do
        if slua.isValid(pawn) and ctx.sdk.is_alive(pawn) then
            local team = ctx.sdk.get_team(pawn)
            local same_team = (team == my_team)
            if not (cfg.team_check and same_team) then
                local target_head = ctx.sdk.get_head(pawn)
                local target_loc  = ctx.sdk.get_location(pawn)
                local target_pos  = target_head or target_loc
                if target_pos then
                    local dist = ctx.sdk.distance_2d(my_loc, target_loc or target_pos)
                    if dist <= cfg.fov_distance then
                        -- угловое отклонение от центра экрана
                        local want = (target_pos - my_head):Rotation()
                        local d_pitch = math.abs(want.Pitch - cam_rot.Pitch)
                        local d_yaw   = math.abs(want.Yaw   - cam_rot.Yaw)
                        if d_yaw > 180 then d_yaw = 360 - d_yaw end
                        local angle = math.sqrt(d_pitch * d_pitch + d_yaw * d_yaw)

                        -- приоритет: ближайший по углу, потом по дистанции
                        local score = angle + dist * 0.01
                        if score < best_score then
                            best, best_score = pawn, score
                        end
                    end
                end
            end
        end
    end

    return best
end

-- === интерполяция углов ===
local function lerp_angle(a, b, t)
    local d = b - a
    while d > 180 do d = d - 360 end
    while d < -180 do d = d + 360 end
    return a + d * t
end

local function lerp_rot(a, b, t)
    return FRotator(
        lerp_angle(a.Pitch, b.Pitch, t),
        lerp_angle(a.Yaw,   b.Yaw,   t),
        lerp_angle(a.Roll,  b.Roll,  t)
    )
end

-- === основной тик ===
function M.tick()
    local cfg = ctx.config.data.aim
    if not cfg.enabled then
        _activated_at = nil
        return
    end

    -- задержка после включения (антидетект)
    if not _activated_at then
        _activated_at = os.clock()
        return
    end
    if ctx.antibypass and not ctx.antibypass.can_act() then
        return
    end

    local pc = ctx.sdk.get_player_controller()
    if not slua.isValid(pc) then return end

    local target = pick_target(pc)
    if not target then
        _current_target = nil
        return
    end

    -- антидетект: не переключаться слишком часто
    if _current_target ~= target then
        local now = os.clock()
        if _last_switch_time and (now - _last_switch_time) < 0.3 then
            target = _current_target or target  -- держим старую
        else
            _current_target = target
            _last_switch_time = now
        end
    end

    -- точка прицеливания
    local bone
    if cfg.bone == "head" then
        bone = ctx.sdk.get_head(target)
    else
        bone = ctx.sdk.get_location(target)
    end
    if not bone then return end

    local me = ctx.sdk.get_local_pawn(pc)
    if not slua.isValid(me) then return end
    local my_head = ctx.sdk.get_head(me) or ctx.sdk.get_location(me)

    -- желаемый поворот
    local want = (bone - my_head):Rotation()
    local cur  = ctx.sdk.get_control_rotation(pc)
    if not cur then return end

    -- плавность
    local smooth = math.max(1, cfg.smooth)
    local t = 1.0 / smooth

    local blended = lerp_rot(cur, want, t)

    -- джиттер (антидетект — не идеально ровно)
    if ctx.antibypass and ctx.antibypass.jitter_rotation then
        blended = ctx.antibypass.jitter_rotation(blended, 0.12)
    end

    ctx.sdk.set_control_rotation(pc, blended)
end

return M
