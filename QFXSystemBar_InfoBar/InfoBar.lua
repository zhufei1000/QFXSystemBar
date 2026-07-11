local addonName, ns = ...
ns = _G.QFXSystemBarNS or ns
if not ns then return end
ns.InfoBarLoaded = true

-- ========================================================================
-- QFXSystemBar Info Bar
-- ------------------------------------------------------------------------
-- QFX modular info strips.
-- Each strip can independently edit visibility, content order, position, size,
-- and gradient direction without relying on external UI naming or layouts.
-- ========================================================================

local DEFAULT_INFOBAR_WIDTH = 450
local DEFAULT_INFOBAR_HEIGHT = 18
local INFOBAR_PAD = 15
local INFOBAR_SPACING = 30
local DEFAULT_INFOBAR_FONT_SIZE = 12
local DEFAULT_INFOBAR_LINE_THICKNESS = 1
local DEFAULT_INFOBAR_LINE_STYLE = "eui-taskbar"
local DEFAULT_INFOBAR_LINE_POSITION_LEFT = "both"
local DEFAULT_INFOBAR_LINE_POSITION_RIGHT = "both"
local MAX_TOOLTIP_ADDONS = 10
local MAX_INFOBAR_ITEMS_PER_BAR = 5

local function LT(key)
    if key == nil then return "" end
    if type(key) ~= "string" then return tostring(key) end
    if ns and ns.T then return ns.T(key) end
    if ns and ns.UIText then return ns.UIText(key) end
    return key
end

local function LF(key, ...)
    local text = LT(key)
    local ok, value = pcall(string.format, text, ...)
    if ok then return value end
    return text
end

local function ShortInfoLabel(key, englishShort)
    local locale = ns and ns.currentLocale
    if locale == nil or locale == "enUS" or locale == "enGB" then
        return englishShort or key
    end
    return LT(key)
end

local INFOBAR_ITEM_ORDER = {"ilvl", "mplus", "fps", "combatlog", "meetingstone", "guild", "friend", "zone", "coords", "phase", "spec", "dura", "gold", "volume", "time"}
local INFOBAR_ITEM_INDEX = {}
for i, id in ipairs(INFOBAR_ITEM_ORDER) do INFOBAR_ITEM_INDEX[id] = i end

local LEFT_DEFAULT_ITEMS = { ilvl = true, mplus = true, fps = true, combatlog = true }
local LEFT_BOTTOM_DEFAULT_ITEMS = { guild = true, friend = true, coords = true, phase = true }
local RIGHT_DEFAULT_ITEMS = { spec = true, dura = true, gold = true, volume = true }

local function CopyArray(src)
    local out = {}
    for i, v in ipairs(src or {}) do out[i] = v end
    return out
end

local function CopyMap(src)
    local out = {}
    for k, v in pairs(src or {}) do out[k] = v end
    return out
end

ns.defaults = ns.defaults or {}
ns.defaults.isInfoBar = false
ns.defaults.infoBarLeftEnabled = true
ns.defaults.infoBarLeftBottomEnabled = false
ns.defaults.infoBarRightEnabled = true
ns.defaults.infoBarLeftWidth = DEFAULT_INFOBAR_WIDTH
ns.defaults.infoBarLeftBottomWidth = DEFAULT_INFOBAR_WIDTH
ns.defaults.infoBarRightWidth = DEFAULT_INFOBAR_WIDTH
ns.defaults.infoBarLeftHeight = DEFAULT_INFOBAR_HEIGHT
ns.defaults.infoBarLeftBottomHeight = DEFAULT_INFOBAR_HEIGHT
ns.defaults.infoBarRightHeight = DEFAULT_INFOBAR_HEIGHT
ns.defaults.infoBarLeftFade = "left"
ns.defaults.infoBarLeftBottomFade = "left"
ns.defaults.infoBarRightFade = "right"
ns.defaults.infoBarFadeStrength = 50
ns.defaults.infoBarFontSize = DEFAULT_INFOBAR_FONT_SIZE
ns.defaults.infoBarLineThickness = DEFAULT_INFOBAR_LINE_THICKNESS -- legacy migration only
ns.defaults.infoBarLineStyle = DEFAULT_INFOBAR_LINE_STYLE -- legacy migration only
ns.defaults.infoBarLeftLineThickness = DEFAULT_INFOBAR_LINE_THICKNESS
ns.defaults.infoBarLeftBottomLineThickness = DEFAULT_INFOBAR_LINE_THICKNESS
ns.defaults.infoBarRightLineThickness = DEFAULT_INFOBAR_LINE_THICKNESS
ns.defaults.infoBarLeftLineStyle = DEFAULT_INFOBAR_LINE_STYLE
ns.defaults.infoBarLeftBottomLineStyle = DEFAULT_INFOBAR_LINE_STYLE
ns.defaults.infoBarRightLineStyle = DEFAULT_INFOBAR_LINE_STYLE
ns.defaults.infoBarLeftLinePosition = DEFAULT_INFOBAR_LINE_POSITION_LEFT
ns.defaults.infoBarLeftBottomLinePosition = DEFAULT_INFOBAR_LINE_POSITION_LEFT
ns.defaults.infoBarRightLinePosition = DEFAULT_INFOBAR_LINE_POSITION_RIGHT
ns.defaults.infoBarLeftUnlocked = false
ns.defaults.infoBarLeftBottomUnlocked = false
ns.defaults.infoBarRightUnlocked = false
ns.defaults.infoBarLeftX = 0
ns.defaults.infoBarLeftY = 0
ns.defaults.infoBarLeftBottomX = 0
ns.defaults.infoBarLeftBottomY = 0
ns.defaults.infoBarRightX = 0
ns.defaults.infoBarRightY = 0
ns.defaults.infoBarLeftOrder = CopyArray(INFOBAR_ITEM_ORDER)
ns.defaults.infoBarLeftBottomOrder = CopyArray(INFOBAR_ITEM_ORDER)
ns.defaults.infoBarRightOrder = CopyArray(INFOBAR_ITEM_ORDER)
ns.defaults.infoBarLeftItems = CopyMap(LEFT_DEFAULT_ITEMS)
ns.defaults.infoBarLeftBottomItems = CopyMap(LEFT_BOTTOM_DEFAULT_ITEMS)
ns.defaults.infoBarRightItems = CopyMap(RIGHT_DEFAULT_ITEMS)

ns.InfoBarItems = {
    guild = { labelKey = "Guild", tooltipKey = "Show online guild members." },
    friend = { labelKey = "Friends", tooltipKey = "Show online Battle.net and character friends." },
    meetingstone = { labelKey = "MeetingStone", tooltipKey = "Show MeetingStone broker information on this info bar. It keeps MeetingStone's own click and hover behavior." },
    fps = { labelKey = "FPS / Latency", tooltipKey = "Show framerate and latency together. Tooltip shows addon memory and latency details." },
    combatlog = { labelKey = "Advanced Combat Log", tooltipKey = "Show Advanced Combat Logging state. Left click turns it on. Right click turns it off." },
    zone = { labelKey = "Location", tooltipKey = "Show current zone and coordinates tooltip." },
    coords = { labelKey = "Coordinates", tooltipKey = "Show player coordinates. Left click opens the world map. Right click creates a waypoint at your current position." },
    phase = { labelKey = "Phase ID", tooltipKey = "Show the current map or instance ID as the available phase-style identifier." },
    spec = { labelKey = "Specialization", tooltipKey = "Left click opens talents. Right click changes loot specialization." },
    ilvl = { labelKey = "Item Level", tooltipKey = "Show equipped item level." },
    mplus = { labelKey = "Mythic+ Score", tooltipKey = "Show current Mythic+ rating." },
    dura = { labelKey = "Durability", tooltipKey = "Show equipped durability." },
    gold = { labelKey = "Gold", tooltipKey = "Show current money and session profit/loss. Right click toggles free bag slots." },
    volume = { labelKey = "Volume", tooltipKey = "Show master volume. Left click opens a volume slider. Right click toggles mute." },
    time = { labelKey = "Time", tooltipKey = "Show time and raid lockouts. Left click opens calendar." },
}
ns.InfoBarAllItems = CopyArray(INFOBAR_ITEM_ORDER)
ns.InfoBarDefaultOrder = CopyArray(INFOBAR_ITEM_ORDER)
ns.InfoBarMaxItems = MAX_INFOBAR_ITEMS_PER_BAR

local INFOBAR_ITEM_SOURCE_TO_ID = {
    ["Guild"] = "guild",
    ["Friends"] = "friend",
    ["Social"] = "friend",
    ["MeetingStone"] = "meetingstone",
    ["Meeting Stone"] = "meetingstone",
    ["FPS / Latency"] = "fps",
    ["FPS/MS"] = "fps",
    ["FPS"] = "fps",
    ["Latency"] = "fps",
    ["Advanced Combat Log"] = "combatlog",
    ["Combat Log"] = "combatlog",
    ["ACL"] = "combatlog",
    ["Location"] = "zone",
    ["Zone"] = "zone",
    ["Coordinates"] = "coords",
    ["Coords"] = "coords",
    ["Phase ID"] = "phase",
    ["Phase"] = "phase",
    ["Specialization"] = "spec",
    ["Spec"] = "spec",
    ["Item Level"] = "ilvl",
    ["iLvl"] = "ilvl",
    ["Mythic+ Score"] = "mplus",
    ["Score"] = "mplus",
    ["M+"] = "mplus",
    ["Durability"] = "dura",
    ["Dura"] = "dura",
    ["Gold"] = "gold",
    ["Money"] = "gold",
    ["Volume"] = "volume",
    ["Master Volume"] = "volume",
    ["Time"] = "time",
}

function ns.NormalizeInfoBarItemID(value)
    if type(value) ~= "string" then return nil end
    if ns.InfoBarItems and ns.InfoBarItems[value] then return value end
    local normalized = ns.NormalizeLocaleKey and ns.NormalizeLocaleKey(value) or value
    return INFOBAR_ITEM_SOURCE_TO_ID[normalized] or INFOBAR_ITEM_SOURCE_TO_ID[value] or normalized
end

local function NormalizeInfoBarEnabledMap(map)
    if type(map) ~= "table" then return end
    local updates = nil
    for key, value in pairs(map) do
        if type(key) == "string" then
            local id = ns.NormalizeInfoBarItemID and ns.NormalizeInfoBarItemID(key) or key
            if type(id) == "string" and id ~= "" and ns.InfoBarItems[id] and id ~= key then
                updates = updates or {}
                updates[key] = id
            end
        end
    end
    if updates then
        for oldKey, newKey in pairs(updates) do
            if map[newKey] == nil then map[newKey] = map[oldKey] end
            map[oldKey] = nil
        end
    end
    if map.ping == true and map.fps == nil then map.fps = true end
    map.ping = nil
end

ns.InfoBarSlots = {
    left = {
        labelKey = "Left Top Info Bar",
        orderKey = "infoBarLeftOrder",
        enabledKey = "infoBarLeftItems",
        unlockedKey = "infoBarLeftUnlocked",
        xKey = "infoBarLeftX",
        yKey = "infoBarLeftY",
        widthKey = "infoBarLeftWidth",
        heightKey = "infoBarLeftHeight",
        fadeKey = "infoBarLeftFade",
        lineStyleKey = "infoBarLeftLineStyle",
        linePositionKey = "infoBarLeftLinePosition",
        lineThicknessKey = "infoBarLeftLineThickness",
        barEnabledKey = "infoBarLeftEnabled",
        frameName = "QFXSystemBarLeftTopInfoStrip",
        anchor = "TOPLEFT",
        defaultX = 0,
        defaultY = 0,
        defaultFade = "left",
        defaultItems = LEFT_DEFAULT_ITEMS,
        align = "left",
    },
    leftbottom = {
        labelKey = "Left Bottom Info Bar",
        orderKey = "infoBarLeftBottomOrder",
        enabledKey = "infoBarLeftBottomItems",
        unlockedKey = "infoBarLeftBottomUnlocked",
        xKey = "infoBarLeftBottomX",
        yKey = "infoBarLeftBottomY",
        widthKey = "infoBarLeftBottomWidth",
        heightKey = "infoBarLeftBottomHeight",
        fadeKey = "infoBarLeftBottomFade",
        lineStyleKey = "infoBarLeftBottomLineStyle",
        linePositionKey = "infoBarLeftBottomLinePosition",
        lineThicknessKey = "infoBarLeftBottomLineThickness",
        barEnabledKey = "infoBarLeftBottomEnabled",
        frameName = "QFXSystemBarLeftBottomInfoStrip",
        anchor = "BOTTOMLEFT",
        defaultX = 0,
        defaultY = 0,
        defaultFade = "left",
        defaultItems = LEFT_BOTTOM_DEFAULT_ITEMS,
        align = "left",
    },
    right = {
        labelKey = "Right Bottom Info Bar",
        orderKey = "infoBarRightOrder",
        enabledKey = "infoBarRightItems",
        unlockedKey = "infoBarRightUnlocked",
        xKey = "infoBarRightX",
        yKey = "infoBarRightY",
        widthKey = "infoBarRightWidth",
        heightKey = "infoBarRightHeight",
        fadeKey = "infoBarRightFade",
        lineStyleKey = "infoBarRightLineStyle",
        linePositionKey = "infoBarRightLinePosition",
        lineThicknessKey = "infoBarRightLineThickness",
        barEnabledKey = "infoBarRightEnabled",
        frameName = "QFXSystemBarRightBottomInfoStrip",
        anchor = "BOTTOMRIGHT",
        defaultX = 0,
        defaultY = 0,
        defaultFade = "right",
        defaultItems = RIGHT_DEFAULT_ITEMS,
        align = "right",
    },
}

local bars = {}
local modules = {}
local eventFrame
local systemTicker
local timeTicker
local tooltipTicker
local itemTickers = {}
local RefreshInfoBarItem
local UpdateItemTickers
local UpdateInfoBarEventRegistration
local IsAnyInfoBarItemEnabled

local ITEM_REFRESH_INTERVALS = {
    fps = 3,
    time = 60,
    coords = 1,
    meetingstone = 10,
}

local ADVANCED_COMBAT_LOG_CVAR = "advancedCombatLogging"
local VOLUME_MASTER_CVAR = "Sound_MasterVolume"
local VOLUME_MUTE_CVAR = "Sound_EnableAllSound"

local CVAR_ITEM_REFRESH = {
    [ADVANCED_COMBAT_LOG_CVAR] = { combatlog = true },
    [VOLUME_MASTER_CVAR] = { volume = true },
    [VOLUME_MUTE_CVAR] = { volume = true },
}

local EVENT_ITEM_REFRESH = {
    PLAYER_MONEY = { gold = true },
    SEND_MAIL_MONEY_CHANGED = { gold = true },
    SEND_MAIL_COD_CHANGED = { gold = true },
    PLAYER_TRADE_MONEY = { gold = true },
    TRADE_MONEY_CHANGED = { gold = true },
    BAG_UPDATE_DELAYED = { gold = true },
    UPDATE_INVENTORY_DURABILITY = { dura = true },
    PLAYER_EQUIPMENT_CHANGED = { dura = true, ilvl = true },
    PLAYER_AVG_ITEM_LEVEL_UPDATE = { ilvl = true },
    CHALLENGE_MODE_COMPLETED = { mplus = true },
    ACTIVE_PLAYER_SPECIALIZATION_CHANGED = { spec = true, mplus = true },
    PLAYER_SPECIALIZATION_CHANGED = { spec = true, mplus = true },
    PLAYER_LOOT_SPEC_UPDATED = { spec = true },
    ZONE_CHANGED = { zone = true, coords = true, phase = true },
    ZONE_CHANGED_INDOORS = { zone = true, coords = true, phase = true },
    ZONE_CHANGED_NEW_AREA = { zone = true, coords = true, phase = true },
    FRIENDLIST_UPDATE = { friend = true },
    BN_FRIEND_ACCOUNT_ONLINE = { friend = true },
    BN_FRIEND_ACCOUNT_OFFLINE = { friend = true },
    BN_FRIEND_INFO_CHANGED = { friend = true },
    GUILD_ROSTER_UPDATE = { guild = true },
    PLAYER_GUILD_UPDATE = { guild = true },
    LFG_LIST_APPLICATION_STATUS_UPDATED = { meetingstone = true },
    LFG_LIST_APPLICANT_LIST_UPDATED = { meetingstone = true },
    LFG_LIST_APPLICANT_UPDATED = { meetingstone = true },
    CVAR_UPDATE = { volume = true, combatlog = true },
    UPDATE_INSTANCE_INFO = { time = true },
}
local loginTime = 0
local showCPU
local showSlots

local function DB()
    QFXSystemBarDB = QFXSystemBarDB or {}
    return QFXSystemBarDB
end

local function GetClassColor()
    local class
    if UnitClass then
        local _, classFile = UnitClass("player")
        class = classFile
    end
    local color = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
    if color then return color.r or 1, color.g or 1, color.b or 1 end
    return 0.6, 0.8, 1
end

local function ColorHex(r, g, b)
    return string.format("|cff%02x%02x%02x", math.floor((r or 1) * 255 + 0.5), math.floor((g or 1) * 255 + 0.5), math.floor((b or 1) * 255 + 0.5))
end

local function MyColor()
    return ColorHex(GetClassColor())
end

local function InfoColor()
    return "|cff99ccff"
end

local function LineString()
    return "------------------------------"
end

local function LeftButtonText()
    return "|TInterface\\TUTORIALFRAME\\UI-TUTORIAL-FRAME:11:11:0:0:512:512:12:66:230:307|t "
end

local function RightButtonText()
    return "|TInterface\\TUTORIALFRAME\\UI-TUTORIAL-FRAME:11:11:0:0:512:512:12:66:330:407|t "
end

local function MiddleButtonText()
    return "|TInterface\\TUTORIALFRAME\\UI-TUTORIAL-FRAME:11:11:0:0:512:512:12:66:430:507|t "
end

local function ScrollButtonText()
    return "|TInterface\\TUTORIALFRAME\\UI-TUTORIAL-FRAME:11:11:0:0:512:512:112:166:230:307|t "
end

local function SafeCall(func, ...)
    if type(func) ~= "function" then return false end
    local ok = pcall(func, ...)
    return ok
end

local function SafeReturn(func, ...)
    if type(func) ~= "function" then return nil end
    local ok, a, b, c, d = pcall(func, ...)
    if ok then return a, b, c, d end
    return nil
end

local function BlockInCombat()
    if InCombatLockdown and InCombatLockdown() then
        if UIErrorsFrame and UIErrorsFrame.AddMessage then UIErrorsFrame:AddMessage(ERR_NOT_IN_COMBAT or "Not available in combat.") end
        return true
    end
    return false
end

local function LoadBlizzardAddon(name)
    if C_AddOns and C_AddOns.LoadAddOn then pcall(C_AddOns.LoadAddOn, name)
    elseif LoadAddOn then pcall(LoadAddOn, name) end
end

local function ToggleCalendarSafe()
    if BlockInCombat() then return end
    if C_Calendar and C_Calendar.OpenCalendar then
        pcall(C_Calendar.OpenCalendar)
    elseif ToggleCalendar then
        pcall(ToggleCalendar)
    end
end

local function SafeClickNativeButton(...)
    if BlockInCombat() then return false end
    for i = 1, select("#", ...) do
        local name = select(i, ...)
        local btn = name and _G[name]
        if btn and btn.Click then
            local ok = pcall(btn.Click, btn, "LeftButton")
            if ok then return true end
        end
    end
    return false
end

local function FormatMemory(value)
    value = tonumber(value or 0) or 0
    if value > 1024 then return string.format("%.1f mb", value / 1024) end
    return string.format("%.0f kb", value)
end

local function FormatMoney(money, full)
    money = tonumber(money or 0) or 0
    local gold = math.floor(money / 10000)
    local silver = math.floor((money % 10000) / 100)
    local copper = money % 100
    local goldSymbol = _G.GOLD_AMOUNT_SYMBOL or "g"
    local silverSymbol = _G.SILVER_AMOUNT_SYMBOL or "s"
    local copperSymbol = _G.COPPER_AMOUNT_SYMBOL or "c"

    if money >= 1000000 and not full then
        local amount = BreakUpLargeNumbers and BreakUpLargeNumbers(tostring(math.floor(money / 10000))) or tostring(math.floor(money / 10000))
        return amount .. "|cffffd700" .. goldSymbol .. "|r"
    end

    if money <= 0 then return "0|cffc77050" .. copperSymbol .. "|r" end
    local text = ""
    if gold > 0 then text = text .. gold .. "|cffffd700" .. goldSymbol .. "|r" end
    if silver > 0 then text = text .. (text ~= "" and " " or "") .. silver .. "|cffd0d0d0" .. silverSymbol .. "|r" end
    if copper > 0 then text = text .. (text ~= "" and " " or "") .. copper .. "|cffc77050" .. copperSymbol .. "|r" end
    return text
end

do
local function GetMoneySessionData()
    local db = DB()
    if type(db.infoBarMoneySession) ~= "table" then
        db.infoBarMoneySession = {
            initialized = false,
            startMoney = 0,
            lastMoney = 0,
            earned = 0,
            spent = 0,
        }
    end
    ns.InfoBarMoneySession = db.infoBarMoneySession
    return db.infoBarMoneySession
end

function ns.EnsureInfoBarMoneySession()
    local session = GetMoneySessionData()
    if session.initialized then return session end
    if type(GetMoney) ~= "function" then return session end

    local current = tonumber(GetMoney())
    if current == nil then return session end

    session.initialized = true
    session.startMoney = current
    session.lastMoney = current
    session.earned = 0
    session.spent = 0
    return session
end

function ns.UpdateInfoBarMoneySession()
    local data = ns.EnsureInfoBarMoneySession()
    if not data.initialized or type(GetMoney) ~= "function" then return data end

    local current = tonumber(GetMoney())
    if current == nil then return data end

    local delta = current - (tonumber(data.lastMoney) or current)
    if delta > 0 then
        data.earned = (tonumber(data.earned) or 0) + delta
    elseif delta < 0 then
        data.spent = (tonumber(data.spent) or 0) - delta
    end
    data.lastMoney = current
    return data
end
end

local function ColorLatency(latency)
    latency = tonumber(latency or 0) or 0
    if latency < 250 then return "|cff0CD809" .. latency .. "|r" end
    if latency < 500 then return "|cffE8DA0F" .. latency .. "|r" end
    return "|cffD80909" .. latency .. "|r"
end

local function ColorFPS(fps)
    fps = tonumber(fps or 0) or 0
    if fps < 15 then return "|cffD80909" .. fps .. "|r" end
    if fps < 30 then return "|cffE8DA0F" .. fps .. "|r" end
    return "|cff0CD809" .. fps .. "|r"
end

local function ColorMythicPlusScore(score)
    score = tonumber(score or 0) or 0
    local color
    if C_ChallengeMode and C_ChallengeMode.GetDungeonScoreRarityColor then
        local ok, result = pcall(C_ChallengeMode.GetDungeonScoreRarityColor, score)
        if ok then color = result end
    end
    if color and color.WrapTextInColorCode then return color:WrapTextInColorCode(tostring(score)) end
    if color and color.GetRGB then
        local r, g, b = color:GetRGB()
        return string.format("|cff%02x%02x%02x%s|r", math.floor((r or 1) * 255), math.floor((g or 1) * 255), math.floor((b or 1) * 255), tostring(score))
    end
    return MyColor() .. tostring(score) .. "|r"
end

local function GetNetLatency()
    if not GetNetStats then return 0, 0, 0 end
    local _, _, home, world = GetNetStats()
    home, world = home or 0, world or 0
    return home, world, math.max(home, world)
end

local function GetMythicPlusScore()
    if C_PlayerInfo and C_PlayerInfo.GetPlayerMythicPlusRatingSummary then
        local ok, summary = pcall(C_PlayerInfo.GetPlayerMythicPlusRatingSummary, "player")
        if ok and type(summary) == "table" then
            return tonumber(summary.currentSeasonScore or summary.overallScore or summary.rating) or 0
        end
    end
    return 0
end

local function GetOnlineGuild()
    if not IsInGuild or not IsInGuild() then return nil end
    if C_GuildInfo and C_GuildInfo.GuildRoster then pcall(C_GuildInfo.GuildRoster) end
    if GetNumGuildMembers then
        local _, online, allOnline = GetNumGuildMembers()
        return allOnline or online or 0
    end
    return 0
end

local function GetOnlineFriends()
    local online = 0
    if C_FriendList and C_FriendList.GetNumOnlineFriends then
        local ok, count = pcall(C_FriendList.GetNumOnlineFriends)
        if ok and count then online = online + count end
    elseif GetNumFriends and GetFriendInfo then
        local ok, count = pcall(GetNumFriends)
        if ok and count then
            for i = 1, count do
                local okInfo, _, _, _, _, connected = pcall(GetFriendInfo, i)
                if okInfo and connected then online = online + 1 end
            end
        end
    end
    if BNGetNumFriends then
        local ok, _, bnetOnline = pcall(BNGetNumFriends)
        if ok and bnetOnline then online = online + bnetOnline end
    end
    return online
end

local function GetBagFreeSlots()
    local free = 0
    for bag = 0, 4 do
        local count = 0
        if C_Container and C_Container.GetContainerNumFreeSlots then
            local ok, value = pcall(C_Container.GetContainerNumFreeSlots, bag)
            if ok and value then count = value end
        elseif GetContainerNumFreeSlots then
            local ok, value = pcall(GetContainerNumFreeSlots, bag)
            if ok and value then count = value end
        end
        free = free + count
    end
    return free
end

local function GetDurabilityPercent()
    local total, current = 0, 0
    for slot = 1, 19 do
        local ok, cur, max = pcall(GetInventoryItemDurability, slot)
        if ok and cur and max and max > 0 then
            current = current + cur
            total = total + max
        end
    end
    if total <= 0 then return nil end
    return math.floor((current / total) * 100 + 0.5)
end

local function ColorDurability(percent)
    percent = tonumber(percent or 0) or 0
    if percent < 30 then return "|cffD80909" .. percent .. "%|r" end
    if percent < 70 then return "|cffE8DA0F" .. percent .. "%|r" end
    return "|cff0CD809" .. percent .. "%|r"
end

local function GetSpecText()
    if not GetSpecialization or not GetSpecializationInfo then return (SPECIALIZATION or "Spec") .. ": " .. MyColor() .. (NONE or "None") .. "|r" end
    local spec = GetSpecialization()
    if spec and spec < 5 then
        local _, name, _, icon = GetSpecializationInfo(spec)
        if name then
            local loot = GetLootSpecialization and GetLootSpecialization() or 0
            if loot and loot ~= 0 and GetSpecializationInfoByID then
                local lootIcon = select(4, GetSpecializationInfoByID(loot))
                icon = lootIcon or icon
            end
            local iconText = icon and ("|T" .. icon .. ":12:16:0:0:50:50:4:46:4:46|t") or ""
            return MyColor() .. name .. "|r" .. iconText
        end
    end
    return (SPECIALIZATION or "Spec") .. ": " .. MyColor() .. (NONE or "None") .. "|r"
end

local function GetZoneTextColor()
    local pvpType = C_PvP and C_PvP.GetZonePVPInfo and C_PvP.GetZonePVPInfo() or (GetZonePVPInfo and GetZonePVPInfo())
    pvpType = pvpType or "neutral"
    if pvpType == "sanctuary" then return 0.41, 0.8, 0.94 end
    if pvpType == "arena" or pvpType == "hostile" or pvpType == "combat" then return 1, 0.1, 0.1 end
    if pvpType == "friendly" then return 0.1, 1, 0.1 end
    if pvpType == "contested" then return 1, 0.7, 0 end
    return 1, 0.93, 0.76
end

local function GetCoords()
    if not C_Map or not C_Map.GetBestMapForUnit or not C_Map.GetPlayerMapPosition then return nil end
    local okMap, mapID = pcall(C_Map.GetBestMapForUnit, "player")
    if not okMap or not mapID then return nil end
    local okPos, pos = pcall(C_Map.GetPlayerMapPosition, mapID, "player")
    if not okPos or not pos then return nil end
    local x, y = pos:GetXY()
    if not x or not y then return nil end
    return x, y, mapID
end

local function FormatCoords(x, y)
    if not x or not y then return "--" end
    return string.format("%.1f, %.1f", x * 100, y * 100)
end

local function GetCurrentMapID()
    if C_Map and C_Map.GetBestMapForUnit then
        local ok, mapID = pcall(C_Map.GetBestMapForUnit, "player")
        if ok and mapID then return mapID end
    end
end

local function GetPhaseLikeID()
    local instanceID
    if GetInstanceInfo then
        local ok, value = pcall(function() return select(8, GetInstanceInfo()) end)
        if ok then instanceID = tonumber(value) end
    end
    if instanceID and instanceID > 0 then return instanceID, "instance" end
    local mapID = GetCurrentMapID()
    if mapID then return mapID, "map" end
    return nil, nil
end

local function CreatePlayerWaypoint()
    local x, y, mapID = GetCoords()
    if not x or not y or not mapID then
        if UIErrorsFrame and UIErrorsFrame.AddMessage then UIErrorsFrame:AddMessage("Current coordinates are unavailable.") end
        return
    end

    local created
    if C_Map and C_Map.SetUserWaypoint and UiMapPoint and UiMapPoint.CreateFromCoordinates then
        local ok, point = pcall(UiMapPoint.CreateFromCoordinates, mapID, x, y)
        if ok and point then
            local okSet = pcall(C_Map.SetUserWaypoint, point)
            created = okSet and true or false
            if created and C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then
                pcall(C_SuperTrack.SetSuperTrackedUserWaypoint, true)
            end
        end
    end

    local zone = GetAreaText and GetAreaText() or ""
    local coords = FormatCoords(x, y)
    print(string.format("|cffffff00|Hworldmap:%d:%d:%d|h[|A:Waypoint-MapPin-ChatIcon:13:13:0:0|a %s: %s (%s)]|h|r", mapID, x * 10000, y * 10000, LT("My Position"), zone, coords))
    if not created and UIErrorsFrame and UIErrorsFrame.AddMessage then
        UIErrorsFrame:AddMessage(LT("Waypoint link created, but the map pin API is unavailable."))
    end
end


local meetingStoneBrokerPanel
local meetingStoneBrokerDesired
local meetingStoneLDBCallbackRegistered
local meetingStoneLDBCallbackTarget = {}
local meetingStoneRefreshQueued

local function Lib(name)
    local libStub = _G.LibStub
    if not libStub then return nil end

    local ok, lib
    -- Standard LibStub is a callable table, not a Lua function.  Some builds
    -- also expose GetLibrary directly, so support both paths.
    if type(libStub) == "table" and type(libStub.GetLibrary) == "function" then
        ok, lib = pcall(libStub.GetLibrary, libStub, name, true)
        if ok and lib then return lib end
    end

    if type(libStub) == "function" or type(getmetatable(libStub)) == "table" then
        ok, lib = pcall(libStub, name, true)
        if ok then return lib end
    end

    return nil
end

local function GetMeetingStoneEnv()
    local ace = Lib("AceAddon-3.0")
    local envLib = Lib("NetEaseEnv-1.0")
    local ms

    if ace and type(ace.GetAddon) == "function" then
        ms = SafeReturn(ace.GetAddon, ace, "MeetingStone", true)
    end

    local envList = envLib and envLib._NSList
    local env
    if envList then
        env = envList.MeetingStone or (ms and ms.baseName and envList[ms.baseName])

        if not env and ms then
            for _, candidate in pairs(envList) do
                if type(candidate) == "table" then
                    local addon = candidate.Addon
                    if addon == ms or candidate.DataBroker or candidate.MainPanel then
                        env = candidate
                        break
                    end
                end
            end
        end

        if not ms then
            for _, candidate in pairs(envList) do
                if type(candidate) == "table" then
                    local addon = candidate.Addon
                    if addon and (addon.name == "MeetingStone" or addon.baseName == "MeetingStone" or candidate.DataBroker) then
                        ms = addon
                        env = env or candidate
                        break
                    end
                end
            end
        end
    end

    if not ms and env and env.Addon then ms = env.Addon end
    return ms, env, envList
end

local function QueueMeetingStoneRefresh()
    if meetingStoneRefreshQueued then return end
    if RefreshInfoBarItem and not IsAnyInfoBarItemEnabled("meetingstone") then return end
    meetingStoneRefreshQueued = true
    local function run()
        meetingStoneRefreshQueued = nil
        if RefreshInfoBarItem then
            RefreshInfoBarItem("meetingstone")
        elseif DB().isInfoBar == true and ns.RefreshInfoBars then
            ns.RefreshInfoBars()
        end
    end
    if C_Timer and C_Timer.After then C_Timer.After(0, run) else run() end
end

local function RegisterMeetingStoneLDBCallback()
    if meetingStoneLDBCallbackRegistered then return end
    local ldb = Lib("LibDataBroker-1.1")
    if not ldb or type(ldb.RegisterCallback) ~= "function" then return end

    local function onChanged(event, name, key, value, object)
        -- LibDataBroker callback signature is:
        -- event, name, key, value, object.
        if name == "MeetingStone" and (not key or key == "text" or key == "flash" or key == "icon") then
            QueueMeetingStoneRefresh()
        end
    end

    local ok1 = pcall(ldb.RegisterCallback, meetingStoneLDBCallbackTarget, "LibDataBroker_AttributeChanged_MeetingStone", onChanged)
    local ok2 = pcall(ldb.RegisterCallback, meetingStoneLDBCallbackTarget, "LibDataBroker_AttributeChanged_MeetingStone_text", onChanged)
    meetingStoneLDBCallbackRegistered = ok1 or ok2
end

local function IsValidMeetingStoneDataBroker(candidate)
    return type(candidate) == "table" and (candidate.BrokerObject or candidate.BrokerPanel or candidate.BrokerText or type(candidate.UpdateLabel) == "function")
end

local function GetMeetingStoneBroker()
    RegisterMeetingStoneLDBCallback()

    local ms, env, envList = GetMeetingStoneEnv()
    local dataBroker = env and env.DataBroker

    if not IsValidMeetingStoneDataBroker(dataBroker) then dataBroker = nil end

    if not dataBroker and ms and type(ms.GetModule) == "function" then
        local module = SafeReturn(ms.GetModule, ms, "DataBroker", true)
        if IsValidMeetingStoneDataBroker(module) then dataBroker = module end
    end

    if not dataBroker and ms and type(ms.modules) == "table" then
        local module = ms.modules.DataBroker or ms.modules["DataBroker"]
        if IsValidMeetingStoneDataBroker(module) then dataBroker = module end
    end

    if not dataBroker and envList then
        for _, candidateEnv in pairs(envList) do
            local module = type(candidateEnv) == "table" and candidateEnv.DataBroker
            if IsValidMeetingStoneDataBroker(module) then
                dataBroker = module
                env = env or candidateEnv
                break
            end
        end
    end

    local panel = dataBroker and dataBroker.BrokerPanel
    local brokerObject = dataBroker and dataBroker.BrokerObject

    local ldb = Lib("LibDataBroker-1.1")
    if ldb and type(ldb.GetDataObjectByName) == "function" then
        local ldbObject = SafeReturn(ldb.GetDataObjectByName, ldb, "MeetingStone")
        if ldbObject then brokerObject = ldbObject end
    end

    if panel and (type(panel) ~= "table" or not panel.GetObjectType) then panel = nil end
    return panel, dataBroker, ms, env, brokerObject
end
local function SaveMeetingStoneBrokerOriginal(panel)
    if not panel or panel.qfxInfoBarOriginalSaved then return end
    panel.qfxInfoBarOriginalSaved = true
    panel.qfxInfoBarOriginalParent = panel.GetParent and panel:GetParent() or UIParent
    panel.qfxInfoBarOriginalScale = panel.GetScale and panel:GetScale() or 1
    panel.qfxInfoBarOriginalWidth = panel.GetWidth and panel:GetWidth() or nil
    panel.qfxInfoBarOriginalHeight = panel.GetHeight and panel:GetHeight() or nil
    panel.qfxInfoBarOriginalShown = panel.IsShown and panel:IsShown() or false
    if panel.GetBackdrop then panel.qfxInfoBarOriginalBackdrop = panel:GetBackdrop() end
    panel.qfxInfoBarOriginalPoints = {}
    local numPoints = panel.GetNumPoints and panel:GetNumPoints() or 0
    for i = 1, numPoints do
        local point, relTo, relPoint, x, y = panel:GetPoint(i)
        panel.qfxInfoBarOriginalPoints[i] = { point, relTo, relPoint, x, y }
    end
end

local function RestoreMeetingStoneBroker()
    -- Reuse QFXSystemBar's MeetingStone floating-window restore logic when
    -- available, so the micro-menu MeetingStone button and the info-bar
    -- MeetingStone item do not fight over the same floating panel state.
    if ns.SyncMeetingStoneFloatingPanel then
        ns.SyncMeetingStoneFloatingPanel()
        return
    end

    local panel = meetingStoneBrokerPanel
    if not panel or not panel.qfxInfoBarHiddenByInfoBar then return end
    panel.qfxInfoBarHiddenByInfoBar = nil
    if panel.SetScale then SafeCall(panel.SetScale, panel, panel.qfxInfoBarOriginalScale or 1) end
    if panel.ClearAllPoints then SafeCall(panel.ClearAllPoints, panel) end
    if panel.SetParent then SafeCall(panel.SetParent, panel, panel.qfxInfoBarOriginalParent or UIParent) end
    local points = panel.qfxInfoBarOriginalPoints
    if type(points) == "table" and #points > 0 and panel.SetPoint then
        for _, pt in ipairs(points) do
            SafeCall(panel.SetPoint, panel, pt[1], pt[2], pt[3], pt[4] or 0, pt[5] or 0)
        end
    elseif panel.SetPoint then
        SafeCall(panel.SetPoint, panel, "CENTER", panel.qfxInfoBarOriginalParent or UIParent, "CENTER", 0, 0)
    end
    if panel.qfxInfoBarOriginalWidth and panel.qfxInfoBarOriginalHeight and panel.SetSize then
        SafeCall(panel.SetSize, panel, panel.qfxInfoBarOriginalWidth, panel.qfxInfoBarOriginalHeight)
    end
    if panel.qfxInfoBarOriginalBackdrop and panel.SetBackdrop then SafeCall(panel.SetBackdrop, panel, panel.qfxInfoBarOriginalBackdrop) end
    if panel.qfxInfoBarOriginalShown then
        if panel.Show then SafeCall(panel.Show, panel) end
    else
        if panel.Hide then SafeCall(panel.Hide, panel) end
    end
end

local function HideMeetingStoneFloatingPanel()
    -- Prefer the main QFXSystemBar MeetingStone hiding helper. It preserves
    -- more of the original frame tree and avoids restore conflicts when both
    -- the micro-menu button and the info-bar item are enabled.
    if ns.HideMeetingStoneFloatingPanel then
        return ns.HideMeetingStoneFloatingPanel()
    end

    local panel = GetMeetingStoneBroker()
    if not panel then return false end
    SaveMeetingStoneBrokerOriginal(panel)
    meetingStoneBrokerPanel = panel
    panel.qfxInfoBarHiddenByInfoBar = true
    if panel.Hide then SafeCall(panel.Hide, panel) end
    return true
end

local function CallMeetingStoneBrokerClick(owner, button)
    local _, _, _, _, brokerObject = GetMeetingStoneBroker()
    if brokerObject and type(brokerObject.OnClick) == "function" then
        return SafeCall(brokerObject.OnClick, owner or UIParent, button or "LeftButton")
    end
    return false
end

local function ToggleMeetingStoneFallback(button, owner)
    local genericText = ns.GetPremadeAddonInfoBarText and ns.GetPremadeAddonInfoBarText()
    if genericText then
        if ns.EnsureMeetingStoneBridgeLoaded then ns.EnsureMeetingStoneBridgeLoaded() end
        if ns.ToggleMeetingStone then
            ns.ToggleMeetingStone(owner, button)
            return true
        end
    end

    if CallMeetingStoneBrokerClick(owner, button) then return true end

    local panel, _, ms, env = GetMeetingStoneBroker()
    if panel and panel.GetScript then
        local script = panel:GetScript("OnMouseUp") or panel:GetScript("OnClick")
        if script and SafeCall(script, panel, button or "LeftButton") then return true end
    end
    if panel and panel.Click and SafeCall(panel.Click, panel, button or "LeftButton") then return true end

    if ms then
        for _, method in ipairs({ "Toggle", "Open", "Show", "ToggleModule" }) do
            if type(ms[method]) == "function" and SafeCall(ms[method], ms) then return true end
        end
    end

    local mainPanel = env and env.MainPanel
    if mainPanel and mainPanel.IsShown and mainPanel.Show and mainPanel.Hide then
        if mainPanel:IsShown() then SafeCall(mainPanel.Hide, mainPanel) else SafeCall(mainPanel.Show, mainPanel) end
        return true
    end

    if SlashCmdList and SlashCmdList.MeetingStone then
        if SafeCall(SlashCmdList.MeetingStone) then return true end
    end

    if UIErrorsFrame and UIErrorsFrame.AddMessage then
        UIErrorsFrame:AddMessage(LT("MeetingStone is not loaded."))
    end
    return false
end

local function GetTimeText()
    local useLocal = GetCVarBool and GetCVarBool("timeMgrUseLocalTime")
    local hour, minute
    if useLocal then
        hour, minute = tonumber(date("%H")), tonumber(date("%M"))
    elseif GetGameTime then
        hour, minute = GetGameTime()
    else
        hour, minute = tonumber(date("%H")), tonumber(date("%M"))
    end

    if GetCVarBool and not GetCVarBool("timeMgrUseMilitaryTime") then
        local suffix = hour < 12 and "AM" or "PM"
        local display = hour % 12
        if display == 0 then display = 12 end
        return string.format("%d:%02d%s", display, minute or 0, MyColor() .. suffix .. "|r")
    end
    return string.format("%02d:%02d", hour or 0, minute or 0)
end



function ns.InfoBarReadSoundCVar(name, fallback)
    local value
    if C_CVar and C_CVar.GetCVar then
        value = SafeReturn(C_CVar.GetCVar, name)
    elseif GetCVar then
        value = SafeReturn(GetCVar, name)
    end
    local numberValue = tonumber(value)
    if numberValue ~= nil then return numberValue end
    return fallback
end

function ns.InfoBarWriteSoundCVar(name, value)
    value = tostring(value)
    if C_CVar and C_CVar.SetCVar then
        if SafeCall(C_CVar.SetCVar, name, value) then return true end
    end
    if SetCVar then return SafeCall(SetCVar, name, value) end
    return false
end

function ns.IsInfoBarMasterSoundMuted()
    local enabled = ns.InfoBarReadSoundCVar(VOLUME_MUTE_CVAR, 1)
    return enabled ~= nil and enabled <= 0
end

function ns.SetInfoBarMasterSoundMuted(muted)
    ns.InfoBarWriteSoundCVar(VOLUME_MUTE_CVAR, muted and 0 or 1)
end

function ns.GetInfoBarMasterVolumePercent()
    local raw = ns.InfoBarReadSoundCVar(VOLUME_MASTER_CVAR, 1) or 1
    raw = math.max(0, math.min(1, raw))
    return math.floor(raw * 100 + 0.5)
end

function ns.SetInfoBarMasterVolumePercent(percent)
    percent = math.max(0, math.min(100, tonumber(percent) or 0))
    ns.InfoBarWriteSoundCVar(VOLUME_MASTER_CVAR, percent / 100)
    if percent > 0 and ns.IsInfoBarMasterSoundMuted() then ns.SetInfoBarMasterSoundMuted(false) end
end

local function ReadAdvancedCombatLogState()
    if C_CVar and C_CVar.GetCVarBool then
        local ok, value = pcall(C_CVar.GetCVarBool, ADVANCED_COMBAT_LOG_CVAR)
        if ok and value ~= nil then return value and true or false end
    end
    if GetCVarBool then
        local ok, value = pcall(GetCVarBool, ADVANCED_COMBAT_LOG_CVAR)
        if ok and value ~= nil then return value and true or false end
    end

    local value
    if C_CVar and C_CVar.GetCVar then
        value = SafeReturn(C_CVar.GetCVar, ADVANCED_COMBAT_LOG_CVAR)
    elseif GetCVar then
        value = SafeReturn(GetCVar, ADVANCED_COMBAT_LOG_CVAR)
    end
    return value == true or value == 1 or value == "1" or value == "true"
end

local function WriteAdvancedCombatLogState(enabled)
    local value = enabled and "1" or "0"
    local ok
    if C_CVar and C_CVar.SetCVar then ok = SafeCall(C_CVar.SetCVar, ADVANCED_COMBAT_LOG_CVAR, value) end
    if not ok and SetCVar then ok = SafeCall(SetCVar, ADVANCED_COMBAT_LOG_CVAR, value) end
    if RefreshInfoBarItem then RefreshInfoBarItem("combatlog") end
    return ok
end

function ns.RefreshInfoBarVolumePanel()
    local panel = ns.infoBarVolumePanel
    if not panel or not panel.slider then return end
    ns.infoBarVolumeSliderInternalUpdate = true
    panel.slider:SetValue(ns.GetInfoBarMasterVolumePercent())
    ns.infoBarVolumeSliderInternalUpdate = nil
    if panel.title then panel.title:SetText(LT("Master Volume")) end
    if panel.status then
        local state = ns.IsInfoBarMasterSoundMuted() and LT("Muted") or (ns.GetInfoBarMasterVolumePercent() .. "%")
        panel.status:SetText(state)
    end
    local sliderName = panel.slider:GetName()
    if sliderName then
        local label = _G[sliderName .. "Text"]
        local low = _G[sliderName .. "Low"]
        local high = _G[sliderName .. "High"]
        -- The panel title and status already explain the control. Hiding the
        -- stock horizontal labels keeps the vertical slider clean.
        if label then label:SetText("") end
        if low then low:SetText("") end
        if high then high:SetText("") end
    end
end

function ns.EnsureInfoBarVolumePanel()
    if ns.infoBarVolumePanel then return ns.infoBarVolumePanel end

    local template = BackdropTemplateMixin and "BackdropTemplate" or nil
    local panel = CreateFrame("Frame", "QFXSystemBarVolumePanel", UIParent, template)
    ns.infoBarVolumePanel = panel
    panel:SetSize(82, 194)
    panel:SetFrameStrata("DIALOG")
    panel:EnableMouse(true)
    if panel.SetClampedToScreen then panel:SetClampedToScreen(true) end
    panel:Hide()
    if panel.SetBackdrop then
        panel:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
            insets = { left = 1, right = 1, top = 1, bottom = 1 },
        })
        panel:SetBackdropColor(0.05, 0.05, 0.05, 0.92)
        panel:SetBackdropBorderColor(0.25, 0.55, 0.9, 0.85)
    end

    panel.title = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    panel.title:SetPoint("TOP", panel, "TOP", 0, -8)
    panel.title:SetJustifyH("CENTER")

    panel.status = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    panel.status:SetPoint("BOTTOM", panel, "BOTTOM", 0, 8)
    panel.status:SetJustifyH("CENTER")

    local slider = CreateFrame("Slider", "QFXSystemBarMasterVolumeSlider", panel, "OptionsSliderTemplate")
    slider:SetOrientation("VERTICAL")
    slider:SetSize(22, 126)
    slider:SetPoint("TOP", panel.title, "BOTTOM", 0, -13)
    slider:SetMinMaxValues(0, 100)
    slider:SetValueStep(1)
    if slider.SetObeyStepOnDrag then slider:SetObeyStepOnDrag(true) end
    slider:SetScript("OnValueChanged", function(_, value)
        if ns.infoBarVolumeSliderInternalUpdate then return end
        local rounded = math.floor((tonumber(value) or 0) + 0.5)
        ns.SetInfoBarMasterVolumePercent(rounded)
        if panel.status then panel.status:SetText(rounded .. "%") end
        if RefreshInfoBarItem then RefreshInfoBarItem("volume") end
    end)
    panel.slider = slider

    if UISpecialFrames then table.insert(UISpecialFrames, "QFXSystemBarVolumePanel") end
    ns.RefreshInfoBarVolumePanel()
    return panel
end

local function AnchorInfoBarVolumePanel(panel, owner)
    panel:ClearAllPoints()
    if owner and owner.GetCenter and UIParent and UIParent.GetCenter then
        local ownerX = owner:GetCenter()
        local uiX = UIParent:GetCenter()
        if ownerX and uiX and ownerX > uiX then
            panel:SetPoint("RIGHT", owner, "LEFT", -8, 0)
        else
            panel:SetPoint("LEFT", owner, "RIGHT", 8, 0)
        end
    else
        panel:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end
end

function ns.ToggleInfoBarVolumePanel(owner)
    local panel = ns.EnsureInfoBarVolumePanel()
    if panel:IsShown() then panel:Hide(); return end
    ns.RefreshInfoBarVolumePanel()
    AnchorInfoBarVolumePanel(panel, owner)
    panel:Show()
end

function ns.ToggleInfoBarMasterMute()
    ns.SetInfoBarMasterSoundMuted(not ns.IsInfoBarMasterSoundMuted())
    ns.RefreshInfoBarVolumePanel()
    if RefreshInfoBarItem then RefreshInfoBarItem("volume") end
end

local tooltipByID
local ShowSystemTooltip
local ShowGoldTooltip
local ShowSimpleInfoBarTooltip
local HideTooltipTicker

do
local addonInfo = {}
local addonListBuilt

local function BuildAddonList()
    if addonListBuilt then return end
    addonListBuilt = true
    wipe(addonInfo)
    local addons = C_AddOns
    local num = addons and addons.GetNumAddOns and addons.GetNumAddOns() or 0
    for i = 1, num do
        local name, title, _, loadable = addons.GetAddOnInfo(i)
        if loadable then addonInfo[#addonInfo + 1] = { index = i, name = name, title = title or name, memory = 0, cpu = 0 } end
    end
end

local function IsAddonLoaded(index)
    if C_AddOns and C_AddOns.IsAddOnLoaded then return C_AddOns.IsAddOnLoaded(index) end
    if IsAddOnLoaded then return IsAddOnLoaded(index) end
    return false
end

local function SortByMemory(a, b)
    if a.memory == b.memory then return tostring(a.title) < tostring(b.title) end
    return a.memory > b.memory
end

local function SortByCPU(a, b)
    if a.cpu == b.cpu then return tostring(a.title) < tostring(b.title) end
    return a.cpu > b.cpu
end

local function UpdateAddonMemory()
    BuildAddonList()
    local updateMemory = UpdateAddOnMemoryUsage or (C_AddOns and C_AddOns.UpdateAddOnMemoryUsage)
    local getMemory = GetAddOnMemoryUsage or (C_AddOns and C_AddOns.GetAddOnMemoryUsage)
    if updateMemory then pcall(updateMemory) end
    local total = 0
    for _, data in ipairs(addonInfo) do
        if IsAddonLoaded(data.index) and getMemory then
            data.memory = getMemory(data.index) or 0
            total = total + data.memory
        else
            data.memory = 0
        end
    end
    table.sort(addonInfo, SortByMemory)
    return total
end

local function UpdateAddonCPU()
    BuildAddonList()
    local updateCPU = UpdateAddOnCPUUsage or (C_AddOns and C_AddOns.UpdateAddOnCPUUsage)
    local getCPU = GetAddOnCPUUsage or (C_AddOns and C_AddOns.GetAddOnCPUUsage)
    if updateCPU then pcall(updateCPU) end
    local total = 0
    for _, data in ipairs(addonInfo) do
        if IsAddonLoaded(data.index) and getCPU then
            data.cpu = getCPU(data.index) or 0
            total = total + data.cpu
        else
            data.cpu = 0
        end
    end
    table.sort(addonInfo, SortByCPU)
    return total
end

local function SetTooltipOwner(owner)
    local y
    if owner and owner.GetCenter then
        local _, centerY = owner:GetCenter()
        y = centerY
    end
    local screenHeight = (UIParent and UIParent.GetHeight and UIParent:GetHeight()) or GetScreenHeight() or 768
    local anchor = (y and y > screenHeight / 2) and "TOP" or "BOTTOM"
    local offset = anchor == "TOP" and -15 or 15
    GameTooltip:SetOwner(owner, "ANCHOR_" .. anchor, 0, offset)
end

HideTooltipTicker = function()
    if tooltipTicker then
        tooltipTicker:Cancel()
        tooltipTicker = nil
    end
end

local SIMPLE_INFOBAR_TOOLTIPS = {
    guild = { name = "Guild", left = "Open Guild" },
    friend = { name = "Friends", left = "Open Friends" },
    meetingstone = { name = "MeetingStone", left = "Open MeetingStone", right = "Open MeetingStone Menu" },
    zone = { name = "Location", left = "Open World Map", right = "Create Waypoint" },
    coords = { name = "Coordinates", left = "Open World Map", right = "Create Waypoint" },
    phase = { name = "Phase ID", left = "Print ID" },
    spec = { name = "Specialization", left = "Open Talents", right = "Change Loot Specialization" },
    ilvl = { name = "Item Level", left = "Open Character" },
    mplus = { name = "Mythic+ Score", left = "Open Group Finder" },
    dura = { name = "Durability", left = "Open Character" },
    gold = {
        name = "Gold",
        left = function() return showSlots and "Open Bags" or "Open Currency" end,
        right = "Toggle Bag Slots",
    },
    volume = { name = "Volume", left = "Open Volume Slider", right = "Toggle Mute" },
    combatlog = { name = "Advanced Combat Log", left = "Turn On", right = "Turn Off" },
    time = { name = "Time", left = "Open Calendar", right = "Open Clock" },
}

local function ResolveInfoBarTooltipText(value)
    if type(value) == "function" then
        local ok, result = pcall(value)
        if ok and result then return LT(tostring(result)) end
        return nil
    end
    if value ~= nil then return LT(tostring(value)) end
    return nil
end

local function FormatSignedMoney(value)
    value = tonumber(value) or 0
    if value > 0 then return "|cff55ff55+|r" .. FormatMoney(value, true) end
    if value < 0 then return "|cffff5555-|r" .. FormatMoney(-value, true) end
    return FormatMoney(0, true)
end

ShowSimpleInfoBarTooltip = function(owner, id)
    local data = SIMPLE_INFOBAR_TOOLTIPS[id]
    if not data then return end

    SetTooltipOwner(owner)
    GameTooltip:ClearLines()
    GameTooltip:AddLine(LT(data.name or id), 0, .6, 1)

    local left = ResolveInfoBarTooltipText(data.left)
    local right = ResolveInfoBarTooltipText(data.right)
    if left or right then GameTooltip:AddLine(" ") end
    if left then GameTooltip:AddLine(LeftButtonText() .. left, .6, .8, 1) end
    if right then GameTooltip:AddLine(RightButtonText() .. right, .6, .8, 1) end

    GameTooltip:Show()
end

local function ShowLatencyTooltip(owner)
    SetTooltipOwner(owner)
    GameTooltip:ClearLines()
    GameTooltip:AddLine(LATENCY_LABEL or LT("Latency"), 0, .6, 1)
    GameTooltip:AddLine(" ")
    local home, world = GetNetLatency()
    GameTooltip:AddDoubleLine(HOME_LATENCY or LT("Home Latency"), ColorLatency(home) .. " ms", .6, .8, 1, 1, 1, 1)
    GameTooltip:AddDoubleLine(WORLD_LATENCY or LT("World Latency"), ColorLatency(world) .. " ms", .6, .8, 1, 1, 1, 1)
    GameTooltip:Show()
end

ShowSystemTooltip = function(owner)
    SetTooltipOwner(owner)
    GameTooltip:ClearLines()

    local fps = math.floor((GetFramerate and GetFramerate() or 0) + 0.5)
    local home, world, latency = GetNetLatency()
    GameTooltip:AddDoubleLine("FPS", ColorFPS(fps), 0, .6, 1, 1, 1, 1)
    GameTooltip:AddDoubleLine(LT("Home Latency"), ColorLatency(home) .. " ms", .6, .8, 1, 1, 1, 1)
    GameTooltip:AddDoubleLine(LT("World Latency"), ColorLatency(world) .. " ms", .6, .8, 1, 1, 1, 1)
    GameTooltip:AddLine(" ")

    local scriptProfile = GetCVarBool and GetCVarBool("scriptProfile")
    local showCPUData = showCPU and scriptProfile
    local total = showCPUData and UpdateAddonCPU() or UpdateAddonMemory()
    local titleValue = showCPUData and string.format("%.3f ms", total / math.max(1, (GetTime and GetTime() or 0) - loginTime)) or FormatMemory(total)
    GameTooltip:AddDoubleLine(LT("System"), titleValue, 0, .6, 1, .6, .8, 1)
    GameTooltip:AddLine(" ")

    local shown = 0
    local expanded = IsShiftKeyDown and IsShiftKeyDown()
    local maxShown = expanded and math.huge or MAX_TOOLTIP_ADDONS
    if showCPUData then
        local passed = math.max(1, (GetTime and GetTime() or 0) - loginTime)
        for _, data in ipairs(addonInfo) do
            if IsAddonLoaded(data.index) then
                shown = shown + 1
                if shown <= maxShown then
                    GameTooltip:AddDoubleLine(data.title, string.format("%.3f ms", (data.cpu or 0) / passed), 1, 1, 1, .6, .8, 1)
                end
            end
        end
    else
        for _, data in ipairs(addonInfo) do
            if IsAddonLoaded(data.index) then
                shown = shown + 1
                if shown <= maxShown then
                    GameTooltip:AddDoubleLine(data.title, FormatMemory(data.memory), 1, 1, 1, .6, .8, 1)
                end
            end
        end
    end
    if shown > MAX_TOOLTIP_ADDONS and not expanded then
        GameTooltip:AddDoubleLine(LF("%d Hidden", shown - MAX_TOOLTIP_ADDONS), LT("Hold Shift"), .6, .8, 1, .6, .8, 1)
    end

    GameTooltip:AddDoubleLine(" ", LineString())
    GameTooltip:AddDoubleLine(" ", LeftButtonText() .. LT("Collect Memory") .. " ", 1, 1, 1, .6, .8, 1)
    if scriptProfile then GameTooltip:AddDoubleLine(" ", RightButtonText() .. LT("CPU / Memory") .. " ", 1, 1, 1, .6, .8, 1) end
    GameTooltip:AddDoubleLine(" ", MiddleButtonText() .. LT("CPU Usage") .. ": " .. (scriptProfile and "|cff55ff55" .. LT("ON") .. "|r" or "|cffff5555" .. LT("OFF") .. "|r") .. " ", 1, 1, 1, .6, .8, 1)
    GameTooltip:Show()
end

local function ShowZoneTooltip(owner)
    SetTooltipOwner(owner)
    GameTooltip:ClearLines()
    local x, y = GetCoords()
    local zone = GetAreaText and GetAreaText() or ""
    local subzone = GetMinimapZoneText and GetMinimapZoneText() or zone
    local coords = FormatCoords(x, y)
    GameTooltip:AddLine(string.format("%s |cffffffff(%s)|r", zone, coords), 0, .6, 1)
    if subzone and subzone ~= zone then
        GameTooltip:AddLine(" ")
        local r, g, b = GetZoneTextColor()
        GameTooltip:AddLine(subzone, r, g, b)
    end
    GameTooltip:AddDoubleLine(" ", LineString())
    GameTooltip:AddDoubleLine(" ", LeftButtonText() .. (WORLD_MAP or LT("World Map")) .. " ", 1, 1, 1, .6, .8, 1)
    GameTooltip:AddDoubleLine(" ", RightButtonText() .. LT("Create Waypoint") .. " ", 1, 1, 1, .6, .8, 1)
    GameTooltip:Show()
end

local function ShowCoordsTooltip(owner)
    SetTooltipOwner(owner)
    GameTooltip:ClearLines()
    local x, y, mapID = GetCoords()
    local coords = FormatCoords(x, y)
    GameTooltip:AddLine(LT("Coordinates"), 0, .6, 1)
    GameTooltip:AddLine(" ")
    GameTooltip:AddDoubleLine(MAP_AND_QUEST_LOG or WORLD_MAP or LT("Map"), mapID and tostring(mapID) or "--", .6, .8, 1, 1, 1, 1)
    GameTooltip:AddDoubleLine(PLAYER or LT("Player"), coords, .6, .8, 1, 1, 1, 1)
    GameTooltip:AddDoubleLine(" ", LineString())
    GameTooltip:AddDoubleLine(" ", LeftButtonText() .. (WORLD_MAP or LT("World Map")) .. " ", 1, 1, 1, .6, .8, 1)
    GameTooltip:AddDoubleLine(" ", RightButtonText() .. LT("Create Waypoint") .. " ", 1, 1, 1, .6, .8, 1)
    GameTooltip:Show()
end

local function ShowPhaseTooltip(owner)
    SetTooltipOwner(owner)
    GameTooltip:ClearLines()
    local id, kind = GetPhaseLikeID()
    local mapID = GetCurrentMapID()
    local instanceID
    if GetInstanceInfo then
        local ok, value = pcall(function() return select(8, GetInstanceInfo()) end)
        if ok then instanceID = tonumber(value) end
    end
    GameTooltip:AddLine(LT("Phase ID"), 0, .6, 1)
    GameTooltip:AddLine(" ")
    GameTooltip:AddDoubleLine(LT("Shown ID"), id and tostring(id) or "--", .6, .8, 1, 1, 1, 1)
    GameTooltip:AddDoubleLine(LT("Source"), kind == "instance" and LT("Instance ID") or LT("Map ID"), .6, .8, 1, 1, 1, 1)
    GameTooltip:AddDoubleLine(LT("Map ID"), mapID and tostring(mapID) or "--", .6, .8, 1, 1, 1, 1)
    if instanceID and instanceID > 0 then GameTooltip:AddDoubleLine(LT("Instance ID"), tostring(instanceID), .6, .8, 1, 1, 1, 1) end
    GameTooltip:Show()
end


local function ShowMeetingStoneTooltip(owner)
    if ns.GetPremadeAddonCounts then
        local count1, count2 = ns.GetPremadeAddonCounts()
        if count1 ~= nil then
            local name = (ns.GetPremadeAddonDisplayName and ns.GetPremadeAddonDisplayName()) or "MeetingStone"
            SetTooltipOwner(owner)
            GameTooltip:ClearLines()
            GameTooltip:AddLine(name, 0, .6, 1)
            GameTooltip:AddLine(" ")
            GameTooltip:AddDoubleLine("Applications", tostring(tonumber(count1) or 0), 1, 1, 1, .6, .8, 1)
            GameTooltip:AddDoubleLine("Groups", tostring(tonumber(count2) or 0), 1, 1, 1, .6, .8, 1)
            GameTooltip:AddLine(" ")
            GameTooltip:AddDoubleLine(" ", LeftButtonText() .. name, 1, 1, 1, .6, .8, 1)
            GameTooltip:Show()
            return
        end
    end
    if ns.ShowPremadeAddonTooltip and ns.ShowPremadeAddonTooltip(owner) then return end

    local _, _, _, _, brokerObject = GetMeetingStoneBroker()
    if brokerObject and type(brokerObject.OnEnter) == "function" and SafeCall(brokerObject.OnEnter, owner) then return end

    SetTooltipOwner(owner)
    GameTooltip:ClearLines()
    GameTooltip:AddLine(LT("MeetingStone"), 0, .6, 1)
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(LT("Show MeetingStone broker information on the info bar."), 1, 1, 1, true)
    GameTooltip:AddDoubleLine(" ", LeftButtonText() .. LT("MeetingStone"), 1, 1, 1, .6, .8, 1)
    GameTooltip:Show()
end

local function ShowSpecTooltip(owner)
    if not GetSpecialization or not GetSpecializationInfo then return end
    local spec = GetSpecialization()
    if not spec then return end
    SetTooltipOwner(owner)
    GameTooltip:ClearLines()
    GameTooltip:AddLine(TALENTS_BUTTON or SPECIALIZATION or LT("Talents"), 0, .6, 1)
    GameTooltip:AddLine(" ")
    local _, name, _, icon = GetSpecializationInfo(spec)
    local iconText = icon and ("|T" .. icon .. ":14:14:0:0:50:50:4:46:4:46|t ") or ""
    GameTooltip:AddLine(iconText .. (name or ""), .6, .8, 1)
    GameTooltip:AddDoubleLine(" ", LineString())
    GameTooltip:AddDoubleLine(" ", LeftButtonText() .. (TALENTS_BUTTON or LT("Talents")) .. " ", 1, 1, 1, .6, .8, 1)
    GameTooltip:AddDoubleLine(" ", RightButtonText() .. (SELECT_LOOT_SPECIALIZATION or LT("Loot Specialization")) .. " ", 1, 1, 1, .6, .8, 1)
    GameTooltip:Show()
end

local function ShowItemLevelTooltip(owner)
    SetTooltipOwner(owner)
    GameTooltip:ClearLines()
    local total, equipped
    if GetAverageItemLevel then total, equipped = GetAverageItemLevel() end
    GameTooltip:AddLine(STAT_AVERAGE_ITEM_LEVEL or LT("Item Level"), 0, .6, 1)
    GameTooltip:AddLine(" ")
    GameTooltip:AddDoubleLine(INVENTORY_TOOLTIP or LT("Equipped"), equipped and string.format("%.2f", equipped) or "--", .6, .8, 1, 1, 1, 1)
    GameTooltip:AddDoubleLine(TOTAL or LT("Total"), total and string.format("%.2f", total) or "--", .6, .8, 1, 1, 1, 1)
    GameTooltip:AddDoubleLine(" ", LineString())
    GameTooltip:AddDoubleLine(" ", LeftButtonText() .. (CHARACTER or LT("Character")) .. " ", 1, 1, 1, .6, .8, 1)
    GameTooltip:Show()
end

local function ShowDurabilityTooltip(owner)
    SetTooltipOwner(owner)
    GameTooltip:ClearLines()
    local total, equipped
    if GetAverageItemLevel then total, equipped = GetAverageItemLevel() end
    GameTooltip:AddDoubleLine(DURABILITY or LT("Durability"), string.format("%s: %s/%s", STAT_AVERAGE_ITEM_LEVEL or LT("Item Level"), equipped or "--", total or "--"), 0, .6, 1, 0, .6, 1)
    GameTooltip:AddLine(" ")
    for slot = 1, 19 do
        local cur, max = GetInventoryItemDurability(slot)
        if cur and max and max > 0 then
            local pct = math.floor(cur / max * 100 + 0.5)
            local slotName = _G["INVSLOT_" .. slot] or tostring(slot)
            GameTooltip:AddDoubleLine(slotName, ColorDurability(pct), 1, 1, 1, 1, 1, 1)
        end
    end
    GameTooltip:AddDoubleLine(" ", LineString())
    GameTooltip:AddDoubleLine(" ", LeftButtonText() .. (CHARACTER or LT("Character")) .. " ", 1, 1, 1, .6, .8, 1)
    GameTooltip:Show()
end

ShowGoldTooltip = function(owner)
    local data = ns.UpdateInfoBarMoneySession and ns.UpdateInfoBarMoneySession() or nil
    local earned = data and tonumber(data.earned) or 0
    local spent = data and tonumber(data.spent) or 0
    local net = earned - spent

    SetTooltipOwner(owner)
    GameTooltip:ClearLines()
    GameTooltip:AddLine(MONEY or LT("Money"), 0, .6, 1)
    GameTooltip:AddLine(" ")
    GameTooltip:AddDoubleLine(CHARACTER or LT("Character"), FormatMoney(GetMoney and GetMoney() or 0, true), .6, .8, 1, 1, 1, 1)
    GameTooltip:AddLine(" ")
    GameTooltip:AddDoubleLine(LT("Session Earned"), FormatSignedMoney(earned), .35, 1, .35, 1, 1, 1)
    GameTooltip:AddDoubleLine(LT("Session Spent"), spent > 0 and ("|cffff5555-|r" .. FormatMoney(spent, true)) or FormatMoney(0, true), 1, .35, .35, 1, 1, 1)
    GameTooltip:AddDoubleLine(LT("Session Net"), FormatSignedMoney(net), .6, .8, 1, 1, 1, 1)
    GameTooltip:AddDoubleLine(" ", LineString())
    GameTooltip:AddDoubleLine(" ", LeftButtonText() .. (CURRENCY or LT("Currency")) .. " ", 1, 1, 1, .6, .8, 1)
    GameTooltip:AddDoubleLine(" ", RightButtonText() .. (BAGSLOTTEXT or BAGS or LT("Bags")) .. " ", 1, 1, 1, .6, .8, 1)
    GameTooltip:Show()
end

local raidLockoutState = {
    entries = {},
    lastUpdate = 0,
    requestPending = false,
    owner = nil,
}
local RAID_LOCKOUT_CACHE_SECONDS = 60
local MAX_RAID_LOCKOUT_LINES = 12

local function FormatRaidResetTime(seconds)
    seconds = math.max(0, tonumber(seconds) or 0)
    if SecondsToTime then
        local ok, value = pcall(SecondsToTime, seconds, true, false, 2)
        if ok and type(value) == "string" and value ~= "" then return value end
    end
    local days = math.floor(seconds / 86400)
    local hours = math.floor((seconds % 86400) / 3600)
    if days > 0 then return string.format("%dd %dh", days, hours) end
    local minutes = math.max(1, math.floor((seconds % 3600) / 60))
    if hours > 0 then return string.format("%dh %dm", hours, minutes) end
    return string.format("%dm", minutes)
end

local function SortRaidLockouts(a, b)
    if a.name == b.name then return tostring(a.difficultyName or "") < tostring(b.difficultyName or "") end
    return tostring(a.name or "") < tostring(b.name or "")
end

local function UpdateRaidLockoutCache()
    wipe(raidLockoutState.entries)
    local count = GetNumSavedInstances and tonumber(GetNumSavedInstances()) or 0
    for index = 1, count do
        local name, _, reset, difficultyID, locked, extended, _, isRaid, _, difficultyName, numEncounters, encounterProgress = GetSavedInstanceInfo(index)
        reset = tonumber(reset) or 0
        if isRaid and locked and reset > 0 then
            raidLockoutState.entries[#raidLockoutState.entries + 1] = {
                name = name or LT("Unknown"),
                reset = reset,
                difficultyID = tonumber(difficultyID) or 0,
                difficultyName = difficultyName,
                total = tonumber(numEncounters) or 0,
                progress = tonumber(encounterProgress) or 0,
                extended = extended == true,
            }
        end
    end
    table.sort(raidLockoutState.entries, SortRaidLockouts)
    raidLockoutState.lastUpdate = GetTime and GetTime() or 0
    raidLockoutState.requestPending = false
end

local function RequestRaidLockoutInfo()
    if type(RequestRaidInfo) ~= "function" then return end
    local now = GetTime and GetTime() or 0
    if raidLockoutState.requestPending then return end
    if raidLockoutState.lastUpdate > 0 and (now - raidLockoutState.lastUpdate) < RAID_LOCKOUT_CACHE_SECONDS then return end

    raidLockoutState.requestPending = true
    local ok = pcall(RequestRaidInfo)
    if not ok then raidLockoutState.requestPending = false; return end
    if C_Timer and C_Timer.After then
        C_Timer.After(5, function() raidLockoutState.requestPending = false end)
    end
end

function ns.HandleInfoBarInstanceInfoUpdate()
    UpdateRaidLockoutCache()
    local owner = raidLockoutState.owner
    if owner and owner.id == "time" and owner.IsMouseOver and owner:IsMouseOver() and ns.ShowInfoBarTimeTooltip then
        ns.ShowInfoBarTimeTooltip(owner)
    end
end

function ns.ClearInfoBarTimeTooltipOwner(owner)
    if raidLockoutState.owner == owner then raidLockoutState.owner = nil end
end

function ns.ShowInfoBarTimeTooltip(owner)
    raidLockoutState.owner = owner
    SetTooltipOwner(owner)
    GameTooltip:ClearLines()
    GameTooltip:AddLine(TIME_LABEL or LT("Time"), 0, .6, 1)
    GameTooltip:AddLine(" ")
    GameTooltip:AddDoubleLine(LOCAL_TIME_LABEL or LT("Local Time"), date("%H:%M"), .6, .8, 1, 1, 1, 1)
    if GetGameTime then
        local h, m = GetGameTime()
        GameTooltip:AddDoubleLine(SERVER_TIME_LABEL or LT("Server Time"), string.format("%02d:%02d", h or 0, m or 0), .6, .8, 1, 1, 1, 1)
    end

    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(LT("Raid Lockouts"), 0, .6, 1)
    if raidLockoutState.lastUpdate <= 0 then
        GameTooltip:AddLine(LT("Loading raid lockouts..."), .6, .6, .6)
    elseif #raidLockoutState.entries == 0 then
        GameTooltip:AddLine(LT("No active raid lockouts."), .6, .6, .6)
    else
        local shown = math.min(#raidLockoutState.entries, MAX_RAID_LOCKOUT_LINES)
        for index = 1, shown do
            local data = raidLockoutState.entries[index]
            local left = data.name
            if data.difficultyName and data.difficultyName ~= "" then
                left = string.format("%s |cff888888(%s)|r", left, data.difficultyName)
            end
            if data.extended then left = left .. " |cffffaa00" .. LT("Extended") .. "|r" end
            local progress = string.format("%d/%d", data.progress, data.total)
            local reset = FormatRaidResetTime(data.reset)
            GameTooltip:AddDoubleLine(left, progress .. "  |cff888888" .. reset .. "|r", 1, 1, 1, .6, .8, 1)
        end
        if #raidLockoutState.entries > shown then
            GameTooltip:AddLine(LF("%d Hidden", #raidLockoutState.entries - shown), .6, .6, .6)
        end
    end

    GameTooltip:AddDoubleLine(" ", LineString())
    GameTooltip:AddDoubleLine(" ", LeftButtonText() .. (CALENDAR or LT("Calendar")) .. " ", 1, 1, 1, .6, .8, 1)
    GameTooltip:AddDoubleLine(" ", RightButtonText() .. (TIMEMANAGER_TITLE or LT("Clock")) .. " ", 1, 1, 1, .6, .8, 1)
    GameTooltip:Show()
    RequestRaidLockoutInfo()
end

local function ShowMythicPlusTooltip(owner)
    SetTooltipOwner(owner)
    GameTooltip:ClearLines()
    GameTooltip:AddLine(CHALLENGE_MODE or LT("Mythic+"), 0, .6, 1)
    GameTooltip:AddLine(" ")
    local score = GetMythicPlusScore()
    GameTooltip:AddDoubleLine(LT("Score"), ColorMythicPlusScore(score), .6, .8, 1, 1, 1, 1)
    GameTooltip:AddDoubleLine(" ", LineString())
    GameTooltip:AddDoubleLine(" ", LeftButtonText() .. (PVE_FRAME_LABEL or DUNGEONS_BUTTON or LT("Group Finder")) .. " ", 1, 1, 1, .6, .8, 1)
    GameTooltip:Show()
end


tooltipByID = {
    guild = function(owner) ShowSimpleInfoBarTooltip(owner, "guild") end,
    friend = function(owner) ShowSimpleInfoBarTooltip(owner, "friend") end,
    meetingstone = function(owner) ShowSimpleInfoBarTooltip(owner, "meetingstone") end,
    fps = ShowSystemTooltip,
    combatlog = function(owner) ShowSimpleInfoBarTooltip(owner, "combatlog") end,
    zone = function(owner) ShowSimpleInfoBarTooltip(owner, "zone") end,
    coords = function(owner) ShowSimpleInfoBarTooltip(owner, "coords") end,
    phase = function(owner) ShowSimpleInfoBarTooltip(owner, "phase") end,
    spec = function(owner) ShowSimpleInfoBarTooltip(owner, "spec") end,
    ilvl = function(owner) ShowSimpleInfoBarTooltip(owner, "ilvl") end,
    mplus = function(owner) ShowSimpleInfoBarTooltip(owner, "mplus") end,
    dura = function(owner) ShowSimpleInfoBarTooltip(owner, "dura") end,
    gold = ShowGoldTooltip,
    volume = function(owner) ShowSimpleInfoBarTooltip(owner, "volume") end,
    time = function(owner) ns.ShowInfoBarTimeTooltip(owner) end,
}
end


local ToggleLootSpecMenu

do
local lootSpecDropDown

local function RefreshInfoBarsSoon()
    if C_Timer and C_Timer.After then
        C_Timer.After(0.05, function() if ns.RefreshInfoBars then ns.RefreshInfoBars() end end)
    elseif ns.RefreshInfoBars then
        ns.RefreshInfoBars()
    end
end

local function SelectLootSpec(_, index)
    index = tonumber(index) or 0
    if SetLootSpecialization then pcall(SetLootSpecialization, index) end
    if CloseDropDownMenus then CloseDropDownMenus() end
    RefreshInfoBarsSoon()
end

local function IsLootSpecSelected(index)
    return (GetLootSpecialization and GetLootSpecialization() or 0) == (tonumber(index) or 0)
end

local function CheckLootSpec(self)
    return IsLootSpecSelected(self and self.arg1)
end

local function SafeFormat(fmt, value)
    if type(fmt) == "string" then
        local ok, result = pcall(string.format, fmt, value)
        if ok and result then return result end
    end
    return "Default (" .. tostring(value or NONE or "None") .. ")"
end

local function BuildLootSpecMenu()
    local menu = {
        { text = SELECT_LOOT_SPECIALIZATION or LT("Loot Specialization"), isTitle = true, notCheckable = true },
    }
    local currentSpec = GetSpecialization and GetSpecialization()
    local currentName = currentSpec and GetSpecializationInfo and select(2, GetSpecializationInfo(currentSpec)) or (NONE or "None")
    menu[#menu + 1] = {
        text = SafeFormat(LOOT_SPECIALIZATION_DEFAULT or "Default (%s)", currentName),
        arg1 = 0,
        func = SelectLootSpec,
        checked = CheckLootSpec,
    }

    local numSpecs = GetNumSpecializations and GetNumSpecializations() or 4
    for i = 1, numSpecs do
        if GetSpecializationInfo then
            local id, name, _, icon = GetSpecializationInfo(i)
            if id and name then
                menu[#menu + 1] = {
                    text = name,
                    icon = icon,
                    arg1 = id,
                    func = SelectLootSpec,
                    checked = CheckLootSpec,
                }
            end
        end
    end
    return menu
end

ToggleLootSpecMenu = function(owner)
    owner = owner or UIParent
    if GameTooltip then GameTooltip:Hide() end

    -- Retail's newer context-menu API is preferred when available.  The old
    -- EasyMenu path is kept as a fallback for clients/addon loads that still
    -- expose UIDropDownMenu.
    if MenuUtil and MenuUtil.CreateContextMenu then
        local ok = pcall(MenuUtil.CreateContextMenu, owner, function(_, rootDescription)
            rootDescription:CreateTitle(SELECT_LOOT_SPECIALIZATION or LT("Loot Specialization"))

            local currentSpec = GetSpecialization and GetSpecialization()
            local currentName = currentSpec and GetSpecializationInfo and select(2, GetSpecializationInfo(currentSpec)) or (NONE or "None")
            rootDescription:CreateRadio(
                SafeFormat(LOOT_SPECIALIZATION_DEFAULT or "Default (%s)", currentName),
                function() return IsLootSpecSelected(0) end,
                function() SelectLootSpec(nil, 0) end
            )

            local numSpecs = GetNumSpecializations and GetNumSpecializations() or 4
            for i = 1, numSpecs do
                if GetSpecializationInfo then
                    local id, name = GetSpecializationInfo(i)
                    if id and name then
                        rootDescription:CreateRadio(
                            name,
                            function() return IsLootSpecSelected(id) end,
                            function() SelectLootSpec(nil, id) end
                        )
                    end
                end
            end
        end)
        if ok then return end
    end

    if not EasyMenu and C_AddOns and C_AddOns.LoadAddOn then
        pcall(C_AddOns.LoadAddOn, "Blizzard_UIDropDownMenu")
    elseif not EasyMenu and LoadAddOn then
        pcall(LoadAddOn, "Blizzard_UIDropDownMenu")
    end
    if not EasyMenu then return end

    if not lootSpecDropDown then
        local ok, frame = pcall(CreateFrame, "Frame", "QFXSystemBarInfoBarLootSpecDropDown", UIParent, "UIDropDownMenuTemplate")
        if ok then lootSpecDropDown = frame end
    end
    if lootSpecDropDown then
        EasyMenu(BuildLootSpecMenu(), lootSpecDropDown, owner, -80, 100, "MENU", 1)
    end
end
end

local function HandleClick(id, button, owner)
    if id == "guild" then
        if button ~= "LeftButton" or not IsInGuild or not IsInGuild() then return end
        if SafeClickNativeButton("GuildMicroButton") then return end
        LoadBlizzardAddon("Blizzard_Communities")
        if CommunitiesFrame and ToggleFrame then SafeCall(ToggleFrame, CommunitiesFrame) end
    elseif id == "friend" then
        if button ~= "LeftButton" then return end
        if SafeClickNativeButton("FriendsMicroButton", "SocialMicroButton", "QuickJoinToastButton") then return end
        if ToggleFriendsFrame then SafeCall(ToggleFriendsFrame) end
    elseif id == "meetingstone" then
        ToggleMeetingStoneFallback(button, owner)
    elseif id == "fps" then
        if button == "LeftButton" then
            local before = collectgarbage("count")
            collectgarbage("collect")
            local freed = math.max(0, before - collectgarbage("count"))
            print(string.format("|cff66C6FFQFXSystemBar:|r %s %s.", COLLECT_MEMORY or LT("Collect Memory"), FormatMemory(freed)))
            if owner then ShowSystemTooltip(owner) end
        elseif button == "RightButton" then
            if GetCVarBool and GetCVarBool("scriptProfile") then
                showCPU = not showCPU
                if owner then ShowSystemTooltip(owner) end
            end
        elseif button == "MiddleButton" and GetCVarBool and SetCVar then
            SetCVar("scriptProfile", GetCVarBool("scriptProfile") and 0 or 1)
            if StaticPopupDialogs and StaticPopupDialogs["QFXSYSTEMBAR_RELOAD_REQUIRED"] then StaticPopupDialogs["QFXSYSTEMBAR_RELOAD_REQUIRED"].text = LT("CPU profiling requires a UI reload to fully apply.") end
                StaticPopup_Show("QFXSYSTEMBAR_RELOAD_REQUIRED")
        end
    elseif id == "combatlog" then
        if button == "LeftButton" then
            WriteAdvancedCombatLogState(true)
        elseif button == "RightButton" then
            WriteAdvancedCombatLogState(false)
        end
        if owner then ShowSimpleInfoBarTooltip(owner, "combatlog") end
    elseif id == "zone" then
        if button == "LeftButton" then
            if BlockInCombat() then return end
            if ToggleWorldMap then SafeCall(ToggleWorldMap)
            elseif WorldMapFrame and ToggleFrame then SafeCall(ToggleFrame, WorldMapFrame) end
        elseif button == "RightButton" then
            CreatePlayerWaypoint()
        end
    elseif id == "coords" then
        if button == "LeftButton" then
            if BlockInCombat() then return end
            if ToggleWorldMap then SafeCall(ToggleWorldMap)
            elseif WorldMapFrame and ToggleFrame then SafeCall(ToggleFrame, WorldMapFrame) end
        elseif button == "RightButton" then
            CreatePlayerWaypoint()
        end
    elseif id == "phase" then
        if button == "LeftButton" then
            local idValue, kind = GetPhaseLikeID()
            print(LF("QFXSystemBar: Phase ID: %s (%s).", tostring(idValue or "--"), kind == "instance" and LT("Instance ID") or LT("Map ID")))
        end
    elseif id == "spec" then
        if button == "LeftButton" then
            if SafeClickNativeButton("PlayerSpellsMicroButton", "SpellbookMicroButton", "TalentMicroButton") then return end
            if BlockInCombat() then return end
            if PlayerSpellsUtil and PlayerSpellsUtil.ToggleClassTalentOrSpecFrame then SafeCall(PlayerSpellsUtil.ToggleClassTalentOrSpecFrame)
            elseif ToggleTalentFrame then SafeCall(ToggleTalentFrame) end
        elseif button == "RightButton" then
            ToggleLootSpecMenu(owner)
        end
    elseif id == "ilvl" then
        if button == "LeftButton" then
            if SafeClickNativeButton("CharacterMicroButton") then return end
            if BlockInCombat() then return end
            if ToggleCharacter then SafeCall(ToggleCharacter, "PaperDollFrame") end
        end
    elseif id == "mplus" then
        if button == "LeftButton" then
            if SafeClickNativeButton("LFDMicroButton") then return end
            if BlockInCombat() then return end
            if PVEFrame_ToggleFrame then SafeCall(PVEFrame_ToggleFrame, "GroupFinderFrame")
            elseif ToggleLFDParentFrame then SafeCall(ToggleLFDParentFrame)
            elseif TogglePVEFrame then SafeCall(TogglePVEFrame) end
        end
    elseif id == "dura" then
        if button == "LeftButton" then
            if SafeClickNativeButton("CharacterMicroButton") then return end
            if BlockInCombat() then return end
            if ToggleCharacter then SafeCall(ToggleCharacter, "PaperDollFrame") end
        end
    elseif id == "gold" then
        if button == "RightButton" then
            showSlots = not showSlots
            RefreshInfoBarItem("gold")
            if owner then ShowGoldTooltip(owner) end
        elseif button == "LeftButton" then
            if showSlots then
                if ToggleAllBags then SafeCall(ToggleAllBags) end
            else
                if BlockInCombat() then return end
                if ToggleCharacter then SafeCall(ToggleCharacter, "TokenFrame") end
            end
        end
    elseif id == "volume" then
        if button == "LeftButton" then
            ns.ToggleInfoBarVolumePanel(owner)
        elseif button == "RightButton" then
            ns.ToggleInfoBarMasterMute()
        end
    elseif id == "time" then
        if button == "LeftButton" then
            ToggleCalendarSafe()
        elseif button == "RightButton" then
            if ToggleTimeManager then SafeCall(ToggleTimeManager) end
        end
    end
end

local function GetSlot(slotKey)
    return ns.InfoBarSlots and ns.InfoBarSlots[slotKey]
end

local function ClampNumber(value, minValue, maxValue, defaultValue)
    value = tonumber(value)
    if value == nil then value = defaultValue end
    if minValue and value < minValue then value = minValue end
    if maxValue and value > maxValue then value = maxValue end
    return value
end

local function GetBarWidth(slotKey)
    local slot = GetSlot(slotKey)
    local default = (ns.defaults and slot and ns.defaults[slot.widthKey]) or DEFAULT_INFOBAR_WIDTH
    return ClampNumber(slot and DB()[slot.widthKey], 260, 900, default)
end

local function GetBarHeight(slotKey)
    local slot = GetSlot(slotKey)
    local default = (ns.defaults and slot and ns.defaults[slot.heightKey]) or DEFAULT_INFOBAR_HEIGHT
    return ClampNumber(slot and DB()[slot.heightKey], 12, 40, default)
end

local function GetInfoBarFontSize()
    local default = (ns.defaults and ns.defaults.infoBarFontSize) or DEFAULT_INFOBAR_FONT_SIZE
    return ClampNumber(DB().infoBarFontSize, 8, 20, default)
end

local VALID_LINE_STYLES = {
    ["eui-unitframes"] = true,
    ["eui-taskbar"] = true,
}

local VALID_LINE_POSITIONS = {
    top = true,
    bottom = true,
    both = true,
    hidden = true,
}

local LEGACY_LINE_POSITION = {
    ["thin-bottom"] = "bottom",
    ["thin-top"] = "top",
    ["thin-both"] = "both",
    ["outer-both"] = "both",
    hidden = "hidden",
}

local LEGACY_LINE_STYLE = {
    ["thin-bottom"] = "eui-unitframes",
    ["thin-top"] = "eui-unitframes",
    ["thin-both"] = "eui-unitframes",
    ["outer-both"] = "eui-taskbar",
    hidden = DEFAULT_INFOBAR_LINE_STYLE,
}

local function GetInfoBarLineThickness(slotKey)
    local slot = GetSlot(slotKey)
    local key = slot and slot.lineThicknessKey
    local default = (ns.defaults and key and ns.defaults[key]) or DEFAULT_INFOBAR_LINE_THICKNESS
    return ClampNumber(key and DB()[key], 1, 6, default)
end

local function GetInfoBarLineStyle(slotKey)
    local slot = GetSlot(slotKey)
    local key = slot and slot.lineStyleKey
    local style = key and DB()[key]
    if VALID_LINE_STYLES[style] then return style end
    return (ns.defaults and key and ns.defaults[key]) or DEFAULT_INFOBAR_LINE_STYLE
end

local function GetInfoBarLinePosition(slotKey)
    local slot = GetSlot(slotKey)
    local key = slot and slot.linePositionKey
    local pos = key and DB()[key]
    if VALID_LINE_POSITIONS[pos] then return pos end
    return (ns.defaults and key and ns.defaults[key]) or (slotKey == "right" and DEFAULT_INFOBAR_LINE_POSITION_RIGHT or DEFAULT_INFOBAR_LINE_POSITION_LEFT)
end

local function InsertMissingInfoBarItem(order, seen, id)
    if seen[id] then return end

    local index = INFOBAR_ITEM_INDEX[id] or (#INFOBAR_ITEM_ORDER + 1)
    local insertAt = #order + 1
    for i = #order, 1, -1 do
        local existingIndex = INFOBAR_ITEM_INDEX[order[i]] or (#INFOBAR_ITEM_ORDER + 1)
        if existingIndex < index then
            insertAt = i + 1
            break
        end
        insertAt = i
    end

    table.insert(order, insertAt, id)
    seen[id] = true
end

local function NormalizeInfoBarOrder(order)
    local seen, out = {}, {}
    for _, rawID in ipairs(order or {}) do
        local id = ns.NormalizeInfoBarItemID and ns.NormalizeInfoBarItemID(rawID) or rawID
        if id and ns.InfoBarItems[id] and not seen[id] then
            out[#out + 1] = id
            seen[id] = true
        end
    end
    for _, id in ipairs(INFOBAR_ITEM_ORDER) do
        InsertMissingInfoBarItem(out, seen, id)
    end
    return out
end

function ns.MigrateInfoBarSavedVariables(db)
    if type(db) ~= "table" then return end
    for _, slot in pairs(ns.InfoBarSlots or {}) do
        if type(slot) == "table" then
            if type(db[slot.orderKey]) == "table" then
                db[slot.orderKey] = NormalizeInfoBarOrder(db[slot.orderKey])
            end
            if type(db[slot.enabledKey]) == "table" then
                NormalizeInfoBarEnabledMap(db[slot.enabledKey])
            end
        end
    end
end

local function EnsureInfoBarDefaults()
    local db = DB()
    if db.isInfoBar == nil then
        db.isInfoBar = ns.defaults.isInfoBar == true
    end
    if db.infoBarFadeStrength == nil then
        db.infoBarFadeStrength = ClampNumber(db.infoBarLeftFadeStrength or db.infoBarRightFadeStrength, 0, 100, ns.defaults.infoBarFadeStrength or 50)
    else
        db.infoBarFadeStrength = ClampNumber(db.infoBarFadeStrength, 0, 100, ns.defaults.infoBarFadeStrength or 50)
    end
    if db.infoBarFontSize == nil then
        db.infoBarFontSize = ns.defaults.infoBarFontSize or DEFAULT_INFOBAR_FONT_SIZE
    else
        db.infoBarFontSize = ClampNumber(db.infoBarFontSize, 8, 20, ns.defaults.infoBarFontSize or DEFAULT_INFOBAR_FONT_SIZE)
    end
    local legacyThickness = ClampNumber(db.infoBarLineThickness, 1, 6, ns.defaults.infoBarLineThickness or DEFAULT_INFOBAR_LINE_THICKNESS)
    local legacyStyle = db.infoBarLineStyle
    local legacyMappedStyle = LEGACY_LINE_STYLE[legacyStyle]
    local legacyMappedPosition = LEGACY_LINE_POSITION[legacyStyle]

    local upgradeDefaultLinePlacement = db.infoBarBothOutsideLineDefaultMigrated ~= true
        and db.infoBarLeftLineStyle == "eui-taskbar"
        and db.infoBarRightLineStyle == "eui-taskbar"
        and (db.infoBarLeftLinePosition == nil or db.infoBarLeftLinePosition == "bottom")
        and (db.infoBarRightLinePosition == nil or db.infoBarRightLinePosition == "top")

    for slotKey, slot in pairs(ns.InfoBarSlots or {}) do
        if db[slot.barEnabledKey] == nil then db[slot.barEnabledKey] = ns.defaults[slot.barEnabledKey] == true end
        if db[slot.widthKey] == nil then db[slot.widthKey] = ns.defaults[slot.widthKey] or DEFAULT_INFOBAR_WIDTH end
        if db[slot.heightKey] == nil then db[slot.heightKey] = ns.defaults[slot.heightKey] or DEFAULT_INFOBAR_HEIGHT end
        if db[slot.fadeKey] == nil then db[slot.fadeKey] = ns.defaults[slot.fadeKey] or slot.defaultFade or "left" end
        if slot.lineThicknessKey then
            db[slot.lineThicknessKey] = ClampNumber(db[slot.lineThicknessKey], 1, 6, legacyThickness or ns.defaults[slot.lineThicknessKey] or DEFAULT_INFOBAR_LINE_THICKNESS)
        end
        if slot.lineStyleKey and db[slot.lineStyleKey] == "ndui" then
            db[slot.lineStyleKey] = "eui-taskbar"
        end
        if slot.lineStyleKey and not VALID_LINE_STYLES[db[slot.lineStyleKey]] then
            db[slot.lineStyleKey] = legacyMappedStyle or ns.defaults[slot.lineStyleKey] or DEFAULT_INFOBAR_LINE_STYLE
        end
        if slot.linePositionKey and not VALID_LINE_POSITIONS[db[slot.linePositionKey]] then
            if legacyMappedPosition then
                if legacyStyle == "thin-bottom" and slotKey == "right" then
                    db[slot.linePositionKey] = "top"
                else
                    db[slot.linePositionKey] = legacyMappedPosition
                end
            else
                db[slot.linePositionKey] = ns.defaults[slot.linePositionKey] or (slotKey == "right" and DEFAULT_INFOBAR_LINE_POSITION_RIGHT or DEFAULT_INFOBAR_LINE_POSITION_LEFT)
            end
        end
        if db[slot.xKey] == nil then db[slot.xKey] = slot.defaultX or 0 end
        if db[slot.yKey] == nil then db[slot.yKey] = slot.defaultY or 0 end
        if db[slot.unlockedKey] == nil then db[slot.unlockedKey] = false end
        if type(db[slot.orderKey]) ~= "table" then db[slot.orderKey] = CopyArray(ns.defaults[slot.orderKey] or INFOBAR_ITEM_ORDER) end
        if type(db[slot.enabledKey]) ~= "table" then db[slot.enabledKey] = CopyMap(ns.defaults[slot.enabledKey] or slot.defaultItems or {}) end
        NormalizeInfoBarEnabledMap(db[slot.enabledKey])

        -- 1.7.81 default layout update: keep the default left info strip to
        -- four items: Item Level / Mythic+ Score / FPS / Advanced Combat Log.
        -- MeetingStone stays available, but is no longer enabled by default.
        -- Only migrate exact previous default layouts, so custom layouts are
        -- not overwritten.
        if slotKey == "left" and db.infoBarLeftCombatLogDefaultMigrated ~= true then
            local enabledItems = db[slot.enabledKey]
            if type(enabledItems) == "table" then
                local enabledCount = 0
                for _, enabled in pairs(enabledItems) do if enabled == true then enabledCount = enabledCount + 1 end end
                if enabledItems.ilvl == true and enabledItems.mplus == true and enabledItems.meetingstone == true then
                    if enabledItems.fps == true and enabledCount == 4 and enabledItems.combatlog ~= true then
                        enabledItems.meetingstone = nil
                        enabledItems.combatlog = true
                    elseif enabledItems.fps == true and enabledCount == 5 and enabledItems.combatlog == true then
                        enabledItems.meetingstone = nil
                    elseif enabledItems.combatlog == true and enabledCount == 4 and enabledItems.fps ~= true then
                        enabledItems.meetingstone = nil
                        enabledItems.fps = true
                    end
                end
            end
        end

        -- 1.7.77 default layout update: keep the default right info strip to
        -- four items and do not include Time by default. Only migrate exact
        -- old default layouts, so custom layouts are not overwritten.
        if slotKey == "right" and db.infoBarRightNoTimeDefaultMigrated ~= true then
            local enabledItems = db[slot.enabledKey]
            if type(enabledItems) == "table" then
                local enabledCount = 0
                for _, enabled in pairs(enabledItems) do if enabled == true then enabledCount = enabledCount + 1 end end
                if enabledItems.spec == true and enabledItems.dura == true and enabledItems.gold == true then
                    if enabledCount == 4 and enabledItems.time == true and enabledItems.volume ~= true then
                        enabledItems.time = nil
                        enabledItems.volume = true
                    elseif enabledCount == 5 and enabledItems.time == true and enabledItems.volume == true then
                        enabledItems.time = nil
                    end
                end
            end
        end

        local out = NormalizeInfoBarOrder(db[slot.orderKey])
        db[slot.orderKey] = out

        local kept = 0
        local enabledItems = db[slot.enabledKey]
        if type(enabledItems) == "table" then
            for _, id in ipairs(out) do
                if enabledItems[id] == true then
                    kept = kept + 1
                    if kept > MAX_INFOBAR_ITEMS_PER_BAR then enabledItems[id] = false end
                end
            end
        end
    end

    -- 1.7.73 default line placement update: both info strips now show the
    -- EUI Taskbar-style class rails on both outside edges by default. Migrate
    -- only the previous default pair (left bottom / right top) so custom top,
    -- bottom, both, or hidden choices are left alone.
    if upgradeDefaultLinePlacement then
        db.infoBarLeftLinePosition = "both"
        db.infoBarRightLinePosition = "both"
    end
    db.infoBarBothOutsideLineDefaultMigrated = true
    db.infoBarVolumeDefaultMigrated = true
    db.infoBarCombatLogDefaultMigrated = true
    db.infoBarFourItemDefaultMigrated = true
    db.infoBarLeftFPSDefaultMigrated = true
    db.infoBarLeftCombatLogDefaultMigrated = true
    db.infoBarRightNoTimeDefaultMigrated = true
end

local function GetOrderForSlot(slotKey)
    EnsureInfoBarDefaults()
    local slot = GetSlot(slotKey)
    return slot and DB()[slot.orderKey] or INFOBAR_ITEM_ORDER
end

local function IsSlotEnabled(slotKey)
    local slot = GetSlot(slotKey)
    if not slot then return false end
    return DB().isInfoBar == true and DB()[slot.barEnabledKey] == true
end

local function GetEnabledItemCount(slotKey)
    local slot = GetSlot(slotKey)
    if not slot then return 0 end
    local enabled = DB()[slot.enabledKey]
    if type(enabled) ~= "table" then return 0 end
    local count = 0
    for _, id in ipairs(GetOrderForSlot(slotKey)) do
        if enabled[id] == true then count = count + 1 end
    end
    return count
end

local function EnforceInfoBarItemLimit(slotKey)
    local slot = GetSlot(slotKey)
    if not slot then return end
    local enabled = DB()[slot.enabledKey]
    if type(enabled) ~= "table" then return end

    local kept = 0
    for _, id in ipairs(GetOrderForSlot(slotKey)) do
        if enabled[id] == true then
            kept = kept + 1
            if kept > MAX_INFOBAR_ITEMS_PER_BAR then enabled[id] = false end
        end
    end
end

local function IsItemEnabled(slotKey, id)
    local slot = GetSlot(slotKey)
    if not slot then return false end
    local enabled = DB()[slot.enabledKey]
    return type(enabled) == "table" and enabled[id] == true
end

IsAnyInfoBarItemEnabled = function(id)
    if not id or DB().isInfoBar ~= true then return false end
    for slotKey in pairs(ns.InfoBarSlots or {}) do
        if IsSlotEnabled(slotKey) and IsItemEnabled(slotKey, id) then return true end
    end
    return false
end

-- Shared by the main micro-menu module.  MeetingStone's own floating broker
-- window must stay hidden not only when the micro-menu MeetingStone button is
-- enabled, but also when the info bar is using MeetingStone as one of its
-- visible data items.  This keeps /reload and fresh login from restoring the
-- MeetingStone floating window behind the user's back.
function ns.IsMeetingStoneInfoBarActive()
    EnsureInfoBarDefaults()
    return IsAnyInfoBarItemEnabled("meetingstone")
end

local function IsAnyInfoBarShown()
    if DB().isInfoBar ~= true then return false end
    for slotKey in pairs(ns.InfoBarSlots or {}) do
        if IsSlotEnabled(slotKey) and GetEnabledItemCount(slotKey) > 0 then return true end
    end
    return false
end

local function IsInfoBarEventNeeded(event)
    if event == "PLAYER_ENTERING_WORLD" then return IsAnyInfoBarShown() end
    if event == "ADDON_LOADED" then return IsAnyInfoBarItemEnabled("meetingstone") end
    local filter = EVENT_ITEM_REFRESH[event]
    if type(filter) ~= "table" then return false end
    for id in pairs(filter) do
        if IsAnyInfoBarItemEnabled(id) then return true end
    end
    return false
end

function ns.GetInfoBarEnabledCount(slotKey)
    EnsureInfoBarDefaults()
    return GetEnabledItemCount(slotKey)
end

function ns.SetInfoBarItemEnabled(slotKey, id, enabled)
    local slot = GetSlot(slotKey)
    if not slot or not id or not ns.InfoBarItems[id] then return false, MAX_INFOBAR_ITEMS_PER_BAR end
    EnsureInfoBarDefaults()
    local items = DB()[slot.enabledKey]
    if type(items) ~= "table" then
        items = {}
        DB()[slot.enabledKey] = items
    end

    if enabled then
        if items[id] ~= true and GetEnabledItemCount(slotKey) >= MAX_INFOBAR_ITEMS_PER_BAR then
            return false, MAX_INFOBAR_ITEMS_PER_BAR
        end
        items[id] = true
    else
        items[id] = false
    end

    EnforceInfoBarItemLimit(slotKey)
    ns.RefreshInfoBars()
    return true, MAX_INFOBAR_ITEMS_PER_BAR
end

local StartInfoBarDrag, StopInfoBarDrag

local function CreateTextModule(slotKey, id)
    modules[slotKey] = modules[slotKey] or {}
    if modules[slotKey][id] then return modules[slotKey][id] end

    local btn = CreateFrame("Button", nil, UIParent)
    btn:SetFrameStrata("LOW")
    btn:SetHitRectInsets(0, 0, -10, -10)
    btn:RegisterForClicks("AnyUp")
    btn:RegisterForDrag("LeftButton")
    btn:EnableMouse(true)
    if btn.SetClipsChildren then btn:SetClipsChildren(true) end
    btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    btn.text:SetPoint("CENTER")
    btn.text:SetJustifyH("CENTER")
    if btn.text.SetJustifyV then btn.text:SetJustifyV("MIDDLE") end
    if btn.text.SetWordWrap then btn.text:SetWordWrap(false) end
    if btn.text.SetNonSpaceWrap then btn.text:SetNonSpaceWrap(false) end
    if btn.text.SetMaxLines then btn.text:SetMaxLines(1) end
    btn.text:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF", GetInfoBarFontSize(), "OUTLINE")
    btn.id = id
    btn.slotKey = slotKey
    btn:SetScript("OnEnter", function(self)
        local func = tooltipByID[self.id]
        if func then
            func(self)
            if self.id == "fps" then
                HideTooltipTicker()
                tooltipTicker = C_Timer and C_Timer.NewTicker and C_Timer.NewTicker(1, function()
                    if not self:IsMouseOver() then HideTooltipTicker(); GameTooltip:Hide(); return end
                    func(self)
                end)
            end
        end
    end)
    btn:SetScript("OnLeave", function(self)
        HideTooltipTicker()
        if self and self.id == "time" and ns.ClearInfoBarTimeTooltipOwner then
            ns.ClearInfoBarTimeTooltipOwner(self)
        end
        if self and self.id == "meetingstone" then
            local _, _, _, _, brokerObject = GetMeetingStoneBroker()
            if brokerObject and type(brokerObject.OnLeave) == "function" then SafeCall(brokerObject.OnLeave, self) end
        end
        GameTooltip:Hide()
    end)
    btn:SetScript("OnDragStart", function(self)
        if StartInfoBarDrag(self.slotKey) then
            self.qfxInfoBarSuppressClick = true
        end
    end)
    btn:SetScript("OnDragStop", function(self)
        if self.qfxInfoBarSuppressClick then
            StopInfoBarDrag(self.slotKey)
        end
    end)
    btn:SetScript("OnMouseUp", function(self, button)
        if self.qfxInfoBarSuppressClick then
            self.qfxInfoBarSuppressClick = nil
            return
        end
        HandleClick(self.id, button, self)
    end)
    modules[slotKey][id] = btn
    return btn
end

local function SaveInfoBarPosition(slotKey, frame)
    local slot = GetSlot(slotKey)
    if not slot or not frame then return end

    local uiLeft = UIParent:GetLeft() or 0
    local uiRight = UIParent:GetRight() or (UIParent:GetWidth() or 0)
    local uiTop = UIParent:GetTop() or (UIParent:GetHeight() or 0)
    local uiBottom = UIParent:GetBottom() or 0

    if slot.anchor == "TOPLEFT" then
        DB()[slot.xKey] = math.floor(((frame:GetLeft() or uiLeft) - uiLeft) + .5)
        DB()[slot.yKey] = math.floor(((frame:GetTop() or uiTop) - uiTop) + .5)
    elseif slot.anchor == "BOTTOMLEFT" then
        DB()[slot.xKey] = math.floor(((frame:GetLeft() or uiLeft) - uiLeft) + .5)
        DB()[slot.yKey] = math.floor(((frame:GetBottom() or uiBottom) - uiBottom) + .5)
    elseif slot.anchor == "BOTTOMRIGHT" then
        DB()[slot.xKey] = math.floor(((frame:GetRight() or uiRight) - uiRight) + .5)
        DB()[slot.yKey] = math.floor(((frame:GetBottom() or uiBottom) - uiBottom) + .5)
    end
end

StartInfoBarDrag = function(slotKey)
    local slot = GetSlot(slotKey)
    local bar = bars[slotKey]
    if not slot or not bar or DB()[slot.unlockedKey] ~= true then return false end
    if bar.StartMoving then
        bar:StartMoving()
        return true
    end
    return false
end

StopInfoBarDrag = function(slotKey)
    local bar = bars[slotKey]
    if not bar then return end
    if bar.StopMovingOrSizing then bar:StopMovingOrSizing() end
    SaveInfoBarPosition(slotKey, bar)
    ns.RefreshInfoBars()
end

local function ApplyGradient(tex, r, g, b, a1, a2, width, height)
    if not tex then return end
    tex:SetTexture("Interface\\Buttons\\WHITE8x8")
    tex:SetSize(width, height)
    if tex.SetGradient and CreateColor then
        local ok = pcall(tex.SetGradient, tex, "Horizontal", CreateColor(r, g, b, a1), CreateColor(r, g, b, a2))
        if not ok then tex:SetColorTexture(r, g, b, math.max(a1 or 0, a2 or 0)) end
    elseif tex.SetGradientAlpha then
        local ok = pcall(tex.SetGradientAlpha, tex, "HORIZONTAL", r, g, b, a1, r, g, b, a2)
        if not ok then tex:SetColorTexture(r, g, b, math.max(a1 or 0, a2 or 0)) end
    else
        tex:SetColorTexture(r, g, b, math.max(a1 or 0, a2 or 0))
    end
end

local function CreateBackground(name, slotKey)
    local frame = CreateFrame("Frame", name, UIParent)
    frame:Hide()
    frame:SetFrameStrata("BACKGROUND")
    frame.slotKey = slotKey
    frame.body = frame:CreateTexture(nil, "BACKGROUND")
    frame.body:SetPoint("CENTER")
    -- QFX class accent rails.  The visual idea is a crisp class-colored rail
    -- that can sit inside the info strip like a unit-frame texture edge, or
    -- outside the strip for the legacy compact system-bar look.  The textures
    -- are plain WHITE8x8 regions, not external artwork.
    frame.topLine = frame:CreateTexture(nil, "BORDER")
    frame.bottomLine = frame:CreateTexture(nil, "BORDER")
    frame.topLineShadow = frame:CreateTexture(nil, "BACKGROUND", nil, 1)
    frame.bottomLineShadow = frame:CreateTexture(nil, "BACKGROUND", nil, 1)
    frame:RegisterForDrag("LeftButton")
    frame:SetClampedToScreen(true)
    frame:SetScript("OnDragStart", function(self)
        StartInfoBarDrag(self.slotKey)
    end)
    frame:SetScript("OnDragStop", function(self)
        StopInfoBarDrag(self.slotKey)
    end)
    return frame
end

local function GetFadeStrength()
    local default = (ns.defaults and ns.defaults.infoBarFadeStrength) or 50
    return ClampNumber(DB().infoBarFadeStrength, 0, 100, default) / 100
end

local function GetFadeAlphas(slotKey)
    local slot = GetSlot(slotKey)
    local fade = slot and DB()[slot.fadeKey] or "left"
    local strength = GetFadeStrength()
    if fade == "right" then return 0, strength end
    return strength, 0
end

local function ApplyBarPosition(slotKey)
    local slot = GetSlot(slotKey)
    local bar = bars[slotKey]
    if not slot or not bar then return end
    local x = DB()[slot.xKey] or slot.defaultX or 0
    local y = DB()[slot.yKey] or slot.defaultY or 0
    -- The line textures sit outside the frame body. Do not add automatic edge
    -- padding here; users can fine-tune the unlocked position manually.
    bar:ClearAllPoints()
    bar:SetPoint(slot.anchor, UIParent, slot.anchor, x, y)
end

local function ResetLineTexture(tex)
    if not tex then return end
    tex:ClearAllPoints()
    tex:SetTexture("Interface\\Buttons\\WHITE8x8")
    tex:SetAlpha(1)
    tex:Show()
end

local function HideLineTexture(tex)
    if tex then tex:Hide() end
end

local function LayoutClassRail(bar, style, position, width, height, thickness)
    if not bar then return end
    local t = math.max(1, thickness or 1)
    local shadowSize = math.max(t + 1, 2)

    ResetLineTexture(bar.topLine)
    ResetLineTexture(bar.bottomLine)
    ResetLineTexture(bar.topLineShadow)
    ResetLineTexture(bar.bottomLineShadow)

    HideLineTexture(bar.topLine)
    HideLineTexture(bar.bottomLine)
    HideLineTexture(bar.topLineShadow)
    HideLineTexture(bar.bottomLineShadow)

    if position == "hidden" then return end

    local mode = "inner"
    local inset = 0
    if style == "eui-taskbar" then
        -- QFX uses the EUI taskbar idea as a short outside accent rail:
        -- outside the info strip, but slightly inset from the two ends.
        mode = "taskbar"
        inset = 4
    end

    local function SetHorizontal(tex, target, edge, offY, leftInset, rightInset)
        tex:SetPoint(edge .. "LEFT", target, edge .. "LEFT", leftInset or 0, offY or 0)
        tex:SetPoint(edge .. "RIGHT", target, edge .. "RIGHT", -(rightInset or 0), offY or 0)
    end

    local function PlaceTop()
        if mode == "outer" or mode == "taskbar" then
            bar.topLine:SetPoint("BOTTOMLEFT", bar, "TOPLEFT", inset, 0)
            bar.topLine:SetPoint("BOTTOMRIGHT", bar, "TOPRIGHT", -inset, 0)
            bar.topLineShadow:SetPoint("BOTTOMLEFT", bar.topLine, "TOPLEFT", 0, 0)
            bar.topLineShadow:SetPoint("BOTTOMRIGHT", bar.topLine, "TOPRIGHT", 0, 0)
        else
            SetHorizontal(bar.topLine, bar, "TOP", 0, inset, inset)
            bar.topLineShadow:SetPoint("TOPLEFT", bar.topLine, "BOTTOMLEFT", 0, 0)
            bar.topLineShadow:SetPoint("TOPRIGHT", bar.topLine, "BOTTOMRIGHT", 0, 0)
        end
        bar.topLine:SetHeight(t)
        bar.topLineShadow:SetHeight(shadowSize)
        bar.topLine:Show()
        bar.topLineShadow:Show()
    end

    local function PlaceBottom()
        if mode == "outer" or mode == "taskbar" then
            bar.bottomLine:SetPoint("TOPLEFT", bar, "BOTTOMLEFT", inset, 0)
            bar.bottomLine:SetPoint("TOPRIGHT", bar, "BOTTOMRIGHT", -inset, 0)
            bar.bottomLineShadow:SetPoint("TOPLEFT", bar.bottomLine, "BOTTOMLEFT", 0, 0)
            bar.bottomLineShadow:SetPoint("TOPRIGHT", bar.bottomLine, "BOTTOMRIGHT", 0, 0)
        else
            SetHorizontal(bar.bottomLine, bar, "BOTTOM", 0, inset, inset)
            bar.bottomLineShadow:SetPoint("BOTTOMLEFT", bar.bottomLine, "TOPLEFT", 0, 0)
            bar.bottomLineShadow:SetPoint("BOTTOMRIGHT", bar.bottomLine, "TOPRIGHT", 0, 0)
        end
        bar.bottomLine:SetHeight(t)
        bar.bottomLineShadow:SetHeight(shadowSize)
        bar.bottomLine:Show()
        bar.bottomLineShadow:Show()
    end

    if position == "top" or position == "both" then PlaceTop() end
    if position == "bottom" or position == "both" then PlaceBottom() end
end

local function UpdateBarVisual(slotKey)
    local slot = GetSlot(slotKey)
    local bar = bars[slotKey]
    if not slot or not bar then return end
    local width, height = GetBarWidth(slotKey), GetBarHeight(slotKey)
    local startAlpha, endAlpha = GetFadeAlphas(slotKey)
    local r, g, b = GetClassColor()
    bar:SetSize(width, height)
    ApplyBarPosition(slotKey)
    if bar.body then bar.body:Show() end
    ApplyGradient(bar.body, 0, 0, 0, startAlpha, endAlpha, width, height)
    local lineThickness = GetInfoBarLineThickness(slotKey)
    local lineStyle = GetInfoBarLineStyle(slotKey)
    local linePosition = GetInfoBarLinePosition(slotKey)
    LayoutClassRail(bar, lineStyle, linePosition, width, height, lineThickness)
    ApplyGradient(bar.topLine, r, g, b, startAlpha, endAlpha, width, lineThickness)
    ApplyGradient(bar.bottomLine, r, g, b, startAlpha, endAlpha, width, lineThickness)
    ApplyGradient(bar.topLineShadow, 0, 0, 0, math.min(.28, startAlpha * .65), math.min(.28, endAlpha * .65), width, math.max(lineThickness + 1, 2))
    ApplyGradient(bar.bottomLineShadow, 0, 0, 0, math.min(.28, startAlpha * .65), math.min(.28, endAlpha * .65), width, math.max(lineThickness + 1, 2))
    local unlocked = DB()[slot.unlockedKey] == true
    bar:SetMovable(unlocked)
    bar:EnableMouse(unlocked)
end

local function ReleaseTexture(tex)
    if not tex then return end
    tex:SetTexture(nil)
    tex:Hide()
end

local function ReleaseBarMaterials(bar)
    if not bar then return end
    ReleaseTexture(bar.body)
    ReleaseTexture(bar.topLine)
    ReleaseTexture(bar.bottomLine)
    ReleaseTexture(bar.topLineShadow)
    ReleaseTexture(bar.bottomLineShadow)
end

local function CreateBarForSlot(slotKey)
    local slot = GetSlot(slotKey)
    if not slot then return nil end
    if not bars[slotKey] then
        bars[slotKey] = CreateBackground(slot.frameName or ("QFXSystemBarInfoStrip" .. tostring(slotKey)), slotKey)
    end
    return bars[slotKey]
end

local function CreateBars()
    for slotKey in pairs(ns.InfoBarSlots or {}) do
        if IsSlotEnabled(slotKey) then
            CreateBarForSlot(slotKey)
        elseif bars[slotKey] then
            ReleaseBarMaterials(bars[slotKey])
            bars[slotKey]:Hide()
        end
    end
end

local function EnsureSlotModules(slotKey)
    if not IsSlotEnabled(slotKey) then return end
    modules[slotKey] = modules[slotKey] or {}
    for _, id in ipairs(GetOrderForSlot(slotKey)) do
        if IsItemEnabled(slotKey, id) then
            CreateTextModule(slotKey, id)
        end
    end
end

local function EnsureModules()
    for slotKey in pairs(ns.InfoBarSlots or {}) do
        EnsureSlotModules(slotKey)
    end
end

local textFuncs

do
local function TextGuild()
    local online = GetOnlineGuild()
    return ShortInfoLabel("Guild", "G") .. ": " .. MyColor() .. (online or LT("None")) .. "|r"
end

local function TextFriend()
    return string.format("%s: %s%d|r", ShortInfoLabel("Friends", "F"), MyColor(), GetOnlineFriends())
end

local function GetMeetingStoneInlineIcon(index)
    local size = math.max(10, math.floor(GetInfoBarFontSize() + .5))
    local atlas = [[Interface\AddOns\MeetingStone\Media\DataBroker]]
    if index == 2 then
        return string.format([[|T%s:%d:%d:0:0:128:32:32:65:0:32|t]], atlas, size, size)
    elseif index == 3 then
        return string.format([[|T%s:%d:%d:0:0:128:32:96:128:0:32|t]], atlas, size, size)
    end
    return string.format([[|T%s:%d:%d:0:0:128:32:0:32:0:32|t]], atlas, size, size)
end

local function GetGenericPremadeInlineIcon()
    local texture = ns.GetPremadeAddonIconTexture and ns.GetPremadeAddonIconTexture()
    if type(texture) ~= "string" or texture == "" then return GetMeetingStoneInlineIcon(1) end
    local size = math.max(10, math.floor(GetInfoBarFontSize() + .5))
    return string.format([[|T%s:%d:%d|t]], texture, size, size)
end

local function SafeNumberFromCall(func, preferSecond, ...)
    if type(func) ~= "function" then return 0 end
    local ok, a, b = pcall(func, ...)
    if not ok then return 0 end
    if preferSecond then return tonumber(b) or tonumber(a) or 0 end
    return tonumber(a) or tonumber(b) or 0
end

local function NormalizeMeetingStoneBrokerText(text)
    if type(text) ~= "string" then return text end
    text = text:gsub("^%s+", ""):gsub("%s+$", "")
    if text == "" then return text end

    local size = math.max(10, math.floor(GetInfoBarFontSize() + .5))
    text = text:gsub("(|T[^:]-MeetingStone[^:]-DataBroker:)%d+:%d+:", function(prefix)
        return prefix .. size .. ":" .. size .. ":"
    end)
    return text
end

local function IsMeetingStonePlaceholderText(text)
    if type(text) ~= "string" then return true end
    text = text:gsub("^%s+", ""):gsub("%s+$", "")
    if text == "" then return true end
    local normalized = ns.NormalizeLocaleKey and ns.NormalizeLocaleKey(text) or text
    if normalized == "MeetingStone" or normalized == "Meeting Stone" then return true end
    if text:find("MS:%s*%-%-") then return true end
    return false
end

local function GetMeetingStonePanelFontText(panel)
    if not panel or type(panel.GetRegions) ~= "function" then return nil end
    local regions = { panel:GetRegions() }
    for _, region in ipairs(regions) do
        if region and type(region.GetText) == "function" then
            local text = region:GetText()
            if type(text) == "string" and not IsMeetingStonePlaceholderText(text) then
                return text
            end
        end
    end
    return nil
end

local function GetMeetingStoneBrokerText(panel, dataBroker, brokerObject)
    local text

    -- Prefer MeetingStone's LibDataBroker data object. This remains available even when
    -- MeetingStone's own floating broker panel is hidden or disabled in MeetingStone settings.
    text = brokerObject and brokerObject.text
    if type(text) == "string" and not IsMeetingStonePlaceholderText(text) then return NormalizeMeetingStoneBrokerText(text) end

    text = dataBroker and dataBroker.BrokerObject and dataBroker.BrokerObject.text
    if type(text) == "string" and not IsMeetingStonePlaceholderText(text) then return NormalizeMeetingStoneBrokerText(text) end

    -- The floating panel font strings are only a compatibility fallback now.
    if dataBroker and dataBroker.BrokerText and type(dataBroker.BrokerText.GetText) == "function" then
        text = dataBroker.BrokerText:GetText()
        if type(text) == "string" and not IsMeetingStonePlaceholderText(text) then return NormalizeMeetingStoneBrokerText(text) end
    end

    text = GetMeetingStonePanelFontText(panel)
    if type(text) == "string" and not IsMeetingStonePlaceholderText(text) then return NormalizeMeetingStoneBrokerText(text) end

    return nil
end

local function GetMeetingStoneCountText(dataBroker, env, brokerObject)
    local count1 = 0
    if C_LFGList then
        local hasActive = false
        if type(C_LFGList.HasActiveEntryInfo) == "function" then
            local ok, result = pcall(C_LFGList.HasActiveEntryInfo)
            hasActive = ok and result == true
        end
        if hasActive then
            count1 = SafeNumberFromCall(C_LFGList.GetNumApplicants, true)
        else
            count1 = SafeNumberFromCall(C_LFGList.GetNumApplications, true)
        end
    end

    local count2 = tonumber(dataBroker and dataBroker.activityCount) or 0
    local count3 = tonumber(dataBroker and dataBroker.followQueryCount) or 0
    local hasApp = false
    local app = env and env.App
    if not app and dataBroker and dataBroker.App then app = dataBroker.App end
    if app and type(app.HasApp) == "function" then
        local ok, result = pcall(app.HasApp, app)
        hasApp = ok and result == true
    end

    if hasApp then
        return string.format("%s %d   %s %d   %s %d", GetMeetingStoneInlineIcon(1), count1, GetMeetingStoneInlineIcon(2), count2, GetMeetingStoneInlineIcon(3), count3)
    end
    return string.format("%s %d   %s %d", GetMeetingStoneInlineIcon(1), count1, GetMeetingStoneInlineIcon(2), count2)
end

local function TextMeetingStone()
    if ns.GetPremadeAddonCounts then
        local count1, count2 = ns.GetPremadeAddonCounts()
        if count1 ~= nil then
            local icon = GetGenericPremadeInlineIcon()
            return string.format("%s %d   %s %d", icon, tonumber(count1) or 0, icon, tonumber(count2) or 0)
        end
    end

    local panel, dataBroker, _, env, brokerObject = GetMeetingStoneBroker()

    -- Text refresh only: do not repeatedly sync/hide MeetingStone's floating
    -- broker panel or force BrokerObject:UpdateLabel() on the timer path.
    -- Full layout refreshes and ADDON_LOADED/settings changes handle the panel
    -- suppression separately.
    local text = GetMeetingStoneBrokerText(panel, dataBroker, brokerObject)
    if text then return text end

    return GetMeetingStoneCountText(dataBroker, env, brokerObject)
end

local function TextFPS()
    local fps = math.floor((GetFramerate and GetFramerate() or 0) + 0.5)
    local _, _, latency = GetNetLatency()
    return "FPS: " .. ColorFPS(fps) .. " | " .. ColorLatency(latency)
end

local function TextCombatLog()
    local enabled = ReadAdvancedCombatLogState()
    local state = enabled and ("|cff00ff00" .. LT("ON") .. "|r") or ("|cffff3333" .. LT("OFF") .. "|r")
    return LT("Combat Log") .. ": " .. state
end

local function TextItemLevel()
    local total, equipped
    if GetAverageItemLevel then total, equipped = GetAverageItemLevel() end
    local value = equipped or total
    local label = LT("Item Level")
    if value then return label .. ": " .. MyColor() .. string.format("%.0f", value) .. "|r" end
    return label .. ": --"
end

local function TextMythicPlus()
    return LT("Score") .. ": " .. ColorMythicPlusScore(GetMythicPlusScore())
end

local function TextZone(btn)
    local text = (GetMinimapZoneText and GetMinimapZoneText()) or (GetAreaText and GetAreaText()) or ""
    local r, g, b = GetZoneTextColor()
    if btn and btn.text then btn.text:SetTextColor(r, g, b, 1) end
    return text
end

local function TextCoords()
    local x, y = GetCoords()
    return "XY: " .. MyColor() .. FormatCoords(x, y) .. "|r"
end

local function TextPhase()
    local id = GetPhaseLikeID()
    return "ID: " .. MyColor() .. tostring(id or "--") .. "|r"
end

local function TextSpec()
    return GetSpecText()
end

local function TextDura()
    local pct = GetDurabilityPercent()
    local label = LT("Durability")
    if pct then return label .. ": " .. ColorDurability(pct) end
    return label .. ": " .. MyColor() .. (NONE or LT("None")) .. "|r"
end

local function TextGold()
    if showSlots then
        return string.format("|cff00ff00%d|r", GetBagFreeSlots())
    end
    return FormatMoney(GetMoney and GetMoney() or 0)
end

local function TextVolume()
    local value = ns.IsInfoBarMasterSoundMuted() and LT("Muted") or (ns.GetInfoBarMasterVolumePercent() .. "%")
    return LT("Vol") .. " " .. value
end

local function TextTime()
    return GetTimeText()
end

textFuncs = {
    guild = TextGuild,
    friend = TextFriend,
    meetingstone = TextMeetingStone,
    fps = TextFPS,
    combatlog = TextCombatLog,
    zone = TextZone,
    coords = TextCoords,
    phase = TextPhase,
    spec = TextSpec,
    ilvl = TextItemLevel,
    mplus = TextMythicPlus,
    dura = TextDura,
    gold = TextGold,
    volume = TextVolume,
    time = TextTime,
}
end

local function HideSlotModules(slotKey)
    for _, btn in pairs(modules[slotKey] or {}) do
        btn:Hide()
    end
end

local function ShouldUpdateInfoBarID(id, filter)
    if not filter then return true end
    if type(filter) == "string" then return id == filter end
    return type(filter) == "table" and filter[id] == true
end

local function ApplyInfoBarTextStyle(btn, force)
    if not btn or not btn.text then return end
    local fontPath = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
    local fontSize = GetInfoBarFontSize()
    if force or btn.qfxInfoBarFontPath ~= fontPath or btn.qfxInfoBarFontSize ~= fontSize then
        btn.text:SetFont(fontPath, fontSize, "OUTLINE")
        btn.qfxInfoBarFontPath = fontPath
        btn.qfxInfoBarFontSize = fontSize
    end
    btn.text:SetTextColor(1, 1, 1, 1)
    btn.text:Show()
end

local function UpdateOneInfoBarText(btn, id, forceStyle)
    if not btn or not btn.text then return false end
    ApplyInfoBarTextStyle(btn, forceStyle)
    local func = textFuncs[id]
    btn.text:SetText(func and func(btn) or id)
    -- Do not resize or re-anchor during runtime text refreshes. Equal-width cell
    -- geometry is owned by AnchorSlotModules(); this path only changes text.
    btn.qfxWidth = math.max(1, math.ceil(btn.text:GetStringWidth() + 2))
    return true
end

local function UpdateTexts(filter, forceStyle)
    local updated = false
    for slotKey, byID in pairs(modules) do
        for id, btn in pairs(byID) do
            if ShouldUpdateInfoBarID(id, filter) and IsSlotEnabled(slotKey) and IsItemEnabled(slotKey, id) then
                updated = UpdateOneInfoBarText(btn, id, forceStyle) or updated
            end
        end
    end
    return updated
end

local function RefreshInfoBarTextOnly(filter)
    if DB().isInfoBar ~= true then return false end
    return UpdateTexts(filter, false)
end

local function RefreshInfoBarItems(filter)
    if DB().isInfoBar ~= true then return end
    EnsureInfoBarDefaults()
    CreateBars()
    EnsureModules()
    UpdateTexts(filter, true)
end

RefreshInfoBarItem = function(id)
    if not IsAnyInfoBarItemEnabled(id) then return end
    if not RefreshInfoBarTextOnly(id) then
        RefreshInfoBarItems(id)
    end
end

UpdateItemTickers = function()
    if not C_Timer or not C_Timer.NewTicker then return end
    for id, interval in pairs(ITEM_REFRESH_INTERVALS) do
        local active = IsAnyInfoBarItemEnabled(id)
        if active and not itemTickers[id] then
            itemTickers[id] = C_Timer.NewTicker(interval, function()
                if IsAnyInfoBarItemEnabled(id) then RefreshInfoBarItem(id) end
            end)
        elseif (not active) and itemTickers[id] then
            itemTickers[id]:Cancel()
            itemTickers[id] = nil
        end
    end
end

local function AnchorSlotModules(slotKey)
    local bar = bars[slotKey]
    local slot = GetSlot(slotKey)
    if not bar or not slot then return end
    HideSlotModules(slotKey)
    if not IsSlotEnabled(slotKey) then return end

    local visible = {}
    for _, id in ipairs(GetOrderForSlot(slotKey)) do
        if IsItemEnabled(slotKey, id) then
            local btn = modules[slotKey] and modules[slotKey][id]
            if not btn and IsSlotEnabled(slotKey) then btn = CreateTextModule(slotKey, id) end
            if btn then visible[#visible + 1] = btn end
        end
    end
    if #visible == 0 then return end

    while #visible > MAX_INFOBAR_ITEMS_PER_BAR do
        table.remove(visible)
    end
    if #visible == 0 then return end

    local width = GetBarWidth(slotKey)
    local height = GetBarHeight(slotKey)
    local cellWidth = width / #visible

    for index, btn in ipairs(visible) do
        local left = (index - 1) * cellWidth
        btn:SetParent(bar)
        if bar.GetFrameLevel and btn.SetFrameLevel then btn:SetFrameLevel((bar:GetFrameLevel() or 0) + 5) end
        btn:ClearAllPoints()
        btn:SetSize(cellWidth, height)
        if btn.SetClipsChildren then btn:SetClipsChildren(true) end
        btn:SetPoint("LEFT", bar, "LEFT", left, 0)
        btn.text:ClearAllPoints()
        -- Make every info item use its own equal-width cell and fill the
        -- bar height.  TOP/BOTTOM anchors plus vertical middle justification
        -- keep all labels visually centered on the background strip.
        btn.text:SetPoint("TOPLEFT", btn, "TOPLEFT", 4, 0)
        btn.text:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -4, 0)
        btn.text:SetSize(math.max(1, cellWidth - 8), height)
        btn.text:SetJustifyH("CENTER")
        if btn.text.SetJustifyV then btn.text:SetJustifyV("MIDDLE") end
        btn:Show()
        if btn.id == "meetingstone" then
            if not meetingStoneBrokerDesired then
                meetingStoneBrokerDesired = btn
                HideMeetingStoneFloatingPanel()
            else
                btn:Hide()
            end
        end
    end
end

function ns.RefreshInfoBars()
    EnsureInfoBarDefaults()

    local enabled = DB().isInfoBar == true
    if not enabled then
        for _, bar in pairs(bars) do
            if bar then
                ReleaseBarMaterials(bar)
                bar:Hide()
            end
        end
        for slotKey in pairs(modules) do HideSlotModules(slotKey) end
        meetingStoneBrokerDesired = nil
        RestoreMeetingStoneBroker()
        if UpdateInfoBarEventRegistration then UpdateInfoBarEventRegistration() end
        if UpdateItemTickers then UpdateItemTickers() end
        return
    end

    CreateBars()
    EnsureModules()

    for slotKey in pairs(ns.InfoBarSlots or {}) do
        local bar = bars[slotKey]
        if IsSlotEnabled(slotKey) then
            if bar then
                UpdateBarVisual(slotKey)
                bar:Show()
            end
        elseif bar then
            ReleaseBarMaterials(bar)
            bar:Hide()
        end
    end
    for slotKey in pairs(modules) do HideSlotModules(slotKey) end

    meetingStoneBrokerDesired = nil
    if IsAnyInfoBarItemEnabled("gold") and ns.EnsureInfoBarMoneySession then
        ns.EnsureInfoBarMoneySession()
    end
    UpdateTexts(nil, true)
    for slotKey in pairs(ns.InfoBarSlots or {}) do
        AnchorSlotModules(slotKey)
    end
    if not meetingStoneBrokerDesired then RestoreMeetingStoneBroker() end
    if UpdateInfoBarEventRegistration then UpdateInfoBarEventRegistration() end
    if UpdateItemTickers then UpdateItemTickers() end
end

function ns.OnInfoBarChanged()
    ns.RefreshInfoBars()
    if ns.QueueMeetingStoneFloatingSync then
        ns.QueueMeetingStoneFloatingSync()
    elseif ns.SyncMeetingStoneFloatingPanel then
        ns.SyncMeetingStoneFloatingPanel()
    end
end

function ns.SetInfoBarUnlocked(slotKey, unlocked)
    local slot = GetSlot(slotKey)
    if not slot then return end
    DB()[slot.unlockedKey] = unlocked and true or false
    ns.RefreshInfoBars()
end

function ns.NudgeInfoBar(slotKey, dx, dy)
    local slot = GetSlot(slotKey)
    if not slot then return end
    DB()[slot.xKey] = (tonumber(DB()[slot.xKey]) or slot.defaultX or 0) + (dx or 0)
    DB()[slot.yKey] = (tonumber(DB()[slot.yKey]) or slot.defaultY or 0) + (dy or 0)
    ns.RefreshInfoBars()
end

function ns.ResetInfoBarPosition(slotKey)
    local slot = GetSlot(slotKey)
    if not slot then return end
    DB()[slot.xKey] = slot.defaultX or 0
    DB()[slot.yKey] = slot.defaultY or 0
    DB()[slot.unlockedKey] = false
    ns.RefreshInfoBars()
end

function ns.MoveInfoBarItem(slotKey, id, delta)
    local slot = GetSlot(slotKey)
    if not slot or not id then return end
    EnsureInfoBarDefaults()
    local order = DB()[slot.orderKey]
    local index
    for i, value in ipairs(order) do
        if value == id then index = i break end
    end
    if not index then return end
    local target = index + (delta or 0)
    if target < 1 or target > #order then return end
    order[index], order[target] = order[target], order[index]
    ns.RefreshInfoBars()
end

function ns.ResetInfoBarContent(slotKey)
    local slot = GetSlot(slotKey)
    if not slot then return end
    DB()[slot.orderKey] = CopyArray(ns.defaults[slot.orderKey] or INFOBAR_ITEM_ORDER)
    DB()[slot.enabledKey] = CopyMap(ns.defaults[slot.enabledKey] or slot.defaultItems or {})
    ns.RefreshInfoBars()
end

local registeredInfoBarEvents = {}

UpdateInfoBarEventRegistration = function()
    if not eventFrame then return end

    local wanted = {}
    wanted.PLAYER_ENTERING_WORLD = IsInfoBarEventNeeded("PLAYER_ENTERING_WORLD")
    wanted.ADDON_LOADED = IsInfoBarEventNeeded("ADDON_LOADED")
    for event in pairs(EVENT_ITEM_REFRESH) do
        wanted[event] = IsInfoBarEventNeeded(event)
    end

    for event, active in pairs(wanted) do
        if active and not registeredInfoBarEvents[event] then
            pcall(eventFrame.RegisterEvent, eventFrame, event)
            registeredInfoBarEvents[event] = true
        elseif (not active) and registeredInfoBarEvents[event] then
            pcall(eventFrame.UnregisterEvent, eventFrame, event)
            registeredInfoBarEvents[event] = nil
        end
    end
end

local function RefreshEnabledItems(filter)
    if type(filter) == "string" then
        RefreshInfoBarItem(filter)
        return
    end
    if type(filter) ~= "table" then return end

    local activeFilter
    for id in pairs(filter) do
        if IsAnyInfoBarItemEnabled(id) then
            activeFilter = activeFilter or {}
            activeFilter[id] = true
        end
    end
    if activeFilter and not RefreshInfoBarTextOnly(activeFilter) then RefreshInfoBarItems(activeFilter) end
end

local function GetCVarInfoBarFilter(cvarName)
    if type(cvarName) ~= "string" or cvarName == "" then
        return EVENT_ITEM_REFRESH.CVAR_UPDATE
    end

    local filter = CVAR_ITEM_REFRESH[cvarName]
    if filter then return filter end

    local normalized = string.lower(cvarName)
    for knownName, knownFilter in pairs(CVAR_ITEM_REFRESH) do
        if string.lower(knownName) == normalized then return knownFilter end
    end

    return nil
end

local function RegisterEvents()
    if eventFrame then
        if UpdateInfoBarEventRegistration then UpdateInfoBarEventRegistration() end
        return
    end

    eventFrame = CreateFrame("Frame")
    eventFrame:SetScript("OnEvent", function(_, event, name)
        if event == "PLAYER_ENTERING_WORLD" then
            if not IsAnyInfoBarShown() then return end
            loginTime = GetTime and GetTime() or 0
            if IsAnyInfoBarItemEnabled("gold") and ns.EnsureInfoBarMoneySession then ns.EnsureInfoBarMoneySession() end
            if IsAnyInfoBarItemEnabled("friend") and C_FriendList and C_FriendList.ShowFriends then pcall(C_FriendList.ShowFriends) end
            if IsAnyInfoBarItemEnabled("guild") and IsInGuild and IsInGuild() and C_GuildInfo and C_GuildInfo.GuildRoster then pcall(C_GuildInfo.GuildRoster) end
            if C_Timer and C_Timer.After then C_Timer.After(.5, ns.RefreshInfoBars) else ns.RefreshInfoBars() end
            return
        end

        if event == "ADDON_LOADED" then
            if name == "MeetingStone" or name == "MeetingStoneEX" or name == "GroupFinder" or name == "PremadeGroupBoard" then
                RefreshInfoBarItem("meetingstone")
                if ns.QueueMeetingStoneFloatingSync then
                    ns.QueueMeetingStoneFloatingSync()
                elseif ns.SyncMeetingStoneFloatingPanel then
                    ns.SyncMeetingStoneFloatingPanel()
                end
            end
            return
        end

        if event == "CVAR_UPDATE" then
            RefreshEnabledItems(GetCVarInfoBarFilter(name))
            return
        end

        if event == "UPDATE_INSTANCE_INFO" then
            if ns.HandleInfoBarInstanceInfoUpdate then ns.HandleInfoBarInstanceInfoUpdate() end
            return
        end

        local filter = EVENT_ITEM_REFRESH[event]
        if type(filter) == "table" and filter.gold and ns.UpdateInfoBarMoneySession then
            ns.UpdateInfoBarMoneySession()
        end
        RefreshEnabledItems(filter)
    end)

    if UpdateInfoBarEventRegistration then UpdateInfoBarEventRegistration() end
    if UpdateItemTickers then UpdateItemTickers() end
end

StaticPopupDialogs["QFXSYSTEMBAR_RELOAD_REQUIRED"] = {
    text = "CPU profiling requires a UI reload to fully apply.",
    button1 = RELOADUI or LT("Reload UI"),
    button2 = CANCEL or LT("Cancel"),
    OnAccept = function() ReloadUI() end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}

local infoBarInitialized
local function QueueInfoBarRefresh()
    if not ns.RefreshInfoBars then return end
    ns.RefreshInfoBars()
    if C_Timer and C_Timer.After then
        C_Timer.After(0.5, function() if ns.RefreshInfoBars then ns.RefreshInfoBars() end end)
    end
end
ns.QueueInfoBarRefresh = QueueInfoBarRefresh

local function InitializeInfoBar()
    -- Do not migrate or rewrite existing InfoBar SavedVariables here.
    -- Defaults are only filled when missing, and the global InfoBar switch
    -- remains off unless the user explicitly enables it.
    if infoBarInitialized then
        QueueInfoBarRefresh()
        return
    end
    infoBarInitialized = true
    EnsureInfoBarDefaults()
    RegisterEvents()
    QueueInfoBarRefresh()
end
ns.InitializeInfoBar = InitializeInfoBar

InitializeInfoBar()

if EventUtil and EventUtil.ContinueOnPlayerLogin then
    EventUtil.ContinueOnPlayerLogin(QueueInfoBarRefresh)
end
