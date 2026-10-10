local ns = {}
local owned, usable, cooldown = false, true, 0
local env = setmetatable({
    InCombatLockdown = function() return false end,
    PlayerHasToy = function(id) return id == 264367 and owned end,
    C_ToyBox = { IsToyUsable = function(id) assert(id == 264367); return usable end },
    C_Item = {
        GetItemCount = function() return 0 end,
        GetItemCooldown = function() return 100, cooldown, true end,
        GetItemNameByID = function() return nil end,
    },
    GetTime = function() return 100 end,
}, { __index = _G })
assert(loadfile("QFXSystemBar/Defaults.lua", "t", env))("QFXSystemBar", ns)
local value = "264367"
assert(ns.GetHearthstoneActionData(value).itemID == 264367)
assert(ns.BuildHearthstoneMacro(value) == "/use item:264367")
assert(#ns.GetAvailableRandomHearthstones() == 0, "unowned hearthspore entered the random pool")
owned = true
assert(#ns.GetAvailableRandomHearthstones() == 1 and ns.GetAvailableRandomHearthstones()[1] == 264367)
local found
for _, option in ipairs(ns.GetHearthstoneDropdownOptions()) do
    if option.value == value then found = true end
end
assert(found, "owned hearthspore is missing from the click-action dropdown")
assert(ns.PickRandomHearthstoneItemID("right") == 264367)
usable = false
assert(ns.PickRandomHearthstoneItemID("right") == nil, "character-ineligible hearthspore was chosen")
usable, cooldown = true, 30
assert(not ns.IsRandomHearthstoneUsable(264367), "cooling hearthspore was treated as ready")
cooldown = 0
assert(ns.IsRandomHearthstoneUsable(264367))
print("Hearthspore_test: owned dropdown, fixed macro, random pool, character usability and cooldown passed")
