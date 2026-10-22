-- Pass the installed LycheeGroup/API.lua path to also verify its real contract.
local geometryWrites, textureWrites, nativeRefreshes = 0, 0, 0
local function region(text)
    local value = { shown = true, text = text or "", points = {} }
    function value:IsShown() return self.shown end
    function value:SetShown(shown) self.shown = shown end
    function value:Show() self.shown = true end
    function value:Hide() self.shown = false end
    function value:SetText(text) self.text = text end
    function value:GetText() return self.text end
    function value:GetFont() return "font.ttf", 12, "OUTLINE" end
    function value:SetFont(...) self.font = { ... } end
    function value:GetTextColor() return 1, 1, 1, 1 end
    function value:SetTextColor() end
    function value:GetTexture() return self.texture end
    function value:SetTexture(texture) textureWrites = textureWrites + 1; self.texture = texture end
    function value:GetTexCoord() return table.unpack(self.coords or { 0, 1, 0, 1 }) end
    function value:SetTexCoord(...) textureWrites = textureWrites + 1; self.coords = { ... } end
    function value:GetVertexColor() return table.unpack(self.color or { 1, 1, 1, 1 }) end
    function value:SetVertexColor(...) textureWrites = textureWrites + 1; self.color = { ... } end
    function value:SetWordWrap() end
    function value:SetJustifyH() end
    function value:SetJustifyV() end
    function value:SetMaxLines() end
    function value:SetAlpha(alpha) self.alpha = alpha end
    function value:ClearAllPoints() geometryWrites = geometryWrites + 1; self.points = {} end
    function value:SetPoint(...) self.points[#self.points + 1] = { ... } end
    function value:SetSize(width, height) self.width, self.height = width, height end
    return value
end
local function frame(width, height)
    local value = region()
    value.width, value.height, value.hooks, value.events = width, height, {}, {}
    function value:IsVisible() return self.shown and (not self.parent or self.parent:IsVisible()) end
    function value:GetWidth() return self.width end
    function value:GetHeight() return self.height end
    function value:GetParent() return self.parent end
    function value:GetClipsChildren() return self.clips end
    function value:SetClipsChildren(clips) self.clips = clips end
    function value:CreateFontString() return region() end
    function value:HookScript(event, callback)
        self.hooks[event] = self.hooks[event] or {}
        table.insert(self.hooks[event], callback)
    end
    function value:SetScript(event, callback) self[event] = callback end
    function value:RegisterEvent(event) self.events[event] = true end
    function value:UnregisterEvent(event) self.events[event] = nil end
    function value:Fire(event)
        for _, callback in ipairs(self.hooks[event] or {}) do callback(self) end
    end
    return value
end

local db = { isCustomMicroMenu = true, isCustomMicroMenuMeetingStone = true, isInfoBar = true }
local root, bar, micro, info = frame(1920, 1080), frame(450, 18), frame(34, 34), frame(100, 32)
bar.parent, micro.parent, info.parent = root, bar, bar
micro.mmIcon, micro.qfxIconSize = region(), 30
micro.qfxDefinition = { id = "MeetingStone" }
info.text, info.clips = region("荔枝组队"), true
local active, combat, refreshes = true, false, 0
local selectedTexture = "Interface\\AddOns\\QFXSystemBar\\Media\\MicroMenu\\GameIcons\\MeetingStone.blp"
local eventFrames = {}
local ns = {
    IsLycheeGroupActive = function() return active end,
    IsMeetingStoneInfoBarActive = function() return db.isInfoBar end,
    GetMeetingStoneInfoBarButton = function() return db.isInfoBar and info:IsVisible() and info or nil end,
    GetMicroMenuPreviewIconData = function(id)
        assert(id == "MeetingStone")
        return selectedTexture, .1, .9, .2, .8, false
    end,
}
local floating = { frame = {}, statusText = "荔枝组队", lastCount = 0 }
floating.logoTexture = region()
floating.logoTexture:SetTexture("lychee-logo.tga")
floating.logoTexture:SetTexCoord(0, 0, 0, 1, 1, 0, 1, 1)
floating.logoTexture:SetVertexColor(.9, .4, .5, 1)
floating.panel = { IsShown = function() return floating.popup == true end }
function floating:LayoutPanel() end
function floating:Render() end
function floating:SetHost(host, size, label)
    self.host, self.size, self.label = host, size, label
    if label then label:SetText(self.statusText) end
    if self.PublishStatus then self:PublishStatus() end
end
function floating:ShowPanel() self.popup = true end
function floating:ScheduleHide() self.popup = false end
local addon = { db = { floating = true, floatingCompatibility = true }, Floating = floating }
local env = setmetatable({
    QFXSystemBarNS = ns, QFXSystemBarDB = db, LycheeGroup = addon, UIParent = root,
    QFXSystemBarButton_MeetingStone = micro, unpack = table.unpack,
    InCombatLockdown = function() return combat end,
    geterrorhandler = function() return function(err) error(err) end end,
    CreateFrame = function()
        local value = frame(1, 1)
        eventFrames[#eventFrames + 1] = value
        return value
    end,
    GameTooltip = { IsOwned = function() return false end },
}, { __index = _G })
env._G = env

if arg[1] then
    assert(loadfile(arg[1], "t", env))()
else
    local api, subscribers, holder, release = { version = 1 }, {}, nil, nil
    addon.API = { Floating = api }
    function api:IsAvailable() return addon.db.floating and addon.db.floatingCompatibility and not floating.standaloneTest end
    function api:GetStatus() return { available = self:IsAvailable(), text = floating.statusText, count = floating.lastCount } end
    function api:Subscribe(callback)
        subscribers[callback] = true
        callback(self:GetStatus())
        return function() subscribers[callback] = nil end
    end
    function api:Attach(nextOwner, host, size, label, callback)
        if not self:IsAvailable() then return false, "unavailable" end
        if holder and holder ~= nextOwner then return false, "occupied" end
        holder, release = nextOwner, callback
        floating:SetHost(host, size, label)
        return true
    end
    function api:Detach(nextOwner)
        if holder ~= nextOwner then return false end
        local callback = release
        holder, release = nil, nil
        floating:SetHost(nil)
        callback()
        return true
    end
    function api:Refresh(nextOwner, size)
        if holder ~= nextOwner then return false end
        floating:SetHost(floating.host, size, floating.label)
        return true
    end
    function api:SetPopupBounds(nextOwner, bounds)
        if holder == nextOwner then floating.popupBounds = bounds; return true end
        return false
    end
    function api:ShowPopup(nextOwner)
        if holder ~= nextOwner then return false end
        floating:ShowPanel()
        return true
    end
    function api:HidePopup(nextOwner)
        if holder ~= nextOwner then return false end
        floating:ScheduleHide()
        return true
    end
    function floating:PublishStatus()
        if holder and not api:IsAvailable() then api:Detach(holder) end
        for callback in pairs(subscribers) do callback(api:GetStatus()) end
    end
end
local api = addon.API.Floating
local nativeRefresh = api.Refresh
api.Refresh = function(self, ...)
    nativeRefreshes = nativeRefreshes + 1
    return nativeRefresh(self, ...)
end
ns.RefreshMeetingStoneInfoBarText = function()
    refreshes = refreshes + 1
    if not db.isInfoBar then return end
    info.text:Show()
    if not ns.RefreshLycheeInfoBarHost(info) then info.text:SetText(ns.GetLycheeFloatingText() or "荔枝组队") end
end
assert(loadfile(arg[2] or "QFXSystemBar_MeetingStone/LycheeGroupBridge.lua", "t", env))("QFXSystemBar_MeetingStone", ns)
assert(floating.host == info and not info.text:IsShown() and not info.clips, "info-bar takeover did not replace the original label or release clipping")
assert(floating.label:GetText() == "荔枝组队" and floating.size == 18)
assert(floating.logoTexture:GetTexture() == selectedTexture and #floating.logoTexture.coords == 4, "hosted entry did not use the selected MeetingStone artwork")
assert(#floating.popupBounds == 2 and floating.popupBounds[2] == bar)
local oldGeometry, oldTextures, oldRefreshes = geometryWrites, textureWrites, nativeRefreshes
for _ = 1, 25 do ns.SyncLycheeFloating() end
print(string.format("Lychee warm sync x25: native refreshes=%d, layout writes=%d, texture writes=%d",
    nativeRefreshes - oldRefreshes, geometryWrites - oldGeometry, textureWrites - oldTextures))
if arg[3] ~= "--measure-only" then
    assert(nativeRefreshes == oldRefreshes and geometryWrites == oldGeometry and textureWrites == oldTextures,
        "unchanged status synchronization still rebuilds native layout or textures")
end
local beforeResize = nativeRefreshes
info.height = 20
info:Fire("OnSizeChanged")
assert(floating.size == 16 and nativeRefreshes == beforeResize + 1, "changed host geometry did not refresh the native entry")
info.height = 32
info:Fire("OnSizeChanged")
assert(floating.size == 18)
beforeResize = nativeRefreshes
info.height = 19
assert(ns.RefreshLycheeInfoBarHost(info))
ns.SyncLycheeFloating()
assert(floating.size == 15 and nativeRefreshes == beforeResize + 1, "text refresh consumed a pending native geometry update")
info.height = 32
info:Fire("OnSizeChanged")
assert(ns.ShowPremadeAddonTooltip(info) and floating.popup, "native application list did not open")
ns.HidePremadeAddonTooltip(info)
assert(not floating.popup)

floating.statusText, floating.lastCount = "申请3个", 3
if floating.label then floating.label:SetText(floating.statusText) end
floating:PublishStatus()
assert(ns.GetLycheeFloatingText() == "申请3个" and refreshes > 0)
assert(not info.text:IsShown(), "text refresh overpainted the native status label")

-- Only one native window exists; hovering either entry moves it safely.
local coreFile = assert(io.open("QFXSystemBar/QFXSystemBar.lua", "rb"))
local core = coreFile:read("*a"):gsub("\r\n", "\n")
coreFile:close()
local tooltipHides = 0
env.ns = ns
env.HideQFXTooltip = function() tooltipHides = tooltipHides + 1 end
env.ShowQFXHoverTooltip = function() error("native popup fell back to the ordinary tooltip") end
local showCode = assert(core:match("    local function ShowOldStyleButtonTooltip.-\n    end\n"))
local show = assert(load(showCode .. "\nreturn ShowOldStyleButtonTooltip", "micro-menu native hover", "t", env))()
show(micro, micro.qfxDefinition)
assert(floating.popup and tooltipHides == 1)
assert(floating.host == micro and not micro.mmIcon:IsShown() and floating.label.alpha == 0)
assert(floating.logoTexture:GetTexture() == selectedTexture, "host transfer lost the MeetingStone icon")
assert(info.text:IsShown() and info.clips, "switching hosts did not restore info-bar visuals")
assert(info.text:GetText() == "申请3个")
local leaveCode = assert(core:match("    local function MicroButtonOnLeave.-\n    end\n"))
local leave = assert(load(leaveCode .. "\nreturn MicroButtonOnLeave", "micro-menu popup leave", "t", env))()
leave(micro)
assert(not floating.popup, "micro-menu mouse leave did not close the native popup")
assert(ns.ShowPremadeAddonTooltip(info) and micro.mmIcon:IsShown())
selectedTexture = "Interface\\AddOns\\QFXSystemBar\\Media\\MicroMenu\\Lucide\\MeetingStone.blp"
ns.SyncLycheeFloating()
assert(floating.logoTexture:GetTexture() == selectedTexture, "icon theme changes did not refresh the hosted artwork")

-- Closing one host transfers ownership; closing all restores standalone mode.
info.shown, db.isInfoBar = false, false
info:Fire("OnHide")
assert(floating.host == micro and info.text:IsShown() and info.clips)
db.isCustomMicroMenu, micro.shown = false, false
micro:Fire("OnHide")
assert(floating.host == nil and micro.mmIcon:IsShown(), "closing all entries did not restore standalone mode")
assert(floating.logoTexture:GetTexture() == "lychee-logo.tga" and #floating.logoTexture.coords == 8
    and floating.logoTexture.color[1] == .9, "release did not restore Lychee's original artwork, crop and tint")
local idleRefreshes = refreshes
floating.statusText, floating.lastCount = "申请4个", 4
floating:PublishStatus()
assert(refreshes == idleRefreshes, "disabled QFX entries retained a status subscription")

db.isCustomMicroMenu, micro.shown = true, true
micro:Fire("OnShow")
assert(floating.host == micro)
addon.db.floatingCompatibility = false
floating:PublishStatus()
assert(floating.host == nil and micro.mmIcon:IsShown(), "provider compatibility opt-out was ignored")
addon.db.floatingCompatibility = true
floating:PublishStatus()
assert(floating.host == micro, "provider compatibility opt-in did not reattach")

active = false
ns.SyncLycheeFloating()
assert(floating.host == nil and micro.mmIcon:IsShown(), "provider change retained the old owner")

-- Another integration's ownership is respected, and a failed attach restores UI.
local foreign, foreignHost = {}, frame(100, 32)
assert(api:Attach(foreign, foreignHost, 18, region(), function() end))
active = true
assert(not ns.SyncLycheeFloating())
assert(floating.host == foreignHost and micro.mmIcon:IsShown(), "failed attach stole a foreign host or hid the QFX icon")
assert(floating.logoTexture:GetTexture() == "lychee-logo.tga", "failed attach changed a foreign owner's icon")
api:Detach(foreign)
ns.SyncLycheeFloating()
assert(floating.host == micro)

-- Reparenting and restoration wait for combat to end.
combat, db.isCustomMicroMenu, micro.shown = true, false, false
micro:Fire("OnHide")
assert(floating.host == micro and #eventFrames == 1 and eventFrames[1].events.PLAYER_REGEN_ENABLED)
combat = false
eventFrames[1].OnEvent(eventFrames[1], "PLAYER_REGEN_ENABLED")
assert(floating.host == nil and not eventFrames[1].events.PLAYER_REGEN_ENABLED)

print("LycheeFloating_test: native attach, status, hover, host transfer, restoration, compatibility, foreign ownership and combat deferral passed" .. (arg[1] and " (installed API)" or ""))
