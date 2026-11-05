local function read(path)
    local file = assert(io.open(path, "rb"))
    local text = file:read("*a"):gsub("\r\n", "\n")
    file:close()
    return text
end

local function frame()
    return setmetatable({}, { __index = function(self, key)
        if key == "IsShown" or key == "IsVisible" then return function() return true end end
        return function() return self end
    end })
end

local function client(forever, versionFallback)
    local ns, disabled = {}, {}
    local env = setmetatable({
        WOW_PROJECT_ID = forever and 18 or 1,
        WOW_PROJECT_CAMELOT = not versionFallback and 18 or nil,
        GetBuildInfo = function() return forever and "1.60.1" or "12.1.5" end,
        GetLocale = function() return "enUS" end,
        UnitClass = function() return "Mage", "MAGE", 8 end,
        UnitFactionGroup = function() return "Alliance" end,
        Enum = { GameRule = { HousingDashboardDisabled = 1, FinderPanelDisabled = 2 } },
        C_GameRules = { IsGameRuleActive = function(rule) return disabled[rule] == true end },
        C_SpecializationInfo = {
            GetSpecialization = function() return 1 end,
            GetSpecializationInfo = function(index) return index + 100, "Test Talent", nil, 123 end,
            GetNumSpecializationsForClassID = function(classID) assert(classID == 8); return 1 end,
        },
        -- Forever does not load these deprecated shims.
        GetSpecialization = function() error("deprecated specialization API used") end,
        GetSpecializationInfo = function() error("deprecated specialization info used") end,
        GameRulesUtil = {
            EJIsDisabled = function() return disabled.ej == true end,
            RegisterSystemCallback = function(callback) ns.rulesChanged = callback end,
        },
        wipe = function(t) for key in pairs(t) do t[key] = nil end end,
        GetTime = function() return 1 end,
        StaticPopupDialogs = {},
        CreateFrame = frame,
        C_Timer = { After = function() end, NewTimer = function() return frame() end },
    }, { __index = _G })
    env._G, env.QFXSystemBarNS, env.QFXSystemBarDB = env, ns, {}
    for _, name in ipairs({ "CharacterMicroButton", "PlayerSpellsMicroButton", "TalentMicroButton",
        "SpellbookMicroButton", "LegacyMicroButton", "HousingMicroButton", "LFDMicroButton", "EJMicroButton" }) do
        env[name] = {}
    end
    assert(loadfile("QFXSystemBar/Compat.lua", "t", env))("QFXSystemBar", ns)
    assert(loadfile("QFXSystemBar/Defaults.lua", "t", env))("QFXSystemBar", ns)
    return ns, env, disabled
end

local ns, env, disabled = client(true)
assert(ns.Compat.IsForever and select(1, client(true, true)).Compat.IsForever)
assert(ns.Compat.GetSpecialization() == 1)
assert(select(2, ns.Compat.GetSpecializationInfo(1)) == "Test Talent")
assert(ns.Compat.GetNumSpecializations() == 1)
assert(ns.Compat.GetTalentButtonName() == "TalentMicroButton")

-- Preserve old choices, positions and unrelated button order on repeated loads.
local db = { isCustomMicroMenuPlayerSpells = false, isCustomMicroMenuLegacy = false,
    nativeMicroMenu = 2, bagBar = 3,
    customMicroMenuPositionX = 99, customMicroMenuButtonOrder = { "Time", "PlayerSpells", "Character", "Housing" } }
ns.MigrateForeverSettings(db)
assert(db.isCustomMicroMenuSpellBook == false and db.isCustomMicroMenuLegacy == false)
assert(db.customMicroMenuPositionX == 99)
assert(db.nativeMicroMenu == 2 and db.bagBar == 3, "migration overwrote saved visibility modes")
assert(ns.defaults.nativeMicroMenu == 0 and ns.defaults.bagBar == 0, "Forever must show native UI by default")
local expected = "Time,PlayerSpells,SpellBook,Legacy,Character,Housing"
assert(table.concat(db.customMicroMenuButtonOrder, ",") == expected)
ns.MigrateForeverSettings(db)
assert(table.concat(db.customMicroMenuButtonOrder, ",") == expected)
assert(ns.defaults.isCustomMicroMenuSpellBook and ns.defaults.isCustomMicroMenuLegacy)
assert(ns.IsMicroMenuButtonAvailable("PlayerSpells") and ns.IsMicroMenuButtonAvailable("SpellBook"))
disabled[1], disabled[2], disabled.ej = true, true, true
assert(not ns.IsMicroMenuButtonAvailable("Housing") and not ns.IsMicroMenuButtonAvailable("LFD"))
assert(not ns.IsMicroMenuButtonAvailable("EJ") and not ns.IsMicroMenuButtonAvailable("GreatVault"))
assert(not ns.IsMicroMenuButtonAvailable("MDT") and not ns.IsInfoBarItemAvailable("mdt"))
env.LegacyMicroButton = nil
assert(not ns.IsMicroMenuButtonAvailable("Legacy"))
env.LegacyMicroButton = {}

-- Exercise actual catalog and secure click binding, including the hidden
-- PlayerSpellsMicroButton that must not receive Forever's talent clicks.
local source = read("QFXSystemBar/QFXSystemBar.lua")
local catalog = assert(source:match("(    local qfxMenuDefinitions = {}.-)%s+%-%- Mouse%-button glyphs"))
env.ns, env.MICRO_ICON_PATH = ns, "Interface\\AddOns\\QFXSystemBar\\Media\\MicroMenu\\"
local _, byID = assert(load(catalog .. "\nreturn qfxMenuDefinitions, buttonDefByID", "catalog", "t", env))()
local function get(name)
    local code = assert(source:match("    local function " .. name .. ".-\n    end\n"))
    return assert(load(code .. "\nreturn " .. name, name, "t", env))()
end
env.ResolveNativeMicroButton = get("ResolveNativeMicroButton")
env.SetSecureClickAttribute = function(button, name, value) button[name] = value end
local assign = get("AssignButtonAction")
for id, target in pairs({ PlayerSpells = "TalentMicroButton", SpellBook = "SpellbookMicroButton", Legacy = "LegacyMicroButton" }) do
    local button = { EnableMouse = function(self, value) self.mouseEnabled = value end }
    assign(button, assert(byID[id]))
    assert(button.type1 == "click" and button.clickbutton1 == env[target] and button.mouseEnabled)
end
assert(byID.PlayerSpells.labelKey == "Talents" and byID.SpellBook.textureKey == "EJ")
local loads, warnings = 0, 0
ns.LoadOptionalAddOn = function() loads = loads + 1 end
env.PrintQFXWarning = function() warnings = warnings + 1 end
get("ToggleGreatVault")(nil, "LeftButton")
assert(loads == 0 and warnings == 1, "unavailable Vault loaded a Blizzard panel")
env.MythicDungeonToolsAPI = { ShowInterface = function() error("Forever opened MDT") end }
env.SlashCmdList = { MYTHICDUNGEONTOOLS = function() error("Forever called MDT slash entry") end }
get("ToggleMDT")(nil, "LeftButton")
assert(loads == 0, "unavailable MDT loaded a third-party addon")

-- No current candidates, unusable mounts and opposite-faction mounts must
-- never turn into SummonByID(0), which relies on Retail's favorites list.
local mounts = {
    [1] = { usable = true, collected = true },
    [2] = { usable = false, collected = true },
    [3] = { usable = true, collected = true, hidden = true },
    [4] = { usable = true, collected = true, factionSpecific = true, faction = 0 },
    [5] = { usable = true, collected = false },
}
env.C_MountJournal = {
    GetMountIDs = function() return { 1, 2, 3, 4, 5 } end,
    GetMountInfoByID = function(id)
        local m = mounts[id]
        return "Mount", id, 123, false, m.usable, 0, false, m.factionSpecific, m.faction, m.hidden, m.collected
    end,
}
assert(ns.Compat.ResolveRandomMount() == 1 and ns.Compat.GetRandomMountLabelKey() == "Random Mount")
mounts[1].usable = false
assert(ns.Compat.ResolveRandomMount() == nil)

-- Load the complete info-bar registry. Unsupported saved selections stay in
-- the DB but neither render nor consume the five-cell content budget.
assert(loadfile("QFXSystemBar_InfoBar/InfoBar.lua", "t", env))("QFXSystemBar_InfoBar", ns)
local slot = ns.InfoBarSlots.left
env.QFXSystemBarDB.isInfoBar = true
env.QFXSystemBarDB[slot.barEnabledKey] = true
env.QFXSystemBarDB[slot.orderKey] = { "mplus", "greatvault", "mdt", "crest_adventurer", "gold", "fps", "zone", "dura", "volume" }
env.QFXSystemBarDB[slot.enabledKey] = { mplus = true, greatvault = true, mdt = true, crest_adventurer = true,
    gold = true, fps = true, zone = true, dura = true, volume = true }
assert(ns.GetInfoBarEnabledCount("left") == 5)
assert(env.QFXSystemBarDB[slot.enabledKey].mplus and env.QFXSystemBarDB[slot.enabledKey].greatvault)
assert(env.QFXSystemBarDB[slot.enabledKey].crest_adventurer and env.QFXSystemBarDB[slot.enabledKey].volume)
assert(ns.SetInfoBarItemEnabled("left", "greatvault", true) == false)
assert(ns.SetInfoBarItemEnabled("left", "mdt", true) == false)
assert(env.QFXSystemBarDB[slot.enabledKey].mdt, "hidden MDT selection was cleared")

local infoSource = read("QFXSystemBar_InfoBar/InfoBar.lua")
local infoPrefix = assert(infoSource:match("(.-)\nlocal DEFAULT_INFOBAR_WIDTH"))
local specCode = assert(infoSource:match("local function GetSpecText.-\nend\n"))
env.MyColor = function() return "" end
local specText = assert(load(infoPrefix .. "\n" .. specCode .. "\nreturn GetSpecText", "specialization text", "t", env))("QFXSystemBar_InfoBar", ns)
assert(specText():find("Test Talent", 1, true), "info bar still uses deprecated specialization globals")
local clicked
env.SafeClickNativeButton = function(name) clicked = name; return true end
env.BlockInCombat = function() return false end
local openTalent = assert(infoSource:match("local function OpenTalentFrame.-\nend\n"))
assert(load(openTalent .. "\nreturn OpenTalentFrame", "talent frame", "t", env))()()
assert(clicked == "TalentMicroButton", "talent loadout fallback opens the spellbook")
assert(loadfile("QFXSystemBar_Config/Options.lua", "t", env))("QFXSystemBar_Config", ns)
local settingsIDs = {}
for _, item in ipairs(ns.ButtonList) do settingsIDs[item.id] = item end
assert(settingsIDs.PlayerSpells.labelKey == "Talents" and settingsIDs.SpellBook and settingsIDs.Legacy)

-- Settings must filter the visible view while preserving the full saved order.
local config = read("QFXSystemBar_Config/Config.lua")
env.GetInfoBarSlot = function() return slot end
env.EnsureDB = function() return env.QFXSystemBarDB end
env.CopyTable = function(t) local out = {}; for k, v in pairs(t) do out[k] = v end; return out end
local viewCode = assert(config:match("local function GetInfoBarOrder.-\nend\n"))
local view = assert(load(viewCode .. "\nreturn GetInfoBarOrder", "settings view", "t", env))()({ slotKey = "left" })
for _, id in ipairs(view) do assert(ns.IsInfoBarItemAvailable(id)) end
local saved = table.concat(env.QFXSystemBarDB[slot.orderKey], ",")
assert(saved:find("mplus", 1, true) and saved:find("greatvault", 1, true))

-- Native game-mode changes use the existing refresh queue; no polling.
local menuRefresh, barRefresh = 0, 0
ns.RequestMicroMenuRefresh = function() menuRefresh = menuRefresh + 1 end
ns.RefreshInfoBars = function() barRefresh = barRefresh + 1 end
ns.rulesChanged()
assert(menuRefresh == 1 and barRefresh == 1)

local retail, retailEnv = client(false)
assert(not retail.Compat.IsForever and retail.Compat.HasRetailProgression())
assert(retail.Compat.GetTalentButtonName() == "PlayerSpellsMicroButton")
assert(retail.Compat.ResolveRandomMount() == 0 and retail.Compat.GetRandomMountLabelKey() == "Random Favorite Mount")
assert(retail.IsInfoBarItemAvailable("mplus") and retail.IsMicroMenuButtonAvailable("GreatVault"))
assert(retail.IsInfoBarItemAvailable("mdt") and retail.IsMicroMenuButtonAvailable("MDT"))
assert(retail.defaults.nativeMicroMenu == 1 and retail.defaults.bagBar == 1, "Retail defaults changed")
assert(retail.defaults.isCustomMicroMenuSpellBook == nil and retail.defaults.isCustomMicroMenuLegacy == nil)
assert(not retail.IsMicroMenuButtonAvailable("SpellBook") and not retail.IsMicroMenuButtonAvailable("Legacy"))
local original = { isCustomMicroMenuPlayerSpells = false, customMicroMenuButtonOrder = { "PlayerSpells" } }
retail.MigrateForeverSettings(original)
assert(#original.customMicroMenuButtonOrder == 1 and original.isCustomMicroMenuSpellBook == nil)
retailEnv.C_SpecializationInfo = nil
retailEnv.GetSpecialization = function() return 3 end
assert(retail.Compat.GetSpecialization() == 3, "legacy fallback failed")
print("ForeverCompatibility_test: migration, native targets, namespaced specialization, capability filtering, mount selection and Retail regression passed")
