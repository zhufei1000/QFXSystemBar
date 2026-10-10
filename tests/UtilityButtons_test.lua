-- Exercise native/optional UI entry points without loading game frames.
local function read(path)
    local file = assert(io.open(path, "rb"))
    local source = file:read("*a"):gsub("\r\n", "\n")
    file:close()
    return source
end
local source = read("QFXSystemBar/QFXSystemBar.lua")
local ns, globals = {}, {}
local combat, loads, opened, closed, reloaded, calendar, cleaned = false, 0, 0, 0, 0, 0, 0
local warnings = {}
local env = setmetatable({
    ns = ns, _G = globals, SlashCmdList = {},
    MICRO_ICON_PATH = "Interface\\AddOns\\QFXSystemBar\\Media\\MicroMenu\\",
    InCombatLockdown = function() return combat end,
    PrintQFXWarning = function(key) warnings[#warnings + 1] = key end,
    OpenQFXCalendarFromClock = function() calendar = calendar + 1 end,
    RunClockMemoryCleanup = function() cleaned = cleaned + 1 end,
    ReloadUI = function() reloaded = reloaded + 1 end,
}, { __index = _G })
local function get(name)
    local code = assert(source:match("    local function " .. name .. ".-\n    end\n"))
    return assert(load(code .. "\nreturn " .. name, name, "t", env))()
end

local clock = get("OnClockButtonClick")
clock(nil, "LeftButton")
clock(nil, "RightButton")
clock(nil, "MiddleButton")
assert(calendar == 1 and cleaned == 1 and reloaded == 1)
combat = true
clock(nil, "MiddleButton")
assert(reloaded == 1 and #warnings == 1, "reload ran during combat")
combat = false
assert(source:find('FormatMouseTooltipLine("Middle Click: Reload UI")', 1, true))

local vault = get("ToggleGreatVault")
local shown = false
local frame = {
    IsShown = function() return shown end,
    SetShown = function(_, visible)
        shown = visible
        if visible then opened = opened + 1 else closed = closed + 1 end
    end,
}
env.ShowUIPanel = function() error("vault must not use UIPanel dispatch") end
env.HideUIPanel = env.ShowUIPanel
env.WeeklyRewards_ShowUI = env.ShowUIPanel
ns.LoadOptionalAddOn = function(name)
    assert(name == "Blizzard_WeeklyRewards")
    loads = loads + 1
    env.WeeklyRewardsFrame = frame
end
vault(nil, "RightButton")
vault(nil, "MiddleButton")
assert(opened == 0)
vault(nil, "LeftButton")
vault(nil, "LeftButton")
assert(loads == 1 and opened == 1 and closed == 1 and not shown, "vault first click did not load and toggle directly")
combat = true
vault(nil, "LeftButton")
assert(opened == 2 and shown and #warnings == 1, "vault did not open during combat")
vault(nil, "LeftButton")
assert(closed == 2 and not shown and loads == 1, "vault did not close during combat")
env.WeeklyRewardsFrame = nil
vault(nil, "LeftButton")
assert(loads == 2 and opened == 3 and shown, "vault first combat click did not load and open")
combat, shown = false, false
env.WeeklyRewardsFrame = nil
ns.LoadOptionalAddOn = function() loads = loads + 1; return false end
vault(nil, "LeftButton")
assert(warnings[#warnings] == "The Great Vault is unavailable.")

local mrt = get("OpenMRT")
loads, opened, closed = 0, 0, 0
local mrtShown = false
local mrtFrame = {
    IsShown = function() return mrtShown end,
    Hide = function() mrtShown = false; closed = closed + 1 end,
}
ns.LoadOptionalAddOn = function(name)
    assert(name == "MRT" and not combat)
    loads = loads + 1
    globals.MRTOptionsFrame = mrtFrame
    globals.MRT_MinimapClickFunction = function()
        assert(not mrtShown, "the public entry point must not run while MRT is already open")
        mrtShown = true
        opened = opened + 1
    end
end
mrt(nil, "RightButton")
mrt(nil, "MiddleButton")
assert(loads == 0 and opened == 0)
mrt(nil, "LeftButton")
assert(loads == 1 and opened == 1 and mrtShown, "first click did not load and open MRT")
mrt(nil, "LeftButton")
assert(loads == 1 and opened == 1 and closed == 1 and not mrtShown, "second MRT click did not close")
combat = true
mrt(nil, "LeftButton")
assert(opened == 2 and mrtShown and loads == 1, "ready MRT must retain its own combat behavior")
mrt(nil, "LeftButton")
assert(closed == 2 and not mrtShown and loads == 1, "MRT did not close during combat")
globals.MRT_MinimapClickFunction = nil
mrt(nil, "LeftButton")
assert(loads == 1, "missing MRT attempted to load in combat")
combat = false
env.SlashCmdList.mrtSlash = function(text)
    assert(text == "" and not mrtShown)
    mrtShown = true
    opened = opened + 1
end
mrt(nil, "LeftButton")
assert(loads == 1 and opened == 3 and mrtShown, "MRT slash fallback failed")
mrt(nil, "LeftButton")
assert(closed == 3 and not mrtShown, "MRT slash-opened window did not close")
combat = true
mrt(nil, "LeftButton")
assert(loads == 1 and opened == 4 and mrtShown, "MRT slash handler was blocked during combat")
mrt(nil, "LeftButton")
assert(closed == 4 and not mrtShown, "slash-opened MRT did not close during combat")
-- Native launchers/close buttons can change visibility between our clicks.
mrtShown = true
env.SlashCmdList = {}
mrt(nil, "RightButton")
mrt(nil, "MiddleButton")
assert(mrtShown and closed == 4, "non-left clicks closed MRT")
mrt(nil, "LeftButton")
assert(not mrtShown and closed == 5 and loads == 1, "externally opened MRT did not close without a public entry point")
combat = false
globals.MRTOptionsFrame = nil
ns.LoadOptionalAddOn = function() loads = loads + 1; return false end
mrt(nil, "LeftButton")
assert(warnings[#warnings] == "MRT is not loaded.")

env.C_AddOns = { GetAddOnMetadata = function() error("MRT must use the white icon, not native colored artwork") end }

assert(loadfile("QFXSystemBar/Defaults.lua"))("QFXSystemBar", ns)
local db = { isCustomMicroMenu = true, customMicroMenuButtonOrder = { "Bags", "Character" } }
ns.MigrateBadgeDisplaySettings(db)
for _, id in ipairs({ "GreatVault", "MRT" }) do
    assert(ns.defaults["isCustomMicroMenu" .. id] == false and db["isCustomMicroMenu" .. id] == false)
    db["isCustomMicroMenu" .. id] = true
end
ns.MigrateBadgeDisplaySettings(db)
assert(db.isCustomMicroMenuGreatVault and db.isCustomMicroMenuMRT)
assert(table.concat(db.customMicroMenuButtonOrder, ",") == "Bags,Character")
local orderDefs = { { id = "Character" }, { id = "Bags" }, { id = "GreatVault" }, { id = "MRT" } }
env.QFXSystemBarDB, env.qfxMenuDefinitions = db, orderDefs
env.buttonDefByID = { Character = orderDefs[1], Bags = orderDefs[2], GreatVault = orderDefs[3], MRT = orderDefs[4] }
env.NormalizeButtonID = function(id) return id end
local orderCode = assert(source:match("(    local function CopyDefaultButtonOrder.-)\n    local function GetOrderedButtonDefs"))
local normalize = assert(load(orderCode .. "\nreturn NormalizeButtonOrder", "utility order", "t", env))()
assert(table.concat(normalize(), ",") == "Bags,Character,GreatVault,MRT")
assert(table.concat(normalize(), ",") == "Bags,Character,GreatVault,MRT", "repeated refresh changed the order")

env.ToggleGreatVault, env.OpenMRT = vault, mrt
local definitions = {}
env.AddMicroMenuButton = function(def) definitions[def.id] = def end
for _, id in ipairs({ "GreatVault", "MRT" }) do
    local code = assert(source:match('    AddMicroMenuButton%({\n        %["id"%] = "' .. id .. '".-\n    %}%)'))
    assert(load(code, id .. " definition", "t", env))()
end
local styleCode = assert(source:match("(    local ICON_STYLE_OPTIONS.-)\n    local function ReleaseButtonIconTexture"))
env.QFXSystemBarDB, env.buttonDefByID = {}, definitions
env.NormalizeButtonID = function(id) return id end
local texture, coords = assert(load(styleCode .. "\nreturn GetIconTexture, ApplyIconTexCoords", "utility styles", "t", env))()
local normalized = {
    MRT = { 10 / 128, 114 / 128, 10 / 128, 114 / 128 },
    GreatVault = { 15 / 128, 113 / 128, 11 / 128, 109 / 128 },
}
for _, style in ipairs({ "original", "gameicons", "lucide", "tabler" }) do
    env.QFXSystemBarDB.customMicroMenuIconStyle = style
    for id, def in pairs(definitions) do
        assert(def.forceWhiteIcon and not def.isSecure)
        assert(texture(def) == def.texture)
        local path = texture(def):gsub("^Interface\\AddOns\\", ""):gsub("\\", "/")
        assert(io.open(path, "rb")):close()
        local expected = normalized[id]
        coords({ SetTexCoord = function(_, l, r, t, b)
            assert(l == expected[1] and r == expected[2] and t == expected[3] and b == expected[4])
        end }, def)
        local previewPath, l, r, t, b, _, filter = ns.GetMicroMenuPreviewIconData(id)
        assert(previewPath == def.texture and l == expected[1] and r == expected[2] and t == expected[3] and b == expected[4])
        assert(filter == "TRILINEAR" and def.textureFilter == filter)
    end
    assert(definitions.MRT.texture == env.MICRO_ICON_PATH .. "MRT-256.blp")
    assert(definitions.MRT.getTexture == nil, "native colored MRT texture still overrides the white icon")
end
-- Verify both UI paths load the unchanged DXT5 texture with mip filtering.
env.GetIconTexture, env.ApplyIconTexCoords = texture, coords
local applyLive = get("ApplyButtonIconTexture")
local configSource = read("QFXSystemBar_Config/Config.lua")
local visualCode = assert(configSource:match("    local function ApplyItemVisual.-\n    end\n"))
local applyPreview = assert(load(visualCode .. "\nreturn ApplyItemVisual", "preview texture", "t", env))()
local mdtCode = assert(source:match('    AddMicroMenuButton%({\n        %["id"%] = "MDT".-\n    %}%)'))
assert(load(mdtCode, "MDT texture definition", "t", env))()
for id, def in pairs(definitions) do
    local selectedPath, selectedFilter
    local mockTexture = {
        SetTexture = function(_, path, wrapX, wrapY, filter)
            assert(wrapX == nil and wrapY == nil)
            if path then selectedPath, selectedFilter = path, filter end
        end,
        SetTexCoord = function() end, Show = function() end, Hide = function() end,
    }
    applyLive({ mmIcon = mockTexture }, def)
    assert(selectedPath == def.texture and selectedFilter == "TRILINEAR", id .. " live filter missing")
    local path, l, r, t, b, _, filter = ns.GetMicroMenuPreviewIconData(id)
    selectedPath, selectedFilter = nil, nil
    applyPreview({ icon = mockTexture, label = { SetText = function() end, Hide = function() end } },
        { texture = path, coords = { l, r, t, b }, filterMode = filter })
    assert(selectedPath == def.texture and selectedFilter == "TRILINEAR", id .. " preview filter missing")
end
local ordinaryFilter = "unset"
applyLive({ mmIcon = {
    SetTexture = function(_, path, _, _, filter) if path then ordinaryFilter = filter end end,
    SetTexCoord = function() end,
} }, { id = "Character", texture = env.MICRO_ICON_PATH .. "Tabler\\Character.blp" })
assert(ordinaryFilter == nil, "ordinary menu icons must retain the default filter")
_G.QFXSystemBarNS = ns
assert(loadfile("QFXSystemBar_Config/Options.lua"))("QFXSystemBar_Config", ns)
local found = {}
for _, row in ipairs(ns.ButtonList) do found[row.id] = row.var end
assert(found.GreatVault == "isCustomMicroMenuGreatVault" and found.MRT == "isCustomMicroMenuMRT")
print("UtilityButtons_test: clock actions, combat vault toggle, MRT combat/loading/fallback, defaults and white icons in four themes passed")
