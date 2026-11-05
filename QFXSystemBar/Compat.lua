local addonName, ns = ...

-- Forever shares Mainline UI code, but has its own game type and feature set.
local isForever = WOW_PROJECT_CAMELOT ~= nil and WOW_PROJECT_ID == WOW_PROJECT_CAMELOT
if not isForever and GetBuildInfo then
    local version = GetBuildInfo()
    isForever = type(version) == "string" and version:match("^1%.60%.") ~= nil
end

local Compat = { IsForever = isForever }
ns.Compat = Compat

function Compat.GetSpecialization(...)
    local api = C_SpecializationInfo and C_SpecializationInfo.GetSpecialization or GetSpecialization
    if api then return api(...) end
end

function Compat.GetSpecializationInfo(...)
    local api = C_SpecializationInfo and C_SpecializationInfo.GetSpecializationInfo or GetSpecializationInfo
    if api then return api(...) end
end

function Compat.GetNumSpecializations()
    if GetNumSpecializations then return GetNumSpecializations() end
    if C_SpecializationInfo and C_SpecializationInfo.GetNumSpecializationsForClassID and UnitClass then
        local _, _, classID = UnitClass("player")
        if classID then return C_SpecializationInfo.GetNumSpecializationsForClassID(classID) end
    end
    return 0
end

function Compat.GetTalentButtonName()
    return isForever and "TalentMicroButton" or "PlayerSpellsMicroButton"
end

function Compat.GetMenuLabelKey(id, fallback)
    if isForever and id == "PlayerSpells" then return "Talents" end
    if id == "SpellBook" then return "Spellbook" end
    if id == "Legacy" then return "Legacy" end
    return fallback
end

-- These features belong to the Retail ruleset. Their C APIs also ship in
-- Forever, so namespace existence alone is not a usable capability check.
function Compat.HasRetailProgression()
    return not isForever
end

local nativeButtons = {
    Character = "CharacterMicroButton", Social = "QuickJoinToastButton",
    Profession = "ProfessionMicroButton", PlayerSpells = Compat.GetTalentButtonName(),
    SpellBook = "SpellbookMicroButton", Legacy = "LegacyMicroButton",
    Achievement = "AchievementMicroButton", QuestLog = "QuestLogMicroButton",
    Housing = "HousingMicroButton", Guild = "GuildMicroButton", LFD = "LFDMicroButton",
    Collections = "CollectionsMicroButton", EJ = "EJMicroButton", Store = "StoreMicroButton",
}
local disabledRules = {
    Character = "CharacterPanelDisabled", Profession = "ProfessionsPanelDisabled",
    QuestLog = "QuestLogMicrobuttonDisabled", Housing = "HousingDashboardDisabled",
    Guild = "CommunitiesPanelDisabled", LFD = "FinderPanelDisabled",
    Collections = "CollectionsPanelDisabled", Store = "StoreDisabled",
}

function ns.IsMicroMenuButtonAvailable(id)
    if not isForever then return id ~= "SpellBook" and id ~= "Legacy" end
    if id == "GreatVault" or id == "MDT" then return false end
    local name = nativeButtons[id]
    if name and not _G[name] then return false end
    local ruleName = disabledRules[id]
    local rule = ruleName and Enum and Enum.GameRule and Enum.GameRule[ruleName]
    if rule and C_GameRules and C_GameRules.IsGameRuleActive and C_GameRules.IsGameRuleActive(rule) then
        return false
    end
    if id == "EJ" and GameRulesUtil and GameRulesUtil.EJIsDisabled then
        return not GameRulesUtil.EJIsDisabled()
    end
    return true
end

function ns.IsInfoBarItemAvailable(id)
    if not isForever then return true end
    if id == "greatvault" or id == "mdt" or id == "mplus" or (type(id) == "string" and id:match("^crest_")) then
        return false
    end
    return true
end

function Compat.GetRandomMountLabelKey()
    return isForever and "Random Mount" or "Random Favorite Mount"
end

function Compat.ResolveRandomMount()
    if not isForever then return 0 end
    if not C_MountJournal or not C_MountJournal.GetMountIDs or not C_MountJournal.GetMountInfoByID then return nil end
    local candidates = {}
    local faction = UnitFactionGroup and UnitFactionGroup("player")
    local factionID = faction == "Horde" and 0 or (faction == "Alliance" and 1 or nil)
    for _, mountID in ipairs(C_MountJournal.GetMountIDs() or {}) do
        local _, _, _, _, usable, _, _, factionSpecific, mountFaction, hidden, collected = C_MountJournal.GetMountInfoByID(mountID)
        if collected and usable and not hidden
            and (not factionSpecific or mountFaction == nil or factionID == nil or mountFaction == factionID) then
            candidates[#candidates + 1] = mountID
        end
    end
    if #candidates > 0 then return candidates[math.random(#candidates)] end
end

if isForever and GameRulesUtil and GameRulesUtil.RegisterSystemCallback then
    GameRulesUtil.RegisterSystemCallback(function()
        if ns.RequestMicroMenuRefresh then ns.RequestMicroMenuRefresh() end
        if ns.RefreshInfoBars then ns.RefreshInfoBars() end
    end)
end
