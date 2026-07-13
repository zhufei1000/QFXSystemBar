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

    buttonHeader = "Toggle visibility and use the up/down arrows to adjust button order on the system bar.",
    customMicroMenuButtonOrder = "Checked buttons are shown on the system bar. Use the arrows on the right to adjust order.",
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
-- QFXSystemBar popup UI
-- Independent plugin window, compact native-looking controls, English-first
-- layout width, English tooltips, cached pages, and immediate lightweight
-- refresh callbacks.
-- ========================================================================
local controlsByKey = {}
local navButtons = {}
local subNavButtons = {}
local rows = {}
local pageCache = {}
local currentPageIndex = 1
local currentGroupIndex = 1
local suppressChange = false
local dropdownFrame
local frame
local scrollFrame
local subTabFrame
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
local sliderSerial = 0
local BuildPage
local InvalidatePage
local InvalidateAllPages
local OpenColorPicker

local PANEL_W, PANEL_H = 840, 610
local LEFT_W = 170
local RIGHT_W = 610
local CONTENT_W = 572

local BACKDROP = {
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileSize = 32,
    edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 },
}

local PANEL_BACKDROP = {
    bgFile = "Interface\\FrameGeneral\\UI-Background-Rock",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 14,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
}

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

local function EnsureDB()
    QFXSystemBarDB = QFXSystemBarDB or {}
    if ns.ApplyLocale then ns.ApplyLocale(QFXSystemBarDB.language) end
    if ns.MigrateLocalizedSavedVariables then ns.MigrateLocalizedSavedVariables(QFXSystemBarDB) end
    if ns.MigrateBadgeDisplaySettings then ns.MigrateBadgeDisplaySettings(QFXSystemBarDB) end
    MergeDefaults(QFXSystemBarDB, ns.defaults)
    if ns.MigrateLocalizedSavedVariables then ns.MigrateLocalizedSavedVariables(QFXSystemBarDB) end
    return QFXSystemBarDB
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
    if suppressChange then return end
    if opt and opt.onChange then opt.onChange(nil, value) end
    if statusText then SetUIText(statusText, "Settings applied") end
end

local function FormatValue(value, step)
    if type(value) ~= "number" then return tostring(value or "") end
    if step and step < 1 then return string.format("%.1f", value) end
    return string.format("%d", value)
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

local function GetEntryText(opt, value)
    if opt and opt.key and (opt.key == "customMicroMenuHearthstoneLeft" or opt.key == "customMicroMenuHearthstoneMiddle" or opt.key == "customMicroMenuHearthstoneRight") then
        if ns and ns.GetHearthstoneActionName then
            return ns.GetHearthstoneActionName(value)
        end
    end
    for _, item in ipairs(NormalizeEntries(opt)) do
        if item.value == value then return T(item.textKey or item.text or tostring(value)) end
    end
    return tostring(value or "")
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

local function SetTextColor(fs, r, g, b)
    if fs and fs.SetTextColor then fs:SetTextColor(r, g, b) end
end

local function SetDropdownButtonVisual(button, state)
    if not button then return end
    -- Selected state is shown by the native check box.  The row highlight is
    -- only for mouse hover so the dropdown keeps a Blizzard-native feel.
    if state == "selected" then
        SetTextColor(button.text, 1.0, 0.82, 0.10)
        if button.bg then button.bg:SetAlpha(0) end
    elseif state == "hover" then
        SetTextColor(button.text, 1.0, 1.0, 1.0)
        if button.bg then button.bg:SetAlpha(0.20) end
    else
        SetTextColor(button.text, 0.92, 0.92, 0.92)
        if button.bg then button.bg:SetAlpha(0) end
    end
end

local function SetButtonEnabled(button, enabled)
    if not button then return end
    if button.SetEnabled then button:SetEnabled(enabled) end
    button:SetAlpha(enabled and 1 or 0.45)
end

local function SetControlEnabled(ctrl, enabled)
    if not ctrl or not ctrl.row then return end
    ctrl.enabled = enabled
    ctrl.row:SetAlpha(enabled and 1 or 0.38)
    if ctrl.checkbox then ctrl.checkbox:SetEnabled(enabled) end
    if ctrl.slider then
        if enabled and ctrl.slider.Enable then ctrl.slider:Enable() elseif ctrl.slider.Disable then ctrl.slider:Disable() end
    end
    if ctrl.button then SetButtonEnabled(ctrl.button, enabled) end
    if ctrl.swatchButton then SetButtonEnabled(ctrl.swatchButton, enabled) end
    if ctrl.children then
        for _, child in ipairs(ctrl.children) do
            local childEnabled = enabled and not child.qfxBoundaryDisabled and not child.qfxInfoBarLimitDisabled
            if child.SetEnabled then child:SetEnabled(childEnabled) end
            if child.EnableMouse then child:EnableMouse(childEnabled) end
            child:SetAlpha(childEnabled and 1 or 0.45)
        end
    end
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

local function RefreshControl(ctrl)
    if not ctrl or not ctrl.opt then return end
    local db = EnsureDB()
    local opt = ctrl.opt
    local value = db[opt.key]
    suppressChange = true

    if ctrl.topCenterWidgetPosition then
        local module = ns.TopCenterWidget
        if ctrl.lockCheckbox then
            if module then
                ctrl.lockCheckbox:SetChecked(module:IsLocked())
            else
                ctrl.lockCheckbox:SetChecked(true)
            end
        end
        if module then module:RefreshCoordinateText(ctrl.coordinateText) end
    elseif ctrl.checkbox then
        ctrl.checkbox:SetChecked(value and true or false)
    elseif ctrl.slider then
        local v = value
        if v == nil then v = opt.default or opt.min or 0 end
        ctrl.slider:SetValue(v)
        local txt = FormatValue(v, opt.step)
        if ctrl.valueText then ctrl.valueText:SetText(txt) end
        if ctrl.currentText then ctrl.currentText:SetText(txt) end
    elseif ctrl.dropdownButton then
        if opt.multiSelect then
            ctrl.dropdownButton:SetText(GetMultiEntryText(opt, value))
        else
            ctrl.dropdownButton:SetText(GetEntryText(opt, value))
        end
    elseif ctrl.iconStyleButtons then
        local selected = value or opt.default or "original"
        for _, b in ipairs(ctrl.iconStyleButtons) do
            local isSelected = b.qfxValue == selected
            SetUIText(b, b.qfxTextKey or b.qfxText or "", isSelected and "✓ " or "")
            b:SetNormalFontObject(isSelected and "GameFontNormal" or "GameFontHighlight")
            b:SetHighlightFontObject("GameFontNormal")
        end
    elseif ctrl.infoBarContent then
        local slot = opt and opt.slotKey and ns.InfoBarSlots and ns.InfoBarSlots[opt.slotKey]
        if slot and ctrl.infoBarItems then
            local enabledItems = db[slot.enabledKey]
            if type(enabledItems) ~= "table" then enabledItems = {} end
            local count = ns.GetInfoBarEnabledCount and ns.GetInfoBarEnabledCount(opt.slotKey) or 0
            local maxItems = ns.InfoBarMaxItems or 5
            if ctrl.limitText then ctrl.limitText:SetText(UIFormat("Shown: %d/%d. The bar is divided equally by the number of shown items.", count, maxItems)) end
            for _, itemCtrl in ipairs(ctrl.infoBarItems) do
                local checked = enabledItems[itemCtrl.id] == true
                if itemCtrl.checkbox then
                    itemCtrl.checkbox:SetChecked(checked)
                    itemCtrl.checkbox.qfxInfoBarLimitDisabled = (not checked and count >= maxItems) and true or false
                end
            end
        end
    elseif ctrl.positionText then
        if opt.type == "infoBarPosition" and opt.slotKey and ns.InfoBarSlots and ns.InfoBarSlots[opt.slotKey] then
            local slot = ns.InfoBarSlots[opt.slotKey]
            ctrl.positionText:SetText(UIFormat("Current Position: X %d, Y %d", db[slot.xKey] or slot.defaultX or 0, db[slot.yKey] or slot.defaultY or 0))
            if ctrl.unlockCheckbox then ctrl.unlockCheckbox:SetChecked(db[slot.unlockedKey] and true or false) end
        else
            ctrl.positionText:SetText(UIFormat("Current Position: X %d, Y %d", db.customMicroMenuPositionX or 0, db.customMicroMenuPositionY or 0))
            if ctrl.unlockCheckbox then ctrl.unlockCheckbox:SetChecked(db.customMicroMenuUnlocked and true or false) end
        end
    end

    if ctrl.swatch then
        local colorKey = ctrl.colorKey or opt.key
        local defaultColor = ctrl.colorDefault or opt.default
        local r, g, b = HexToRGB(db[colorKey] or defaultColor)
        ctrl.swatch:SetColorTexture(r, g, b, 1)
    end

    suppressChange = false
end

local function RefreshAllControls()
    for _, ctrl in pairs(controlsByKey) do RefreshControl(ctrl) end
    RefreshDependencies()
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

local function CreateDivider(parent)
    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetTexture("Interface\\Common\\UI-TooltipDivider-Transparent")
    line:SetHeight(8)
    line:SetPoint("BOTTOMLEFT", 0, -3)
    line:SetPoint("BOTTOMRIGHT", -16, -3)
    return line
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

local function CreateHeader(parent, y, opt)
    local row = CreateRow(parent, y, 42, opt)
    local text = row:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    text:SetPoint("TOPLEFT", 4, -3)
    SetUIText(text, OptName(opt))
    text:SetJustifyH("LEFT")
    local desc = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    desc:SetPoint("TOPLEFT", text, "BOTTOMLEFT", 0, -3)
    desc:SetPoint("RIGHT", -18, 0)
    desc:SetJustifyH("LEFT")
    desc:SetTextColor(0.78, 0.78, 0.78)
    SetUIText(desc, OptTooltip(opt))
    CreateDivider(row)
    return row, 48
end

local function CreateCheckbox(parent, y, opt)
    local row = CreateRow(parent, y, 38, opt, true)
    local cb = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
    cb:SetSize(24, 24)
    cb:SetPoint("LEFT", 10, 0)

    local label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    label:SetPoint("LEFT", cb, "RIGHT", 6, 0)
    label:SetPoint("RIGHT", row, "RIGHT", opt.colorKey and -54 or -16, 0)
    label:SetJustifyH("LEFT")
    SetUIText(label, OptName(opt))

    cb:SetScript("OnClick", function(self)
        SetOptionValue(opt, self:GetChecked() and true or false)
    end)
    SetTooltip(cb, OptName(opt), OptTooltip(opt))

    local children = { cb }
    local ctrl = { row = row, opt = opt, checkbox = cb, children = children }

    if opt.colorKey then
        local colorOpt = {
            key = opt.colorKey,
            nameKey = opt.colorNameKey or opt.nameKey,
            tooltipKey = opt.colorTooltipKey or opt.tooltipKey,
            default = opt.colorDefault or (ns.defaults and ns.defaults[opt.colorKey]) or "FFFFFFFF",
            onChange = opt.onChange,
        }

        local btn = CreateFrame("Button", nil, row)
        btn:SetSize(30, 24)
        btn:SetPoint("RIGHT", -16, 0)

        local swatch = btn:CreateTexture(nil, "OVERLAY")
        swatch:SetTexture("Interface\\Buttons\\WHITE8x8")
        swatch:SetSize(24, 20)
        swatch:SetPoint("CENTER", btn, "CENTER", 0, 0)

        btn:SetScript("OnEnter", function(self)
            if self.qfxSwatch then self.qfxSwatch:SetAlpha(0.85) end
        end)
        btn:SetScript("OnLeave", function(self)
            if self.qfxSwatch then self.qfxSwatch:SetAlpha(1) end
        end)
        btn.qfxSwatch = swatch
        btn:SetScript("OnClick", function()
            if OpenColorPicker then OpenColorPicker(colorOpt) end
        end)
        SetTooltip(btn, colorOpt.nameKey, colorOpt.tooltipKey)

        ctrl.swatchButton = btn
        ctrl.button = btn
        ctrl.swatch = swatch
        ctrl.colorKey = opt.colorKey
        ctrl.colorDefault = colorOpt.default
        children[#children + 1] = btn
        controlsByKey[opt.colorKey] = ctrl
    end

    controlsByKey[opt.key] = ctrl
    RefreshControl(ctrl)
    return row, 44
end

local function CreateSlider(parent, y, opt)
    local row = CreateRow(parent, y, 82, opt, true)
    local label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    label:SetPoint("TOPLEFT", 12, -8)
    label:SetPoint("RIGHT", -16, 0)
    label:SetJustifyH("LEFT")
    SetUIText(label, OptName(opt))

    sliderSerial = sliderSerial + 1
    local slider = CreateFrame("Slider", "QFXSystemBarSlider" .. sliderSerial, row, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", 20, -36)
    slider:SetPoint("RIGHT", -26, 0)
    slider:SetMinMaxValues(opt.min or 0, opt.max or 1)
    slider:SetValueStep(opt.step or 1)
    if slider.SetObeyStepOnDrag then slider:SetObeyStepOnDrag(true) end

    _G[slider:GetName() .. "Text"]:SetText("")
    _G[slider:GetName() .. "Low"]:SetText("")
    _G[slider:GetName() .. "High"]:SetText("")

    local minText = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    minText:SetPoint("TOPLEFT", slider, "BOTTOMLEFT", 0, -4)
    minText:SetText(FormatValue(opt.min or 0, opt.step))

    local maxText = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    maxText:SetPoint("TOPRIGHT", slider, "BOTTOMRIGHT", 0, -4)
    maxText:SetText(FormatValue(opt.max or 0, opt.step))

    local currentText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    currentText:SetPoint("TOP", slider, "BOTTOM", 0, -4)
    currentText:SetText("")

    slider:SetScript("OnValueChanged", function(self, value)
        if suppressChange then return end
        local step = opt.step or 1
        if step > 0 then value = math.floor(value / step + 0.5) * step end
        if opt.step and opt.step < 1 then value = tonumber(string.format("%.1f", value)) end
        QFXSystemBarDB[opt.key] = value
        currentText:SetText(FormatValue(value, opt.step))
        ApplyOptionChanged(opt, value)
    end)
    SetTooltip(slider, OptName(opt), OptTooltip(opt))

    local ctrl = { row = row, opt = opt, slider = slider, currentText = currentText, children = { slider } }
    controlsByKey[opt.key] = ctrl
    RefreshControl(ctrl)
    return row, 88
end

local function HideDropdown()
    if dropdownFrame then dropdownFrame:Hide() end
end

local function CreateDropdown(parent, y, opt)
    local row = CreateRow(parent, y, 48, opt, true)
    local label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    label:SetPoint("LEFT", 12, 0)
    label:SetWidth(258)
    label:SetJustifyH("LEFT")
    SetUIText(label, OptName(opt))

    local btn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    btn:SetSize(232, 26)
    btn:SetPoint("RIGHT", -14, 0)
    btn:SetText("")
    SetTooltip(btn, OptName(opt), OptTooltip(opt))

    btn:SetScript("OnClick", function(self)
        local entries = NormalizeEntries(opt)
        if dropdownFrame and dropdownFrame:IsShown() and dropdownFrame.qfxOwner == self then
            HideDropdown()
            return
        end
        if not dropdownFrame then
            dropdownFrame = CreateFrame("Frame", "QFXSystemBarDropdownFrame", frame or UIParent, "BackdropTemplate")
            dropdownFrame:SetFrameStrata("FULLSCREEN_DIALOG")
            dropdownFrame:SetClampedToScreen(true)
            dropdownFrame:SetBackdrop(PANEL_BACKDROP)
            dropdownFrame:SetBackdropColor(0.02, 0.02, 0.02, 0.92)
            dropdownFrame:SetBackdropBorderColor(0.78, 0.78, 0.78, 0.90)
            dropdownFrame.buttons = {}

            dropdownFrame.scrollFrame = CreateFrame("ScrollFrame", "QFXSystemBarDropdownScrollFrame", dropdownFrame, "UIPanelScrollFrameTemplate")
            dropdownFrame.scrollFrame:EnableMouseWheel(true)

            dropdownFrame.scrollChild = CreateFrame("Frame", nil, dropdownFrame.scrollFrame)
            dropdownFrame.scrollFrame:SetScrollChild(dropdownFrame.scrollChild)

            dropdownFrame:SetScript("OnHide", function(self)
                self.qfxOwner = nil
                if self.scrollFrame then self.scrollFrame:SetVerticalScroll(0) end
            end)
        elseif frame and dropdownFrame:GetParent() ~= frame then
            dropdownFrame:SetParent(frame)
        end

        dropdownFrame.qfxOwner = self
        dropdownFrame.qfxOpt = opt
        dropdownFrame:ClearAllPoints()
        dropdownFrame:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -2)

        local rowHeight = 26
        local maxVisibleRows = tonumber(opt.maxVisibleRows or opt.visibleRows or opt.maxRows or #entries) or #entries
        if maxVisibleRows < 1 then maxVisibleRows = #entries end
        local visibleRows = math.min(#entries, maxVisibleRows)
        local hasScroll = #entries > visibleRows
        local listHeight = math.max(28, visibleRows * rowHeight + 8)
        local contentHeight = math.max(1, #entries * rowHeight)
        local scrollRightInset = hasScroll and 24 or 4
        local contentWidth = math.max(1, self:GetWidth() - scrollRightInset - 4)

        dropdownFrame:SetSize(self:GetWidth(), listHeight)
        dropdownFrame.scrollFrame:ClearAllPoints()
        dropdownFrame.scrollFrame:SetPoint("TOPLEFT", dropdownFrame, "TOPLEFT", 4, -4)
        dropdownFrame.scrollFrame:SetPoint("BOTTOMRIGHT", dropdownFrame, "BOTTOMRIGHT", -scrollRightInset, 4)
        dropdownFrame.scrollChild:SetSize(contentWidth, contentHeight)
        dropdownFrame.scrollFrame:SetVerticalScroll(0)

        local scrollBar = dropdownFrame.scrollFrame.ScrollBar or _G["QFXSystemBarDropdownScrollFrameScrollBar"]
        local maxScroll = math.max(0, contentHeight - math.max(1, visibleRows * rowHeight))
        if scrollBar then
            if scrollBar.SetMinMaxValues then scrollBar:SetMinMaxValues(0, maxScroll) end
            if scrollBar.SetValueStep then scrollBar:SetValueStep(rowHeight) end
            if scrollBar.SetStepsPerPage then scrollBar:SetStepsPerPage(visibleRows > 1 and (visibleRows - 1) or 1) end
            if scrollBar.SetValue then scrollBar:SetValue(0) end
            if hasScroll then scrollBar:Show() else scrollBar:Hide() end
        end
        dropdownFrame.scrollFrame:SetScript("OnMouseWheel", function(scrollFrame, delta)
            if not hasScroll then return end
            local current = scrollFrame:GetVerticalScroll() or 0
            local nextValue = current - (delta or 0) * rowHeight
            if nextValue < 0 then nextValue = 0 elseif nextValue > maxScroll then nextValue = maxScroll end
            scrollFrame:SetVerticalScroll(nextValue)
            if scrollBar and scrollBar.SetValue then scrollBar:SetValue(nextValue) end
        end)
        if scrollBar and scrollBar.SetScript then
            scrollBar:SetScript("OnValueChanged", function(bar, value)
                if dropdownFrame and dropdownFrame.scrollFrame then
                    dropdownFrame.scrollFrame:SetVerticalScroll(value or 0)
                end
            end)
        end

        local db = EnsureDB()
        local currentValue = db[opt.key]
        if opt.multiSelect and type(currentValue) ~= "table" then currentValue = {} end
        for _, b in ipairs(dropdownFrame.buttons) do b:Hide() end
        for i, item in ipairs(entries) do
            local b = dropdownFrame.buttons[i]
            if not b then
                b = CreateFrame("Button", nil, dropdownFrame.scrollChild)
                b:SetHeight(24)
                b:SetPoint("LEFT", 0, 0)
                b:SetPoint("RIGHT", 0, 0)
                b.bg = b:CreateTexture(nil, "BACKGROUND")
                b.bg:SetTexture("Interface\\Buttons\\WHITE8x8")
                b.bg:SetAllPoints()
                b.bg:SetColorTexture(0.90, 0.58, 0.10, 1)
                b.bg:SetAlpha(0)

                b.check = CreateFrame("CheckButton", nil, b, "UICheckButtonTemplate")
                b.check:SetSize(22, 22)
                b.check:SetPoint("LEFT", 0, 0)
                b.check:EnableMouse(false)

                b.text = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                b.text:SetPoint("LEFT", b.check, "RIGHT", 2, 0)
                b.text:SetPoint("RIGHT", -8, 0)
                b.text:SetJustifyH("LEFT")
                b:SetScript("OnEnter", function(button)
                    SetDropdownButtonVisual(button, "hover")
                end)
                b:SetScript("OnLeave", function(button)
                    if button.qfxSelected then
                        SetDropdownButtonVisual(button, "selected")
                    else
                        SetDropdownButtonVisual(button, "normal")
                    end
                end)
                dropdownFrame.buttons[i] = b
            end
            b:SetParent(dropdownFrame.scrollChild)
            b:ClearAllPoints()
            b:SetPoint("TOPLEFT", dropdownFrame.scrollChild, "TOPLEFT", 0, -((i - 1) * rowHeight))
            b:SetPoint("TOPRIGHT", dropdownFrame.scrollChild, "TOPRIGHT", 0, -((i - 1) * rowHeight))
            b:SetHeight(24)
            b.value = item.value
            b.qfxSelected = opt.multiSelect and (type(currentValue) == "table" and currentValue[item.value] and true or false) or (item.value == currentValue)
            if b.check then b.check:SetChecked(b.qfxSelected) end
            SetUIText(b.text, item.textKey or item.text or tostring(item.value or ""))
            SetDropdownButtonVisual(b, b.qfxSelected and "selected" or "normal")
            b:SetScript("OnClick", function(button)
                if opt.multiSelect then
                    local dbNow = EnsureDB()
                    local values = CopyValue(type(dbNow[opt.key]) == "table" and dbNow[opt.key] or opt.default or {}) or {}
                    values[button.value] = values[button.value] and nil or true
                    dbNow[opt.key] = values
                    ApplyOptionChanged(opt, values)
                    RefreshAllControls()
                    if dropdownFrame and dropdownFrame:IsShown() then
                        for _, listButton in ipairs(dropdownFrame.buttons or {}) do
                            if listButton:IsShown() then
                                listButton.qfxSelected = values[listButton.value] and true or false
                                if listButton.check then listButton.check:SetChecked(listButton.qfxSelected) end
                                SetDropdownButtonVisual(listButton, listButton.qfxSelected and "selected" or "normal")
                            end
                        end
                    end
                else
                    HideDropdown()
                    SetOptionValue(opt, button.value)
                end
            end)
            b:Show()
        end
        dropdownFrame:Show()
    end)

    local ctrl = { row = row, opt = opt, dropdownButton = btn, button = btn, children = { btn } }
    controlsByKey[opt.key] = ctrl
    RefreshControl(ctrl)
    return row, 54
end

local function CreateIconStyleSelector(parent, y, opt)
    local entries = NormalizeEntries(opt)
    local row = CreateRow(parent, y, 104, opt, true)
    local children = {}

    local title = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", 12, -10)
    SetUIText(title, OptName(opt))

    local hint = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    hint:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
    hint:SetPoint("RIGHT", -16, 0)
    hint:SetJustifyH("LEFT")
    hint:SetTextColor(0.78, 0.78, 0.78)
    SetUIText(hint, OptTooltip(opt))

    local buttons = {}
    local buttonW, buttonH, gap = 128, 26, 8
    for i, item in ipairs(entries) do
        local b = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        b:SetSize(buttonW, buttonH)
        b:SetPoint("TOPLEFT", 12 + (i - 1) * (buttonW + gap), -64)
        b.qfxValue = item.value
        b.qfxTextKey = item.textKey or item.text or tostring(item.value or "")
        b:SetScript("OnClick", function(button)
            SetOptionValue(opt, button.qfxValue)
        end)
        SetTooltip(b, OptName(opt), OptTooltip(opt))
        buttons[#buttons + 1] = b
        children[#children + 1] = b
    end

    local ctrl = { row = row, opt = opt, iconStyleButtons = buttons, children = children }
    controlsByKey[opt.key] = ctrl
    RefreshControl(ctrl)
    return row, 110
end

OpenColorPicker = function(opt)
    local db = EnsureDB()
    local r, g, b = HexToRGB(db[opt.key] or opt.default)
    local function commit(nr, ng, nb)
        SetOptionValue(opt, RGBToHex(nr, ng, nb))
    end

    if ColorPickerFrame and ColorPickerFrame.SetupColorPickerAndShow then
        ColorPickerFrame:SetupColorPickerAndShow({
            r = r, g = g, b = b,
            swatchFunc = function()
                local nr, ng, nb = ColorPickerFrame:GetColorRGB()
                commit(nr, ng, nb)
            end,
            cancelFunc = function(previousValues)
                if previousValues then commit(previousValues.r, previousValues.g, previousValues.b) end
            end,
        })
    else
        ColorPickerFrame.previousValues = { r = r, g = g, b = b }
        ColorPickerFrame.hasOpacity = false
        ColorPickerFrame.func = function()
            local nr, ng, nb = ColorPickerFrame:GetColorRGB()
            commit(nr, ng, nb)
        end
        ColorPickerFrame.cancelFunc = function(previousValues)
            if previousValues then commit(previousValues.r, previousValues.g, previousValues.b) end
        end
        ColorPickerFrame:SetColorRGB(r, g, b)
        ColorPickerFrame:Hide()
        ColorPickerFrame:Show()
    end
end

local function CreateColor(parent, y, opt)
    local row = CreateRow(parent, y, 48, opt, true)
    local label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    label:SetPoint("LEFT", 12, 0)
    label:SetWidth(270)
    label:SetJustifyH("LEFT")
    SetUIText(label, OptName(opt))

    -- Compact color swatch button.  Keep the click area, but show only the
    -- selected color itself: no native button background and no extra border.
    local btn = CreateFrame("Button", nil, row)
    btn:SetSize(30, 24)
    btn:SetPoint("RIGHT", -16, 0)

    local swatch = btn:CreateTexture(nil, "OVERLAY")
    swatch:SetTexture("Interface\\Buttons\\WHITE8x8")
    swatch:SetSize(24, 20)
    swatch:SetPoint("CENTER", btn, "CENTER", 0, 0)

    btn:SetScript("OnEnter", function(self)
        if self.qfxSwatch then self.qfxSwatch:SetAlpha(0.85) end
    end)
    btn:SetScript("OnLeave", function(self)
        if self.qfxSwatch then self.qfxSwatch:SetAlpha(1) end
    end)
    btn.qfxSwatch = swatch
    btn:SetScript("OnClick", function() OpenColorPicker(opt) end)
    SetTooltip(btn, OptName(opt), OptTooltip(opt))

    local ctrl = { row = row, opt = opt, button = btn, swatchButton = btn, swatch = swatch, children = { btn } }
    controlsByKey[opt.key] = ctrl
    RefreshControl(ctrl)
    return row, 54
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

local function CreateSmallButton(parent, text, w, h)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetSize(w or 28, h or 24)
    b:SetText(text)
    return b
end

InvalidatePage = function(index)
    index = index or currentPageIndex
    local cache = index and pageCache[index]
    if not cache then return end
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

local function CreateButtonOrder(parent, y, opt)
    local order = GetButtonOrder()
    local count = math.max(#order, #(ns.ButtonList or {}))
    local height = 48 + count * 32
    local row = CreateRow(parent, y, height, opt, true)
    local children = {}

    local title = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", 12, -10)
    SetUIText(title, OptName(opt))

    local hint = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    hint:SetPoint("LEFT", title, "RIGHT", 12, 0)
    hint:SetPoint("RIGHT", -16, 0)
    hint:SetJustifyH("LEFT")
    hint:SetTextColor(0.78, 0.78, 0.78)
    SetUIText(hint, "Check to show. Use ↑ / ↓ to reorder.")

    for i, rawID in ipairs(order) do
        local id = NormalizeButtonID(rawID)
        local item = FindButtonItem(id)
        if item then
            local line = CreateFrame("Frame", nil, row)
            line:SetSize(CONTENT_W - 24, 30)
            line:SetPoint("TOPLEFT", 12, -38 - (i - 1) * 32)
            children[#children + 1] = line

            local cb = CreateFrame("CheckButton", nil, line, "UICheckButtonTemplate")
            cb:SetSize(24, 24)
            cb:SetPoint("LEFT", 0, 0)
            cb:SetChecked(QFXSystemBarDB and QFXSystemBarDB[item.var] == true)
            cb:SetScript("OnClick", function(self)
                local checked = self:GetChecked() and true or false
                local function apply(finalChecked)
                    EnsureDB()[item.var] = finalChecked and true or false
                    if self.SetChecked then self:SetChecked(finalChecked and true or false) end
                    if opt.onChange then opt.onChange() end
                    if statusText then SetUIText(statusText, "Settings applied") end
                end

                if item.id == "MeetingStone" and ns.ConfirmMeetingStoneButtonVisibility then
                    ns.ConfirmMeetingStoneButtonVisibility(checked, self, apply)
                else
                    apply(checked)
                end
            end)
            SetTooltip(cb, GetButtonLabelKey(item), GetButtonTooltipKey(item))
            children[#children + 1] = cb

            local label = line:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            label:SetPoint("LEFT", cb, "RIGHT", 6, 0)
            label:SetPoint("RIGHT", line, "RIGHT", -82, 0)
            label:SetJustifyH("LEFT")
            SetUIText(label, GetButtonLabelKey(item))

            local up = CreateSmallButton(line, "↑", 28, 23)
            up:SetPoint("RIGHT", -36, 0)
            up:SetScript("OnClick", function()
                if ns.MoveMicroMenuButton then ns.MoveMicroMenuButton(id, -1) end
                if InvalidatePage then InvalidatePage(currentPageIndex) end
                BuildPage(currentPageIndex)
                if statusText then SetUIText(statusText, "Button order updated") end
            end)
            SetTooltip(up, GetButtonLabelKey(item), "Move Up")
            up.qfxBoundaryDisabled = i <= 1
            SetButtonEnabled(up, i > 1)
            children[#children + 1] = up

            local down = CreateSmallButton(line, "↓", 28, 23)
            down:SetPoint("RIGHT", 0, 0)
            down:SetScript("OnClick", function()
                if ns.MoveMicroMenuButton then ns.MoveMicroMenuButton(id, 1) end
                if InvalidatePage then InvalidatePage(currentPageIndex) end
                BuildPage(currentPageIndex)
                if statusText then SetUIText(statusText, "Button order updated") end
            end)
            SetTooltip(down, GetButtonLabelKey(item), "Move Down")
            down.qfxBoundaryDisabled = i >= #order
            SetButtonEnabled(down, i < #order)
            children[#children + 1] = down
        end
    end

    local ctrl = { row = row, opt = opt, children = children }
    controlsByKey[opt.key] = ctrl
    return row, height + 8
end

local function Nudge(dx, dy)
    if ns.NudgeMicroMenu then ns.NudgeMicroMenu(dx, dy) end
    RefreshAllControls()
    if statusText then SetUIText(statusText, "Position updated") end
end

local function CreatePosition(parent, y, opt)
    local row = CreateRow(parent, y, 184, opt, true)
    local children = {}

    local title = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", 12, -10)
    SetUIText(title, OptName(opt))

    local desc = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
    desc:SetPoint("RIGHT", -16, 0)
    desc:SetJustifyH("LEFT")
    desc:SetTextColor(0.78, 0.78, 0.78)
    SetUIText(desc, "Unlock to drag the system bar directly. Arrow buttons nudge it by 1 pixel.")

    local cb = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
    cb:SetSize(24, 24)
    cb:SetPoint("TOPLEFT", 12, -62)
    children[#children + 1] = cb

    local cbLabel = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    cbLabel:SetPoint("LEFT", cb, "RIGHT", 6, 0)
    SetUIText(cbLabel, "Unlock Dragging")

    cb:SetScript("OnClick", function(self)
        EnsureDB().customMicroMenuUnlocked = self:GetChecked() and true or false
        if ns.SetMicroMenuUnlocked then ns.SetMicroMenuUnlocked(EnsureDB().customMicroMenuUnlocked) end
        if statusText then SetUIText(statusText, EnsureDB().customMicroMenuUnlocked and "Unlocked. Drag the system bar to move it." or "System bar position locked") end
        RefreshAllControls()
    end)
    SetTooltip(cb, "Unlock Dragging", "Allows moving QFXSystemBar with the mouse.")

    local posText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    posText:SetPoint("TOPLEFT", 14, -96)
    posText:SetText("")

    local left = CreateSmallButton(row, "←", 42, 26)
    left:SetPoint("TOPRIGHT", -154, -62)
    left:SetScript("OnClick", function() Nudge(-1, 0) end)
    children[#children + 1] = left

    local up = CreateSmallButton(row, "↑", 42, 26)
    up:SetPoint("LEFT", left, "RIGHT", 4, 0)
    up:SetScript("OnClick", function() Nudge(0, 1) end)
    children[#children + 1] = up

    local down = CreateSmallButton(row, "↓", 42, 26)
    down:SetPoint("LEFT", up, "RIGHT", 4, 0)
    down:SetScript("OnClick", function() Nudge(0, -1) end)
    children[#children + 1] = down

    local right = CreateSmallButton(row, "→", 42, 26)
    right:SetPoint("LEFT", down, "RIGHT", 4, 0)
    right:SetScript("OnClick", function() Nudge(1, 0) end)
    children[#children + 1] = right

    local reset = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    reset:SetSize(112, 26)
    reset:SetPoint("TOPRIGHT", -16, -134)
    SetUIText(reset, "Reset Position")
    reset:SetScript("OnClick", function()
        if ns.ResetMicroMenuPosition then ns.ResetMicroMenuPosition() end
        RefreshAllControls()
        if statusText then SetUIText(statusText, "Position reset") end
    end)
    children[#children + 1] = reset

    local ctrl = { row = row, opt = opt, positionText = posText, unlockCheckbox = cb, checkbox = nil, children = children }
    controlsByKey[opt.key] = ctrl
    RefreshControl(ctrl)
    return row, 190
end

local function CreateTopCenterWidgetPosition(parent, y, opt)
    local row = CreateRow(parent, y, 120, opt, true)
    local children = {}

    local lock = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
    lock:SetSize(24, 24)
    lock:SetPoint("TOPLEFT", 12, -10)
    children[#children + 1] = lock

    local lockLabel = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    lockLabel:SetPoint("LEFT", lock, "RIGHT", 6, 0)
    SetUIText(lockLabel, "Lock Position")
    lock:SetScript("OnClick", function(self)
        if ns.TopCenterWidget then ns.TopCenterWidget:SetLocked(self:GetChecked() and true or false) end
        RefreshAllControls()
    end)
    SetTooltip(lock, "Lock Position", "Lock Position")

    local coordinates = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    coordinates:SetPoint("TOPLEFT", 14, -52)
    coordinates:SetWidth(160)
    coordinates:SetJustifyH("LEFT")
    coordinates:SetText("X: --  Y: --")

    local function AddNudgeButton(text, tooltipKey, dx, dy, relativeTo)
        local button = CreateSmallButton(row, text, 36, 26)
        if relativeTo then
            button:SetPoint("LEFT", relativeTo, "RIGHT", 4, 0)
        else
            button:SetPoint("TOPLEFT", 190, -42)
        end
        button:SetScript("OnClick", function()
            if ns.TopCenterWidget then ns.TopCenterWidget:Nudge(dx, dy) end
            RefreshAllControls()
        end)
        SetTooltip(button, tooltipKey, tooltipKey)
        children[#children + 1] = button
        return button
    end

    -- Required order: down, up, left, right.
    local down = AddNudgeButton("↓", "Move Down 1", 0, -1)
    local up = AddNudgeButton("↑", "Move Up 1", 0, 1, down)
    local left = AddNudgeButton("←", "Move Left 1", -1, 0, up)
    AddNudgeButton("→", "Move Right 1", 1, 0, left)

    local reset = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    reset:SetSize(112, 26)
    reset:SetPoint("TOPLEFT", 12, -84)
    SetUIText(reset, "Reset Top-Center Position")
    reset:SetScript("OnClick", function()
        if ns.TopCenterWidget then ns.TopCenterWidget:ResetPosition() end
        RefreshAllControls()
    end)
    SetTooltip(reset, "Reset Top-Center Position", "Reset Top-Center Position")
    children[#children + 1] = reset

    local ctrl = {
        row = row,
        opt = opt,
        topCenterWidgetPosition = true,
        lockCheckbox = lock,
        coordinateText = coordinates,
        children = children,
    }
    controlsByKey[opt.key] = ctrl
    RefreshControl(ctrl)
    return row, 126
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
    db[slot.orderKey] = out
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

local function RefreshInfoBarContentRows(ctrl)
    if not ctrl or not ctrl.infoBarContent or not ctrl.infoBarItems then return end
    local opt = ctrl.opt
    local slot = GetInfoBarSlot(opt)
    if not slot then return end

    local order = GetInfoBarOrder(opt)
    local byID = {}
    for _, itemCtrl in ipairs(ctrl.infoBarItems) do
        if itemCtrl and itemCtrl.id then byID[itemCtrl.id] = itemCtrl end
    end

    for i, id in ipairs(order) do
        local itemCtrl = byID[id]
        if itemCtrl and itemCtrl.line then
            itemCtrl.line:ClearAllPoints()
            itemCtrl.line:SetPoint("TOPLEFT", 12, -38 - (i - 1) * 32)
            if itemCtrl.up then
                itemCtrl.up.qfxBoundaryDisabled = i <= 1
                SetButtonEnabled(itemCtrl.up, i > 1)
            end
            if itemCtrl.down then
                itemCtrl.down.qfxBoundaryDisabled = i >= #order
                SetButtonEnabled(itemCtrl.down, i < #order)
            end
        end
    end

    RefreshControl(ctrl)
end

local function CreateInfoBarContent(parent, y, opt)
    local slot = GetInfoBarSlot(opt)
    local order = GetInfoBarOrder(opt)
    local count = #order
    local height = 48 + count * 32
    local row = CreateRow(parent, y, height, opt, true)
    local children = {}
    local itemControls = {}
    local contentCtrl

    local title = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", 12, -10)
    SetUIText(title, OptName(opt))

    local hint = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    hint:SetPoint("LEFT", title, "RIGHT", 12, 0)
    hint:SetPoint("RIGHT", -16, 0)
    hint:SetJustifyH("LEFT")
    hint:SetTextColor(0.78, 0.78, 0.78)
    SetUIText(hint, "Max 5 shown. FPS includes latency without MS. Items are divided equally across the bar.")

    if not slot then
        local ctrl = { row = row, opt = opt, children = children }
        controlsByKey[opt.key] = ctrl
        return row, height + 8
    end

    local db = EnsureDB()
    local enabled = db[slot.enabledKey]
    if type(enabled) ~= "table" then enabled = {}; db[slot.enabledKey] = enabled end

    for i, id in ipairs(order) do
        local line = CreateFrame("Frame", nil, row)
        line:SetSize(CONTENT_W - 24, 30)
        line:SetPoint("TOPLEFT", 12, -38 - (i - 1) * 32)
        children[#children + 1] = line

        local cb = CreateFrame("CheckButton", nil, line, "UICheckButtonTemplate")
        cb:SetSize(24, 24)
        cb:SetPoint("LEFT", 0, 0)
        cb:SetChecked(enabled[id] and true or false)
        cb:SetScript("OnClick", function(self)
            local checked = self:GetChecked() and true or false
            local ok, maxItems
            if ns.SetInfoBarItemEnabled then
                ok, maxItems = ns.SetInfoBarItemEnabled(opt.slotKey, id, checked)
            else
                EnsureDB()[slot.enabledKey][id] = checked
                ok, maxItems = true, 5
            end
            if not ok then
                self:SetChecked(false)
                if UIErrorsFrame and UIErrorsFrame.AddMessage then UIErrorsFrame:AddMessage(UIFormat("One info bar can show up to %d items.", maxItems or 5)) end
                if statusText then statusText:SetText(UIFormat("One info bar can show up to %d items.", maxItems or 5)) end
            else
                if opt.onChange then opt.onChange() end
                if statusText then SetUIText(statusText, "Settings applied") end
            end
            RefreshAllControls()
        end)
        SetTooltip(cb, GetInfoBarItemLabelKey(id), GetInfoBarItemTooltipKey(id))
        children[#children + 1] = cb
        itemControls[#itemControls + 1] = { id = id, line = line, checkbox = cb }

        local label = line:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        label:SetPoint("LEFT", cb, "RIGHT", 6, 0)
        label:SetPoint("RIGHT", line, "RIGHT", -82, 0)
        label:SetJustifyH("LEFT")
        SetUIText(label, GetInfoBarItemLabelKey(id))

        local up = CreateSmallButton(line, "↑", 28, 23)
        up:SetPoint("RIGHT", -36, 0)
        up:SetScript("OnClick", function()
            if ns.MoveInfoBarItem then ns.MoveInfoBarItem(opt.slotKey, id, -1) end
            RefreshInfoBarContentRows(contentCtrl or controlsByKey[opt.key])
            if statusText then SetUIText(statusText, "Button order updated") end
        end)
        SetTooltip(up, GetInfoBarItemLabelKey(id), "Move Up")
        up.qfxBoundaryDisabled = i <= 1
        SetButtonEnabled(up, i > 1)
        children[#children + 1] = up
        itemControls[#itemControls].up = up

        local down = CreateSmallButton(line, "↓", 28, 23)
        down:SetPoint("RIGHT", 0, 0)
        down:SetScript("OnClick", function()
            if ns.MoveInfoBarItem then ns.MoveInfoBarItem(opt.slotKey, id, 1) end
            RefreshInfoBarContentRows(contentCtrl or controlsByKey[opt.key])
            if statusText then SetUIText(statusText, "Button order updated") end
        end)
        SetTooltip(down, GetInfoBarItemLabelKey(id), "Move Down")
        down.qfxBoundaryDisabled = i >= #order
        SetButtonEnabled(down, i < #order)
        children[#children + 1] = down
        itemControls[#itemControls].down = down
    end

    local limitText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    limitText:SetPoint("BOTTOMLEFT", 14, 8)
    limitText:SetTextColor(0.78, 0.78, 0.78)

    contentCtrl = { row = row, opt = opt, children = children, infoBarContent = true, infoBarItems = itemControls, limitText = limitText }
    controlsByKey[opt.key] = contentCtrl
    RefreshControl(contentCtrl)
    return row, height + 8
end

local function InfoBarNudge(slotKey, dx, dy)
    if ns.NudgeInfoBar then ns.NudgeInfoBar(slotKey, dx, dy) end
    RefreshAllControls()
    if statusText then SetUIText(statusText, "Position updated") end
end

local function CreateInfoBarPosition(parent, y, opt)
    local slot = GetInfoBarSlot(opt)
    local row = CreateRow(parent, y, 184, opt, true)
    local children = {}

    local title = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", 12, -10)
    SetUIText(title, OptName(opt))

    local desc = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
    desc:SetPoint("RIGHT", -16, 0)
    desc:SetJustifyH("LEFT")
    desc:SetTextColor(0.78, 0.78, 0.78)
    SetUIText(desc, "Unlock to drag this info bar directly. Arrow buttons nudge it by 1 pixel.")

    local cb = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
    cb:SetSize(24, 24)
    cb:SetPoint("TOPLEFT", 12, -62)
    children[#children + 1] = cb

    local cbLabel = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    cbLabel:SetPoint("LEFT", cb, "RIGHT", 6, 0)
    SetUIText(cbLabel, "Unlock Dragging")

    cb:SetScript("OnClick", function(self)
        if slot and ns.SetInfoBarUnlocked then ns.SetInfoBarUnlocked(opt.slotKey, self:GetChecked() and true or false) end
        if statusText then SetUIText(statusText, self:GetChecked() and "Unlocked. Drag the info bar to move it." or "Info bar position locked") end
        RefreshAllControls()
    end)
    SetTooltip(cb, "Unlock Dragging", "Allows moving this info bar with the mouse.")

    local posText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    posText:SetPoint("TOPLEFT", 14, -96)
    posText:SetText("")

    local left = CreateSmallButton(row, "←", 42, 26)
    left:SetPoint("TOPRIGHT", -154, -62)
    left:SetScript("OnClick", function() InfoBarNudge(opt.slotKey, -1, 0) end)
    children[#children + 1] = left

    local up = CreateSmallButton(row, "↑", 42, 26)
    up:SetPoint("LEFT", left, "RIGHT", 4, 0)
    up:SetScript("OnClick", function() InfoBarNudge(opt.slotKey, 0, 1) end)
    children[#children + 1] = up

    local down = CreateSmallButton(row, "↓", 42, 26)
    down:SetPoint("LEFT", up, "RIGHT", 4, 0)
    down:SetScript("OnClick", function() InfoBarNudge(opt.slotKey, 0, -1) end)
    children[#children + 1] = down

    local right = CreateSmallButton(row, "→", 42, 26)
    right:SetPoint("LEFT", down, "RIGHT", 4, 0)
    right:SetScript("OnClick", function() InfoBarNudge(opt.slotKey, 1, 0) end)
    children[#children + 1] = right

    local reset = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    reset:SetSize(112, 26)
    reset:SetPoint("TOPRIGHT", -16, -134)
    SetUIText(reset, "Reset Position")
    reset:SetScript("OnClick", function()
        if ns.ResetInfoBarPosition then ns.ResetInfoBarPosition(opt.slotKey) end
        RefreshAllControls()
        if statusText then SetUIText(statusText, "Position reset") end
    end)
    children[#children + 1] = reset

    local ctrl = { row = row, opt = opt, positionText = posText, unlockCheckbox = cb, children = children }
    controlsByKey[opt.key] = ctrl
    RefreshControl(ctrl)
    return row, 190
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
            if i == currentGroupIndex then
                btn:SetNormalFontObject("GameFontNormal")
                SetUIText(btn, OptName(group), "» ")
            else
                btn:SetNormalFontObject("GameFontHighlight")
                SetUIText(btn, OptName(group))
            end
            btn:Show()
        else
            btn:Hide()
        end
    end

    if not subTabFrame then return end
    for _, btn in ipairs(subNavButtons) do btn:Hide() end
    if not activeGroup then return end

    local pages = activeGroup.pages or {}
    local count = math.max(1, #pages)
    local gap = 6
    local totalWidth = subTabFrame:GetWidth() or (RIGHT_W - 48)
    local buttonWidth = math.max(92, math.floor((totalWidth - ((count - 1) * gap)) / count))
    local x = 0

    for i, pageKey in ipairs(pages) do
        local pageIndex = GetPageIndexByKey(pageKey)
        local page = pageIndex and ns.OptionPages and ns.OptionPages[pageIndex]
        if page then
            local btn = subNavButtons[i]
            if not btn then
                btn = CreateFrame("Button", nil, subTabFrame, "UIPanelButtonTemplate")
                subNavButtons[i] = btn
            end
            btn:ClearAllPoints()
            btn:SetPoint("LEFT", subTabFrame, "LEFT", x, 0)
            btn:SetSize(buttonWidth, 26)
            if page == activePage then
                btn:SetNormalFontObject("GameFontNormal")
                SetUIText(btn, OptName(page), "» ")
            else
                btn:SetNormalFontObject("GameFontHighlight")
                SetUIText(btn, OptName(page))
            end
            btn:SetScript("OnClick", function() BuildPage(pageIndex) end)
            btn:Show()
            x = x + buttonWidth + gap
        end
    end
end

function BuildPage(index)
    EnsureDB()
    HideDropdown()

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
    else
        rows = {}
        controlsByKey = {}

        local y = -8
        for _, opt in ipairs(page.options or {}) do
            local used = 0
            if opt.type == "header" then
                _, used = CreateHeader(content, y, opt)
            elseif opt.type == "checkbox" then
                _, used = CreateCheckbox(content, y, opt)
            elseif opt.type == "slider" then
                _, used = CreateSlider(content, y, opt)
            elseif opt.type == "dropdown" then
                _, used = CreateDropdown(content, y, opt)
            elseif opt.type == "iconStyle" then
                _, used = CreateIconStyleSelector(content, y, opt)
            elseif opt.type == "color" then
                _, used = CreateColor(content, y, opt)
            elseif opt.type == "buttonOrder" then
                _, used = CreateButtonOrder(content, y, opt)
            elseif opt.type == "position" then
                _, used = CreatePosition(content, y, opt)
            elseif opt.type == "topCenterWidgetPosition" then
                _, used = CreateTopCenterWidgetPosition(content, y, opt)
            elseif opt.type == "infoBarContent" then
                _, used = CreateInfoBarContent(content, y, opt)
            elseif opt.type == "infoBarPosition" then
                _, used = CreateInfoBarPosition(content, y, opt)
            end
            y = y - (used or 0)
        end

        local contentHeight = math.max(452, -y + 24)
        content:SetHeight(contentHeight)
        pageCache[currentPageIndex] = {
            rows = rows,
            controls = controlsByKey,
            height = contentHeight,
        }
    end

    if scrollFrame then scrollFrame:SetVerticalScroll(0) end

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
    frame:SetBackdrop(BACKDROP)
    frame:SetClampedToScreen(true)
    frame:Hide()
    frame:SetScript("OnHide", function()
        HideDropdown()
        if ns.TopCenterWidget then ns.TopCenterWidget:OnConfigClosed() end
    end)

    table.insert(UISpecialFrames, "QFXSystemBarConfigFrame")

    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -5, -5)

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
    sub:SetTextColor(0.82, 0.82, 0.82)

    local iconCredit = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    rootIconCredit = iconCredit
    iconCredit:SetPoint("TOPLEFT", sub, "BOTTOMLEFT", 0, -3)
    SetUIText(iconCredit, "Some icons are from ElvUI WindTools GameBar.")
    iconCredit:SetTextColor(0.82, 0.82, 0.82)

    local left = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    left:SetPoint("TOPLEFT", 22, -72)
    left:SetSize(LEFT_W, 456)
    left:SetBackdrop(PANEL_BACKDROP)

    local right = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    right:SetPoint("TOPLEFT", left, "TOPRIGHT", 12, 0)
    right:SetSize(RIGHT_W, 456)
    right:SetBackdrop(PANEL_BACKDROP)

    pageTitle = right:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    pageTitle:SetPoint("TOPLEFT", 16, -14)
    pageTitle:SetText("")

    subTabFrame = CreateFrame("Frame", nil, right)
    subTabFrame:SetPoint("TOPLEFT", 16, -42)
    subTabFrame:SetSize(RIGHT_W - 48, 28)

    scrollFrame = CreateFrame("ScrollFrame", "QFXSystemBarConfigScrollFrame", right, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 16, -78)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 12)

    content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(CONTENT_W, 452)
    scrollFrame:SetScrollChild(content)

    for i, group in ipairs(ns.OptionGroups or {}) do
        local b = CreateFrame("Button", nil, left, "UIPanelButtonTemplate")
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

    local resetPage = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    resetPageButton = resetPage
    resetPage:SetSize(132, 26)
    resetPage:SetPoint("BOTTOMLEFT", 24, 24)
    SetUIText(resetPage, "Reset Page")
    resetPage:SetScript("OnClick", function()
        local page = ns.OptionPages[currentPageIndex]
        ResetOptions(page and page.options)
    end)

    local resetAll = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
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

    frame:SetScript("OnMouseDown", HideDropdown)
    BuildPage(1)
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
    HideDropdown()
    if frame then
        RefreshStaticFrameText()
        BuildPage(currentPageIndex or 1)
    end
end

function ns.OpenConfigFrame()
    local f = CreateMainFrame()
    BuildPage(currentPageIndex or 1)
    f:Show()
end

function ns.ToggleConfigFrame()
    local f = CreateMainFrame()
    if f:IsShown() then
        f:Hide()
    else
        BuildPage(currentPageIndex or 1)
        f:Show()
    end
end

function ns.CloseConfigFrame()
    HideDropdown()
    if frame then frame:Hide() end
end

EventUtil.ContinueOnPlayerLogin(function()
    EnsureDB()
end)
