-- src/core/sdk.lua
local M = {}
local Security = require("GameLua.Mod.BaseMod.Common.Security.SecurityCommonUtils")

function M.get_player_controller() return slua_GameFrontendHUD:GetPlayerController() end
function M.get_local_pawn(pc)     if slua.isValid(pc) then return pc:GetCurPawn() end return nil end
function M.get_all_pawns()        return Game:GetAllPlayerPawns() or {} end
function M.is_alive(pawn)         if slua.isValid(pawn) then return Security.IsHealthStatusAlive(pawn.HealthStatus) end return false end
function M.get_team(pawn)         if slua.isValid(pawn) then return pawn.TeamID end return -1 end
function M.get_head(pawn)         if slua.isValid(pawn) then return pawn:GetHeadLocation(true) end return nil end
function M.get_location(pawn)     if slua.isValid(pawn) then return pawn:K2_GetActorLocation() end return nil end
function M.distance_2d(a, b)      return FVector.Dist2D(a, b) end
function M.get_control_rotation(pc) return pc:GetControlRotation() end
function M.set_control_rotation(pc, rot) pc:SetControlRotation(rot) end

function M.world_to_screen(world_pos)
    local pc = M.get_player_controller()
    if not slua.isValid(pc) then return nil end
    local ok, out = pcall(function() return pc:ProjectWorldLocationToScreen(world_pos) end)
    if ok and out then return out end
    return nil
end

return M
