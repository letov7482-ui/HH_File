-- src/features/esp.lua
local M = {}
local ctx
function M.init(c) ctx = c end

function M.tick()
    local cfg = ctx.config.data.esp
    if not cfg.enabled then return end

    local pc = ctx.sdk.get_player_controller()
    if not slua.isValid(pc) then return end
    local me = ctx.sdk.get_local_pawn(pc)
    if not slua.isValid(me) then return end
    local my_team = ctx.sdk.get_team(me)
    local my_loc  = ctx.sdk.get_location(me)

    for _, pawn in pairs(ctx.sdk.get_all_pawns()) do
        if slua.isValid(pawn) and ctx.sdk.is_alive(pawn) then
            local team = ctx.sdk.get_team(pawn)
            if not cfg.team_check or team ~= my_team then
                local dist = ctx.sdk.distance_2d(my_loc, ctx.sdk.get_location(pawn))
                if dist <= cfg.max_distance then
                    if not pawn:Replay_IsEnemyFrameUIExisted() then
                        pawn:Replay_CreateEnemyFrameUI(true, true)
                    end
                    pawn:Replay_SetVisiableOfFrameUI(true)
                end
            end
        end
    end
end

return M
