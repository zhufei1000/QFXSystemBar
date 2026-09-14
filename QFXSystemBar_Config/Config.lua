local addonName, ns = ...
ns = _G.QFXSystemBarNS or ns
if not ns then return end
ns.ConfigLoaded = true
local L = setmetatable({}, {
    __index = function(_, key)
        if ns and ns.T then return ns.T(key) end
        local locale = ns and ns.L
        return (locale and locale[key]) or key
    end,
})
local function T(value)
    if ns and ns.T then return ns.T(value) end
    if value == nil then return "" end
    if type(value) ~= "string" then return tostring(value) end
    return L[value] or value
end

local function SetUIText(object, key, prefix, suffix)
    if ns and ns.SetUIText then return ns.SetUIText(object, key, prefix, suffix) end
    if object and object.SetText then object:SetText((prefix or "") .. T(key) .. (suffix or "")) end
    return object
end

local function UIText(key)
    if ns and ns.UIText then return ns.UIText(key) end
    return T(key)
end

local function UIFormat(key, ...)
    if ns and ns.UIFormat then return ns.UIFormat(key, ...) end
    local ok, text = pcall(string.format, T(key), ...)
    return ok and text or T(key)
end

-- Migrated to the shared QFXWidgets factory (see QFXSystemBar_Config\QFXWidgets.lua):
-- every option type (generic and custom) is rendered with the factory. The
-- factory is required; ns.useQFXWidgets = false only disables it (the config
-- window then refuses to open with a "reinstall" message instead of crashing).
local W = _G.QFXWidgets
local USE_QFX = type(W) == "table" and type(W.DualRow) == "function" and ns.useQFXWidgets ~= false
if USE_QFX and W.SetArrowTexture then
    -- the factory is embedded in this addon; point its dropdown arrow at the
    -- copy that ships next to this file (a standalone QFXWidgets addon, if any,
    -- would otherwise fall back to the drawn chevron)
    W:SetArrowTexture("Interface\\AddOns\\QFXSystemBar_Config\\Media\\arrow-down.png")
end

-- Canonical English source keys for every popup UI item.  These maps are
-- intentionally keyed by stable option/page IDs, so even if an older file,
-- old SavedVariables, or a Blizzard display label reaches the renderer,
-- the visible UI is rebuilt from the English source first.
local OPTION_NAME_KEYS = {
    general = "Display",
    buttons = "Button List",
    appearance = "Appearance",
    iconSettings = "Icon Settings",
    clockSettings = "Clock Settings",
    badgeSettings = "Extra Text",
    position = "Position",
    topCenterWidget = "Top-Center Zone Information",
    topCenterWidgetGroup = "Top-Center Zone Information",
    microMenu = "Micro Menu",
    infoBars = "Info Bars",
    infoGeneral = "General",
    infoLeft = "Left Info Bar",
    infoRight = "Right Info Bar",
    infoLeftTop = "Left Top Info Bar",
    infoLeftBottom = "Left Bottom Info Bar",
    infoRightBottom = "Right Bottom Info Bar",

    generalHeader = "Visibility & Language",
    language = "Interface Language",
    isCustomMicroMenu = "Enable QFXSystemBar",
    customMicroMenu = "Top QFX Bar Visibility",
    nativeMicroMenu = "Native Micro Menu Visibility",
    bagBar = "Native Bag Bar Visibility",
    uiFadeInDuration = "Mouseover Show Speed",
    uiFadeOutDuration = "Mouseover Hide Speed",

    buttonHeader = "Button Order & Visibility",
    customMicroMenuButtonOrder = "Button List",
    hearthstoneSettingsHeader = "Hearthstone Settings",
    customMicroMenuHearthstoneLeft = "Left Click Hearthstone",
    customMicroMenuHearthstoneMiddle = "Middle Click Hearthstone",
    customMicroMenuHearthstoneRight = "Right Click Hearthstone",

    appearanceHeader = "Appearance",
    iconSettingsHeader = "Icon Settings",
    clockSettingsHeader = "Clock Settings",
    badgeSettingsHeader = "Extra Text Settings",
    customMicroMenuIconStyle = "Icon Style",
    customMicroMenuIconColorMode = "Icon Color",
    customMicroMenuIconCustomColor = "Icon Custom Color",
    customMicroMenuClockColorMode = "Clock Color",
    customMicroMenuClockCustomColor = "Clock Custom Color",
    customMicroMenuBadgeColorMode = "Extra Text Color",
    customMicroMenuBadgeCustomColor = "Extra Text Custom Color",
    customMicroMenuBadgeHeader = "Button Extra Text",
    customMicroMenuBadgeDisplay = "Button Extra Text",
    customMicroMenuShowDurabilityBadge = "Character Button: Durability Number",
    customMicroMenuShowFriendBadge = "Social Button: Online Friends",
    customMicroMenuShowGuildBadge = "Guild Button: Online Guild Members",
    customMicroMenuShowBagBadge = "Bags Button: Free Bag Slots",
    customMicroMenuShowVolumeBadge = "Volume Button: Master Volume",
    customMicroMenuDurabilityBadgeColor = "Durability Text Color",
    customMicroMenuFriendBadgeColor = "Friend Count Text Color",
    customMicroMenuGuildBadgeColor = "Guild Count Text Color",
    customMicroMenuBagBadgeColor = "Bag Count Text Color",
    customMicroMenuVolumeBadgeColor = "Volume Text Color",
    isCustomMicroMenuTimeAdj = "Enable Clock Text Settings",
    customMicroMenuTimeMode = "Clock Source",
    customMicroMenuTimeFormat = "Clock Format",
    customMicroMenuTimeFont = "Clock Font",
    customMicroMenuFontSize = "Clock Font Size",
    customMicroMenuTimeTextYOffset = "Clock Number Y Offset",
    customMicroMenuTimeOutline = "Clock Text Outline",
    customMicroMenuIconSize = "Icon Button Size",
    customMicroMenuButtonSpacing = "Icon Spacing",

    positionHeader = "Position",
    microMenuPositionTools = "Position Controls",
    topCenterWidgetPosition = "Top-Center Zone Information",

    infoBarHeader = "Info Bars",
    isInfoBar = "Enable Info Bars",
    infoBarFontSize = "Info Text Size",
    infoBarFadeStrength = "Background Strength",
    infoBarLeftTopHeader = "Left Top Info Bar",
    infoBarLeftBottomHeader = "Left Bottom Info Bar",
    infoBarRightBottomHeader = "Right Bottom Info Bar",
    infoBarLeftHeader = "Left Top Info Bar",
    infoBarRightHeader = "Right Bottom Info Bar",
    infoBarLeftEnabled = "Enable Left Top Info Bar",
    infoBarLeftBottomEnabled = "Enable Left Bottom Info Bar",
    infoBarRightEnabled = "Enable Right Bottom Info Bar",
    infoBarLeftWidth = "Info Bar Width",
    infoBarLeftBottomWidth = "Info Bar Width",
    infoBarRightWidth = "Info Bar Width",
    infoBarLeftHeight = "Info Bar Height",
    infoBarLeftBottomHeight = "Info Bar Height",
    infoBarRightHeight = "Info Bar Height",
    infoBarLeftLineThickness = "Class Line Thickness",
    infoBarLeftBottomLineThickness = "Class Line Thickness",
    infoBarRightLineThickness = "Class Line Thickness",
    infoBarLeftLineStyle = "Class Line Style",
    infoBarLeftBottomLineStyle = "Class Line Style",
    infoBarRightLineStyle = "Class Line Style",
    infoBarLeftLinePosition = "Class Line Position",
    infoBarLeftBottomLinePosition = "Class Line Position",
    infoBarRightLinePosition = "Class Line Position",
    infoBarLeftFade = "Gradient Direction",
    infoBarLeftBottomFade = "Gradient Direction",
    infoBarRightFade = "Gradient Direction",
    infoBarLeftTopPosition = "Position Controls",
    infoBarLeftBottomPosition = "Position Controls",
    infoBarRightBottomPosition = "Position Controls",
    infoBarLeftPosition = "Position Controls",
    infoBarRightPosition = "Position Controls",
    infoBarLeftTopContent = "Displayed Information",
    infoBarLeftBottomContent = "Displayed Information",
    infoBarRightBottomContent = "Displayed Information",
    infoBarLeftContent = "Displayed Information",
    infoBarRightContent = "Displayed Information",
}

local OPTION_TOOLTIP_KEYS = {
    generalHeader = "Set the interface language and choose how QFXSystemBar, the native micro menu, and the native bag bar are displayed.",
    language = "Defaults to the client language. You can force a specific language. The settings window refreshes immediately after switching.",
    isCustomMicroMenu = "Show the custom QFXSystemBar system bar.",
    customMicroMenu = "Always show the QFX bar, hide it, or show it only while the mouse is over the bar.",
    nativeMicroMenu = "Choose whether Blizzard's original micro menu is always shown, hidden, or shown only on mouseover.",
    bagBar = "Choose whether Blizzard's original bag bar is always shown, hidden, or shown only on mouseover.",
    uiFadeInDuration = "How quickly mouseover-hidden bars become fully visible after the mouse enters.",
    uiFadeOutDuration = "How quickly mouseover-hidden bars hide again after the mouse leaves.",

    buttonHeader = "Toggle visibility and drag the preview icons to adjust button order on the system bar.",
    customMicroMenuButtonOrder = "Checked buttons are shown on the system bar. Drag the preview icons to adjust order.",
    hearthstoneSettingsHeader = "Choose which hearthstone item each mouse button uses.",
    customMicroMenuHearthstoneLeft = "Choose the hearthstone used by left-clicking the Hearthstone button.",
    customMicroMenuHearthstoneMiddle = "Choose the hearthstone used by middle-clicking the Hearthstone button.",
    customMicroMenuHearthstoneRight = "Choose the hearthstone used by right-clicking the Hearthstone button.",

    appearanceHeader = "Appearance options are split into icon settings, clock settings, and extra text settings.",
    iconSettingsHeader = "Configure micro menu icon style, icon coloring, button size, and button spacing.",
    clockSettingsHeader = "Configure the top micro menu clock source, color, format, font, size, and outline.",
    badgeSettingsHeader = "Configure the small numbers shown on supported micro menu buttons, such as durability, friends, guild members, free bag slots, and volume.",
    customMicroMenuIconStyle = "Choose which icon set is used by the top micro menu.",
    customMicroMenuIconColorMode = "Choose how the micro menu icons are colored.",
    customMicroMenuIconCustomColor = "Choose the custom color used by micro menu icons.",
    customMicroMenuClockColorMode = "Choose how the clock text is colored.",
    customMicroMenuClockCustomColor = "Choose the custom color used by the clock text.",
    customMicroMenuBadgeColorMode = "Choose how the button extra text is colored.",
    customMicroMenuBadgeCustomColor = "Choose the custom color used by button extra text.",
    customMicroMenuBadgeHeader = "Choose which button extra counters are shown. Checked items are shown; unchecked items are hidden.",
    customMicroMenuBadgeDisplay = "Choose which button extra counters are shown. Checked items are shown; unchecked items are hidden.",
    customMicroMenuShowDurabilityBadge = "Show the equipped durability number on the Character button.",
    customMicroMenuShowFriendBadge = "Show the online friend count on the Social button.",
    customMicroMenuShowGuildBadge = "Show the online guild member count on the Guild button.",
    customMicroMenuShowBagBadge = "Show the free bag slot count on the Bags button.",
    customMicroMenuShowVolumeBadge = "Show the master volume number on the Volume button while hovering.",
    customMicroMenuDurabilityBadgeColor = "Choose the durability number text color.",
    customMicroMenuFriendBadgeColor = "Choose the online friend count text color.",
    customMicroMenuGuildBadgeColor = "Choose the online guild member count text color.",
    customMicroMenuBagBadgeColor = "Choose the free bag slot count text color.",
    customMicroMenuVolumeBadgeColor = "Choose the master volume number text color.",
    isCustomMicroMenuTimeAdj = "Allows changing the clock source, format, font size, and outline.",
    customMicroMenuTimeMode = "Choose whether the clock uses local time or server time.",
    customMicroMenuTimeFormat = "Choose 24-hour or 12-hour clock display.",
    customMicroMenuTimeFont = "Choose the font used by the top micro menu clock.",
    customMicroMenuFontSize = "Adjust the top micro menu clock text size.",
    customMicroMenuTimeTextYOffset = "Adjust only the hour and minute numbers up or down. The colon stays centered.",
    customMicroMenuTimeOutline = "Adjust the top micro menu clock text outline.",
    customMicroMenuIconSize = "Adjust the size of each top micro menu icon button.",
    customMicroMenuButtonSpacing = "Adjust the spacing between top micro menu icon buttons.",

    positionHeader = "Unlock and drag the system bar, or use arrow buttons for fine positioning.",
    microMenuPositionTools = "After unlocking, drag the system bar directly. Arrow buttons move it by 1 pixel.",

    infoBarHeader = "QFX modular info strips with editable visibility, order, position, size, and background direction.",
    isInfoBar = "Show the QFX info strips. Each strip only builds and loads its own textures after it is enabled.",
    infoBarFontSize = "Adjust the text size used by all info bars.",
    infoBarFadeStrength = "Adjust the shared background and class-line strength for all info bars. 0 hides the extra background, 50 keeps the default, and 100 makes it strongest.",
    infoBarLeftTopHeader = "Configure this info bar independently.",
    infoBarLeftBottomHeader = "Configure this info bar independently. This strip is disabled by default and must be enabled manually.",
    infoBarRightBottomHeader = "Configure this info bar independently.",
    infoBarLeftHeader = "Configure this info bar independently.",
    infoBarRightHeader = "Configure this info bar independently.",
    infoBarLeftEnabled = "Show or hide this single info bar.",
    infoBarLeftBottomEnabled = "Show or hide this single info bar. It is disabled by default.",
    infoBarRightEnabled = "Show or hide this single info bar.",
    infoBarLeftWidth = "Adjust this info bar width.",
    infoBarLeftBottomWidth = "Adjust this info bar width.",
    infoBarRightWidth = "Adjust this info bar width.",
    infoBarLeftHeight = "Adjust this info bar height.",
    infoBarLeftBottomHeight = "Adjust this info bar height.",
    infoBarRightHeight = "Adjust this info bar height.",
    infoBarLeftLineThickness = "Adjust this info bar class-colored line thickness.",
    infoBarLeftBottomLineThickness = "Adjust this info bar class-colored line thickness.",
    infoBarRightLineThickness = "Adjust this info bar class-colored line thickness.",
    infoBarLeftLineStyle = "Choose this info bar class-colored line visual style.",
    infoBarLeftBottomLineStyle = "Choose this info bar class-colored line visual style.",
    infoBarRightLineStyle = "Choose this info bar class-colored line visual style.",
    infoBarLeftLinePosition = "Choose whether this info bar shows the class line on the top edge, bottom edge, both edges, or not at all.",
    infoBarLeftBottomLinePosition = "Choose whether this info bar shows the class line on the top edge, bottom edge, both edges, or not at all.",
    infoBarRightLinePosition = "Choose whether this info bar shows the class line on the top edge, bottom edge, both edges, or not at all.",
    infoBarLeftFade = "Choose whether this info bar background extends from the left side or the right side.",
    infoBarLeftBottomFade = "Choose whether this info bar background extends from the left side or the right side.",
    infoBarRightFade = "Choose whether this info bar background extends from the left side or the right side.",
    infoBarLeftTopPosition = "Unlock and drag this info bar, or nudge it by 1 pixel.",
    infoBarLeftBottomPosition = "Unlock and drag this info bar, or nudge it by 1 pixel.",
    infoBarRightBottomPosition = "Unlock and drag this info bar, or nudge it by 1 pixel.",
    infoBarLeftPosition = "Unlock and drag this info bar, or nudge it by 1 pixel.",
    infoBarRightPosition = "Unlock and drag this info bar, or nudge it by 1 pixel.",
    infoBarLeftTopContent = "Checked items are shown. Each info bar can show up to 5 items. FPS includes latency without MS, so latency no longer takes a separate slot. Coordinates and Phase ID are optional items. Visible items are divided equally across the bar.",
    infoBarLeftBottomContent = "Checked items are shown. Each info bar can show up to 5 items. FPS includes latency without MS, so latency no longer takes a separate slot. Coordinates and Phase ID are optional items. Visible items are divided equally across the bar.",
    infoBarRightBottomContent = "Checked items are shown. Each info bar can show up to 5 items. FPS includes latency without MS, so latency no longer takes a separate slot. Coordinates and Phase ID are optional items. Visible items are divided equally across the bar.",
    infoBarLeftContent = "Checked items are shown. Each info bar can show up to 5 items. FPS includes latency without MS, so latency no longer takes a separate slot. Coordinates and Phase ID are optional items. Visible items are divided equally across the bar.",
    infoBarRightContent = "Checked items are shown. Each info bar can show up to 5 items. FPS includes latency without MS, so latency no longer takes a separate slot. Coordinates and Phase ID are optional items. Visible items are divided equally across the bar.",
}

local function CanonicalKey(value)
    if value == nil then return "" end
    if type(value) ~= "string" then return tostring(value) end
    if ns and ns.NormalizeLocaleKey then return ns.NormalizeLocaleKey(value) end
    return value
end

local function OptName(opt)
    if not opt then return "" end
    if opt.key and OPTION_NAME_KEYS[opt.key] then return OPTION_NAME_KEYS[opt.key] end
    if ns and ns.GetOptionTextKey then return CanonicalKey(ns.GetOptionTextKey(opt)) end
    return CanonicalKey(opt.nameKey or opt.labelKey or opt.name or "")
end

local function OptTooltip(opt)
    if not opt then return "" end
    if opt.key and OPTION_TOOLTIP_KEYS[opt.key] then return OPTION_TOOLTIP_KEYS[opt.key] end
    if ns and ns.GetOptionTooltipKey then return CanonicalKey(ns.GetOptionTooltipKey(opt)) end
    return CanonicalKey(opt.tooltipKey or opt.tooltip or "")
end

-- ========================================================================
-- QFXSystemBar popup UI (QFXWidgets factory renderer)
-- Independent plugin window drawn with the embedded QFXWidgets factory:
-- compact rows, cached pages, immediate lightweight refresh callbacks.
-- ========================================================================
local controlsByKey = {}
local navButtons = {}
local scrollPage -- factory scroll page (phase 2 chrome)
local subTabStrips = {} -- one factory Tabs strip per option group
local subTabOwners = {} -- factory refresh scope per sub-tab strip
local subTabAnchor
local rows = {}
local pageCache = {}
local pageOwners = {} -- stable factory refresh owner per page (survives cache/rebuild)
local currentPageIndex = 1
local currentGroupIndex = 1
local frame
local content
local pageTitle
local statusText
local rootTitle
local rootSubtitle
local rootIconCredit
local creditTitle
local creditNames
local resetPageButton
local resetAllButton
local BuildPage
local InvalidatePage
local InvalidateAllPages

local PANEL_W, PANEL_H = 960, 610
local LEFT_W = 170
local RIGHT_W = 730
local CONTENT_W = 692

local CARD_BACKDROP = {
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = false,
    edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
}

local function CopyTable(src)
    local out = {}
    for k, v in pairs(src or {}) do
        if type(v) == "table" then out[k] = CopyTable(v) else out[k] = v end
    end
    return out
end

local function MergeDefaults(target, source)
    for key, value in pairs(source or {}) do
        if type(value) == "table" then
            if type(target[key]) ~= "table" then target[key] = {} end
            MergeDefaults(target[key], value)
        elseif target[key] == nil then
            target[key] = value
        end
    end
end

local ensuredDB
local function EnsureDB()
    local db = QFXSystemBarDB
    if db == ensuredDB then return db end
    QFXSystemBarDB = QFXSystemBarDB or {}
    db = QFXSystemBarDB
    -- Locale application, SavedVariables migration, and default merging are
    -- idempotent, so run them only once per database instance. RefreshControl
    -- and every control change call EnsureDB repeatedly; re-running the full
    -- locale/alias rebuild there made every config refresh and several game
    -- events (BAG_UPDATE_DELAYED, GET_ITEM_INFO_RECEIVED) walk every locale
    -- table again.
    if ns.ApplyLocale then ns.ApplyLocale(db.language) end
    if ns.MigrateLocalizedSavedVariables then ns.MigrateLocalizedSavedVariables(db) end
    if ns.MigrateBadgeDisplaySettings then ns.MigrateBadgeDisplaySettings(db) end
    MergeDefaults(db, ns.defaults)
    if ns.MigrateLocalizedSavedVariables then ns.MigrateLocalizedSavedVariables(db) end
    ensuredDB = db
    return db
end

local function SetTooltip(owner, titleKey, bodyKey)
    if ns and ns.SetUITooltip then
        ns.SetUITooltip(owner, titleKey, bodyKey)
        return
    end
    owner:SetScript("OnEnter", function(self)
        if not bodyKey or bodyKey == "" then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:ClearLines()
        GameTooltip:AddLine(T(titleKey) or "", 1, 1, 1)
        GameTooltip:AddLine(T(bodyKey), 0.85, 0.85, 0.85, true)
        GameTooltip:Show()
    end)
    owner:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end

local function ApplyOptionChanged(opt, value)
    if opt and opt.onChange then opt.onChange(nil, value) end
    if statusText then SetUIText(statusText, "Settings applied") end
end

local function NormalizeEntries(opt)
    local raw = opt.options
    if type(raw) == "function" then raw = raw() end
    local out = {}
    if type(raw) ~= "table" then return out end
    for _, item in ipairs(raw) do
        if type(item) == "table" then
            out[#out + 1] = {
                value = item.value ~= nil and item.value or item[1],
                textKey = CanonicalKey(item.textKey or (item.text ~= nil and item.text or item.name or item.label or item[2])),
                shortTextKey = (item.shortTextKey or item.shortText) and CanonicalKey(item.shortTextKey or item.shortText) or nil,
                summaryTextKey = (item.summaryTextKey or item.summaryText) and CanonicalKey(item.summaryTextKey or item.summaryText) or nil,
            }
        end
    end
    return out
end

local function CopyValue(value)
    if type(value) ~= "table" then return value end
    local out = {}
    for k, v in pairs(value) do
        if type(v) == "table" then out[k] = CopyValue(v) else out[k] = v end
    end
    return out
end

local function GetMultiEntryText(opt, values)
    values = type(values) == "table" and values or {}
    local selected = {}
    for _, item in ipairs(NormalizeEntries(opt)) do
        if item.value ~= nil and values[item.value] then
            -- Dropdown rows keep the full descriptive label, but the closed
            -- dropdown uses a short label so translated text does not overflow.
            local textKey = item.summaryTextKey or item.shortTextKey or item.textKey or tostring(item.value)
            selected[#selected + 1] = T(textKey)
        end
    end
    if #selected == 0 then return T("None") end
    return table.concat(selected, ", ")
end

local function HexToRGB(hex)
    hex = tostring(hex or "FFFFFFFF"):gsub("|c", ""):gsub("|r", "")
    if #hex == 6 then hex = "FF" .. hex end
    local r = tonumber(hex:sub(3, 4), 16) or 255
    local g = tonumber(hex:sub(5, 6), 16) or 255
    local b = tonumber(hex:sub(7, 8), 16) or 255
    return r / 255, g / 255, b / 255
end

local function RGBToHex(r, g, b)
    r = math.max(0, math.min(255, math.floor((r or 1) * 255 + 0.5)))
    g = math.max(0, math.min(255, math.floor((g or 1) * 255 + 0.5)))
    b = math.max(0, math.min(255, math.floor((b or 1) * 255 + 0.5)))
    return string.format("FF%02X%02X%02X", r, g, b)
end




local function SetControlEnabled(ctrl, enabled)
    if not ctrl or not ctrl.row then return end
    ctrl.enabled = enabled
    if ctrl.qfx then ctrl.blocked = not enabled end -- factory disabled() reads this
    ctrl.row:SetAlpha(enabled and 1 or 0.38)
end

local function RefreshDependencies()
    for _, ctrl in pairs(controlsByKey) do SetControlEnabled(ctrl, true) end
    for _, groups in pairs(ns.OptionDependencies or {}) do
        for _, group in ipairs(groups) do
            local enabled = true
            if type(group.enabled) == "function" then enabled = group.enabled() and true or false end
            for _, childKey in ipairs(group.children or {}) do
                local ctrl = controlsByKey[childKey]
                if ctrl then SetControlEnabled(ctrl, enabled) end
            end
        end
    end
end


local function RefreshAllControls()
    RefreshDependencies()
    -- Global refresh is intentional: it also updates ownerless factory callbacks
    -- (e.g. the sub-tab strips). Pages no longer cancel each other because each
    -- page now owns its own factory refresh scope.
    if USE_QFX then W:Refresh() end
end

function ns.RefreshConfigControls()
    if frame and frame.IsShown and frame:IsShown() then
        RefreshAllControls()
    end
end

local function SetOptionValue(opt, value)
    local db = EnsureDB()
    if not opt or not opt.key then return end
    db[opt.key] = value
    ApplyOptionChanged(opt, value)
    RefreshAllControls()
end


local function CreateRow(parent, y, height, opt, isCard)
    local row = CreateFrame("Frame", nil, parent, isCard and "BackdropTemplate" or nil)
    row:SetSize(CONTENT_W, height)
    row:SetPoint("TOPLEFT", 0, y)
    if isCard then
        row:SetBackdrop(CARD_BACKDROP)
        row:SetBackdropColor(0.03, 0.03, 0.03, 0.30)
        row:SetBackdropBorderColor(0.42, 0.42, 0.42, 0.45)
    end
    SetTooltip(row, OptName(opt), OptTooltip(opt))
    rows[#rows + 1] = row
    return row
end









local function NormalizeButtonID(id)
    if ns.NormalizeMicroMenuButtonID then
        local normalized = ns.NormalizeMicroMenuButtonID(id)
        if normalized then return normalized end
    end
    return id
end

local function FindButtonItem(id)
    local normalized = NormalizeButtonID(id)
    for _, item in ipairs(ns.ButtonList or {}) do
        if item.id == normalized then return item end
    end
    return nil
end

local function GetButtonLabelKey(item)
    if not item then return "" end
    if ns.GetMicroMenuButtonLocaleKey and item.id then
        return ns.GetMicroMenuButtonLocaleKey(item.id)
    end
    return CanonicalKey(item.labelKey or item.name or item.id or "")
end

local function GetButtonTooltipKey(item)
    if not item then return "" end
    return CanonicalKey(item.tooltipKey or item.tooltip or GetButtonLabelKey(item))
end

local function GetButtonOrder()
    if ns.GetMicroMenuButtonOrder then return ns.GetMicroMenuButtonOrder() end
    return ns.GetDefaultMicroMenuButtonOrder and ns.GetDefaultMicroMenuButtonOrder() or {}
end

local function GetMicroMenuPreviewItems()
    local icons = {}
    local clock
    local db = EnsureDB()
    for _, id in ipairs(GetButtonOrder()) do
        local item = FindButtonItem(id)
        if item and db[item.var] == true then
            local texture, left, right, top, bottom, isText
            if ns.GetMicroMenuPreviewIconData then
                texture, left, right, top, bottom, isText = ns.GetMicroMenuPreviewIconData(id)
            end
            local previewItem = {
                id = id,
                labelKey = GetButtonLabelKey(item),
                texture = isText and nil or texture,
                coords = texture and { left or 0, right or 1, top or 0, bottom or 1 } or nil,
                previewText = isText and "12:34" or nil,
                locked = isText and true or false,
            }
            if isText and not clock then clock = previewItem else icons[#icons + 1] = previewItem end
        end
    end
    local items = {}
    local leftCount = math.floor(#icons / 2)
    for index = 1, leftCount do items[#items + 1] = icons[index] end
    if clock then items[#items + 1] = clock end
    for index = leftCount + 1, #icons do items[#items + 1] = icons[index] end
    return items
end

-- Shared horizontal drag preview used by both the micro menu and info bars.
-- The preview owns only ordinary config frames, so it can provide EUI-style
-- drag feedback without interfering with the secure/clickable live buttons.
local function CreateReorderPreview(parent, options)
    local preview = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    preview:SetSize(options.width or (CONTENT_W - 24), options.height or 46)
    preview:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false,
        edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    preview:SetBackdropColor(0.025, 0.03, 0.04, 0.88)
    preview:SetBackdropBorderColor(0.42, 0.42, 0.42, 0.65)

    local emptyText = preview:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    emptyText:SetPoint("CENTER")
    emptyText:SetTextColor(0.65, 0.65, 0.65)
    SetUIText(emptyText, "Enable items below to preview and drag them.")

    local insertion = preview:CreateTexture(nil, "OVERLAY", nil, 7)
    insertion:SetColorTexture(1.0, 0.72, 0.10, 0.95)
    insertion:SetWidth(2)
    insertion:SetPoint("TOP", preview, "TOP", 0, -3)
    insertion:SetPoint("BOTTOM", preview, "BOTTOM", 0, 3)
    insertion:Hide()

    local buttons = {}
    local activeButtons = {}
    local dragGhost
    local draggingIndex
    local draggingID
    local dragBoundary

    local function ApplyItemVisual(button, item)
        button._qfxItem = item
        button.icon:SetTexture(nil)
        button.icon:Hide()
        button.label:SetText("")
        button.label:Hide()

        if item.texture then
            button.icon:SetTexture(item.texture)
            local c = item.coords
            if c then button.icon:SetTexCoord(c[1], c[2], c[3], c[4]) else button.icon:SetTexCoord(0, 1, 0, 1) end
            button.icon:Show()
        else
            button.label:SetText(item.previewText or T(item.labelKey or item.id or ""))
            button.label:Show()
        end
    end

    local function EnsureGhost()
        if dragGhost then return dragGhost end
        dragGhost = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
        dragGhost:SetFrameStrata("TOOLTIP")
        dragGhost:SetFrameLevel(500)
        dragGhost:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = false,
            edgeSize = 8,
            insets = { left = 2, right = 2, top = 2, bottom = 2 },
        })
        dragGhost:SetBackdropColor(0.06, 0.07, 0.09, 0.96)
        dragGhost:SetBackdropBorderColor(1.0, 0.72, 0.10, 0.95)
        dragGhost.icon = dragGhost:CreateTexture(nil, "ARTWORK")
        dragGhost.icon:SetPoint("TOPLEFT", 4, -4)
        dragGhost.icon:SetPoint("BOTTOMRIGHT", -4, 4)
        dragGhost.label = dragGhost:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        dragGhost.label:SetPoint("CENTER")
        dragGhost.label:SetJustifyH("CENTER")
        dragGhost:Hide()
        return dragGhost
    end

    local function CursorLocalX()
        local cursorX = GetCursorPosition()
        local scale = preview:GetEffectiveScale()
        if not scale or scale == 0 then scale = 1 end
        return cursorX / scale - (preview:GetLeft() or 0)
    end

    local function ComputeBoundary()
        local x = CursorLocalX()
        for index, button in ipairs(activeButtons) do
            if x < button._qfxPreviewX + button._qfxPreviewW / 2 then return index end
        end
        return #activeButtons + 1
    end

    local function UpdateInsertion()
        if not draggingIndex or #activeButtons == 0 then insertion:Hide(); return end
        dragBoundary = ComputeBoundary()
        local finalIndex = dragBoundary
        if finalIndex > draggingIndex then finalIndex = finalIndex - 1 end
        if finalIndex == draggingIndex then insertion:Hide(); return end

        local x
        if dragBoundary <= #activeButtons then
            x = activeButtons[dragBoundary]._qfxPreviewX - 1
        else
            local last = activeButtons[#activeButtons]
            x = last._qfxPreviewX + last._qfxPreviewW + 1
        end
        insertion:ClearAllPoints()
        insertion:SetPoint("TOP", preview, "TOPLEFT", x, -3)
        insertion:SetPoint("BOTTOM", preview, "BOTTOMLEFT", x, 3)
        insertion:Show()
    end

    local function FinishDrag()
        preview:SetScript("OnUpdate", nil)
        local from = draggingIndex
        local id = draggingID
        local boundary = dragBoundary or (from and ComputeBoundary())
        if from and activeButtons[from] then activeButtons[from]:SetAlpha(1) end
        draggingIndex, draggingID, dragBoundary = nil, nil, nil
        insertion:Hide()
        if dragGhost then dragGhost:Hide() end
        if not (from and id and boundary) then return end

        local finalIndex = boundary
        if finalIndex > from then finalIndex = finalIndex - 1 end
        if finalIndex < 1 then finalIndex = 1 end
        if finalIndex > #activeButtons then finalIndex = #activeButtons end
        if finalIndex ~= from and options.onMove then options.onMove(id, finalIndex) end
        if options.afterDrop then options.afterDrop(id, finalIndex, from) end
        preview:Refresh()
    end

    local function BeginDrag(index)
        local button = activeButtons[index]
        local item = button and button._qfxItem
        if not item then return end
        draggingIndex = index
        draggingID = item.id
        dragBoundary = index
        button:SetAlpha(0.32)

        local ghost = EnsureGhost()
        ghost:SetSize(math.max(28, button:GetWidth()), math.max(28, button:GetHeight()))
        ApplyItemVisual(ghost, item)
        ghost:Show()

        preview:SetScript("OnUpdate", function()
            if not IsMouseButtonDown("LeftButton") then FinishDrag(); return end
            local cx, cy = GetCursorPosition()
            local scale = UIParent:GetEffectiveScale()
            if not scale or scale == 0 then scale = 1 end
            ghost:ClearAllPoints()
            ghost:SetPoint("CENTER", UIParent, "BOTTOMLEFT", cx / scale, cy / scale)
            UpdateInsertion()
        end)
    end

    local function EnsureButton(index)
        if buttons[index] then return buttons[index] end
        local button = CreateFrame("Button", nil, preview)
        local bg = button:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(0.12, 0.14, 0.17, 0.82)
        button._qfxBG = bg
        button.icon = button:CreateTexture(nil, "ARTWORK")
        button.icon:SetPoint("TOPLEFT", 4, -4)
        button.icon:SetPoint("BOTTOMRIGHT", -4, 4)
        button.label = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        button.label:SetPoint("CENTER")
        button.label:SetJustifyH("CENTER")
        if button.label.SetWordWrap then button.label:SetWordWrap(false) end
        button:SetScript("OnEnter", function(self) self._qfxBG:SetColorTexture(0.24, 0.27, 0.31, 0.95) end)
        button:SetScript("OnLeave", function(self) self._qfxBG:SetColorTexture(0.12, 0.14, 0.17, 0.82) end)
        button:SetScript("OnMouseDown", function(self, mouseButton)
            if mouseButton ~= "LeftButton" or draggingIndex or (self._qfxItem and self._qfxItem.locked) then return end
            local startX, startY = GetCursorPosition()
            self:SetScript("OnUpdate", function(armed)
                if not IsMouseButtonDown("LeftButton") then armed:SetScript("OnUpdate", nil); return end
                local x, y = GetCursorPosition()
                if math.abs(x - startX) >= 3 or math.abs(y - startY) >= 3 then
                    armed:SetScript("OnUpdate", nil)
                    BeginDrag(armed._qfxPreviewIndex)
                end
            end)
        end)
        buttons[index] = button
        return button
    end

    function preview:Refresh()
        if draggingIndex then return end
        local items = options.getItems and options.getItems() or {}
        for _, button in ipairs(buttons) do button:Hide() end
        for index = #activeButtons, 1, -1 do activeButtons[index] = nil end
        emptyText:SetShown(#items == 0)

        local width = preview:GetWidth() or (options.width or CONTENT_W - 24)
        local height = preview:GetHeight() or (options.height or 46)
        local gap = options.gap or 2
        local pad = 4
        local itemWidth
        local startX
        if options.fill and #items > 0 then
            itemWidth = (width - pad * 2 - gap * (#items - 1)) / #items
            startX = pad
        else
            itemWidth = options.itemWidth or 28
            local totalWidth = #items * itemWidth + math.max(0, #items - 1) * gap
            startX = math.max(pad, (width - totalWidth) / 2)
        end

        for index, item in ipairs(items) do
            local button = EnsureButton(index)
            local x = startX + (index - 1) * (itemWidth + gap)
            button:ClearAllPoints()
            button:SetPoint("TOPLEFT", preview, "TOPLEFT", x, -4)
            button:SetSize(itemWidth, height - 8)
            button._qfxPreviewIndex = index
            button._qfxPreviewX = x
            button._qfxPreviewW = itemWidth
            ApplyItemVisual(button, item)
            button:SetAlpha(1)
            button:EnableMouse(true)
            button:Show()
            activeButtons[index] = button
        end
        if options.onRefreshHost then options.onRefreshHost(preview, items) end
    end

    preview:SetScript("OnHide", function()
        if draggingIndex then FinishDrag() end
    end)
    preview:Refresh()
    return preview
end

InvalidatePage = function(index)
    index = index or currentPageIndex
    local cache = index and pageCache[index]
    if not cache then return end
    if USE_QFX and pageOwners[index] then W:ClearRefreshes(pageOwners[index]) end
    for _, row in ipairs(cache.rows or {}) do
        row:Hide()
    end
    pageCache[index] = nil
    if index == currentPageIndex then
        rows = {}
        controlsByKey = {}
    end
end

InvalidateAllPages = function()
    for index in pairs(pageCache) do
        InvalidatePage(index)
    end
end






local function GetInfoBarSlot(opt)
    return opt and opt.slotKey and ns.InfoBarSlots and ns.InfoBarSlots[opt.slotKey]
end

local function GetInfoBarOrder(opt)
    local slot = GetInfoBarSlot(opt)
    if not slot then return {} end
    local db = EnsureDB()
    if ns.InfoBarDefaultOrder and type(db[slot.orderKey]) ~= "table" then
        db[slot.orderKey] = CopyTable(ns.InfoBarDefaultOrder)
    end
    local seen, out = {}, {}
    for _, rawID in ipairs(db[slot.orderKey] or {}) do
        local id = ns.NormalizeInfoBarItemID and ns.NormalizeInfoBarItemID(rawID) or rawID
        if ns.InfoBarItems and ns.InfoBarItems[id] and not seen[id] then
            out[#out + 1] = id
            seen[id] = true
        end
    end
    local canonicalIndex = {}
    for index, id in ipairs(ns.InfoBarAllItems or {}) do canonicalIndex[id] = index end
    for _, id in ipairs(ns.InfoBarAllItems or {}) do
        if not seen[id] then
            local targetIndex = canonicalIndex[id] or 999
            local insertAt = #out + 1
            for i = #out, 1, -1 do
                local existingIndex = canonicalIndex[out[i]] or 999
                if existingIndex < targetIndex then
                    insertAt = i + 1
                    break
                end
                insertAt = i
            end
            table.insert(out, insertAt, id)
            seen[id] = true
        end
    end
    -- Only persist when the normalized order differs: this runs from every
    -- preview refresh, and replacing the table each time churned garbage.
    local stored = db[slot.orderKey]
    local changed = type(stored) ~= "table" or #stored ~= #out
    if not changed then
        for i = 1, #out do
            if stored[i] ~= out[i] then changed = true break end
        end
    end
    if changed then db[slot.orderKey] = out end
    if type(db[slot.enabledKey]) ~= "table" then db[slot.enabledKey] = CopyTable(ns.defaults and ns.defaults[slot.enabledKey] or {}) end
    return out
end

local function GetInfoBarItemLabelKey(id)
    local item = ns.InfoBarItems and ns.InfoBarItems[id]
    return item and item.labelKey or id or ""
end

local function GetInfoBarItemTooltipKey(id)
    local item = ns.InfoBarItems and ns.InfoBarItems[id]
    return item and item.tooltipKey or GetInfoBarItemLabelKey(id)
end

local function GetInfoBarPreviewItems(opt)
    local items = {}
    local slot = GetInfoBarSlot(opt)
    if not slot then return items end
    local enabled = EnsureDB()[slot.enabledKey] or {}
    for _, id in ipairs(GetInfoBarOrder(opt)) do
        if enabled[id] == true then
            local previewText = T(GetInfoBarItemLabelKey(id))
            if id == "meetingstone" and ns.GetPremadeAddonDisplayName then
                local name = ns.GetPremadeAddonDisplayName()
                if type(name) == "string" and name ~= "" and name ~= "MeetingStone" and name ~= "Meeting Stone" then
                    previewText = name
                end
            elseif (id == "profession" or id == "secondaryprofession") and ns.GetInfoBarProfessionPreviewText then
                previewText = ns.GetInfoBarProfessionPreviewText(id) or previewText
            end
            items[#items + 1] = {
                id = id,
                labelKey = GetInfoBarItemLabelKey(id),
                previewText = previewText,
            }
        end
    end
    return items
end

local function ApplyPreviewGradient(texture, r, g, b, fromAlpha, toAlpha)
    texture:SetTexture("Interface\\Buttons\\WHITE8x8")
    local colorFactory = _G.CreateColor
    if texture.SetGradient and colorFactory then
        local ok = pcall(texture.SetGradient, texture, "Horizontal", colorFactory(r, g, b, fromAlpha), colorFactory(r, g, b, toAlpha))
        if ok then return end
    end
    if texture.SetGradientAlpha then
        local ok = pcall(texture.SetGradientAlpha, texture, "HORIZONTAL", r, g, b, fromAlpha, r, g, b, toAlpha)
        if ok then return end
    end
    texture:SetColorTexture(r, g, b, math.max(fromAlpha or 0, toAlpha or 0))
end

local function RefreshInfoBarPreviewAppearance(preview, opt)
    local slot = GetInfoBarSlot(opt)
    if not slot then return end
    if not preview.qfxBody then
        preview.qfxBody = preview:CreateTexture(nil, "BACKGROUND", nil, 1)
        preview.qfxBody:SetPoint("TOPLEFT", 3, -3)
        preview.qfxBody:SetPoint("BOTTOMRIGHT", -3, 3)
        preview.qfxTopLine = preview:CreateTexture(nil, "OVERLAY", nil, 5)
        preview.qfxTopLine:SetPoint("TOPLEFT", 3, -3)
        preview.qfxTopLine:SetPoint("TOPRIGHT", -3, -3)
        preview.qfxBottomLine = preview:CreateTexture(nil, "OVERLAY", nil, 5)
        preview.qfxBottomLine:SetPoint("BOTTOMLEFT", 3, 3)
        preview.qfxBottomLine:SetPoint("BOTTOMRIGHT", -3, 3)
    end

    local db = EnsureDB()
    local strength = math.max(0, math.min(100, tonumber(db.infoBarFadeStrength) or 50)) / 100
    local fade = db[slot.fadeKey] or slot.defaultFade or "left"
    local fromAlpha, toAlpha = strength, 0
    if fade == "right" then fromAlpha, toAlpha = 0, strength end
    ApplyPreviewGradient(preview.qfxBody, 0, 0, 0, fromAlpha, toAlpha)

    local _, class = UnitClass("player")
    local color = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
    local r, g, b = color and color.r or 1, color and color.g or 0.72, color and color.b or 0.10
    local thickness = math.max(1, math.min(4, tonumber(db[slot.lineThicknessKey]) or 1))
    preview.qfxTopLine:SetHeight(thickness)
    preview.qfxBottomLine:SetHeight(thickness)
    ApplyPreviewGradient(preview.qfxTopLine, r, g, b, fromAlpha, toAlpha)
    ApplyPreviewGradient(preview.qfxBottomLine, r, g, b, fromAlpha, toAlpha)
    local position = db[slot.linePositionKey] or "both"
    preview.qfxTopLine:SetShown(position == "top" or position == "both")
    preview.qfxBottomLine:SetShown(position == "bottom" or position == "both")
end

local function GetPageIndexByKey(key)
    if not key then return nil end
    if ns.OptionPageIndexByKey and ns.OptionPageIndexByKey[key] then
        return ns.OptionPageIndexByKey[key]
    end
    for index, page in ipairs(ns.OptionPages or {}) do
        if page and page.key == key then return index end
    end
    return nil
end

local function FindGroupIndexForPageKey(pageKey)
    if not pageKey then return nil end
    for groupIndex, group in ipairs(ns.OptionGroups or {}) do
        for _, key in ipairs(group.pages or {}) do
            if key == pageKey then return groupIndex end
        end
    end
    return nil
end

local function GetFirstPageIndexForGroup(group)
    local firstKey = group and group.pages and group.pages[1]
    return GetPageIndexByKey(firstKey) or 1
end

local function PageNeedsInfoBar(page)
    if not page then return false end
    if type(page.key) == "string" and page.key:match("^info") then return true end
    for _, opt in ipairs(page.options or {}) do
        local optType = opt and opt.type
        if type(optType) == "string" and optType:find("infoBar", 1, true) then return true end
    end
    return false
end

local function EnsureInfoBarForPage(page)
    if PageNeedsInfoBar(page) and ns.EnsureInfoBarLoaded and not ns.InfoBarLoaded then
        ns.EnsureInfoBarLoaded()
    end
end

local function SelectGroup(groupIndex)
    local group = ns.OptionGroups and ns.OptionGroups[groupIndex]
    if not group then return end
    currentGroupIndex = groupIndex
    BuildPage(GetFirstPageIndexForGroup(group))
end

local function RefreshNavigationState(activePage)
    local groups = ns.OptionGroups or {}
    if activePage and activePage.key then
        currentGroupIndex = FindGroupIndexForPageKey(activePage.key) or currentGroupIndex or 1
    end
    local activeGroup = groups[currentGroupIndex]

    for i, btn in ipairs(navButtons) do
        local group = groups[i]
        if group then
            SetUIText(btn, OptName(group))
            btn:SetActive(i == currentGroupIndex)
            btn:Show()
        else
            btn:Hide()
        end
    end

    -- Factory page tabs (one cached strip per group; the strip itself re-reads
    -- the active page on every W:Refresh()).
    if USE_QFX then
        for _, strip in pairs(subTabStrips) do strip:Hide() end
        if activeGroup and subTabAnchor then
            local gi = currentGroupIndex or 1
            local strip = subTabStrips[gi]
            if not strip then
                local items = {}
                for _, pageKey in ipairs(activeGroup.pages or {}) do
                    local pi = GetPageIndexByKey(pageKey)
                    local page = pi and ns.OptionPages and ns.OptionPages[pi]
                    if page then
                        items[#items + 1] = { key = pageKey, label = UIText(OptName(page)) }
                    end
                end
                -- scope the strip's factory refresh callback to its own owner so
                -- a language switch can drop it instead of leaking a permanent one
                local owner = subTabOwners[gi] or {}
                subTabOwners[gi] = owner
                W:BeginPage(owner)
                strip = W:Tabs(subTabAnchor, 0, items,
                    function()
                        -- must read the CURRENT page: a captured activePage would
                        -- freeze the underline on the first tab forever
                        local cur = ns.OptionPages and ns.OptionPages[currentPageIndex]
                        return cur and cur.key
                    end,
                    function(key)
                        local pi = GetPageIndexByKey(key)
                        if pi then BuildPage(pi) end
                    end)
                W:EndPage()
                subTabStrips[gi] = strip
            end
            strip:Show()
        end
        return
    end

end

-------------------------------------------------------------------------------
local function QfxOptText(opt)
    return UIText(OptName(opt))
end

local function QfxOptTip(opt)
    local tip = OptTooltip(opt)
    if tip == nil or tip == "" then return nil end
    return UIText(tip)
end
-- QFXWidgets renderers for the generic option types (migration phase 1).
-- Each returns (row, usedHeight) like the legacy builders, keeps its frame in
-- `rows` for the page cache and registers a ctrl in controlsByKey. Factory rows
-- read/write the DB through getValue/setValue and repaint via W:Refresh().
-------------------------------------------------------------------------------
local function QfxDisabled(ctrl)
    return function() return ctrl.blocked == true end
end

local function CreateHeaderQFX(parent, y, opt)
    local head, hUsed = W:SectionHeader(parent, QfxOptText(opt), y)
    rows[#rows + 1] = head
    local tip = QfxOptTip(opt)
    if tip and tip ~= "" and tip ~= QfxOptText(opt) then
        local noteY, note = W:Note(parent, y - hUsed, tip)
        if note then rows[#rows + 1] = note end
        return head, (y - hUsed) - noteY
    end
    return head, hUsed
end

local function CreateCheckboxQFX(parent, y, opt)
    local ctrl = { opt = opt, qfx = true, blocked = false }
    local function Get()
        return EnsureDB()[opt.key] == true
    end
    local function Set(v)
        SetOptionValue(opt, v and true or false)
    end
    local row, h
    if opt.colorKey then
        local colorOpt = {
            key = opt.colorKey,
            nameKey = opt.colorNameKey or opt.nameKey,
            tooltipKey = opt.colorTooltipKey or opt.tooltipKey,
            default = opt.colorDefault or (ns.defaults and ns.defaults[opt.colorKey]) or "FFFFFFFF",
            onChange = opt.onChange,
        }
        local function GetColor()
            return HexToRGB(EnsureDB()[opt.colorKey] or colorOpt.default)
        end
        local function SetColor(r, g, b)
            SetOptionValue(colorOpt, RGBToHex(r, g, b))
        end
        row, h = W:DualRow(parent, y,
            { type = "toggle", text = QfxOptText(opt), getValue = Get, setValue = Set,
              tooltip = QfxOptTip(opt), disabled = QfxDisabled(ctrl) },
            { type = "color", text = T(colorOpt.nameKey), getValue = GetColor, setValue = SetColor,
              tooltip = T(colorOpt.tooltipKey), disabled = QfxDisabled(ctrl) })
        controlsByKey[opt.colorKey] = ctrl
    else
        row, h = W:DualRow(parent, y,
            { type = "toggle", text = QfxOptText(opt), getValue = Get, setValue = Set,
              tooltip = QfxOptTip(opt), disabled = QfxDisabled(ctrl) }, nil)
    end
    ctrl.row = row
    rows[#rows + 1] = row
    controlsByKey[opt.key] = ctrl
    return row, h
end

local function CreateSliderQFX(parent, y, opt)
    local ctrl = { opt = opt, qfx = true, blocked = false }
    local function Get()
        local v = EnsureDB()[opt.key]
        if v == nil then v = opt.default or opt.min or 0 end
        return v
    end
    local function Set(v)
        -- Light write path (same as the legacy slider): a page-wide
        -- RefreshAllControls on every drag tick made the whole page flicker.
        local db = EnsureDB()
        db[opt.key] = v
        ApplyOptionChanged(opt, v)
    end
    local row, h = W:DualRow(parent, y,
        { type = "slider", text = QfxOptText(opt), min = opt.min or 0, max = opt.max or 100,
          step = opt.step or 1, valueSuffix = opt.suffix or opt.unit or "",
          getValue = Get, setValue = Set, tooltip = QfxOptTip(opt), disabled = QfxDisabled(ctrl) }, nil)
    ctrl.row = row
    rows[#rows + 1] = row
    controlsByKey[opt.key] = ctrl
    return row, h
end

local function QfxDropdownData(opt)
    local values, order, items = {}, {}, {}
    for _, item in ipairs(NormalizeEntries(opt)) do
        local label = T(item.textKey or tostring(item.value))
        values[item.value] = label
        order[#order + 1] = item.value
        items[#items + 1] = { key = item.value, label = label }
    end
    return values, order, items
end

local function CreateDropdownQFX(parent, y, opt)
    local ctrl = { opt = opt, qfx = true, blocked = false }
    local values, order, items = QfxDropdownData(opt)
    local row, h
    if opt.multiSelect then
        local function Get(k)
            local v = EnsureDB()[opt.key]
            return type(v) == "table" and v[k] == true
        end
        local function Set(k, on)
            local db = EnsureDB()
            local v = type(db[opt.key]) == "table" and db[opt.key] or {}
            local out = {}
            for key, val in pairs(v) do out[key] = val end
            out[k] = on and true or nil
            SetOptionValue(opt, out)
        end
        row, h = W:DualRow(parent, y,
            { type = "checkboxDropdown", text = QfxOptText(opt), width = 220, items = items,
              getFn = Get, setFn = Set,
              summaryFn = function() return GetMultiEntryText(opt, EnsureDB()[opt.key]) end,
              tooltip = QfxOptTip(opt), disabled = QfxDisabled(ctrl) }, nil)
    else
        local function Get()
            return EnsureDB()[opt.key] or opt.default
        end
        local function Set(v)
            SetOptionValue(opt, v)
        end
        row, h = W:DualRow(parent, y,
            { type = "dropdown", text = QfxOptText(opt), width = 220, values = values, order = order,
              getValue = Get, setValue = Set, tooltip = QfxOptTip(opt), disabled = QfxDisabled(ctrl) }, nil)
    end
    ctrl.row = row
    rows[#rows + 1] = row
    controlsByKey[opt.key] = ctrl
    return row, h
end

local function CreateColorQFX(parent, y, opt)
    local ctrl = { opt = opt, qfx = true, blocked = false }
    local function Get()
        return HexToRGB(EnsureDB()[opt.key] or opt.default)
    end
    local function Set(r, g, b)
        SetOptionValue(opt, RGBToHex(r, g, b))
    end
    local row, h = W:DualRow(parent, y,
        { type = "label", text = QfxOptText(opt) },
        { type = "color", text = QfxOptText(opt), getValue = Get, setValue = Set,
          tooltip = QfxOptTip(opt), disabled = QfxDisabled(ctrl) })
    ctrl.row = row
    rows[#rows + 1] = row
    controlsByKey[opt.key] = ctrl
    return row, h
end

local function CreateIconStyleQFX(parent, y, opt)
    local ctrl = { opt = opt, qfx = true, blocked = false }
    local values, order = {}, {}
    for _, item in ipairs(NormalizeEntries(opt)) do
        values[item.value] = T(item.textKey or tostring(item.value))
        order[#order + 1] = item.value
    end
    local function Get()
        return EnsureDB()[opt.key] or opt.default
    end
    local function Set(v)
        SetOptionValue(opt, v)
    end
    local row, h = W:DualRow(parent, y,
        { type = "label", text = QfxOptText(opt) },
        { type = "segmented", text = QfxOptText(opt), values = values, order = order,
          getValue = Get, setValue = Set, tooltip = QfxOptTip(opt), disabled = QfxDisabled(ctrl) })
    ctrl.row = row
    rows[#rows + 1] = row
    controlsByKey[opt.key] = ctrl
    return row, h
end

-------------------------------------------------------------------------------
-- QFXWidgets renderers for the custom option types (migration phase 2b).
-- The legacy drag-preview strips stay (they own the drag interaction); the
-- checkbox lists / position controls are factory widgets now.
-------------------------------------------------------------------------------
local function CreateButtonOrderQFX(parent, y, opt)
    local startY = y
    local order = GetButtonOrder()
    local items, seen = {}, {}
    for _, rawID in ipairs(order) do
        local id = NormalizeButtonID(rawID)
        if not seen[id] then
            seen[id] = true
            local item = FindButtonItem(id)
            if item then items[#items + 1] = item end
        end
    end
    for _, item in ipairs(ns.ButtonList or {}) do
        if not seen[item.id] then items[#items + 1] = item end
    end

    local ctrl = { opt = opt, qfx = true, blocked = false }

    local noteY, hint = W:Note(parent, y, UIText("Drag the preview icons to reorder. The clock remains centered. Check items below to show them."))
    if hint then rows[#rows + 1] = hint end
    y = noteY

    local previewRow = CreateRow(parent, y, 56, opt, false)
    local preview = CreateReorderPreview(previewRow, {
        width = CONTENT_W - 24, height = 48, itemWidth = 36, gap = 1,
        getItems = GetMicroMenuPreviewItems,
        onMove = function(id, targetIndex)
            if ns.MoveMicroMenuButtonTo then ns.MoveMicroMenuButtonTo(id, targetIndex) end
        end,
        afterDrop = function()
            RefreshAllControls()
            if statusText then SetUIText(statusText, "Button order updated") end
        end,
    })
    preview:SetPoint("TOPLEFT", 12, -6)
    y = y - 56

    local entries = {}
    for i = 1, #items do
        local item = items[i]
        entries[i] = {
            label = UIText(GetButtonLabelKey(item)),
            getValue = function()
                return EnsureDB()[item.var] == true
            end,
            setValue = function(v)
                local function apply(finalChecked)
                    EnsureDB()[item.var] = finalChecked and true or false
                    if opt.onChange then opt.onChange() end
                    if statusText then SetUIText(statusText, "Settings applied") end
                    RefreshAllControls()
                end
                if item.id == "MeetingStone" and ns.ConfirmMeetingStoneButtonVisibility then
                    local proxy = { SetChecked = function(_, v2) apply(v2) end }
                    ns.ConfirmMeetingStoneButtonVisibility(v, proxy, apply)
                else
                    apply(v)
                end
            end,
            tooltip = UIText(GetButtonTooltipKey(item)),
        }
    end
    local grid, gh = W:CheckGrid(parent, y, 3, entries, { gap = 12, rowH = 24 })
    rows[#rows + 1] = grid
    y = y - gh

    ctrl.row = grid
    controlsByKey[opt.key] = ctrl
    W:RegisterRefresh(function()
        if preview and preview.Refresh then preview:Refresh() end
    end)
    return grid, startY - y
end

local function CreateInfoBarContentQFX(parent, y, opt)
    local startY = y
    local slot = GetInfoBarSlot(opt)
    local order = GetInfoBarOrder(opt)
    local ctrl = { opt = opt, qfx = true, blocked = false }

    local noteY, hint = W:Note(parent, y, UIText("Max 5 shown. Drag the preview items to reorder."))
    if hint then rows[#rows + 1] = hint end
    y = noteY
    if not slot then
        ctrl.row = hint
        controlsByKey[opt.key] = ctrl
        return hint, startY - y
    end

    local db = EnsureDB()
    local enabled = db[slot.enabledKey]
    if type(enabled) ~= "table" then enabled = {}; db[slot.enabledKey] = enabled end
    local maxItems = ns.InfoBarMaxItems or 5

    local previewRow = CreateRow(parent, y, 56, opt, false)
    local preview = CreateReorderPreview(previewRow, {
        width = CONTENT_W - 24, height = 48, fill = true, gap = 2,
        getItems = function() return GetInfoBarPreviewItems(opt) end,
        onMove = function(id, targetIndex)
            if ns.MoveInfoBarItemTo then ns.MoveInfoBarItemTo(opt.slotKey, id, targetIndex) end
        end,
        afterDrop = function()
            RefreshAllControls()
            if statusText then SetUIText(statusText, "Button order updated") end
        end,
        onRefreshHost = function(host) RefreshInfoBarPreviewAppearance(host, opt) end,
    })
    preview:SetPoint("TOPLEFT", 12, -6)
    y = y - 56

    local entries = {}
    for i, id in ipairs(order) do
        entries[i] = {
            label = UIText(GetInfoBarItemLabelKey(id)),
            getValue = function()
                local e = EnsureDB()[slot.enabledKey]
                return type(e) == "table" and e[id] == true
            end,
            setValue = function(v)
                local ok
                if ns.SetInfoBarItemEnabled then
                    ok = ns.SetInfoBarItemEnabled(opt.slotKey, id, v)
                else
                    EnsureDB()[slot.enabledKey][id] = v and true or false
                    ok = true
                end
                if not ok then
                    local msg = UIFormat("One info bar can show up to %d items.", maxItems)
                    if UIErrorsFrame and UIErrorsFrame.AddMessage then UIErrorsFrame:AddMessage(msg) end
                    if statusText then statusText:SetText(msg) end
                else
                    if opt.onChange then opt.onChange() end
                    if statusText then SetUIText(statusText, "Settings applied") end
                end
                RefreshAllControls()
            end,
            tooltip = UIText(GetInfoBarItemTooltipKey(id)),
        }
    end
    local grid, gh = W:CheckGrid(parent, y, 3, entries, {
        gap = 12, rowH = 24, maxSelected = maxItems,
        limitTooltip = UIFormat("One info bar can show up to %d items.", maxItems),
    })
    rows[#rows + 1] = grid
    y = y - gh

    local limit, lh = W:StatusRow(parent, y, {
        getText = function()
            local count = ns.GetInfoBarEnabledCount and ns.GetInfoBarEnabledCount(opt.slotKey) or 0
            return UIFormat("Shown: %d/%d. The bar is divided equally by the number of shown items.", count, maxItems)
        end,
    })
    rows[#rows + 1] = limit
    y = y - lh

    ctrl.row = grid
    controlsByKey[opt.key] = ctrl
    W:RegisterRefresh(function()
        if preview and preview.Refresh then preview:Refresh() end
    end)
    return grid, startY - y
end

-- Nudge/position pages share this skeleton (unlock toggle, 4 arrows, reset).
local function CreatePositionQFX(parent, y, opt)
    local startY = y
    local ctrl = { opt = opt, qfx = true, blocked = false }
    local isInfoBar = opt.type == "infoBarPosition"
    local slot = isInfoBar and GetInfoBarSlot(opt) or nil

    -- The plain position page already has its own header option (title +
    -- description); only the info-bar variants need a section header here.
    if isInfoBar then
        local head, hh = W:SectionHeader(parent, QfxOptText(opt), y)
        rows[#rows + 1] = head
        y = y - hh
        local tip = QfxOptTip(opt) or UIText("Unlock to drag this info bar directly. Arrow buttons nudge it by 1 pixel.")
        local noteY, note = W:Note(parent, y, tip)
        if note then rows[#rows + 1] = note end
        y = noteY
    end

    local function GetUnlock()
        if isInfoBar then return slot and QFXSystemBarDB and QFXSystemBarDB[slot.unlockedKey] and true or false end
        return EnsureDB().customMicroMenuUnlocked and true or false
    end
    local function SetUnlock(v)
        v = v and true or false
        if isInfoBar then
            if slot and ns.SetInfoBarUnlocked then ns.SetInfoBarUnlocked(opt.slotKey, v) end
        else
            EnsureDB().customMicroMenuUnlocked = v
            if ns.SetMicroMenuUnlocked then ns.SetMicroMenuUnlocked(v) end
        end
        -- reuse the already-translated keys (the unified English strings added
        -- by the rebuild had no locale entries, so non-English clients saw English)
        if statusText then
            SetUIText(statusText, v
                and (isInfoBar and "Unlocked. Drag the info bar to move it." or "Unlocked. Drag the system bar to move it.")
                or (isInfoBar and "Info bar position locked" or "System bar position locked"))
        end
        RefreshAllControls()
    end
    local function Nudge(dx, dy)
        if isInfoBar then
            if ns.NudgeInfoBar then ns.NudgeInfoBar(opt.slotKey, dx, dy) end
        else
            if ns.NudgeMicroMenu then ns.NudgeMicroMenu(dx, dy) end
        end
        RefreshAllControls()
        if statusText then
            -- the micro menu is a secure frame: nudges are refused in combat,
            -- so do not claim the position changed
            if not isInfoBar and InCombatLockdown and InCombatLockdown() then
                SetUIText(statusText, "Cannot move position in combat.")
            else
                SetUIText(statusText, "Position updated")
            end
        end
    end

    local row, h = W:DualRow(parent, y,
        { type = "toggle", text = UIText("Unlock Dragging"), getValue = GetUnlock, setValue = SetUnlock,
          tooltip = UIText(isInfoBar and "Allows moving this info bar with the mouse." or "Allows moving QFXSystemBar with the mouse."),
          disabled = QfxDisabled(ctrl) }, nil)
    rows[#rows + 1] = row
    y = y - h

    -- one compact row: description on the left, the 4 half-width nudge buttons
    -- on the right (← → ↓ ↑)
    local nudgeRow, nudgeH = W:DualRow(parent, y,
        { type = "label", text = UIText("Nudge Position") },
        { type = "buttonRow", disabled = QfxDisabled(ctrl), buttons = {
            { text = "←", width = 60, tooltip = UIText("Move Left 1"), onClick = function() Nudge(-1, 0) end },
            { text = "→", width = 60, tooltip = UIText("Move Right 1"), onClick = function() Nudge(1, 0) end },
            { text = "↓", width = 60, tooltip = UIText("Move Down 1"), onClick = function() Nudge(0, -1) end },
            { text = "↑", width = 60, tooltip = UIText("Move Up 1"), onClick = function() Nudge(0, 1) end },
        } })
    rows[#rows + 1] = nudgeRow
    y = y - nudgeH

    -- reuse the existing translated format key instead of a new English label
    local coord, ch = W:StatusRow(parent, y, {
        getText = function()
            local db = EnsureDB()
            if isInfoBar then
                if slot then
                    return UIFormat("Current Position: X %d, Y %d",
                        db[slot.xKey] or slot.defaultX or 0, db[slot.yKey] or slot.defaultY or 0)
                end
                return ""
            end
            return UIFormat("Current Position: X %d, Y %d",
                db.customMicroMenuPositionX or 0, db.customMicroMenuPositionY or 0)
        end,
    })
    rows[#rows + 1] = coord
    y = y - ch

    local rr, rh = W:ResetRow(parent, y, {
        buttons = { { text = UIText("Reset Position"), onReset = function()
            if isInfoBar then
                if ns.ResetInfoBarPosition then ns.ResetInfoBarPosition(opt.slotKey) end
            else
                if ns.ResetMicroMenuPosition then
                    ns.ResetMicroMenuPosition()
                else
                    local db = EnsureDB()
                    db.customMicroMenuUnlocked = false
                    db.customMicroMenuPositionX = opt.defaultX or 0
                    db.customMicroMenuPositionY = opt.defaultY or 0
                end
            end
        end } },
    })
    rows[#rows + 1] = rr
    y = y - rh

    ctrl.row = row
    controlsByKey[opt.key] = ctrl
    return rr, startY - y
end

local function CreateTopCenterWidgetPositionQFX(parent, y, opt)
    local startY = y
    local ctrl = { opt = opt, qfx = true, blocked = false }

    local head, hh = W:SectionHeader(parent, QfxOptText(opt), y)
    rows[#rows + 1] = head
    y = y - hh

    local row, h = W:DualRow(parent, y,
        { type = "toggle", text = UIText("Lock Position"), tooltip = UIText("Lock Position"),
          getValue = function()
              local m = ns.TopCenterWidget
              return m and m.IsLocked and m:IsLocked() or false
          end,
          setValue = function(v)
              if ns.TopCenterWidget and ns.TopCenterWidget.SetLocked then ns.TopCenterWidget:SetLocked(v and true or false) end
              RefreshAllControls()
          end,
          disabled = QfxDisabled(ctrl) }, nil)
    rows[#rows + 1] = row
    y = y - h

    local function Nudge(dx, dy)
        if ns.TopCenterWidget and ns.TopCenterWidget.Nudge then ns.TopCenterWidget:Nudge(dx, dy) end
        RefreshAllControls()
    end
    local nudgeRow, nudgeH = W:DualRow(parent, y,
        { type = "label", text = UIText("Nudge Position") },
        { type = "buttonRow", disabled = QfxDisabled(ctrl), buttons = {
            { text = "←", width = 60, tooltip = UIText("Move Left 1"), onClick = function() Nudge(-1, 0) end },
            { text = "→", width = 60, tooltip = UIText("Move Right 1"), onClick = function() Nudge(1, 0) end },
            { text = "↓", width = 60, tooltip = UIText("Move Down 1"), onClick = function() Nudge(0, -1) end },
            { text = "↑", width = 60, tooltip = UIText("Move Up 1"), onClick = function() Nudge(0, 1) end },
        } })
    rows[#rows + 1] = nudgeRow
    y = y - nudgeH

    local proxyHost = CreateFrame("Frame", nil, parent)
    proxyHost:Hide()
    local coordProxy = W.Font(proxyHost, 12, 1, 1, 1, 1)
    local coord, ch = W:StatusRow(parent, y, {
        label = UIText("Current Position"),
        getText = function()
            local m = ns.TopCenterWidget
            if m and m.RefreshCoordinateText then m:RefreshCoordinateText(coordProxy) end
            return coordProxy:GetText() or ""
        end,
    })
    rows[#rows + 1] = coord
    y = y - ch

    local rr, rh = W:ResetRow(parent, y, {
        buttons = { { text = UIText("Reset Top-Center Position"), onReset = function()
            if ns.TopCenterWidget and ns.TopCenterWidget.ResetPosition then ns.TopCenterWidget:ResetPosition() end
        end } },
    })
    rows[#rows + 1] = rr
    y = y - rh

    ctrl.row = row
    controlsByKey[opt.key] = ctrl
    return rr, startY - y
end

function BuildPage(index)
    EnsureDB()

    for _, row in ipairs(rows or {}) do
        row:Hide()
    end

    currentPageIndex = index or 1
    local page = ns.OptionPages[currentPageIndex]
    if not page then return end
    if ns.TopCenterWidget then ns.TopCenterWidget:SetConfigPageActive(page.key == "topCenterWidget") end
    EnsureInfoBarForPage(page)
    if pageTitle then SetUIText(pageTitle, OptName(page)) end

    local cache = pageCache[currentPageIndex]
    if cache then
        rows = cache.rows or {}
        controlsByKey = cache.controls or {}
        for _, row in ipairs(rows) do
            row:Show()
        end
        if content then content:SetHeight(cache.height or 452) end
        if scrollPage then scrollPage:SetContentHeight(cache.height or 452) end
    else
        rows = {}
        controlsByKey = {}

        local y = -8
        if USE_QFX then
            -- One stable owner per page: BeginPage only drops THIS page's old
            -- callbacks, so building another page no longer silently unregisters
            -- every earlier page's refresh callbacks.
            local owner = pageOwners[currentPageIndex] or {}
            pageOwners[currentPageIndex] = owner
            W:BeginPage(owner)
            W:ResetRows(content)
        end
        for _, opt in ipairs(page.options or {}) do
            local used = 0
            local t = opt.type
            if t == "header" then
                _, used = CreateHeaderQFX(content, y, opt)
            elseif t == "checkbox" then
                _, used = CreateCheckboxQFX(content, y, opt)
            elseif t == "slider" then
                _, used = CreateSliderQFX(content, y, opt)
            elseif t == "dropdown" then
                _, used = CreateDropdownQFX(content, y, opt)
            elseif t == "iconStyle" then
                _, used = CreateIconStyleQFX(content, y, opt)
            elseif t == "color" then
                _, used = CreateColorQFX(content, y, opt)
            elseif t == "buttonOrder" then
                _, used = CreateButtonOrderQFX(content, y, opt)
            elseif t == "position" then
                _, used = CreatePositionQFX(content, y, opt)
            elseif t == "topCenterWidgetPosition" then
                _, used = CreateTopCenterWidgetPositionQFX(content, y, opt)
            elseif t == "infoBarContent" then
                _, used = CreateInfoBarContentQFX(content, y, opt)
            elseif t == "infoBarPosition" then
                _, used = CreatePositionQFX(content, y, opt)
            end
            y = y - (used or 0)
        end
        if USE_QFX then W:EndPage() end

        local contentHeight = math.max(452, -y + 24)
        content:SetHeight(contentHeight)
        if scrollPage then scrollPage:SetContentHeight(contentHeight) end
        pageCache[currentPageIndex] = {
            rows = rows,
            controls = controlsByKey,
            height = contentHeight,
        }
    end

    if scrollPage then scrollPage:ScrollTo(0) end

    RefreshNavigationState(page)

    RefreshAllControls()
    if statusText then SetUIText(statusText, "Changes apply immediately") end
end

local function ResetOneOption(opt)
    local db = EnsureDB()
    if opt.type == "header" then return end
    if opt.key == "language" then return end
    if opt.type == "buttonOrder" then
        db.customMicroMenuButtonOrder = ns.GetDefaultMicroMenuButtonOrder and ns.GetDefaultMicroMenuButtonOrder() or CopyTable(ns.defaults.customMicroMenuButtonOrder)
        for _, item in ipairs(ns.ButtonList or {}) do db[item.var] = ns.defaults[item.var] ~= false end
        if ns.OnMicroMenuChanged then ns.OnMicroMenuChanged() end
    elseif opt.type == "position" then
        db.customMicroMenuUnlocked = false
        db.customMicroMenuPositionX = opt.defaultX or 0
        db.customMicroMenuPositionY = opt.defaultY or 0
        if ns.SetMicroMenuUnlocked then ns.SetMicroMenuUnlocked(false) end
        if ns.OnMicroMenuPositionChanged then ns.OnMicroMenuPositionChanged() end
    elseif opt.type == "topCenterWidgetPosition" then
        if ns.TopCenterWidget then
            ns.TopCenterWidget:SetLocked(true)
            ns.TopCenterWidget:ResetPosition()
        end
    elseif opt.type == "infoBarContent" then
        if ns.ResetInfoBarContent then ns.ResetInfoBarContent(opt.slotKey) end
    elseif opt.type == "infoBarPosition" then
        if ns.ResetInfoBarPosition then ns.ResetInfoBarPosition(opt.slotKey) end
    elseif opt.key and opt.default ~= nil then
        local defaultValue = CopyValue(opt.default)
        db[opt.key] = defaultValue
        if opt.key ~= "language" and opt.onChange then opt.onChange(nil, defaultValue) end
    end
end

local function ResetOptions(optList)
    for _, opt in ipairs(optList or {}) do ResetOneOption(opt) end
    if InvalidatePage then InvalidatePage(currentPageIndex) end
    BuildPage(currentPageIndex)
    if statusText then SetUIText(statusText, "Current page defaults restored") end
end

local function ResetAllOptions()
    for _, page in ipairs(ns.OptionPages or {}) do
        for _, opt in ipairs(page.options or {}) do ResetOneOption(opt) end
    end
    if InvalidateAllPages then InvalidateAllPages() end
    BuildPage(currentPageIndex)
    if statusText then SetUIText(statusText, "All defaults restored") end
end

-- Factory-styled chrome button (falls back to the legacy template without
-- QFXWidgets). Returns a button with SetText/GetText/SetActive.
local function CreateChromeButton(parent, opts)
    opts = opts or {}
    local S = W:Tokens()
    local b = CreateFrame("Button", nil, parent)
    local bg = W.Surface(b, "BACKGROUND", 0, S.controlBg)
    bg:SetAllPoints()
    local brd = W.Border(b, b:GetFrameLevel(), S.border, 1, 1)
    local lbl = W.Font(b, opts.size or S.textSize, S.text[1], S.text[2], S.text[3], S.text[4] or 1)
    lbl:SetPoint("CENTER", b, "CENTER", opts.textX or 0, 0)
    if lbl.SetWordWrap then lbl:SetWordWrap(false) end
    if lbl.SetMaxLines then lbl:SetMaxLines(1) end
    b._bg, b._brd, b._lbl = bg, brd, lbl
    function b:SetText(t)
        lbl:SetText(t or "")
    end
    function b:GetText()
        return lbl:GetText()
    end
    function b:SetActive(on)
        b._active = on and true or false
        -- same muted blue as the factory selection (full accent was too bright)
        local c = (on and (S.selectedFill or S.accent) or S.controlBg)
        bg:SetColorTexture(c[1], c[2], c[3], c[4] or 1)
        brd._setBorder(on and (S.borderHi or S.border) or S.border)
        if on then
            lbl:SetTextColor(1, 1, 1, 1)
        else
            lbl:SetTextColor(S.text[1], S.text[2], S.text[3], S.text[4] or 1)
        end
    end
    b:SetScript("OnEnter", function()
        if not b._active then
            bg:SetColorTexture(S.controlBgHi[1], S.controlBgHi[2], S.controlBgHi[3], S.controlBgHi[4] or 1)
            brd._setBorder(S.borderHi or S.border)
        end
    end)
    b:SetScript("OnLeave", function()
        if b._active then
            b:SetActive(true)
        else
            bg:SetColorTexture(S.controlBg[1], S.controlBg[2], S.controlBg[3], S.controlBg[4] or 1)
            brd._setBorder(S.border)
        end
    end)
    return b
end

local function CreateMainFrame()
    if frame then return frame end

    frame = CreateFrame("Frame", "QFXSystemBarConfigFrame", UIParent, "BackdropTemplate")
    frame:SetSize(PANEL_W, PANEL_H)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    W:SkinFrame(frame)
    frame:SetClampedToScreen(true)
    frame:Hide()
    frame:SetScript("OnHide", function()
        if ns.TopCenterWidget then ns.TopCenterWidget:OnConfigClosed() end
    end)

    -- Independent from the Blizzard options panel by default: ESC closes the
    -- options panel only, this window closes through its own X button. (A
    -- UISpecialFrames entry would make one ESC press close BOTH, because
    -- CloseSpecialWindows() hides every listed frame at once.) Opt in with
    -- ns.closeOnEscape = true if ESC should close this window too.
    if ns.closeOnEscape then
        table.insert(UISpecialFrames, "QFXSystemBarConfigFrame")
    end

    local close = CreateChromeButton(frame, { size = 14 })
    close:SetSize(22, 22)
    close:SetPoint("TOPRIGHT", -10, -10)
    close:SetText("×")
    close:SetScript("OnClick", function() ns.CloseConfigFrame() end)
    function close:SetActive() end -- never highlighted

    local icon = frame:CreateTexture(nil, "ARTWORK")
    icon:SetSize(34, 34)
    icon:SetPoint("TOPLEFT", 24, -18)
    icon:SetTexture("Interface\\AddOns\\QFXSystemBar\\Media\\Icon.tga")

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    rootTitle = title
    title:SetPoint("TOPLEFT", icon, "TOPRIGHT", 10, -1)
    SetUIText(title, "QFXSystemBar")

    local sub = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    rootSubtitle = sub
    sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -5)
    SetUIText(sub, "Lightweight system bar popup settings UI")

    local iconCredit = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    rootIconCredit = iconCredit
    iconCredit:SetPoint("TOPLEFT", sub, "BOTTOMLEFT", 0, -3)
    SetUIText(iconCredit, "Some icons are from ElvUI WindTools GameBar.")

    local left = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    left:SetPoint("TOPLEFT", 22, -72)
    left:SetSize(LEFT_W, 456)
    W:SkinFrame(left)

    local right = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    right:SetPoint("TOPLEFT", left, "TOPRIGHT", 12, 0)
    right:SetSize(RIGHT_W, 456)
    W:SkinFrame(right)

    do
        local S = W:Tokens()
        title:SetTextColor(S.sectionText[1], S.sectionText[2], S.sectionText[3], 1)
        local mc = S.textMuted
        sub:SetTextColor(mc[1], mc[2], mc[3], 1)
        iconCredit:SetTextColor(mc[1], mc[2], mc[3], 1)
    end

    pageTitle = right:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    pageTitle:SetPoint("TOPLEFT", 16, -14)
    pageTitle:SetText("")
    do
        local S = W:Tokens()
        pageTitle:SetTextColor(S.text[1], S.text[2], S.text[3], 1)
    end

    subTabAnchor = CreateFrame("Frame", nil, right)
    subTabAnchor:SetPoint("TOPLEFT", 16, -42)
    subTabAnchor:SetSize(RIGHT_W - 48, 28)

    scrollPage = W:ScrollPage(right, {
        width = RIGHT_W - 46, height = 366,
        point = "TOPLEFT", relPoint = "TOPLEFT", x = 16, y = -78,
        reserveBar = true,
    })
    content = scrollPage.content

    for i, group in ipairs(ns.OptionGroups or {}) do
        local b = CreateChromeButton(left, { size = 13 })
        b:SetSize(138, 30)
        b:SetPoint("TOP", 0, -14 - (i - 1) * 36)
        SetUIText(b, OptName(group))
        b:SetScript("OnClick", function() SelectGroup(i) end)
        navButtons[i] = b
    end

    creditTitle = left:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    creditTitle:SetPoint("BOTTOMLEFT", left, "BOTTOMLEFT", 14, 62)
    creditTitle:SetPoint("RIGHT", left, "RIGHT", -14, 0)
    creditTitle:SetJustifyH("LEFT")
    SetUIText(creditTitle, "Credits:")

    creditNames = left:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    creditNames:SetPoint("TOPLEFT", creditTitle, "BOTTOMLEFT", 0, -5)
    creditNames:SetPoint("RIGHT", left, "RIGHT", -14, 0)
    creditNames:SetJustifyH("LEFT")
    creditNames:SetWidth(LEFT_W - 28)
    if creditNames.SetSpacing then creditNames:SetSpacing(2) end
    SetUIText(creditNames, "Credit Author Names")
    creditNames:SetTextColor(0.25, 0.55, 1.00)

    local resetPage = CreateChromeButton(frame, { size = 13 })
    resetPageButton = resetPage
    resetPage:SetSize(132, 26)
    resetPage:SetPoint("BOTTOMLEFT", 24, 24)
    SetUIText(resetPage, "Reset Page")
    resetPage:SetScript("OnClick", function()
        local page = ns.OptionPages[currentPageIndex]
        ResetOptions(page and page.options)
    end)

    local resetAll = CreateChromeButton(frame, { size = 13 })
    resetAllButton = resetAll
    resetAll:SetSize(126, 26)
    resetAll:SetPoint("LEFT", resetPage, "RIGHT", 8, 0)
    SetUIText(resetAll, "Reset All")
    resetAll:SetScript("OnClick", ResetAllOptions)

    statusText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    statusText:SetPoint("BOTTOMLEFT", resetAll, "RIGHT", 14, 7)
    statusText:SetPoint("RIGHT", frame, "RIGHT", -28, 0)
    statusText:SetJustifyH("LEFT")
    SetUIText(statusText, "Changes apply immediately")
    do
        local S = W:Tokens()
        statusText:SetTextColor(S.textMuted[1], S.textMuted[2], S.textMuted[3], 1)
        creditTitle:SetTextColor(S.textMuted[1], S.textMuted[2], S.textMuted[3], 1)
        creditNames:SetTextColor(S.accent[1], S.accent[2], S.accent[3], 1)
    end

    -- The callers (OpenConfigFrame / ToggleConfigFrame) build the page they are
    -- about to show, so building page 1 here would build twice on first open.
    return frame
end

local function RefreshStaticFrameText()
    if rootTitle then SetUIText(rootTitle, "QFXSystemBar") end
    if rootSubtitle then SetUIText(rootSubtitle, "Lightweight system bar popup settings UI") end
    if rootIconCredit then SetUIText(rootIconCredit, "Some icons are from ElvUI WindTools GameBar.") end
    if creditTitle then SetUIText(creditTitle, "Credits:") end
    if creditNames then SetUIText(creditNames, "Credit Author Names") end
    if resetPageButton then SetUIText(resetPageButton, "Reset Page") end
    if resetAllButton then SetUIText(resetAllButton, "Reset All") end
    if statusText then SetUIText(statusText, "Changes apply immediately") end
end

function ns.RefreshConfigLocalization()
    if ns.ApplyLocale then ns.ApplyLocale((QFXSystemBarDB and QFXSystemBarDB.language) or "auto") end
    if ns.RefreshRegisteredUIText then ns.RefreshRegisteredUIText() end
    if frame then
        RefreshStaticFrameText()
        -- Factory rows bake their translated labels at build time, so the cached
        -- pages and sub-tab strips must be dropped; BuildPage re-creates them in
        -- the new locale instead of re-showing stale English/old-locale text.
        if InvalidateAllPages then InvalidateAllPages() end
        for gi in pairs(subTabOwners) do W:ClearRefreshes(subTabOwners[gi]) end
        for _, strip in pairs(subTabStrips) do strip:Hide() end
        subTabStrips = {}
        BuildPage(currentPageIndex or 1)
    end
end

function ns.OpenConfigFrame()
    if not USE_QFX then
        print("|cFF33FF99QFX|r - |cFFEE8800QFXWidgets is missing (QFXSystemBar_Config\\QFXWidgets.lua). Please reinstall the addon.|r")
        return
    end
    local f = CreateMainFrame()
    BuildPage(currentPageIndex or 1)
    f:Show()
end

-- Open the config on a specific page (page key or index) - deep links.
function ns.SelectConfigPage(keyOrIndex)
    local idx = type(keyOrIndex) == "number" and keyOrIndex or GetPageIndexByKey(keyOrIndex)
    if not idx or not (ns.OptionPages and ns.OptionPages[idx]) then return false end
    if not USE_QFX then
        ns.OpenConfigFrame() -- prints the missing-factory message and returns
        return false
    end
    ns.OpenConfigFrame()
    BuildPage(idx)
    return true
end

function ns.ToggleConfigFrame()
    if not USE_QFX then
        ns.OpenConfigFrame() -- prints the missing-factory message and returns
        return
    end
    local f = CreateMainFrame()
    if f:IsShown() then
        f:Hide()
    else
        BuildPage(currentPageIndex or 1)
        f:Show()
    end
end

function ns.CloseConfigFrame()
    if frame then frame:Hide() end
end

EventUtil.ContinueOnPlayerLogin(function()
    EnsureDB()
end)
