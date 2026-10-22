local addonName, ns = ...
ns = _G.QFXSystemBarNS or ns
if not ns then return end

-- ========================================================================
-- QFXSystemBar InfoBar - Extra module
-- ------------------------------------------------------------------------
-- Loaded after InfoBar.lua by QFXSystemBar_InfoBar.toc.
--
--   1. Upgrade crests (Midnight, five currencies): icon + amount cell and a
--      tooltip with the weekly progress. Item definitions and the weighted
--      layout hooks live in InfoBar.lua; this file owns the data, the
--      rendering and the tooltip.
--   2. Account gold: per-character gold snapshots recorded at login and on
--      money changes, shown in the gold tooltip together with the warband
--      bank reading and the session profit/loss.
-- ========================================================================

local function LT(key)
    if key == nil then return "" end
    if type(key) ~= "string" then return tostring(key) end
    if ns.T then return ns.T(key) end
    if ns.UIText then return ns.UIText(key) end
    return key
end

local function LF(key, ...)
    local text = LT(key)
    local ok, value = pcall(string.format, text, ...)
    if ok then return value end
    return text
end

local function FormatLargeNumber(value)
    local text = tostring(math.floor(tonumber(value) or 0))
    if BreakUpLargeNumbers then
        local ok, formatted = pcall(BreakUpLargeNumbers, text)
        if ok and formatted then return formatted end
    end
    return text
end

local GOLD_AMOUNT_SYMBOL = _G.GOLD_AMOUNT_SYMBOL or "g"

local function FormatGoldOnly(gold)
    return FormatLargeNumber(gold) .. " |cffffd700" .. GOLD_AMOUNT_SYMBOL .. "|r"
end

local LINE_STRING = "------------------------------"

-- ========================================================================
-- 1. Upgrade crests
-- ========================================================================

-- currencyID: C_CurrencyInfo id of the Midnight crest currencies (Adventurer
-- .. Myth). The display name changes with the season (Dawncrest/Mistcrest),
-- so the tooltip title reads the live API name and only falls back to the
-- localized item label. fallbackIcon is used only when the API fails; the
-- normal path uses GetCurrencyInfo().iconFileID.
ns.InfoBarCrestData = {
    crest_adventurer = { currencyID = 3442, fallbackIcon = 7734054 },
    crest_veteran    = { currencyID = 3443, fallbackIcon = 7734062 },
    crest_champion   = { currencyID = 3444, fallbackIcon = 7734056 },
    crest_hero       = { currencyID = 3445, fallbackIcon = 7734058 },
    crest_mythic     = { currencyID = 3446, fallbackIcon = 7734060 },
}

local CREST_ICON_SIZE = 18
local CREST_NUMBER_GAP = 2
local CREST_TEXTURE_TRIM = 4 / 64

local crestDisplayNameCache = {}

local function GetCurrencyInfo(currencyID)
    if not (C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo) then return nil end
    local ok, info = pcall(C_CurrencyInfo.GetCurrencyInfo, currencyID)
    if ok and type(info) == "table" then return info end
    return nil
end

function ns.GetInfoBarCrestDisplayName(id)
    local data = ns.InfoBarCrestData[id]
    if not data then return nil end
    -- The API name is stable for the whole session (it only changes when the
    -- season changes and the client restarts), so it is cached. The localized
    -- label fallback is not cached because the interface language can change.
    local cached = crestDisplayNameCache[id]
    if cached then return cached end
    local info = GetCurrencyInfo(data.currencyID)
    if info and type(info.name) == "string" and info.name ~= "" then
        crestDisplayNameCache[id] = info.name
        return info.name
    end
    local item = ns.InfoBarItems and ns.InfoBarItems[id]
    if item and item.labelKey then return LT(item.labelKey) end
    return nil
end

-- Called from CreateTextModule for every button so crest items get their own
-- number FontString next to the icon.
function ns.OnInfoBarTextModuleCreated(btn, id)
    if not (btn and id and ns.InfoBarCrestData[id]) then return end
    if btn.crestNumber then return end
    local fontPath, fontFlag = nil, nil
    if ns.GetInfoBarTextFont then fontPath, fontFlag = ns.GetInfoBarTextFont() end
    fontPath = fontPath or STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
    local fontSize = (ns.GetInfoBarFontSize and ns.GetInfoBarFontSize()) or 12
    btn.crestNumber = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    btn.crestNumber:SetFont(fontPath, fontSize, fontFlag or "")
    btn.crestNumber:SetJustifyH("LEFT")
    if btn.crestNumber.SetJustifyV then btn.crestNumber:SetJustifyV("MIDDLE") end
    if btn.crestNumber.SetWordWrap then btn.crestNumber:SetWordWrap(false) end
    if btn.crestNumber.SetMaxLines then btn.crestNumber:SetMaxLines(1) end
    btn.crestNumber:SetTextColor(1, 1, 1, 1)
end

-- Crest renderer hooked into UpdateInfoBarIconTextures: draws the currency
-- icon plus the amount, centered as one unit inside the cell.
function ns.UpdateInfoBarCrestDisplay(btn, id)
    local data = ns.InfoBarCrestData[id]
    if not data or not btn then return false end

    local info = GetCurrencyInfo(data.currencyID)
    local icon = (info and info.iconFileID) or data.fallbackIcon

    btn.qfxInfoBarIconTextures = btn.qfxInfoBarIconTextures or {}
    local texture = btn.qfxInfoBarIconTextures[1]
    if not texture then
        texture = btn:CreateTexture(nil, "OVERLAY")
        btn.qfxInfoBarIconTextures[1] = texture
    end
    for index = 2, #btn.qfxInfoBarIconTextures do
        btn.qfxInfoBarIconTextures[index]:Hide()
    end

    if not btn.crestNumber and ns.OnInfoBarTextModuleCreated then
        ns.OnInfoBarTextModuleCreated(btn, id)
    end
    local number = btn.crestNumber
    local quantityText = FormatLargeNumber((info and info.quantity) or 0)
    if number then
        local fontPath, fontFlag = nil, nil
        if ns.GetInfoBarTextFont then fontPath, fontFlag = ns.GetInfoBarTextFont() end
        fontPath = fontPath or STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
        local fontSize = (ns.GetInfoBarFontSize and ns.GetInfoBarFontSize()) or 12
        if btn.qfxCrestFontPath ~= fontPath or btn.qfxCrestFontSize ~= fontSize or btn.qfxCrestFontFlag ~= fontFlag then
            number:SetFont(fontPath, fontSize, fontFlag or "")
            btn.qfxCrestFontPath = fontPath
            btn.qfxCrestFontSize = fontSize
            btn.qfxCrestFontFlag = fontFlag
        end
        if btn.qfxCrestValue ~= quantityText then
            number:SetText(quantityText)
            btn.qfxCrestValue = quantityText
        end
        number:SetTextColor(1, 1, 1, 1)
        number:Show()
    end

    -- Size the icon and the number first, then center the pair in the cell.
    local numberWidth = number and number:GetStringWidth() or 0
    local contentWidth = CREST_ICON_SIZE + (number and (CREST_NUMBER_GAP + numberWidth) or 0)
    local startX = -contentWidth / 2

    texture:ClearAllPoints()
    texture:SetSize(CREST_ICON_SIZE, CREST_ICON_SIZE)
    texture:SetPoint("LEFT", btn, "CENTER", startX, 0)
    texture:SetTexture(icon)
    texture:SetTexCoord(CREST_TEXTURE_TRIM, 1 - CREST_TEXTURE_TRIM, CREST_TEXTURE_TRIM, 1 - CREST_TEXTURE_TRIM)
    texture:Show()

    if number then
        number:ClearAllPoints()
        number:SetPoint("LEFT", btn, "CENTER", startX + CREST_ICON_SIZE + CREST_NUMBER_GAP, 0)
    end

    btn.text:Hide()
    return true
end

function ns.ShowInfoBarCrestTooltip(owner, id)
    local data = ns.InfoBarCrestData[id]
    if not data then return end

    if ns.SetInfoBarTooltipOwner then
        ns.SetInfoBarTooltipOwner(owner)
    elseif owner then
        GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    end
    GameTooltip:ClearLines()

    local info = GetCurrencyInfo(data.currencyID)
    local title = ns.GetInfoBarCrestDisplayName and ns.GetInfoBarCrestDisplayName(id) or id
    GameTooltip:AddLine(title, 0, .6, 1)
    GameTooltip:AddLine(" ")

    local quantity = (info and tonumber(info.quantity)) or 0
    local maximum = (info and tonumber(info.maxQuantity)) or 0
    local quantityText = FormatLargeNumber(quantity)
    if maximum > 0 then quantityText = quantityText .. " / " .. FormatLargeNumber(maximum) end
    GameTooltip:AddDoubleLine(LT("Current"), quantityText, .6, .8, 1, 1, 1, 1)

    -- Weekly progress: earned this week against the weekly cap. totalEarned
    -- is the season total and is deliberately not paired with the weekly cap.
    if info and info.canEarnPerWeek and (tonumber(info.maxWeeklyQuantity) or 0) > 0 then
        local earned = tonumber(info.quantityEarnedThisWeek) or 0
        GameTooltip:AddDoubleLine(LT("This Week"), string.format("%s / %s", FormatLargeNumber(earned), FormatLargeNumber(info.maxWeeklyQuantity)), .6, .8, 1, 1, 1, 1)
    end

    if ns.InfoBarLeftButtonMarkup then
        GameTooltip:AddLine(" ")
        GameTooltip:AddDoubleLine(" ", ns.InfoBarLeftButtonMarkup() .. (CURRENCY or LT("Currency")) .. " ", 1, 1, 1, .6, .8, 1)
    end
    GameTooltip:Show()
end

-- Crest clicks open the currency tab of the character pane.
function ns.HandleInfoBarExtraClick(id, button)
    if not (id and ns.InfoBarCrestData[id]) then return false end
    if button == "LeftButton" then
        if InCombatLockdown and InCombatLockdown() then return true end
        if ToggleCharacter then
            pcall(ToggleCharacter, "TokenFrame")
        elseif TokenFrame and ToggleFrame then
            pcall(ToggleFrame, TokenFrame)
        end
    end
    return true
end

-- ========================================================================
-- 2. Account gold
-- ========================================================================

local GOLD_RECORD_FIELD = "accountGold"
local CLEAR_CONFIRM_SECONDS = 5
local MAX_OTHER_CHARACTERS = 8

local function GoldRecords()
    local db = rawget(_G, "QFXSystemBarDB")
    if type(db) ~= "table" then return nil end
    if type(db[GOLD_RECORD_FIELD]) ~= "table" then db[GOLD_RECORD_FIELD] = {} end
    return db[GOLD_RECORD_FIELD]
end

local function GetCharacterKey()
    local realm = (type(GetRealmName) == "function" and GetRealmName()) or "Unknown"
    local name = (type(UnitName) == "function" and UnitName("player")) or "Unknown"
    return tostring(realm) .. "-" .. tostring(name)
end

-- Snapshots are written to SavedVariables; every character only updates its
-- own entry, so the list stays available across characters and reloads.
function ns.RecordAccountGoldCharacter()
    local records = GoldRecords()
    if not records or type(GetMoney) ~= "function" then return end
    local gold = math.floor((tonumber(GetMoney()) or 0) / 10000)
    local key = GetCharacterKey()
    local record = records[key]
    if record and tonumber(record.gold) == gold then return end
    records[key] = {
        gold = gold,
        updated = (type(time) == "function" and time()) or 0,
    }
end

function ns.GetAccountGoldSummary()
    local records = GoldRecords() or {}
    local currentKey = GetCharacterKey()
    local summary = { others = {}, count = 0, allTotal = 0, otherTotal = 0 }
    for key, record in pairs(records) do
        local gold = tonumber(record and record.gold) or 0
        summary.count = summary.count + 1
        summary.allTotal = summary.allTotal + gold
        if key ~= currentKey then
            local realm, name = tostring(key):match("^(.-)%-(.+)$")
            summary.others[#summary.others + 1] = {
                key = key,
                realm = realm or "",
                name = name or tostring(key),
                gold = gold,
            }
            summary.otherTotal = summary.otherTotal + gold
        end
    end
    table.sort(summary.others, function(a, b)
        if a.gold ~= b.gold then return a.gold > b.gold end
        if a.realm ~= b.realm then return a.realm < b.realm end
        return a.name < b.name
    end)
    return summary
end

-- Warband bank gold is a cached client value: it refreshes after the bank
-- has been visited. Returns nil when the API is unavailable.
local function GetWarbandBankGold()
    if not (C_Bank and C_Bank.FetchDepositedMoney and Enum and Enum.BankType and Enum.BankType.Account) then
        return nil
    end
    local ok, money = pcall(C_Bank.FetchDepositedMoney, Enum.BankType.Account)
    if ok and type(money) == "number" then return math.floor(money / 10000) end
    return nil
end

function ns.ShowInfoBarGoldTooltip(owner)
    local data = ns.UpdateInfoBarMoneySession and ns.UpdateInfoBarMoneySession() or nil
    local earned = data and tonumber(data.earned) or 0
    local spent = data and tonumber(data.spent) or 0
    local net = earned - spent

    if ns.SetInfoBarTooltipOwner then
        ns.SetInfoBarTooltipOwner(owner)
    elseif owner then
        GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    end
    GameTooltip:ClearLines()
    GameTooltip:AddLine(_G.MONEY or LT("Money"), 0, .6, 1)
    GameTooltip:AddLine(" ")

    local FormatMoney = ns.FormatInfoBarMoney
    local moneyText = FormatMoney and FormatMoney((type(GetMoney) == "function" and GetMoney()) or 0, true) or FormatGoldOnly(0)
    local playerName = (type(UnitName) == "function" and UnitName("player")) or LT("Character")
    GameTooltip:AddDoubleLine(playerName, moneyText, .85, .85, .85, 1, 1, 1)

    local summary = ns.GetAccountGoldSummary()
    local currentRealm = (type(GetRealmName) == "function" and GetRealmName()) or ""
    local expanded = IsShiftKeyDown and IsShiftKeyDown()
    local maxShown = expanded and math.huge or MAX_OTHER_CHARACTERS
    if #summary.others > 0 then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(LT("Other Characters"), .6, .6, .6)
        for index, character in ipairs(summary.others) do
            if index <= maxShown then
                local display = character.name
                if character.realm ~= currentRealm and character.realm ~= "" then
                    display = character.name .. "-" .. character.realm
                end
                GameTooltip:AddDoubleLine(display, FormatGoldOnly(character.gold), .85, .85, .85, 1, 1, 1)
            end
        end
        if not expanded and #summary.others > MAX_OTHER_CHARACTERS then
            GameTooltip:AddDoubleLine(" ", LF("%d more characters", #summary.others - MAX_OTHER_CHARACTERS), .6, .8, 1, .6, .8, 1)
        end
    end

    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(LINE_STRING)
    GameTooltip:AddDoubleLine(LT("Total Character Gold"), FormatGoldOnly(summary.allTotal), .3, .8, 1, 1, 1, 1)
    local warbandGold = GetWarbandBankGold()
    if warbandGold ~= nil then
        GameTooltip:AddDoubleLine(LT("Warband Bank"), FormatGoldOnly(warbandGold), .3, .8, 1, 1, 1, 1)
        GameTooltip:AddDoubleLine(LT("Total (Including Bank)"), FormatGoldOnly(summary.allTotal + warbandGold), .3, 1, .3, 1, 1, 1)
    else
        GameTooltip:AddDoubleLine(LT("Warband Bank"), "|cff888888--|r", .3, .8, 1, 1, 1, 1)
    end

    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(LINE_STRING)
    local signed = ns.FormatInfoBarSignedMoney
    GameTooltip:AddDoubleLine(LT("Session Earned"), signed and signed(earned) or FormatGoldOnly(0), .35, 1, .35, 1, 1, 1)
    GameTooltip:AddDoubleLine(LT("Session Spent"), signed and signed(-spent) or FormatGoldOnly(0), 1, .35, .35, 1, 1, 1)
    GameTooltip:AddDoubleLine(LT("Session Net"), signed and signed(net) or FormatGoldOnly(0), .6, .8, 1, 1, 1, 1)

    if ns.InfoBarLeftButtonMarkup then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(LINE_STRING)
        GameTooltip:AddDoubleLine(" ", ns.InfoBarLeftButtonMarkup() .. (CURRENCY or LT("Currency")) .. "  " .. (ns.InfoBarRightButtonMarkup and ns.InfoBarRightButtonMarkup() or "") .. (BAGSLOTTEXT or BAGS or LT("Bags")), 1, 1, 1, .6, .8, 1)
        GameTooltip:AddDoubleLine(" ", "|cffaaaaaa" .. LT("Ctrl+Left Click to clear the account gold records.") .. "|r", 1, 1, 1, .6, .6, .6)
    end
    GameTooltip:Show()
end

-- Ctrl+Left Click clears every recorded character after a second confirming
-- click inside five seconds; the current character is re-recorded right away
-- so the list is never left empty.
local clearArmedUntil = 0

function ns.HandleInfoBarGoldCtrlClick(owner)
    local now = (type(GetTime) == "function" and GetTime()) or 0
    if clearArmedUntil > 0 and now > 0 and now <= clearArmedUntil then
        clearArmedUntil = 0
        local records = GoldRecords()
        if records then
            for key in pairs(records) do records[key] = nil end
        end
        ns.RecordAccountGoldCharacter()
        print("|cff66C6FFQFXSystemBar:|r " .. LT("Account gold records cleared."))
        if owner and ns.ShowInfoBarGoldTooltip then ns.ShowInfoBarGoldTooltip(owner) end
    else
        clearArmedUntil = now + CLEAR_CONFIRM_SECONDS
        print("|cff66C6FFQFXSystemBar:|r " .. LT("Press Ctrl+Left Click again within 5 seconds to clear account gold records."))
    end
end
