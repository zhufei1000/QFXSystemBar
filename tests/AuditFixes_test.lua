-- Regressions for the 1.16.0 post-release audit: the single-icon drag crash,
-- the Forever login migration ordering, load-on-demand option defaults, and
-- the duplicate MeetingStone broker layout budget.
local function read(path)
    local file = assert(io.open(path, "rb"))
    local text = file:read("*a"):gsub("\r\n", "\n")
    file:close()
    return text
end
local core = read("QFXSystemBar/QFXSystemBar.lua")
local coreInit = read("QFXSystemBar/Core.lua")
local defaults = read("QFXSystemBar/Defaults.lua")
local config = read("QFXSystemBar_Config/Config.lua")

-- ---------------------------------------------------------------------
-- 1. Reordering with a single enabled icon must not insert at position 0.
-- ---------------------------------------------------------------------
local definitions = {
    { id = "Time", var = "isCustomMicroMenuTime", isText = true },
    { id = "Bags", var = "isCustomMicroMenuBags" },
    { id = "Character", var = "isCustomMicroMenuCharacter" },
}
local byID = {}
for _, def in ipairs(definitions) do byID[def.id] = def end

local function orderEnv(db)
    local ns = {
        defaultMicroMenuButtonOrder = { "Time", "Bags", "Character" },
        IsMicroMenuButtonAvailable = function() return true end,
        OnMicroMenuChanged = function() end,
    }
    local env = setmetatable({
        ns = ns, QFXSystemBarDB = db, qfxMenuDefinitions = definitions,
        buttonDefByID = byID, NormalizeButtonID = function(id) return id end,
    }, { __index = _G })
    env._G = env
    local orderSource = assert(core:match("(    local function CopyDefaultButtonOrder.-)\n    local function GetOrderedButtonDefs"))
    local moveSource = assert(core:match("    function ns%.MoveMicroMenuButtonTo%(id, visibleIndex%)\n.-\n    end\n"))
    local normalize = assert(load(orderSource .. "\n" .. moveSource .. "\nreturn NormalizeButtonOrder", "button order", "t", env))()
    return ns, normalize
end

-- One icon: leftCount is 0, so dropping it left of the clock used to call
-- table.insert(list, 0, id) and abort the whole drag before the DB write.
local db = {
    isCustomMicroMenuTime = true, isCustomMicroMenuBags = true,
    customMicroMenuButtonOrder = { "Time", "Bags", "Character" },
}
local ns = orderEnv(db)
ns.MoveMicroMenuButtonTo("Bags", 1)
assert(type(db.customMicroMenuButtonOrder) == "table", "single-icon drag aborted before writing the order")
local seen = {}
for _, id in ipairs(db.customMicroMenuButtonOrder) do
    assert(not seen[id], "single-icon drag duplicated an entry: " .. id)
    seen[id] = true
end
assert(seen.Bags and seen.Time, "single-icon drag lost a button")

-- Two icons still split evenly around the clock and cross-center drops work.
db = {
    isCustomMicroMenuTime = true, isCustomMicroMenuBags = true, isCustomMicroMenuCharacter = true,
    customMicroMenuButtonOrder = { "Bags", "Time", "Character" },
}
ns = orderEnv(db)
ns.MoveMicroMenuButtonTo("Character", 1)
local order = db.customMicroMenuButtonOrder
local bagIndex, clockIndex
for index, id in ipairs(order) do
    if id == "Bags" then bagIndex = index elseif id == "Time" then clockIndex = index end
end
assert(bagIndex and clockIndex, "two-icon drag lost the clock or the dragged icon")

-- ---------------------------------------------------------------------
-- 2. The Forever migration must run before MergeDefaults at login.
-- ---------------------------------------------------------------------
local loginBlock = assert(coreInit:match("EventUtil%.ContinueOnAddOnLoaded%(addonName, function%(%)\n(.-)\nend%)"))
local migrateAt = loginBlock:find("MigrateForeverSettings", 1, true)
local mergeAt = loginBlock:find("MergeDefaults(QFXSystemBarDB", 1, true)
assert(migrateAt and mergeAt, "login chain lost the Forever migration or the defaults merge")
assert(migrateAt < mergeAt, "MergeDefaults runs first and fills SpellBook=true, so the migration can no longer inherit PlayerSpells=false")

-- Behavioural proof of why that order matters.
local mergeSource = assert(coreInit:match("local function MergeDefaults%(target, source%)\n.-\nend\n"))
local migrateSource = assert(defaults:match("function ns%.MigrateForeverSettings%(db%)\n.-\nend\n"))
local migEnv = setmetatable({ ns = { Compat = { IsForever = true } } }, { __index = _G })
migEnv._G = migEnv
assert(load("local ns = ...\n" .. migrateSource, "forever migration", "t", migEnv))(migEnv.ns)
local mergeEnv = setmetatable({}, { __index = _G })
local merge = assert(load(mergeSource .. "\nreturn MergeDefaults", "defaults merge", "t", mergeEnv))()
local foreverDefaults = { isCustomMicroMenuSpellBook = true, isCustomMicroMenuLegacy = true }

local upgrading = { isCustomMicroMenuPlayerSpells = false }
migEnv.ns.MigrateForeverSettings(upgrading)
merge(upgrading, foreverDefaults)
assert(upgrading.isCustomMicroMenuSpellBook == false, "login order lost the user's PlayerSpells=false choice")

local wrongOrder = { isCustomMicroMenuPlayerSpells = false }
merge(wrongOrder, foreverDefaults)
migEnv.ns.MigrateForeverSettings(wrongOrder)
assert(wrongOrder.isCustomMicroMenuSpellBook == true, "control case no longer reproduces the old bug")

-- ---------------------------------------------------------------------
-- 3. Option defaults resolve lazily for load-on-demand InfoBar keys.
-- ---------------------------------------------------------------------
local defaultSource = assert(config:match("local function OptionDefault%(opt%)\n.-\nend\n"))
local defEnv = setmetatable({ ns = { defaults = {} } }, { __index = _G })
defEnv._G = defEnv
local optionDefault = assert(load("local ns = ...\n" .. defaultSource .. "\nreturn OptionDefault", "option default", "t", defEnv))(defEnv.ns)
local infoBarOpt = { key = "infoBarLeftWidth", default = nil }
assert(optionDefault(infoBarOpt) == nil, "unloaded InfoBar default resolved to a bogus value")
defEnv.ns.defaults.infoBarLeftWidth = 450
assert(optionDefault(infoBarOpt) == 450, "default captured before InfoBar loaded was not resolved lazily")
assert(optionDefault({ key = "infoBarLeftWidth", default = 300 }) == 300, "explicit option default was overridden")
assert(optionDefault({ key = "someFlag", default = false }) == false, "a false default was treated as missing")
assert(optionDefault({}) == nil, "keyless option resolved a default")
assert(not config:find("elseif opt.key and opt.default ~= nil then", 1, true), "reset path still skips nil captured defaults")

-- ---------------------------------------------------------------------
-- 4. A second strip must not reserve a blank cell (and lose item budget)
--    for the MeetingStone broker the first strip already owns.
-- ---------------------------------------------------------------------
local infoBar = read("QFXSystemBar_InfoBar/InfoBar.lua")
local anchorSource = assert(infoBar:match("local function AnchorSlotModules%(slotKey%)\n.-\nend\n"))

local function FakeInfoBarButton(id)
    local b = { id = id, shown = false, width = 0, x = nil }
    b.text = {
        ClearAllPoints = function() end, SetPoint = function() end,
        SetSize = function() end, SetJustifyH = function() end, SetJustifyV = function() end,
    }
    function b:SetParent() end
    function b:GetFrameLevel() return 1 end
    function b:SetFrameLevel() end
    function b:ClearAllPoints() end
    function b:SetSize(w) self.width = w end
    function b:SetClipsChildren() end
    function b:SetPoint(_, _, _, x) self.x = x end
    function b:Show() self.shown = true end
    function b:Hide() self.shown = false end
    return b
end

local stripWidth = 500
local floatingPanelHides = 0
local modules = { left = {}, right = {} }
local orders = {
    left = { "gold", "meetingstone", "fps" },
    right = { "meetingstone", "ilvl", "dura", "zone", "coords", "gold" },
}
for slotKey, list in pairs(orders) do
    for _, id in ipairs(list) do
        modules[slotKey][id] = modules[slotKey][id] or FakeInfoBarButton(id)
    end
end
local fakeBar = { GetFrameLevel = function() return 1 end }
local anchorEnv = setmetatable({
    ns = { GetInfoBarItemSpan = function() return 1 end },
    bars = { left = fakeBar, right = fakeBar },
    modules = modules,
    MAX_INFOBAR_ITEMS_PER_BAR = 5,
    GetSlot = function() return {} end,
    HideSlotModules = function(slotKey)
        for _, btn in pairs(modules[slotKey] or {}) do btn:Hide() end
    end,
    IsSlotEnabled = function() return true end,
    IsItemEnabled = function() return true end,
    GetOrderForSlot = function(slotKey) return orders[slotKey] end,
    CreateTextModule = function() error("test modules must be pre-created") end,
    GetBarWidth = function() return stripWidth end,
    GetBarHeight = function() return 20 end,
    GetInfoBarTextBoxHeight = function() return 20 end,
    GetInfoBarFontSize = function() return 12 end,
    HideMeetingStoneFloatingPanel = function() floatingPanelHides = floatingPanelHides + 1 end,
}, { __index = _G })
anchorEnv._G = anchorEnv
local anchorChunk = "local meetingStoneBrokerDesired\n" .. anchorSource
    .. "\nreturn AnchorSlotModules, function() return meetingStoneBrokerDesired end"
local anchorSlot, getBroker = assert(load(anchorChunk, "anchor slot modules", "t", anchorEnv))()

local function AssertContiguousLayout(slotKey, expectedShown)
    local shown = {}
    for _, id in ipairs(orders[slotKey]) do
        local btn = modules[slotKey][id]
        if btn.shown then shown[#shown + 1] = btn end
    end
    assert(#shown == expectedShown, slotKey .. " strip showed " .. #shown .. " cells, expected " .. expectedShown)
    local offset, total = 0, 0
    for _, btn in ipairs(shown) do
        assert(btn.x == offset, slotKey .. " strip has a gap or blank cell before " .. btn.id)
        offset = offset + btn.width
        total = total + btn.width
    end
    assert(math.abs(total - stripWidth) < 0.01, slotKey .. " strip widths do not fill the bar")
end

anchorSlot("left")
assert(getBroker() == modules.left.meetingstone, "first strip did not claim the MeetingStone broker")
assert(modules.left.meetingstone.shown, "owning strip hid its own MeetingStone broker")
AssertContiguousLayout("left", 3)
assert(floatingPanelHides >= 1, "laying out the broker did not hide the floating panel")

-- Six candidates on the right strip but only five budget slots: the duplicate
-- broker must be dropped before it consumes a span, leaving room for all five
-- ordinary items and no blank cell.
anchorSlot("right")
assert(not modules.right.meetingstone.shown, "duplicate MeetingStone broker stayed visible")
assert(getBroker() == modules.left.meetingstone, "duplicate broker stole ownership")
AssertContiguousLayout("right", 5)

-- Re-anchoring the owning strip keeps its broker (same button, not a duplicate).
anchorSlot("left")
assert(modules.left.meetingstone.shown and getBroker() == modules.left.meetingstone, "re-anchor dropped the owning broker")
AssertContiguousLayout("left", 3)

print("AuditFixes_test: single-icon drag writes order; Forever migration precedes MergeDefaults; LoD defaults resolve lazily; duplicate MeetingStone broker costs no cell")