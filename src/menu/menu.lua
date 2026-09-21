-- src/menu/menu.lua
-- Override оригинального HawkEyeReportWindow — наполняем его нашим содержимым
local ASTExtraPlayerController = import("/Script/ShadowTrackerExtra.STExtraPlayerController")
local FormatLog = FuncUtil.FormatLog
local HawkEyeReportWindow = {}

local ctx  -- устанавливается из main.lua через M.init(ctx)
local _TABS = {"ESP", "Chams", "Aimbot", "Config"}
local _activeTab = 1

-- === схема настроек ===
local function build_items()
    local c = ctx.config.data
    if _activeTab == 1 then
        return {
            {id="esp_en",    label="Enable",       kind="toggle", get=function() return c.esp.enabled end,     set=function(v) c.esp.enabled = v end},
            {id="esp_tm",    label="Team check",   kind="toggle", get=function() return c.esp.team_check end,  set=function(v) c.esp.team_check = v end},
            {id="esp_dist",  label="Max distance", kind="slider", get=function() return c.esp.max_distance end,set=function(v) c.esp.max_distance = v end, min=50, max=800, step=10},
            {id="esp_box",   label="Box",          kind="toggle", get=function() return c.esp.box end,         set=function(v) c.esp.box = v end},
        }
    elseif _activeTab == 2 then
        return {
            {id="ch_en",     label="Enable",       kind="toggle", get=function() return c.chams.enabled end,     set=function(v) c.chams.enabled = v end},
            {id="ch_tm",     label="Team check",   kind="toggle", get=function() return c.chams.team_check end,  set=function(v) c.chams.team_check = v end},
            {id="ch_vis",    label="Stencil vis",  kind="slider", get=function() return c.chams.stencil_visible end, set=function(v) c.chams.stencil_visible = v end, min=0, max=255, step=1},
            {id="ch_beh",    label="Stencil behind",kind="slider",get=function() return c.chams.stencil_behind end,  set=function(v) c.chams.stencil_behind = v end,  min=0, max=255, step=1},
        }
    elseif _activeTab == 3 then
        return {
            {id="am_en",     label="Enable",       kind="toggle", get=function() return c.aim.enabled end,      set=function(v) c.aim.enabled = v end},
            {id="am_tm",     label="Team check",   kind="toggle", get=function() return c.aim.team_check end,   set=function(v) c.aim.team_check = v end},
            {id="am_bone",   label="Bone",         kind="choice", get=function() return c.aim.bone end,         set=function(v) c.aim.bone = v end, opts={"head","body"}},
            {id="am_fov",    label="FOV distance", kind="slider", get=function() return c.aim.fov_distance end, set=function(v) c.aim.fov_distance = v end, min=10, max=500, step=10},
            {id="am_sm",     label="Smooth",       kind="slider", get=function() return c.aim.smooth end,       set=function(v) c.aim.smooth = v end, min=1, max=20, step=1},
        }
    else
        return {
            {id="cf_save",   label="Save config",  kind="button", action=function() ctx.config.save() end},
            {id="cf_reset",  label="Reset",        kind="button", action=function() ctx.config.reset() end},
            {id="cf_close",  label="Close",        kind="button", action=function() HawkEyeReportWindow:_OnClickHide() end},
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
    -- заголовок = текущий таб
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

-- === рендер одного item ===
function HawkEyeReportWindow:_OnRefreshReasonItem(uWidget, nIndex)
    local item = self._LoopGridReason:GetItemData(nIndex)
    if not item then return end

    local label_text = item.label
    if item.kind == "slider" then
        label_text = string.format("%s: %d", item.label, item.get())
    elseif item.kind == "choice" then
        label_text = string.format("%s: %s", item.label, tostring(item.get()))
    elseif item.kind == "toggle" then
        label_text = string.format("%s: %s", item.label, item.get() and "ON" or "OFF")
    end

    if uWidget.TextBlock_38 then uWidget.TextBlock_38:SetText(label_text) end
    if uWidget.TextBlock_40 then uWidget.TextBlock_40:SetText(label_text) end

    -- индикатор toggle (1 = ON, 0 = OFF)
    if uWidget.WidgetSwitcher_3 then
        if item.kind == "toggle" and item.get() then
            uWidget.WidgetSwitcher_3:SetActiveWidgetIndex(1)
        else
            uWidget.WidgetSwitcher_3:SetActiveWidgetIndex(0)
        end
    end
end

-- === действия по кнопкам в item ===
-- Button_6 = основной клик (toggle / - / prev)
-- Button_7 = правый клик (+ / next)
function HawkEyeReportWindow:_OnClickReasonItem(uWidget, nIndex)
    self:PlayAudio(sound_config.click_v1)
    local item = self._LoopGridReason:GetItemData(nIndex)
    if not item then return end

    local which = "Button_6"  -- определить по виджету сложно, обработаем оба сценария
    -- (в реальном slua здесь придёт имя контрола, но HawkEye не даёт — используем эвристику по nIndex)
    -- для простоты: любой клик по item делает основное действие

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
    elseif item.kind == "button" then
        if item.action then item.action() end
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
    ctx.config.save()
    self:Hide()
end

function HawkEyeReportWindow:OnAndroidBack()
    self:_OnClickHide()
end

-- === точка входа ===
function HawkEyeReportWindow.init(c)
    ctx = c
    FuncUtil.FormatLog("[HH] menu bound to HawkEyeReportWindow")
end

function HawkEyeReportWindow.open()
    UIManager.ShowUI(UIManager.UI_Config_InGame.HawkEyeReportWindow)
end

function HawkEyeReportWindow.toggle()
    -- проверим открыто ли
    local ui = UIManager.GetUI(UIManager.UI_Config_InGame.HawkEyeReportWindow)
    if ui and ui.UIRoot and ui.UIRoot:IsVisible() then
        ui:Hide()
    else
        HawkEyeReportWindow.open()
    end
end

local class = require("class")
local object = require("GameLua.Mod.BaseMod.Client.Security.UI.AbstractConfirmCancelWindow")
return class(object, nil, HawkEyeReportWindow)
