local addonName, ns = ...
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

-- ========================================================================
-- QFX system bar
-- ========================================================================
do
    local function LoadMeetingStoneBridge()
        if ns.MeetingStoneBridgeLoaded then return true end
        if ns.LoadOptionalAddOn then
            ns.LoadOptionalAddOn("QFXSystemBar_MeetingStone")
        elseif C_AddOns and C_AddOns.LoadAddOn then
            pcall(C_AddOns.LoadAddOn, "QFXSystemBar_MeetingStone")
        elseif LoadAddOn then
            pcall(LoadAddOn, "QFXSystemBar_MeetingStone")
        end
        return ns.MeetingStoneBridgeLoaded == true
    end
    ns.EnsureMeetingStoneBridgeLoaded = LoadMeetingStoneBridge

    local function IsMeetingStoneInfoBarSavedActive()
        local db = QFXSystemBarDB
        if not db or db.isInfoBar ~= true then return false end
        local slots = ns.InfoBarSlots
        if type(slots) == "table" then
            for _, slot in pairs(slots) do
                if type(slot) == "table" and db[slot.barEnabledKey] == true then
                    local items = db[slot.enabledKey]
                    if type(items) == "table" and items.meetingstone == true then return true end
                end
            end
        end
        local savedLists = { db.infoBarLeftItems, db.infoBarLeftBottomItems, db.infoBarRightItems }
        for _, items in ipairs(savedLists) do
            if type(items) == "table" and items.meetingstone == true then return true end
        end
        return false
    end

    local function ShouldLoadMeetingStoneBridge()
        local db = QFXSystemBarDB
        return db and (
            db.isCustomMicroMenuMeetingStone == true
            or db.qfxMeetingStoneOriginalPanelSetting ~= nil
            or IsMeetingStoneInfoBarSavedActive()
        )
    end
    ns.ShouldLoadMeetingStoneBridge = ShouldLoadMeetingStoneBridge

    local function CallMeetingStoneBridge(method, ...)
        local before = ns[method]
        if LoadMeetingStoneBridge() and ns[method] and ns[method] ~= before then
            return ns[method](...)
        end
        return nil
    end

    function ns.HideMeetingStoneFloatingPanel()
        return CallMeetingStoneBridge("HideMeetingStoneFloatingPanel")
    end

    function ns.RestoreMeetingStoneFloatingPanel()
        return CallMeetingStoneBridge("RestoreMeetingStoneFloatingPanel")
    end

    function ns.SyncMeetingStoneFloatingPanel()
        return CallMeetingStoneBridge("SyncMeetingStoneFloatingPanel")
    end

    function ns.QueueMeetingStoneFloatingSync()
        return CallMeetingStoneBridge("QueueMeetingStoneFloatingSync")
    end

    local GetPremadeAddonDisplayNameStub
    GetPremadeAddonDisplayNameStub = function()
        if LoadMeetingStoneBridge() and ns.GetPremadeAddonDisplayName ~= GetPremadeAddonDisplayNameStub then
            return ns.GetPremadeAddonDisplayName()
        end
        return "MeetingStone"
    end
    ns.GetPremadeAddonDisplayName = GetPremadeAddonDisplayNameStub

    local GetPremadeAddonIconTextureStub
    GetPremadeAddonIconTextureStub = function()
        if LoadMeetingStoneBridge() and ns.GetPremadeAddonIconTexture ~= GetPremadeAddonIconTextureStub then
            return ns.GetPremadeAddonIconTexture()
        end
        return nil
    end
    ns.GetPremadeAddonIconTexture = GetPremadeAddonIconTextureStub

    local GetPremadeAddonInfoBarTextStub
    GetPremadeAddonInfoBarTextStub = function()
        if LoadMeetingStoneBridge() and ns.GetPremadeAddonInfoBarText ~= GetPremadeAddonInfoBarTextStub then
            return ns.GetPremadeAddonInfoBarText()
        end
        return nil
    end
    ns.GetPremadeAddonInfoBarText = GetPremadeAddonInfoBarTextStub

    local GetPremadeAddonCountsStub
    GetPremadeAddonCountsStub = function()
        if LoadMeetingStoneBridge() and ns.GetPremadeAddonCounts ~= GetPremadeAddonCountsStub then
            return ns.GetPremadeAddonCounts()
        end
        return nil
    end
    ns.GetPremadeAddonCounts = GetPremadeAddonCountsStub

    local ShowPremadeAddonTooltipStub
    ShowPremadeAddonTooltipStub = function(owner)
        if LoadMeetingStoneBridge() and ns.ShowPremadeAddonTooltip ~= ShowPremadeAddonTooltipStub then
            return ns.ShowPremadeAddonTooltip(owner)
        end
        return false
    end
    ns.ShowPremadeAddonTooltip = ShowPremadeAddonTooltipStub

    local ConfirmMeetingStoneButtonVisibilityStub
    ConfirmMeetingStoneButtonVisibilityStub = function(checked, checkbox, applyFunc)
        if LoadMeetingStoneBridge() and ns.ConfirmMeetingStoneButtonVisibility ~= ConfirmMeetingStoneButtonVisibilityStub then
            return ns.ConfirmMeetingStoneButtonVisibility(checked, checkbox, applyFunc)
        end
        if type(applyFunc) == "function" then applyFunc(checked and true or false) end
    end
    ns.ConfirmMeetingStoneButtonVisibility = ConfirmMeetingStoneButtonVisibilityStub

    local function ToggleMeetingStone(owner, button)
        if LoadMeetingStoneBridge() and ns.ToggleMeetingStone then
            return ns.ToggleMeetingStone(owner, button)
        end
        print("|cFF33FF99QFX|r - |cFFEE8800" .. T("MeetingStone is not loaded.") .. "|r")
    end

    -- QFX micro-menu command catalog
    -- -------------------------------------------------------------------
    local MICRO_ICON_PATH = "Interface\\AddOns\\QFXSystemBar\\Media\\MicroMenu\\"

    local function PrintQFXWarning(messageKey)
        print("|cFF33FF99QFX|r - |cFFEE8800" .. T(messageKey) .. "|r")
    end

    local function OpenQFXCalendarFromClock()
        if InCombatLockdown and InCombatLockdown() then
            PrintQFXWarning("Unavailable in combat. Please try again after combat ends.")
            return
        end
        if not CalendarFrame and C_AddOns and C_AddOns.LoadAddOn then
            pcall(C_AddOns.LoadAddOn, "Blizzard_Calendar")
        end
        local toggleCalendar = ToggleCalendar
        if toggleCalendar then
            toggleCalendar()
        end
    end

    local function FormatCollectedMemory(kbValue)
        local amount = tonumber(kbValue) or 0
        if amount > 1024 then
            return ("%.2f MB"):format(amount / 1024)
        end
        return ("%d KB"):format(math.max(0, math.floor(amount + 0.5)))
    end

    local function RunClockMemoryCleanup()
        local updateMemoryUsage = UpdateAddOnMemoryUsage
        if updateMemoryUsage then
            updateMemoryUsage()
        end
        local startKB = collectgarbage("count") or 0
        collectgarbage("collect")
        local savedKB = startKB - (collectgarbage("count") or startKB)
        print(("|cFF33FF99QFX|r - |cFF4499FF%s %s|r"):format(T("Cleaned"), FormatCollectedMemory(savedKB)))
    end

    local function OnClockButtonClick(_, mouseButton)
        local action = mouseButton or "LeftButton"
        if action == "LeftButton" then
            OpenQFXCalendarFromClock()
        elseif action == "RightButton" then
            RunClockMemoryCleanup()
        end
    end

    local function OnBagButtonClick()
        local openBags = ToggleAllBags
        if openBags then
            openBags()
        end
    end

    local AdjustMasterVolume, ShowVolumeButtonText, RequestBadgeUpdate, RefreshBadgeValue, UpdateButtonBadge
    local function OnVolumeButtonClick(self, mouseButton)
        local action = mouseButton or "LeftButton"
        if action ~= "LeftButton" and action ~= "RightButton" then
            return
        end
        local delta = (action == "LeftButton") and 5 or -5
        if AdjustMasterVolume then
            AdjustMasterVolume(delta)
        end
        if ShowVolumeButtonText then
            ShowVolumeButtonText(self)
        end
    end

    local function OnMainMenuButtonClick(_, mouseButton)
        local action = mouseButton or "LeftButton"
        if action == "RightButton" then
            local toggle = ToggleFrame
            if toggle then
                toggle(AddonList)
            end
            return
        end
        if action ~= "LeftButton" then
            return
        end
        if InCombatLockdown and InCombatLockdown() then
            PrintQFXWarning("Unavailable in combat. Please try again after combat ends.")
            return
        end
        local toggle = ToggleFrame
        if toggle then
            toggle(GameMenuFrame)
        end
    end

    local function ResolveNativeMicroButton(def)
        if not def or not def.nativeBtn then return nil end
        return _G[def.nativeBtn]
    end

    local qfxMenuDefinitions = {}
    local buttonDefByID = {}

    local function AddMicroMenuButton(def)
        if not def or not def.id then return end
        def.textureKey = def.textureKey or def.id
        def.var = def.var or ("isCustomMicroMenu" .. def.id)
        def.label = def.label or def.labelKey
        def.tooltip = def.tooltip or def.labelKey
        qfxMenuDefinitions[#qfxMenuDefinitions + 1] = def
        buttonDefByID[def.id] = def
    end

    local function AddNativeMicroButton(id, textureFile, labelKey, tooltipKey, nativeButtonName, badgeKey)
        local nativeDef = {}
        nativeDef.id = id
        nativeDef.texture = MICRO_ICON_PATH .. textureFile
        nativeDef.labelKey = labelKey
        nativeDef.tooltipKey = tooltipKey
        nativeDef.badgeKey = badgeKey
        nativeDef.isSecure = nativeButtonName ~= false
        nativeDef.secureAction = "nativeClick"
        nativeDef.nativeBtn = nativeButtonName
        AddMicroMenuButton(nativeDef)
    end

    AddNativeMicroButton("Character", "Character.tga", "Character", "Show the character info button.", "CharacterMicroButton", "durability")
    AddNativeMicroButton("Social", "Friends.tga", "Social", "Show the social button.", "QuickJoinToastButton", "friends")
    AddNativeMicroButton("Profession", "Profession.tga", "Profession", "Show the profession button.", "ProfessionMicroButton")
    AddNativeMicroButton("PlayerSpells", "SpellBook.tga", "Talents & Spells", "Show the talents and spellbook button.", "PlayerSpellsMicroButton")
    AddNativeMicroButton("Achievement", "Achievements.tga", "Achievements", "Show the achievements button.", "AchievementMicroButton")
    AddNativeMicroButton("QuestLog", "MissionReports.tga", "Quests", "Show the quest log button.", "QuestLogMicroButton")

    AddMicroMenuButton((function()
        local clockDef = {
            ["id"] = "Time",
            ["var"] = "isCustomMicroMenuTime",
            ["isText"] = true,
            ["labelKey"] = "Time",
            ["tooltipKey"] = "Show the time button.",
            ["isSecure"] = false,
        }
        clockDef.onClick = OnClockButtonClick
        return clockDef
    end)())

    AddNativeMicroButton("Housing", "Home.tga", "Housing", "Show the housing button.", "HousingMicroButton")
    AddMicroMenuButton({
        ["id"] = "Hearthstone",
        ["texture"] = MICRO_ICON_PATH .. "Hearthstone.tga",
        ["labelKey"] = "Hearthstone",
        ["tooltipKey"] = "Show the hearthstone button.",
        ["isSecure"] = true,
        ["secureAction"] = "hearthstone",
    })
    AddNativeMicroButton("Guild", "Guild.tga", "Guild / Communities", "Show the guild and communities button.", "GuildMicroButton", "guild")
    AddNativeMicroButton("LFD", "GroupFinder.tga", "Group Finder", "Show the group finder button.", "LFDMicroButton")
    AddMicroMenuButton({
        ["id"] = "MeetingStone",
        ["texture"] = MICRO_ICON_PATH .. "MeetingStone.tga",
        ["labelKey"] = "MeetingStone",
        ["tooltipKey"] = "Show the MeetingStone button.",
        ["isSecure"] = false,
        ["onClick"] = function(self, button) ToggleMeetingStone(self, button) end,
    })
    AddNativeMicroButton("Collections", "Collections.tga", "Collections", "Show the collections button.", "CollectionsMicroButton")
    AddNativeMicroButton("EJ", "EncounterJournal.tga", "Adventure Guide", "Show the adventure guide button.", "EJMicroButton")
    AddNativeMicroButton("Store", "BlizzardShop.tga", "Shop", "Show the shop button.", "StoreMicroButton")
    AddMicroMenuButton({
        ["id"] = "Bags",
        ["texture"] = MICRO_ICON_PATH .. "Bags.tga",
        ["labelKey"] = "Bags",
        ["tooltipKey"] = "Show the bags button.",
        ["badgeKey"] = "bags",
        ["isSecure"] = false,
        ["onClick"] = OnBagButtonClick,
    })
    AddMicroMenuButton({
        ["id"] = "Volume",
        ["texture"] = MICRO_ICON_PATH .. "Volume.tga",
        ["labelKey"] = "Volume",
        ["tooltipLines"] = { "Left Click: Volume Up", "Right Click: Volume Down" },
        ["badgeKey"] = "volume",
        ["isSecure"] = false,
        ["onClick"] = OnVolumeButtonClick,
    })
    AddMicroMenuButton({
        ["id"] = "MainMenu",
        ["texture"] = MICRO_ICON_PATH .. "GameMenu.tga",
        ["labelKey"] = "Game Menu",
        ["tooltipKey"] = "Show the game menu button.",
        ["isSecure"] = false,
        ["onClick"] = OnMainMenuButtonClick,
    })

    local HEARTHSTONE_SIDE_SETTINGS = {
        {
            dbKey = "customMicroMenuHearthstoneLeft",
            defaultValue = "6948",
            typeAttribute = "type1",
            macroAttribute = "macrotext1",
            labelKey = "Left Click",
        },
        {
            dbKey = "customMicroMenuHearthstoneMiddle",
            defaultValue = "none",
            typeAttribute = "type3",
            macroAttribute = "macrotext3",
            labelKey = "Middle Click",
        },
        {
            dbKey = "customMicroMenuHearthstoneRight",
            defaultValue = ns.HEARTHSTONE_RANDOM_VALUE or "random",
            typeAttribute = "type2",
            macroAttribute = "macrotext2",
            labelKey = "Right Click",
        },
    }

    local function GetHearthstoneActionName(value)
        if ns.GetHearthstoneActionName then return ns.GetHearthstoneActionName(value) end
        if tostring(value or "none") == "none" then return T("No Action") end
        return tostring(value or "")
    end

    local function BuildHearthstoneMacro(value, randomKey)
        if ns.BuildHearthstoneMacro then return ns.BuildHearthstoneMacro(value, randomKey) end
        value = tostring(value or "none")
        if value == "none" or value == "" then return nil end
        local itemID = tonumber(value)
        return itemID and ("/use item:" .. itemID) or nil
    end

    local function ConfigureHearthstoneButton(btn)
        if not btn then return end
        local db = QFXSystemBarDB or ns.defaults or {}
        for _, side in ipairs(HEARTHSTONE_SIDE_SETTINGS) do
            local value = db[side.dbKey]
            if value == nil then value = side.defaultValue end
            local macro = BuildHearthstoneMacro(value, side.dbKey)
            if macro then
                btn:SetAttribute(side.typeAttribute, "macro")
                btn:SetAttribute(side.macroAttribute, macro)
            else
                btn:SetAttribute(side.typeAttribute, nil)
                btn:SetAttribute(side.macroAttribute, nil)
            end
        end
        btn:EnableMouse(true)
    end

    local function GetHearthstoneTooltipLines()
        local db = QFXSystemBarDB or ns.defaults or {}
        local lines = { T("Hearthstone") }
        for _, side in ipairs(HEARTHSTONE_SIDE_SETTINGS) do
            local value = db[side.dbKey]
            if value == nil then value = side.defaultValue end
            if tostring(value or "none") ~= "none" and tostring(value or "") ~= "" then
                lines[#lines + 1] = T(side.labelKey) .. ": " .. GetHearthstoneActionName(value)
            end
        end
        if #lines == 1 then
            lines[#lines + 1] = T("No Action")
        end
        return lines
    end

    local coreNormalizeButtonID = ns.NormalizeMicroMenuButtonID
    local function NormalizeButtonID(id)
        if coreNormalizeButtonID then
            local normalized = coreNormalizeButtonID(id)
            if normalized then return normalized end
        end
        if type(id) ~= "string" then return nil end
        return id
    end
    ns.NormalizeMicroMenuButtonID = NormalizeButtonID

    local function CopyDefaultButtonOrder()
        local order = {}
        local seen = {}
        for _, id in ipairs(ns.defaultMicroMenuButtonOrder or {}) do
            local normalized = NormalizeButtonID(id)
            if normalized and buttonDefByID[normalized] and not seen[normalized] then
                order[#order + 1] = normalized
                seen[normalized] = true
            end
        end
        for _, def in ipairs(qfxMenuDefinitions) do
            if not seen[def.id] then
                order[#order + 1] = def.id
                seen[def.id] = true
            end
        end
        return order
    end

    local function NormalizeButtonOrder()
        QFXSystemBarDB = QFXSystemBarDB or {}
        local raw = QFXSystemBarDB.customMicroMenuButtonOrder
        if type(raw) ~= "table" then raw = CopyDefaultButtonOrder() end

        local seen, order = {}, {}
        for _, rawID in ipairs(raw) do
            local id = NormalizeButtonID(rawID)
            if buttonDefByID[id] and not seen[id] then
                order[#order + 1] = id
                seen[id] = true
            end
        end
        for _, def in ipairs(qfxMenuDefinitions) do
            if not seen[def.id] then
                order[#order + 1] = def.id
                seen[def.id] = true
            end
        end
        QFXSystemBarDB.customMicroMenuButtonOrder = order
        return order
    end

    local function GetOrderedButtonDefs()
        local ordered = {}
        for _, id in ipairs(NormalizeButtonOrder()) do
            local def = buttonDefByID[id]
            if def then ordered[#ordered + 1] = def end
        end
        return ordered
    end

    function ns.GetMicroMenuButtonOrder()
        local copy = {}
        for _, id in ipairs(NormalizeButtonOrder()) do copy[#copy + 1] = id end
        return copy
    end

    function ns.MoveMicroMenuButton(id, delta)
        local order = NormalizeButtonOrder()
        local index
        for i, v in ipairs(order) do
            if v == id then index = i; break end
        end
        if not index then return end
        local target = index + (delta or 0)
        if target < 1 or target > #order then return end
        order[index], order[target] = order[target], order[index]
        QFXSystemBarDB.customMicroMenuButtonOrder = order
        if ns.OnMicroMenuChanged then ns.OnMicroMenuChanged() end
    end

    function ns.ResetMicroMenuButtonOrder()
        QFXSystemBarDB = QFXSystemBarDB or {}
        QFXSystemBarDB.customMicroMenuButtonOrder = CopyDefaultButtonOrder()
        if ns.OnMicroMenuChanged then ns.OnMicroMenuChanged() end
    end

    -- -------------------------------------------------------------------
    -- Hover tooltip: text-only, no background or border
    -- -------------------------------------------------------------------
    local function Two(n)
        n = tonumber(n) or 0
        if n < 10 then return "0" .. n end
        return tostring(n)
    end

    local qfxHoverTooltip

    local function EnsureQFXHoverTooltip()
        if qfxHoverTooltip then return qfxHoverTooltip end
        qfxHoverTooltip = CreateFrame("Frame", "QFXSystemBarHoverTooltip", UIParent)
        qfxHoverTooltip:SetFrameStrata("TOOLTIP")
        qfxHoverTooltip:EnableMouse(false)
        qfxHoverTooltip.lines = {}
        qfxHoverTooltip:Hide()
        return qfxHoverTooltip
    end

    local function ShowQFXHoverTooltip(owner, lines)
        if not owner then return end
        local tip = EnsureQFXHoverTooltip()
        local maxW, lineH, gap = 0, 0, 2
        for i, text in ipairs(lines or {}) do
            local fs = tip.lines[i]
            if not fs then
                fs = tip:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                fs:SetJustifyH("CENTER")
                fs:SetShadowColor(0, 0, 0, 1)
                fs:SetShadowOffset(1, -1)
                tip.lines[i] = fs
            end
            fs:ClearAllPoints()
            fs:SetPoint("TOP", tip, "TOP", 0, -((i - 1) * 14))
            fs:SetText(text or "")
            fs:Show()
            maxW = math.max(maxW, fs:GetStringWidth() or 0)
            lineH = lineH + 14
        end
        for i = #(lines or {}) + 1, #tip.lines do
            tip.lines[i]:Hide()
        end
        tip:SetSize(math.max(24, maxW + 4), math.max(14, lineH + gap))
        tip:ClearAllPoints()
        tip:SetPoint("TOP", owner, "BOTTOM", 0, -5)
        tip:Show()
    end

    local function HideQFXTooltip()
        if qfxHoverTooltip then qfxHoverTooltip:Hide() end
        GameTooltip:Hide()
    end

    local function ShowOldStyleButtonTooltip(frame, def)
        if def and def.secureAction == "hearthstone" then
            ShowQFXHoverTooltip(frame, GetHearthstoneTooltipLines())
            return
        end
        if def and def.id == "MeetingStone" then
            local name = (ns.GetPremadeAddonDisplayName and ns.GetPremadeAddonDisplayName()) or "MeetingStone"
            ShowQFXHoverTooltip(frame, { name })
            return
        end
        if def and def.tooltipLines then
            local lines = {}
            if def.labelKey or def.label then
                lines[#lines + 1] = T(def.labelKey or def.label)
            end
            for _, lineKey in ipairs(def.tooltipLines) do
                lines[#lines + 1] = T(lineKey)
            end
            ShowQFXHoverTooltip(frame, lines)
            return
        end
        ShowQFXHoverTooltip(frame, { T((def and (def.labelKey or def.label or def.tooltipKey or def.tooltip)) or "") })
    end

    local function ShowOldStyleClockTooltip(frame)
        ShowQFXHoverTooltip(frame, { T("Left Click: Open Calendar"), T("Right Click: Clean Memory") })
    end

    -- -------------------------------------------------------------------
    -- QFX palette helpers
    -- -------------------------------------------------------------------
    local playerClassRGB
    local clockTintRGB = { r = 1, g = 1, b = 1 }

    local function ReadPlayerClassRGB()
        if playerClassRGB == nil then
            local _, classToken = UnitClass("player")
            playerClassRGB = (RAID_CLASS_COLORS and classToken and RAID_CLASS_COLORS[classToken]) or false
        end
        local color = playerClassRGB
        if not color then
            return 1, 1, 1
        end
        return color.r or 1, color.g or 1, color.b or 1
    end

    local function ReadHexColorSetting(dbKey, defaultHex)
        local hex = (QFXSystemBarDB and QFXSystemBarDB[dbKey]) or defaultHex or "FFFFFFFF"
        local ok, color = pcall(CreateColorFromHexString, hex)
        if ok and color then
            return color:GetRGB()
        end
        return 1, 1, 1
    end

    local function ResolveClockTint()
        local db = QFXSystemBarDB or {}
        local choice = db.customMicroMenuClockColorMode or "class"
        if choice == "custom" then
            return ReadHexColorSetting("customMicroMenuClockCustomColor", db.customMicroMenuTextColor or "FFFFFFFF")
        elseif choice == "original" then
            return 1, 1, 1
        end
        return ReadPlayerClassRGB()
    end

    local function RefreshClockTintCache()
        local r, g, b = ResolveClockTint()
        clockTintRGB.r, clockTintRGB.g, clockTintRGB.b = r, g, b
    end

    local function ResolveIconTint()
        local db = QFXSystemBarDB or {}
        local choice = db.customMicroMenuIconColorMode or "class"
        if choice == "original" then
            return nil
        elseif choice == "custom" then
            return ReadHexColorSetting("customMicroMenuIconCustomColor", db.customMicroMenuTextColor or "FFFFFFFF")
        end
        return ReadPlayerClassRGB()
    end


    -- -------------------------------------------------------------------
    -- Button extra text counters
    -- -------------------------------------------------------------------
    local qfxButtonPool = {}
    local badgeValues = { friends = 0, guild = nil, bags = 0, durability = nil, volume = nil }
    local badgeUpdatePending = {}
    local RefreshQFXClockWidgets, StartQFXClockTicker, StopQFXClockTicker, RefreshPulseTickerState
    local IsMicroMenuEnabledNow

    local function GetBadgeColorRGB(badgeKey)
        local db = QFXSystemBarDB or {}
        local mode = db.customMicroMenuBadgeColorMode or "original"
        if mode == "class" then return ReadPlayerClassRGB() end
        if mode == "custom" then return ReadHexColorSetting("customMicroMenuBadgeCustomColor", db.customMicroMenuBadgeTextColor or "FFFFFFFF") end
        return 1, 1, 1
    end

    local function IsBadgeEnabled(key)
        local db = QFXSystemBarDB or ns.defaults or {}
        local map = ns.microMenuBadgeSettingByKey or {}
        local settingKey = map[key]
        if settingKey then
            return db[settingKey] ~= false
        end

        -- Backward-compatible fallback for very old builds that only had the
        -- multi-select customMicroMenuBadgeDisplay table.
        local display = db and db.customMicroMenuBadgeDisplay
        return type(display) == "table" and display[key] and true or false
    end

    local function ClampPercent(value)
        value = tonumber(value) or 0
        if value < 0 then return 0 end
        if value > 100 then return 100 end
        return value
    end

    local function GetMasterVolumePercent()
        local raw
        if C_CVar and C_CVar.GetCVar then
            raw = C_CVar.GetCVar("Sound_MasterVolume")
        elseif GetCVar then
            raw = GetCVar("Sound_MasterVolume")
        end
        local value = tonumber(raw)
        if not value then return 0 end
        return ClampPercent(math.floor((value * 100) + 0.5))
    end

    local function SetMasterVolumePercent(percent)
        local clamped = ClampPercent(percent)
        local cvarValue = ("%.2f"):format(clamped / 100)
        if C_CVar and C_CVar.SetCVar then
            C_CVar.SetCVar("Sound_MasterVolume", cvarValue)
        elseif SetCVar then
            SetCVar("Sound_MasterVolume", cvarValue)
        end
        return clamped
    end

    AdjustMasterVolume = function(delta)
        return SetMasterVolumePercent(GetMasterVolumePercent() + (tonumber(delta) or 0))
    end

    -- Volume uses the same managed badge text as friends, durability, guild,
    -- and bag slots, but it remains hover-only. Do not create a separate
    -- centered FontString; this keeps font, color, position, and refresh
    -- behavior unified while preserving the old "show on mouseover" behavior.
    local function IsVolumeBadge(def)
        return def and def.badgeKey == "volume"
    end

    local function HideVolumeButtonText(btn)
        if not btn then return end
        btn.qfxVolumeBadgeHover = nil
        if btn.qfxBadgeText and btn.qfxDefinition and IsVolumeBadge(btn.qfxDefinition) then
            btn.qfxBadgeText:Hide()
        end
        if btn.qfxVolumeText then
            btn.qfxVolumeText:Hide()
        end
    end

    local function ShouldShowBadgeOnButton(btn, def)
        if IsVolumeBadge(def) then
            return btn and btn.qfxVolumeBadgeHover == true
        end
        return true
    end

    ShowVolumeButtonText = function(btn)
        if not btn then return end
        btn.qfxVolumeBadgeHover = true
        RefreshBadgeValue("volume")
        UpdateButtonBadge(btn, btn.qfxDefinition)
    end

    local function GetOnlineFriendCount()
        local total = 0

        if C_FriendList and C_FriendList.GetNumOnlineFriends then
            local ok, count = pcall(C_FriendList.GetNumOnlineFriends)
            if ok and count then total = total + count end
        elseif GetNumFriends and GetFriendInfo then
            local ok, count = pcall(GetNumFriends)
            if ok and count then
                for i = 1, count do
                    local okInfo, _, _, _, _, connected = pcall(GetFriendInfo, i)
                    if okInfo and connected then total = total + 1 end
                end
            end
        end

        if BNGetNumFriends then
            local ok, _, online = pcall(BNGetNumFriends)
            if ok and online then total = total + online end
        end

        return total
    end

    local function GetOnlineGuildCount()
        if not IsInGuild or not IsInGuild() then return nil end
        if GetNumGuildMembers then
            local ok, _, online = pcall(GetNumGuildMembers)
            if ok and online then return online end
        end
        return 0
    end

    local function GetFreeBagSlots()
        local free = 0
        local getFree = C_Container and C_Container.GetContainerNumFreeSlots
        if not getFree then return 0 end

        for bag = 0, NUM_BAG_SLOTS or 4 do
            local ok, count = pcall(getFree, bag)
            if ok and count then free = free + count end
        end

        local reagentBag = Enum and Enum.BagIndex and Enum.BagIndex.ReagentBag
        if reagentBag then
            local ok, count = pcall(getFree, reagentBag)
            if ok and count then free = free + count end
        end

        return free
    end

    local function GetEquippedDurabilityPercentText()
        -- Display only: calculate a text badge from equipped item durability.
        -- This does not touch the character icon texture, secure attributes,
        -- button size, or the micro-menu layout.
        if not GetInventoryItemDurability then return nil end

        local totalCurrent, totalMax = 0, 0
        local firstSlot = INVSLOT_FIRST_EQUIPPED or 1
        local lastSlot = INVSLOT_LAST_EQUIPPED or 19

        for slot = firstSlot, lastSlot do
            local ok, current, maximum = pcall(GetInventoryItemDurability, slot)
            current = ok and tonumber(current) or nil
            maximum = ok and tonumber(maximum) or nil
            if current and maximum and maximum > 0 then
                totalCurrent = totalCurrent + math.max(0, current)
                totalMax = totalMax + maximum
            end
        end

        if totalMax <= 0 then return nil end
        local percent = math.floor((totalCurrent / totalMax) * 100 + 0.5)
        if percent < 0 then percent = 0 elseif percent > 100 then percent = 100 end
        return tostring(percent)
    end

    RefreshBadgeValue = function(kind)
        if kind == "friends" or kind == "all" then
            badgeValues.friends = GetOnlineFriendCount()
        end
        if kind == "guild" or kind == "all" then
            badgeValues.guild = GetOnlineGuildCount()
        end
        if kind == "bags" or kind == "all" then
            badgeValues.bags = GetFreeBagSlots()
        end
        if kind == "durability" or kind == "all" then
            badgeValues.durability = GetEquippedDurabilityPercentText()
        end
        if kind == "volume" or kind == "all" then
            badgeValues.volume = GetMasterVolumePercent()
        end
    end

    local function StopBadgeHeartbeat(btn)
        if btn and btn.qfxBadgeHeartbeat then btn.qfxBadgeHeartbeat:Stop() end
        if btn and btn.qfxBadgeText then btn.qfxBadgeText:SetAlpha(1) end
    end

    local function IsLowDurabilityBadge(def, value)
        if not def or def.badgeKey ~= "durability" then return false end
        local percent = tonumber(value)
        return percent ~= nil and percent < 50
    end

    local function EnsureBadgeText(btn)
        if not btn.qfxBadgeText then
            btn.qfxBadgeText = btn:CreateFontString(nil, "OVERLAY")
            btn.qfxBadgeText:SetJustifyH("RIGHT")
            btn.qfxBadgeText:SetJustifyV("BOTTOM")
            btn.qfxBadgeText:SetShadowColor(0, 0, 0, 1)
            btn.qfxBadgeText:SetShadowOffset(1, -1)
            if btn.qfxBadgeText.SetDrawLayer then btn.qfxBadgeText:SetDrawLayer("OVERLAY", 7) end

            -- A FontString must have a font before any SetText() call.
            -- Set a safe default immediately so nil/hidden counters, such as
            -- guild count on characters without a guild, can be hidden safely.
            local defaultIconSize = btn.qfxIconSize or (QFXSystemBarDB and QFXSystemBarDB.customMicroMenuIconSize) or 30
            local defaultFontSize = math.max(9, math.floor(defaultIconSize * 0.42 + 0.5))
            btn.qfxBadgeText:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF", defaultFontSize, "OUTLINE")
        end
        return btn.qfxBadgeText
    end

    local function EnsureBadgeHeartbeat(btn)
        if not btn or not btn.qfxBadgeText then return nil end
        if btn.qfxBadgeHeartbeat then return btn.qfxBadgeHeartbeat end

        local ag = btn.qfxBadgeText:CreateAnimationGroup()
        ag:SetLooping("REPEAT")

        local fadeOut = ag:CreateAnimation("Alpha")
        fadeOut:SetFromAlpha(1)
        fadeOut:SetToAlpha(0.22)
        fadeOut:SetDuration(0.45)
        fadeOut:SetOrder(1)

        local fadeIn = ag:CreateAnimation("Alpha")
        fadeIn:SetFromAlpha(0.22)
        fadeIn:SetToAlpha(1)
        fadeIn:SetDuration(0.45)
        fadeIn:SetOrder(2)

        ag:SetScript("OnPlay", function()
            if btn.qfxBadgeText then btn.qfxBadgeText:SetAlpha(1) end
        end)
        ag:SetScript("OnStop", function()
            if btn.qfxBadgeText then btn.qfxBadgeText:SetAlpha(1) end
        end)

        btn.qfxBadgeHeartbeat = ag
        return ag
    end

    local function StartBadgeHeartbeat(btn, def)
        if not btn or not def or not btn.qfxBadgeText then return end
        local value = badgeValues[def.badgeKey]
        if not IsBadgeEnabled(def.badgeKey) or not IsLowDurabilityBadge(def, value) then return end
        local ag = EnsureBadgeHeartbeat(btn)
        if ag and not ag:IsPlaying() then
            btn.qfxBadgeText:SetAlpha(1)
            ag:Play()
        end
    end

    local function ApplyBadgeVisualState(btn, def, value, refreshLayout)
        local iconSize = btn.qfxIconSize or (QFXSystemBarDB and QFXSystemBarDB.customMicroMenuIconSize) or 30
        local fontSize = math.max(9, math.floor(iconSize * 0.42 + 0.5))
        local isLowDurability = IsLowDurabilityBadge(def, value)
        local fontPath = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
        local text = EnsureBadgeText(btn)

        text:SetFont(fontPath, fontSize, "OUTLINE")
        if refreshLayout then
            text:ClearAllPoints()
            text:SetPoint("BOTTOMRIGHT", btn.mmIcon or btn, "BOTTOMRIGHT", 2, -2)
        end

        -- Keep the durability number on the same color system as other extra text.
        -- Low durability warning is alpha heartbeat only; no orange color, glow, or thick outline.
        local r, g, b = GetBadgeColorRGB(def and def.badgeKey)
        text:SetTextColor(r, g, b)
        text:SetShadowColor(0, 0, 0, 1)
        text:SetShadowOffset(1, -1)
        if isLowDurability then
            StartBadgeHeartbeat(btn, def)
        else
            StopBadgeHeartbeat(btn)
        end
    end

    UpdateButtonBadge = function(btn, def)
        if not btn or not def or not def.badgeKey then
            if btn and btn.qfxBadgeText then btn.qfxBadgeText:Hide() end
            StopBadgeHeartbeat(btn)
            return
        end

        local text = EnsureBadgeText(btn)
        local value = badgeValues[def.badgeKey]
        if not IsBadgeEnabled(def.badgeKey) or value == nil or not ShouldShowBadgeOnButton(btn, def) then
            text:Hide()
            StopBadgeHeartbeat(btn)
            return
        end

        ApplyBadgeVisualState(btn, def, value, true)
        text:SetText(tostring(value))
        text:Show()
    end

    local function UpdateBadgeTextOnly(btn, def)
        -- Runtime counter refresh path: only touch the existing FontString and heartbeat state.
        -- Never rebuild buttons, move frames, resize buttons, or modify secure attributes here.
        if not btn or not def or not def.badgeKey or not btn.qfxBadgeText then return end

        local value = badgeValues[def.badgeKey]
        if not IsBadgeEnabled(def.badgeKey) or value == nil or not ShouldShowBadgeOnButton(btn, def) then
            -- Only hide nil/disabled/hover-gated counters. Do not call SetText("") here;
            -- this runtime path must not rebuild the button or refresh icon textures.
            btn.qfxBadgeText:Hide()
            StopBadgeHeartbeat(btn)
            return
        end

        ApplyBadgeVisualState(btn, def, value, false)
        btn.qfxBadgeText:SetText(tostring(value))
        btn.qfxBadgeText:Show()
    end

    local function UpdateAllBadges(refreshValues)
        -- Full badge style/layout refresh. This is used only from button rebuilds or UI option changes.
        -- Event-driven count updates use UpdateBadgeTextOnly() instead.
        if refreshValues then RefreshBadgeValue("all") end
        for id, btn in pairs(qfxButtonPool or {}) do
            UpdateButtonBadge(btn, buttonDefByID[id])
        end
    end

    local function UpdateBadgeTextsOnly(kind)
        kind = kind or "all"
        for id, btn in pairs(qfxButtonPool or {}) do
            local def = buttonDefByID[id]
            if def and def.badgeKey and (kind == "all" or kind == def.badgeKey) then
                UpdateBadgeTextOnly(btn, def)
            end
        end
    end

    local function HasLowDurabilityBadge()
        if not IsBadgeEnabled("durability") then return false end
        local value = badgeValues.durability
        if not value or tonumber(value) == nil or tonumber(value) >= 50 then return false end
        for id, btn in pairs(qfxButtonPool or {}) do
            local def = buttonDefByID[id]
            if def and def.badgeKey == "durability" and btn and btn.qfxBadgeText and btn.qfxBadgeText:IsShown() then
                return true
            end
        end
        return false
    end

    RequestBadgeUpdate = function(kind, delay)
        if not IsMicroMenuEnabledNow() then return end
        kind = kind or "all"
        if badgeUpdatePending[kind] then return end
        badgeUpdatePending[kind] = true
        if C_Timer and C_Timer.After then
            C_Timer.After(delay or 0.2, function()
                badgeUpdatePending[kind] = nil
                RefreshBadgeValue(kind)
                UpdateBadgeTextsOnly(kind)
                if RefreshPulseTickerState then RefreshPulseTickerState() end
            end)
        else
            badgeUpdatePending[kind] = nil
            RefreshBadgeValue(kind)
            UpdateBadgeTextsOnly(kind)
            if RefreshPulseTickerState then RefreshPulseTickerState() end
        end
    end

    ns.RefreshMicroMenuBadges = function(refreshValues)
        UpdateAllBadges(refreshValues)
        if ns.UpdateMicroMenuEventRegistration then ns.UpdateMicroMenuEventRegistration() end
    end

    -- -------------------------------------------------------------------
    -- Icon styles and normalization
    -- -------------------------------------------------------------------
    -- Supports four icon styles: ElvUI WindTools GameBar-inspired icons plus three web icon sets.
    -- Each icon set is normalized into the same button cell size for consistent alignment.
    local ICON_STYLE_OPTIONS = {
        original = {
            folder = "Interface\\AddOns\\QFXSystemBar\\Media\\MicroMenu\\",
            files = {
                Character    = "Character.tga",
                Social       = "Friends.tga",
                Profession   = "Profession.tga",
                PlayerSpells = "SpellBook.tga",
                Achievement  = "Achievements.tga",
                QuestLog     = "MissionReports.tga",
                Housing      = "Home.tga",
                Hearthstone  = "Hearthstone.tga",
                Guild        = "Guild.tga",
                LFD          = "GroupFinder.tga",
                MeetingStone = "MeetingStone.tga",
                Collections  = "Collections.tga",
                EJ           = "EncounterJournal.tga",
                Store        = "BlizzardShop.tga",
                Bags         = "Bags.tga",
                Volume       = "Volume.tga",
                MainMenu     = "GameMenu.tga",
            },
        },
        gameicons = {
            folder = "Interface\\AddOns\\QFXSystemBar\\Media\\MicroMenu\\GameIcons\\",
            files = { Character = "Character.tga", Social = "Social.tga", Profession = "Profession.tga", PlayerSpells = "PlayerSpells.tga", Achievement = "Achievement.tga", QuestLog = "QuestLog.tga", Housing = "Housing.tga", Hearthstone = "Hearthstone.tga", Guild = "Guild.tga", LFD = "LFD.tga", MeetingStone = "MeetingStone.tga", Collections = "Collections.tga", EJ = "EJ.tga", Store = "Store.tga", Bags = "Bags.tga", Volume = "Volume.tga", MainMenu = "MainMenu.tga" },
        },
        lucide = {
            folder = "Interface\\AddOns\\QFXSystemBar\\Media\\MicroMenu\\Lucide\\",
            files = { Character = "Character.tga", Social = "Social.tga", Profession = "Profession.tga", PlayerSpells = "PlayerSpells.tga", Achievement = "Achievement.tga", QuestLog = "QuestLog.tga", Housing = "Housing.tga", Hearthstone = "Hearthstone.tga", Guild = "Guild.tga", LFD = "LFD.tga", MeetingStone = "MeetingStone.tga", Collections = "Collections.tga", EJ = "EJ.tga", Store = "Store.tga", Bags = "Bags.tga", Volume = "Volume.tga", MainMenu = "MainMenu.tga" },
        },
        tabler = {
            folder = "Interface\\AddOns\\QFXSystemBar\\Media\\MicroMenu\\Tabler\\",
            files = { Character = "Character.tga", Social = "Social.tga", Profession = "Profession.tga", PlayerSpells = "PlayerSpells.tga", Achievement = "Achievement.tga", QuestLog = "QuestLog.tga", Housing = "Housing.tga", Hearthstone = "Hearthstone.tga", Guild = "Guild.tga", LFD = "LFD.tga", MeetingStone = "MeetingStone.tga", Collections = "Collections.tga", EJ = "EJ.tga", Store = "Store.tga", Bags = "Bags.tga", Volume = "Volume.tga", MainMenu = "MainMenu.tga" },
        },
    }

    local ICON_TEX_COORDS = {
        original = {},
        gameicons = {
            Achievement   = { 0.093750, 0.906250, 0.031250, 0.968750 },
            Bags          = { 0.062500, 0.937500, 0.031250, 0.968750 },
            Character     = { 0.156250, 0.843750, 0.031250, 1.000000 },
            Collections   = { 0.062500, 0.937500, 0.093750, 0.906250 },
            EJ            = { 0.062500, 0.937500, 0.062500, 0.937500 },
            Guild         = { 0.031250, 0.968750, 0.031250, 0.968750 },
            Hearthstone   = { 0.093750, 0.906250, 0.031250, 0.968750 },
            Housing       = { 0.031250, 0.968750, 0.031250, 0.968750 },
            LFD           = { 0.031250, 0.968750, 0.031250, 0.968750 },
            MainMenu      = { 0.031250, 0.968750, 0.031250, 0.968750 },
            PlayerSpells  = { 0.031250, 0.968750, 0.031250, 0.968750 },
            Profession    = { 0.125000, 0.968750, 0.031250, 0.968750 },
            QuestLog      = { 0.062500, 0.968750, 0.031250, 0.968750 },
            Social        = { 0.031250, 0.968750, 0.062500, 0.937500 },
            Store         = { 0.093750, 0.906250, 0.031250, 0.968750 },
        },
        lucide = {
            Achievement   = { 0.031250, 0.968750, 0.031250, 0.968750 },
            Bags          = { 0.125000, 0.875000, 0.031250, 0.968750 },
            Character     = { 0.156250, 0.843750, 0.062500, 0.937500 },
            Collections   = { 0.031250, 0.968750, 0.031250, 0.968750 },
            EJ            = { 0.062500, 0.937500, 0.093750, 0.906250 },
            Guild         = { 0.125000, 0.875000, 0.031250, 0.968750 },
            Hearthstone   = { 0.062500, 0.968750, 0.062500, 0.968750 },
            Housing       = { 0.062500, 0.937500, 0.031250, 0.937500 },
            LFD           = { 0.031250, 0.968750, 0.062500, 0.937500 },
            MainMenu      = { 0.062500, 0.937500, 0.031250, 0.968750 },
            PlayerSpells  = { 0.031250, 0.968750, 0.062500, 0.937500 },
            Profession    = { 0.031250, 0.968750, 0.062500, 0.968750 },
            QuestLog      = { 0.031250, 0.968750, 0.062500, 0.937500 },
            Social        = { 0.031250, 0.968750, 0.062500, 0.937500 },
            Store         = { 0.062500, 0.937500, 0.031250, 0.968750 },
        },
        tabler = {
            Achievement   = { 0.062500, 0.937500, 0.125000, 0.937500 },
            Bags          = { 0.156250, 0.843750, 0.062500, 0.937500 },
            Character     = { 0.187500, 0.812500, 0.062500, 0.937500 },
            Collections   = { 0.062500, 0.937500, 0.062500, 0.937500 },
            EJ            = { 0.062500, 0.937500, 0.125000, 0.875000 },
            Guild         = { 0.156250, 0.843750, 0.093750, 0.937500 },
            Hearthstone   = { 0.062500, 0.968750, 0.062500, 0.968750 },
            Housing       = { 0.062500, 0.937500, 0.062500, 0.937500 },
            LFD           = { 0.062500, 0.937500, 0.062500, 0.937500 },
            MainMenu      = { 0.062500, 0.937500, 0.062500, 0.937500 },
            PlayerSpells  = { 0.062500, 0.937500, 0.156250, 0.843750 },
            Profession    = { 0.093750, 0.937500, 0.093750, 0.937500 },
            QuestLog      = { 0.156250, 0.843750, 0.062500, 0.937500 },
            Social        = { 0.062500, 0.937500, 0.062500, 0.937500 },
            Store         = { 0.125000, 0.875000, 0.062500, 0.937500 },
        },
    }

    local function GetIconStyleKey()
        local key = QFXSystemBarDB and QFXSystemBarDB.customMicroMenuIconStyle or "gameicons"
        if not ICON_STYLE_OPTIONS[key] then key = "original" end
        return key
    end

    local function GetIconTexture(def)
        local style = ICON_STYLE_OPTIONS[GetIconStyleKey()] or ICON_STYLE_OPTIONS.original
        local key = def and (def.textureKey or def.id)
        local file = key and style.files and style.files[key]
        if file then return style.folder .. file end
        return def and def.texture
    end

    local function ApplyIconTexCoords(texture, def)
        local styleKey = GetIconStyleKey()
        local key = def and (def.textureKey or def.id)
        local styleCoords = ICON_TEX_COORDS[styleKey] or ICON_TEX_COORDS.original
        local c = key and styleCoords and styleCoords[key]
        if c then
            texture:SetTexCoord(c[1], c[2], c[3], c[4])
        else
            texture:SetTexCoord(0, 1, 0, 1)
        end
    end

    local function ReleaseButtonIconTexture(btn)
        if not (btn and btn.mmIcon) then return end
        btn.mmIcon:SetTexture(nil)
        btn.mmIcon:SetTexCoord(0, 1, 0, 1)
        btn.mmIcon:Hide()
        btn.qfxLoadedIconTexture = nil
    end

    local function ReleaseAllMicroMenuIconTextures()
        for _, btn in pairs(qfxButtonPool or {}) do
            ReleaseButtonIconTexture(btn)
        end
    end

    local function ApplyButtonIconTexture(btn, def)
        if not (btn and btn.mmIcon) then return end
        local texturePath = GetIconTexture(def)
        if btn.qfxLoadedIconTexture ~= texturePath then
            -- Keep only the selected icon set referenced by live Texture objects.
            -- Hidden/old theme textures are cleared before the new path is applied.
            btn.mmIcon:SetTexture(nil)
            if texturePath then
                btn.mmIcon:SetTexture(texturePath)
            end
            btn.qfxLoadedIconTexture = texturePath
        end
        ApplyIconTexCoords(btn.mmIcon, def)
    end

    -- -------------------------------------------------------------------
    -- QFX clock utility
    -- -------------------------------------------------------------------
    local function PadClockNumber(value)
        return ("%02d"):format(tonumber(value) or 0)
    end

    local function ReadClockSource()
        local db = QFXSystemBarDB or {}
        if db.customMicroMenuTimeMode == "server" then
            local serverHour, serverMinute = GetGameTime()
            return serverHour or 0, serverMinute or 0
        end
        local localTime = date("*t") or {}
        return localTime.hour or 0, localTime.min or 0
    end

    local function BuildClockTextParts()
        local hour, minute = ReadClockSource()
        local useTwelveHour = QFXSystemBarDB and QFXSystemBarDB.customMicroMenuTimeFormat == "12h"
        if useTwelveHour then
            hour = hour % 12
            if hour < 1 then
                hour = 12
            end
            return tostring(hour), PadClockNumber(minute)
        end
        return PadClockNumber(hour), PadClockNumber(minute)
    end

    local function BuildClockSignature()
        local hourText, minuteText = BuildClockTextParts()
        return ("%s:%s"):format(hourText, minuteText)
    end

    -- -------------------------------------------------------------------
    -- QFX clock update system
    -- -------------------------------------------------------------------
    local qfxClockButtons = {}
    local previousClockSignature = false
    local qfxClockTicker

    IsMicroMenuEnabledNow = function()
        return QFXSystemBarDB and QFXSystemBarDB.isCustomMicroMenu == true
    end

    local function GetSelectedTimeFont()
        local db = QFXSystemBarDB
        if ns.ResolveMicroMenuTimeFont then
            return ns.ResolveMicroMenuTimeFont(db and db.customMicroMenuTimeFont or "default")
        end
        return STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
    end

    local function GetClockNumberVerticalOffset()
        local db = QFXSystemBarDB or {}
        return tonumber(db.customMicroMenuTimeTextYOffset) or 0
    end

    local function ApplyTimeFont(fs, textSize, outlineStyle)
        if not fs then return end
        local fontPath = GetSelectedTimeFont()
        local ok
        if outlineStyle and outlineStyle ~= "" then
            ok = fs:SetFont(fontPath, textSize, outlineStyle)
        else
            ok = fs:SetFont(fontPath, textSize)
        end
        -- Some localized font files may not exist on every client.  If the
        -- selected font fails, fall back to the client's normal text font.
        if not ok then
            if outlineStyle and outlineStyle ~= "" then
                fs:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF", textSize, outlineStyle)
            else
                fs:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF", textSize)
            end
        end
        fs:SetJustifyH("CENTER")
        if fs.SetJustifyV then fs:SetJustifyV("MIDDLE") end
    end

    local function GetFixedTimePartWidth(fs)
        if not fs then return 1 end
        local oldText = fs:GetText()
        local maxWidth = 1
        for i = 0, 59 do
            fs:SetText(string.format("%02d", i))
            local width = fs:GetStringWidth() or 0
            if width > maxWidth then
                maxWidth = width
            end
        end
        fs:SetText(oldText or "")
        return math.ceil(maxWidth)
    end

    local function GetClockTextHeight(fs, fallbackSize)
        if not fs then return math.max(1, tonumber(fallbackSize) or 1) end
        local oldText = fs:GetText()
        fs:SetText("00")
        local height = fs.GetStringHeight and fs:GetStringHeight() or nil
        fs:SetText(oldText or "")
        return math.max(1, math.ceil(tonumber(height) or tonumber(fallbackSize) or 1))
    end

    local qfxColonBlinkTicker
    local qfxColonBlinkVisible = true
    local COLON_BLINK_INTERVAL = 1.0

    local function SetClockColonVisible(btn, visible)
        if not btn then return end
        local alpha = visible and 1 or 0
        if btn.timeColonAnchor then
            btn.timeColonAnchor:Show()
            btn.timeColonAnchor:SetAlpha(alpha)
        end
        if btn.timeColonTop then
            btn.timeColonTop:SetAlpha(alpha)
            if visible then btn.timeColonTop:Show() else btn.timeColonTop:Hide() end
        end
        if btn.timeColonBottom then
            btn.timeColonBottom:SetAlpha(alpha)
            if visible then btn.timeColonBottom:Show() else btn.timeColonBottom:Hide() end
        end
    end

    local function StopClockColonBlinkTicker(resetVisible)
        if qfxColonBlinkTicker then
            qfxColonBlinkTicker:Cancel()
            qfxColonBlinkTicker = nil
        end
        if resetVisible then
            qfxColonBlinkVisible = true
            for _, btn in ipairs(qfxClockButtons) do
                SetClockColonVisible(btn, true)
            end
        end
    end

    local function TickClockColonBlink()
        if not IsMicroMenuEnabledNow() or #qfxClockButtons == 0 then
            StopClockColonBlinkTicker(true)
            return
        end

        qfxColonBlinkVisible = not qfxColonBlinkVisible
        local anyVisible = false
        for _, btn in ipairs(qfxClockButtons) do
            if btn:IsVisible() then
                anyVisible = true
                SetClockColonVisible(btn, qfxColonBlinkVisible)
            end
        end

        if not anyVisible then
            StopClockColonBlinkTicker(true)
        end
    end

    local function StartClockColonBlinkTicker()
        if not C_Timer or not C_Timer.NewTicker then return end
        if qfxColonBlinkTicker then return end
        qfxColonBlinkVisible = true
        for _, btn in ipairs(qfxClockButtons) do
            if btn:IsVisible() then
                SetClockColonVisible(btn, true)
            end
        end
        qfxColonBlinkTicker = C_Timer.NewTicker(COLON_BLINK_INTERVAL, TickClockColonBlink)
    end

    local function StartTimeColonPulse(btn)
        if not btn or not btn.timeColonAnchor then return end
        SetClockColonVisible(btn, qfxColonBlinkVisible)
        StartClockColonBlinkTicker()
    end

    local function StopTimeColonPulse(btn)
        SetClockColonVisible(btn, true)
    end

    local function StopAllClockColonPulses()
        StopClockColonBlinkTicker(true)
    end

    local function UpdateTimeButton(btn)
        if not btn or not btn.timeHour or not btn.timeMinute or not btn.timeColonAnchor then return end
        local h, m = BuildClockTextParts()
        btn.timeHour:SetText(h)
        btn.timeMinute:SetText(m)
        btn.qfxTimeString = ("%s:%s"):format(h, m)
    end

    local CLOCK_REFRESH_INTERVAL = 30

    RefreshQFXClockWidgets = function()
        local t = BuildClockSignature()
        local changed = previousClockSignature ~= t
        previousClockSignature = t
        for _, btn in ipairs(qfxClockButtons) do
            if btn:IsVisible() then
                if changed or btn.qfxTimeString ~= t then
                    UpdateTimeButton(btn)
                end
                StartTimeColonPulse(btn)
            end
        end
    end

    StartQFXClockTicker = function()
        if not C_Timer or not C_Timer.NewTicker then return end
        if qfxClockTicker then return end
        qfxClockTicker = C_Timer.NewTicker(CLOCK_REFRESH_INTERVAL, RefreshQFXClockWidgets)
    end

    StopQFXClockTicker = function()
        if qfxClockTicker then
            qfxClockTicker:Cancel()
            qfxClockTicker = nil
        end
        StopAllClockColonPulses()
    end

    RefreshPulseTickerState = function()
        if not IsMicroMenuEnabledNow() then
            if StopQFXClockTicker then StopQFXClockTicker() end
            return
        end
        if #qfxClockButtons > 0 then
            if RefreshQFXClockWidgets then RefreshQFXClockWidgets() end
            if StartQFXClockTicker then StartQFXClockTicker() end
        elseif StopQFXClockTicker then
            StopQFXClockTicker()
        end
    end

    -- -------------------------------------------------------------------
    -- Frame and buttons
    -- -------------------------------------------------------------------
    local qfxMicroMenuFrame = nil

    local HOVER_SCALE = 1.2
    local dragOverlay = nil

    local pendingMicroMenuRefresh = false
    local combatDeferredMicroMenu = false

    local function IsCombatLocked()
        return InCombatLockdown and InCombatLockdown()
    end

    local function RoundPixel(value, fallback)
        value = tonumber(value) or fallback or 0
        if value >= 0 then
            return math.floor(value + 0.5)
        end
        return math.ceil(value - 0.5)
    end

    local function SaveCurrentPosition()
        if not qfxMicroMenuFrame or not QFXSystemBarDB then return end
        local left, right, top = qfxMicroMenuFrame:GetLeft(), qfxMicroMenuFrame:GetRight(), qfxMicroMenuFrame:GetTop()
        local uiW, uiH = UIParent:GetWidth(), UIParent:GetHeight()
        if left and right and top and uiW and uiH then
            QFXSystemBarDB.customMicroMenuPositionX = RoundPixel(((left + right) / 2) - (uiW / 2), 0)
            QFXSystemBarDB.customMicroMenuPositionY = RoundPixel(top - uiH, 0)
        end
    end

    local function EnsureDragOverlay()
        if dragOverlay then return dragOverlay end
        dragOverlay = CreateFrame("Frame", "QFXSystemBarDragOverlay", UIParent, "BackdropTemplate")
        dragOverlay:SetFrameStrata("DIALOG")
        -- The overlay is deliberately larger than the menu frame. Clamping it
        -- would leave an artificial gap at the top and bottom of the screen.
        -- The menu frame itself remains clamped, so it cannot be dragged away.
        dragOverlay:SetClampedToScreen(false)
        dragOverlay:EnableMouse(true)
        dragOverlay:RegisterForDrag("LeftButton")
        dragOverlay:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 12,
            insets = { left = 3, right = 3, top = 3, bottom = 3 },
        })
        dragOverlay:SetBackdropColor(0.05, 0.25, 0.45, 0.18)
        dragOverlay:SetBackdropBorderColor(0.25, 0.75, 1, 0.95)

        dragOverlay.text = dragOverlay:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        dragOverlay.text:SetPoint("BOTTOM", dragOverlay, "TOP", 0, 4)
        SetUIText(dragOverlay.text, "Drag to move QFXSystemBar")

        dragOverlay:SetScript("OnDragStart", function()
            if InCombatLockdown() then
                print("|cFF33FF99QFX|r - |cFFEE8800" .. T("Cannot move position in combat.") .. "|r")
                return
            end
            if qfxMicroMenuFrame then
                qfxMicroMenuFrame:SetMovable(true)
                qfxMicroMenuFrame:StartMoving()
            end
        end)
        dragOverlay:SetScript("OnDragStop", function()
            if qfxMicroMenuFrame then
                qfxMicroMenuFrame:StopMovingOrSizing()
                SaveCurrentPosition()
                if ns.OnMicroMenuPositionChanged then ns.OnMicroMenuPositionChanged() end
            end
        end)
        dragOverlay:Hide()
        return dragOverlay
    end

    local function UpdateUnlockOverlay()
        if not qfxMicroMenuFrame then return end
        local db = QFXSystemBarDB
        if not db or not db.customMicroMenuUnlocked or not db.isCustomMicroMenu then
            if dragOverlay then dragOverlay:Hide() end
            return
        end
        local overlay = EnsureDragOverlay()
        overlay:ClearAllPoints()
        overlay:SetPoint("CENTER", qfxMicroMenuFrame, "CENTER", 0, 0)
        overlay:SetSize(math.max(40, qfxMicroMenuFrame:GetWidth() + 18), math.max(30, qfxMicroMenuFrame:GetHeight() + 18))
        overlay:Show()
    end

    local function ApplyButtonVisuals(btn, def, iconSize, textSize, outlineStyle)
        btn:ClearAllPoints()

        if def.isText then
            ReleaseButtonIconTexture(btn)
            if not btn.clockGroup then
                btn.clockGroup = CreateFrame("Frame", nil, btn)
            end
            if not btn.timeHour then
                btn.timeHour = btn:CreateFontString(nil, "OVERLAY")
                btn.timeMinute = btn:CreateFontString(nil, "OVERLAY")
                btn.timeColonAnchor = CreateFrame("Frame", nil, btn)
                btn.timeColonTop = btn.timeColonAnchor:CreateTexture(nil, "OVERLAY")
                btn.timeColonBottom = btn.timeColonAnchor:CreateTexture(nil, "OVERLAY")
            end
            if btn.timeColon then btn.timeColon:Hide() end

            ApplyTimeFont(btn.timeHour, textSize, outlineStyle)
            ApplyTimeFont(btn.timeMinute, textSize, outlineStyle)

            local fixedTimePartWidth = GetFixedTimePartWidth(btn.timeHour)
            btn.timeHour:SetWidth(fixedTimePartWidth)
            btn.timeMinute:SetWidth(fixedTimePartWidth)
            btn.timeHour:SetJustifyH("RIGHT")
            btn.timeMinute:SetJustifyH("LEFT")
            if btn.timeHour.SetWordWrap then btn.timeHour:SetWordWrap(false) end
            if btn.timeMinute.SetWordWrap then btn.timeMinute:SetWordWrap(false) end

            btn.timeHour:SetTextColor(clockTintRGB.r, clockTintRGB.g, clockTintRGB.b)
            btn.timeMinute:SetTextColor(clockTintRGB.r, clockTintRGB.g, clockTintRGB.b)

            local dotSize = math.max(3, math.floor(textSize * 0.13 + 0.5))
            local dotOffset = math.max(4, math.floor(textSize * 0.18 + 0.5))
            local clockTextHeight = GetClockTextHeight(btn.timeHour, textSize)
            local clockHeight = math.max(iconSize or 0, clockTextHeight)
            local numberYOffset = GetClockNumberVerticalOffset()
            btn.timeColonAnchor:SetSize(dotSize + 2, clockHeight)
            btn.timeColonTop:SetTexture("Interface\\Buttons\\WHITE8x8")
            btn.timeColonBottom:SetTexture("Interface\\Buttons\\WHITE8x8")
            btn.timeColonTop:SetSize(dotSize, dotSize)
            btn.timeColonBottom:SetSize(dotSize, dotSize)
            btn.timeColonTop:SetColorTexture(clockTintRGB.r, clockTintRGB.g, clockTintRGB.b, 1)
            btn.timeColonBottom:SetColorTexture(clockTintRGB.r, clockTintRGB.g, clockTintRGB.b, 1)

            btn.timeHour:ClearAllPoints()
            btn.timeMinute:ClearAllPoints()
            btn.clockGroup:ClearAllPoints()
            btn.timeColonAnchor:ClearAllPoints()
            btn.timeColonTop:ClearAllPoints()
            btn.timeColonBottom:ClearAllPoints()
            btn.clockGroup:SetSize(1, clockHeight)
            btn.clockGroup:SetPoint("CENTER", btn, "CENTER", 0, 0)
            btn.timeColonAnchor:SetPoint("CENTER", btn.clockGroup, "CENTER", 0, 0)
            btn.timeColonTop:SetPoint("CENTER", btn.timeColonAnchor, "CENTER", 0, dotOffset)
            btn.timeColonBottom:SetPoint("CENTER", btn.timeColonAnchor, "CENTER", 0, -dotOffset)
            -- Treat the clock as one fixed-width layout item, just like an icon
            -- button. The outer button width is calculated only during a full
            -- rebuild/style refresh; regular time ticks only update the text.
            local colonGap = 4
            local clockWidth = (fixedTimePartWidth * 2) + btn.timeColonAnchor:GetWidth() + (colonGap * 2)
            btn.timeHour:SetHeight(clockTextHeight)
            btn.timeMinute:SetHeight(clockTextHeight)
            btn.timeHour:SetPoint("RIGHT", btn.timeColonAnchor, "LEFT", -colonGap, numberYOffset)
            btn.timeMinute:SetPoint("LEFT", btn.timeColonAnchor, "RIGHT", colonGap, numberYOffset)

            UpdateTimeButton(btn)
            StartTimeColonPulse(btn)

            btn.qfxClockWidth = math.max(1, math.ceil(clockWidth))
            btn:SetSize(btn.qfxClockWidth, math.max(clockHeight, clockHeight + math.abs(numberYOffset) * 2))

            btn.clockGroup:Show()
            btn.timeHour:Show()
            btn.timeColonAnchor:Show()
            btn.timeColonTop:Show()
            btn.timeColonBottom:Show()
            btn.timeMinute:Show()
            if btn.mmText then btn.mmText:Hide() end
            if btn.mmIcon then btn.mmIcon:Hide() end
        else
            if not btn.mmIcon then
                btn.mmIcon = btn:CreateTexture(nil, "OVERLAY")
            end
            btn.mmIcon:ClearAllPoints()
            ApplyButtonIconTexture(btn, def)
            btn.qfxIconSize = iconSize
            btn.mmIcon:SetSize(iconSize, iconSize)
            local numberYOffset = math.abs(GetClockNumberVerticalOffset())
            local rowHeight = math.max(iconSize, (tonumber(textSize) or iconSize) + numberYOffset * 2)
            btn:SetSize(iconSize, rowHeight)
            btn.mmIcon:SetPoint("CENTER", btn, "CENTER", 0, 0)
            local r, g, b = ResolveIconTint()
            local iconTexture = btn.mmIcon
            if r then
                iconTexture:SetVertexColor(r, g, b)
            else
                iconTexture:SetVertexColor(1, 1, 1)
            end
            btn.mmIcon:Show()
            if btn.mmText then btn.mmText:Hide() end
            StopTimeColonPulse(btn)
            if btn.clockGroup then btn.clockGroup:Hide() end
            if btn.timeHour then btn.timeHour:Hide() end
            if btn.timeColon then btn.timeColon:Hide() end
            if btn.timeColonAnchor then btn.timeColonAnchor:Hide() end
            if btn.timeMinute then btn.timeMinute:Hide() end
        end

        if btn.qfxVolumeText then
            btn.qfxVolumeText:Hide()
        end
        if def and def.badgeKey == "volume" then
            btn.qfxVolumeBadgeHover = nil
        end
        UpdateButtonBadge(btn, def)
    end

    local function CollectMenuButtonsForDisplay(db)
        local list = {}
        for _, def in ipairs(GetOrderedButtonDefs()) do
            if db and db[def.var] then
                list[#list + 1] = def
            end
        end
        return list
    end

    local function HideButtonForReuse(btn)
        if not btn then return end
        btn.qfxVolumeBadgeHover = nil
        if btn.qfxBadgeText then btn.qfxBadgeText:Hide() end
        if btn.qfxVolumeText then btn.qfxVolumeText:Hide() end
        StopBadgeHeartbeat(btn)
        StopTimeColonPulse(btn)
        ReleaseButtonIconTexture(btn)
        btn:Hide()
        btn:ClearAllPoints()
    end

    local function HideAllConstructedButtons()
        for _, btn in pairs(qfxButtonPool) do
            HideButtonForReuse(btn)
        end
    end

    local function MicroButtonOnEnter(self)
        local def = self.qfxDefinition
        if def and def.isText then
            ShowOldStyleClockTooltip(self)
        else
            ShowOldStyleButtonTooltip(self, def)
        end
        if def and def.id == "Volume" then
            ShowVolumeButtonText(self)
        end
        if self.mmIcon and not (def and def.isText) then
            local size = self.qfxIconSize or (QFXSystemBarDB and QFXSystemBarDB.customMicroMenuIconSize) or 30
            self.mmIcon:SetSize(size * HOVER_SCALE, size * HOVER_SCALE)
        end
    end

    local function MicroButtonOnLeave(self)
        local def = self.qfxDefinition
        HideQFXTooltip()
        if def and def.id == "Volume" then
            HideVolumeButtonText(self)
        end
        if self.mmIcon then
            local size = self.qfxIconSize or (QFXSystemBarDB and QFXSystemBarDB.customMicroMenuIconSize) or 30
            self.mmIcon:SetSize(size, size)
        end
    end

    local function CreateOrGetMenuButton(def)
        local name = "QFXSystemBarButton_" .. def.id
        local btn = qfxButtonPool[def.id] or _G[name]
        if btn then return btn end

        local template = def.isSecure and "SecureActionButtonTemplate,SecureHandlerStateTemplate" or nil
        btn = CreateFrame("Button", name, qfxMicroMenuFrame, template)
        btn:RegisterForClicks("LeftButtonUp", "RightButtonUp", "MiddleButtonUp")
        btn:SetScript("OnEnter", MicroButtonOnEnter)
        btn:SetScript("OnLeave", MicroButtonOnLeave)
        return btn
    end

    local function SetSecureClickAttribute(button, attributeName, attributeValue)
        if button then
            button:SetAttribute(attributeName, attributeValue)
        end
    end

    local function AssignButtonAction(btn, def)
        btn.qfxDefinition = def

        -- Important: secure buttons must keep the click handler installed by
        -- SecureActionButtonTemplate. Native micro-menu buttons are opened by
        -- pre-bound secure click forwarding, so they can still be clicked in
        -- combat without running a Lua fallback. Non-secure buttons keep normal
        -- Lua OnClick handlers.
        if not def.isSecure then
            btn:SetScript("OnClick", def.onClick)
            return
        end

        SetSecureClickAttribute(btn, "useOnKeyDown", false)

        if def.secureAction == "hearthstone" then
            ConfigureHearthstoneButton(btn)
            return
        end

        if def.secureAction == "nativeClick" then
            local targetButton = ResolveNativeMicroButton(def)
            SetSecureClickAttribute(btn, "type1", targetButton and "click" or nil)
            SetSecureClickAttribute(btn, "clickbutton1", targetButton)
            btn:EnableMouse(targetButton and true or false)
        end
    end

    local function BuildVisibleButtons(definitions, iconSize, textSize, outlineStyle)
        local placed = {}
        StopAllClockColonPulses()
        wipe(qfxClockButtons)
        previousClockSignature = false

        for _, def in ipairs(definitions) do
            local btn = CreateOrGetMenuButton(def)
            AssignButtonAction(btn, def)
            ApplyButtonVisuals(btn, def, iconSize, textSize, outlineStyle)
            qfxButtonPool[def.id] = btn
            placed[#placed + 1] = btn
            if def.isText then qfxClockButtons[#qfxClockButtons + 1] = btn end
        end

        return placed
    end

    local function MeasureButtonRow(buttons, spacing)
        local width, height = 0, 0
        for index, btn in ipairs(buttons) do
            width = width + (btn:GetWidth() or 0)
            if index < #buttons then width = width + spacing end
            height = math.max(height, btn:GetHeight() or 0)
        end
        return width, height
    end

    local function BuildClockCenteredOrder(buttons)
        -- Keep the clock as the center item of the custom micro menu.
        -- Icon buttons are split automatically around it:
        -- 6 icons = 3 / clock / 3, 7 icons = 3 / clock / 4, 8 icons = 4 / clock / 4.
        -- If the clock is disabled, the original button order is preserved.
        local clockButton
        local icons = {}
        for _, btn in ipairs(buttons or {}) do
            local def = btn and btn.qfxDefinition
            if def and def.isText and not clockButton then
                clockButton = btn
            elseif btn then
                icons[#icons + 1] = btn
            end
        end

        if not clockButton then
            return buttons
        end

        local arranged = {}
        local leftCount = math.floor(#icons / 2)
        for index = 1, leftCount do
            arranged[#arranged + 1] = icons[index]
        end
        arranged[#arranged + 1] = clockButton
        for index = leftCount + 1, #icons do
            arranged[#arranged + 1] = icons[index]
        end
        return arranged
    end

    local function LayoutButtonRow(buttons, spacing)
        local offset = 0
        for buttonIndex = 1, #buttons do
            local btn = buttons[buttonIndex]
            btn:ClearAllPoints()
            btn:SetPoint("LEFT", qfxMicroMenuFrame, "LEFT", offset, 0)
            btn:Show()
            offset = offset + (btn:GetWidth() or 0) + spacing
        end
    end

    local function RebuildQFXMicroMenu()
        if not qfxMicroMenuFrame then return end

        local db = QFXSystemBarDB
        local menuEnabled = db and db.isCustomMicroMenu
        if not menuEnabled then
            StopQFXClockTicker()
            ReleaseAllMicroMenuIconTextures()
            qfxMicroMenuFrame:Hide()
            if dragOverlay then dragOverlay:Hide() end
            return
        end

        local visibleDefs = CollectMenuButtonsForDisplay(db)
        if #visibleDefs == 0 then
            StopQFXClockTicker()
            ReleaseAllMicroMenuIconTextures()
            qfxMicroMenuFrame:Hide()
            if dragOverlay then dragOverlay:Hide() end
            return
        end

        local iconSize = math.max(1, tonumber(db.customMicroMenuIconSize) or 30)
        local textSize = math.max(1, tonumber(db.customMicroMenuFontSize) or 22)
        local spacing = math.max(0, tonumber(db.customMicroMenuButtonSpacing) or 0)
        local outlineStyle = db.isCustomMicroMenuTimeAdj and tostring(db.customMicroMenuTimeOutline or "") or ""

        RefreshClockTintCache()
        HideAllConstructedButtons()

        local rowButtons = BuildClockCenteredOrder(BuildVisibleButtons(visibleDefs, iconSize, textSize, outlineStyle))
        local rowWidth, rowHeight = MeasureButtonRow(rowButtons, spacing)

        LayoutButtonRow(rowButtons, spacing)
        qfxMicroMenuFrame:SetSize(rowWidth, rowHeight)
        qfxMicroMenuFrame:Show()

        UpdateUnlockOverlay()
        UpdateAllBadges(true)
        if RefreshPulseTickerState then RefreshPulseTickerState() end
    end

    local function PlaceQFXMicroMenu()
        if not qfxMicroMenuFrame then return end
        local db = QFXSystemBarDB
        local x = RoundPixel(db and db.customMicroMenuPositionX, 0)
        local y = RoundPixel(db and db.customMicroMenuPositionY, 0)
        if db then
            db.customMicroMenuPositionX = x
            db.customMicroMenuPositionY = y
        end
        if InCombatLockdown() then return end
        qfxMicroMenuFrame:ClearAllPoints()
        qfxMicroMenuFrame:SetPoint("TOP", UIParent, "TOP", x, y)
        UpdateUnlockOverlay()
    end

    local function CreateQFXMicroMenuHost()
        local db = QFXSystemBarDB
        if not (db and db.isCustomMicroMenu) then
            return
        end
        if IsCombatLocked() then
            pendingMicroMenuRefresh = true
            combatDeferredMicroMenu = true
            return
        end

        if not qfxMicroMenuFrame then
            qfxMicroMenuFrame = CreateFrame("Frame", "QFXSystemBarFrame", UIParent, "SecureFrameTemplate")
            qfxMicroMenuFrame:SetFrameStrata("MEDIUM")
            qfxMicroMenuFrame:SetSize(1, 1)
            qfxMicroMenuFrame:SetMovable(true)
            qfxMicroMenuFrame:SetClampedToScreen(true)
        end

        PlaceQFXMicroMenu()
        RebuildQFXMicroMenu()
        if ns.TopCenterWidget and ns.TopCenterWidget.OnMenuFrameReady then
            ns.TopCenterWidget:OnMenuFrameReady()
        end
    end

    local function ApplyMicroMenuRefresh()
        if IsCombatLocked() then
            pendingMicroMenuRefresh = true
            combatDeferredMicroMenu = true
            return
        end

        pendingMicroMenuRefresh = false
        combatDeferredMicroMenu = false

        local db = QFXSystemBarDB
        if not (db and db.isCustomMicroMenu) then
            StopQFXClockTicker()
            ReleaseAllMicroMenuIconTextures()
            if qfxMicroMenuFrame then qfxMicroMenuFrame:Hide() end
            if dragOverlay then dragOverlay:Hide() end
            return
        end

        if not qfxMicroMenuFrame then
            CreateQFXMicroMenuHost()
        else
            PlaceQFXMicroMenu()
            RebuildQFXMicroMenu()
        end

        if type(ns.RequestApplyAllStates) == "function" then
            ns.RequestApplyAllStates()
        end
    end

    local function RequestMicroMenuRefresh()
        if pendingMicroMenuRefresh then return end
        pendingMicroMenuRefresh = true
        if C_Timer and C_Timer.After then
            C_Timer.After(0, ApplyMicroMenuRefresh)
        else
            ApplyMicroMenuRefresh()
        end
    end

    local function FlushMicroMenuRefresh()
        if pendingMicroMenuRefresh or combatDeferredMicroMenu then
            ApplyMicroMenuRefresh()
        end
    end

    -- Expose the queued refresh helpers to the fade/state block below.
    -- They are local to this micro-menu block, so later startup handlers must
    -- call them through ns instead of passing an out-of-scope local to C_Timer.After.
    ns.RequestMicroMenuRefresh = RequestMicroMenuRefresh
    ns.FlushMicroMenuRefresh = FlushMicroMenuRefresh

    -- -------------------------------------------------------------------
    -- Public API
    -- -------------------------------------------------------------------
    function ns.RefreshMicroMenuLocalization()
        HideQFXTooltip()
        if dragOverlay and dragOverlay.text then
            SetUIText(dragOverlay.text, "Drag to move QFXSystemBar")
        end
    end

    ns["OnMicroMenuToggle"] = function(value)
        RequestMicroMenuRefresh()
        if ns.UpdateMicroMenuEventRegistration then ns.UpdateMicroMenuEventRegistration() end
    end

    ns["OnMicroMenuChanged"] = function()
        RequestMicroMenuRefresh()
        if ns.UpdateMicroMenuEventRegistration then ns.UpdateMicroMenuEventRegistration() end
        if ShouldLoadMeetingStoneBridge() and ns.SyncMeetingStoneFloatingPanel then ns.SyncMeetingStoneFloatingPanel() end
    end

    function ns.OnHearthstoneSettingsChanged()
        RequestMicroMenuRefresh()
    end

    function ns.RefreshHearthstoneButtonMacros()
        if IsCombatLocked() then
            pendingMicroMenuRefresh = true
            combatDeferredMicroMenu = true
            return
        end
        local btn = qfxButtonPool and qfxButtonPool.Hearthstone
        if btn then ConfigureHearthstoneButton(btn) end
    end

    _G[ns.HEARTHSTONE_RANDOM_REFRESH_GLOBAL or "QFXSystemBar_RandomHearthstoneRefresh"] = function()
        if ns.RefreshHearthstoneButtonMacros then ns.RefreshHearthstoneButtonMacros() end
    end

    ns["OnMicroMenuPositionChanged"] = function()
        if IsCombatLocked() then
            pendingMicroMenuRefresh = true
            combatDeferredMicroMenu = true
            return
        end
        PlaceQFXMicroMenu()
    end

    function ns.SetMicroMenuUnlocked(value)
        QFXSystemBarDB = QFXSystemBarDB or {}
        QFXSystemBarDB.customMicroMenuUnlocked = value and true or false
        if not qfxMicroMenuFrame and QFXSystemBarDB.isCustomMicroMenu then CreateQFXMicroMenuHost() end
        UpdateUnlockOverlay()
    end

    function ns.NudgeMicroMenu(dx, dy)
        QFXSystemBarDB = QFXSystemBarDB or {}
        if InCombatLockdown() then
            print("|cFF33FF99QFX|r - |cFFEE8800" .. T("Cannot move position in combat.") .. "|r")
            return
        end
        QFXSystemBarDB.customMicroMenuPositionX = RoundPixel((QFXSystemBarDB.customMicroMenuPositionX or 0) + (dx or 0), 0)
        QFXSystemBarDB.customMicroMenuPositionY = RoundPixel((QFXSystemBarDB.customMicroMenuPositionY or 0) + (dy or 0), 0)
        if not qfxMicroMenuFrame and QFXSystemBarDB.isCustomMicroMenu then CreateQFXMicroMenuHost() end
        PlaceQFXMicroMenu()
    end

    function ns.ResetMicroMenuPosition()
        QFXSystemBarDB = QFXSystemBarDB or {}
        QFXSystemBarDB.customMicroMenuPositionX = 0
        QFXSystemBarDB.customMicroMenuPositionY = 0
        QFXSystemBarDB.customMicroMenuUnlocked = false
        if not qfxMicroMenuFrame and QFXSystemBarDB.isCustomMicroMenu then CreateQFXMicroMenuHost() end
        PlaceQFXMicroMenu()
        UpdateUnlockOverlay()
    end

    -- -------------------------------------------------------------------
    -- Event initialization
    -- -------------------------------------------------------------------
    local qfxLoginWatcher = CreateFrame("Frame")
    local microMenuRegisteredEvents = {}

    local function SetMicroMenuEvent(event, active)
        active = active and true or false
        if active and not microMenuRegisteredEvents[event] then
            qfxLoginWatcher:RegisterEvent(event)
            microMenuRegisteredEvents[event] = true
        elseif (not active) and microMenuRegisteredEvents[event] then
            qfxLoginWatcher:UnregisterEvent(event)
            microMenuRegisteredEvents[event] = nil
        end
    end

    local function IsMenuButtonEnabled(var)
        return QFXSystemBarDB and QFXSystemBarDB[var] == true
    end

    local function UpdateMicroMenuEventRegistration()
        local active = IsMicroMenuEnabledNow()
        local wantsBags = active and IsBadgeEnabled("bags") and IsMenuButtonEnabled("isCustomMicroMenuBags")
        local wantsDurability = active and IsBadgeEnabled("durability") and IsMenuButtonEnabled("isCustomMicroMenuCharacter")
        local wantsFriends = active and IsBadgeEnabled("friends") and IsMenuButtonEnabled("isCustomMicroMenuSocial")
        local wantsGuild = active and IsBadgeEnabled("guild") and IsMenuButtonEnabled("isCustomMicroMenuGuild")
        SetMicroMenuEvent("BAG_UPDATE_DELAYED", wantsBags)
        SetMicroMenuEvent("UPDATE_INVENTORY_DURABILITY", wantsDurability)
        SetMicroMenuEvent("PLAYER_EQUIPMENT_CHANGED", wantsDurability)
        SetMicroMenuEvent("MERCHANT_CLOSED", wantsDurability)
        SetMicroMenuEvent("FRIENDLIST_UPDATE", wantsFriends)
        SetMicroMenuEvent("BN_FRIEND_ACCOUNT_ONLINE", wantsFriends)
        SetMicroMenuEvent("BN_FRIEND_ACCOUNT_OFFLINE", wantsFriends)
        SetMicroMenuEvent("BN_FRIEND_INFO_CHANGED", wantsFriends)
        SetMicroMenuEvent("GUILD_ROSTER_UPDATE", wantsGuild)
        SetMicroMenuEvent("PLAYER_GUILD_UPDATE", wantsGuild)
        SetMicroMenuEvent("TOYS_UPDATED", active and IsMenuButtonEnabled("isCustomMicroMenuHearthstone"))
        SetMicroMenuEvent("GET_ITEM_INFO_RECEIVED", active and IsMenuButtonEnabled("isCustomMicroMenuHearthstone"))
        SetMicroMenuEvent("CVAR_UPDATE", active and IsBadgeEnabled("volume") and IsMenuButtonEnabled("isCustomMicroMenuVolume"))
    end
    ns.UpdateMicroMenuEventRegistration = UpdateMicroMenuEventRegistration

    qfxLoginWatcher:RegisterEvent("PLAYER_ENTERING_WORLD")
    qfxLoginWatcher:RegisterEvent("ADDON_LOADED")
    qfxLoginWatcher:RegisterEvent("PLAYER_REGEN_ENABLED")
    qfxLoginWatcher:SetScript("OnEvent", function(_, event, isInitialLogin, isReloadingUI)
        if event == "ADDON_LOADED" then
            local loadedAddon = isInitialLogin
            if (loadedAddon == "MeetingStone" or loadedAddon == "MeetingStoneEX" or loadedAddon == "GroupFinder" or loadedAddon == "PremadeGroupBoard") and ShouldLoadMeetingStoneBridge() and ns.QueueMeetingStoneFloatingSync then
                ns.QueueMeetingStoneFloatingSync()
            end
            return
        end

        if event == "PLAYER_ENTERING_WORLD" then
            UpdateMicroMenuEventRegistration()

            -- Keep InfoBar gold totals across /reload, but start a fresh
            -- session after a real character login.
            if isInitialLogin or isReloadingUI then
                QFXSystemBarDB = QFXSystemBarDB or {}
                local currentMoney = (type(GetMoney) == "function" and tonumber(GetMoney())) or 0
                local session = QFXSystemBarDB.infoBarMoneySession
                if type(session) ~= "table" then
                    session = {}
                    QFXSystemBarDB.infoBarMoneySession = session
                end
                if isInitialLogin then
                    session.earned = 0
                    session.spent = 0
                    session.startMoney = currentMoney
                else
                    session.earned = tonumber(session.earned) or 0
                    session.spent = tonumber(session.spent) or 0
                    session.startMoney = tonumber(session.startMoney) or currentMoney
                end
                session.initialized = true
                session.lastMoney = currentMoney
                if ns.InfoBarMoneySession ~= session then ns.InfoBarMoneySession = session end
            end

            if ShouldLoadMeetingStoneBridge() then LoadMeetingStoneBridge() end
        end

        if not IsMicroMenuEnabledNow() then
            return
        end

        if event == "PLAYER_REGEN_ENABLED" then
            FlushMicroMenuRefresh()
            return
        end

        if event == "BAG_UPDATE_DELAYED" then
            RequestBadgeUpdate("bags", 0.1)
            if ns.RefreshConfigControls then ns.RefreshConfigControls() end
            return
        elseif event == "TOYS_UPDATED" or event == "GET_ITEM_INFO_RECEIVED" then
            if ns.RefreshConfigControls then ns.RefreshConfigControls() end
            return
        elseif event == "UPDATE_INVENTORY_DURABILITY" or event == "PLAYER_EQUIPMENT_CHANGED" or event == "MERCHANT_CLOSED" then
            -- Text-only refresh. Do not rebuild the micro menu or refresh icon textures.
            RequestBadgeUpdate("durability", 0.2)
            return
        elseif event == "FRIENDLIST_UPDATE" or event == "BN_FRIEND_ACCOUNT_ONLINE" or event == "BN_FRIEND_ACCOUNT_OFFLINE" or event == "BN_FRIEND_INFO_CHANGED" then
            RequestBadgeUpdate("friends", 0.5)
            return
        elseif event == "GUILD_ROSTER_UPDATE" or event == "PLAYER_GUILD_UPDATE" then
            RequestBadgeUpdate("guild", 0.5)
            return
        elseif event == "CVAR_UPDATE" then
            local cvarName = isInitialLogin
            if cvarName == "Sound_MasterVolume" or cvarName == "Sound_EnableAllSound" then
                RequestBadgeUpdate("volume", 0)
            end
            return
        end

        if isInitialLogin or isReloadingUI then
            if C_FriendList and C_FriendList.ShowFriends then pcall(C_FriendList.ShowFriends) end
            if IsInGuild and IsInGuild() and C_GuildInfo and C_GuildInfo.GuildRoster then pcall(C_GuildInfo.GuildRoster) end
            UpdateMicroMenuEventRegistration()
            C_Timer.After(1, RequestMicroMenuRefresh)
            C_Timer.After(1.2, function() RequestBadgeUpdate("all", 0) end)
            C_Timer.After(1.4, function() if ShouldLoadMeetingStoneBridge() and ns.QueueMeetingStoneFloatingSync then ns.QueueMeetingStoneFloatingSync() end end)
        end
    end)

    UpdateMicroMenuEventRegistration()

    ns.QFXMicroMenuDefinitions = qfxMenuDefinitions
    ns["MicroMenuButtonDefs"] = qfxMenuDefinitions
end

-- ========================================================================
-- Frame fade system
-- ========================================================================
do
    local MODE_SHOW = 0
    local MODE_HIDE = 1
    local QFX_VIS_MOUSEOVER = 2
    local QFX_VIS_MOUSEOVER_KEEP_COMBAT = 3
    local QFX_VIS_MOUSEOVER_ICONS_ONLY = 4

    -- -------------------------------------------------------------------
    -- Core: lightweight alpha tween driver
    -- -------------------------------------------------------------------
    local fadeJobs = {}
    local fadeDriver = CreateFrame("Frame")
    local fadeDriverActive = false

    local function HasFadeJobs()
        return next(fadeJobs) ~= nil
    end

    local function StopAnim(key)
        fadeJobs[key] = nil
        if not HasFadeJobs() then
            fadeDriver:SetScript("OnUpdate", nil)
            fadeDriverActive = false
        end
    end

    local function DriveFadeJobs()
        local now = (GetTime and GetTime()) or 0
        for key, job in pairs(fadeJobs) do
            local progress = math.min((now - job.startedAt) / job.duration, 1)
            job.owner:SetAlpha(job.fromAlpha + ((job.toAlpha - job.fromAlpha) * progress))
            if progress >= 1 then fadeJobs[key] = nil end
        end
        if not HasFadeJobs() then
            fadeDriver:SetScript("OnUpdate", nil)
            fadeDriverActive = false
        end
    end

    local function StartFadeDriver()
        if fadeDriverActive then return end
        fadeDriverActive = true
        fadeDriver:SetScript("OnUpdate", DriveFadeJobs)
    end

    local function RunAlphaTransition(key, frame, targetAlpha, duration)
        if frame == nil then return end
        local startAlpha = frame:GetAlpha()
        if math.abs(startAlpha - targetAlpha) < 0.001 then
            StopAnim(key)
            frame:SetAlpha(targetAlpha)
            return
        end

        duration = tonumber(duration) or 0
        if duration <= 0 then
            StopAnim(key)
            frame:SetAlpha(targetAlpha)
            return
        end

        fadeJobs[key] = {
            owner = frame,
            fromAlpha = startAlpha,
            toAlpha = targetAlpha,
            startedAt = (GetTime and GetTime()) or 0,
            duration = duration,
        }
        StartFadeDriver()
    end

    local function GetFadeIn() return QFXSystemBarDB.uiFadeInDuration or 0.2 end
    local function GetFadeOut() return QFXSystemBarDB.uiFadeOutDuration or 0.2 end
    local function InCombat() return UnitAffectingCombat("player") end

    local mouseoverVisibilityEnabled = true
    local isHideLocked = {}
    local fadeHookRecords = {}

    local function IsOrdinaryFadeMode(mode)
        return mode == QFX_VIS_MOUSEOVER or mode == QFX_VIS_MOUSEOVER_KEEP_COMBAT
    end

    local function AnyPartHovered(frame, buttons)
        if frame and frame:IsMouseOver() then return true end
        for _, button in ipairs(buttons or {}) do
            if button and button:IsMouseOver() then return true end
        end
        return false
    end

    local function GetFadeRecord(key, frame)
        fadeHookRecords[key] = fadeHookRecords[key] or setmetatable({}, { __mode = "k" })
        local record = fadeHookRecords[key][frame]
        if record then return record end
        record = { buttons = {}, buttonHooks = setmetatable({}, { __mode = "k" }) }
        fadeHookRecords[key][frame] = record
        return record
    end

    local function AttachMouseoverReveal(key, frame, buttons, forceShowCheck, dynamicButtons)
        if frame == nil then return end
        local record = GetFadeRecord(key, frame)
        record.buttons = buttons or {}
        record.forceShowCheck = forceShowCheck

        if not record.frameHooked then
            record.frameHooked = true

            record.fadeIn = function()
                if not QFXSystemBarDB then return end
                if not IsOrdinaryFadeMode(QFXSystemBarDB[key]) or not mouseoverVisibilityEnabled then return end
                RunAlphaTransition(key, frame, 1, GetFadeIn())
            end

            record.fadeOut = function()
                if not QFXSystemBarDB then return end
                if not IsOrdinaryFadeMode(QFXSystemBarDB[key]) or not mouseoverVisibilityEnabled then return end
                C_Timer.After(.05, function()
                    if AnyPartHovered(frame, record.buttons) then return end
                    if QFXSystemBarDB[key] == QFX_VIS_MOUSEOVER_KEEP_COMBAT and InCombat() then return end
                    if record.forceShowCheck and record.forceShowCheck() then return end
                    RunAlphaTransition(key, frame, 0, GetFadeOut())
                end)
            end

            frame:HookScript("OnEnter", record.fadeIn)
            frame:HookScript("OnLeave", record.fadeOut)
        end

        for _, button in ipairs(record.buttons) do
            if button and not record.buttonHooks[button] then
                record.buttonHooks[button] = true
                button:HookScript("OnEnter", record.fadeIn)
                button:HookScript("OnLeave", record.fadeOut)
            end
        end
    end

    local function ApplyMouseoverPolicy(key, frame, buttons, mode, forceShowCheck, dynamicButtons)
        local targets = buttons or {}
        AttachMouseoverReveal(key, frame, targets, forceShowCheck, dynamicButtons)

        if mode == QFX_VIS_MOUSEOVER_KEEP_COMBAT and InCombat() then
            StopAnim(key)
            frame:SetAlpha(1.0)
            return
        end

        if not mouseoverVisibilityEnabled then
            RunAlphaTransition(key, frame, 1, GetFadeIn())
            return
        end

        local targetAlpha = AnyPartHovered(frame, targets) and 1 or 0
        RunAlphaTransition(key, frame, targetAlpha, targetAlpha == 1 and GetFadeIn() or GetFadeOut())
    end

    local exceptTimeRecords = {}

    local function FadeExceptTimeButtons(data, targetAlpha)
        local duration = (targetAlpha == 1) and GetFadeIn() or GetFadeOut()
        for _, button in ipairs(data.fadeButtons or {}) do
            if button then
                local name = button.GetName and button:GetName() or tostring(button)
                RunAlphaTransition(data.key .. "_btn_" .. name, button, targetAlpha, duration)
            end
        end
    end

    local function ApplyIconMouseoverWithPinnedClock(key, frame, nonTimeBtns, timePins)
        if frame == nil then return end

        local record = exceptTimeRecords[key]
        if not record then
            record = {
                key = key,
                fadeButtons = {},
                hoverTargets = {},
                buttonHooks = setmetatable({}, { __mode = "k" }),
                leaveSerial = 0,
            }
            exceptTimeRecords[key] = record
        end
        record.frame = frame
        record.fadeButtons = nonTimeBtns or {}
        record.hoverTargets = {}

        local seen = {}
        local function AddHoverTarget(button)
            if button and not seen[button] then
                seen[button] = true
                record.hoverTargets[#record.hoverTargets + 1] = button
            end
        end

        for _, button in ipairs(record.fadeButtons) do
            AddHoverTarget(button)
        end

        for _, pin in ipairs(timePins or {}) do
            if pin:GetParent() ~= frame then
                pin:SetParent(frame)
            end
            pin:SetAlpha(1)
            AddHoverTarget(pin)
        end

        if not record.frameHooked then
            record.frameHooked = true

            record.fadeIn = function()
                record.leaveSerial = (record.leaveSerial or 0) + 1

                if not QFXSystemBarDB then return end
                if QFXSystemBarDB[key] ~= QFX_VIS_MOUSEOVER_ICONS_ONLY then return end
                if not mouseoverVisibilityEnabled then return end

                FadeExceptTimeButtons(record, 1)
            end

            record.fadeOut = function()
                if not QFXSystemBarDB then return end
                if QFXSystemBarDB[key] ~= QFX_VIS_MOUSEOVER_ICONS_ONLY then return end
                if not mouseoverVisibilityEnabled then return end

                record.leaveSerial = (record.leaveSerial or 0) + 1
                local leaveSerial = record.leaveSerial

                C_Timer.After(.05, function()
                    if leaveSerial ~= record.leaveSerial then return end
                    if not QFXSystemBarDB then return end
                    if QFXSystemBarDB[key] ~= QFX_VIS_MOUSEOVER_ICONS_ONLY then return end
                    if not mouseoverVisibilityEnabled then return end
                    if AnyPartHovered(frame, record.hoverTargets) then return end

                    FadeExceptTimeButtons(record, 0)
                end)
            end

            frame:HookScript("OnEnter", record.fadeIn)
            frame:HookScript("OnLeave", record.fadeOut)
        end

        for _, button in ipairs(record.hoverTargets) do
            if button and not record.buttonHooks[button] then
                record.buttonHooks[button] = true
                button:HookScript("OnEnter", record.fadeIn)
                button:HookScript("OnLeave", record.fadeOut)
            end
        end

        if not mouseoverVisibilityEnabled then
            FadeExceptTimeButtons(record, 1)
        else
            FadeExceptTimeButtons(record, AnyPartHovered(frame, record.hoverTargets) and 1 or 0)
        end
    end

    -- -------------------------------------------------------------------
    -- Visibility controllers: native micro menu, bag bar, and QFX menu
    -- -------------------------------------------------------------------
    local NATIVE_MICRO_KEY = "nativeMicroMenu"
    local BAG_BAR_KEY = "bagBar"
    local QFX_MENU_KEY = "customMicroMenu"

    local NATIVE_MICRO_BUTTON_NAMES = {
        "CharacterMicroButton",
        "ProfessionMicroButton",
        "PlayerSpellsMicroButton",
        "AchievementMicroButton",
        "QuestLogMicroButton",
        "HousingMicroButton",
        "GuildMicroButton",
        "LFDMicroButton",
        "CollectionsMicroButton",
        "EJMicroButton",
        "StoreMicroButton",
        "MainMenuMicroButton",
    }

    local BAG_BUTTON_NAMES = {
        "MainMenuBarBackpackButton",
        "BagBarExpandToggle",
        "CharacterReagentBag0Slot",
        "CharacterBag0Slot",
        "CharacterBag1Slot",
        "CharacterBag2Slot",
        "CharacterBag3Slot",
    }

    local function CollectNamedFrames(names)
        local frames = {}
        for index = 1, #names do
            local frame = _G[names[index]]
            if frame then frames[#frames + 1] = frame end
        end
        return frames
    end

    local function CollectNativeMicroButtons()
        return CollectNamedFrames(NATIVE_MICRO_BUTTON_NAMES)
    end

    local function CollectBagSlotButtons()
        return CollectNamedFrames(BAG_BUTTON_NAMES)
    end

    local function SetFramesShown(frames, shown, lockOnShow)
        for _, frame in ipairs(frames or {}) do
            if frame then
                frame:SetScript("OnShow", lockOnShow and frame.Hide or nil)
                if shown then frame:Show() else frame:Hide() end
            end
        end
    end

    local microAlertHooksInstalled = false

    local function ShouldHideNativeMicroAlerts()
        return QFXSystemBarDB and QFXSystemBarDB[NATIVE_MICRO_KEY] == MODE_HIDE
    end

    local function HideNativeMicroAlert(button)
        if not button or not ShouldHideNativeMicroAlerts() then return end

        if MainMenuMicroButton_HideAlert then pcall(MainMenuMicroButton_HideAlert, button) end
        if MicroButtonPulseStop then pcall(MicroButtonPulseStop, button) end

        local alert = button.Alert
        if not alert and button.GetName then
            local name = button:GetName()
            alert = name and _G[name .. "Alert"]
        end
        if alert and alert.Hide then pcall(alert.Hide, alert) end
        if HelpTip and HelpTip.HideAll then pcall(HelpTip.HideAll, HelpTip, button) end
    end

    local function HideAllNativeMicroAlerts()
        if not ShouldHideNativeMicroAlerts() then return end
        for _, button in ipairs(CollectNativeMicroButtons()) do
            HideNativeMicroAlert(button)
        end
    end

    local function InstallNativeMicroAlertHooks()
        if microAlertHooksInstalled then return end
        microAlertHooksInstalled = true

        if MainMenuMicroButton_ShowAlert then
            hooksecurefunc("MainMenuMicroButton_ShowAlert", function(button)
                HideNativeMicroAlert(button)
            end)
        end
        if MicroButtonPulse then
            hooksecurefunc("MicroButtonPulse", function(button)
                HideNativeMicroAlert(button)
            end)
        end
    end

    local function QueueNativeAlertCleanup()
        if not ShouldHideNativeMicroAlerts() then return end
        InstallNativeMicroAlertHooks()
        HideAllNativeMicroAlerts()
        C_Timer.After(0.1, HideAllNativeMicroAlerts)
        C_Timer.After(1.0, HideAllNativeMicroAlerts)
    end

    local nativeFadeHooksReady = false

    local function NativeMicroIsHovered()
        if MicroMenu and MicroMenu:IsMouseOver() then return true end
        if MicroMenuContainer and MicroMenuContainer:IsMouseOver() then return true end
        for _, button in ipairs(CollectNativeMicroButtons()) do
            if button:IsMouseOver() then return true end
        end
        return false
    end

    local function NativeMicroCanFade()
        return QFXSystemBarDB and QFXSystemBarDB[NATIVE_MICRO_KEY] == QFX_VIS_MOUSEOVER and mouseoverVisibilityEnabled
    end

    local function FadeNativeMicroTo(alpha)
        local root = MicroMenu
        if not root then return end
        RunAlphaTransition(NATIVE_MICRO_KEY, root, alpha, alpha == 1 and GetFadeIn() or GetFadeOut())
    end

    local function ArmNativeMicroFadeHooks()
        if nativeFadeHooksReady then return end
        nativeFadeHooksReady = true

        local function FadeIn()
            if NativeMicroCanFade() then FadeNativeMicroTo(1) end
        end

        local function FadeOutSoon()
            if not NativeMicroCanFade() then return end
            C_Timer.After(.05, function()
                if NativeMicroCanFade() and not NativeMicroIsHovered() then
                    FadeNativeMicroTo(0)
                end
            end)
        end

        local hookTargets = CollectNativeMicroButtons()
        hookTargets[#hookTargets + 1] = MicroMenu
        hookTargets[#hookTargets + 1] = MicroMenuContainer
        for _, target in ipairs(hookTargets) do
            if target and target.HookScript then
                target:HookScript("OnEnter", FadeIn)
                target:HookScript("OnLeave", FadeOutSoon)
            end
        end
    end

    local function RestoreNativeMicroMenu(root)
        if not isHideLocked[NATIVE_MICRO_KEY] then return end
        isHideLocked[NATIVE_MICRO_KEY] = nil
        SetFramesShown(CollectNativeMicroButtons(), true, false)
        if root then root:Show() end
    end

    local function HideNativeMicroMenu(root)
        isHideLocked[NATIVE_MICRO_KEY] = true
        StopAnim(NATIVE_MICRO_KEY)
        SetFramesShown(CollectNativeMicroButtons(), false, true)
        if root then root:Hide() end
        QueueNativeAlertCleanup()
    end

    local function ApplyNativeMicroMenu(mode)
        local root = MicroMenu
        if not root then return end

        if mode ~= MODE_HIDE then RestoreNativeMicroMenu(root) end

        if mode == MODE_SHOW then
            StopAnim(NATIVE_MICRO_KEY)
            root:SetAlpha(1)
        elseif mode == MODE_HIDE then
            HideNativeMicroMenu(root)
        else
            ArmNativeMicroFadeHooks()
            if mouseoverVisibilityEnabled then
                FadeNativeMicroTo(NativeMicroIsHovered() and 1 or 0)
            else
                FadeNativeMicroTo(1)
            end
        end
    end

    local function RestoreBagBar(root)
        if not isHideLocked[BAG_BAR_KEY] then return end
        isHideLocked[BAG_BAR_KEY] = nil
        if root then
            root:SetScript("OnShow", nil)
            root:Show()
        end
        SetFramesShown(CollectBagSlotButtons(), true, false)
    end

    local function HideBagBar(root)
        isHideLocked[BAG_BAR_KEY] = true
        StopAnim(BAG_BAR_KEY)
        if root then
            root:SetScript("OnShow", root.Hide)
            root:Hide()
        end
        SetFramesShown(CollectBagSlotButtons(), false, true)
    end

    local function ApplyBagContainerPolicy(mode)
        local root = BagsBar
        if not root then return end

        if mode ~= MODE_HIDE then RestoreBagBar(root) end

        if mode == MODE_SHOW then
            StopAnim(BAG_BAR_KEY)
            root:SetAlpha(1)
        elseif mode == MODE_HIDE then
            HideBagBar(root)
        else
            ApplyMouseoverPolicy(BAG_BAR_KEY, root, CollectBagSlotButtons(), mode)
        end
    end

    local function CollectQFXMenuButtons(includeClock)
        local result = {}
        local db = QFXSystemBarDB
        if not db then return result end

        for _, def in ipairs(ns.QFXMicroMenuDefinitions or ns["MicroMenuButtonDefs"] or {}) do
            if db[def.var] and ((includeClock and def.isText) or ((not includeClock) and not def.isText)) then
                local btn = _G[("QFXSystemBarButton_%s"):format(def.id)]
                if btn then result[#result + 1] = btn end
            end
        end
        return result
    end

    local function StopQFXIconFadeJobs(iconButtons)
        for _, button in ipairs(iconButtons or {}) do
            if button then
                local name = button.GetName and button:GetName() or tostring(button)
                StopAnim(QFX_MENU_KEY .. "_btn_" .. name)
            end
        end
    end

    local function SetQFXMenuShown(frame, iconButtons, alpha)
        StopAnim(QFX_MENU_KEY)
        StopQFXIconFadeJobs(iconButtons)
        frame:SetAlpha(alpha)
        for _, button in ipairs(iconButtons or {}) do
            if button then
                button:SetAlpha(alpha)
            end
        end
    end

    local function EnsureClockPinsAttached(frame, clockButtons)
        for _, pin in ipairs(clockButtons or {}) do
            if pin:GetParent() ~= frame then
                pin:SetParent(frame)
            end
            pin:SetAlpha(1)
        end
    end

    local function ApplyQFXCustomMenu(mode)
        local frame = _G.QFXSystemBarFrame
        if frame == nil then return end

        local iconButtons = CollectQFXMenuButtons(false)
        local clockButtons = CollectQFXMenuButtons(true)

        if mode == MODE_SHOW then
            EnsureClockPinsAttached(frame, clockButtons)
            SetQFXMenuShown(frame, iconButtons, 1)
        elseif mode == MODE_HIDE then
            EnsureClockPinsAttached(frame, clockButtons)
            SetQFXMenuShown(frame, iconButtons, 0)
        elseif mode == QFX_VIS_MOUSEOVER_ICONS_ONLY then
            StopAnim(QFX_MENU_KEY)
            frame:SetAlpha(1.0)
            EnsureClockPinsAttached(frame, clockButtons)
            ApplyIconMouseoverWithPinnedClock(QFX_MENU_KEY, frame, iconButtons, clockButtons)
        else
            StopQFXIconFadeJobs(iconButtons)
            EnsureClockPinsAttached(frame, clockButtons)
            for _, button in ipairs(iconButtons) do if button then button:SetAlpha(1) end end
            ApplyMouseoverPolicy(QFX_MENU_KEY, frame, iconButtons, mode, nil, true)
        end
    end

    local STATE_APPLIERS = {
        nativeMicroMenu = ApplyNativeMicroMenu,
        bagBar = ApplyBagContainerPolicy,
        customMicroMenu = ApplyQFXCustomMenu,
    }
    local STATE_ORDER = { NATIVE_MICRO_KEY, BAG_BAR_KEY, QFX_MENU_KEY }

    local function ApplyStateKey(key)
        if not QFXSystemBarDB then return end
        local apply = STATE_APPLIERS[key]
        if apply then apply(QFXSystemBarDB[key] or MODE_SHOW) end
    end

    -- -------------------------------------------------------------------
    -- Event handling and initialization
    -- -------------------------------------------------------------------
    local pendingApplyAllStates = false
    local applyAllQueued = false

    local function ApplyAllStates()
        pendingApplyAllStates = false
        for _, key in ipairs(STATE_ORDER) do
            ApplyStateKey(key)
        end
    end

    local function RequestApplyAllStates()
        if InCombatLockdown and InCombatLockdown() then
            pendingApplyAllStates = true
            return
        end
        if applyAllQueued then return end
        applyAllQueued = true
        C_Timer.After(0, function()
            applyAllQueued = false
            ApplyAllStates()
        end)
    end

    ns.RequestApplyAllStates = RequestApplyAllStates

    local function ApplyCombatEnterStates()
        if not QFXSystemBarDB then return end
        if QFXSystemBarDB[QFX_MENU_KEY] == QFX_VIS_MOUSEOVER_KEEP_COMBAT then
            local frame = _G.QFXSystemBarFrame
            if frame then
                StopAnim(QFX_MENU_KEY)
                frame:SetAlpha(1.0)
            end
        end
    end

    local qfxCombatWatcher = CreateFrame("Frame")
    qfxCombatWatcher:RegisterEvent("PLAYER_REGEN_DISABLED")
    qfxCombatWatcher:RegisterEvent("PLAYER_REGEN_ENABLED")
    qfxCombatWatcher:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_REGEN_DISABLED" then
            ApplyCombatEnterStates()
            return
        end
        if event == "PLAYER_REGEN_ENABLED" and pendingApplyAllStates then
            ApplyAllStates()
        else
            RequestApplyAllStates()
        end
    end)

    ns["OnUIFrameModeChanged"] = function(key, value)
        if not QFXSystemBarDB then return end
        RequestApplyAllStates()
    end

    ns["OnUIFadeTimerChanged"] = function() end

    local function Initialize()
        local savedMouseoverState = QFXSystemBarDB and QFXSystemBarDB["globalFadeEnabled"]
        if savedMouseoverState ~= nil then
            mouseoverVisibilityEnabled = savedMouseoverState and true or false
        end
        if C_Timer and C_Timer.After then
            C_Timer.After(1.0, RequestApplyAllStates)
            C_Timer.After(2.0, RequestApplyAllStates)
            C_Timer.After(4.0, RequestApplyAllStates)
        else
            RequestApplyAllStates()
        end
    end

    EventUtil.ContinueOnAddOnLoaded(addonName, Initialize)

    local qfxWorldWatcher = CreateFrame("Frame")
    qfxWorldWatcher:RegisterEvent("PLAYER_ENTERING_WORLD")
    qfxWorldWatcher:RegisterEvent("PLAYER_REGEN_ENABLED")
    qfxWorldWatcher:SetScript("OnEvent", function(_, event, isInitialLogin, isReloadingUI)
        if event == "PLAYER_REGEN_ENABLED" then
            if type(ns.FlushMicroMenuRefresh) == "function" then
                ns.FlushMicroMenuRefresh()
            end
            RequestApplyAllStates()
            return
        end

        if isInitialLogin or isReloadingUI then
            C_Timer.After(1.0, function()
                if QFXSystemBarDB and QFXSystemBarDB.isCustomMicroMenu == true and type(ns.RequestMicroMenuRefresh) == "function" then
                    ns.RequestMicroMenuRefresh()
                end
            end)
        else
            C_Timer.After(0.5, function()
                if QFXSystemBarDB and QFXSystemBarDB.isCustomMicroMenu == true and type(ns.RequestMicroMenuRefresh) == "function" then
                    ns.RequestMicroMenuRefresh()
                end
                RequestApplyAllStates()
            end)
        end
    end)
end
