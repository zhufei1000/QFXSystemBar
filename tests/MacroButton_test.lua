-- Exercise native action forwarding, combat boundaries and saved-order migration.
local function read(path)
    local file = assert(io.open(path, "rb"))
    local source = file:read("*a"):gsub("\r\n", "\n")
    file:close()
    return source
end

local source = read("QFXSystemBar/QFXSystemBar.lua")
local combat, secureContext, loads, opens, closes, writes = false, false, 0, 0, 0, 0
local proxies, wrappers = 0, 0
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
        IsShown = function() error("macro action must inspect only its protected visibility proxy") end,
    }
    env.MacroFrame.CloseButton = { Click = function()
        assert(secureContext, "closed native panel from insecure Lua")
        closes = closes + 1
        env.MacroFrame.savedBody = env.MacroFrame.draft
        env.MacroFrame.shown = false
    end }
    return true
end
local nativeOnClick = function() end
env.CreateFrame = function(kind, _, parent, template)
    assert(not combat, "created a visibility proxy or button in combat")
    if kind == "Frame" then
        assert(template == "SecureHandlerBaseTemplate" and parent == env.MacroFrame,
            "visibility proxy must be an explicitly protected child of the native panel")
        proxies = proxies + 1
        local proxy = { protected = true, parent = parent, shown = false }
        function proxy:SetSize() end
        function proxy:SetPoint() end
        function proxy:Show() self.shown = true end
        function proxy:IsVisible()
            assert(secureContext, "visibility must be checked in the restricted click")
            return self.shown and self.parent.shown
        end
        return proxy
    end
    assert(kind == "Button" and template:find("SecureActionButtonTemplate"), "macro button lacks a secure action template")
    local btn = { attributes = {}, scripts = { OnClick = nativeOnClick } }
    function btn:SetAttribute(key, value)
        assert(not combat or secureContext, "insecure addon wrote protected attributes in combat")
        writes = writes + 1
        self.attributes[key] = value
    end
    function btn:SetFrameRef(key, frame)
        assert(not combat and key == "macroVisibility" and frame.protected and frame.parent == env.MacroFrame,
            "only the addon-owned protected visibility proxy may be bound")
        self.refs = self.refs or {}
        self.refs[key] = frame
    end
    function btn:GetFrameRef(key)
        assert(secureContext, "frame references may only be read in the secure wrapper")
        return self.refs[key]
    end
    function btn:WrapScript(target, script, body)
        assert(not combat and target == self and script == "OnClick", "must wrap only the addon-owned click")
        wrappers = wrappers + 1
        self.securePre = assert(load("return function(self, button, down) " .. body .. " end",
            "macro-secure-toggle", "t", {}))()
    end
    function btn:EnableMouse(value)
        assert(not combat, "changed click availability in combat")
        self.enabled = value
    end
    function btn:RegisterForClicks(...) self.clicks = { ... } end
    function btn:SetScript(script, callback)
        assert(script ~= "OnClick", "macro action must keep native secure click handling")
        assert((script ~= "PreClick" and script ~= "PostClick") or callback == nil,
            "toggle must not depend on insecure click scripts")
        self.scripts[script] = callback
    end
    return btn
end
local helperSource = assert(source:match(
    "(    local macroVisibilityFrames.-)\n    local function ResolveNativeMicroButton"))
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
assert(#def.tooltipLines == 1 and def.tooltipLines[1] == "Left Click: Toggle Macros",
    "tooltip must describe one unified left-click action")
assert(loads == 0, "disabled button eagerly loaded the macro UI")
local btn = create(def)
assign(btn, def)
assert(loads == 1 and btn.enabled, "enabled button did not initialize the native UI")
assert(btn.scripts.OnClick == nativeOnClick and btn.attributes.useOnKeyDown == false, "native click handling changed")
assert(btn.attributes.type1 == "macro" and btn.attributes.macrotext1 == "/macro", "left click must use Blizzard's command")
assert(btn.attributes.clickbutton1 == env.MacroFrame.CloseButton, "left close must forward to the native close button")
assert(not btn.attributes.type2 and not btn.attributes.clickbutton2, "right-click close must be removed")
assert(not btn.attributes.type3, "middle click must remain unused")
assign(btn, def)
assert(loads == 1 and proxies == 1 and wrappers == 1, "rebuild duplicated native loading, proxy or wrapper")
-- This dispatch is a test harness, not a reproduction of the client's security
-- engine. Execute the actual restricted snippet before the native action;
-- native MacroFrame visibility queries deliberately error in this harness.
local function dispatch(mouseButton)
    secureContext = true
    if btn.securePre(btn, mouseButton, false) == false then
        secureContext = false
        return
    end
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
for _, inCombat in ipairs({ false, true }) do
    combat = inCombat
    env.MacroFrame.shown = false
    local oldOpens, oldCloses, oldWrites = opens, closes, writes
    dispatch("RightButton")
    dispatch("MiddleButton")
    assert(opens == oldOpens and closes == oldCloses and writes == oldWrites,
        "non-left clicks changed panel state or secure configuration")
    dispatch("LeftButton")
    assert(opens == oldOpens + 1 and env.MacroFrame.shown, "left toggle failed to open")
    env.MacroFrame.draft = "/say keep native save"
    dispatch("RightButton")
    assert(env.MacroFrame.shown and closes == oldCloses, "right-click still closes an open panel")
    dispatch("LeftButton")
    assert(closes == oldCloses + 1 and not env.MacroFrame.shown,
        "second left-click did not close the panel")
    assert(env.MacroFrame.savedBody == "/say keep native save", "toggle bypassed the native close/save path")
    env.MacroFrame.shown = true -- another launcher opened it
    dispatch("LeftButton")
    assert(closes == oldCloses + 2 and not env.MacroFrame.shown,
        "externally opened panel desynchronized the toggle")
    dispatch("LeftButton")
    env.MacroFrame.shown = false -- Esc/native close/another launcher
    dispatch("LeftButton")
    assert(opens == oldOpens + 3 and env.MacroFrame.shown,
        "externally closed panel desynchronized the toggle")
end
-- Enter and leave combat while already open: there is no cached toggle state.
combat = false
dispatch("LeftButton")
assert(not env.MacroFrame.shown, "leaving combat broke the next close")
dispatch("LeftButton")
combat = true
dispatch("LeftButton")
assert(not env.MacroFrame.shown and loads == 1 and proxies == 1 and wrappers == 1,
    "entering combat broke the next close or rebuilt setup")
combat = false

env.MacroFrame, env.MacroFrame_LoadUI = nil, nil
configure(btn)
assert(not btn.enabled and not btn.attributes.type1 and not btn.attributes.type2
    and warnings[1] == "The macro window is unavailable.", "unavailable UI was not disabled safely")
assert(not btn.scripts.PreClick and not btn.scripts.PostClick, "unavailable UI kept stale toggle callbacks")

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
print("MacroButton_test: unified combat toggle, protected visibility proxy, native close/save, no right-click action, migration and icon styles passed")
