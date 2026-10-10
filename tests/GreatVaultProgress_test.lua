local ns = { T = function(key) return key end }
local types = { Raid = 1, Activities = 2, World = 3, RankedPvP = 4 }
local activities, rewards = {}, false
local created, eventFrame = 0
local env = setmetatable({
    Enum = { WeeklyRewardChestThresholdType = types },
    C_WeeklyRewards = {
        GetActivities = function() return activities end,
        HasAvailableRewards = function() return rewards end,
    },
    CreateFrame = function(kind)
        assert(kind == "Frame")
        created = created + 1
        eventFrame = {
            events = {},
            RegisterEvent = function(self, event) self.events[event] = true end,
            UnregisterAllEvents = function(self) self.events = {} end,
            SetScript = function(self, event, callback) self[event] = callback end,
        }
        return eventFrame
    end,
}, { __index = _G })
assert(loadfile("QFXSystemBar/GreatVault.lua", "t", env))("QFXSystemBar", ns)
assert(created == 0, "progress module created an idle event frame")
local function add(kind, progress, thresholds)
    for index, threshold in ipairs(thresholds) do
        activities[#activities + 1] = { type = kind, index = index, progress = progress, threshold = threshold }
    end
end
add(types.Raid, 6, { 2, 4, 6 })
add(types.Activities, 5, { 1, 4, 8 })
add(types.World, 10, { 2, 4, 8 })
activities[#activities + 1] = { type = 99, index = 1, progress = 100, threshold = 100 }
activities[#activities + 1] = { type = types.Raid, progress = 0, threshold = 0 }
local rows = ns.GetGreatVaultProgressRows()
assert(#rows == 3 and rows[1].labelKey == "Raids" and rows[2].labelKey == "Dungeons" and rows[3].labelKey == "World Activities")
assert(rows[1].progress == 6 and rows[1].threshold == 6 and rows[1].unlocked == 3)
assert(rows[2].progress == 5 and rows[2].threshold == 8 and rows[2].unlocked == 2)
assert(rows[3].progress == 8 and rows[3].threshold == 8 and rows[3].unlocked == 3)
assert(activities[7].progress == 10, "vault helper mutated Blizzard's activity data")
local text = table.concat(ns.GetGreatVaultTooltipLines(), "\n")
assert(text:find("6/6", 1, true) and text:find("5/8", 1, true) and text:find("8/8", 1, true))
assert(text:find("Reward Slots: 8/9", 1, true))
activities[#activities + 1] = activities[1]
assert(ns.GetGreatVaultProgressRows()[1].total == 3, "duplicate slots changed the reward count")
rewards = true
assert(table.concat(ns.GetGreatVaultTooltipLines()):find("Rewards available to claim.", 1, true))
activities, rewards = {}, false
add(types.World, 5, { 3, 6, 9 })
rows = ns.GetGreatVaultProgressRows()
assert(#rows == 1 and rows[1].progress == 5 and rows[1].threshold == 9 and rows[1].unlocked == 1, "season thresholds were hardcoded")
activities = {}
assert(table.concat(ns.GetGreatVaultTooltipLines()):find("Loading Great Vault progress...", 1, true))
local vaultAPI = env.C_WeeklyRewards
env.C_WeeklyRewards = nil
assert(ns.GetGreatVaultProgressRows() == nil)
assert(table.concat(ns.GetGreatVaultTooltipLines()):find("The Great Vault is unavailable.", 1, true))

local function owner()
    return {
        shown = true, hovered = true,
        IsShown = function(self) return self.shown end,
        IsMouseOver = function(self) return self.hovered end,
        HookScript = function(self, event, callback) self[event] = callback end,
    }
end
local first, second = owner(), owner()
local refreshed, hidden = 0, 0
ns.TrackGreatVaultTooltip(first, function() refreshed = refreshed + 1 end, function() hidden = hidden + 1 end)
assert(created == 1 and eventFrame.events.WEEKLY_REWARDS_UPDATE and eventFrame.events.CHALLENGE_MODE_COMPLETED)
eventFrame.OnEvent()
assert(refreshed == 1)
ns.TrackGreatVaultTooltip(second, function() refreshed = refreshed + 1 end, function() hidden = hidden + 1 end)
assert(hidden == 1 and created == 1)
first.OnHide(first)
assert(eventFrame.events.WEEKLY_REWARDS_UPDATE, "old owner's hide stopped the current tooltip")
eventFrame.OnEvent()
assert(refreshed == 2)
second.hovered = false
eventFrame.OnEvent()
assert(refreshed == 2 and hidden == 2 and next(eventFrame.events) == nil)
ns.TrackGreatVaultTooltip(first, function() refreshed = refreshed + 1 end, function() hidden = hidden + 1 end)
first.OnHide(first)
assert(hidden == 3 and next(eventFrame.events) == nil, "hide leaked tooltip event registrations")

-- Exercise the shared native renderer and ownership-aware cleanup.
env.C_WeeklyRewards = vaultAPI
activities = {}
add(types.Raid, 6, { 2, 4, 6 })
local tip = {
    lines = {},
    SetOwner = function(self, frame) self.owner = frame end,
    IsOwned = function(self, frame) return self.owner == frame end,
    ClearAllPoints = function() end,
    SetPoint = function(self, point) self.point = point end,
    ClearLines = function(self) self.lines = {} end,
    AddLine = function(self, text) self.lines[#self.lines + 1] = text end,
    Show = function(self) self.shown = true end,
    Hide = function(self) self.shown = false; self.owner = nil end,
}
env.GameTooltip = tip
env.UIParent = { GetHeight = function() return 900 end }
first.GetCenter = function() return 0, 800 end
second.GetCenter = function() return 0, 100 end
second.hovered = true
ns.ShowGreatVaultTooltip(first)
local firstText = table.concat(tip.lines, "\n")
assert(tip.owner == first and tip.point == "TOP" and firstText:find("6/6", 1, true))
ns.ShowGreatVaultTooltip(second)
assert(tip.owner == second and tip.point == "BOTTOM" and table.concat(tip.lines, "\n") == firstText)
for _, activity in ipairs(activities) do activity.progress = 5 end
eventFrame.OnEvent()
assert(table.concat(tip.lines, "\n"):find("5/6", 1, true), "native tooltip did not refresh live progress")
local foreign = {}
tip.owner = foreign
second.OnHide(second)
assert(tip.owner == foreign and tip.shown and next(eventFrame.events) == nil, "vault cleanup hid another tooltip")
print("GreatVaultProgress_test: dynamic thresholds, completion, slots, missing data and hover-only event lifecycle passed")
