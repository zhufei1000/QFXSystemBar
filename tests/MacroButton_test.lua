-- Exercise fixed native action setup and saved-order migration without WoW.
local function read(path)
    local file = assert(io.open(path, "rb"))
    local source = file:read("*a"):gsub("\r\n", "\n")
    file:close()
    return source
end

local source = read("QFXSystemBar/QFXSystemBar.lua")
local combat, secureContext, loads, opens, closes, writes = false, false, 0, 0, 0, 0
local warnings = {}
local env = setmetatable({
    InCombatLockdown = function() return combat end,
    PrintQFXWarning = function(key) warnings[#warnings + 1] = key end,
    MICRO_ICON_PATH = "",
    qfxButtonPool = {},
    SecureHandlerWrapScript = function() error("macro action must not install a restricted wrapper") end,
}, { __index = _G })
env.MacroFrame_LoadUI = function()
    assert(not combat, "initialized macro frames in combat")
    loads = loads + 1
    env.MacroFrame = {
        shown = false,
        IsShown = function() error("macro action must not query native window visibility") end,
    }
    env.MacroFrame.CloseButton = { Click = function()
        assert(secureContext, "closed native panel from insecure Lua")
        closes = closes + 1
        env.MacroFrame.shown = false
    end }
    return true
end
local nativeOnClick = function() end
env.CreateFrame = function(kind, _, _, template)
    assert(kind == "Button" and template:find("SecureActionButtonTemplate"), "macro button lacks a secure action template")
    local btn = { attributes = {}, scripts = { OnClick = nativeOnClick } }
    function btn:SetAttribute(key, value)
        assert(not combat, "addon wrote protected attributes in combat")
        writes = writes + 1
        self.attributes[key] = value
    end
    function btn:SetFrameRef() error("macro action must not bind restricted frame handles") end
    function btn:GetFrameRef() error("macro action must not access restricted frame handles") end
    function btn:EnableMouse(value)
        assert(not combat, "changed click availability in combat")
        self.enabled = value
    end
    function btn:RegisterForClicks(...) self.clicks = { ... } end
    function btn:SetScript(script, callback)
        assert(script ~= "OnClick" and script ~= "PreClick" and script ~= "PostClick",
            "macro action must keep native click handling without addon click scripts")
        self.scripts[script] = callback
    end
    return btn
end
local helperSource = assert(source:match(
    "(    local function ConfigureMacroButton.-)\n    local function ResolveNativeMicroButton"))
local configure = assert(load(helperSource .. "\nreturn ConfigureMacroButton", "macro-setup", "t", env))()
env.ConfigureMacroButton = configure
local actionSource = assert(source:match(
    "(    local function CreateOrGetMenuButton.-)\n    local function BuildVisibleButtons"))
local create, assign = assert(load(actionSource .. "\nreturn CreateOrGetMenuButton, AssignButtonAction", "macro-bind", "t", env))()
local definitionStart = assert(source:find('    AddMicroMenuButton({\n        ["id"] = "Macro",', 1, true))
local definitionEnd = assert(source:find('\n    })', definitionStart, true))
local def
env.AddMicroMenuButton = function(value) def = value end
assert(load(source:sub(definitionStart, definitionEnd + 6), "macro-definition", "t", env))()
assert(def.isSecure and def.secureAction == "macroWindow" and not def.onClick, "macro definition uses insecure clicking")
assert(def.tooltipLines[1] == "Left Click: Open Macros" and def.tooltipLines[2] == "Right Click: Close Macros",
    "tooltip does not describe the fixed native actions")
assert(loads == 0, "disabled button eagerly loaded the macro UI")
local btn = create(def)
assign(btn, def)
assert(loads == 1 and btn.enabled, "enabled button did not initialize the native UI")
assert(btn.scripts.OnClick == nativeOnClick and btn.attributes.useOnKeyDown == false, "native click handling changed")
assert(btn.attributes.type1 == "macro" and btn.attributes.macrotext1 == "/macro", "left click must use Blizzard's command")
assert(btn.attributes.type2 == "click" and btn.attributes.clickbutton2 == env.MacroFrame.CloseButton,
    "right click must directly forward to the native close button")
assert(not btn.attributes.type3, "middle click must remain unused")
assign(btn, def)
assert(loads == 1, "rebuild reloaded the native UI")
-- This dispatch is a test harness, not a reproduction of the client's security
-- engine. The production addon supplies only fixed attributes to that engine.
local function dispatch(mouseButton)
    secureContext = true
    local index = ({ LeftButton = 1, RightButton = 2, MiddleButton = 3 })[mouseButton]
    local action = btn.attributes["type" .. index]
    if action == "macro" then
        opens = opens + 1
        env.MacroFrame.shown = true
    elseif action == "click" then
        assert(btn.attributes["clickbutton" .. index] == env.MacroFrame.CloseButton)
        env.MacroFrame.CloseButton.Click()
    end
    secureContext = false
end
local beforeWrites = writes
combat = true
configure(btn)
assert(writes == beforeWrites and loads == 1, "combat setup mutated protected state or loaded UI")
dispatch("MiddleButton")
assert(opens == 0 and closes == 0, "middle click changed panel state")
dispatch("LeftButton")
assert(opens == 1 and env.MacroFrame.shown, "left action failed to open")
dispatch("LeftButton")
assert(opens == 2 and closes == 0 and env.MacroFrame.shown, "left action should retain native open-only behavior")
dispatch("RightButton")
assert(closes == 1 and not env.MacroFrame.shown, "right action failed to close")
dispatch("LeftButton")
assert(opens == 3 and env.MacroFrame.shown and loads == 1 and writes == beforeWrites,
    "combat reopening changed native load or protected configuration")
combat = false
dispatch("RightButton")
assert(closes == 2 and not env.MacroFrame.shown and #warnings == 0, "out-of-combat actions regressed")
env.MacroFrame, env.MacroFrame_LoadUI = nil, nil
configure(btn)
assert(not btn.enabled and not btn.attributes.type1 and not btn.attributes.type2
    and warnings[1] == "The macro window is unavailable.", "unavailable UI was not disabled safely")

local ns = {}
assert(loadfile("QFXSystemBar/Defaults.lua"))("QFXSystemBar", ns)
assert(ns.defaults.isCustomMicroMenuMacro == false, "new installs must opt into the utility button")
local db = { isCustomMicroMenu = true, customMicroMenuButtonOrder = { "Bags", "Character" }, isCustomMicroMenuBags = true }
ns.MigrateBadgeDisplaySettings(db)
assert(db.isCustomMicroMenuMacro == false and db.isCustomMicroMenuBags == true, "migration changed existing visibility")
assert(table.concat(db.customMicroMenuButtonOrder, ",") == "Bags,Character", "migration reordered existing buttons")
db.isCustomMicroMenuMacro = true
ns.MigrateBadgeDisplaySettings(db)
assert(db.isCustomMicroMenuMacro == true, "migration reset the user's macro toggle")

local definitions = { { id = "Character" }, { id = "Bags" }, { id = "Macro" } }
local orderEnv = setmetatable({
    ns = ns, QFXSystemBarDB = db, qfxMenuDefinitions = definitions,
    buttonDefByID = { Character = definitions[1], Bags = definitions[2], Macro = definitions[3] },
    NormalizeButtonID = function(id) return id end,
}, { __index = _G })
local orderSource = assert(source:match(
    "(    local function CopyDefaultButtonOrder.-)\n    local function GetOrderedButtonDefs"))
local normalizeOrder = assert(load(orderSource .. "\nreturn NormalizeButtonOrder", "macro-order", "t", orderEnv))()
assert(table.concat(normalizeOrder(), ",") == "Bags,Character,Macro", "new button must append without reordering")
assert(table.concat(normalizeOrder(), ",") == "Bags,Character,Macro", "normalization duplicated the macro button")

local stylesSource = assert(source:match(
    "(    local ICON_STYLE_OPTIONS.-)\n    local function GetIconTexture"))
local styles, coords = assert(load(stylesSource .. "\nreturn ICON_STYLE_OPTIONS, ICON_TEX_COORDS", "macro-icons", "t", env))()
for _, style in ipairs({ "original", "gameicons", "lucide", "tabler" }) do
    local path = styles[style].folder .. assert(styles[style].files.Macro, "missing macro icon mapping")
    path = path:gsub("^Interface\\AddOns\\", ""):gsub("\\", "/")
    assert(io.open(path, "rb")):close()
    local c = coords[style].Macro
    if c then assert(c[1] >= 0 and c[2] <= 1 and c[1] < c[2] and c[3] < c[4], "invalid macro crop") end
end
print("MacroButton_test: fixed native actions without frame handles, migration, order and all four icon styles passed")
