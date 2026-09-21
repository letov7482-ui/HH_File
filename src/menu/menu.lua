-- src/menu/menu.lua
local M = {}
local ctx
function M.init(c) ctx = c end

-- UI регистрируется через UIManager по паттерну HawkEyeReportWindow
-- Здесь — только логика открытия/закрытия по горячей клавише
function M.toggle()
    local UIUtil = require("client.common.ui_util")
    local root = UIUtil.GetWidgetByName("hh", "HH_Menu_UIBP")
    if root then
        local vis = root:GetVisibility()
        if vis == UEnums.ESlateVisibility.Collapsed then
            root:SetWidgetVisibility(UEnums.ESlateVisibility.Visible)
        else
            root:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
        end
    end
end

return M
