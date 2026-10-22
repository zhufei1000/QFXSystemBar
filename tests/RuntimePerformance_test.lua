local function upvalue(callback, key)
    for i = 1, 255 do
        local name, value = debug.getupvalue(callback, i)
        if not name then break end
        if name == key then return value end
    end
    error("missing upvalue: " .. key)
end
local function frame()
    local value = { events = {}, visible = true, shown = true, qfxInfoBarIconTextures = false }
    function value:SetScript(key, callback) self[key] = callback end
    function value:RegisterEvent(key) self.events[key] = true end
    function value:UnregisterEvent(key) self.events[key] = nil end
    function value:IsVisible() return self.visible end
    function value:IsShown() return self.shown end
    function value:Show() self.shown = true end
    function value:Hide() self.shown = false end
    function value:SetFont() end
    function value:SetText(text) self.textValue = text end
    function value:SetTextColor(...) self.color = { ... } end
    function value:CreateTexture() return frame() end
    function value:SetPoint(...) self.point = { ... } end
    return setmetatable(value, { __index = function() return function() end end })
end

-- Real InfoBar closures: share data queries, preserve per-button zone colours,
-- and stop/resume tickers on visibility changes without adding a polling loop.
local ns, db, created, tickers = { T = function(key) return key end }, {}, {}, {}
local fpsQueries, latencyQueries, zoneQueries = 0, 0, 0
local env = setmetatable({
    QFXSystemBarNS = ns, QFXSystemBarDB = db, StaticPopupDialogs = {},
    IsLoggedIn = function() return true end,
    GetFramerate = function() fpsQueries = fpsQueries + 1; return 60 end,
    GetNetStats = function() latencyQueries = latencyQueries + 1; return 0, 0, 10, 20 end,
    GetMinimapZoneText = function() zoneQueries = zoneQueries + 1; return "Test Zone" end,
    C_Timer = {
        NewTimer = function() return { Cancel = function() end } end,
        NewTicker = function(_, callback)
            local ticker = { callback = callback, Cancel = function(self) self.cancelled = true end }
            tickers[#tickers + 1] = ticker
            return ticker
        end,
    },
    CreateFrame = function() local value = frame(); created[#created + 1] = value; return value end,
}, { __index = _G })
env._G = env
assert(loadfile("QFXSystemBar_InfoBar/InfoBar.lua", "t", env))("QFXSystemBar_InfoBar", ns)
local updateTexts = upvalue(ns.RefreshInfoBars, "UpdateTexts")
local modules = upvalue(updateTexts, "modules")
db.isInfoBar = true
local buttons = {}
for key, slot in pairs(ns.InfoBarSlots) do
    db[slot.barEnabledKey], db[slot.enabledKey] = true, { fps = true, zone = true }
    local fps, zone = frame(), frame()
    fps.text, zone.text = frame(), frame()
    modules[key] = { fps = fps, zone = zone }
    buttons[#buttons + 1] = fps
end
updateTexts({ fps = true }, false)
assert(#buttons == 3 and fpsQueries == 1 and latencyQueries == 1, "each info strip queried the same FPS/latency independently")
updateTexts({ zone = true }, false)
assert(zoneQueries == 3, "shared text cache skipped per-button zone colouring")
for _, byID in pairs(modules) do assert(byID.zone.text.color ~= nil) end
local updateTickers = upvalue(ns.RefreshInfoBars, "UpdateItemTickers")
updateTickers()
assert(#tickers == 1)
local createBars = upvalue(ns.RefreshInfoBars, "CreateBars")
local createBar = upvalue(createBars, "CreateBarForSlot")
local background = upvalue(createBar, "CreateBackground")("TestBar", "left")
for _, button in ipairs(buttons) do button.visible = false end
background.OnHide(background)
assert(tickers[1].cancelled, "hidden info bars kept their ticker")
buttons[1].visible = true
background.OnShow(background)
assert(#tickers == 2 and not tickers[2].cancelled, "showing info bars did not resume their ticker")
for _, button in ipairs(buttons) do button.visible = false end
tickers[2].callback()
assert(tickers[2].cancelled, "visibility fallback did not stop a hidden ticker")

-- The FPS hover tooltip reuses its 30s memory snapshot without sorting every
-- second. Switching CPU/memory still restores the right ordering immediately.
local clock, sorts, memoryScans = 1, 0, 0
env.GetTime = function() return clock end
env.wipe = function(value) for key in pairs(value) do value[key] = nil end end
env.C_AddOns = {
    GetNumAddOns = function() return 2 end,
    GetAddOnInfo = function(index) return "Addon" .. index, "Title" .. index, "", true end,
    IsAddOnLoaded = function() return true end,
    UpdateAddOnMemoryUsage = function() memoryScans = memoryScans + 1 end,
    GetAddOnMemoryUsage = function(index) return index * 10 end,
    GetAddOnCPUUsage = function(index) return (3 - index) * 10 end,
}
env.table = setmetatable({ sort = function(...) sorts = sorts + 1; return table.sort(...) end }, { __index = table })
local ensureSlot = upvalue(upvalue(ns.RefreshInfoBars, "EnsureModules"), "EnsureSlotModules")
local tooltipByID = upvalue(upvalue(ensureSlot, "CreateTextModule"), "tooltipByID")
local memory = upvalue(tooltipByID.fps, "UpdateAddonMemory")
local cpu = upvalue(tooltipByID.fps, "UpdateAddonCPU")
local addonInfo = upvalue(memory, "addonInfo")
for _ = 1, 20 do assert(memory() == 30) end
assert(sorts == 1 and memoryScans == 1 and addonInfo[1].index == 2)
cpu(); cpu()
assert(sorts == 2 and addonInfo[1].index == 1)
memory(); memory()
assert(sorts == 3 and memoryScans == 1 and addonInfo[1].index == 2)
clock = 32
memory()
assert(sorts == 4 and memoryScans == 2)
local coreFile = assert(io.open("QFXSystemBar/QFXSystemBar.lua", "rb"))
local core = coreFile:read("*a"):gsub("\r\n", "\n")
coreFile:close()
local memoryCode = assert(core:match("    local qfxMenuAddonInfo = {}\n(.-)\n    local function ShowGameMenuTooltip"))
local menuMemory = assert(load("local qfxMenuAddonInfo = {}\n" .. memoryCode .. "\nreturn UpdateQFXMenuAddonMemory", "menu memory cache", "t", env))()
sorts, memoryScans = 0, 0
for _ = 1, 20 do assert(menuMemory() == 30) end
assert(sorts == 1 and memoryScans == 1, "menu hover re-sorted an unchanged memory snapshot")
clock = 63
menuMemory()
assert(sorts == 2 and memoryScans == 2)

-- Parent visibility (Alt+Z/cinematics) stops menu polling too, and showing the
-- same secure host resumes it without needing another settings refresh.
local menuHost, clockStarts, clockStops, fpsStates = frame(), 0, 0, {}
menuHost.alpha = 1
function menuHost:GetAlpha() return self.alpha end
env.QFXSystemBarFrame = menuHost
local visibleCode = assert(core:match("    local function IsQFXMenuVisible%(%).-\n    end\n"))
env.IsQFXMenuVisible = assert(load(visibleCode .. "\nreturn IsQFXMenuVisible", "menu visibility", "t", env))()
env.IsMicroMenuEnabledNow = function() return true end
env.qfxClockButtons = { menuHost }
env.RefreshQFXClockWidgets = function() end
env.StartQFXClockTicker = function() clockStarts = clockStarts + 1 end
env.StopQFXClockTicker = function() clockStops = clockStops + 1 end
local pulseCode = assert(core:match("    RefreshPulseTickerState = function%(%).-\n    end\n"))
assert(load(pulseCode, "menu ticker visibility", "t", env))()
env.RefreshMenuFPSState = function() fpsStates[#fpsStates + 1] = env.IsQFXMenuVisible() end
env.CreateFrame = function() return menuHost end
env.ns = ns
env.IsCombatLocked = function() return false end
env.PlaceQFXMicroMenu, env.RebuildQFXMicroMenu = function() end, function() end
db.isCustomMicroMenu = true
local hostCode = assert(core:match("    local function CreateQFXMicroMenuHost%(%).-\n    end\n"))
assert(load("local qfxMicroMenuFrame\n" .. hostCode .. "\nCreateQFXMicroMenuHost()", "menu host visibility hooks", "t", env))()
menuHost.visible = false
menuHost.OnHide()
assert(clockStops == 1 and fpsStates[1] == false)
menuHost.visible = true
menuHost.OnShow()
assert(clockStarts == 1 and fpsStates[2] == true)
menuHost.alpha = 0
env.RefreshPulseTickerState()
assert(clockStops == 2, "alpha-hidden menu kept its clock ticker")

-- Top-center placement unsubscribes after initialization and only waits for
-- combat when there is a protected anchor change to flush.
local topNS, topFrames, timers, combat = {}, {}, {}, false
local target = frame()
local topEnv = setmetatable({
    QFXSystemBarDB = { topCenterWidget = { positionMode = "custom", x = 10, y = -20, locked = true } },
    UIWidgetTopCenterContainerFrame = target, QFXSystemBarFrame = frame(),
    InCombatLockdown = function() return combat end,
    C_AddOns = { IsAddOnLoaded = function() return true end },
    C_Timer = { After = function(_, callback) timers[#timers + 1] = callback end },
    CreateFrame = function() local value = frame(); topFrames[#topFrames + 1] = value; return value end,
}, { __index = _G })
topEnv._G = topEnv
assert(loadfile("QFXSystemBar/TopCenterWidget.lua", "t", topEnv))("QFXSystemBar", topNS)
local topEvents, top = topFrames[1], topNS.TopCenterWidget
assert(not topEvents.events.PLAYER_REGEN_ENABLED)
top:OnDatabaseReady()
topEvents.OnEvent(topEvents, "PLAYER_ENTERING_WORLD")
assert(#timers == 1)
table.remove(timers, 1)()
assert(next(topEvents.events) == nil, "initialized position manager retained idle events")
combat = true
top:ApplyCustomTopCenterWidgetPosition(30, -40, true)
assert(topEvents.events.PLAYER_REGEN_ENABLED and target.point[4] == 10)
combat = false
topEvents.OnEvent(topEvents, "PLAYER_REGEN_ENABLED")
assert(target.point[4] == 30 and target.point[5] == -40 and next(topEvents.events) == nil)

-- MeetingStone repair has no events when absent/already loaded, while a
-- genuinely queued protected repair is still applied once after combat.
local function loadCombatFix(present, loaded, inCombat)
    local fixNS, fixFrame, attributes = {}, nil, 0
    local panel = present and { SetAttribute = function() attributes = attributes + 1 end } or nil
    local fixEnv = setmetatable({
        QFXSystemBarNS = fixNS, MainPanel = panel,
        InCombatLockdown = function() return inCombat end,
        C_AddOns = {
            GetAddOnMetadata = function() return present and "1.0" or nil end,
            IsAddOnLoaded = function() return loaded end,
        },
        CreateFrame = function() fixFrame = frame(); return fixFrame end,
    }, { __index = _G })
    fixEnv._G = fixEnv
    assert(loadfile("QFXSystemBar_MeetingStone/MeetingStoneCombatFix.lua", "t", fixEnv))("QFXSystemBar_MeetingStone", fixNS)
    return fixFrame, function() inCombat = false; fixFrame.OnEvent(fixFrame, "PLAYER_REGEN_ENABLED"); return attributes end
end
local absent = loadCombatFix(false, false, false)
assert(next(absent.events) == nil, "absent MeetingStone retained compatibility listeners")
local repaired = loadCombatFix(true, true, false)
assert(next(repaired.events) == nil, "already repaired MeetingStone retained idle listeners")
local waiting, flush = loadCombatFix(true, true, true)
assert(waiting.events.PLAYER_REGEN_ENABLED and flush() == 5 and next(waiting.events) == nil)
print("RuntimePerformance_test: 3 info strips -> 1 FPS/latency query; hidden tickers and idle compatibility/position listeners -> 0")
