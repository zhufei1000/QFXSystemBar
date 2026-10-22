local function read(path)
    local file = assert(io.open(path, "rb"))
    local source = file:read("*a"):gsub("\r\n", "\n")
    file:close()
    return source
end

local source = read("QFXSystemBar_InfoBar/InfoBar.lua")
local db, money = {}, 10000000
local ns = { T = function(key) return key end }
local tip = { rows = {} }
function tip:ClearLines() self.rows = {} end
function tip:AddLine() end
function tip:AddDoubleLine(label, value) self.rows[label] = value end
function tip:Show() self.draws = (self.draws or 0) + 1 end
function tip:IsOwned(owner) return self.owner == owner end
function tip:SetOwner(owner) self.owner = owner end
function tip:ClearAllPoints() end
function tip:SetPoint() end

local env = setmetatable({
    ns = ns,
    _G = { QFXSystemBarNS = ns, QFXSystemBarDB = db },
    QFXSystemBarDB = db,
    GetMoney = function() return money end,
    GetRealmName = function() return "TestRealm" end,
    UnitName = function() return "Tester" end,
    GetTime = function() return 50 end,
    IsLoggedIn = function() return true end,
    GameTooltip = tip,
    UIParent = { GetHeight = function() return 1080 end },
    StaticPopupDialogs = {},
    C_Timer = { NewTimer = function() return { Cancel = function() end } end },
    CreateFrame = function()
        return {
            RegisterEvent = function() end,
            UnregisterEvent = function() end,
            SetScript = function(self, event, callback) self[event] = callback end,
        }
    end,
}, { __index = _G })
-- Load both complete files in TOC order. Do not supply exports from the test:
-- doing so hides functions accidentally exported outside their local scope.
assert(loadfile("QFXSystemBar_InfoBar/InfoBar.lua", "t", env))("QFXSystemBar_InfoBar", ns)
assert(type(ns.FormatInfoBarMoney) == "function", "full module load lost the copper formatter")
assert(type(ns.FormatInfoBarSignedMoney) == "function", "full module load lost the signed money formatter")
assert(type(ns.SetInfoBarTooltipOwner) == "function", "full module load lost the tooltip owner helper")
assert(loadfile("QFXSystemBar_InfoBar/InfoBar-Extra.lua", "t", env))("QFXSystemBar_InfoBar", ns)

local function plain(value)
    return (value:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""))
end

local function expectRow(label, expected)
    local actual = plain(assert(tip.rows[label], "missing tooltip row: " .. label))
    assert(actual == expected, label .. ": expected " .. expected .. ", got " .. actual)
end

local function owner()
    return {
        shown = true, hovered = true,
        IsShown = function(self) return self.shown end,
        IsMouseOver = function(self) return self.hovered end,
    }
end
local first, second = owner(), owner()

local session = ns.EnsureInfoBarMoneySession()
assert(session.earned == 0 and session.spent == 0 and session.lastMoney == money)
ns.ShowInfoBarGoldTooltip(first)
expectRow("Session Earned", "0c")
expectRow("Session Spent", "0c")
expectRow("Session Net", "0c")

money = money + 1250345
ns.UpdateInfoBarMoneySession()
money = money - 23456
ns.UpdateInfoBarMoneySession()
ns.ShowInfoBarGoldTooltip(first)
assert(session.earned == 1250345 and session.spent == 23456)
assert(session.earned - session.spent == money - session.startMoney)
expectRow("Session Earned", "+125g 3s 45c")
expectRow("Session Spent", "-2g 34s 56c")
expectRow("Session Net", "+122g 68s 89c")
ns.UpdateInfoBarMoneySession()
assert(session.earned == 1250345 and session.spent == 23456, "unchanged balance was counted twice")

-- Losses and copper-only spending keep their sign and precision.
db.infoBarMoneySession = nil
ns.EnsureInfoBarMoneySession()
money = money - 37
ns.ShowInfoBarGoldTooltip(first)
expectRow("Session Earned", "0c")
expectRow("Session Spent", "-37c")
expectRow("Session Net", "-37c")

-- The parent owns login/reload initialization, even before the LoD child loads.
local core = read("QFXSystemBar/QFXSystemBar.lua")
local initCode = assert(core:match("            if isInitialLogin or isReloadingUI then\n(.-)\n            end\n\n            if ShouldLoadMeetingStoneBridge"))
env.QFXSystemBarDB = db
local initialize = assert(load("return function(isInitialLogin, isReloadingUI)\n" .. initCode .. "\nend", "login money baseline", "t", env))()
session = db.infoBarMoneySession
initialize(false, true)
assert(db.infoBarMoneySession == session and session.spent == 37, "reload reset session totals")
money = money + 103
ns.UpdateInfoBarMoneySession()
assert(session.earned == 103 and session.spent == 37, "reload baseline lost a subsequent change")
initialize(false, false)
assert(session.earned == 103 and session.spent == 37, "world transition reset session totals")
money = 900000
initialize(true, false)
assert(session.earned == 0 and session.spent == 0 and session.startMoney == money and session.lastMoney == money,
    "character login retained another session's totals")

-- Money events must redraw only a visible, hovered gold tooltip they own.
env.EVENT_ITEM_REFRESH = assert(load("return " .. assert(source:match("local EVENT_ITEM_REFRESH = (%b{})"))))()
env.modules = { left = { gold = first }, right = { gold = second } }
env.tooltipByID = { gold = function(frame) ns.ShowInfoBarGoldTooltip(frame) end }
local textRefreshes = 0
env.RefreshEnabledItems = function() textRefreshes = textRefreshes + 1 end
env.CreateFrame = function()
    return { SetScript = function(self, event, callback) self[event] = callback end }
end
local register = assert(load(assert(source:match("local function RegisterEvents.-\nend\n")) .. "\nreturn RegisterEvents", "money events", "t", env))()
register()
local function fire(event) env.eventFrame.OnEvent(env.eventFrame, event) end
ns.ShowInfoBarGoldTooltip(second)
local draws = tip.draws
money = money + 20000
fire("PLAYER_MONEY")
assert(tip.draws == draws + 1 and tip.owner == second, "money event left the owned gold tooltip stale")
expectRow("Session Earned", "+2g")
expectRow("Session Net", "+2g")
money = money - 10101
fire("PLAYER_MONEY")
expectRow("Session Spent", "-1g 1s 1c")
expectRow("Session Net", "+98s 99c")
assert(textRefreshes == 2, "money event lost its info-bar text refresh")

local earned, spent = session.earned, session.spent
for _, event in ipairs({ "SEND_MAIL_MONEY_CHANGED", "SEND_MAIL_COD_CHANGED", "PLAYER_TRADE_MONEY", "TRADE_MONEY_CHANGED", "BAG_UPDATE_DELAYED" }) do
    fire(event)
end
assert(session.earned == earned and session.spent == spent, "auxiliary events counted the same balance twice")

-- Other tooltips, hidden buttons, and buttons no longer hovered stay untouched.
local foreign = {}
tip.owner, draws = foreign, tip.draws
money = money + 100
fire("PLAYER_MONEY")
assert(tip.owner == foreign and tip.draws == draws, "money event replaced a foreign tooltip")
tip.owner, second.shown = second, false
fire("PLAYER_MONEY")
assert(tip.draws == draws, "money event reopened a hidden tooltip")
second.shown, second.hovered = true, false
fire("PLAYER_MONEY")
assert(tip.draws == draws, "money event reopened a tooltip after mouse leave")

-- Existing nonzero SavedVariables must display without resetting the session.
db.infoBarMoneySession = {
    initialized = true, startMoney = 103713274, lastMoney = 105463274,
    earned = 1750000, spent = 0,
}
money = db.infoBarMoneySession.lastMoney
ns.ShowInfoBarGoldTooltip(first)
expectRow("Session Earned", "+175g")
expectRow("Session Spent", "0c")
expectRow("Session Net", "+175g")
assert(db.infoBarMoneySession.earned == 1750000, "rendering reset a saved session")

print("InfoBarMoney_test: full module exports, saved totals, copper precision, reload/login and owned-tooltip event refresh passed")
