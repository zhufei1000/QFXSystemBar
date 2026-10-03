-- Exercise production selection and PreClick with mutable toy/character state.
local function read(path)
    local file = assert(io.open(path, "rb"))
    local source = file:read("*a"):gsub("\r\n", "\n")
    file:close()
    return source
end

local ns = {
    HEARTHSTONE_RANDOM_VALUE = "random",
    hearthstoneActionList = {
        { value = "6948", itemID = 6948 },
        { value = "101", itemID = 101 },
        { value = "102", itemID = 102 },
        { value = "103", itemID = 103 },
        { value = "104", itemID = 104 },
    },
    randomHearthstoneExcludedItemIDs = { [6948] = true },
}
local owned = { [101] = true, [102] = true, [103] = true }
local usable = { [101] = false, [102] = true, [103] = true }
local cooldowns = { [102] = { 500, 200, true }, [103] = { 0, 0, true } }
local bagItems = { [6948] = 1 }
local combat, now, usabilityChecks = false, 600, 0
local env = setmetatable({
    ns = ns,
    QFXSystemBarDB = {
        customMicroMenuHearthstoneLeft = "6948",
        customMicroMenuHearthstoneMiddle = "none",
        customMicroMenuHearthstoneRight = "random",
    },
    InCombatLockdown = function() return combat end,
    GetTime = function() return now end,
    PlayerHasToy = function(id) return owned[id] or false end,
    C_ToyBox = {
        IsToyUsable = function(id)
            assert(not combat, "queried toy usability in combat")
            usabilityChecks = usabilityChecks + 1
            return usable[id] or false
        end,
    },
    C_Item = {
        GetItemCount = function(id) return bagItems[id] or 0 end,
        IsUsableItem = function(id) return bagItems[id] ~= nil end,
        GetItemCooldown = function(id)
            assert(not combat, "queried cooldown in combat")
            return table.unpack(cooldowns[id] or { 0, 0, true })
        end,
    },
}, { __index = _G })
local helpers = assert(read("QFXSystemBar/Defaults.lua"):match(
    "(local function PlayerOwnsHearthstoneItem.-)\nlocal function GetItemIconMarkup"))
assert(load(helpers, "hearthstone-helpers", "t", env))()
local buttonCode = assert(read("QFXSystemBar/QFXSystemBar.lua"):match(
    "(    local HEARTHSTONE_SIDE_SETTINGS.-)\n    local function GetHearthstoneTooltipLines"))
local configure, preClick = assert(load(buttonCode ..
    "\nreturn ConfigureHearthstoneButton, HearthstoneButtonPreClick", "hearthstone-button", "t", env))()
local button = { attributes = {}, writes = 0 }
function button:SetAttribute(key, value)
    assert(not combat, "changed a protected attribute in combat")
    self.attributes[key] = value
    self.writes = self.writes + 1
end
function button:EnableMouse(value) self.mouseEnabled = value end

math.randomseed(29)
configure(button)
assert(button.attributes.macrotext2 == "/use item:103", "selected an unusable or cooling toy")
assert(button.attributes.macrotext1 == "/use item:6948", "changed the fixed action")
assert(button.attributes.type3 == nil, "enabled the no-action binding")
assert(button.mouseEnabled, "button cannot recover from an empty pool")

-- The old preselected toy becomes unusable; the same click must use toy 102.
usable[103] = false
cooldowns[102] = { 500, 100, true }
preClick(button, "RightButton", false)
assert(button.attributes.macrotext2 == "/use item:102", "first click used the stale preselected toy")
assert(not button.attributes.macrotext2:find("/run", 1, true), "still refreshes after /use")

-- All usable toys cooling down must retain a native action for the error.
cooldowns[102] = { 500, 200, true }
preClick(button, "RightButton", false)
assert(button.attributes.macrotext2 == "/use item:102", "all cooldowns cleared the action")
now = 700
preClick(button, "RightButton", false)
assert(button.attributes.macrotext2 == "/use item:102", "did not recover when cooldown expired")

usable[102] = false
preClick(button, "RightButton", false)
assert(button.attributes.type2 == nil, "used a character-ineligible toy")
usable[103] = true
preClick(button, "RightButton", false)
assert(button.attributes.macrotext2 == "/use item:103", "empty pool did not recover on the next click")

-- Fixed/no-action clicks must not consume the other side's random deck.
local writes, checks = button.writes, usabilityChecks
preClick(button, "LeftButton", false)
preClick(button, "MiddleButton", false)
preClick(button, "RightButton", true)
assert(button.writes == writes and usabilityChecks == checks, "unrelated click advanced random state")
env.QFXSystemBarDB.customMicroMenuHearthstoneLeft = "random"
configure(button)
local rightDeck = ns._randomHearthstoneDecksByKey.customMicroMenuHearthstoneRight
local rightSignature = ns._randomHearthstoneDeckSignaturesByKey.customMicroMenuHearthstoneRight
preClick(button, "LeftButton", false)
assert(ns._randomHearthstoneDecksByKey.customMicroMenuHearthstoneRight == rightDeck,
    "left click replaced the right deck")
assert(ns._randomHearthstoneDeckSignaturesByKey.customMicroMenuHearthstoneRight == rightSignature)

combat = true
writes, checks = button.writes, usabilityChecks
preClick(button, "RightButton", false)
assert(button.writes == writes and usabilityChecks == checks, "combat click refreshed insecure state")
assert(not ns.IsRandomHearthstoneUsable(103), "helper queried restricted state in combat")
combat = false

-- Ownership updates must add toys without resetting decks on unrelated bag changes.
local _, changed = ns.RefreshRandomHearthstoneCache()
assert(not changed, "unchanged inventory reset the decks")
owned[104], usable[104] = true, true
usable[103] = false
_, changed = ns.RefreshRandomHearthstoneCache()
assert(changed and ns.PickRandomHearthstoneItemID("right") == 104, "new toy not added to selection")
owned[104] = nil
ns.RefreshRandomHearthstoneCache()
assert(ns.PickRandomHearthstoneItemID("right") == nil, "removed toy remained selectable")
bagItems[104] = 1
ns.RefreshRandomHearthstoneCache()
assert(ns.PickRandomHearthstoneItemID("right") == 104, "bag-only hearthstone did not use item usability")

-- Legacy cooldown helpers use numeric enable flags; absent APIs stay compatible.
env.C_Item.GetItemCooldown = nil
env.GetItemCooldown = function() return 0, 0, 0 end
assert(not ns.IsRandomHearthstoneUsable(104), "ignored disabled legacy cooldown flag")
env.GetItemCooldown = function() return 0, 0, 1 end
assert(ns.IsRandomHearthstoneUsable(104), "legacy ready cooldown rejected")
env.GetItemCooldown = nil
env.C_ToyBox = nil
usable[103] = true
assert(ns.IsRandomHearthstoneUsable(103), "missing toy API broke compatibility")
assert(ns.BuildHearthstoneMacro("none") == nil)
assert(ns.BuildHearthstoneMacro("6948") == "/use item:6948")
print("Random hearthstone click tests passed")
