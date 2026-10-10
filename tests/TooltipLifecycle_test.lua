local function read(path)
    local file = assert(io.open(path, "rb"))
    local source = file:read("*a"):gsub("\r\n", "\n")
    file:close()
    return source
end
local source = read("QFXSystemBar_InfoBar/InfoBar.lua")
local timers, draws, hides = {}, 0, 0
local tip = {
    IsOwned = function(self, owner) return self.owner == owner end,
    Hide = function(self) hides = hides + 1; self.owner = nil end,
}
local ns = { StopGreatVaultTooltip = function() end, ClearInfoBarTimeTooltipOwner = function() end }
local env = setmetatable({
    ns = ns, modules = {}, GameTooltip = tip,
    C_Timer = { NewTicker = function(interval, callback)
        local timer = { interval = interval, callback = callback, Cancel = function(self) self.cancelled = true end }
        timers[#timers + 1] = timer
        return timer
    end },
    GetInfoBarTextFont = function() return "font.ttf", "" end,
    GetInfoBarFontSize = function() return 12 end,
    tooltipByID = { fps = function(owner) tip.owner = owner; draws = draws + 1 end },
    CreateFrame = function()
        local btn = { shown = true, hovered = true, scripts = {} }
        function btn:SetScript(event, callback) self.scripts[event] = callback end
        function btn:IsShown() return self.shown end
        function btn:IsMouseOver() return self.hovered end
        function btn:CreateFontString() return setmetatable({}, { __index = function() return function() end end }) end
        return setmetatable(btn, { __index = function() return function() end end })
    end,
}, { __index = _G })
assert(load(assert(source:match("HideTooltipTicker = function.-\nend\n")), "ticker cleanup", "t", env))()
env.HideInfoBarItemTooltip = assert(load(assert(source:match("local function HideInfoBarItemTooltip.-\nend\n")) .. "\nreturn HideInfoBarItemTooltip", "owner cleanup", "t", env))()
local create = assert(load(assert(source:match("local function CreateTextModule.-\nend\n")) .. "\nreturn CreateTextModule", "info-bar button", "t", env))()
local first, second = create("left", "fps"), create("right", "fps")
first.scripts.OnEnter(first)
local firstTimer = timers[#timers]
first.shown = false
first.scripts.OnHide(first) -- Hiding a bar need not deliver OnLeave.
assert(firstTimer.cancelled and env.tooltipTicker == nil and tip.owner == nil)
first.shown = true
first.scripts.OnEnter(first)
firstTimer = timers[#timers]
second.scripts.OnEnter(second)
local secondTimer = timers[#timers]
assert(firstTimer.cancelled)
first.scripts.OnHide(first)
assert(not secondTimer.cancelled and tip.owner == second, "old owner hid the new owner's tooltip")
local previousDraws = draws
secondTimer.callback()
assert(draws == previousDraws + 1 and not secondTimer.cancelled)
local foreign = {}
tip.owner = foreign
local previousHides = hides
secondTimer.callback()
assert(secondTimer.cancelled and tip.owner == foreign and hides == previousHides, "refresh stole or hid a foreign tooltip")
second.scripts.OnEnter(second)
secondTimer = timers[#timers]
second.shown = false -- Visibility fallback even if a hide callback was missed.
secondTimer.callback()
assert(secondTimer.cancelled and env.tooltipTicker == nil)

local timeCode = assert(source:match("function ns.HandleInfoBarInstanceInfoUpdate%(%)\n(.-)\nend"))
local timeOwner = { id = "time", IsShown = function(self) return self.shown end, IsMouseOver = function() return true end }
env.raidLockoutState = { owner = timeOwner }
local timeDraws = 0
env.UpdateRaidLockoutCache = function() end
ns.ShowInfoBarTimeTooltip = function() timeDraws = timeDraws + 1 end
assert(load("function ns.HandleInfoBarInstanceInfoUpdate()\n" .. timeCode .. "\nend", "time tooltip update", "t", env))()
timeOwner.shown, tip.owner = false, timeOwner
ns.HandleInfoBarInstanceInfoUpdate()
assert(timeDraws == 0, "event reopened a hidden time tooltip")
timeOwner.shown, tip.owner = true, foreign
ns.HandleInfoBarInstanceInfoUpdate()
assert(timeDraws == 0, "time event replaced a foreign tooltip")
tip.owner = timeOwner
ns.HandleInfoBarInstanceInfoUpdate()
assert(timeDraws == 1)

env.itemTickers = {}
env.ITEM_REFRESH_INTERVALS = assert(load("return " .. assert(source:match("local ITEM_REFRESH_INTERVALS = (%b{})"))))()
local enabled, refreshed = {}, 0
env.IsAnyInfoBarItemEnabled = function(id) return enabled[id] == true end
env.RefreshInfoBarItem = function() refreshed = refreshed + 1 end
local tickerCode = assert(source:match("(UpdateItemTickers = function.-)\nlocal function AnchorSlotModules"))
assert(load(tickerCode, "item ticker lifecycle", "t", env))()
local count = #timers
env.UpdateItemTickers()
assert(#timers == count, "disabled info bars allocated polling timers")
enabled.coords = true
env.UpdateItemTickers()
local coordsTimer = env.itemTickers.coords
assert(coordsTimer.interval == 2)
coordsTimer.callback()
assert(refreshed == 1)
enabled.coords = false
coordsTimer.callback()
assert(coordsTimer.cancelled and env.itemTickers.coords == nil, "disabled item kept polling")

local core = read("QFXSystemBar/QFXSystemBar.lua")
local menu = { alpha = 1, GetAlpha = function(self) return self.alpha end }
env._G = { QFXSystemBarFrame = menu }
local stopped, menuDraws = 0, 0
env.StopGameMenuTooltipTicker = function() stopped = stopped + 1; env.qfxGameMenuTooltipOwner = nil end
env.ShowGameMenuTooltip = function() menuDraws = menuDraws + 1 end
local callbackCode = assert(core:match("qfxGameMenuTooltipTicker = C_Timer.NewTicker%(GAME_MENU_TOOLTIP_INTERVAL, function%(%)\n(.-)\n            end%)"))
local callback = assert(load("return function()\n" .. callbackCode .. "\nend", "menu tooltip tick", "t", env))()
second.shown = true
env.qfxGameMenuTooltipOwner, tip.owner = second, second
callback()
assert(menuDraws == 1 and stopped == 0)
menu.alpha = 0
callback()
assert(stopped == 1 and tip.owner == nil and menuDraws == 1, "faded menu kept refreshing")
menu.alpha = 1
env.qfxGameMenuTooltipOwner, tip.owner = second, foreign
callback()
assert(stopped == 2 and tip.owner == foreign, "menu refresh hid a foreign tooltip")
local hideCode = assert(core:match('btn:SetScript%("OnHide", function%(self%)\n(.-)\n        end%)'))
local onHide = assert(load("return function(self)\n" .. hideCode .. "\nend", "menu hide", "t", env))()
env.qfxGameMenuTooltipOwner, tip.owner = second, second
onHide(second)
assert(stopped == 3 and tip.owner == nil, "hidden menu button kept its tooltip timer")
print("TooltipLifecycle_test: hidden owners, owner handoff, foreign tooltips, faded menus and disabled-item cancellation passed")
