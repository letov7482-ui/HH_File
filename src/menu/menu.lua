-- src/menu/menu.lua
-- Override HawkEyeReportWindow: используем это окно как меню чита
local ASTExtraPlayerController = import("/Script/ShadowTrackerExtra.STExtraPlayerController")
local FormatLog = FuncUtil.FormatLog
local HawkEyeReportWindow = {}

local _TABS = {"ESP", "Chams", "Aimbot", "Config"}
local _activeTab = 1

-- ctx берём из глобального реестра (устанавливается в core/main.lua)
local function ctx()
    return _G._HH_CTX
end

-- === схема пунктов текущего таба ===
local function build_items()
    local c = ctx()
    if not c then return {} end
    local d = c.config.data

    if _activeTab == 1 then -- ESP
        return {
            {label = "Enable",       kind = "toggle", get = function() return d.esp.enabled end,      set = function(v) d.esp.enabled = v end},
            {label = "Team check",   kind = "toggle", get = function() return d.esp.team_check end,   set = function(v) d.esp.team_check = v end},
            {label = "Max distance", kind = "slider", get = function() return d.esp.max_distance end, set = function(v) d.esp.max_distance = v end, min = 50, max = 800, step = 10},
            {label = "Box",          kind = "toggle", get = function() return d.esp.box end,          set = function(v) d.esp.box = v end},
        }
    elseif _activeTab == 2 then -- Chams
        return {
            {label = "Enable",         kind = "toggle", get = function() return d.chams.enabled end,         set = function(v) d.chams.enabled = v end},
            {label = "Team check",     kind = "toggle", get = function() return d.chams.team_check end,      set = function(v) d.chams.team_check = v end},
            {label = "Stencil vis",    kind = "slider", get = function() return d.chams.stencil_visible end, set = function(v) d.chams.stencil_visible = v end, min = 0, max = 255, step = 1},
            {label = "Stencil behind", kind = "slider", get = function() return d.chams.stencil_behind end,  set = function(v) d.chams.stencil_behind = v end,  min = 0, max = 255, step = 1},
        }
    elseif _activeTab == 3 then -- Aimbot
        return {
            {label = "Enable",       kind = "toggle", get = function() return d.aim.enabled end,        set = function(v) d.aim.enabled = v end},
            {label = "Team check",   kind = "toggle", get = function() return d.aim.team_check end,     set = function(v) d.aim.team_check = v end},
            {label = "Bone",         kind = "choice", get = function() return d.aim.bone end,           set = function(v) d.aim.bone = v end, opts = {"head", "body"}},
            {label = "FOV distance", kind = "slider", get = function() return d.aim.fov_distance end,   set = function(v) d.aim.fov_distance = v end, min = 10, max = 500, step = 10},
            {label = "Smooth",       kind = "slider", get = function() return d.aim.smooth end,         set = function(v) d.aim.smooth = v end, min = 1, max = 20, step = 1},
        }
    else -- Config
        return {
            {label = "Save config", kind = "button", action = function() c.config.save() end},
            {label = "Reset",       kind = "button", action = function() c.config.reset() end},
            {label = "Close",       kind = "button", action = function() HawkEyeReportWindow:_OnClickHide() end},
        }
    end
end

-- === жизненный цикл окна ===
function HawkEyeReportWindow:RegistEvents()
    FormatLog("[HH] RegistEvents")
    self:AddOnClickedEventByControl(self.UIRoot.Button_2, self._OnClickHide, self)
    self:AddOnClickedEventByControl(self.UIRoot.Button_0, self._OnClickSubmit, self)
    self._LoopGridReason:SetRefreshItemCallback(self._OnRefreshReasonItem, self)
    self._LoopGridReason:AddItemWidgetChildEvent("Button_6", "OnClicked", self._OnClickReasonItem, self)
    self._LoopGridReason:AddItemWidgetChildEvent("Button_7", "OnClicked", self._OnClickReasonItem, self)
end

function HawkEyeReportWindow:OnInitialize()
    FormatLog("[HH] OnInitialize")
    self._LoopGridReason = self:InitScrollBox(self.UIRoot.LoopScrollGrid_0)
    _activeTab = 1
end

function HawkEyeReportWindow:OnShow()
    FormatLog("[HH] OnShow")
    HawkEyeReportWindow.__super.OnShow(self)
    self:_RefreshWindow()
end

function HawkEyeReportWindow:_RefreshWindow()
    self:_RefreshTabHeader()
    self:_RefreshList()
end

function HawkEyeReportWindow:_RefreshTabHeader()
    local title = self.UIRoot.Common_Popup_Large_UIBP
    if title and title.Title then
        title.Title:SetText("HH  [" .. _TABS[_activeTab] .. "]")
        title.Title:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
    end
    if title and title.Button_Help then
        title.Button_Help:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
    end
end

function HawkEyeReportWindow:_RefreshList()
    local items = build_items()
    self._LoopGridReason:SetData(items)
    self._LoopGridReason:RefreshAllItems()
end

-- === рендер строки списка ===
function HawkEyeReportWindow:_OnRefreshReasonItem(uWidget, nIndex)
    local item = self._LoopGridReason:GetItemData(nIndex)
    if not item then return end

    local text = item.label
    if item.kind == "slider" then
        text = string.format("%s: %d", item.label, item.get())
    elseif item.kind == "choice" then
        text = string.format("%s: %s", item.label, tostring(item.get()))
    elseif item.kind == "toggle" then
        text = string.format("%s: %s", item.label, item.get() and "ON" or "OFF")
    end

    if uWidget.TextBlock_38 then uWidget.TextBlock_38:SetText(text) end
    if uWidget.TextBlock_40 then uWidget.TextBlock_40:SetText(text) end

    if uWidget.WidgetSwitcher_3 then
        if item.kind == "toggle" and item.get() then
            uWidget.WidgetSwitcher_3:SetActiveWidgetIndex(1)
        else
            uWidget.WidgetSwitcher_3:SetActiveWidgetIndex(0)
        end
    end
end

-- === клик по строке ===
function HawkEyeReportWindow:_OnClickReasonItem(uWidget, nIndex)
    self:PlayAudio(sound_config.click_v1)
    local item = self._LoopGridReason:GetItemData(nIndex)
    if not item then return end

    if item.kind == "toggle" then
        item.set(not item.get())
    elseif item.kind == "slider" then
        item.set(math.max(item.min, item.get() - item.step))
    elseif item.kind == "choice" then
        local opts = item.opts
        for i, o in ipairs(opts) do
            if o == item.get() then
                item.set(opts[(i % #opts) + 1])
                break
            end
        end
    elseif item.kind == "button" and item.action then
        item.action()
    end

    self:_RefreshWindow()
end

-- === кнопка submit (Button_0) — переключение таба ===
function HawkEyeReportWindow:_OnClickSubmit()
    self:PlayAudio(sound_config.click_v1)
    _activeTab = (_activeTab % #_TABS) + 1
    FormatLog("[HH] tab -> %s", _TABS[_activeTab])
    self:_RefreshWindow()
end

-- === кнопка close (Button_2) ===
function HawkEyeReportWindow:_OnClickHide()
    self:PlayAudio(sound_config.click_v1)
    local c = ctx()
    if c then c.config.save() end
    self:Hide()
end

function HawkEyeReportWindow:OnAndroidBack()
    self:_OnClickHide()
end

local class = require("class")
local object = require("GameLua.Mod.BaseMod.Client.Security.UI.AbstractConfirmCancelWindow")
return class(object, nil, HawkEyeReportWindow)
