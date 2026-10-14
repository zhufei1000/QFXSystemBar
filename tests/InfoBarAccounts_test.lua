-- Account gold snapshots, warband-aware totals and the two-step clear flow
-- for InfoBar-Extra.lua (crests + account gold info-bar module).
local ns = {
    T = function(key) return key end,
    -- labelKey fallback for crest display names; the real table is built by
    -- InfoBar.lua.
    InfoBarItems = {
        crest_adventurer = { labelKey = "Adventurer Crest" },
        crest_veteran = { labelKey = "Veteran Crest" },
    },
}
local db = {}
local env = setmetatable({
    ns = ns,
    _G = { QFXSystemBarNS = ns, QFXSystemBarDB = db },
    GetRealmName = function() return "TestRealm" end,
    UnitName = function() return "Tester" end,
    time = function() return 1000 end,
    print = function() end,
    IsShiftKeyDown = function() return false end,
}, { __index = _G })
local money = 5000000000 -- 500,000 gold in copper
local now = 50
local currencyInfoCalls = 0
env.GetMoney = function() return money end
env.GetTime = function() return now end
env.C_CurrencyInfo = {
    GetCurrencyInfo = function(id)
        currencyInfoCalls = currencyInfoCalls + 1
        if id == 3442 then
            return { name = "Adventurer Mistcrest", quantity = 321, iconFileID = 111 }
        end
        return nil
    end,
}
assert(loadfile("QFXSystemBar_InfoBar/InfoBar-Extra.lua", "t", env))("QFXSystemBar_InfoBar", ns)

-- Crest data and display name lookup (API name, cached, fallback label)
assert(ns.InfoBarCrestData.crest_adventurer.currencyID == 3442)
assert(ns.InfoBarCrestData.crest_mythic.currencyID == 3446)
assert(ns.GetInfoBarCrestDisplayName("crest_adventurer") == "Adventurer Mistcrest")
local callsAfterFirstLookup = currencyInfoCalls
assert(ns.GetInfoBarCrestDisplayName("crest_adventurer") == "Adventurer Mistcrest")
assert(currencyInfoCalls == callsAfterFirstLookup, "display name must be cached")
assert(ns.GetInfoBarCrestDisplayName("crest_veteran") == "Veteran Crest", "fallback label must be used when the API has no entry")
assert(ns.GetInfoBarCrestDisplayName("gold") == nil)

-- Recording the current character
assert(type(db.accountGold) ~= "table")
ns.RecordAccountGoldCharacter()
assert(type(db.accountGold) == "table")
assert(db.accountGold["TestRealm-Tester"].gold == 500000)
assert(db.accountGold["TestRealm-Tester"].updated == 1000)

-- Summary: totals, realm suffix for other realms, gold-descending order
db.accountGold["TestRealm-Alt"] = { gold = 120 }
db.accountGold["OtherRealm-Big"] = { gold = 9000 }
db.accountGold["TestRealm-Small"] = { gold = 5 }
money = 7000000000 -- 700,000 gold
ns.RecordAccountGoldCharacter()
assert(db.accountGold["TestRealm-Tester"].gold == 700000)
local summary = ns.GetAccountGoldSummary()
assert(summary.count == 4)
assert(summary.allTotal == 700000 + 120 + 9000 + 5)
assert(summary.otherTotal == 120 + 9000 + 5)
assert(#summary.others == 3)
assert(summary.others[1].name == "Big" and summary.others[1].realm == "OtherRealm" and summary.others[1].gold == 9000)
assert(summary.others[2].name == "Alt" and summary.others[3].name == "Small")

-- First Ctrl+click arms, second clears and re-records the current character
local shown = 0
local fakeOwner = {}
ns.ShowInfoBarGoldTooltip = function() shown = shown + 1 end
ns.HandleInfoBarGoldCtrlClick(fakeOwner)
assert(db.accountGold["TestRealm-Alt"] ~= nil, "first ctrl-click must only arm the confirmation")
assert(shown == 0)
now = 52
ns.HandleInfoBarGoldCtrlClick(fakeOwner)
assert(db.accountGold["TestRealm-Alt"] == nil and db.accountGold["OtherRealm-Big"] == nil)
assert(db.accountGold["TestRealm-Tester"] ~= nil, "current character must be re-recorded after a clear")
assert(shown == 1)

-- An expired confirmation only re-arms
db.accountGold["TestRealm-Alt"] = { gold = 120 }
now = 100
ns.HandleInfoBarGoldCtrlClick(nil)
now = 106 -- outside the 5 second window
ns.HandleInfoBarGoldCtrlClick(nil)
assert(db.accountGold["TestRealm-Alt"] ~= nil, "expired confirmation must not clear")

print("InfoBarAccounts_test: crest lookup, account gold recording, summary and clear confirmation passed")
