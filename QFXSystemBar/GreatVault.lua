local addonName, ns = ...

-- Read the same per-slot progress and season thresholds as Blizzard's vault UI.
-- No reward UI addon is loaded merely to inspect progress.
function ns.GetGreatVaultProgressRows()
    local api = C_WeeklyRewards
    local types = Enum and Enum.WeeklyRewardChestThresholdType
    if not api or not api.GetActivities or not types then return nil end
    local activities = api.GetActivities()
    if type(activities) ~= "table" then return nil end
    local categories = {
        { id = types.Raid, labelKey = "Raids" },
        { id = types.Activities, labelKey = "Dungeons" },
        { id = types.World, labelKey = "World Activities" },
        { id = types.RankedPvP, labelKey = "Ranked PvP" },
    }
    local rows = {}
    for _, category in ipairs(categories) do
        local row = { labelKey = category.labelKey, progress = 0, threshold = 0, unlocked = 0, total = 0 }
        local slots = {}
        for _, activity in ipairs(activities) do
            if category.id and activity.type == category.id then
                local threshold = tonumber(activity.threshold) or 0
                local progress = math.max(0, tonumber(activity.progress) or 0)
                local index = tonumber(activity.index)
                if threshold > 0 and index then
                    row.progress = math.max(row.progress, progress)
                    row.threshold = math.max(row.threshold, threshold)
                    slots[index] = progress >= threshold
                end
            end
        end
        for _, unlocked in pairs(slots) do
            row.total = row.total + 1
            if unlocked then row.unlocked = row.unlocked + 1 end
        end
        if row.total > 0 then
            row.progress = math.min(row.progress, row.threshold)
            rows[#rows + 1] = row
        end
    end
    return rows
end

function ns.GetGreatVaultTooltipLines()
    local translate = ns.T or function(key) return key end
    local lines = { translate("Great Vault"), translate("Great Vault Progress") }
    local rows = ns.GetGreatVaultProgressRows()
    local unlocked, total = 0, 0
    if not rows then
        lines[#lines + 1] = translate("The Great Vault is unavailable.")
    elseif #rows == 0 then
        lines[#lines + 1] = translate("Loading Great Vault progress...")
    else
        for _, row in ipairs(rows) do
            local color = row.progress >= row.threshold and "|cff55ff55" or (row.progress > 0 and "|cffffcc66" or "|cffaaaaaa")
            lines[#lines + 1] = string.format("%s: %s%d/%d|r", translate(row.labelKey), color, row.progress, row.threshold)
            unlocked, total = unlocked + row.unlocked, total + row.total
        end
        lines[#lines + 1] = string.format("%s: %d/%d", translate("Reward Slots"), unlocked, total)
    end
    if C_WeeklyRewards and C_WeeklyRewards.HasAvailableRewards and C_WeeklyRewards.HasAvailableRewards() then
        lines[#lines + 1] = "|cff55ff55" .. translate("Rewards available to claim.") .. "|r"
    end
    return lines
end

local eventFrame, tooltipOwner, refreshTooltip, hideTooltip

function ns.StopGreatVaultTooltip(owner)
    if owner and owner ~= tooltipOwner then return end
    local hide = hideTooltip
    tooltipOwner, refreshTooltip, hideTooltip = nil, nil, nil
    if eventFrame then eventFrame:UnregisterAllEvents() end
    if hide then hide() end
end

function ns.TrackGreatVaultTooltip(owner, refresh, hide)
    ns.StopGreatVaultTooltip()
    tooltipOwner, refreshTooltip, hideTooltip = owner, refresh, hide
    if not eventFrame then
        eventFrame = CreateFrame("Frame")
        eventFrame:SetScript("OnEvent", function()
            if not tooltipOwner or not tooltipOwner:IsShown() or not tooltipOwner:IsMouseOver() then
                ns.StopGreatVaultTooltip()
                return
            end
            if refreshTooltip then refreshTooltip() end
        end)
    end
    eventFrame:RegisterEvent("WEEKLY_REWARDS_UPDATE")
    eventFrame:RegisterEvent("CHALLENGE_MODE_COMPLETED")
    if not owner.qfxVaultTooltipHideHooked then
        owner.qfxVaultTooltipHideHooked = true
        owner:HookScript("OnHide", function(self) ns.StopGreatVaultTooltip(self) end)
    end
end

-- Both launchers use the same native tooltip, placement and live refresh.
-- Keep this in the core so the menu does not need the info-bar module loaded.
function ns.ShowGreatVaultTooltip(owner)
    if not owner then return end
    local function refresh()
        local y
        if owner.GetCenter then
            local _, centerY = owner:GetCenter()
            y = centerY
        end
        local screenHeight = (UIParent and UIParent.GetHeight and UIParent:GetHeight()) or GetScreenHeight() or 768
        GameTooltip:SetOwner(owner, "ANCHOR_NONE")
        GameTooltip:ClearAllPoints()
        if not y or y <= screenHeight / 2 then
            GameTooltip:SetPoint("BOTTOM", owner, "TOP", 0, 8)
        else
            GameTooltip:SetPoint("TOP", owner, "BOTTOM", 0, -8)
        end
        GameTooltip:ClearLines()
        for index, line in ipairs(ns.GetGreatVaultTooltipLines()) do
            GameTooltip:AddLine(line, index == 1 and 0 or .9, index == 1 and .6 or .9, 1)
        end
        GameTooltip:AddLine(" ")
        local translate = ns.T or function(key) return key end
        GameTooltip:AddLine(translate("Left Click: Toggle Great Vault"), .6, .8, 1)
        GameTooltip:Show()
    end
    ns.TrackGreatVaultTooltip(owner, refresh, function()
        if GameTooltip:IsOwned(owner) then GameTooltip:Hide() end
    end)
    refresh()
end
