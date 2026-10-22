local function read(path)
    local file = assert(io.open(path, "rb"))
    local source = file:read("*a"):gsub("\r\n", "\n")
    file:close()
    return source
end

local ns, locales, locale = {}, {}, "enUS"
ns.RegisterLocale = function(name, strings) locales[name] = strings end
ns.T = function(key) return locales[locale] and locales[locale][key] or key end
local installed, loaded = { LycheeGroup = true }, { LycheeGroup = true }
local db, frames, warnings = {}, {}, {}
local shown, toggles, loads = false, 0, 0
local combat = false
local protectedCallDepth = 0
local lychee = {}
function lychee:ToggleWindow()
    assert(protectedCallDepth == 0, "QFX wrapped Lychee's native click in pcall")
    assert(self == lychee, "Lychee ToggleWindow lost its receiver")
    shown, toggles = not shown, toggles + 1
end
local env = setmetatable({
    ns = ns, QFXSystemBarNS = ns, QFXSystemBarDB = db, LycheeGroup = lychee,
    SlashCmdList = {}, StaticPopupDialogs = {},
    IsLoggedIn = function() return true end,
    InCombatLockdown = function() return combat end,
    pcall = function(callback, ...)
        protectedCallDepth = protectedCallDepth + 1
        local results = table.pack(pcall(callback, ...))
        protectedCallDepth = protectedCallDepth - 1
        return table.unpack(results, 1, results.n)
    end,
    C_Timer = { NewTimer = function() return { Cancel = function() end } end },
    print = function(message) warnings[#warnings + 1] = message end,
    CreateFrame = function()
        local frame = {
            RegisterEvent = function() end,
            UnregisterEvent = function() end,
            SetScript = function(self, event, callback) self[event] = callback end,
        }
        frames[#frames + 1] = frame
        return frame
    end,
}, { __index = _G })
env._G = env
env.C_AddOns = {
    IsAddOnLoaded = function(name) return loaded[name] == true end,
    GetAddOnInfo = function(name)
        if installed[name] ~= nil then return name, name, "", installed[name] end
    end,
    LoadAddOn = function(name)
        assert(name == "LycheeGroup", "unexpected lazy load: " .. name)
        loads = loads + 1
        if installed[name] ~= true then return false end
        loaded[name], env.LycheeGroup = true, lychee
        return true
    end,
}
for _, name in ipairs({ "zhCN", "zhTW" }) do
    assert(loadfile("QFXSystemBar_Locale/" .. name .. ".lua", "t", env))("QFXSystemBar_Locale", ns)
end
assert(loadfile("QFXSystemBar_MeetingStone/MeetingStoneBridge.lua", "t", env))("QFXSystemBar_MeetingStone", ns)
assert(loadfile("QFXSystemBar_MeetingStone/LycheeGroupBridge.lua", "t", env))("QFXSystemBar_MeetingStone", ns)
assert(ns.MeetingStoneBridgeLoaded)
assert(ns.GetPremadeAddonDisplayName() == "Lychee LFG")
assert(ns.GetPremadeAddonInfoBarText() == "Lychee LFG")
locale = "zhCN"
assert(ns.GetPremadeAddonDisplayName() == "荔枝组队")
locale = "zhTW"
assert(ns.GetPremadeAddonInfoBarText() == "荔枝組隊")
locale = "zhCN"

local owner = {}
ns.ToggleMeetingStone(owner, "LeftButton")
assert(shown and toggles == 1 and loads == 0)
ns.ToggleMeetingStone(owner, "LeftButton")
assert(not shown and toggles == 2)
ns.ToggleMeetingStone(owner, "RightButton")
ns.ToggleMeetingStone(owner, "MiddleButton")
assert(toggles == 2, "non-left clicks toggled Lychee")

loaded.LycheeGroup, env.LycheeGroup = nil, nil
ns.ToggleMeetingStone(owner, "LeftButton")
assert(shown and toggles == 3 and loads == 1, "first click did not lazy-load and open Lychee")

-- The addon's registered slash command is also a supported public entry.
local toggleWindow = lychee.ToggleWindow
lychee.ToggleWindow = nil
local slashCalls = 0
env.SlashCmdList.LYCHEEGROUP = function(message)
    assert(protectedCallDepth == 0, "QFX wrapped Lychee's slash click in pcall")
    assert(message == "")
    slashCalls = slashCalls + 1
    toggleWindow(lychee)
end
ns.ToggleMeetingStone(owner, "LeftButton")
assert(not shown and slashCalls == 1 and toggles == 4, "missing method lost the slash fallback")
lychee.ToggleWindow = toggleWindow

-- Earlier providers retain their existing priority; disabled addons do not win.
installed.PremadeGroupBoard = true
assert(ns.GetPremadeAddonDisplayName() == "PGB")
installed.GroupFinder = true
assert(ns.GetPremadeAddonDisplayName() == "GroupFinder")
installed.MeetingStone = true
assert(ns.GetPremadeAddonDisplayName() == "MeetingStone" and ns.GetPremadeAddonInfoBarText() == nil)
installed.MeetingStone, installed.GroupFinder, installed.PremadeGroupBoard = false, false, false
assert(ns.GetPremadeAddonDisplayName() == "荔枝组队")

-- Exercise the actual loaded info-bar closures, including its click dispatch.
assert(loadfile("QFXSystemBar_InfoBar/InfoBar.lua", "t", env))("QFXSystemBar_InfoBar", ns)
local function upvalue(callback, key)
    for index = 1, 255 do
        local name, value = debug.getupvalue(callback, index)
        if not name then break end
        if name == key then return value end
    end
    error("missing upvalue: " .. key)
end
local updateTexts = upvalue(ns.RefreshInfoBars, "UpdateTexts")
local updateOne = upvalue(updateTexts, "UpdateOneInfoBarText")
local textFuncs = upvalue(updateOne, "textFuncs")
assert(textFuncs.meetingstone() == "荔枝组队", "info bar did not use the detected provider name")
local ensureModules = upvalue(ns.RefreshInfoBars, "EnsureModules")
local ensureSlot = upvalue(ensureModules, "EnsureSlotModules")
local createModule = upvalue(ensureSlot, "CreateTextModule")
local click = upvalue(createModule, "HandleClick")
click("meetingstone", "LeftButton", owner)
assert(shown and toggles == 5, "info-bar click did not open Lychee")
click("meetingstone", "LeftButton", owner)
assert(not shown and toggles == 6, "info-bar click did not close Lychee")
click("meetingstone", "RightButton", owner)
assert(toggles == 6)
locale = "enUS"
assert(textFuncs.meetingstone() == "Lychee LFG")

-- Both launchers invoke Lychee synchronously during combat, including its
-- lazy-load and missing-method command paths. No retry/automatic replay occurs.
combat, locale = true, "zhCN"
ns.ToggleMeetingStone(owner, "LeftButton")
assert(shown and toggles == 7)
click("meetingstone", "LeftButton", owner)
assert(not shown and toggles == 8 and loads == 1 and slashCalls == 1 and #warnings == 0)
ns.ToggleMeetingStone(owner, "RightButton")
ns.ToggleMeetingStone(owner, "MiddleButton")
assert(toggles == 8 and #warnings == 0, "ignored clicks toggled Lychee")
loaded.LycheeGroup, env.LycheeGroup = nil, nil
ns.ToggleMeetingStone(owner, "LeftButton")
assert(shown and toggles == 9 and loads == 2)
click("meetingstone", "LeftButton", owner)
assert(not shown and toggles == 10 and loads == 2)
lychee.ToggleWindow = nil
ns.ToggleMeetingStone(owner, "LeftButton")
assert(shown and toggles == 11)
click("meetingstone", "LeftButton", owner)
assert(not shown and toggles == 12 and slashCalls == 3 and #warnings == 0)
lychee.ToggleWindow = toggleWindow

-- A real error or explicit failure must never dispatch a second toggle through
-- a fallback; error reporting belongs to the game's normal script handler.
lychee.ToggleWindow = function() error("native test error") end
local ok, err = pcall(ns.ToggleMeetingStone, owner, "LeftButton")
assert(not ok and tostring(err):find("native test error", 1, true) and slashCalls == 3)
lychee.ToggleWindow = function() return false, "native unavailable" end
local result, reason = ns.ToggleMeetingStone(owner, "LeftButton")
assert(result == false and reason == "native unavailable" and slashCalls == 3)
lychee.ToggleWindow = toggleWindow

-- Lychee remains installed while another provider wins the normal priority.
local otherToggles = 0
for _, provider in ipairs({
    { addon = "PremadeGroupBoard", toggle = "PGB_TOGGLE" },
    { addon = "GroupFinder", toggle = "GROUPFINDER_TOGGLE" },
    { addon = "MeetingStone", slash = "MeetingStone" },
}) do
    installed[provider.addon], loaded[provider.addon] = true, true
    local callback = function() otherToggles = otherToggles + 1 end
    if provider.toggle then env[provider.toggle] = callback else env.SlashCmdList[provider.slash] = callback end
    ns.ToggleMeetingStone(owner, "LeftButton")
    click("meetingstone", "LeftButton", owner)
    installed[provider.addon], loaded[provider.addon] = false, nil
end
assert(otherToggles == 6 and #warnings == 0, "Lychee dispatch changed another provider")
combat, locale = false, "enUS"
assert(not shown and toggles == 12, "combat click was replayed")
click("meetingstone", "LeftButton", owner)
assert(shown and toggles == 13, "Lychee did not open after combat")
ns.ToggleMeetingStone(owner, "LeftButton")
assert(not shown and toggles == 14)

-- Bursts retain their immediate sync but share a single pair of startup retries.
local retries, retrySyncs = {}, 0
local originalSync = ns.SyncMeetingStoneFloatingPanel
ns.SyncMeetingStoneFloatingPanel = function() retrySyncs = retrySyncs + 1 end
env.C_Timer.After = function(_, callback) retries[#retries + 1] = callback end
for _ = 1, 10 do ns.QueueMeetingStoneFloatingSync() end
assert(retrySyncs == 10 and #retries == 2, "sync burst multiplied the delayed retry timers")
retries[1](); retries[2]()
assert(retrySyncs == 12)
ns.QueueMeetingStoneFloatingSync()
assert(retrySyncs == 13 and #retries == 4, "completed retries blocked a later sync request")
retries[3](); retries[4]()
ns.SyncMeetingStoneFloatingPanel = originalSync

-- Late base/UI loading is recognized by both existing event handlers.
local syncs = 0
ns.QueueMeetingStoneFloatingSync = function() syncs = syncs + 1 end
for _, name in ipairs({ "LycheeGroup", "LycheeGroup_UI" }) do
    frames[1].OnEvent(frames[1], "ADDON_LOADED", name)
end
assert(syncs == 2, "info bar ignored late Lychee loading")
frames[1].OnEvent(frames[1], "ADDON_LOADED", "UnrelatedAddon")
assert(syncs == 2)

local core = read("QFXSystemBar/QFXSystemBar.lua")
local eventCode = assert(core:match('qfxLoginWatcher:SetScript%("OnEvent", function%(_, event, isInitialLogin, isReloadingUI%)\n(.-)\n    end%)'))
env.ShouldLoadMeetingStoneBridge = function() return true end
local onEvent = assert(load("return function(_, event, isInitialLogin, isReloadingUI)\n" .. eventCode .. "\nend", "micro-menu provider events", "t", env))()
for _, name in ipairs({ "LycheeGroup", "LycheeGroup_UI" }) do onEvent(nil, "ADDON_LOADED", name) end
assert(syncs == 4, "micro menu ignored late Lychee loading")
assert(#warnings == 0, "supported Lychee clicks reported an error")

-- Optional installed-addon contract: execute its real ToggleWindow/Open/Ensure
-- and Host Show/FitToScreen/Hide, mocking only the UI objects and page content.
-- This checks dispatch, not the client engine's combat/taint enforcement.
if arg[1] then
    local addonRoot = arg[1]:gsub("[/\\]$", "")
    env.LycheeGroup = lychee
    assert(loadfile(addonRoot .. "/LycheeGroup/Core.lua", "t", env))()
    lychee.LoadDB = function() end
    lychee.db = { uiScale = 100, reduceMotion = true }
    lychee.Group = {}
    loaded.LycheeGroup_Group, loaded.LycheeGroup_UI = true, true
    env.C_AddOns.IsAddOnLoaded = function(name) return loaded[name] == true, loaded[name] == true end
    env.C_LFGList = { HasActiveEntryInfo = function() return false end }
    env.UIParent = { GetWidth = function() return 1920 end, GetHeight = function() return 1080 end }
    local ui, opens, closes, clamps = {}, 0, 0, 0
    local uiFrame = { shown = false, scale = 1 }
    function uiFrame:IsShown() return self.shown end
    function uiFrame:Show() self.shown = true; opens = opens + 1 end
    function uiFrame:Hide() self.shown = false; closes = closes + 1 end
    function uiFrame:GetScale() return self.scale end
    function uiFrame:SetScale(value) self.scale = value end
    function uiFrame:SetClampRectInsets()
        assert(protectedCallDepth == 0, "real Lychee FitToScreen entered through QFX's pcall wrapper")
        clamps = clamps + 1
    end
    local function noop() end
    ui.Theme = { width = 1299.2, height = 764 }
    ui.Motion = { Presence = noop, Brand = noop, StopAll = noop, StopBrand = noop, SetPresence = noop }
    ui.C, ui.L, ui.pages = {}, {}, { find = {} }
    ui.frame, ui.blocker, ui.drag = uiFrame, { Hide = noop, Show = noop }, { Stop = noop }
    ui.Tooltip, ui.Application = { Hide = noop }, { ClearFocus = noop }
    ui.context = { CloseMenu = noop }
    lychee.UI = ui
    assert(loadfile(addonRoot .. "/LycheeGroup_UI/Host.lua", "t", env))()
    ui.RefreshHeaderLayout = noop
    ui.Navigate = function(self, page) self.page = page end
    for _, inCombat in ipairs({ false, true }) do
        combat = inCombat
        ns.ToggleMeetingStone(owner, "LeftButton")
        assert(uiFrame:IsShown())
        ns.ToggleMeetingStone(owner, "LeftButton")
        assert(not uiFrame:IsShown())
        click("meetingstone", "LeftButton", owner)
        assert(uiFrame:IsShown())
        click("meetingstone", "LeftButton", owner)
        assert(not uiFrame:IsShown())
    end
    assert(opens == 4 and closes == 4 and clamps == 4 and #warnings == 0)
    print("Installed Lychee Core/Host: both QFX launchers open/close once per click in both combat states, with no outer pcall")
end

print("PremadeAddons_test: Lychee direct combat clicks, single dispatch, labels, launchers, other-provider combat clicks, lazy load, slash fallback and priority passed")
