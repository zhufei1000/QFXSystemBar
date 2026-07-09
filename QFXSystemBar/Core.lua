local addonName, ns = ...
_G.QFXSystemBarNS = ns

-- ========================================================================
-- Localization
-- ========================================================================
ns.locales = ns.locales or {}
ns.L = setmetatable({}, { __index = function(_, key) return key end })

ns.supportedLocales = {
    "auto", "zhCN", "zhTW", "enUS", "deDE", "frFR", "esES", "esMX", "ptBR", "ruRU", "koKR", "itIT",
}

-- Some text can come from older QFX builds, saved button data, or Blizzard
-- native labels. Normalize those variants to canonical English source keys.
local localeKeyAliases = {
    -- Canonical button IDs and Blizzard/native names -> English source keys
    Character = "Character",
    Social = "Social",
    Friends = "Social",
    Profession = "Profession",
    Professions = "Profession",
    PlayerSpells = "Talents & Spells",
    ["Player Spells"] = "Talents & Spells",
    ["Talents & Spells"] = "Talents & Spells",
    Spellbook = "Spellbook",
    ["Spell Book"] = "Spellbook",
    Achievement = "Achievements",
    Achievements = "Achievements",
    QuestLog = "Quests",
    ["Quest Log"] = "Quests",
    Quests = "Quests",
    Time = "Time",
    Housing = "Housing",
    Hearthstone = "Hearthstone",
    Guild = "Guild",
    ["Guild / Communities"] = "Guild / Communities",
    ["Guild & Communities"] = "Guild / Communities",
    Communities = "Guild / Communities",
    LFD = "Group Finder",
    ["Group Finder"] = "Group Finder",
    ["Dungeon Finder"] = "Group Finder",
    MeetingStone = "MeetingStone",
    Collections = "Collections",
    Collection = "Collections",
    EJ = "Adventure Guide",
    ["Adventure Guide"] = "Adventure Guide",
    ["Encounter Journal"] = "Adventure Guide",
    ["Dungeon Journal"] = "Adventure Guide",
    Store = "Shop",
    Shop = "Shop",
    ["Blizzard Shop"] = "Blizzard Shop",
    Bags = "Bags",
    Bag = "Bags",
    Volume = "Volume",
    MainMenu = "Game Menu",
    ["Main Menu"] = "Game Menu",
    ["Game Menu"] = "Game Menu",
    Menu = "Menu",
}
ns.localeKeyAliases = localeKeyAliases

-- Canonical micro menu button IDs. SavedVariables must store these stable IDs,
-- never display labels.
local microMenuButtonIDAliases = {
    Character = "Character",
    Social = "Social",
    Friends = "Social",
    Profession = "Profession",
    Professions = "Profession",
    PlayerSpells = "PlayerSpells",
    ["Player Spells"] = "PlayerSpells",
    ["Talents & Spells"] = "PlayerSpells",
    Spellbook = "PlayerSpells",
    ["Spell Book"] = "PlayerSpells",
    Achievement = "Achievement",
    Achievements = "Achievement",
    QuestLog = "QuestLog",
    ["Quest Log"] = "QuestLog",
    Quests = "QuestLog",
    Time = "Time",
    Housing = "Housing",
    Hearthstone = "Hearthstone",
    Guild = "Guild",
    ["Guild / Communities"] = "Guild",
    ["Guild & Communities"] = "Guild",
    Communities = "Guild",
    LFD = "LFD",
    ["Group Finder"] = "LFD",
    ["Dungeon Finder"] = "LFD",
    MeetingStone = "MeetingStone",
    Collections = "Collections",
    Collection = "Collections",
    EJ = "EJ",
    ["Adventure Guide"] = "EJ",
    ["Encounter Journal"] = "EJ",
    ["Dungeon Journal"] = "EJ",
    Store = "Store",
    Shop = "Store",
    ["Blizzard Shop"] = "Store",
    Bags = "Bags",
    Bag = "Bags",
    Volume = "Volume",
    MainMenu = "MainMenu",
    ["Main Menu"] = "MainMenu",
    ["Game Menu"] = "MainMenu",
    Menu = "MainMenu",
}
ns.microMenuButtonIDAliases = microMenuButtonIDAliases

local microMenuSourceKeyToID = {
    Character = "Character",
    Social = "Social",
    Friends = "Social",
    Profession = "Profession",
    ["Talents & Spells"] = "PlayerSpells",
    Spellbook = "PlayerSpells",
    Achievements = "Achievement",
    Quests = "QuestLog",
    Time = "Time",
    Housing = "Housing",
    Hearthstone = "Hearthstone",
    Guild = "Guild",
    ["Guild / Communities"] = "Guild",
    ["Group Finder"] = "LFD",
    MeetingStone = "MeetingStone",
    Collections = "Collections",
    ["Adventure Guide"] = "EJ",
    Shop = "Store",
    ["Blizzard Shop"] = "Store",
    Bags = "Bags",
    Volume = "Volume",
    ["Game Menu"] = "MainMenu",
    Menu = "MainMenu",
}

local function RegisterReverseLocaleAliases(data)
    if type(data) ~= "table" then return end
    for sourceKey, translated in pairs(data) do
        if type(sourceKey) == "string" and type(translated) == "string" and translated ~= "" then
            -- If any old option object, cached row, or SavedVariables entry still
            -- contains a display label, normalize it back to the English source key.
            if localeKeyAliases[translated] == nil then
                localeKeyAliases[translated] = sourceKey
            end

            local buttonID = microMenuSourceKeyToID[sourceKey]
            if buttonID then
                microMenuButtonIDAliases[translated] = buttonID
            end
        end
    end
end

function ns.NormalizeMicroMenuButtonID(id)
    if type(id) ~= "string" then return nil end
    return microMenuButtonIDAliases[id] or id
end

local microMenuButtonLocaleKeys = {
    Character = "Character",
    Social = "Social",
    Profession = "Profession",
    PlayerSpells = "Talents & Spells",
    Achievement = "Achievements",
    QuestLog = "Quests",
    Time = "Time",
    Housing = "Housing",
    Hearthstone = "Hearthstone",
    Guild = "Guild / Communities",
    LFD = "Group Finder",
    MeetingStone = "MeetingStone",
    Collections = "Collections",
    EJ = "Adventure Guide",
    Store = "Shop",
    Bags = "Bags",
    Volume = "Volume",
    MainMenu = "Game Menu",
}
ns.microMenuButtonLocaleKeys = microMenuButtonLocaleKeys

function ns.GetMicroMenuButtonLocaleKey(id)
    id = ns.NormalizeMicroMenuButtonID(id)
    return id and microMenuButtonLocaleKeys[id] or id
end

function ns.NormalizeLocaleKey(key)
    if type(key) ~= "string" then return key end
    return localeKeyAliases[key] or key
end

local localeDisplayNames = {
    auto = "Automatic (Client Language)",
    zhCN = "Simplified Chinese",
    zhTW = "Traditional Chinese",
    enUS = "English",
    deDE = "German",
    frFR = "French",
    esES = "Spanish",
    esMX = "Latin American Spanish",
    ptBR = "Brazilian Portuguese",
    ruRU = "Russian",
    koKR = "Korean",
    itIT = "Italian",
}

local localeValueAliases = {
    ["Automatic (Client Language)"] = "auto",
    Auto = "auto",
    English = "enUS",
    enGB = "enUS",
}

for _, locale in ipairs(ns.supportedLocales) do
    localeValueAliases[locale] = locale
end

function ns.NormalizeLanguageValue(value)
    if type(value) ~= "string" then return "auto" end
    value = value:gsub("^%s+", ""):gsub("%s+$", "")
    if value == "" then return "auto" end

    local direct = localeValueAliases[value]
    if direct then return direct end

    local normalized = ns.NormalizeLocaleKey and ns.NormalizeLocaleKey(value) or value
    direct = localeValueAliases[normalized]
    if direct then return direct end

    return value
end

local englishOverrides = {
    ["Original Icons"] = "ElvUI Wind",
    ["Lightweight system bar popup settings UI"] = "Micro menu inspired by RoyMicroMenu; info bars inspired by NDUI",
    ["Credit Author Names"] = "RoyRong\nsiweia\nfang2hou",
    ["Icon & Clock Color Rule"] = "Color Style",
    ["Class Color: Icons and Clock"] = "Class Color: All",
    ["Original Icon Texture Color"] = "Original Colors",

    -- English UI is intentionally compact so the popup rows and info bars do
    -- not overflow on narrow layouts. These are display-only overrides: the
    -- canonical English keys above remain unchanged, so locale files and
    -- SavedVariables compatibility are not affected.
    ["Automatic (Client Language)"] = "Auto",
    ["Visibility & Language"] = "Display",
    ["Enable QFXSystemBar"] = "Enable QFX Bar",
    ["Top QFX Bar Visibility"] = "QFX Bar",
    ["Native Micro Menu Visibility"] = "Native Menu",
    ["Native Bag Bar Visibility"] = "Bag Bar",
    ["Mouseover Show Speed"] = "Show Speed",
    ["Mouseover Hide Speed"] = "Hide Speed",
    ["Always Show"] = "Show",
    ["Always Hide"] = "Hide",
    ["Show on Mouseover"] = "Mouseover",
    ["Show on Mouseover, Keep Shown in Combat"] = "Mouseover + Combat",
    ["Show Icons on Mouseover, Keep Clock Shown"] = "Icons Mouseover",

    ["Button Order & Visibility"] = "Buttons",
    ["Hearthstone Settings"] = "Hearthstone",
    ["Left Click Hearthstone"] = "Left Click",
    ["Middle Click Hearthstone"] = "Middle Click",
    ["Right Click Hearthstone"] = "Right Click",
    ["Talents & Spells"] = "Spells",
    ["Guild / Communities"] = "Guild",
    ["Group Finder"] = "Finder",
    ["Adventure Guide"] = "Guide",
    ["Game Menu"] = "Menu",

    ["Icon Settings"] = "Icons",
    ["Clock Settings"] = "Clock",
    ["Extra Text Settings"] = "Extra Text",
    ["Icon Custom Color"] = "Icon Custom",
    ["Clock Custom Color"] = "Clock Custom",
    ["Extra Text Color"] = "Text Color",
    ["Extra Text Custom Color"] = "Text Custom",
    ["Button Extra Text"] = "Extra Text",
    ["Character Button: Durability Number"] = "Char: Dura",
    ["Social Button: Online Friends"] = "Social: Friends",
    ["Guild Button: Online Guild Members"] = "Guild: Online",
    ["Bags Button: Free Bag Slots"] = "Bags: Free",
    ["Volume Button: Master Volume"] = "Volume: Master",
    ["Durability Text Color"] = "Dura Color",
    ["Friend Count Text Color"] = "Friends Color",
    ["Guild Count Text Color"] = "Guild Color",
    ["Bag Count Text Color"] = "Bag Color",
    ["Volume Text Color"] = "Vol Color",
    ["Enable Clock Text Settings"] = "Clock Text",
    ["Clock Source"] = "Source",
    ["Clock Format"] = "Format",
    ["Clock Font"] = "Font",
    ["Clock Font Size"] = "Font Size",
    ["Clock Text Outline"] = "Outline",
    ["Icon Button Size"] = "Icon Size",
    ["Position Controls"] = "Position",
    ["Unlock Dragging"] = "Unlock",
    ["Reset Position"] = "Reset Pos",
    ["Move Up"] = "Up",
    ["Move Down"] = "Down",
    ["Check to show. Use ↑ / ↓ to reorder."] = "Check to show. ↑/↓ reorder.",
    ["Unlock to drag the system bar directly. Arrow buttons nudge it by 1 pixel."] = "Unlock to drag. Arrows nudge 1 px.",
    ["Unlock to drag this info bar directly. Arrow buttons nudge it by 1 pixel."] = "Unlock to drag. Arrows nudge 1 px.",
    ["Max 5 shown. FPS includes latency without MS. Items are divided equally across the bar."] = "Max 5. FPS includes latency. Items split evenly.",

    ["Adjust the text size used by all info bars."] = "Adjust text size for all bars.",
    ["Adjust the shared background and class-line strength for all info bars. 0 hides the extra background, 50 keeps the default, and 100 makes it strongest."] = "Adjust shared bg/line strength.",
    ["Configure this info bar independently."] = "Configure this bar.",
    ["Show or hide this single info bar."] = "Show or hide this bar.",
    ["Show or hide this single info bar. It is disabled by default."] = "Show or hide this bar. Off by default.",
    ["Adjust this info bar width."] = "Adjust bar width.",
    ["Adjust this info bar height."] = "Adjust bar height.",
    ["Adjust this info bar class-colored line thickness."] = "Adjust class-line size.",
    ["Choose this info bar class-colored line visual style."] = "Choose class-line style.",
    ["Choose whether this info bar shows the class line on the top edge, bottom edge, both edges, or not at all."] = "Choose class-line position.",
    ["Choose whether this info bar background extends from the left side or the right side."] = "Choose gradient direction.",
    ["Unlock and drag this info bar, or nudge it by 1 pixel."] = "Unlock and drag, or nudge 1 px.",
    ["Checked items are shown. Each info bar can show up to 5 items. FPS includes latency without MS, so latency no longer takes a separate slot. Coordinates and Phase ID are optional items. Visible items are divided equally across the bar."] = "Checked items show. Max 5. FPS includes latency. Items split evenly.",
    ["One info bar can show up to %d items."] = "One bar can show up to %d items.",
    ["Unlocked. Drag the info bar to move it."] = "Unlocked. Drag the bar to move it.",
    ["Info bar position locked"] = "Bar position locked",
    ["Allows moving this info bar with the mouse."] = "Allows moving this bar with the mouse.",
    ["Show MeetingStone broker information on this info bar. It keeps MeetingStone's own click and hover behavior."] = "Show MeetingStone broker info on this bar.",
    ["Show MeetingStone broker information on the info bar."] = "Show MeetingStone broker info on the bar.",

    ["Info Bars"] = "Bars",
    ["Enable Info Bars"] = "Enable",
    ["Info Text Size"] = "Text Size",
    ["Background Strength"] = "Bg Strength",
    ["Left Info Bar"] = "Left",
    ["Right Info Bar"] = "Right",
    ["Left Top Info Bar"] = "Top Left",
    ["Left Bottom Info Bar"] = "Bottom Left",
    ["Right Bottom Info Bar"] = "Bottom Right",
    ["Enable Left Top Info Bar"] = "Top Left",
    ["Enable Left Bottom Info Bar"] = "Bottom Left",
    ["Enable Right Bottom Info Bar"] = "Bottom Right",
    ["Info Bar Width"] = "Width",
    ["Info Bar Height"] = "Height",
    ["Class Line Thickness"] = "Line Size",
    ["Class Line Style"] = "Line Style",
    ["Class Line Position"] = "Line Pos",
    ["Gradient Direction"] = "Gradient",
    ["Displayed Information"] = "Items",
    ["Left Gradient"] = "Left",
    ["Right Gradient"] = "Right",
    ["Bottom Line"] = "Bottom",
    ["Top Line"] = "Top",
    ["Top and Bottom Lines"] = "Both",
    ["No Class Line"] = "None",

    ["FPS / Latency"] = "FPS/MS",
    ["Advanced Combat Log"] = "ACL",
    ["Combat Log"] = "ACL",
    ["Location"] = "Zone",
    ["Coordinates"] = "Coords",
    ["Phase ID"] = "Phase",
    ["Specialization"] = "Spec",
    ["Item Level"] = "iLvl",
    ["Mythic+ Score"] = "M+",
    ["Score"] = "M+",
    ["Durability"] = "Dura",
    ["Muted"] = "Mute",
}
ns.englishOverrides = englishOverrides


-- Extra compact English copy.  Keep these as English-only display overrides so
-- zhCN/zhTW and other locale files continue using their existing translations.
local englishShortDescriptionOverrides = {
    -- Root / entry text
    ["Lightweight system bar popup settings UI"] = "Micro menu + bars",
    ["Micro menu inspired by RoyMicroMenu; info bars inspired by NDUI"] = "RoyMicroMenu / NDUI inspired",
    ["Open the QFXSystemBar popup settings window from here."] = "Open QFX settings.",
    ["Some icons are from ElvUI WindTools GameBar."] = "Icons: ElvUI WindTools",

    -- Main option names that still looked wide in English
    ["Interface Language"] = "Language",
    ["Button List"] = "Buttons",
    ["Icon Style"] = "Style",
    ["Icon Color"] = "Color",
    ["Icon Spacing"] = "Spacing",
    ["Clock Color"] = "Color",
    ["Clock Custom Color"] = "Custom",
    ["Clock Text Outline"] = "Outline",
    ["Default Font"] = "Default",
    ["Unit Name Font"] = "Unit Font",
    ["Damage Font"] = "Damage",
    ["Thin Outline"] = "Thin",
    ["Thick Outline"] = "Thick",
    ["Original Color"] = "Original",
    ["Custom Color"] = "Custom",
    ["Class Color"] = "Class",
    ["Local Time"] = "Local",
    ["Server Time"] = "Server",
    ["24-Hour"] = "24h",
    ["12-Hour"] = "12h",
    ["Reset Page"] = "Reset Page",
    ["Reset All"] = "Reset All",
    ["Changes apply immediately"] = "Applies now",
    ["Settings applied"] = "Applied",
    ["Button order updated"] = "Order updated",
    ["Position updated"] = "Position saved",
    ["Position reset"] = "Position reset",
    ["Current page defaults restored"] = "Page reset",
    ["All defaults restored"] = "All reset",
    ["Drag to move QFXSystemBar"] = "Drag QFX bar",

    -- Display page descriptions
    ["Set the interface language and choose how QFXSystemBar, the native micro menu, and the native bag bar are displayed."] = "Language and bar display.",
    ["Defaults to the client language. You can force a specific language. The settings window refreshes immediately after switching."] = "Auto uses client language.",
    ["Show the custom QFXSystemBar system bar."] = "Show QFX bar.",
    ["Always show the QFX bar, hide it, or show it only while the mouse is over the bar."] = "Show, hide, or mouseover.",
    ["Choose whether Blizzard's original micro menu is always shown, hidden, or shown only on mouseover."] = "Native micro menu display.",
    ["Choose whether Blizzard's original bag bar is always shown, hidden, or shown only on mouseover."] = "Native bag bar display.",
    ["How quickly mouseover-hidden bars become fully visible after the mouse enters."] = "Fade in speed.",
    ["How quickly mouseover-hidden bars hide again after the mouse leaves."] = "Fade out speed.",

    -- Button / hearthstone descriptions
    ["Toggle visibility and use the up/down arrows to adjust button order on the system bar."] = "Show buttons and reorder.",
    ["Checked buttons are shown on the system bar. Use the arrows on the right to adjust order."] = "Checked = shown. Arrows reorder.",
    ["Choose which hearthstone item each mouse button uses."] = "Set Hearthstone clicks.",
    ["Choose the hearthstone used by left-clicking the Hearthstone button."] = "Left-click Hearthstone.",
    ["Choose the hearthstone used by middle-clicking the Hearthstone button."] = "Middle-click Hearthstone.",
    ["Choose the hearthstone used by right-clicking the Hearthstone button."] = "Right-click Hearthstone.",
    ["Show the character info button."] = "Show Character.",
    ["Show the social button."] = "Show Social.",
    ["Show the profession button."] = "Show Profession.",
    ["Show the talents and spellbook button."] = "Show Spells.",
    ["Show the achievements button."] = "Show Achievements.",
    ["Show the quest log button."] = "Show Quests.",
    ["Show the time button."] = "Show Time.",
    ["Show the housing button."] = "Show Housing.",
    ["Show the guild and communities button."] = "Show Guild.",
    ["Show the group finder button."] = "Show Finder.",
    ["Show the collections button."] = "Show Collections.",
    ["Show the adventure guide button."] = "Show Guide.",
    ["Show the shop button."] = "Show Shop.",
    ["Show the bags button."] = "Show Bags.",
    ["Show the volume button."] = "Show Volume.",
    ["Show the game menu button."] = "Show Menu.",
    ["Show the MeetingStone button."] = "Show MeetingStone.",
    ["Show the hearthstone button."] = "Show Hearthstone.",

    -- Appearance descriptions
    ["Appearance options are split into icon settings, clock settings, and extra text settings."] = "Icon, clock, and text options.",
    ["Configure micro menu icon style, icon coloring, button size, and button spacing."] = "Icon style, color, size, spacing.",
    ["Configure the top micro menu clock source, color, format, font, size, and outline."] = "Clock source, color, font, size.",
    ["Configure the small numbers shown on supported micro menu buttons, such as durability, friends, guild members, free bag slots, and volume."] = "Small button counters.",
    ["Choose which icon set is used by the top micro menu."] = "Choose icon set.",
    ["Choose how the micro menu icons are colored."] = "Icon color mode.",
    ["Choose the custom color used by micro menu icons."] = "Custom icon color.",
    ["Choose how the clock text is colored."] = "Clock color mode.",
    ["Choose the custom color used by the clock text."] = "Custom clock color.",
    ["Choose how the button extra text is colored."] = "Counter color mode.",
    ["Choose the custom color used by button extra text."] = "Custom counter color.",
    ["Choose which button extra counters are shown. Checked items are shown; unchecked items are hidden."] = "Checked counters show.",
    ["Show the equipped durability number on the Character button."] = "Show durability number.",
    ["Show the online friend count on the Social button."] = "Show friend count.",
    ["Show the online guild member count on the Guild button."] = "Show guild count.",
    ["Show the free bag slot count on the Bags button."] = "Show free bag slots.",
    ["Show the master volume number on the Volume button while hovering."] = "Show volume on hover.",
    ["Show the master volume number on the Volume button."] = "Show volume number.",
    ["Choose the durability number text color."] = "Durability text color.",
    ["Choose the online friend count text color."] = "Friend text color.",
    ["Choose the online guild member count text color."] = "Guild text color.",
    ["Choose the free bag slot count text color."] = "Bag text color.",
    ["Choose the master volume number text color."] = "Volume text color.",
    ["Controls the color of the small extra text shown at the bottom-right of supported buttons."] = "Counter text color.",
    ["Allows changing the clock source, format, font size, and outline."] = "Enable clock text options.",
    ["Choose whether the clock uses local time or server time."] = "Local or server time.",
    ["Choose 24-hour or 12-hour clock display."] = "24h or 12h display.",
    ["Choose the font used by the top micro menu clock."] = "Clock font.",
    ["Adjust the top micro menu clock text size."] = "Clock text size.",
    ["Adjust the top micro menu clock text outline."] = "Clock outline.",
    ["Adjust the size of each top micro menu icon button."] = "Icon button size.",
    ["Adjust the spacing between top micro menu icon buttons."] = "Icon spacing.",

    -- Position descriptions
    ["Unlock and drag the system bar, or use arrow buttons for fine positioning."] = "Drag or nudge the bar.",
    ["After unlocking, drag the system bar directly. Arrow buttons move it by 1 pixel."] = "Unlock to drag. Arrows = 1 px.",
    ["Allows moving QFXSystemBar with the mouse."] = "Allow mouse drag.",
    ["Unlocked. Drag the system bar to move it."] = "Unlocked. Drag to move.",
    ["Cannot move position in combat."] = "Can't move in combat.",
    ["Unavailable in combat. Please try again after combat ends."] = "Unavailable in combat.",

    -- Info bar descriptions
    ["QFX modular info strips with editable visibility, order, position, size, and background direction."] = "Modular info bars.",
    ["Show the QFX info strips. Each strip only builds and loads its own textures after it is enabled."] = "Enable QFX info bars.",
    ["Adjust the text size used by all info bars."] = "Text size for all bars.",
    ["Adjust the shared background and class-line strength for all info bars. 0 hides the extra background, 50 keeps the default, and 100 makes it strongest."] = "Shared bg/line strength.",
    ["Configure this info bar independently."] = "Configure this bar.",
    ["Configure this info bar independently. This strip is disabled by default and must be enabled manually."] = "Configure this bar. Off by default.",
    ["Show or hide this single info bar."] = "Show or hide this bar.",
    ["Show or hide this single info bar. It is disabled by default."] = "Show/hide. Off by default.",
    ["Adjust this info bar width."] = "Bar width.",
    ["Adjust this info bar height."] = "Bar height.",
    ["Adjust this info bar class-colored line thickness."] = "Class-line size.",
    ["Choose this info bar class-colored line visual style."] = "Class-line style.",
    ["Choose whether this info bar shows the class line on the top edge, bottom edge, both edges, or not at all."] = "Class-line position.",
    ["Choose whether this info bar background extends from the left side or the right side."] = "Gradient direction.",
    ["Unlock and drag this info bar, or nudge it by 1 pixel."] = "Drag or nudge 1 px.",
    ["Checked items are shown. Each info bar can show up to 5 items. FPS includes latency without MS, so latency no longer takes a separate slot. Coordinates and Phase ID are optional items. Visible items are divided equally across the bar."] = "Checked = shown. Max 5. FPS includes latency.",
    ["Max 5 shown. FPS includes latency without MS. Items are divided equally across the bar."] = "Max 5. FPS includes latency.",
    ["One info bar can show up to %d items."] = "Max %d items per bar.",
    ["One bar can show up to %d items."] = "Max %d items per bar.",
    ["Unlocked. Drag the info bar to move it."] = "Unlocked. Drag to move.",
    ["Info bar position locked"] = "Bar locked",
    ["Allows moving this info bar with the mouse."] = "Allow mouse drag.",
    ["Show MeetingStone broker information on this info bar. It keeps MeetingStone's own click and hover behavior."] = "MeetingStone broker info.",
    ["Show MeetingStone broker information on the info bar."] = "MeetingStone broker info.",

    -- Info item descriptions / tooltips
    ["Show online guild members."] = "Show guild online.",
    ["Show online Battle.net and character friends."] = "Show online friends.",
    ["Show framerate and latency together. Tooltip shows addon memory and latency details."] = "Show FPS and latency.",
    ["Show Advanced Combat Logging state. Left click turns it on. Right click turns it off."] = "ACL. Left on, right off.",
    ["Show current zone and coordinates tooltip."] = "Show zone and coords.",
    ["Show player coordinates. Left click opens the world map. Right click creates a waypoint at your current position."] = "Coords. Left map, right waypoint.",
    ["Show the current map or instance ID as the available phase-style identifier."] = "Show map/instance ID.",
    ["Left click opens talents. Right click changes loot specialization."] = "Left talents, right loot spec.",
    ["Show equipped item level."] = "Show equipped iLvl.",
    ["Show current Mythic+ rating."] = "Show M+ score.",
    ["Show equipped durability."] = "Show durability.",
    ["Show current money. Right click toggles free bag slots."] = "Gold. Right toggles bag slots.",
    ["Show master volume. Left click opens a volume slider. Right click toggles mute."] = "Volume. Left slider, right mute.",
    ["Show time. Left click opens calendar."] = "Time. Left opens calendar.",
    ["CPU profiling requires a UI reload to fully apply."] = "CPU profiling needs /reload.",
    ["Current coordinates are unavailable."] = "Coords unavailable.",
    ["Waypoint link created, but the map pin API is unavailable."] = "Waypoint link created; pin API unavailable.",
    ["MeetingStone is not loaded."] = "MeetingStone not loaded.",
    ["Enabling the MeetingStone button will hide MeetingStone's floating window. Continue?"] = "Hide MeetingStone floating window?",

    -- Short labels used inside info bars / tooltips
    ["Advanced Combat Log"] = "ACL",
    ["Home Latency"] = "Home MS",
    ["World Latency"] = "World MS",
    ["Collect Memory"] = "Clean Mem",
    ["CPU / Memory"] = "CPU/Mem",
    ["CPU Usage"] = "CPU",
    ["Create Waypoint"] = "Waypoint",
    ["Loot Specialization"] = "Loot Spec",
    ["Change Loot Specialization"] = "Change Loot",
    ["Master Volume"] = "Volume",
    ["My Position"] = "My Pos",
    ["Shown ID"] = "ID",
    ["Instance ID"] = "Instance",
    ["Map ID"] = "Map",
    ["World Map"] = "Map",
    ["Latency"] = "MS",
    ["Applications"] = "Apps",
    ["Left Click: Open Calendar"] = "Left: Calendar",
    ["Right Click: Clean Memory"] = "Right: Clean Mem",
    ["Left Click: Volume Up"] = "Left: Vol +",
    ["Right Click: Volume Down"] = "Right: Vol -",
}
for key, value in pairs(englishShortDescriptionOverrides) do
    englishOverrides[key] = value
end

local function CopyMap(src)
    local out = {}
    for key, value in pairs(src or {}) do
        out[key] = value
    end
    return out
end

local baseLocaleKeyAliases = CopyMap(localeKeyAliases)
local baseMicroMenuButtonIDAliases = CopyMap(microMenuButtonIDAliases)

local function ResetLocaleAliases()
    wipe(localeKeyAliases)
    for key, value in pairs(baseLocaleKeyAliases) do
        localeKeyAliases[key] = value
    end
    wipe(microMenuButtonIDAliases)
    for key, value in pairs(baseMicroMenuButtonIDAliases) do
        microMenuButtonIDAliases[key] = value
    end
end

function ns.RegisterLocale(locale, data)
    if not locale or type(data) ~= "table" then return end
    ns.locales[locale] = data
end

local function GetSavedLanguage()
    local db = rawget(_G, "QFXSystemBarDB")
    local value = db and db.language
    if type(value) ~= "string" or value == "" then value = "auto" end
    return (ns.NormalizeLanguageValue and ns.NormalizeLanguageValue(value)) or value
end

local function LoadOptionalAddOn(name)
    if type(name) ~= "string" or name == "" then return false end
    if C_AddOns and C_AddOns.IsAddOnLoaded then
        local ok, loaded = pcall(C_AddOns.IsAddOnLoaded, name)
        if ok and loaded then return true end
    elseif IsAddOnLoaded then
        local ok, loaded = pcall(IsAddOnLoaded, name)
        if ok and loaded then return true end
    end

    local ok, loaded
    if C_AddOns and C_AddOns.LoadAddOn then
        ok, loaded = pcall(C_AddOns.LoadAddOn, name)
    elseif LoadAddOn then
        ok, loaded = pcall(LoadAddOn, name)
    end
    return ok and loaded ~= false
end
ns.LoadOptionalAddOn = LoadOptionalAddOn

function ns.EnsureLocaleLoaded(locale)
    if locale == "enGB" then locale = "enUS" end
    if not locale or locale == "auto" then locale = (GetLocale and GetLocale()) or "enUS" end
    if ns.locales[locale] then return true end
    if locale == "enUS" then return false end
    LoadOptionalAddOn("QFXSystemBar_Locale_" .. locale)
    return ns.locales[locale] ~= nil
end

function ns.ResolveLocale(value)
    local locale = ns.NormalizeLanguageValue and ns.NormalizeLanguageValue(value) or value
    if not locale or locale == "auto" then
        locale = (GetLocale and GetLocale()) or "enUS"
    end
    if locale == "enGB" then locale = "enUS" end
    if ns.EnsureLocaleLoaded then ns.EnsureLocaleLoaded(locale) end
    if not ns.locales[locale] then locale = "enUS" end
    return locale
end

function ns.IsEnglishLocaleActive()
    local current = ns.currentLocale
    if current == "enUS" or current == "enGB" then return true end

    local saved = rawget(_G, "QFXSystemBarDB") and rawget(_G, "QFXSystemBarDB").language
    saved = (ns.NormalizeLanguageValue and ns.NormalizeLanguageValue(saved)) or saved
    return saved == "enUS" or saved == "enGB"
end

local function EnglishSourceText(key)
    if key == nil then return "" end
    if type(key) ~= "string" then return tostring(key) end
    local normalized = ns.NormalizeLocaleKey and ns.NormalizeLocaleKey(key) or key
    local english = ns.englishOverrides or {}
    return english[normalized] or english[key] or normalized or key
end
ns.GetEnglishSourceText = EnglishSourceText

function ns.ApplyLocale(value)
    local resolved = ns.ResolveLocale(value or GetSavedLanguage())
    if ns.EnsureLocaleLoaded then ns.EnsureLocaleLoaded(resolved) end
    local selected = ns.locales[resolved] or {}
    local english = ns.englishOverrides or {}
    local isEnglish = resolved == "enUS" or resolved == "enGB"

    ResetLocaleAliases()
    if not isEnglish then
        RegisterReverseLocaleAliases(english)
        RegisterReverseLocaleAliases(selected)
    end

    ns.currentLocale = resolved
    ns.L = setmetatable({}, {
        __index = function(_, key)
            if key == nil then return "" end
            if type(key) ~= "string" then return tostring(key) end

            -- Always normalize first. Render code may pass an old localized
            -- label, a Blizzard label, or an old SavedVariables value; convert
            -- it back to the English source key before translating.
            local normalized = ns.NormalizeLocaleKey and ns.NormalizeLocaleKey(key) or key

            if resolved == "enUS" then
                return english[normalized] or english[key] or normalized or key
            end

            local v = selected[normalized]
            if v ~= nil then return v end
            v = selected[key]
            if v ~= nil then return v end
            v = english[normalized]
            if v ~= nil then return v end
            v = english[key]
            if v ~= nil then return v end
            return normalized or key
        end,
    })
    return resolved
end

function ns.T(key)
    if key == nil then return "" end
    if type(key) ~= "string" then return tostring(key) end
    if ns.IsEnglishLocaleActive and ns.IsEnglishLocaleActive() then
        return EnglishSourceText(key)
    end
    local L = ns.L
    if L then return L[key] end
    return EnglishSourceText(key)
end

function ns.GetLanguageOptions()
    local data = {}
    for _, locale in ipairs(ns.supportedLocales) do
        local name = localeDisplayNames[locale] or locale
        data[#data + 1] = { value = locale, textKey = name }
    end
    return data
end

function ns.RefreshLocaleSensitiveUI()
    if ns.RefreshRegisteredUIText then ns.RefreshRegisteredUIText() end
    if ns.RefreshAddonOptionsEntryLocalization then ns.RefreshAddonOptionsEntryLocalization() end
    if ns.RefreshConfigLocalization then ns.RefreshConfigLocalization() end
    if ns.RefreshMicroMenuLocalization then ns.RefreshMicroMenuLocalization() end
    if ns.InfoBarLoaded and ns.RefreshInfoBars then ns.RefreshInfoBars() end
end

function ns.SetLanguage(value)
    QFXSystemBarDB = QFXSystemBarDB or {}
    QFXSystemBarDB.language = (ns.NormalizeLanguageValue and ns.NormalizeLanguageValue(value)) or value or "auto"
    ns.ApplyLocale(QFXSystemBarDB.language)
    if ns.MigrateLocalizedSavedVariables then ns.MigrateLocalizedSavedVariables(QFXSystemBarDB) end
    if ns.RefreshLocaleSensitiveUI then ns.RefreshLocaleSensitiveUI() end
    print("|cFF33FF99QFX|r - |cFFFFD100" .. ((ns.L and ns.L["Language changed."]) or "Language changed.") .. "|r")
end

function ns.OnLanguageChanged(value)
    ns.SetLanguage(value)
end


-- ========================================================================
-- SavedVariables display-label migration
-- ========================================================================
local function NormalizeStringKey(value)
    if type(value) ~= "string" then return value end
    if ns.NormalizeLocaleKey then return ns.NormalizeLocaleKey(value) end
    return value
end

local function NormalizeBooleanKeyMap(map, normalizer)
    if type(map) ~= "table" or type(normalizer) ~= "function" then return end
    local updates = nil
    for key, value in pairs(map) do
        if type(key) == "string" then
            local normalized = normalizer(key)
            if type(normalized) == "string" and normalized ~= "" and normalized ~= key then
                updates = updates or {}
                updates[key] = normalized
            end
        end
    end
    if updates then
        for oldKey, newKey in pairs(updates) do
            if map[newKey] == nil then map[newKey] = map[oldKey] end
            map[oldKey] = nil
        end
    end
end

local function NormalizeArrayInPlace(list, normalizer, valid)
    if type(list) ~= "table" or type(normalizer) ~= "function" then return false end
    local seen, out, changed = {}, {}, false
    for _, value in ipairs(list) do
        local normalized = normalizer(value)
        if type(normalized) == "string" and normalized ~= "" and (not valid or valid[normalized]) and not seen[normalized] then
            out[#out + 1] = normalized
            seen[normalized] = true
            if normalized ~= value then changed = true end
        else
            changed = true
        end
    end
    if changed or #out ~= #list then
        wipe(list)
        for i, value in ipairs(out) do list[i] = value end
        return true
    end
    return false
end

function ns.MigrateLocalizedSavedVariables(db)
    if type(db) ~= "table" then return end

    -- Button order: old builds could store localized button labels. Convert them
    -- back to stable button IDs before any renderer reads the order.
    if type(db.customMicroMenuButtonOrder) == "table" then
        local validButtons = {}
        for _, id in ipairs(ns.defaultMicroMenuButtonOrder or {}) do validButtons[id] = true end
        for _, def in ipairs(ns.QFXMicroMenuDefinitions or ns.MicroMenuButtonDefs or {}) do
            if def and def.id then validButtons[def.id] = true end
        end
        NormalizeArrayInPlace(db.customMicroMenuButtonOrder, function(value)
            if ns.NormalizeMicroMenuButtonID then return ns.NormalizeMicroMenuButtonID(value) end
            return NormalizeStringKey(value)
        end, validButtons)
    end

    -- Old multi-select/badge maps should use internal keys, never display text.
    local badgeKeyBySource = {
        ["Durability"] = "durability",
        ["Friends"] = "friends",
        ["Social"] = "friends",
        ["Guild"] = "guild",
        ["Bags"] = "bags",
        ["Bag"] = "bags",
        ["Volume"] = "volume",
        ["Master Volume"] = "volume",
    }
    NormalizeBooleanKeyMap(db.customMicroMenuBadgeDisplay, function(value)
        local normalized = NormalizeStringKey(value)
        return badgeKeyBySource[normalized] or normalized
    end)

    -- Info bar content orders and enabled maps are normalized by the InfoBar
    -- module when it is loaded. Call it here when available so the config UI
    -- also sees stable IDs immediately.
    if ns.MigrateInfoBarSavedVariables then ns.MigrateInfoBarSavedVariables(db) end
end

-- ========================================================================
-- SavedVariables initialization
-- ========================================================================
local function MergeDefaults(target, source)
    for key, value in pairs(source) do
        if type(value) == "table" then
            if type(target[key]) ~= "table" then target[key] = {} end
            MergeDefaults(target[key], value)
        elseif target[key] == nil then
            target[key] = value
        end
    end
end

function ns.EnsureInfoBarLoaded()
    if not ns.InfoBarLoaded then
        LoadOptionalAddOn("QFXSystemBar_InfoBar")
    end
    if ns.InfoBarLoaded then
        if ns.InitializeInfoBar then
            ns.InitializeInfoBar()
        elseif ns.QueueInfoBarRefresh then
            ns.QueueInfoBarRefresh()
        elseif ns.RefreshInfoBars then
            ns.RefreshInfoBars()
        end
        return true
    end
    return false
end

function ns.EnsureConfigLoaded()
    if ns.ConfigLoaded then return true end
    LoadOptionalAddOn("QFXSystemBar_Config")
    return ns.ConfigLoaded == true
end

local function OpenConfig()
    if ns.EnsureConfigLoaded then ns.EnsureConfigLoaded() end
    if ns.OpenConfigFrame then
        ns.OpenConfigFrame()
    elseif ns.ToggleConfigFrame then
        ns.ToggleConfigFrame()
    end
end

function QFXSystemBar_OpenConfig()
    OpenConfig()
end

local addonOptionsEntryRefs = {}

local function GetAddonOptionsDisplayName()
    return (ns.T and ns.T("QFXSystemBar")) or "QFXSystemBar"
end

function ns.RefreshAddonOptionsEntryLocalization()
    local refs = addonOptionsEntryRefs
    local displayName = GetAddonOptionsDisplayName()
    if refs.panel then refs.panel.name = displayName end
    if refs.category then
        refs.category.name = displayName
        if refs.category.SetName then refs.category:SetName(displayName) end
    end
    if ns.SetUIText then
        if refs.title then ns.SetUIText(refs.title, "QFXSystemBar") end
        if refs.desc then ns.SetUIText(refs.desc, "Open the QFXSystemBar popup settings window from here.") end
        if refs.button then ns.SetUIText(refs.button, "Open Settings") end
    else
        if refs.title then refs.title:SetText((ns.T and ns.T("QFXSystemBar")) or "QFXSystemBar") end
        if refs.desc then refs.desc:SetText((ns.T and ns.T("Open the QFXSystemBar popup settings window from here.")) or "Open the QFXSystemBar popup settings window from here.") end
        if refs.button then refs.button:SetText((ns.T and ns.T("Open Settings")) or "Open Settings") end
    end
end

local function RegisterAddonOptionsEntry()
    if not Settings or not Settings.RegisterCanvasLayoutCategory or not Settings.RegisterAddOnCategory then return end
    if _G.QFXSystemBarOptionsEntryFrame then
        ns.RefreshAddonOptionsEntryLocalization()
        return
    end

    local panel = CreateFrame("Frame", "QFXSystemBarOptionsEntryFrame")
    addonOptionsEntryRefs.panel = panel
    panel.name = GetAddonOptionsDisplayName()

    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    addonOptionsEntryRefs.title = title

    local desc = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)
    desc:SetPoint("RIGHT", -24, 0)
    desc:SetJustifyH("LEFT")
    addonOptionsEntryRefs.desc = desc

    local button = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    button:SetSize(180, 28)
    button:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -16)
    button:SetScript("OnClick", OpenConfig)
    addonOptionsEntryRefs.button = button

    ns.RefreshAddonOptionsEntryLocalization()

    local category = Settings.RegisterCanvasLayoutCategory(panel, GetAddonOptionsDisplayName())
    if category then
        category.ID = "QFXSystemBar"
        addonOptionsEntryRefs.category = category
        Settings.RegisterAddOnCategory(category)
    end
end

EventUtil.ContinueOnAddOnLoaded(addonName, function()
    QFXSystemBarDB = QFXSystemBarDB or {}
    -- Apply locale first so supplemental reverse aliases are available before
    -- migrating old localized display labels from SavedVariables.
    if ns.ApplyLocale then
        ns.ApplyLocale(QFXSystemBarDB.language)
    end
    if ns.MigrateLocalizedSavedVariables then ns.MigrateLocalizedSavedVariables(QFXSystemBarDB) end
    if ns.MigrateBadgeDisplaySettings then ns.MigrateBadgeDisplaySettings(QFXSystemBarDB) end
    if ns.MigrateMicroMenuColorSettings then ns.MigrateMicroMenuColorSettings(QFXSystemBarDB) end
    if ns.defaults then
        MergeDefaults(QFXSystemBarDB, ns.defaults)
    end
    if QFXSystemBarDB.isInfoBar == true and ns.EnsureInfoBarLoaded then
        ns.EnsureInfoBarLoaded()
    end

    SLASH_QFXSYSTEMBAR1 = "/qfxbar"
    SLASH_QFXSYSTEMBAR2 = "/qsb"
    SlashCmdList.QFXSYSTEMBAR = function()
        OpenConfig()
    end

    RegisterAddonOptionsEntry()
end)

if EventUtil and EventUtil.ContinueOnPlayerLogin then
    EventUtil.ContinueOnPlayerLogin(RegisterAddonOptionsEntry)
end
