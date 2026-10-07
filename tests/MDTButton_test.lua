local file = assert(io.open("QFXSystemBar/QFXSystemBar.lua", "rb"))
local source = file:read("*a"):gsub("\r\n", "\n")
file:close()
local ns, globals = {}, {}
local combat, loads, calls, warnings = false, 0, 0, {}
local env = setmetatable({
    _G = globals, ns = ns, SlashCmdList = {},
    InCombatLockdown = function() return combat end,
    PrintQFXWarning = function(key) warnings[#warnings + 1] = key end,
}, { __index = _G })
local toggleSource = assert(source:match("    local function ToggleMDT.-\n    end\n"))
local toggle = assert(load(toggleSource .. "\nreturn ToggleMDT", "MDT toggle", "t", env))()
local shown = false
local api
api = { ShowInterface = function(self, force)
    assert(self == api or self == globals.MythicDungeonToolsAPI)
    assert(force == nil, "the menu must use MDT's toggle, not force the window open")
    shown = not shown
    calls = calls + 1
end }
ns.LoadOptionalAddOn = function(name)
    assert(name == "MythicDungeonTools" and not combat)
    loads = loads + 1
    globals.MythicDungeonToolsAPI = api
end
toggle(nil, "RightButton")
toggle(nil, "MiddleButton")
assert(loads == 0 and calls == 0)
toggle(nil, "LeftButton")
assert(loads == 1 and calls == 1 and shown, "first click did not load and open MDT")
toggle(nil, "LeftButton")
assert(loads == 1 and calls == 2 and not shown, "second click did not delegate closing")
combat = true
toggle(nil, "LeftButton")
assert(loads == 1 and calls == 3 and shown, "ready MDT must retain its own combat behavior")
globals.MythicDungeonToolsAPI = nil
toggle(nil, "LeftButton")
assert(loads == 1 and #warnings == 1, "a missing MDT core must not load during combat")
combat = false
env.SlashCmdList.MYTHICDUNGEONTOOLS = function(text)
    assert(text == "")
    calls = calls + 1
end
toggle(nil, "LeftButton")
assert(loads == 1 and calls == 4, "legacy slash handler fallback failed")
env.SlashCmdList = {}
ns.LoadOptionalAddOn = function() loads = loads + 1; return false end
toggle(nil, "LeftButton")
assert(loads == 2 and warnings[#warnings] == "Mythic Dungeon Tools is not loaded.")

assert(loadfile("QFXSystemBar/Defaults.lua"))("QFXSystemBar", ns)
assert(ns.defaults.isCustomMicroMenuMDT == false)
local db = { isCustomMicroMenu = true, customMicroMenuButtonOrder = { "Bags", "Character" } }
ns.MigrateBadgeDisplaySettings(db)
assert(db.isCustomMicroMenuMDT == false and table.concat(db.customMicroMenuButtonOrder, ",") == "Bags,Character")
db.isCustomMicroMenuMDT = true
ns.MigrateBadgeDisplaySettings(db)
assert(db.isCustomMicroMenuMDT == true, "migration reset MDT visibility")
local definitions = { { id = "Character" }, { id = "Bags" }, { id = "MDT" } }
local orderEnv = setmetatable({
    ns = ns, QFXSystemBarDB = db, qfxMenuDefinitions = definitions,
    buttonDefByID = { Character = definitions[1], Bags = definitions[2], MDT = definitions[3] },
    NormalizeButtonID = function(id) return id end,
}, { __index = _G })
local orderSource = assert(source:match("(    local function CopyDefaultButtonOrder.-)\n    local function GetOrderedButtonDefs"))
local normalize = assert(load(orderSource .. "\nreturn NormalizeButtonOrder", "MDT order", "t", orderEnv))()
assert(table.concat(normalize(), ",") == "Bags,Character,MDT")
assert(table.concat(normalize(), ",") == "Bags,Character,MDT")

local definitionSource = assert(source:match('    AddMicroMenuButton%({\n        %["id"%] = "MDT".-\n    %}%)'))
local definition
env.AddMicroMenuButton = function(def) definition = def end
env.MICRO_ICON_PATH, env.ToggleMDT = "Interface\\AddOns\\QFXSystemBar\\Media\\MicroMenu\\", toggle
assert(load(definitionSource, "MDT definition", "t", env))()
assert(definition.id == "MDT" and definition.forceWhiteIcon and not definition.isSecure and definition.onClick == toggle)
local tintSource = assert(source:match("            local r, g, b = ResolveIconTint%(%)\n            local iconTexture = btn.mmIcon.-\n            btn.mmIcon:Show%(%)"))
local color
local texture = { SetVertexColor = function(_, r, g, b) color = { r, g, b } end, Show = function() end }
env.btn, env.def = { mmIcon = texture }, definition
env.ResolveIconTint = function() return 0.2, 0.4, 0.8 end
assert(load(tintSource, "MDT color", "t", env))()
assert(color[1] == 1 and color[2] == 1 and color[3] == 1, "MDT icon was tinted by the global setting")

local iconSource = assert(source:match("(    local ICON_STYLE_OPTIONS.-)\n    local function ReleaseButtonIconTexture"))
env.QFXSystemBarDB = {}
env.buttonDefByID = { MDT = definition }
env.NormalizeButtonID = function(id) return id end
local getTexture, applyCoords = assert(load(iconSource .. "\nreturn GetIconTexture, ApplyIconTexCoords", "MDT styles", "t", env))()
for _, style in ipairs({ "original", "gameicons", "lucide", "tabler" }) do
    env.QFXSystemBarDB.customMicroMenuIconStyle = style
    local path = getTexture(definition)
    assert(path == definition.texture, "a theme replaced the shared white MDT logo")
    assert(io.open(path:gsub("^Interface\\AddOns\\", ""):gsub("\\", "/"), "rb")):close()
    applyCoords({ SetTexCoord = function(_, left, right, top, bottom)
        assert(left == 0 and right == 1 and top == 0 and bottom == 1, "a theme cropped the MDT logo")
    end }, definition)
end
_G.QFXSystemBarNS = ns
assert(loadfile("QFXSystemBar_Config/Options.lua"))("QFXSystemBar_Config", ns)
local found
for _, row in ipairs(ns.ButtonList) do
    if row.id == "MDT" then found = row.var == "isCustomMicroMenuMDT" end
end
assert(found, "the optional MDT button is missing from settings")
print("MDTButton_test: public toggle, lazy load, fallback, defaults, order, white tint and four icon styles passed")
