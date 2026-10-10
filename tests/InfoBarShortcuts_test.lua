local function read(path)
    local file = assert(io.open(path, "rb"))
    local data = file:read("*a"):gsub("\r\n", "\n")
    file:close()
    return data
end
local source = read("QFXSystemBar_InfoBar/InfoBar.lua")
local ns = { T = function(key) return key == "Vault" and "宝库" or key end }
local env = setmetatable({ ns = ns, _G = { QFXSystemBarNS = ns } }, { __index = _G })
local prefix = assert(source:match("(.-)\nlocal bars ="))
local order, index, normalizeMap = assert(load(prefix .. "\nreturn INFOBAR_ITEM_ORDER, INFOBAR_ITEM_INDEX, NormalizeInfoBarEnabledMap", "info bar registry", "t", env))("QFXSystemBar_InfoBar", ns)
assert(#order == 21 and ns.InfoBarMaxItems == 5)
for _, id in ipairs({ "greatvault", "mrt", "mdt" }) do
    assert(ns.InfoBarItems[id] and ns.NormalizeInfoBarItemID(id) == id)
    for _, slot in pairs(ns.InfoBarSlots) do
        assert(ns.defaults[slot.enabledKey][id] ~= true, "new shortcut overwrote default content")
    end
end
assert(ns.NormalizeInfoBarItemID("Great Vault") == "greatvault")
assert(ns.NormalizeInfoBarItemID("MRT") == "mrt" and ns.NormalizeInfoBarItemID("MDT") == "mdt")
env.INFOBAR_ITEM_ORDER, env.INFOBAR_ITEM_INDEX, env.NormalizeInfoBarEnabledMap = order, index, normalizeMap
local migration = assert(source:match("(local function InsertMissingInfoBarItem.-)\nlocal infoBarDefaultsEnsured"))
assert(load(migration, "info bar migration", "t", env))()
local db = { infoBarLeftOrder = { "gold", "fps", "ilvl" }, infoBarLeftItems = { gold = true, fps = false } }
ns.MigrateInfoBarSavedVariables(db)
local positions = {}
for position, id in ipairs(db.infoBarLeftOrder) do positions[id] = position end
assert(positions.gold < positions.fps and positions.fps < positions.ilvl, "migration changed the user's relative order")
assert(positions.greatvault == 19 and positions.mrt == 20 and positions.mdt == 21)
assert(db.infoBarLeftItems.gold == true and db.infoBarLeftItems.fps == false and db.infoBarLeftItems.greatvault == nil)
local firstOrder = table.concat(db.infoBarLeftOrder, ",")
ns.MigrateInfoBarSavedVariables(db)
assert(table.concat(db.infoBarLeftOrder, ",") == firstOrder, "migration is not idempotent")
local clicked, owner = {}, {}
for _, entry in ipairs({ { "greatvault", "ToggleGreatVault" }, { "mrt", "ToggleMRT" }, { "mdt", "ToggleMDT" } }) do
    local id = entry[1]
    ns[entry[2]] = function(frame, button)
        assert(frame == owner)
        if button == "LeftButton" then clicked[id] = (clicked[id] or 0) + 1 end
    end
end
env.BlockInCombat = function() error("info-bar shortcuts must delegate their combat behavior") end
local clickCode = assert(source:match("local function HandleClick.-\nend\n"))
local click = assert(load(clickCode .. "\nreturn HandleClick", "info bar clicks", "t", env))()
for _, id in ipairs({ "greatvault", "mrt", "mdt" }) do
    click(id, "LeftButton", owner)
    click(id, "RightButton", owner)
    click(id, "MiddleButton", owner)
    assert(clicked[id] == 1)
end
local funcs = assert(source:match("textFuncs = (%b{})"))
env.LT = ns.T
local textFuncs = assert(load("return " .. funcs, "info bar text", "t", env))()
assert(textFuncs.greatvault() == "宝库" and textFuncs.mrt() == "MRT" and textFuncs.mdt() == "MDT")
local iconCode = assert(source:match("local function UpdateInfoBarIconTextures.-\nend\n"))
local updateIcons = assert(load(iconCode .. "\nreturn UpdateInfoBarIconTextures", "text-only shortcuts", "t", env))()
for _, id in ipairs({ "greatvault", "mrt", "mdt" }) do
    assert(updateIcons({ CreateTexture = function() error("text shortcut created an icon") end }, id) == false)
end
local core = read("QFXSystemBar/QFXSystemBar.lua")
local exports = assert(core:match("(    ns.ToggleMDT = ToggleMDT.-)\n\n    local function ConfigureMacroButton"))
env.ToggleMDT, env.ToggleGreatVault, env.OpenMRT = function() end, function() end, function() end
assert(load(exports, "shared shortcut exports", "t", env))()
assert(ns.ToggleMDT == env.ToggleMDT and ns.ToggleGreatVault == env.ToggleGreatVault and ns.ToggleMRT == env.OpenMRT)
print("InfoBarShortcuts_test: text-only labels, shared click dispatch, optional defaults and stable migration passed")
