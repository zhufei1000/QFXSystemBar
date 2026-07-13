local addonName, ns = ...
ns = _G.QFXSystemBarNS or ns
if not ns then return end

-- Option data uses stable English source keys only. Locale files translate
-- these keys at render time through ns.T(), so manual language switching
-- remains independent from SavedVariables and client language.

-- ========================================================================
-- QFXSystemBar options model
-- Popup UI only. Layout is designed from English width first.
-- ========================================================================
local FRAME_MODE_LABELS = {
    [0] = "Always Show",
    [1] = "Always Hide",
    [2] = "Show on Mouseover",
    [3] = "Show on Mouseover, Keep Shown in Combat",
    [4] = "Show Icons on Mouseover, Keep Clock Shown",
}

local function MakeFrameOptions(modeList)
    return function()
        local data = {}
        for _, mode in ipairs(modeList) do
            data[#data + 1] = { value = mode, textKey = FRAME_MODE_LABELS[mode] }
        end
        return data
    end
end

local function MicroMenuChanged()
    if ns.OnMicroMenuChanged then ns.OnMicroMenuChanged() end
end

local function PositionChanged()
    if ns.OnMicroMenuPositionChanged then ns.OnMicroMenuPositionChanged() end
end

local function BadgeTextChanged()
    if ns.RefreshMicroMenuBadges then ns.RefreshMicroMenuBadges(true) end
end

local function HearthstoneSettingsChanged()
    if ns.OnHearthstoneSettingsChanged then
        ns.OnHearthstoneSettingsChanged()
    else
        MicroMenuChanged()
    end
end


local function UIFrameModeChanged(key)
    return function(_, value)
        if ns.OnUIFrameModeChanged then ns.OnUIFrameModeChanged(key, value) end
    end
end

ns.ButtonList = {
    { id = "Character",     var = "isCustomMicroMenuCharacter",     labelKey = "Character",          tooltipKey = "Show the character info button." },
    { id = "Social",        var = "isCustomMicroMenuSocial",        labelKey = "Social",             tooltipKey = "Show the social button." },
    { id = "Profession",    var = "isCustomMicroMenuProfession",    labelKey = "Profession",         tooltipKey = "Show the profession button." },
    { id = "PlayerSpells",  var = "isCustomMicroMenuPlayerSpells",  labelKey = "Talents & Spells",   tooltipKey = "Show the talents and spellbook button." },
    { id = "Achievement",   var = "isCustomMicroMenuAchievement",   labelKey = "Achievements",       tooltipKey = "Show the achievements button." },
    { id = "QuestLog",      var = "isCustomMicroMenuQuestLog",      labelKey = "Quests",             tooltipKey = "Show the quest log button." },
    { id = "Time",          var = "isCustomMicroMenuTime",          labelKey = "Time",               tooltipKey = "Show the time button." },
    { id = "Housing",       var = "isCustomMicroMenuHousing",       labelKey = "Housing",            tooltipKey = "Show the housing button." },
    { id = "Guild",         var = "isCustomMicroMenuGuild",         labelKey = "Guild / Communities",tooltipKey = "Show the guild and communities button." },
    { id = "LFD",           var = "isCustomMicroMenuLFD",           labelKey = "Group Finder",       tooltipKey = "Show the group finder button." },
    { id = "Collections",   var = "isCustomMicroMenuCollections",   labelKey = "Collections",        tooltipKey = "Show the collections button." },
    { id = "EJ",            var = "isCustomMicroMenuEJ",            labelKey = "Adventure Guide",    tooltipKey = "Show the adventure guide button." },
    { id = "Store",         var = "isCustomMicroMenuStore",         labelKey = "Shop",               tooltipKey = "Show the shop button." },
    { id = "Bags",          var = "isCustomMicroMenuBags",          labelKey = "Bags",               tooltipKey = "Show the bags button." },
    { id = "Volume",        var = "isCustomMicroMenuVolume",        labelKey = "Volume",             tooltipKey = "Show the volume button." },
    { id = "MainMenu",      var = "isCustomMicroMenuMainMenu",      labelKey = "Game Menu",          tooltipKey = "Show the game menu button." },
    { id = "MeetingStone",  var = "isCustomMicroMenuMeetingStone",  labelKey = "MeetingStone",        tooltipKey = "Show the MeetingStone button." },
    { id = "Hearthstone",   var = "isCustomMicroMenuHearthstone",   labelKey = "Hearthstone",        tooltipKey = "Show the hearthstone button." },
}

-- Backward compatibility for code paths that still read item.name/item.tooltip.
-- These remain English source keys, not localized display text.
for _, item in ipairs(ns.ButtonList) do
    item.name = item.labelKey
    item.tooltip = item.tooltipKey
end
local function CopyDefaultButtonOrder()
    local order = {}
    for _, item in ipairs(ns.ButtonList) do
        order[#order + 1] = item.id
    end
    return order
end

ns.GetDefaultMicroMenuButtonOrder = CopyDefaultButtonOrder

ns.GeneralOptions = {
    {
        type = "header",
        key = "generalHeader",
        nameKey = "Visibility & Language",
        tooltipKey = "Set the interface language and choose how QFXSystemBar, the native micro menu, and the native bag bar are displayed.",
    },
    {
        type = "dropdown",
        key = "language",
        nameKey = "Interface Language",
        default = ns.defaults.language,
        tooltipKey = "Defaults to the client language. You can force a specific language. The settings window refreshes immediately after switching.",
        options = function()
            return ns.GetLanguageOptions and ns.GetLanguageOptions() or {
                { value = "auto", textKey = "Automatic (Client Language)" },
            }
        end,
        onChange = function(_, value)
            if ns.OnLanguageChanged then ns.OnLanguageChanged(value) end
        end,
    },
    {
        type = "checkbox",
        key = "isCustomMicroMenu",
        nameKey = "Enable QFXSystemBar",
        default = ns.defaults.isCustomMicroMenu,
        tooltipKey = "Show the custom QFXSystemBar system bar.",
        onChange = function(_, value)
            if ns.OnMicroMenuToggle then ns.OnMicroMenuToggle(value) end
        end,
    },
    {
        type = "dropdown",
        key = "customMicroMenu",
        nameKey = "Top QFX Bar Visibility",
        default = ns.defaults.customMicroMenu,
        tooltipKey = "Always show the QFX bar, hide it, or show it only while the mouse is over the bar.",
        options = MakeFrameOptions({ 0, 2, 4, 3 }),
        onChange = UIFrameModeChanged("customMicroMenu"),
    },
    {
        type = "dropdown",
        key = "nativeMicroMenu",
        nameKey = "Native Micro Menu Visibility",
        default = ns.defaults.nativeMicroMenu,
        tooltipKey = "Choose whether Blizzard's original micro menu is always shown, hidden, or shown only on mouseover.",
        options = MakeFrameOptions({ 0, 1, 2 }),
        onChange = UIFrameModeChanged("nativeMicroMenu"),
    },
    {
        type = "dropdown",
        key = "bagBar",
        nameKey = "Native Bag Bar Visibility",
        default = ns.defaults.bagBar,
        tooltipKey = "Choose whether Blizzard's original bag bar is always shown, hidden, or shown only on mouseover.",
        options = MakeFrameOptions({ 0, 1, 2 }),
        onChange = UIFrameModeChanged("bagBar"),
    },
    {
        type = "slider",
        key = "uiFadeInDuration",
        nameKey = "Mouseover Show Speed",
        default = ns.defaults.uiFadeInDuration,
        min = 0,
        max = 2,
        step = 0.1,
        tooltipKey = "How quickly mouseover-hidden bars become fully visible after the mouse enters.",
        onChange = function()
            if ns.OnUIFadeTimerChanged then ns.OnUIFadeTimerChanged() end
        end,
    },
    {
        type = "slider",
        key = "uiFadeOutDuration",
        nameKey = "Mouseover Hide Speed",
        default = ns.defaults.uiFadeOutDuration,
        min = 0,
        max = 2,
        step = 0.1,
        tooltipKey = "How quickly mouseover-hidden bars hide again after the mouse leaves.",
        onChange = function()
            if ns.OnUIFadeTimerChanged then ns.OnUIFadeTimerChanged() end
        end,
    },
}

ns.ButtonOptions = {
    {
        type = "header",
        key = "buttonHeader",
        nameKey = "Button Order & Visibility",
        tooltipKey = "Toggle visibility and use the up/down arrows to adjust button order on the system bar.",
    },
    {
        type = "buttonOrder",
        key = "customMicroMenuButtonOrder",
        nameKey = "Button List",
        tooltipKey = "Checked buttons are shown on the system bar. Use the arrows on the right to adjust order.",
        onChange = MicroMenuChanged,
    },
    {
        type = "header",
        key = "hearthstoneSettingsHeader",
        nameKey = "Hearthstone Settings",
        tooltipKey = "Choose which hearthstone item each mouse button uses.",
    },
    {
        type = "dropdown",
        key = "customMicroMenuHearthstoneLeft",
        nameKey = "Left Click Hearthstone",
        default = ns.defaults.customMicroMenuHearthstoneLeft,
        maxVisibleRows = 8,
        tooltipKey = "Choose the hearthstone used by left-clicking the Hearthstone button.",
        options = function()
            return ns.GetHearthstoneDropdownOptions and ns.GetHearthstoneDropdownOptions() or {}
        end,
        onChange = HearthstoneSettingsChanged,
    },
    {
        type = "dropdown",
        key = "customMicroMenuHearthstoneMiddle",
        nameKey = "Middle Click Hearthstone",
        default = ns.defaults.customMicroMenuHearthstoneMiddle,
        maxVisibleRows = 8,
        tooltipKey = "Choose the hearthstone used by middle-clicking the Hearthstone button.",
        options = function()
            return ns.GetHearthstoneDropdownOptions and ns.GetHearthstoneDropdownOptions() or {}
        end,
        onChange = HearthstoneSettingsChanged,
    },
    {
        type = "dropdown",
        key = "customMicroMenuHearthstoneRight",
        nameKey = "Right Click Hearthstone",
        default = ns.defaults.customMicroMenuHearthstoneRight,
        maxVisibleRows = 8,
        tooltipKey = "Choose the hearthstone used by right-clicking the Hearthstone button.",
        options = function()
            return ns.GetHearthstoneDropdownOptions and ns.GetHearthstoneDropdownOptions() or {}
        end,
        onChange = HearthstoneSettingsChanged,
    },
}

ns.IconOptions = {
    {
        type = "header",
        key = "iconSettingsHeader",
        nameKey = "Icon Settings",
        tooltipKey = "Configure micro menu icon style, icon coloring, button size, and button spacing.",
    },
    {
        type = "dropdown",
        key = "customMicroMenuIconStyle",
        nameKey = "Icon Style",
        default = ns.defaults.customMicroMenuIconStyle,
        tooltipKey = "Choose which icon set is used by the top micro menu.",
        options = function()
            return {
                { value = "original", textKey = "ElvUI Wind" },
                { value = "gameicons", textKey = "Game Icons" },
                { value = "lucide", textKey = "Lucide" },
                { value = "tabler", textKey = "Tabler" },
            }
        end,
        onChange = MicroMenuChanged,
    },
    {
        type = "dropdown",
        key = "customMicroMenuIconColorMode",
        nameKey = "Icon Color",
        default = ns.defaults.customMicroMenuIconColorMode,
        tooltipKey = "Choose how the micro menu icons are colored.",
        options = function()
            return {
                { value = "class", textKey = "Class Color" },
                { value = "original", textKey = "Original Color" },
                { value = "custom", textKey = "Custom Color" },
            }
        end,
        onChange = MicroMenuChanged,
    },
    {
        type = "color",
        key = "customMicroMenuIconCustomColor",
        nameKey = "Icon Custom Color",
        default = ns.defaults.customMicroMenuIconCustomColor,
        tooltipKey = "Choose the custom color used by micro menu icons.",
        onChange = MicroMenuChanged,
    },
    {
        type = "slider",
        key = "customMicroMenuIconSize",
        nameKey = "Icon Button Size",
        default = ns.defaults.customMicroMenuIconSize,
        min = 20,
        max = 50,
        step = 1,
        tooltipKey = "Adjust the size of each top micro menu icon button.",
        onChange = MicroMenuChanged,
    },
    {
        type = "slider",
        key = "customMicroMenuButtonSpacing",
        nameKey = "Icon Spacing",
        default = ns.defaults.customMicroMenuButtonSpacing,
        min = -10,
        max = 30,
        step = 1,
        tooltipKey = "Adjust the spacing between top micro menu icon buttons.",
        onChange = MicroMenuChanged,
    },
}

ns.ClockOptions = {
    {
        type = "header",
        key = "clockSettingsHeader",
        nameKey = "Clock Settings",
        tooltipKey = "Configure the top micro menu clock source, color, format, font, size, and outline.",
    },
    {
        type = "dropdown",
        key = "customMicroMenuClockColorMode",
        nameKey = "Clock Color",
        default = ns.defaults.customMicroMenuClockColorMode,
        tooltipKey = "Choose how the clock text is colored.",
        options = function()
            return {
                { value = "class", textKey = "Class Color" },
                { value = "original", textKey = "Original Color" },
                { value = "custom", textKey = "Custom Color" },
            }
        end,
        onChange = MicroMenuChanged,
    },
    {
        type = "color",
        key = "customMicroMenuClockCustomColor",
        nameKey = "Clock Custom Color",
        default = ns.defaults.customMicroMenuClockCustomColor,
        tooltipKey = "Choose the custom color used by the clock text.",
        onChange = MicroMenuChanged,
    },
    {
        type = "checkbox",
        key = "isCustomMicroMenuTimeAdj",
        nameKey = "Enable Clock Text Settings",
        default = ns.defaults.isCustomMicroMenuTimeAdj,
        tooltipKey = "Allows changing the clock source, format, font size, and outline.",
        onChange = MicroMenuChanged,
    },
    {
        type = "dropdown",
        key = "customMicroMenuTimeMode",
        nameKey = "Clock Source",
        default = ns.defaults.customMicroMenuTimeMode,
        tooltipKey = "Choose whether the clock uses local time or server time.",
        options = function()
            return {
                { value = "local", textKey = "Local Time" },
                { value = "server", textKey = "Server Time" },
            }
        end,
        onChange = MicroMenuChanged,
    },
    {
        type = "dropdown",
        key = "customMicroMenuTimeFormat",
        nameKey = "Clock Format",
        default = ns.defaults.customMicroMenuTimeFormat,
        tooltipKey = "Choose 24-hour or 12-hour clock display.",
        options = function()
            return {
                { value = "24h", textKey = "24-Hour" },
                { value = "12h", textKey = "12-Hour" },
            }
        end,
        onChange = MicroMenuChanged,
    },
    {
        type = "dropdown",
        key = "customMicroMenuTimeFont",
        nameKey = "Clock Font",
        default = ns.defaults.customMicroMenuTimeFont,
        tooltipKey = "Choose the font used by the top micro menu clock.",
        maxVisibleRows = 8,
        options = function()
            return ns.GetMicroMenuTimeFontOptions and ns.GetMicroMenuTimeFontOptions() or {
                { value = "default", textKey = "Default Font" },
            }
        end,
        onChange = MicroMenuChanged,
    },
    {
        type = "slider",
        key = "customMicroMenuFontSize",
        nameKey = "Clock Font Size",
        default = ns.defaults.customMicroMenuFontSize,
        min = 10,
        max = 80,
        step = 1,
        tooltipKey = "Adjust the top micro menu clock text size.",
        onChange = MicroMenuChanged,
    },
    {
        type = "slider",
        key = "customMicroMenuTimeTextYOffset",
        nameKey = "Clock Number Y Offset",
        default = ns.defaults.customMicroMenuTimeTextYOffset,
        min = -20,
        max = 20,
        step = 1,
        tooltipKey = "Adjust only the hour and minute numbers up or down. The colon stays centered.",
        onChange = MicroMenuChanged,
    },
    {
        type = "dropdown",
        key = "customMicroMenuTimeOutline",
        nameKey = "Clock Text Outline",
        default = ns.defaults.customMicroMenuTimeOutline,
        tooltipKey = "Adjust the top micro menu clock text outline.",
        options = function()
            return {
                { value = "", textKey = "None" },
                { value = "OUTLINE", textKey = "Thin Outline" },
                { value = "THICKOUTLINE", textKey = "Thick Outline" },
            }
        end,
        onChange = MicroMenuChanged,
    },
}

ns.BadgeOptions = {
    {
        type = "header",
        key = "badgeSettingsHeader",
        nameKey = "Extra Text Settings",
        tooltipKey = "Configure the small numbers shown on supported micro menu buttons, such as durability, friends, guild members, free bag slots, and volume.",
    },
    {
        type = "dropdown",
        key = "customMicroMenuBadgeColorMode",
        nameKey = "Extra Text Color",
        default = ns.defaults.customMicroMenuBadgeColorMode,
        tooltipKey = "Choose how the button extra text is colored.",
        options = function()
            return {
                { value = "class", textKey = "Class Color" },
                { value = "original", textKey = "Original Color" },
                { value = "custom", textKey = "Custom Color" },
            }
        end,
        onChange = BadgeTextChanged,
    },
    {
        type = "color",
        key = "customMicroMenuBadgeCustomColor",
        nameKey = "Extra Text Custom Color",
        default = ns.defaults.customMicroMenuBadgeCustomColor,
        tooltipKey = "Choose the custom color used by button extra text.",
        onChange = BadgeTextChanged,
    },
    {
        type = "checkbox",
        key = "customMicroMenuShowDurabilityBadge",
        nameKey = "Character Button: Durability Number",
        default = ns.defaults.customMicroMenuShowDurabilityBadge,
        tooltipKey = "Show the equipped durability number on the Character button.",
        onChange = BadgeTextChanged,
    },
    {
        type = "checkbox",
        key = "customMicroMenuShowFriendBadge",
        nameKey = "Social Button: Online Friends",
        default = ns.defaults.customMicroMenuShowFriendBadge,
        tooltipKey = "Show the online friend count on the Social button.",
        onChange = BadgeTextChanged,
    },
    {
        type = "checkbox",
        key = "customMicroMenuShowGuildBadge",
        nameKey = "Guild Button: Online Guild Members",
        default = ns.defaults.customMicroMenuShowGuildBadge,
        tooltipKey = "Show the online guild member count on the Guild button.",
        onChange = BadgeTextChanged,
    },
    {
        type = "checkbox",
        key = "customMicroMenuShowBagBadge",
        nameKey = "Bags Button: Free Bag Slots",
        default = ns.defaults.customMicroMenuShowBagBadge,
        tooltipKey = "Show the free bag slot count on the Bags button.",
        onChange = BadgeTextChanged,
    },
    {
        type = "checkbox",
        key = "customMicroMenuShowVolumeBadge",
        nameKey = "Volume Button: Master Volume",
        default = ns.defaults.customMicroMenuShowVolumeBadge,
        tooltipKey = "Show the master volume number on the Volume button while hovering.",
        onChange = BadgeTextChanged,
    },
}

ns.AppearanceOptions = {}
for _, item in ipairs(ns.IconOptions) do ns.AppearanceOptions[#ns.AppearanceOptions + 1] = item end
for _, item in ipairs(ns.ClockOptions) do ns.AppearanceOptions[#ns.AppearanceOptions + 1] = item end
for _, item in ipairs(ns.BadgeOptions) do ns.AppearanceOptions[#ns.AppearanceOptions + 1] = item end

ns.PositionOptions = {
    {
        type = "header",
        key = "positionHeader",
        nameKey = "Position",
        tooltipKey = "Unlock and drag the system bar, or use arrow buttons for fine positioning.",
    },
    {
        type = "position",
        key = "microMenuPositionTools",
        nameKey = "Position Controls",
        tooltipKey = "After unlocking, drag the system bar directly. Arrow buttons move it by 1 pixel.",
        defaultX = ns.defaults.customMicroMenuPositionX,
        defaultY = ns.defaults.customMicroMenuPositionY,
        onChange = PositionChanged,
    },
}

ns.TopCenterWidgetOptions = {
    {
        type = "topCenterWidgetPosition",
        key = "topCenterWidgetPosition",
        nameKey = "Top-Center Zone Information",
    },
}

local function InfoBarChanged()
    if ns.EnsureInfoBarLoaded then ns.EnsureInfoBarLoaded() end
    if ns.OnInfoBarChanged then ns.OnInfoBarChanged() end
end

local function InfoBarFadeOptions()
    return {
        { value = "left", textKey = "Left Gradient" },
        { value = "right", textKey = "Right Gradient" },
    }
end

local function InfoBarLineStyleOptions()
    return {
        { value = "eui-unitframes", textKey = "EUI UnitFrames" },
        { value = "eui-taskbar", textKey = "EUI Taskbar" },
    }
end

local function InfoBarLinePositionOptions()
    return {
        { value = "bottom", textKey = "Bottom Line" },
        { value = "top", textKey = "Top Line" },
        { value = "both", textKey = "Top and Bottom Lines" },
        { value = "hidden", textKey = "No Class Line" },
    }
end

ns.InfoBarGeneralOptions = {
    {
        type = "header",
        key = "infoBarHeader",
        nameKey = "Info Bars",
        tooltipKey = "QFX modular info strips with editable visibility, order, position, size, and background direction.",
    },
    {
        type = "checkbox",
        key = "isInfoBar",
        nameKey = "Enable Info Bars",
        default = ns.defaults.isInfoBar,
        tooltipKey = "Show the QFX info strips. Each strip only builds and loads its own textures after it is enabled.",
        onChange = InfoBarChanged,
    },
    {
        type = "slider",
        key = "infoBarFontSize",
        nameKey = "Info Text Size",
        default = ns.defaults.infoBarFontSize,
        min = 8,
        max = 20,
        step = 1,
        tooltipKey = "Adjust the text size used by all info bars.",
        onChange = InfoBarChanged,
    },
    {
        type = "slider",
        key = "infoBarFadeStrength",
        nameKey = "Background Strength",
        default = ns.defaults.infoBarFadeStrength,
        min = 0,
        max = 100,
        step = 1,
        tooltipKey = "Adjust the shared background and class-line strength for all info bars. 0 hides the extra background, 50 keeps the default, and 100 makes it strongest.",
        onChange = InfoBarChanged,
    },
}

local function MakeInfoBarSideOptions(slotKey, optionSuffix, titleKey, enableTitleKey, enabledKey, widthKey, heightKey, fadeKey, lineStyleKey, linePositionKey, lineThicknessKey)
    return {
        {
            type = "header",
            key = "infoBar" .. optionSuffix .. "Header",
            nameKey = titleKey,
            tooltipKey = "Configure this info bar independently.",
        },
        {
            type = "checkbox",
            key = enabledKey,
            nameKey = enableTitleKey,
            default = ns.defaults[enabledKey],
            tooltipKey = "Show or hide this single info bar.",
            onChange = InfoBarChanged,
        },
        {
            type = "slider",
            key = widthKey,
            nameKey = "Info Bar Width",
            default = ns.defaults[widthKey],
            min = 260,
            max = 900,
            step = 1,
            tooltipKey = "Adjust this info bar width.",
            onChange = InfoBarChanged,
        },
        {
            type = "slider",
            key = heightKey,
            nameKey = "Info Bar Height",
            default = ns.defaults[heightKey],
            min = 12,
            max = 40,
            step = 1,
            tooltipKey = "Adjust this info bar height.",
            onChange = InfoBarChanged,
        },
        {
            type = "slider",
            key = lineThicknessKey,
            nameKey = "Class Line Thickness",
            default = ns.defaults[lineThicknessKey],
            min = 1,
            max = 6,
            step = 1,
            tooltipKey = "Adjust this info bar class-colored line thickness.",
            onChange = InfoBarChanged,
        },
        {
            type = "dropdown",
            key = lineStyleKey,
            nameKey = "Class Line Style",
            default = ns.defaults[lineStyleKey],
            tooltipKey = "Choose this info bar class-colored line visual style.",
            options = InfoBarLineStyleOptions,
            onChange = InfoBarChanged,
        },
        {
            type = "dropdown",
            key = linePositionKey,
            nameKey = "Class Line Position",
            default = ns.defaults[linePositionKey],
            tooltipKey = "Choose whether this info bar shows the class line on the top edge, bottom edge, both edges, or not at all.",
            options = InfoBarLinePositionOptions,
            onChange = InfoBarChanged,
        },
        {
            type = "dropdown",
            key = fadeKey,
            nameKey = "Gradient Direction",
            default = ns.defaults[fadeKey],
            tooltipKey = "Choose whether this info bar background extends from the left side or the right side.",
            options = InfoBarFadeOptions,
            onChange = InfoBarChanged,
        },
        {
            type = "infoBarPosition",
            key = "infoBar" .. optionSuffix .. "Position",
            slotKey = slotKey,
            nameKey = "Position Controls",
            tooltipKey = "Unlock and drag this info bar, or nudge it by 1 pixel.",
            onChange = InfoBarChanged,
        },
        {
            type = "infoBarContent",
            key = "infoBar" .. optionSuffix .. "Content",
            slotKey = slotKey,
            nameKey = "Displayed Information",
            tooltipKey = "Checked items are shown. Each info bar can show up to 5 items. FPS includes latency without MS, so latency no longer takes a separate slot. Coordinates and Phase ID are optional items. Visible items are divided equally across the bar.",
            onChange = InfoBarChanged,
        },
    }
end

ns.InfoBarLeftOptions = MakeInfoBarSideOptions("left", "LeftTop", "Left Top Info Bar", "Enable Left Top Info Bar", "infoBarLeftEnabled", "infoBarLeftWidth", "infoBarLeftHeight", "infoBarLeftFade", "infoBarLeftLineStyle", "infoBarLeftLinePosition", "infoBarLeftLineThickness")
ns.InfoBarLeftBottomOptions = MakeInfoBarSideOptions("leftbottom", "LeftBottom", "Left Bottom Info Bar", "Enable Left Bottom Info Bar", "infoBarLeftBottomEnabled", "infoBarLeftBottomWidth", "infoBarLeftBottomHeight", "infoBarLeftBottomFade", "infoBarLeftBottomLineStyle", "infoBarLeftBottomLinePosition", "infoBarLeftBottomLineThickness")
ns.InfoBarRightOptions = MakeInfoBarSideOptions("right", "RightBottom", "Right Bottom Info Bar", "Enable Right Bottom Info Bar", "infoBarRightEnabled", "infoBarRightWidth", "infoBarRightHeight", "infoBarRightFade", "infoBarRightLineStyle", "infoBarRightLinePosition", "infoBarRightLineThickness")

-- Compatibility aliases for older Config.lua normalization paths.
ns.InfoBarLeftTopOptions = ns.InfoBarLeftOptions
ns.InfoBarRightBottomOptions = ns.InfoBarRightOptions
ns.InfoBarOptions = {}
local function AppendOptions(target, source)
    for _, item in ipairs(source or {}) do target[#target + 1] = item end
end
AppendOptions(ns.InfoBarOptions, ns.InfoBarGeneralOptions)
AppendOptions(ns.InfoBarOptions, ns.InfoBarLeftOptions)
AppendOptions(ns.InfoBarOptions, ns.InfoBarLeftBottomOptions)
AppendOptions(ns.InfoBarOptions, ns.InfoBarRightOptions)

ns.OptionPages = {
    { key = "general", nameKey = "Display", options = ns.GeneralOptions },
    { key = "buttons", nameKey = "Button List", options = ns.ButtonOptions },
    { key = "iconSettings", nameKey = "Icon Settings", options = ns.IconOptions },
    { key = "clockSettings", nameKey = "Clock Settings", options = ns.ClockOptions },
    { key = "badgeSettings", nameKey = "Extra Text", options = ns.BadgeOptions },
    { key = "position", nameKey = "Position", options = ns.PositionOptions },
    { key = "topCenterWidget", nameKey = "Top-Center Zone Information", options = ns.TopCenterWidgetOptions },
    { key = "infoGeneral", nameKey = "General", options = ns.InfoBarGeneralOptions },
    { key = "infoLeftTop", nameKey = "Left Top Info Bar", options = ns.InfoBarLeftOptions },
    { key = "infoLeftBottom", nameKey = "Left Bottom Info Bar", options = ns.InfoBarLeftBottomOptions },
    { key = "infoRightBottom", nameKey = "Right Bottom Info Bar", options = ns.InfoBarRightOptions },
}

ns.OptionGroups = {
    {
        key = "microMenu",
        nameKey = "Micro Menu",
        pages = { "general", "buttons", "iconSettings", "clockSettings", "badgeSettings", "position" },
    },
    {
        key = "infoBars",
        nameKey = "Info Bars",
        pages = { "infoGeneral", "infoLeftTop", "infoLeftBottom", "infoRightBottom" },
    },
    {
        key = "topCenterWidgetGroup",
        nameKey = "Top-Center Zone Information",
        pages = { "topCenterWidget" },
    },
}

ns.OptionPageIndexByKey = {}
for index, page in ipairs(ns.OptionPages or {}) do
    ns.OptionPageIndexByKey[page.key] = index
end


local function NormalizeOptionSourceKeys(list)
    for _, opt in ipairs(list or {}) do
        if ns.MakeOption then ns.MakeOption(opt) end
        if opt.name and not opt.nameKey then opt.nameKey = opt.name end
        if opt.tooltip and not opt.tooltipKey then opt.tooltipKey = opt.tooltip end
    end
end

NormalizeOptionSourceKeys(ns.GeneralOptions)
NormalizeOptionSourceKeys(ns.ButtonOptions)
NormalizeOptionSourceKeys(ns.IconOptions)
NormalizeOptionSourceKeys(ns.ClockOptions)
NormalizeOptionSourceKeys(ns.BadgeOptions)
NormalizeOptionSourceKeys(ns.AppearanceOptions)
NormalizeOptionSourceKeys(ns.InfoBarGeneralOptions)
NormalizeOptionSourceKeys(ns.InfoBarLeftOptions)
NormalizeOptionSourceKeys(ns.InfoBarRightOptions)
NormalizeOptionSourceKeys(ns.InfoBarLeftTopOptions)
NormalizeOptionSourceKeys(ns.InfoBarLeftBottomOptions)
NormalizeOptionSourceKeys(ns.InfoBarRightBottomOptions)
NormalizeOptionSourceKeys(ns.InfoBarOptions)
NormalizeOptionSourceKeys(ns.PositionOptions)
NormalizeOptionSourceKeys(ns.TopCenterWidgetOptions)
NormalizeOptionSourceKeys(ns.OptionPages)
NormalizeOptionSourceKeys(ns.OptionGroups)

-- ========================================================================
-- Parent / child dependencies
-- ========================================================================
ns.OptionDependencies = {
    isInfoBar = {
        {
            children = {
                "infoBarFontSize", "infoBarFadeStrength",
                "infoBarLeftEnabled", "infoBarLeftWidth", "infoBarLeftHeight", "infoBarLeftLineThickness", "infoBarLeftLineStyle", "infoBarLeftLinePosition", "infoBarLeftFade", "infoBarLeftTopPosition", "infoBarLeftTopContent",
                "infoBarLeftBottomEnabled", "infoBarLeftBottomWidth", "infoBarLeftBottomHeight", "infoBarLeftBottomLineThickness", "infoBarLeftBottomLineStyle", "infoBarLeftBottomLinePosition", "infoBarLeftBottomFade", "infoBarLeftBottomPosition", "infoBarLeftBottomContent",
                "infoBarRightEnabled", "infoBarRightWidth", "infoBarRightHeight", "infoBarRightLineThickness", "infoBarRightLineStyle", "infoBarRightLinePosition", "infoBarRightFade", "infoBarRightBottomPosition", "infoBarRightBottomContent",
            },
            enabled = function() return QFXSystemBarDB and QFXSystemBarDB.isInfoBar == true end,
        },
    },
    isCustomMicroMenu = {
        {
            children = {
                "customMicroMenu", "customMicroMenuButtonOrder", "customMicroMenuHearthstoneLeft", "customMicroMenuHearthstoneMiddle", "customMicroMenuHearthstoneRight", "customMicroMenuIconStyle",
                "customMicroMenuIconColorMode", "customMicroMenuIconCustomColor", "customMicroMenuClockColorMode", "customMicroMenuClockCustomColor",
                "customMicroMenuBadgeColorMode", "customMicroMenuBadgeCustomColor", "customMicroMenuShowDurabilityBadge", "customMicroMenuShowFriendBadge", "customMicroMenuShowGuildBadge", "customMicroMenuShowBagBadge", "customMicroMenuShowVolumeBadge",
                "isCustomMicroMenuTimeAdj", "customMicroMenuTimeMode", "customMicroMenuTimeFormat",
                "customMicroMenuTimeFont", "customMicroMenuFontSize", "customMicroMenuTimeTextYOffset", "customMicroMenuTimeOutline", "customMicroMenuIconSize",
                "customMicroMenuButtonSpacing", "microMenuPositionTools",
            },
            enabled = function() return QFXSystemBarDB and QFXSystemBarDB.isCustomMicroMenu == true end,
        },
    },
    customMicroMenuIconColorMode = {
        {
            children = { "customMicroMenuIconCustomColor" },
            enabled = function()
                return QFXSystemBarDB and QFXSystemBarDB.customMicroMenuIconColorMode == "custom"
            end,
        },
    },
    customMicroMenuClockColorMode = {
        {
            children = { "customMicroMenuClockCustomColor" },
            enabled = function()
                return QFXSystemBarDB and QFXSystemBarDB.customMicroMenuClockColorMode == "custom"
            end,
        },
    },
    customMicroMenuBadgeColorMode = {
        {
            children = { "customMicroMenuBadgeCustomColor" },
            enabled = function()
                return QFXSystemBarDB and QFXSystemBarDB.customMicroMenuBadgeColorMode == "custom"
            end,
        },
    },
    isCustomMicroMenuTimeAdj = {
        {
            children = { "customMicroMenuTimeMode", "customMicroMenuTimeFormat", "customMicroMenuTimeFont", "customMicroMenuFontSize", "customMicroMenuTimeOutline" },
            enabled = function() return QFXSystemBarDB and QFXSystemBarDB.isCustomMicroMenuTimeAdj == true end,
        },
    },
}
