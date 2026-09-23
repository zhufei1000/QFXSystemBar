local addonName, childNS = ...
local ns = _G.QFXSystemBarNS or childNS
if not ns then return end
ns.MeetingStoneCombatFixLoaded = true

-- ========================================================================
-- MeetingStone combat fix (part of the MeetingStone bridge addon)
-- ------------------------------------------------------------------------
-- MeetingStone marks its main panel as a Blizzard UIPanel through the
-- "UIPanelLayout-*" attributes (NetEaseGUI Panel:EnableUIPanel in
-- Module/MainPanel.lua). Frames carrying those attributes are protected in
-- combat, so Addon:Toggle() -> ShowModule('MainPanel') -> MainPanel:Hide()
-- triggers ADDON_ACTION_BLOCKED and the panel cannot be opened while
-- fighting.
--
-- Removing the attributes turns the panel back into an ordinary frame:
-- Hide/Show work in combat again. The panel keeps its own position handling,
-- its ESC close (NetEaseGUI special handler) and its OnShow/OnHide messages,
-- so nothing else changes. The fix is applied at load, re-applied after
-- combat, and guarded against future EnableUIPanel calls.
--
-- It also silences a 12.1 crash in MeetingStone's LibShowUIPanel-1.0: that
-- library searches for a secure delegate frame (Frame:SetUIPanel) which no
-- longer exists on this client, then indexes the nil delegate whenever a
-- protected Blizzard panel is shown in combat.
-- ========================================================================

local PANEL_LAYOUT_ATTRIBUTES = {
    "UIPanelLayout-defined",
    "UIPanelLayout-enabled",
    "UIPanelLayout-whileDead",
    "UIPanelLayout-area",
    "UIPanelLayout-pushable",
}

local pendingPanels = {}
local panelClassHooked = false
local libGuarded = false

local function GetMeetingStoneMainPanel()
    local panel = _G.MainPanel
    if panel then return panel end

    local libStub = _G.LibStub
    local ace = libStub and type(libStub.GetLibrary) == "function"
        and libStub.GetLibrary(libStub, "AceAddon-3.0", true)
    if type(ace) ~= "table" or type(ace.GetAddon) ~= "function" then return nil end

    local addon = ace.GetAddon(ace, "MeetingStone", true)
    if addon and type(addon.GetModule) == "function" then
        return addon:GetModule("MainPanel", true)
    end
    return nil
end

local function StripPanelLayout(panel)
    if not panel or type(panel.SetAttribute) ~= "function" then return false end
    for i = 1, #PANEL_LAYOUT_ATTRIBUTES do
        panel:SetAttribute(PANEL_LAYOUT_ATTRIBUTES[i], nil)
    end
    return true
end

local function ApplyPanelFix(panel)
    if not panel then return false end
    -- SetAttribute on a protected frame is itself protected, so defer to
    -- PLAYER_REGEN_ENABLED when the client is locked down.
    if InCombatLockdown and InCombatLockdown() then
        pendingPanels[panel] = true
        return false
    end
    pendingPanels[panel] = nil
    return StripPanelLayout(panel)
end

local function FlushPendingPanelFixes()
    if InCombatLockdown and InCombatLockdown() then return end
    for panel in pairs(pendingPanels) do
        pendingPanels[panel] = nil
        StripPanelLayout(panel)
    end
end

local function HookNetEasePanelClass()
    if panelClassHooked then return end
    local libStub = _G.LibStub
    local GUI = libStub and type(libStub.GetLibrary) == "function"
        and libStub.GetLibrary(libStub, "NetEaseGUI-2.0", true)
    if type(GUI) ~= "table" or type(GUI.GetClass) ~= "function" then return end

    local panelClass = GUI:GetClass("Panel")
    if type(panelClass) ~= "table" or type(panelClass.EnableUIPanel) ~= "function" then return end

    panelClassHooked = true
    hooksecurefunc(panelClass, "EnableUIPanel", function(self)
        ApplyPanelFix(self)
    end)
end

local function GuardLibShowUIPanel()
    if libGuarded then return end
    local libStub = _G.LibStub
    local Lib = libStub and type(libStub.GetLibrary) == "function"
        and libStub.GetLibrary(libStub, "LibShowUIPanel-1.0", true)
    if type(Lib) ~= "table" then return end

    libGuarded = true
    if Lib.Delegate ~= nil then return end -- library works on this client

    -- No secure delegate frame exists (12.1). Keep the out-of-combat path and
    -- skip the in-combat one instead of crashing on the nil delegate.
    Lib.OnCallShowUIPanel = function() end
    Lib.OnCallHideUIPanel = function() end
    Lib.Show = function(frame, force)
        if InCombatLockdown and InCombatLockdown() then return end
        if type(ShowUIPanel) == "function" then return ShowUIPanel(frame, force) end
    end
    Lib.Hide = function(frame, skipSetPoint)
        if InCombatLockdown and InCombatLockdown() then return end
        if type(HideUIPanel) == "function" then return HideUIPanel(frame, skipSetPoint) end
    end
end

-- Instance-level guard: works even when the NetEaseGUI class object cannot be
-- hooked (LibClass may expose methods through a prototype).
local function GuardPanelInstance(panel)
    if not panel or panel.qfxMeetingStoneCombatGuarded then return end
    local original = panel.EnableUIPanel
    if type(original) ~= "function" then return end
    panel.qfxMeetingStoneCombatGuarded = true
    panel.EnableUIPanel = function(self, ...)
        original(self, ...)
        ApplyPanelFix(self)
    end
end

local function ApplyMeetingStoneFix()
    local panel = GetMeetingStoneMainPanel()
    if panel then
        GuardPanelInstance(panel)
        ApplyPanelFix(panel)
    end
    HookNetEasePanelClass()
    GuardLibShowUIPanel()
end

-- /run QFXSystemBarNS.MeetingStoneCombatDiagnostics()
-- Prints whether the fix is loaded and what the live panel looks like. Run it
-- once out of combat and once in combat to compare.
function ns.MeetingStoneCombatDiagnostics()
    local panel = GetMeetingStoneMainPanel()
    local layoutDefined = panel and panel.GetAttribute and panel:GetAttribute("UIPanelLayout-defined")
    local protected = panel and panel.IsProtected and panel:IsProtected()
    local shown = panel and panel.IsShown and panel:IsShown()
    local alpha = panel and panel.GetAlpha and panel:GetAlpha()
    local guarded = panel and panel.qfxMeetingStoneCombatGuarded or false

    print("|cFF33FF99QFX MeetingStone Combat Fix|r " .. (ns.MeetingStoneCombatFixLoaded and "loaded" or "|cFFFF5555NOT loaded|r"))
    print(("  panel=%s UIPanelLayout-defined=%s protected=%s shown=%s alpha=%s guarded=%s classHooked=%s libGuarded=%s"):format(
        tostring(panel ~= nil), tostring(layoutDefined), tostring(protected),
        tostring(shown), tostring(alpha), tostring(guarded),
        tostring(panelClassHooked), tostring(libGuarded)))
    return {
        loaded = ns.MeetingStoneCombatFixLoaded == true,
        panel = panel,
        layoutDefined = layoutDefined,
        protected = protected,
        shown = shown,
        alpha = alpha,
        guarded = guarded,
        classHooked = panelClassHooked,
        libGuarded = libGuarded,
    }
end

-- /run QFXSystemBarNS.MeetingStoneCombatForceStrip()
function ns.MeetingStoneCombatForceStrip()
    return ApplyPanelFix(GetMeetingStoneMainPanel())
end

local watcher = CreateFrame("Frame")
watcher:RegisterEvent("ADDON_LOADED")
watcher:RegisterEvent("PLAYER_REGEN_ENABLED")
watcher:SetScript("OnEvent", function(self, event, name)
    if event == "PLAYER_REGEN_ENABLED" then
        FlushPendingPanelFixes()
        return
    end

    if name == "MeetingStone" then
        ApplyMeetingStoneFix()
        -- NetEaseGUI initializes during ADDON_LOADED; re-check one frame later
        -- in case the panel attributes are set after this handler runs.
        if C_Timer and C_Timer.After then
            C_Timer.After(0, ApplyMeetingStoneFix)
        end
        self:UnregisterEvent("ADDON_LOADED")
    end
end)

-- MeetingStone is loaded late (AddonLoader) but may already be present when
-- this bridge loads first.
ApplyMeetingStoneFix()
