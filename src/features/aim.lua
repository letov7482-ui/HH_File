-- src/features/aim.lua
local M = {}
local ctx
local current_target
function M.init(c) ctx = c end

function M.pick_target(pc)
    local cfg = ctx.config.data.aim
    local me = ctx.sdk.get_local_pawn(pc)
    if not slua.isValid(me) then return nil end
    local my_loc = ctx.sdk.get_location(me)
    local my_team = ctx.sdk.get_team(me)
    local best, best_dist = nil, cfg.fov_distance
    for _, pawn in pairs(ctx.sdk.get_all_pawns()) do
        if slua.isValid(pawn) and ctx.sdk.is_alive(pawn) then
            if not cfg.team_check or ctx.sdk.get_team(pawn) ~= my_team then
                local d = ctx.sdk.distance_2d(my_loc, ctx.sdk.get_location(pawn))
                if d < best_dist then best, best_dist = pawn, d end
            end
        end
    end
    return best
end

local function lerp_rot(a, b, t)
    local function l(x, y, tt)
        local d = y - x
        while d > 180 do d = d - 360 end
        while d < -180 do d = d + 360 end
        return x + d * tt
    end
    return FRotator(l(a.Pitch, b.Pitch, t), l(a.Yaw, b.Yaw, t), l(a.Roll, b.Roll, t))
end

function M.tick()
    local cfg = ctx.config.data.aim
    if not cfg.enabled then return end
    local pc = ctx.sdk.get_player_controller()
    if not slua.isValid(pc) then return end
    local target = M.pick_target(pc)
    if not target then current_target = nil return end
    current_target = target
    local bone = cfg.bone == "head" and ctx.sdk.get_head(target) or ctx.sdk.get_location(target)
    if not bone then return end
    local me = ctx.sdk.get_local_pawn(pc)
    local my_loc = ctx.sdk.get_location(me)
    local want = (bone - my_loc):Rotation()
    local cur  = ctx.sdk.get_control_rotation(pc)
    local smooth = math.max(1, cfg.smooth)
    ctx.sdk.set_control_rotation(pc, lerp_rot(cur, want, 1.0 / smooth))
end

return M
