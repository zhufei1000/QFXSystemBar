local function read(path)
    local file = assert(io.open(path, "rb"))
    local result = file:read("*a"):gsub("\r\n", "\n")
    file:close()
    return result
end

local ns = {}
assert(loadfile("QFXSystemBar/Defaults.lua"))("QFXSystemBar", ns)
for _, iconSize in ipairs({ 16, 30, 48, 64 }) do
    local db = { customMicroMenuIconSize = iconSize }
    ns.MigrateMicroMenuBadgeFontSize(db)
    assert(db.customMicroMenuBadgeFontSize == math.max(9, math.floor(iconSize * 0.42 + 0.5)),
        "migration changed the existing displayed size")
end
QFXSystemBarDB = { customMicroMenuBadgeFontSize = 21, customMicroMenuFontSize = 50, infoBarFontSize = 12 }
ns.MigrateMicroMenuBadgeFontSize(QFXSystemBarDB)
assert(ns.GetMicroMenuBadgeFontSize(16) == 21 and ns.GetMicroMenuBadgeFontSize(64) == 21,
    "the configured size still depends on icon size")
assert(QFXSystemBarDB.customMicroMenuFontSize == 50 and QFXSystemBarDB.infoBarFontSize == 12)

local function fontString()
    local fs = {}
    function fs:SetFont(_, size) self.size = size end
    for _, method in ipairs({ "ClearAllPoints", "SetPoint", "SetTextColor", "SetShadowColor", "SetShadowOffset",
        "SetJustifyH", "SetJustifyV", "SetDrawLayer" }) do fs[method] = function() end end
    return fs
end
local badge = fontString()
local btn = { qfxIconSize = 30, mmIcon = {} }
function btn:CreateFontString() return fontString() end
local refreshes = 0
local env = setmetatable({
    ns = ns, IsLowDurabilityBadge = function() return false end,
    EnsureBadgeText = function() return badge end,
    GetBadgeColorRGB = function() return 1, 1, 1 end,
    StopBadgeHeartbeat = function() end,
    GetMenuFPSButton = function() return btn end,
    RefreshMenuFPSState = function() refreshes = refreshes + 1 end,
}, { __index = _G })
local source = read("QFXSystemBar/QFXSystemBar.lua")
local apply = assert(source:match("    local function ApplyBadgeVisualState.-\n    end\n"))
assert(load(apply .. "\nreturn ApplyBadgeVisualState", "badge visual", "t", env))()(btn, {}, "42", true)
assert(badge.size == 21, "ordinary counters did not use the configured size")
local ensure = assert(source:match("    local function EnsureMenuFPSTexts.-\n    end\n"))
env.EnsureMenuFPSTexts = assert(load(ensure .. "\nreturn EnsureMenuFPSTexts", "FPS fonts", "t", env))()
local refresh = assert(source:match("    ns.RefreshMenuFPSBadge = function%(%).-\n    end\n"))
assert(load(refresh, "FPS refresh", "t", env))()
ns.RefreshMenuFPSBadge()
assert(btn.qfxFpsTop.size == 21 and btn.qfxFpsMs.size == 21 and refreshes == 1,
    "FPS and latency did not immediately receive the configured size")
QFXSystemBarDB.customMicroMenuBadgeFontSize = 16
ns.RefreshMenuFPSBadge()
assert(btn.qfxFpsTop.size == 16 and btn.qfxFpsMs.size == 16, "FPS size stayed cached after a setting change")

_G.QFXSystemBarNS = ns
local badgeRefreshes = 0
ns.RefreshMicroMenuBadges = function() badgeRefreshes = badgeRefreshes + 1 end
assert(loadfile("QFXSystemBar_Config/Options.lua"))("QFXSystemBar_Config", ns)
local option
for _, opt in ipairs(ns.BadgeOptions) do
    if opt.key == "customMicroMenuBadgeFontSize" then option = opt end
end
assert(option and option.min == 8 and option.max == 32 and option.step == 1)
option.onChange()
assert(badgeRefreshes == 1 and refreshes == 3, "the slider did not refresh both counter types")

local locales = {}
local localeNS = { RegisterLocale = function(locale, data) locales[locale] = data end }
_G.QFXSystemBarNS = localeNS
for _, locale in ipairs({ "zhCN", "zhTW", "deDE", "frFR", "esES", "esMX", "ptBR", "ruRU", "koKR", "itIT" }) do
    assert(loadfile("QFXSystemBar_Locale/" .. locale .. ".lua"))("QFXSystemBar_Locale", localeNS)
    assert(locales[locale][option.nameKey] and locales[locale][option.tooltipKey])
    assert(locales[locale]["Game Menu Button: FPS / Latency"] and
        locales[locale]["Show the FPS and latency numbers on the Game Menu button."])
end
assert(locales.zhCN["Game Menu Button: FPS / Latency"] == "游戏菜单按钮：帧数 / 延迟")
print("BadgeFontSize_test: all assertions passed")
