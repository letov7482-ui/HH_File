-- src/core/config.lua
local M = {}
M.data = {
    esp   = {enabled = true,  team_check = true, max_distance = 400, box = true},
    chams = {enabled = false, team_check = true, stencil_visible = 250, stencil_behind = 251},
    aim   = {enabled = false, team_check = true, bone = "head", fov_distance = 150, smooth = 8},
    menu  = {open_key = "volume_down", panic_key = "volume_up"}
}

M.defaults = nil

function M.init()
    M.defaults = FuncUtil.JsonDecode and FuncUtil.JsonDecode(FuncUtil.JsonEncode and FuncUtil.JsonEncode(M.data) or "{}") or M.data
    if FuncUtil.LoadConfig then
        local saved = FuncUtil.LoadConfig("hh_config")
        if saved then for k, v in pairs(saved) do M.data[k] = v end end
    end
end

function M.save()
    if FuncUtil.SaveConfig then
        FuncUtil.SaveConfig("hh_config", M.data)
    end
    FuncUtil.FormatLog("[HH] config saved")
end

function M.reset()
    if M.defaults then
        for k, v in pairs(M.defaults) do M.data[k] = v end
    end
    M.save()
    FuncUtil.FormatLog("[HH] config reset")
end

return M
