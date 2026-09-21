-- src/features/chams.lua
local M = {}
local ctx
function M.init(c) ctx = c end

function M.tick()
    local cfg = ctx.config.data.chams
    if not cfg.enabled then return end

    local pc = ctx.sdk.get_player_controller()
    if not slua.isValid(pc) then return end
    local me = ctx.sdk.get_local_pawn(pc)
    local my_team = ctx.sdk.get_team(me)

    for _, pawn in pairs(ctx.sdk.get_all_pawns()) do
        if slua.isValid(pawn) and ctx.sdk.is_alive(pawn) then
            local team = ctx.sdk.get_team(pawn)
            if not cfg.team_check or team ~= my_team then
                pcall(function()
                    pawn:SetRenderCustomDepth(true)
                    pawn:SetCustomDepthStencilValue(cfg.stencil_visible)
                end)
            end
        end
    end
end

return M
