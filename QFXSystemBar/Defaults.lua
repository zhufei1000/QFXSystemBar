local addonName, ns = ...

-- ========================================================================
-- QFXSystemBar default settings
-- All initial SavedVariables defaults are centralized here.
-- ========================================================================
local function CopyArray(src)
    local out = {}
    for i, v in ipairs(src or {}) do
        out[i] = v
    end
    return out
end

ns.defaultMicroMenuButtonOrder = {
    "Character",
    "Social",
    "Profession",
    "PlayerSpells",
    "Achievement",
    "QuestLog",
    "Time",
    "Housing",
    "Guild",
    "LFD",
    "Collections",
    "EJ",
    "Store",
    "Bags",
    "Volume",
    "MainMenu",
    "MeetingStone",
    "Hearthstone",
}
ns.defaultMicroMenuButtonEnabled = {
    Character = true,
    Social = true,
    Profession = false,
    PlayerSpells = true,
    Achievement = true,
    QuestLog = true,
    Time = true,
    Housing = false,
    Hearthstone = true,
    Guild = true,
    LFD = true,
    MeetingStone = false,
    Collections = true,
    EJ = true,
    Store = false,
    Bags = false,
    Volume = false,
    MainMenu = false,
}

-- Button extra text visibility settings. Stable DB keys are separate boolean
-- options now, so the Appearance page can show native checkboxes instead of a
-- multi-select dropdown. The old customMicroMenuBadgeDisplay table is migrated
-- below for existing users.
ns.microMenuBadgeSettingByKey = {
    durability = "customMicroMenuShowDurabilityBadge",
    friends = "customMicroMenuShowFriendBadge",
    guild = "customMicroMenuShowGuildBadge",
    bags = "customMicroMenuShowBagBadge",
    volume = "customMicroMenuShowVolumeBadge",
}

ns.microMenuBadgeColorSettingByKey = {
    durability = "customMicroMenuDurabilityBadgeColor",
    friends = "customMicroMenuFriendBadgeColor",
    guild = "customMicroMenuGuildBadgeColor",
    bags = "customMicroMenuBagBadgeColor",
    volume = "customMicroMenuVolumeBadgeColor",
}

function ns.MigrateBadgeDisplaySettings(db)
    if type(db) ~= "table" then return end

    -- Safe micro-menu migration rule:
    -- only fill missing compatibility fields; never force-change existing users'
    -- visible button toggles, order, position, size, colors or click actions.
    local hasExistingMicroMenuConfig = db.isCustomMicroMenu ~= nil
        or db.customMicroMenuButtonOrder ~= nil
        or db.isCustomMicroMenuCharacter ~= nil
        or db.isCustomMicroMenuBags ~= nil

    -- If an older SavedVariables file did not know about optional newly added
    -- utility buttons, keep them hidden for that existing user. Fresh installs
    -- still receive the current defaults from ns.defaults below.
    if hasExistingMicroMenuConfig then
        if db.isCustomMicroMenuMeetingStone == nil then db.isCustomMicroMenuMeetingStone = false end
        if db.isCustomMicroMenuHearthstone == nil then db.isCustomMicroMenuHearthstone = false end
        if db.isCustomMicroMenuVolume == nil then db.isCustomMicroMenuVolume = false end
    end

    local display = db.customMicroMenuBadgeDisplay
    if type(display) == "table" then
        local map = ns.microMenuBadgeSettingByKey or {}
        for badgeKey, settingKey in pairs(map) do
            if db[settingKey] == nil then
                -- Old SavedVariables did not know about the Volume badge.
                -- Leave it nil so the current default decides it when the
                -- hidden-by-default Volume button is manually enabled.
                if badgeKey == "volume" and display[badgeKey] == nil then
                    -- keep default
                else
                    db[settingKey] = display[badgeKey] and true or false
                end
            end
        end
    end

    -- 1.7.32 split the old shared extra-text color into one color per
    -- supported counter. Existing users keep their previous shared color as
    -- the initial value for each new per-counter color.
    local oldColor = type(db.customMicroMenuBadgeTextColor) == "string" and db.customMicroMenuBadgeTextColor or nil
    if oldColor then
        local colorMap = ns.microMenuBadgeColorSettingByKey or {}
        for _, colorKey in pairs(colorMap) do
            if db[colorKey] == nil then
                db[colorKey] = oldColor
            end
        end
    end
end


-- Info Bar defaults are centralized here too so a fresh SavedVariables file
-- receives explicit false values before any UI refresh logic runs.
ns.defaults = ns.defaults or {}
ns.defaults.isInfoBar = false
ns.defaults.infoBarLeftEnabled = true
ns.defaults.infoBarLeftBottomEnabled = false
ns.defaults.infoBarRightEnabled = true

function ns.GetDefaultMicroMenuButtonOrder()
    return CopyArray(ns.defaultMicroMenuButtonOrder)
end

-- Hearthstone button actions.
-- Values are stable IDs saved in SavedVariables; display labels are English
-- source fallbacks and may be replaced by localized item names from the client.
ns.HEARTHSTONE_RANDOM_VALUE = "random"
ns.HEARTHSTONE_RANDOM_REFRESH_GLOBAL = "QFXSystemBar_RandomHearthstoneRefresh"

-- Items that should remain selectable directly, but should not be picked by
-- the random hearthstone action. These are utility hearthstones rather than
-- cosmetic hearthstone toys.
ns.randomHearthstoneExcludedItemIDs = {
    [6948] = true, -- Hearthstone
    [110560] = true, -- Garrison Hearthstone
    [140192] = true, -- Dalaran Hearthstone
    [253629] = true, -- Personal Key to the Arcantina

    -- Engineering wormholes are available as direct click actions, but are
    -- intentionally excluded from the cosmetic random hearthstone pool.
    [18984] = true, -- Dimensional Ripper - Everlook
    [18986] = true, -- Ultrasafe Transporter: Gadgetzan
    [30542] = true, -- Dimensional Ripper - Area 52
    [30544] = true, -- Ultrasafe Transporter: Toshley's Station
    [48933] = true, -- Wormhole Generator: Northrend
    [87215] = true, -- Wormhole Generator: Pandaria
    [112059] = true, -- Wormhole Centrifuge
    [132517] = true, -- Intra-Dalaran Wormhole Generator
    [132524] = true, -- Reaves Module: Wormhole Generator Mode
    [151652] = true, -- Wormhole Generator: Argus
    [168807] = true, -- Wormhole Generator: Kul Tiras
    [168808] = true, -- Wormhole Generator: Zandalar
    [172924] = true, -- Wormhole Generator: Shadowlands
    [198156] = true, -- Wyrmhole Generator: Dragon Isles
    [221966] = true, -- Wormhole Generator: Khaz Algar
    [248485] = true, -- Wormhole Generator: Quel'Thalas
}

ns.hearthstoneActionList = {
    { value = "none", textKey = "No Action" },
    { value = ns.HEARTHSTONE_RANDOM_VALUE, textKey = "Random Hearthstone", isRandom = true },
    { value = "6948", textKey = "Hearthstone", itemID = 6948 },
    { value = "140192", textKey = "Dalaran Hearthstone", itemID = 140192 },
    { value = "110560", textKey = "Garrison Hearthstone", itemID = 110560 },
    { value = "253629", textKey = "P.O.S.T. Master's Express Hearthstone", itemID = 253629 },

    -- Hearthstone toys
    { value = "54452", textKey = "Ethereal Portal", itemID = 54452 },
    { value = "64488", textKey = "The Innkeeper's Daughter", itemID = 64488 },
    { value = "93672", textKey = "Dark Portal", itemID = 93672 },
    { value = "142542", textKey = "Tome of Town Portal", itemID = 142542 },
    { value = "162973", textKey = "Greatfather Winter's Hearthstone", itemID = 162973 },
    { value = "163045", textKey = "Headless Horseman's Hearthstone", itemID = 163045 },
    { value = "165669", textKey = "Lunar Elder's Hearthstone", itemID = 165669 },
    { value = "165670", textKey = "Peddlefeet's Lovely Hearthstone", itemID = 165670 },
    { value = "165802", textKey = "Noble Gardener's Hearthstone", itemID = 165802 },
    { value = "166746", textKey = "Fire Eater's Hearthstone", itemID = 166746 },
    { value = "166747", textKey = "Brewfest Reveler's Hearthstone", itemID = 166747 },
    { value = "168907", textKey = "Holographic Digitalization Hearthstone", itemID = 168907 },
    { value = "172179", textKey = "Eternal Traveler's Hearthstone", itemID = 172179 },
    { value = "180290", textKey = "Night Fae Hearthstone", itemID = 180290 },
    { value = "182773", textKey = "Necrolord Hearthstone", itemID = 182773 },
    { value = "183716", textKey = "Venthyr Sinstone", itemID = 183716 },
    { value = "184353", textKey = "Kyrian Hearthstone", itemID = 184353 },
    { value = "188952", textKey = "Dominated Hearthstone", itemID = 188952 },
    { value = "190196", textKey = "Enlightened Hearthstone", itemID = 190196 },
    { value = "193588", textKey = "Timewalker's Hearthstone", itemID = 193588 },
    { value = "200630", textKey = "Ohn'ir Windsage's Hearthstone", itemID = 200630 },
    { value = "206195", textKey = "Path of the Naaru", itemID = 206195 },
    { value = "208704", textKey = "Deepdweller's Earthen Hearthstone", itemID = 208704 },
    { value = "209035", textKey = "Hearthstone of the Flame", itemID = 209035 },
    { value = "210455", textKey = "Draenic Hologem", itemID = 210455 },
    { value = "212337", textKey = "Stone of the Hearth", itemID = 212337 },
    { value = "228940", textKey = "Notorious Thread's Hearthstone", itemID = 228940 },
    { value = "235016", textKey = "Redeployment Module", itemID = 235016 },
    { value = "236687", textKey = "Explosive Hearthstone", itemID = 236687 },
    { value = "245970", textKey = "P.O.S.T. Master's Express Hearthstone", itemID = 245970 },
    { value = "246565", textKey = "Astral Hearthstone", itemID = 246565 },
    { value = "257736", textKey = "Light's Call Hearthstone", itemID = 257736 },
    { value = "263489", textKey = "Embrace of the Naaru", itemID = 263489 },
    { value = "263933", textKey = "Harvester's Hearthstone", itemID = 263933 },
    { value = "265100", textKey = "Coreway Defender's Hearthstone", itemID = 265100 },

    -- Engineering wormholes. These can be selected directly for left/middle/right
    -- click actions, but are excluded from the random hearthstone pool above.
    { value = "18984", textKey = "Dimensional Ripper - Everlook", itemID = 18984 },
    { value = "18986", textKey = "Ultrasafe Transporter: Gadgetzan", itemID = 18986 },
    { value = "30542", textKey = "Dimensional Ripper - Area 52", itemID = 30542 },
    { value = "30544", textKey = "Ultrasafe Transporter: Toshley's Station", itemID = 30544 },
    { value = "48933", textKey = "Wormhole Generator: Northrend", itemID = 48933 },
    { value = "87215", textKey = "Wormhole Generator: Pandaria", itemID = 87215 },
    { value = "112059", textKey = "Wormhole Centrifuge", itemID = 112059 },
    { value = "132517", textKey = "Intra-Dalaran Wormhole Generator", itemID = 132517 },
    { value = "132524", textKey = "Reaves Module: Wormhole Generator Mode", itemID = 132524 },
    { value = "151652", textKey = "Wormhole Generator: Argus", itemID = 151652 },
    { value = "168807", textKey = "Wormhole Generator: Kul Tiras", itemID = 168807 },
    { value = "168808", textKey = "Wormhole Generator: Zandalar", itemID = 168808 },
    { value = "172924", textKey = "Wormhole Generator: Shadowlands", itemID = 172924 },
    { value = "198156", textKey = "Wyrmhole Generator: Dragon Isles", itemID = 198156 },
    { value = "221966", textKey = "Wormhole Generator: Khaz Algar", itemID = 221966 },
    { value = "248485", textKey = "Wormhole Generator: Quel'Thalas", itemID = 248485 },
}

-- Shared hearthstone helpers. Runtime button code and the options UI both use
-- this single source, so item-name loading, SavedVariables values, and macro
-- generation stay consistent.
ns.hearthstoneActionByValue = ns.hearthstoneActionByValue or {}
for _, item in ipairs(ns.hearthstoneActionList or {}) do
    ns.hearthstoneActionByValue[tostring(item.value)] = item
end

local function HearthstoneTextFallback(key)
    if key == nil then return "" end
    if ns.UIText then return ns.UIText(key) end
    if ns.T then return ns.T(key) end
    return tostring(key)
end

function ns.GetItemDisplayName(itemID, fallbackKey)
    itemID = tonumber(itemID)
    if itemID then
        if C_Item and C_Item.RequestLoadItemDataByID then
            pcall(C_Item.RequestLoadItemDataByID, itemID)
        end

        local name
        if C_Item and C_Item.GetItemNameByID then
            local ok, result = pcall(C_Item.GetItemNameByID, itemID)
            if ok and result then name = result end
        end
        if not name and C_Item and C_Item.GetItemInfo then
            local ok, result = pcall(C_Item.GetItemInfo, itemID)
            if ok then
                if type(result) == "table" then
                    name = result.itemName or result.name
                else
                    name = result
                end
            end
        end
        if not name and GetItemInfo then
            local ok, result = pcall(GetItemInfo, itemID)
            if ok and result then name = result end
        end
        if name and name ~= "" then return name end
    end

    return HearthstoneTextFallback(fallbackKey or "")
end

function ns.GetHearthstoneActionData(value)
    value = tostring(value or "none")
    return ns.hearthstoneActionByValue and ns.hearthstoneActionByValue[value] or nil
end

function ns.GetHearthstoneActionName(value)
    value = tostring(value or "none")
    local item = ns.GetHearthstoneActionData and ns.GetHearthstoneActionData(value)

    if not item then
        local itemID = tonumber(value)
        if itemID then return ns.GetItemDisplayName(itemID, "Item " .. itemID) end
        return HearthstoneTextFallback("No Action")
    end

    if item.value == "none" then return HearthstoneTextFallback("No Action") end
    if item.isRandom then return HearthstoneTextFallback("Random Hearthstone") end
    if item.itemID then
        -- Display names come from Blizzard item APIs, matching the reference
        -- Hearthstone selector behavior while keeping the surrounding UI English-only.
        return ns.GetItemDisplayName(item.itemID, item.textKey or tostring(item.value or ""))
    end
    return HearthstoneTextFallback(item.textKey or tostring(item.value or ""))
end

local function PlayerOwnsHearthstoneItem(itemID)
    itemID = tonumber(itemID)
    if not itemID then return false end

    if C_Item and C_Item.GetItemCount then
        local ok, count = pcall(C_Item.GetItemCount, itemID, false, true)
        if ok and tonumber(count or 0) and tonumber(count or 0) > 0 then
            return true
        end
    elseif GetItemCount then
        local ok, count = pcall(GetItemCount, itemID, false, true)
        if ok and tonumber(count or 0) and tonumber(count or 0) > 0 then
            return true
        end
    end

    if PlayerHasToy then
        local ok, hasToy = pcall(PlayerHasToy, itemID)
        if ok and hasToy then
            if C_ToyBox and C_ToyBox.IsToyUsable then
                local usableOK, usable = pcall(C_ToyBox.IsToyUsable, itemID)
                if usableOK and usable == false then return false end
            end
            return true
        end
    end

    return false
end

function ns.GetAvailableRandomHearthstones()
    local available = {}
    local excluded = ns.randomHearthstoneExcludedItemIDs or {}
    for _, item in ipairs(ns.hearthstoneActionList or {}) do
        if item and item.itemID and not item.isRandom and item.value ~= "none" and not excluded[item.itemID] then
            if PlayerOwnsHearthstoneItem(item.itemID) then
                available[#available + 1] = item.itemID
            end
        end
    end
    return available
end

function ns.PickRandomHearthstoneItemID(randomKey)
    local available = ns.GetAvailableRandomHearthstones and ns.GetAvailableRandomHearthstones() or {}
    local count = #available
    if count <= 0 then return nil end
    if count == 1 then
        local only = available[1]
        ns._lastRandomHearthstoneByKey = ns._lastRandomHearthstoneByKey or {}
        ns._lastRandomHearthstoneByKey[randomKey or "default"] = only
        return only
    end

    ns._lastRandomHearthstoneByKey = ns._lastRandomHearthstoneByKey or {}
    randomKey = randomKey or "default"
    local last = ns._lastRandomHearthstoneByKey[randomKey]
    local pick
    for _ = 1, 8 do
        pick = available[math.random(1, count)]
        if pick ~= last then break end
    end
    ns._lastRandomHearthstoneByKey[randomKey] = pick
    return pick
end

function ns.BuildHearthstoneMacro(value, randomKey)
    value = tostring(value or "none")
    if value == "none" or value == "" then return nil end

    if value == (ns.HEARTHSTONE_RANDOM_VALUE or "random") then
        local itemID = ns.PickRandomHearthstoneItemID and ns.PickRandomHearthstoneItemID(randomKey)
        if not itemID then return nil end
        local macro = "/use item:" .. itemID
        local refreshGlobal = ns.HEARTHSTONE_RANDOM_REFRESH_GLOBAL or "QFXSystemBar_RandomHearthstoneRefresh"
        if refreshGlobal and refreshGlobal ~= "" then
            macro = macro .. "\n/run " .. refreshGlobal .. "()"
        end
        return macro
    end

    local itemID = tonumber(value)
    if itemID then return "/use item:" .. itemID end
    return nil
end

local function GetItemIconMarkup(itemID, size)
    itemID = tonumber(itemID)
    if not itemID then return nil end

    local icon
    if C_Item and C_Item.GetItemIconByID then
        local ok, result = pcall(C_Item.GetItemIconByID, itemID)
        if ok then icon = result end
    end
    if not icon and GetItemIcon then
        local ok, result = pcall(GetItemIcon, itemID)
        if ok then icon = result end
    end

    if icon then
        size = tonumber(size) or 14
        return "|T" .. tostring(icon) .. ":" .. size .. ":" .. size .. ":0:0|t"
    end
    return nil
end

function ns.GetHearthstoneDropdownOptions()
    local out = {}
    local function AddOption(item)
        if not item then return end
        local text
        if item.itemID then
            local name = ns.GetHearthstoneActionName and ns.GetHearthstoneActionName(item.value) or HearthstoneTextFallback(item.textKey)
            local icon = GetItemIconMarkup(item.itemID, 14)
            text = icon and (icon .. " " .. name) or name
        else
            text = HearthstoneTextFallback(item.textKey or tostring(item.value or ""))
        end
        out[#out + 1] = { value = item.value, text = text }
    end

    for _, item in ipairs(ns.hearthstoneActionList or {}) do
        if item.value == "none" or item.isRandom then
            AddOption(item)
        elseif item.itemID and PlayerOwnsHearthstoneItem(item.itemID) then
            -- Match the reference selector: show only real choices the player owns.
            -- Saved values remain stable itemIDs, and closed dropdown labels are
            -- resolved through ns.GetHearthstoneActionName.
            AddOption(item)
        end
    end
    return out
end

-- Time text font options for the top micro menu.  Values are stable IDs saved
-- in SavedVariables; the real font path is resolved at render time so it can
-- safely follow the client's available font globals.
ns.MicroMenuTimeFontOptions = {
    { value = "default", textKey = "Default Font" },
    { value = "unit", textKey = "Unit Name Font" },
    { value = "damage", textKey = "Damage Font" },
    { value = "frizqt", textKey = "Friz Quadrata" },
    { value = "arialn", textKey = "Arial Narrow" },
    { value = "morpheus", textKey = "Morpheus" },
    { value = "skurri", textKey = "Skurri" },
    { value = "arkai_t", textKey = "Chinese KaiTi" },
    { value = "arkai_c", textKey = "Chinese KaiTi Bold" },
}

local function GetOptionalLSM()
    if not LibStub then return nil end
    local ok, lib = pcall(LibStub, "LibSharedMedia-3.0", true)
    if ok and lib then return lib end
    return nil
end

function ns.GetMicroMenuTimeFontOptions()
    local out = {}
    local seen = {}
    for i, item in ipairs(ns.MicroMenuTimeFontOptions or {}) do
        out[#out + 1] = item
        seen[item.value] = true
    end

    -- WoW addons cannot scan the Fonts folder or read TTF metadata at runtime.
    -- This optional bridge exposes fonts registered by SharedMedia/LSM packs.
    local lsm = GetOptionalLSM()
    if lsm and lsm.List then
        local ok, names = pcall(lsm.List, lsm, "font")
        if ok and type(names) == "table" then
            for _, name in ipairs(names) do
                if type(name) == "string" and name ~= "" then
                    local value = "lsm:" .. name
                    if not seen[value] then
                        out[#out + 1] = { value = value, textKey = name }
                        seen[value] = true
                    end
                end
            end
        end
    end
    return out
end

function ns.ResolveMicroMenuTimeFont(value)
    value = tostring(value or "default")
    if value:sub(1, 4) == "lsm:" then
        local lsm = GetOptionalLSM()
        if lsm and lsm.Fetch then
            local ok, path = pcall(lsm.Fetch, lsm, "font", value:sub(5))
            if ok and type(path) == "string" and path ~= "" then return path end
        end
    end
    if value == "unit" then return UNIT_NAME_FONT or STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF" end
    if value == "damage" then return DAMAGE_TEXT_FONT or STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF" end
    if value == "frizqt" then return "Fonts\\FRIZQT__.TTF" end
    if value == "arialn" then return "Fonts\\ARIALN.TTF" end
    if value == "morpheus" then return "Fonts\\MORPHEUS.TTF" end
    if value == "skurri" then return "Fonts\\SKURRI.TTF" end
    if value == "arkai_t" then return "Fonts\\ARKai_T.TTF" end
    if value == "arkai_c" then return "Fonts\\ARKai_C.TTF" end
    return STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
end

ns.defaults = {
    -- Localization
    language = "auto",

    -- General
    isCustomMicroMenu = true,
    customMicroMenu = 0,
    nativeMicroMenu = 1,
    bagBar = 1,
    uiFadeInDuration = 0.2,
    uiFadeOutDuration = 0.2,

    -- Buttons
    customMicroMenuButtonOrder = CopyArray(ns.defaultMicroMenuButtonOrder),
    isCustomMicroMenuCharacter = ns.defaultMicroMenuButtonEnabled.Character,
    isCustomMicroMenuSocial = ns.defaultMicroMenuButtonEnabled.Social,
    isCustomMicroMenuProfession = ns.defaultMicroMenuButtonEnabled.Profession,
    isCustomMicroMenuPlayerSpells = ns.defaultMicroMenuButtonEnabled.PlayerSpells,
    isCustomMicroMenuAchievement = ns.defaultMicroMenuButtonEnabled.Achievement,
    isCustomMicroMenuQuestLog = ns.defaultMicroMenuButtonEnabled.QuestLog,
    isCustomMicroMenuTime = ns.defaultMicroMenuButtonEnabled.Time,
    isCustomMicroMenuHousing = ns.defaultMicroMenuButtonEnabled.Housing,
    isCustomMicroMenuHearthstone = ns.defaultMicroMenuButtonEnabled.Hearthstone,
    isCustomMicroMenuGuild = ns.defaultMicroMenuButtonEnabled.Guild,
    isCustomMicroMenuLFD = ns.defaultMicroMenuButtonEnabled.LFD,
    isCustomMicroMenuMeetingStone = ns.defaultMicroMenuButtonEnabled.MeetingStone,
    isCustomMicroMenuCollections = ns.defaultMicroMenuButtonEnabled.Collections,
    isCustomMicroMenuEJ = ns.defaultMicroMenuButtonEnabled.EJ,
    isCustomMicroMenuStore = ns.defaultMicroMenuButtonEnabled.Store,
    isCustomMicroMenuBags = ns.defaultMicroMenuButtonEnabled.Bags,
    isCustomMicroMenuVolume = ns.defaultMicroMenuButtonEnabled.Volume,
    isCustomMicroMenuMainMenu = ns.defaultMicroMenuButtonEnabled.MainMenu,
    customMicroMenuHearthstoneLeft = "6948",
    customMicroMenuHearthstoneMiddle = "none",
    customMicroMenuHearthstoneRight = ns.HEARTHSTONE_RANDOM_VALUE or "random",

    -- Appearance
    customMicroMenuIconStyle = "gameicons",
    customMicroMenuColorMode = "class", -- legacy shared color mode, kept for old SavedVariables migration
    customMicroMenuTextColor = "FFFFFFFF", -- legacy shared custom color, kept for old SavedVariables migration
    customMicroMenuIconColorMode = "class",
    customMicroMenuIconCustomColor = "FFFFFFFF",
    customMicroMenuClockColorMode = "class",
    customMicroMenuClockCustomColor = "FFFFFFFF",
    customMicroMenuBadgeColorMode = "original",
    customMicroMenuBadgeCustomColor = "FFFFFFFF",
    customMicroMenuBadgeDisplay = { friends = true, guild = true, bags = true, durability = true, volume = true },
    customMicroMenuShowDurabilityBadge = true,
    customMicroMenuShowFriendBadge = true,
    customMicroMenuShowGuildBadge = true,
    customMicroMenuShowBagBadge = true,
    customMicroMenuShowVolumeBadge = true,
    customMicroMenuDurabilityBadgeColor = "FFFFFFFF",
    customMicroMenuFriendBadgeColor = "FFFFFFFF",
    customMicroMenuGuildBadgeColor = "FFFFFFFF",
    customMicroMenuBagBadgeColor = "FFFFFFFF",
    customMicroMenuVolumeBadgeColor = "FFFFFFFF",
    customMicroMenuBadgeTextColor = "FFFFFFFF", -- legacy shared color, hidden from the UI
    isCustomMicroMenuTimeAdj = true,
    customMicroMenuTimeMode = "local",
    customMicroMenuTimeFormat = "24h",
    customMicroMenuTimeFont = "default",
    customMicroMenuFontSize = 50,
    customMicroMenuTimeTextYOffset = 0,
    customMicroMenuTimeOutline = "THICKOUTLINE",
    customMicroMenuIconSize = 30,
    customMicroMenuButtonSpacing = 10,

    -- Position
    customMicroMenuUnlocked = false,
    customMicroMenuPositionX = 0,
    customMicroMenuPositionY = 0,

    -- Blizzard top-center zone information position. positionMode/x/y stay
    -- absent until the first successful initialization inspects the live frame.
    topCenterWidget = {
        locked = true,
    },
}

function ns.MigrateMicroMenuColorSettings(db)
    if type(db) ~= "table" then return end
    local legacyMode = db.customMicroMenuColorMode
    local legacyColor = db.customMicroMenuTextColor or "FFFFFFFF"
    if db.customMicroMenuIconColorMode == nil then
        if legacyMode == "material" then
            db.customMicroMenuIconColorMode = "original"
        elseif legacyMode == "class_except_icons" then
            db.customMicroMenuIconColorMode = "custom"
            db.customMicroMenuIconCustomColor = db.customMicroMenuIconCustomColor or legacyColor
        else
            db.customMicroMenuIconColorMode = "class"
        end
    end
    if db.customMicroMenuClockColorMode == nil then
        if legacyMode == "class" or legacyMode == "class_except_icons" then
            db.customMicroMenuClockColorMode = "class"
        elseif legacyMode == "class_except_time" or legacyMode == "material" then
            db.customMicroMenuClockColorMode = "custom"
            db.customMicroMenuClockCustomColor = db.customMicroMenuClockCustomColor or legacyColor
        else
            db.customMicroMenuClockColorMode = "class"
        end
    end
    if db.customMicroMenuIconCustomColor == nil then
        db.customMicroMenuIconCustomColor = legacyColor
    end
    if db.customMicroMenuClockCustomColor == nil then
        db.customMicroMenuClockCustomColor = legacyColor
    end
    if db.customMicroMenuBadgeColorMode == nil then
        db.customMicroMenuBadgeColorMode = "original"
    end
    if db.customMicroMenuBadgeCustomColor == nil then
        db.customMicroMenuBadgeCustomColor = db.customMicroMenuBadgeTextColor or db.customMicroMenuDurabilityBadgeColor or "FFFFFFFF"
    end
    db.customMicroMenuClockYOffset = nil
    db.customMicroMenuIconYOffset = nil
    db.customMicroMenuColonYOffset = nil
end
