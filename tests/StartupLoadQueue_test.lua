-- Regression coverage for login-deferred, one-child-per-tick startup loads.
local function expect(condition, message)
    if not condition then error(message or "expectation failed", 2) end
end

local function wipeTable(tbl)
    for key in pairs(tbl) do tbl[key] = nil end
end

wipe = wipeTable
GetLocale = function() return "enUS" end
SlashCmdList = {}

local addonLoadedCallback
local playerLoginCallback
EventUtil = {
    ContinueOnAddOnLoaded = function(_, callback)
        addonLoadedCallback = callback
    end,
    ContinueOnPlayerLogin = function(callback)
        playerLoginCallback = callback
    end,
}

local timers = {}
C_Timer = {
    After = function(delay, callback)
        timers[#timers + 1] = { delay = delay, callback = callback }
    end,
}

local function TickOneTimer()
    local timer = table.remove(timers, 1)
    expect(timer, "expected a pending startup-load timer")
    timer.callback()
    return timer.delay
end

local ns = {
    defaults = {
        language = "auto",
        isInfoBar = false,
    },
}

assert(loadfile("QFXSystemBar/Core.lua"))("QFXSystemBar", ns)
expect(type(addonLoadedCallback) == "function", "base addon callback was not registered")
expect(type(playerLoginCallback) == "function", "player login callback was not registered")

QFXSystemBarDB = {
    language = "enUS",
    isInfoBar = true,
}

local infoBarLoads = 0
local meetingStoneLoads = 0
local allowMeetingStone = true
ns.EnsureInfoBarLoaded = function()
    infoBarLoads = infoBarLoads + 1
    ns.InfoBarLoaded = true
    return true
end
ns.QueueMeetingStoneBridgeStartupLoad = function()
    if not allowMeetingStone then return false end
    return ns.QueueStartupLoad("meetingstone-bridge", function()
        meetingStoneLoads = meetingStoneLoads + 1
        ns.MeetingStoneBridgeLoaded = true
    end)
end

addonLoadedCallback()
expect(infoBarLoads == 0, "InfoBar loaded synchronously from ADDON_LOADED")
expect(#timers == 0, "ADDON_LOADED unexpectedly scheduled an optional child")

playerLoginCallback()
expect(infoBarLoads == 0 and meetingStoneLoads == 0, "optional children loaded synchronously at login")
expect(#timers == 1, "login must schedule exactly one active startup tick")
expect(ns.QueueStartupLoad("info-bar", function() error("duplicate callback ran") end) == false,
    "a duplicate startup key was accepted")
expect(#timers == 1, "duplicate work scheduled another startup tick")

expect(TickOneTimer() == 0.25, "the first child load must wait until login settles")
expect(infoBarLoads == 1 and meetingStoneLoads == 0, "the first tick did not load only InfoBar")
expect(#timers == 1, "the remaining child did not receive one follow-up tick")

expect(TickOneTimer() == 0.10, "follow-up child loads must use the short interval")
expect(infoBarLoads == 1 and meetingStoneLoads == 1, "MeetingStone did not load on its own tick")
expect(#timers == 0, "startup queue did not drain cleanly")

-- One optional child must not strand the rest of the queue if it errors.
local afterErrorLoads = 0
ns.QueueStartupLoad("failing-child", function() error("intentional startup test error") end)
ns.QueueStartupLoad("after-error", function() afterErrorLoads = afterErrorLoads + 1 end)
expect(TickOneTimer() == 0.25, "an error test queue did not use the initial delay")
expect(#timers == 1, "a failed child stranded the remaining startup queue")
expect(TickOneTimer() == 0.10, "post-error child did not retain the stagger interval")
expect(afterErrorLoads == 1, "the child after a startup error did not run")

-- Feature state is checked again when deferred work runs.
ns.InfoBarLoaded = nil
QFXSystemBarDB.isInfoBar = true
allowMeetingStone = false
playerLoginCallback()
QFXSystemBarDB.isInfoBar = false
expect(TickOneTimer() == 0.25, "a fresh queue must restore the initial delay")
expect(infoBarLoads == 1, "InfoBar loaded after being disabled while queued")
expect(#timers == 0, "disabled deferred work left an extra timer")

print("Startup load queue tests passed")
