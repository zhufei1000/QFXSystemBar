local _, childNS = ...
local ns = _G.QFXSystemBarNS or childNS
if not ns then return end

-- Lychee owns the animation, application list and standalone position.
-- QFX supplies the hosted icon and restores the native artwork on release.
local owner = {}
local records = setmetatable({}, { __mode = "k" })
local api, unsubscribe, currentHost, currentRecord
local syncing, deferredFrame
local logoState
local REQUIRED_API_METHODS = { "IsAvailable", "GetStatus", "Subscribe", "Attach", "Refresh", "Detach", "ShowPopup", "HidePopup", "SetPopupBounds" }

local function IsVisible(frame)
    return frame and frame.IsVisible and frame:IsVisible()
end

local function WantsIntegration()
    if not ns.IsLycheeGroupActive or not ns.IsLycheeGroupActive() then return false end
    local db = QFXSystemBarDB or {}
    if db.isCustomMicroMenu and db.isCustomMicroMenuMeetingStone then return true end
    return ns.IsMeetingStoneInfoBarActive and ns.IsMeetingStoneInfoBarActive() or false
end

local function GetAPI()
    local addon = rawget(_G, "LycheeGroup")
    local candidate = addon and addon.API and addon.API.Floating
    if type(candidate) ~= "table" or candidate.version ~= 1 then return nil end
    for _, method in ipairs(REQUIRED_API_METHODS) do
        if type(candidate[method]) ~= "function" then return nil end
    end
    return candidate
end

local function RefreshInfoText()
    if ns.RefreshMeetingStoneInfoBarText then ns.RefreshMeetingStoneInfoBarText() end
end

local function RestoreLogo()
    local state = logoState
    logoState = nil
    if not state then return end
    state.region:SetTexture(state.texture)
    state.region:SetTexCoord(unpack(state.coords))
    state.region:SetVertexColor(unpack(state.color))
end

local function ApplyMeetingStoneLogo()
    local addon = rawget(_G, "LycheeGroup")
    local logo = addon and addon.Floating and addon.Floating.logoTexture
    if not logo or not logo.GetTexture or not logo.GetTexCoord or not logo.GetVertexColor
        or not logo.SetTexture or not logo.SetTexCoord or not logo.SetVertexColor then return end
    if logoState and logoState.region ~= logo then RestoreLogo() end
    -- API v1 has no artwork option; snapshot only the existing visual region.
    if not logoState then
        logoState = { region = logo, texture = logo:GetTexture(), coords = { logo:GetTexCoord() }, color = { logo:GetVertexColor() } }
    end
    local texture, left, right, top, bottom, isText, filter
    if ns.GetMicroMenuPreviewIconData then
        texture, left, right, top, bottom, isText, filter = ns.GetMicroMenuPreviewIconData("MeetingStone")
    end
    texture = texture or "Interface\\AddOns\\QFXSystemBar\\Media\\MicroMenu\\MeetingStone.tga"
    left, right, top, bottom = left or 0, right or 1, top or 0, bottom or 1
    local state = logoState
    if state.appliedTexture ~= texture or state.filter ~= filter then
        logo:SetTexture(texture, nil, nil, filter)
        state.appliedTexture, state.filter = texture, filter
    end
    if state.left ~= left or state.right ~= right or state.top ~= top or state.bottom ~= bottom then
        logo:SetTexCoord(left, right, top, bottom)
        state.left, state.right, state.top, state.bottom = left, right, top, bottom
    end
    local icon = currentRecord and currentRecord.icon
    local r, g, b, a = 1, 1, 1, 1
    if icon and icon.GetVertexColor then r, g, b, a = icon:GetVertexColor() end
    if state.r ~= r or state.g ~= g or state.b ~= b or state.a ~= a then
        logo:SetVertexColor(r, g, b, a)
        state.r, state.g, state.b, state.a = r, g, b, a
    end
end

local function RestoreHost()
    local host, record = currentHost, currentRecord
    currentHost, currentRecord = nil, nil
    RestoreLogo()
    if not host or not record then return end
    record.label:Hide()
    if record.originalText then record.originalText:SetShown(record.textShown) end
    if record.icon then record.icon:SetShown(record.iconShown) end
    if record.clips ~= nil then host:SetClipsChildren(record.clips) end
    host.qfxInfoBarText = nil
    RefreshInfoText()
end

local function Release()
    if api and currentHost then api:Detach(owner) end
    -- A provider that has already detached must not leave QFX visuals hidden.
    if currentHost then RestoreHost() end
end

local function DeferSync()
    if not deferredFrame then
        deferredFrame = CreateFrame("Frame")
        deferredFrame:SetScript("OnEvent", function(self)
            self:UnregisterEvent("PLAYER_REGEN_ENABLED")
            ns.SyncLycheeFloating()
        end)
    end
    deferredFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
end

local function GetHosts()
    local info = ns.GetMeetingStoneInfoBarButton and ns.GetMeetingStoneInfoBarButton()
    local db = QFXSystemBarDB or {}
    local micro = db.isCustomMicroMenu and db.isCustomMicroMenuMeetingStone and rawget(_G, "QFXSystemBarButton_MeetingStone")
    return IsVisible(info) and info or nil, IsVisible(micro) and micro or nil
end

local function GetRecord(host, kind)
    local record = records[host]
    if record then return record end
    local label = host:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetWordWrap(false)
    label:SetJustifyH("CENTER")
    label:SetJustifyV("MIDDLE")
    label:SetMaxLines(1)
    label:Hide()
    record = { label = label, kind = kind }
    records[host] = record
    host:HookScript("OnHide", function(self)
        if currentHost == self then ns.SyncLycheeFloating() end
    end)
    host:HookScript("OnShow", function() ns.SyncLycheeFloating() end)
    host:HookScript("OnSizeChanged", function(self)
        if currentHost == self then ns.SyncLycheeFloating() end
    end)
    return record
end

local function LayoutHost(host, record)
    local label = record.label
    local width, height = host:GetWidth(), host:GetHeight()
    local left = host.GetLeft and host:GetLeft()
    local top = host.GetTop and host:GetTop()
    local scale = host.GetEffectiveScale and host:GetEffectiveScale()
    local size = record.kind == "info" and math.min(18, math.max(1, height - 4)) or tonumber(host.qfxIconSize) or 30
    local changed = record.width ~= width or record.height ~= height or record.left ~= left
        or record.top ~= top or record.scale ~= scale or record.size ~= size
    if record.kind == "info" then
        local path, height, flags = host.text:GetFont()
        local r, g, b, a = host.text:GetTextColor()
        if record.font ~= path or record.fontSize ~= height or record.flags ~= flags then
            label:SetFont(path, height, flags or "")
            record.font, record.fontSize, record.flags = path, height, flags
        end
        if record.r ~= r or record.g ~= g or record.b ~= b or record.a ~= a then
            label:SetTextColor(r, g, b, a)
            record.r, record.g, record.b, record.a = r, g, b, a
        end
        host.text:Hide()
    else
        if not record.width then label:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF", 12, "OUTLINE") end
        if host.mmIcon then host.mmIcon:Hide() end
    end
    if changed then
        record.needsRefresh = true
        label:ClearAllPoints()
        if record.kind == "info" then
            label:SetPoint("TOPLEFT", host, "TOPLEFT", size + 8, 0)
            label:SetPoint("BOTTOMRIGHT", host, "BOTTOMRIGHT", -4, 0)
            label:SetAlpha(1)
        else
            label:SetPoint("LEFT", host, "CENTER", size / 2 + 4, 0)
            label:SetSize(1, height)
            label:SetAlpha(0)
        end
        record.width, record.height, record.left, record.top, record.scale, record.size = width, height, left, top, scale, size
    end
    if host.SetClipsChildren then host:SetClipsChildren(false) end
    label:Show()
    return size, changed
end

function ns.SyncLycheeFloating(preferredHost)
    if syncing then return currentHost ~= nil end
    if InCombatLockdown and InCombatLockdown() then
        DeferSync()
        return currentHost ~= nil
    end
    syncing = true
    local wanted = WantsIntegration()
    local nextAPI = wanted and GetAPI() or nil
    if nextAPI ~= api then
        Release()
        if unsubscribe then unsubscribe(); unsubscribe = nil end
        api = nextAPI
        if api then
            unsubscribe = api:Subscribe(function()
                ns.SyncLycheeFloating()
                RefreshInfoText()
            end)
        end
    end

    local info, micro = GetHosts()
    local host
    if preferredHost and (preferredHost == info or preferredHost == micro) then host = preferredHost
    elseif currentHost and (currentHost == info or currentHost == micro) then host = currentHost
    else host = info or micro end
    if not api or not api:IsAvailable() or not host then
        Release()
        syncing = nil
        return false
    end

    local record = GetRecord(host, host == info and "info" or "micro")
    local attached = currentHost ~= host
    if attached then
        Release()
        currentHost, currentRecord = host, record
        record.originalText = record.kind == "info" and host.text or nil
        record.textShown = record.originalText and record.originalText:IsShown()
        record.icon = record.kind == "micro" and host.mmIcon or nil
        record.iconShown = record.icon and record.icon:IsShown()
        record.clips = host.GetClipsChildren and host:GetClipsChildren()
        local size = LayoutHost(host, record)
        if not api:Attach(owner, host, size, record.label, RestoreHost) then
            RestoreHost()
            syncing = nil
            return false
        end
        record.needsRefresh = nil
    else
        local size, changed = LayoutHost(host, record)
        if changed or record.needsRefresh then
            record.needsRefresh = nil
            api:Refresh(owner, size)
        end
    end
    ApplyMeetingStoneLogo()
    local parent = host:GetParent()
    if attached or record.boundsParent ~= parent then
        api:SetPopupBounds(owner, parent and parent ~= UIParent and { host, parent } or { host })
        record.boundsParent = parent
    end
    syncing = nil
    return true
end

function ns.RefreshLycheeInfoBarHost(host)
    if host ~= currentHost or not currentRecord or currentRecord.kind ~= "info" then return false end
    LayoutHost(host, currentRecord)
    return true
end

function ns.GetLycheeFloatingText()
    local candidate = api or GetAPI()
    if not candidate or not candidate:IsAvailable() then return nil end
    local status = candidate:GetStatus()
    return status and type(status.text) == "string" and status.text ~= "" and status.text or nil
end

function ns.ShowPremadeAddonTooltip(host)
    if not ns.IsLycheeGroupActive or not ns.IsLycheeGroupActive() then return false end
    if not ns.SyncLycheeFloating(host) or currentHost ~= host then return false end
    if GameTooltip and GameTooltip:IsOwned(host) then GameTooltip:Hide() end
    return api:ShowPopup(owner)
end

function ns.HidePremadeAddonTooltip(host)
    if api and host == currentHost then api:HidePopup(owner) end
end

ns.SyncLycheeFloating()
