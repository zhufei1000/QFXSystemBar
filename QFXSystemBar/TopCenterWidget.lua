local addonName, ns = ...

-- Position manager for Blizzard's top-center zone information container.
-- This module owns only UIWidgetTopCenterContainerFrame's root anchor. It does
-- not inspect or modify the frame's widgets, visibility, scale, alpha or strata.
local Module = {}
ns.TopCenterWidget = Module

local TARGET_FRAME_NAME = "UIWidgetTopCenterContainerFrame"
local MENU_FRAME_NAME = "QFXSystemBarFrame"
local UI_WIDGETS_ADDON = "Blizzard_UIWidgets"
local MENU_ANCHOR_Y = -6
local INITIALIZE_DELAY = 0.5

local databaseReady = false
local enteredWorld = false
local initializationScheduled = false
local initialized = false
local pendingPositionData = nil
local previewFrame = nil
local previewDragging = false
local configPageActive = false
local coordinateTextObject = nil

local function IsFiniteNumber(value)
    return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

local function RoundCoordinate(value)
    if not IsFiniteNumber(value) then return nil end
    if value >= 0 then return math.floor(value + 0.5) end
    return math.ceil(value - 0.5)
end

local function IsInCombat()
    return InCombatLockdown and InCombatLockdown()
end

local function GetTargetFrame()
    return _G[TARGET_FRAME_NAME]
end

local function GetMenuFrame()
    return _G[MENU_FRAME_NAME]
end

local function IsUIWidgetsLoaded()
    return C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded(UI_WIDGETS_ADDON)
end

local function GetPositionDB()
    QFXSystemBarDB = QFXSystemBarDB or {}
    if type(QFXSystemBarDB.topCenterWidget) ~= "table" then
        QFXSystemBarDB.topCenterWidget = {}
    end
    local db = QFXSystemBarDB.topCenterWidget
    if db.locked == nil then db.locked = true end
    return db
end

-- Convert a frame's live top-center point into UIParent's coordinate system.
-- GetLeft/GetTop/GetWidth use the frame's effective scale, so both sides are
-- converted through physical screen units and then back to UIParent UI units.
function Module:GetTopCenterOffsetRelativeToUIParent(frame)
    if not frame or not UIParent then return nil, nil end

    local frameLeft = frame:GetLeft()
    local frameTop = frame:GetTop()
    local frameWidth = frame:GetWidth()
    local parentLeft = UIParent:GetLeft()
    local parentTop = UIParent:GetTop()
    local parentWidth = UIParent:GetWidth()
    local frameScale = frame:GetEffectiveScale()
    local parentScale = UIParent:GetEffectiveScale()

    if not IsFiniteNumber(frameLeft) or not IsFiniteNumber(frameTop) or not IsFiniteNumber(frameWidth)
        or not IsFiniteNumber(parentLeft) or not IsFiniteNumber(parentTop) or not IsFiniteNumber(parentWidth)
        or not IsFiniteNumber(frameScale) or not IsFiniteNumber(parentScale)
        or frameScale <= 0 or parentScale <= 0 then
        return nil, nil
    end

    local frameCenterPhysical = (frameLeft + frameWidth * 0.5) * frameScale
    local frameTopPhysical = frameTop * frameScale
    local parentCenterPhysical = (parentLeft + parentWidth * 0.5) * parentScale
    local parentTopPhysical = parentTop * parentScale
    return (frameCenterPhysical - parentCenterPhysical) / parentScale,
        (frameTopPhysical - parentTopPhysical) / parentScale
end

local function GetMenuAnchorOffset()
    local menu = GetMenuFrame()
    if not menu or not UIParent then return nil, nil end

    local menuLeft = menu:GetLeft()
    local menuBottom = menu:GetBottom()
    local menuWidth = menu:GetWidth()
    local parentLeft = UIParent:GetLeft()
    local parentTop = UIParent:GetTop()
    local parentWidth = UIParent:GetWidth()
    local menuScale = menu:GetEffectiveScale()
    local parentScale = UIParent:GetEffectiveScale()

    if not IsFiniteNumber(menuLeft) or not IsFiniteNumber(menuBottom) or not IsFiniteNumber(menuWidth)
        or not IsFiniteNumber(parentLeft) or not IsFiniteNumber(parentTop) or not IsFiniteNumber(parentWidth)
        or not IsFiniteNumber(menuScale) or not IsFiniteNumber(parentScale)
        or menuScale <= 0 or parentScale <= 0 then
        return nil, nil
    end

    local menuCenterPhysical = (menuLeft + menuWidth * 0.5) * menuScale
    local menuBottomPhysical = menuBottom * menuScale
    local parentCenterPhysical = (parentLeft + parentWidth * 0.5) * parentScale
    local parentTopPhysical = parentTop * parentScale
    return (menuCenterPhysical - parentCenterPhysical) / parentScale,
        (menuBottomPhysical - parentTopPhysical) / parentScale + MENU_ANCHOR_Y
end

local function IsBlizzardDefaultAnchor(frame)
    if not frame then return nil end
    local point, relativeTo, relativePoint, x, y = frame:GetPoint(1)
    if not point or not IsFiniteNumber(x) or not IsFiniteNumber(y) then return nil end
    return point == "TOP"
        and relativeTo == UIParent
        and relativePoint == "TOP"
        and math.abs(x) < 0.5
        and math.abs(y + 15) < 0.5
end

local function CopyPositionData(data)
    if not data then return nil end
    return { mode = data.mode, x = data.x, y = data.y }
end

local function SavePositionData(data)
    local db = GetPositionDB()
    if data.mode == "menu" then
        db.positionMode = "menu"
        db.x = nil
        db.y = nil
    elseif data.mode == "custom" and IsFiniteNumber(data.x) and IsFiniteNumber(data.y) then
        db.positionMode = "custom"
        db.x = data.x
        db.y = data.y
    end
end

local function ApplyAnchorNow(data)
    local target = GetTargetFrame()
    if not target then return false end

    if data.mode == "menu" then
        local menu = GetMenuFrame()
        if not menu then return false end
        target:ClearAllPoints()
        target:SetPoint("TOP", menu, "BOTTOM", 0, MENU_ANCHOR_Y)
        return true
    end

    if data.mode == "custom" and IsFiniteNumber(data.x) and IsFiniteNumber(data.y) then
        target:ClearAllPoints()
        target:SetPoint("TOP", UIParent, "TOP", data.x, data.y)
        return true
    end

    return false
end

local function FormatCoordinates(x, y)
    local roundedX, roundedY = RoundCoordinate(x), RoundCoordinate(y)
    if roundedX == nil or roundedY == nil then return "X: --  Y: --" end
    return string.format("X: %d  Y: %d", roundedX, roundedY)
end

function Module:GetCurrentPosition()
    return self:GetTopCenterOffsetRelativeToUIParent(GetTargetFrame())
end

function Module:RefreshCoordinateText(object, x, y)
    if object then coordinateTextObject = object end
    local target = object or coordinateTextObject
    if not target or not target.SetText then return end
    if not IsFiniteNumber(x) or not IsFiniteNumber(y) then x, y = self:GetCurrentPosition() end
    target:SetText(FormatCoordinates(x, y))
end

local function ApplyPositionData(data, save, syncPreview, refreshCoordinates)
    if not data or (data.mode ~= "menu" and data.mode ~= "custom") then return false end
    if data.mode == "custom" and (not IsFiniteNumber(data.x) or not IsFiniteNumber(data.y)) then return false end
    if save then SavePositionData(data) end

    if IsInCombat() then
        pendingPositionData = CopyPositionData(data)
        return true
    end

    if not ApplyAnchorNow(data) then
        pendingPositionData = CopyPositionData(data)
        return false
    end

    pendingPositionData = nil
    if syncPreview then Module:RefreshPreview() end
    if refreshCoordinates ~= false then Module:RefreshCoordinateText() end
    return true
end

function Module:ApplyCustomTopCenterWidgetPosition(x, y, save)
    return ApplyPositionData({ mode = "custom", x = x, y = y }, save ~= false, true, true)
end

function Module:ApplyMenuTopCenterWidgetPosition(save)
    return ApplyPositionData({ mode = "menu" }, save ~= false, true, true)
end

function Module:IsLocked()
    return GetPositionDB().locked ~= false
end

function Module:FinishPreviewDrag(save)
    if not previewFrame or not previewDragging then return end
    previewFrame:SetScript("OnUpdate", nil)
    previewDragging = false
    previewFrame:StopMovingOrSizing()

    local x, y = self:GetTopCenterOffsetRelativeToUIParent(previewFrame)
    if save and IsFiniteNumber(x) and IsFiniteNumber(y) then
        ApplyPositionData({ mode = "custom", x = x, y = y }, true, true, true)
    else
        self:RefreshPreview()
    end
end

local function EnsurePreviewFrame()
    if previewFrame then return previewFrame end

    previewFrame = CreateFrame("Frame", "QFXSystemBarTopCenterWidgetPreview", UIParent, "BackdropTemplate")
    previewFrame:SetSize(220, 32)
    previewFrame:SetFrameStrata("DIALOG")
    previewFrame:SetClampedToScreen(true)
    previewFrame:SetMovable(true)
    previewFrame:EnableMouse(true)
    previewFrame:RegisterForDrag("LeftButton")
    previewFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    previewFrame:SetBackdropColor(0.05, 0.25, 0.45, 0.32)
    previewFrame:SetBackdropBorderColor(0.25, 0.75, 1, 0.95)

    local label = previewFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("CENTER")
    if ns.SetUIText then ns.SetUIText(label, "Top-Center Zone Information") else label:SetText("Top-Center Zone Information") end

    local markerVertical = previewFrame:CreateTexture(nil, "OVERLAY")
    markerVertical:SetColorTexture(1, 0.82, 0, 1)
    markerVertical:SetSize(2, 10)
    markerVertical:SetPoint("CENTER", previewFrame, "TOP", 0, 0)

    local markerHorizontal = previewFrame:CreateTexture(nil, "OVERLAY")
    markerHorizontal:SetColorTexture(1, 0.82, 0, 1)
    markerHorizontal:SetSize(12, 2)
    markerHorizontal:SetPoint("CENTER", previewFrame, "TOP", 0, 0)

    previewFrame:SetScript("OnDragStart", function(self)
        if Module:IsLocked() or IsInCombat() then return end
        local x, y = Module:GetCurrentPosition()
        if not IsFiniteNumber(x) or not IsFiniteNumber(y) then return end

        self:ClearAllPoints()
        self:SetPoint("TOP", UIParent, "TOP", x, y)
        self:StartMoving()
        previewDragging = true
        self:SetScript("OnUpdate", function(activePreview)
            local currentX, currentY = Module:GetTopCenterOffsetRelativeToUIParent(activePreview)
            if not IsFiniteNumber(currentX) or not IsFiniteNumber(currentY) then return end
            ApplyPositionData({ mode = "custom", x = currentX, y = currentY }, false, false, false)
            Module:RefreshCoordinateText(nil, currentX, currentY)
        end)
    end)

    previewFrame:SetScript("OnDragStop", function()
        Module:FinishPreviewDrag(true)
    end)
    previewFrame:Hide()
    return previewFrame
end

function Module:RefreshPreview()
    if not previewFrame or previewDragging then return end
    local x, y = self:GetCurrentPosition()
    if not IsFiniteNumber(x) or not IsFiniteNumber(y) then return end
    previewFrame:ClearAllPoints()
    previewFrame:SetPoint("TOP", UIParent, "TOP", x, y)
end

function Module:ShowPreview()
    if self:IsLocked() then return end
    local x, y = self:GetCurrentPosition()
    if not IsFiniteNumber(x) or not IsFiniteNumber(y) then return end
    local preview = EnsurePreviewFrame()
    preview:ClearAllPoints()
    preview:SetPoint("TOP", UIParent, "TOP", x, y)
    preview:Show()
end

function Module:HidePreview()
    self:FinishPreviewDrag(true)
    if previewFrame then previewFrame:Hide() end
end

function Module:SetLocked(locked)
    local db = GetPositionDB()
    db.locked = locked and true or false
    if db.locked then
        self:HidePreview()
    elseif configPageActive then
        self:ShowPreview()
    end
end

function Module:Nudge(deltaX, deltaY)
    deltaX = IsFiniteNumber(deltaX) and deltaX or 0
    deltaY = IsFiniteNumber(deltaY) and deltaY or 0

    local x, y
    if pendingPositionData and pendingPositionData.mode == "custom" then
        x, y = pendingPositionData.x, pendingPositionData.y
    elseif pendingPositionData and pendingPositionData.mode == "menu" then
        x, y = GetMenuAnchorOffset()
    else
        x, y = self:GetCurrentPosition()
    end

    if not IsFiniteNumber(x) or not IsFiniteNumber(y) then
        local db = GetPositionDB()
        if db.positionMode == "custom" and IsFiniteNumber(db.x) and IsFiniteNumber(db.y) then
            x, y = db.x, db.y
        elseif db.positionMode == "menu" then
            x, y = GetMenuAnchorOffset()
        end
    end
    if not IsFiniteNumber(x) or not IsFiniteNumber(y) then return false end

    return ApplyPositionData({ mode = "custom", x = x + deltaX, y = y + deltaY }, true, true, true)
end

function Module:ResetPosition()
    return ApplyPositionData({ mode = "menu" }, true, true, true)
end

function Module:SetConfigPageActive(active)
    configPageActive = active and true or false
    if configPageActive and not self:IsLocked() then
        self:ShowPreview()
    else
        self:HidePreview()
    end
    self:RefreshCoordinateText()
end

function Module:OnConfigClosed()
    configPageActive = false
    self:HidePreview()
end

local function FlushPendingPosition()
    if IsInCombat() or not pendingPositionData then return end
    local data = CopyPositionData(pendingPositionData)
    if ApplyAnchorNow(data) then
        pendingPositionData = nil
        Module:RefreshPreview()
        Module:RefreshCoordinateText()
    end
end

local function InitializationConditionsReady()
    return databaseReady
        and enteredWorld
        and IsUIWidgetsLoaded()
        and GetTargetFrame() ~= nil
        and GetMenuFrame() ~= nil
end

local function InitializeTopCenterWidgetPosition()
    initializationScheduled = false
    if initialized or not InitializationConditionsReady() then return false end

    local db = GetPositionDB()
    if db.positionMode == "custom" then
        if not IsFiniteNumber(db.x) or not IsFiniteNumber(db.y) then return false end
        ApplyPositionData({ mode = "custom", x = db.x, y = db.y }, false, true, true)
        initialized = true
        return true
    end

    if db.positionMode == "menu" then
        ApplyPositionData({ mode = "menu" }, false, true, true)
        initialized = true
        return true
    end

    if db.positionMode ~= nil then return false end

    local target = GetTargetFrame()
    local isDefault = IsBlizzardDefaultAnchor(target)
    if isDefault == nil then return false end

    if isDefault then
        ApplyPositionData({ mode = "menu" }, true, true, true)
    else
        local currentX, currentY = Module:GetCurrentPosition()
        if not IsFiniteNumber(currentX) or not IsFiniteNumber(currentY) then return false end
        SavePositionData({ mode = "custom", x = currentX, y = currentY })
        Module:RefreshPreview()
        Module:RefreshCoordinateText(nil, currentX, currentY)
    end

    initialized = true
    return true
end

local function TryScheduleInitialization()
    if initialized or initializationScheduled or not InitializationConditionsReady() then return end
    initializationScheduled = true
    if C_Timer and C_Timer.After then
        C_Timer.After(INITIALIZE_DELAY, InitializeTopCenterWidgetPosition)
    else
        InitializeTopCenterWidgetPosition()
    end
end

function Module:Initialize()
    TryScheduleInitialization()
end

function Module:OnDatabaseReady()
    GetPositionDB()
    databaseReady = true
    TryScheduleInitialization()
end

function Module:OnMenuFrameReady()
    TryScheduleInitialization()
    FlushPendingPosition()
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == UI_WIDGETS_ADDON then TryScheduleInitialization() end
        return
    end

    if event == "PLAYER_ENTERING_WORLD" then
        enteredWorld = true
        TryScheduleInitialization()
        return
    end

    if event == "PLAYER_REGEN_ENABLED" then
        FlushPendingPosition()
        TryScheduleInitialization()
    end
end)
