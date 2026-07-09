local addonName, childNS = ...
local ns = _G.QFXSystemBarNS or childNS
if not ns then return end
ns.MeetingStoneBridgeLoaded = true

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

    local function GetOptionalLibrary(name)
        local libstub = _G.LibStub
        if not libstub then return nil end
        local ok, lib
        if type(libstub) == "table" and libstub.GetLibrary then
            ok, lib = pcall(libstub.GetLibrary, libstub, name, true)
        else
            ok, lib = pcall(libstub, name, true)
        end
        if ok then return lib end
        return nil
    end

    local function EnsureMeetingStoneLoaded()
        local loaded = false
        if C_AddOns and C_AddOns.IsAddOnLoaded then
            local ok, result = pcall(C_AddOns.IsAddOnLoaded, "MeetingStone")
            loaded = ok and result and true or false
        elseif IsAddOnLoaded then
            local ok, result = pcall(IsAddOnLoaded, "MeetingStone")
            loaded = ok and result and true or false
        end
        if loaded then return true end

        local ok, result
        if C_AddOns and C_AddOns.LoadAddOn then
            ok, result = pcall(C_AddOns.LoadAddOn, "MeetingStone")
        elseif LoadAddOn then
            ok, result = pcall(LoadAddOn, "MeetingStone")
        end
        return ok and result ~= false
    end

    local function GetMeetingStoneAddon()
        local ace = GetOptionalLibrary("AceAddon-3.0")
        if ace and ace.GetAddon then
            local ok, addon = pcall(ace.GetAddon, ace, "MeetingStone", true)
            if ok and addon then return addon end
        end
        return nil
    end

    local meetingStoneFloatingPanel
    local HideMeetingStoneFloatingPanel
    local meetingStoneHideReentry
    local IsMeetingStoneReplacementActive

    local function SafeCall(func, ...)
        if type(func) ~= "function" then return false end
        local ok = pcall(func, ...)
        return ok and true or false
    end

    local function SafeReturn(func, ...)
        if type(func) ~= "function" then return nil end
        local ok, result = pcall(func, ...)
        if ok then return result end
        return nil
    end

    local premadeAddonDefs = {
        {
            addon = "MeetingStone",
            legacyAddons = { "MeetingStoneEX" },
            displayName = "MeetingStone",
        },
        {
            addon = "GroupFinder",
            displayName = "GroupFinder",
            globalName = "GroupFinder",
            brokerName = "GroupFinderLauncher",
            icon = "Interface\\AddOns\\GroupFinder\\Art\\Logo\\GroupFinder.png",
            floatFrameName = "GroupFinderAddonFloatButton",
            toggleGlobal = "GROUPFINDER_TOGGLE",
            slash = "GROUPFINDER",
        },
        {
            addon = "PremadeGroupBoard",
            displayName = "PremadeGroupBoard",
            globalName = "PremadeGroupBoard",
            brokerName = "PremadeGroupBoard",
            icon = "Interface\\AddOns\\PremadeGroupBoard\\Media\\minimap",
            floatFrameName = "PremadeGroupBoardFloatButton",
            toggleGlobal = "PGB_TOGGLE",
            slash = "PGB",
        },
    }

    local function IsAddonLoaded(addon)
        if C_AddOns and C_AddOns.IsAddOnLoaded then
            local ok, loaded = pcall(C_AddOns.IsAddOnLoaded, addon)
            return ok and loaded == true
        elseif IsAddOnLoaded then
            local ok, loaded = pcall(IsAddOnLoaded, addon)
            return ok and loaded == true
        end
        return false
    end

    local function IsAddonAvailable(addon)
        if IsAddonLoaded(addon) then return true end
        if C_AddOns and C_AddOns.GetAddOnInfo then
            local ok, name, title, notes, loadable = pcall(C_AddOns.GetAddOnInfo, addon)
            return ok and name ~= nil and loadable ~= false
        elseif GetAddOnInfo then
            local ok, name, title, notes, loadable = pcall(GetAddOnInfo, addon)
            return ok and name ~= nil and loadable ~= false
        end
        return false
    end

    local function IsPremadeAddonAvailable(def)
        if not def then return false end
        if IsAddonAvailable(def.addon) then return true end
        for _, alias in ipairs(def.legacyAddons or {}) do
            if IsAddonAvailable(alias) then return true end
        end
        return false
    end

    local function GetActivePremadeAddonDef()
        for _, def in ipairs(premadeAddonDefs) do
            if IsPremadeAddonAvailable(def) then return def end
        end
        return premadeAddonDefs[1]
    end

    local function EnsureAddonLoaded(addon)
        if IsAddonLoaded(addon) then return true end
        local ok, result
        if C_AddOns and C_AddOns.LoadAddOn then
            ok, result = pcall(C_AddOns.LoadAddOn, addon)
        elseif LoadAddOn then
            ok, result = pcall(LoadAddOn, addon)
        end
        return ok and result ~= false
    end

    local function EnsurePremadeAddonLoaded(def)
        def = def or GetActivePremadeAddonDef()
        if not def then return false end
        if EnsureAddonLoaded(def.addon) then return true end
        for _, alias in ipairs(def.legacyAddons or {}) do
            if EnsureAddonLoaded(alias) then return true end
        end
        return false
    end

    local function GetPremadeAddonObject(def)
        if not def then return nil end
        if def.globalName and _G[def.globalName] then return _G[def.globalName] end
        return nil
    end

    local function GetPremadeAddonDisplayName(def)
        def = def or GetActivePremadeAddonDef()
        return (def and def.displayName) or "MeetingStone"
    end

    local function GetGenericPremadeCounts(def)
        EnsurePremadeAddonLoaded(def)
        local addon = GetPremadeAddonObject(def)
        if addon and type(addon.GetLauncherStatusCounts) == "function" then
            local ok, applicants, groups, activeListing, applicantUnit = pcall(addon.GetLauncherStatusCounts)
            if ok then return tonumber(applicants) or 0, tonumber(groups) or 0, activeListing == true, applicantUnit end
        end

        local applicants, groups, activeListing = 0, 0, false
        if addon then
            if addon.Listing and type(addon.Listing.HasActive) == "function" then
                local ok, active = pcall(addon.Listing.HasActive, addon.Listing)
                activeListing = ok and active == true
            end
            if addon.ApplicantAlert and type(addon.ApplicantAlert.GetCount) == "function" then
                local ok, count = pcall(addon.ApplicantAlert.GetCount, addon.ApplicantAlert)
                if ok then applicants = tonumber(count) or applicants end
            elseif activeListing and addon.Listing and type(addon.Listing.GetApplicantCount) == "function" then
                local ok, count = pcall(addon.Listing.GetApplicantCount, addon.Listing)
                if ok then applicants = tonumber(count) or applicants end
            end
            if addon.Result and type(addon.Result.GetCount) == "function" then
                local ok, count = pcall(addon.Result.GetCount, addon.Result)
                if ok then groups = tonumber(count) or groups end
            elseif addon.Result and addon.Result.total then
                groups = tonumber(addon.Result.total) or groups
            end
        end

        if applicants <= 0 and C_LFGList then
            local hasActive = false
            if type(C_LFGList.HasActiveEntryInfo) == "function" then
                local ok, result = pcall(C_LFGList.HasActiveEntryInfo)
                hasActive = ok and result == true
            end
            activeListing = activeListing or hasActive
            local func = hasActive and C_LFGList.GetNumApplicants or C_LFGList.GetNumApplications
            if type(func) == "function" then
                local ok, a, b = pcall(func)
                if ok then applicants = tonumber(b) or tonumber(a) or applicants end
            end
        end

        return math.max(0, applicants), math.max(0, groups), activeListing
    end

    local function GetGenericPremadeFloatingFrame(def)
        if not def then return nil end
        local addon = GetPremadeAddonObject(def)
        if addon and addon.FloatButton and type(addon.FloatButton.GetButtonFrame) == "function" then
            local frame = SafeReturn(addon.FloatButton.GetButtonFrame, addon.FloatButton)
            if frame and frame.GetObjectType then return frame end
        end
        local frame = def.floatFrameName and _G[def.floatFrameName]
        if frame and frame.GetObjectType then return frame end
        return nil
    end

    local function HookGenericPremadeFloatingFrame(frame, def)
        if not frame or frame.qfxSystemBarGenericHideHooked or not frame.HookScript then return end
        frame.qfxSystemBarGenericHideHooked = true
        SafeCall(frame.HookScript, frame, "OnShow", function(self)
            local activeDef = GetActivePremadeAddonDef()
            if not IsMeetingStoneReplacementActive() or not activeDef or not def or activeDef.addon ~= def.addon then return end
            if C_Timer and C_Timer.After then
                C_Timer.After(0, function()
                    if self and self.Hide and IsMeetingStoneReplacementActive() then SafeCall(self.Hide, self) end
                end)
            elseif self.Hide then
                SafeCall(self.Hide, self)
            end
        end)
    end

    local function HideGenericPremadeFloatingPanel(def)
        def = def or GetActivePremadeAddonDef()
        if not def or def.addon == "MeetingStone" then return false end
        EnsurePremadeAddonLoaded(def)
        local frame = GetGenericPremadeFloatingFrame(def)
        if not frame then return false end
        HookGenericPremadeFloatingFrame(frame, def)
        if frame.qfxSystemBarGenericOriginalShown == nil and frame.IsShown then
            frame.qfxSystemBarGenericOriginalShown = frame:IsShown() and true or false
        end
        frame.qfxSystemBarHiddenBySystemBar = true
        if frame.Hide then SafeCall(frame.Hide, frame) end
        return true
    end

    local function RestoreGenericPremadeFloatingPanels()
        local restored = false
        for _, def in ipairs(premadeAddonDefs) do
            if def.addon ~= "MeetingStone" and IsAddonLoaded(def.addon) then
                local frame = GetGenericPremadeFloatingFrame(def)
                if frame and frame.qfxSystemBarHiddenBySystemBar then
                    frame.qfxSystemBarHiddenBySystemBar = nil
                    if frame.qfxSystemBarGenericOriginalShown and frame.Show then
                        SafeCall(frame.Show, frame)
                        restored = true
                    end
                    frame.qfxSystemBarGenericOriginalShown = nil
                end
            end
        end
        return restored
    end

    local function FormatGenericPremadeInfoBarText(def)
        local applicants, groups = GetGenericPremadeCounts(def)
        return string.format("Apply %d   Groups %d", applicants, groups)
    end

    function ns.GetActivePremadeAddonName()
        local def = GetActivePremadeAddonDef()
        return def and def.addon or "MeetingStone"
    end

    function ns.GetPremadeAddonDisplayName()
        return GetPremadeAddonDisplayName(GetActivePremadeAddonDef())
    end

    function ns.GetPremadeAddonIconTexture()
        local def = GetActivePremadeAddonDef()
        if not def or def.addon == "MeetingStone" then return nil end
        return def.icon
    end

    function ns.GetPremadeAddonInfoBarText()
        local def = GetActivePremadeAddonDef()
        if not def or def.addon == "MeetingStone" then return nil end
        return FormatGenericPremadeInfoBarText(def)
    end

    function ns.GetPremadeAddonCounts()
        local def = GetActivePremadeAddonDef()
        if not def or def.addon == "MeetingStone" then return nil end
        return GetGenericPremadeCounts(def)
    end

    function ns.ShowPremadeAddonTooltip(owner)
        local def = GetActivePremadeAddonDef()
        if not def or def.addon == "MeetingStone" then return false end
        local applicants, groups = GetGenericPremadeCounts(def)
        if GameTooltip and owner then
            GameTooltip:SetOwner(owner, "ANCHOR_TOP", 0, 12)
            GameTooltip:ClearLines()
            GameTooltip:AddLine(GetPremadeAddonDisplayName(def), 0, .6, 1)
            GameTooltip:AddLine(" ")
            GameTooltip:AddDoubleLine("Applications", tostring(applicants), 1, 1, 1, .6, .8, 1)
            GameTooltip:AddDoubleLine("Groups", tostring(groups), 1, 1, 1, .6, .8, 1)
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("Left Click: Open " .. GetPremadeAddonDisplayName(def), .6, .8, 1)
            GameTooltip:Show()
        end
        return true
    end

    local function GetMeetingStoneEnv()
        local ms = GetMeetingStoneAddon()
        local envLib = GetOptionalLibrary("NetEaseEnv-1.0")
        local envList = envLib and envLib._NSList
        local env

        if envList then
            env = envList.MeetingStone or (ms and ms.baseName and envList[ms.baseName])
            if not env then
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

    local function IsValidMeetingStoneDataBroker(candidate)
        return type(candidate) == "table" and (candidate.BrokerObject or candidate.BrokerPanel or candidate.BrokerText or type(candidate.UpdateLabel) == "function")
    end

    local function GetMeetingStoneBrokerPanel()
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
                    break
                end
            end
        end

        local panel = dataBroker and dataBroker.BrokerPanel
        if panel and type(panel) == "table" and panel.GetObjectType then return panel end
        return nil
    end

    local function GetMeetingStoneProfileModule()
        local ms, env, envList = GetMeetingStoneEnv()
        local profile = env and env.Profile
        if type(profile) == "table" then return profile end

        if ms and type(ms.GetModule) == "function" then
            profile = SafeReturn(ms.GetModule, ms, "Profile", true)
            if type(profile) == "table" then return profile end
        end
        if ms and type(ms.modules) == "table" then
            profile = ms.modules.Profile or ms.modules["Profile"]
            if type(profile) == "table" then return profile end
        end
        if envList then
            for _, candidateEnv in pairs(envList) do
                profile = type(candidateEnv) == "table" and candidateEnv.Profile
                if type(profile) == "table" then return profile end
            end
        end
        return nil
    end

    local function GetMeetingStonePanelSetting()
        local profile = GetMeetingStoneProfileModule()
        if not profile then return nil end
        if type(profile.GetSetting) == "function" then
            local value = SafeReturn(profile.GetSetting, profile, "panel")
            if value ~= nil then return value and true or false end
        end
        local cdb = profile.cdb
        local settings = cdb and cdb.profile and cdb.profile.settings
        if type(settings) == "table" and settings.panel ~= nil then return settings.panel and true or false end
        return nil
    end

    local function SetMeetingStonePanelSetting(value)
        local profile = GetMeetingStoneProfileModule()
        if not profile then return false end
        value = value and true or false
        if type(profile.SetSetting) == "function" then
            return SafeCall(profile.SetSetting, profile, "panel", value, true)
        end

        local cdb = profile.cdb
        local settings = cdb and cdb.profile and cdb.profile.settings
        if type(settings) == "table" then
            settings.panel = value
            if type(profile.SendMessage) == "function" then
                SafeCall(profile.SendMessage, profile, "MEETINGSTONE_SETTING_CHANGED", "panel", value, true)
                SafeCall(profile.SendMessage, profile, "MEETINGSTONE_SETTING_CHANGED_panel", value, true)
            end
            return true
        end
        return false
    end

    local function SaveQFXMeetingStoneOriginalPanelSetting()
        QFXSystemBarDB = QFXSystemBarDB or {}
        if QFXSystemBarDB.qfxMeetingStoneOriginalPanelSetting ~= nil then return end
        local current = GetMeetingStonePanelSetting()
        if current ~= nil then
            QFXSystemBarDB.qfxMeetingStoneOriginalPanelSetting = current and true or false
        end
    end

    local function ForceMeetingStonePanelSettingOff()
        SaveQFXMeetingStoneOriginalPanelSetting()
        return SetMeetingStonePanelSetting(false)
    end

    local function RestoreMeetingStonePanelSetting()
        local db = QFXSystemBarDB
        if not db or db.qfxMeetingStoneOriginalPanelSetting == nil then return false end
        local original = db.qfxMeetingStoneOriginalPanelSetting and true or false
        if SetMeetingStonePanelSetting(original) then
            db.qfxMeetingStoneOriginalPanelSetting = nil
            return true
        end
        return false
    end

    local function IsQFXMicroMenuActive(db)
        db = db or QFXSystemBarDB
        return db and db.isCustomMicroMenu == true
    end

    function ns.IsQFXMicroMenuActive()
        return IsQFXMicroMenuActive(QFXSystemBarDB)
    end

    local function IsMeetingStoneInfoBarActiveFallback(db)
        if not db or db.isInfoBar ~= true then return false end
        local slots = ns.InfoBarSlots
        if type(slots) ~= "table" then return false end
        for _, slot in pairs(slots) do
            if type(slot) == "table" and db[slot.barEnabledKey] == true then
                local items = db[slot.enabledKey]
                if type(items) == "table" and items.meetingstone == true then return true end
            end
        end
        return false
    end

    IsMeetingStoneReplacementActive = function()
        local db = QFXSystemBarDB
        if IsQFXMicroMenuActive(db) and db.isCustomMicroMenuMeetingStone == true then return true end
        if ns.IsMeetingStoneInfoBarActive then
            local ok, active = pcall(ns.IsMeetingStoneInfoBarActive)
            if ok and active then return true end
        end
        return IsMeetingStoneInfoBarActiveFallback(db)
    end

    local function HookMeetingStoneFloatingPanel(panel)
        if not panel or panel.qfxSystemBarHideHooked or not panel.HookScript then return end
        panel.qfxSystemBarHideHooked = true
        SafeCall(panel.HookScript, panel, "OnShow", function()
            if meetingStoneHideReentry or not IsMeetingStoneReplacementActive() then return end
            if C_Timer and C_Timer.After then
                C_Timer.After(0, function()
                    if HideMeetingStoneFloatingPanel and IsMeetingStoneReplacementActive() then HideMeetingStoneFloatingPanel() end
                end)
            elseif HideMeetingStoneFloatingPanel then
                HideMeetingStoneFloatingPanel()
            end
        end)
    end

    local function SaveObjectVisualState(object)
        if not object then return nil end
        local state = { object = object }
        if object.IsShown then state.shown = object:IsShown() and true or false end
        if object.GetAlpha then state.alpha = SafeReturn(object.GetAlpha, object) end
        if object.GetVertexColor then
            local r, g, b, a = SafeReturn(object.GetVertexColor, object)
            if r then state.vertexColor = { r, g, b, a } end
        end
        if object.IsMouseEnabled then state.mouseEnabled = object:IsMouseEnabled() and true or false end
        if object.IsMouseMotionEnabled then state.mouseMotionEnabled = object:IsMouseMotionEnabled() and true or false end
        return state
    end

    local function RestoreObjectVisualState(state)
        local object = state and state.object
        if not object then return end
        if state.alpha ~= nil and object.SetAlpha then SafeCall(object.SetAlpha, object, state.alpha) end
        if state.vertexColor and object.SetVertexColor then
            SafeCall(object.SetVertexColor, object, state.vertexColor[1] or 1, state.vertexColor[2] or 1, state.vertexColor[3] or 1, state.vertexColor[4] or 1)
        end
        if state.mouseEnabled ~= nil and object.EnableMouse then SafeCall(object.EnableMouse, object, state.mouseEnabled and true or false) end
        if state.mouseMotionEnabled ~= nil and object.EnableMouseMotion then SafeCall(object.EnableMouseMotion, object, state.mouseMotionEnabled and true or false) end
        if state.shown ~= nil then
            if state.shown then
                if object.Show then SafeCall(object.Show, object) end
            else
                if object.Hide then SafeCall(object.Hide, object) end
            end
        end
    end

    local function SaveFrameTreeState(frame, depth)
        if not frame then return nil end
        depth = depth or 0
        local state = SaveObjectVisualState(frame) or { object = frame }
        state.parent = frame.GetParent and frame:GetParent() or UIParent
        state.scale = frame.GetScale and SafeReturn(frame.GetScale, frame) or nil
        state.width = frame.GetWidth and SafeReturn(frame.GetWidth, frame) or nil
        state.height = frame.GetHeight and SafeReturn(frame.GetHeight, frame) or nil
        state.frameStrata = frame.GetFrameStrata and SafeReturn(frame.GetFrameStrata, frame) or nil
        state.frameLevel = frame.GetFrameLevel and SafeReturn(frame.GetFrameLevel, frame) or nil
        if frame.GetBackdrop then state.backdrop = SafeReturn(frame.GetBackdrop, frame) end
        if frame.GetBackdropColor then
            local r, g, b, a = SafeReturn(frame.GetBackdropColor, frame)
            if r then state.backdropColor = { r, g, b, a } end
        end
        if frame.GetBackdropBorderColor then
            local r, g, b, a = SafeReturn(frame.GetBackdropBorderColor, frame)
            if r then state.backdropBorderColor = { r, g, b, a } end
        end
        state.points = {}
        local numPoints = frame.GetNumPoints and frame:GetNumPoints() or 0
        for i = 1, numPoints do
            local point, relTo, relPoint, x, y = frame:GetPoint(i)
            state.points[i] = { point, relTo, relPoint, x, y }
        end
        state.regions = {}
        if frame.GetRegions then
            local regions = { frame:GetRegions() }
            for _, region in ipairs(regions) do
                local regionState = SaveObjectVisualState(region)
                if regionState then state.regions[#state.regions + 1] = regionState end
            end
        end
        state.children = {}
        if depth < 2 and frame.GetChildren then
            local children = { frame:GetChildren() }
            for _, child in ipairs(children) do
                local childState = SaveFrameTreeState(child, depth + 1)
                if childState then state.children[#state.children + 1] = childState end
            end
        end
        return state
    end

    local function RestoreFrameTreeState(state)
        local frame = state and state.object
        if frame == nil then return end
        if state.parent and frame.SetParent then SafeCall(frame.SetParent, frame, state.parent) end
        if state.scale and frame.SetScale then SafeCall(frame.SetScale, frame, state.scale) end
        if state.frameStrata and frame.SetFrameStrata then SafeCall(frame.SetFrameStrata, frame, state.frameStrata) end
        if state.frameLevel and frame.SetFrameLevel then SafeCall(frame.SetFrameLevel, frame, state.frameLevel) end
        if frame.ClearAllPoints then SafeCall(frame.ClearAllPoints, frame) end
        if type(state.points) == "table" and #state.points > 0 and frame.SetPoint then
            for _, pt in ipairs(state.points) do
                SafeCall(frame.SetPoint, frame, pt[1], pt[2], pt[3], pt[4] or 0, pt[5] or 0)
            end
        elseif frame.SetPoint then
            SafeCall(frame.SetPoint, frame, "CENTER", state.parent or UIParent, "CENTER", 0, 0)
        end
        if state.width and state.height and frame.SetSize then SafeCall(frame.SetSize, frame, state.width, state.height) end
        if state.backdrop and frame.SetBackdrop then SafeCall(frame.SetBackdrop, frame, state.backdrop) end
        if state.backdropColor and frame.SetBackdropColor then
            SafeCall(frame.SetBackdropColor, frame, state.backdropColor[1] or 0, state.backdropColor[2] or 0, state.backdropColor[3] or 0, state.backdropColor[4] or 1)
        end
        if state.backdropBorderColor and frame.SetBackdropBorderColor then
            SafeCall(frame.SetBackdropBorderColor, frame, state.backdropBorderColor[1] or 1, state.backdropBorderColor[2] or 1, state.backdropBorderColor[3] or 1, state.backdropBorderColor[4] or 1)
        end
        if state.alpha ~= nil and frame.SetAlpha then SafeCall(frame.SetAlpha, frame, state.alpha) end
        if state.mouseEnabled ~= nil and frame.EnableMouse then SafeCall(frame.EnableMouse, frame, state.mouseEnabled and true or false) end
        if state.mouseMotionEnabled ~= nil and frame.EnableMouseMotion then SafeCall(frame.EnableMouseMotion, frame, state.mouseMotionEnabled and true or false) end
        for _, regionState in ipairs(state.regions or {}) do RestoreObjectVisualState(regionState) end
        for _, childState in ipairs(state.children or {}) do RestoreFrameTreeState(childState) end
        if state.shown ~= nil then
            if state.shown then
                if frame.Show then SafeCall(frame.Show, frame) end
            else
                if frame.Hide then SafeCall(frame.Hide, frame) end
            end
        end
    end

    local function DisableFrameTreeMouse(state)
        local frame = state and state.object
        if frame then
            if frame.EnableMouse then SafeCall(frame.EnableMouse, frame, false) end
            if frame.EnableMouseMotion then SafeCall(frame.EnableMouseMotion, frame, false) end
        end
        for _, childState in ipairs((state and state.children) or {}) do DisableFrameTreeMouse(childState) end
    end

    local function SaveMeetingStoneFloatingOriginal(panel)
        if not panel or panel.qfxSystemBarHiddenBySystemBar then return end
        panel.qfxSystemBarOriginalState = SaveFrameTreeState(panel, 0)
        panel.qfxSystemBarOriginalSaved = true
        panel.qfxSystemBarOriginalParent = panel.GetParent and panel:GetParent() or UIParent
        panel.qfxSystemBarOriginalScale = panel.GetScale and panel:GetScale() or 1
        panel.qfxSystemBarOriginalWidth = panel.GetWidth and panel:GetWidth() or nil
        panel.qfxSystemBarOriginalHeight = panel.GetHeight and panel:GetHeight() or nil
        panel.qfxSystemBarOriginalShown = panel.IsShown and panel:IsShown() or false
        if panel.GetBackdrop then panel.qfxSystemBarOriginalBackdrop = panel:GetBackdrop() end
        panel.qfxSystemBarOriginalPoints = {}
        local numPoints = panel.GetNumPoints and panel:GetNumPoints() or 0
        for i = 1, numPoints do
            local point, relTo, relPoint, x, y = panel:GetPoint(i)
            panel.qfxSystemBarOriginalPoints[i] = { point, relTo, relPoint, x, y }
        end
    end

    local function RestoreMeetingStoneFloatingPanel()
        if IsMeetingStoneReplacementActive() then
            if HideMeetingStoneFloatingPanel then HideMeetingStoneFloatingPanel() end
            return false
        end

        RestoreMeetingStonePanelSetting()

        local panel = meetingStoneFloatingPanel or GetMeetingStoneBrokerPanel()
        if not panel or not panel.qfxSystemBarHiddenBySystemBar then return false end
        panel.qfxSystemBarHiddenBySystemBar = nil
        local state = panel.qfxSystemBarOriginalState
        if state then
            RestoreFrameTreeState(state)
            local function retryRestore()
                if panel and not panel.qfxSystemBarHiddenBySystemBar then
                    RestoreFrameTreeState(state)
                end
            end
            if C_Timer and C_Timer.After then
                C_Timer.After(0, retryRestore)
                C_Timer.After(0.10, retryRestore)
            end
            return true
        end
        if panel.SetScale then SafeCall(panel.SetScale, panel, panel.qfxSystemBarOriginalScale or 1) end
        if panel.ClearAllPoints then SafeCall(panel.ClearAllPoints, panel) end
        if panel.SetParent then SafeCall(panel.SetParent, panel, panel.qfxSystemBarOriginalParent or UIParent) end
        local points = panel.qfxSystemBarOriginalPoints
        if type(points) == "table" and #points > 0 and panel.SetPoint then
            for _, pt in ipairs(points) do
                SafeCall(panel.SetPoint, panel, pt[1], pt[2], pt[3], pt[4] or 0, pt[5] or 0)
            end
        elseif panel.SetPoint then
            SafeCall(panel.SetPoint, panel, "CENTER", panel.qfxSystemBarOriginalParent or UIParent, "CENTER", 0, 0)
        end
        if panel.qfxSystemBarOriginalWidth and panel.qfxSystemBarOriginalHeight and panel.SetSize then
            SafeCall(panel.SetSize, panel, panel.qfxSystemBarOriginalWidth, panel.qfxSystemBarOriginalHeight)
        end
        if panel.qfxSystemBarOriginalBackdrop and panel.SetBackdrop then SafeCall(panel.SetBackdrop, panel, panel.qfxSystemBarOriginalBackdrop) end
        if panel.qfxSystemBarOriginalShown then
            if panel.Show then SafeCall(panel.Show, panel) end
        else
            if panel.Hide then SafeCall(panel.Hide, panel) end
        end
        return true
    end

    HideMeetingStoneFloatingPanel = function()
        local panel = GetMeetingStoneBrokerPanel()
        if panel then
            HookMeetingStoneFloatingPanel(panel)
            SaveMeetingStoneFloatingOriginal(panel)
            meetingStoneFloatingPanel = panel
            panel.qfxSystemBarHiddenBySystemBar = true
        end

        local changedSetting = ForceMeetingStonePanelSettingOff()
        if not panel then return changedSetting end

        local state = panel.qfxSystemBarOriginalState
        meetingStoneHideReentry = true
        if panel.SetAlpha then SafeCall(panel.SetAlpha, panel, 0) end
        if panel.EnableMouse then SafeCall(panel.EnableMouse, panel, false) end
        if panel.EnableMouseMotion then SafeCall(panel.EnableMouseMotion, panel, false) end
        DisableFrameTreeMouse(state)
        if panel.Hide then SafeCall(panel.Hide, panel) end
        meetingStoneHideReentry = nil
        return true
    end

    function ns.HideMeetingStoneFloatingPanel()
        local activeDef = GetActivePremadeAddonDef()
        if activeDef and activeDef.addon ~= "MeetingStone" then
            return HideGenericPremadeFloatingPanel(activeDef)
        end
        EnsureMeetingStoneLoaded()
        return HideMeetingStoneFloatingPanel()
    end

    function ns.RestoreMeetingStoneFloatingPanel()
        if QFXSystemBarDB and QFXSystemBarDB.qfxMeetingStoneOriginalPanelSetting ~= nil then
            EnsureMeetingStoneLoaded()
        end
        local restoredGeneric = RestoreGenericPremadeFloatingPanels()
        return RestoreMeetingStoneFloatingPanel() or restoredGeneric
    end

    function ns.SyncMeetingStoneFloatingPanel()
        if IsMeetingStoneReplacementActive() then
            local activeDef = GetActivePremadeAddonDef()
            if activeDef and activeDef.addon ~= "MeetingStone" then
                HideGenericPremadeFloatingPanel(activeDef)
            else
                ns.HideMeetingStoneFloatingPanel()
            end
        else
            ns.RestoreMeetingStoneFloatingPanel()
        end
    end

    function ns.QueueMeetingStoneFloatingSync()
        if ns.SyncMeetingStoneFloatingPanel then ns.SyncMeetingStoneFloatingPanel() end
        if C_Timer and C_Timer.After then
            C_Timer.After(0.20, function() if ns.SyncMeetingStoneFloatingPanel then ns.SyncMeetingStoneFloatingPanel() end end)
            C_Timer.After(1.00, function() if ns.SyncMeetingStoneFloatingPanel then ns.SyncMeetingStoneFloatingPanel() end end)
        end
    end

    function ns.ConfirmMeetingStoneButtonVisibility(checked, checkbox, applyFunc)
        local function Apply(finalChecked)
            if type(applyFunc) == "function" then applyFunc(finalChecked and true or false) end
            if finalChecked then
                ns.HideMeetingStoneFloatingPanel()
            else
                ns.RestoreMeetingStoneFloatingPanel()
            end
        end

        if checked then
            local activeDef = GetActivePremadeAddonDef()
            -- Load the active replacement target before accepting so its
            -- floating entry can be captured and hidden immediately.
            EnsurePremadeAddonLoaded(activeDef)
            if not StaticPopupDialogs or not StaticPopup_Show then
                Apply(true)
                return
            end

            local popupID = "QFXSYSTEMBAR_MEETINGSTONE_FLOATING_WINDOW"
            StaticPopupDialogs[popupID] = StaticPopupDialogs[popupID] or {
                button1 = YES,
                button2 = CANCEL,
                timeout = 0,
                whileDead = true,
                hideOnEscape = true,
                preferredIndex = 3,
            }
            StaticPopupDialogs[popupID].text = T("Enabling the MeetingStone button will hide MeetingStone's floating window. Continue?")
            StaticPopupDialogs[popupID].button1 = YES or T("Confirm")
            StaticPopupDialogs[popupID].button2 = CANCEL or T("Cancel")
            StaticPopupDialogs[popupID].OnAccept = function(_, data)
                Apply(true)
            end
            StaticPopupDialogs[popupID].OnCancel = function(_, data)
                if checkbox and checkbox.SetChecked then checkbox:SetChecked(false) end
                Apply(false)
            end
            StaticPopup_Show(popupID)
        else
            Apply(false)
        end
    end

    local function ToggleMeetingStone(owner, button)
        local activeDef = GetActivePremadeAddonDef()
        if activeDef and activeDef.addon ~= "MeetingStone" then
            EnsurePremadeAddonLoaded(activeDef)

            local ldb = GetOptionalLibrary("LibDataBroker-1.1")
            if ldb and activeDef.brokerName and ldb.GetDataObjectByName then
                local okObj, obj = pcall(ldb.GetDataObjectByName, ldb, activeDef.brokerName)
                if okObj and obj and type(obj.OnClick) == "function" then
                    local okClick = pcall(obj.OnClick, owner or UIParent, button or "LeftButton")
                    if okClick then return end
                end
            end

            local addon = GetPremadeAddonObject(activeDef)
            if addon and addon.MainFrame and type(addon.MainFrame.Toggle) == "function" then
                local okToggle = pcall(addon.MainFrame.Toggle, addon.MainFrame)
                if okToggle then return end
            end
            if activeDef.toggleGlobal and type(_G[activeDef.toggleGlobal]) == "function" then
                local okToggle = pcall(_G[activeDef.toggleGlobal])
                if okToggle then return end
            end
            if activeDef.slash and SlashCmdList and type(SlashCmdList[activeDef.slash]) == "function" then
                local okSlash = pcall(SlashCmdList[activeDef.slash], "")
                if okSlash then return end
            end

            print("|cFF33FF99QFX|r - |cFFEE8800" .. GetPremadeAddonDisplayName(activeDef) .. " is not loaded.|r")
            return
        end

        EnsureMeetingStoneLoaded()

        local ldb = GetOptionalLibrary("LibDataBroker-1.1")
        if ldb and ldb.GetDataObjectByName then
            local okObj, obj = pcall(ldb.GetDataObjectByName, ldb, "MeetingStone")
            if okObj and obj and type(obj.OnClick) == "function" then
                local okClick = pcall(obj.OnClick, owner or UIParent, button or "LeftButton")
                if okClick then return end
            end
        end

        local ms = GetMeetingStoneAddon()
        if ms and type(ms.Toggle) == "function" then
            local okToggle = pcall(ms.Toggle, ms)
            if okToggle then return end
        end

        local envLib = GetOptionalLibrary("NetEaseEnv-1.0")
        local env = envLib and envLib._NSList and envLib._NSList.MeetingStone
        local panel = env and env.MainPanel
        if panel then
            if panel:IsShown() then
                if HideUIPanel then HideUIPanel(panel) else panel:Hide() end
            else
                if ShowUIPanel then ShowUIPanel(panel) else panel:Show() end
            end
            return
        end

        if SlashCmdList and SlashCmdList.MeetingStone then
            SlashCmdList.MeetingStone("")
            return
        end

        print("|cFF33FF99QFX|r - |cFFEE8800" .. T("MeetingStone is not loaded.") .. "|r")
    end

    -- -------------------------------------------------------------------

ns.ToggleMeetingStone = ToggleMeetingStone
