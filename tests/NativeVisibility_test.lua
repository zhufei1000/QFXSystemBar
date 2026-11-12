-- Native visibility must preserve Blizzard scripts and defer combat mutations.
local file = assert(io.open("QFXSystemBar/QFXSystemBar.lua", "rb"))
local source = file:read("*a"):gsub("\r\n", "\n")
file:close()
local block = assert(source:match("%-%- Frame fade system\n.-\ndo\n(.*)\nend%s*$"))
local ns, timers, watchers = {}, {}, {}
local combat, nativeOnShow, nativeMutations = false, 0, 0
local combatFlushes, menuApplies = 0, 0
ns.FlushMicroMenuRefresh = function() combatFlushes = combatFlushes + 1 end
local env = setmetatable({}, { __index = _G })
env._G = env
env.QFXSystemBarDB = { nativeMicroMenu = 1, bagBar = 1, customMicroMenu = 0 }
env.InCombatLockdown = function() return combat end
env.C_Timer = { After = function(_, callback) timers[#timers + 1] = callback end }
env.EventUtil = { ContinueOnAddOnLoaded = function() end }
local function newFrame(name, native, shown)
    local scripts, hooks, events = {}, {}, {}
    local visible = shown ~= false
    local frame = {}
    local function onShow()
        if scripts.OnShow then scripts.OnShow(frame) end
        for _, hook in ipairs(hooks.OnShow or {}) do hook(frame) end
    end
    function frame:GetName() return name end
    function frame:SetScript(script, callback)
        assert(not native, "replaced a Blizzard script on " .. name)
        scripts[script] = callback
    end
    function frame:GetScript(script) return scripts[script] end
    function frame:HookScript(script, callback)
        hooks[script] = hooks[script] or {}
        hooks[script][#hooks[script] + 1] = callback
    end
    function frame:RegisterEvent(event) events[event] = true end
    function frame:IsShown() return visible end
    function frame:Show()
        if native then
            assert(not combat, "addon Show in combat on " .. name)
            nativeMutations = nativeMutations + 1
        end
        if visible then return end
        visible = true
        onShow()
    end
    function frame:Hide()
        if native then
            assert(not combat, "addon Hide in combat on " .. name)
            nativeMutations = nativeMutations + 1
        end
        visible = false
    end
    function frame:BlizzardShow()
        if visible then return end
        visible = true
        onShow()
    end
    function frame:Fire(event)
        if events[event] and scripts.OnEvent then scripts.OnEvent(frame, event) end
    end
    function frame:GetHookCount(script) return #(hooks[script] or {}) end
    function frame:GetAlpha() return 1 end
    function frame:SetAlpha()
        if name == "QFXSystemBarFrame" then menuApplies = menuApplies + 1 end
    end
    if native then
        scripts.OnShow = function() nativeOnShow = nativeOnShow + 1 end
    else
        watchers[#watchers + 1] = frame
    end
    return frame
end
env.CreateFrame = function() return newFrame("watcher", false) end
env.QFXSystemBarFrame = newFrame("QFXSystemBarFrame", false)
local originals = {}
for _, name in ipairs({
    "MicroMenu", "CharacterMicroButton", "EJMicroButton", "StoreMicroButton",
    "BagsBar", "MainMenuBarBackpackButton", "BagBarExpandToggle", "CharacterBag0Slot",
}) do
    env[name] = newFrame(name, true, name ~= "StoreMicroButton" and name ~= "CharacterBag0Slot")
    originals[name] = env[name]:GetScript("OnShow")
end
local function flush()
    local pending = timers
    timers = {}
    for _, callback in ipairs(pending) do callback() end
end
local function fire(event)
    for _, frame in ipairs(watchers) do frame:Fire(event) end
end
assert(load("local addonName, ns = ...\ndo\n" .. block .. "\nend", "visibility", "t", env))("QFXSystemBar", ns)

-- Combat can start between requesting the apply and running its timer.
ns.RequestApplyAllStates()
combat = true
flush()
assert(nativeMutations == 0, "queued apply bypassed combat lockdown")
combat = false
fire("PLAYER_REGEN_ENABLED")
flush()
assert(combatFlushes == 1 and menuApplies == 1, "combat end repeated menu flush or visibility apply")
-- Only the ordinary containers are hidden. Their secure children keep their
-- native shown state, scripts and hook tables untouched so no button taint can
-- leak into the action-bar system.
assert(not env.MicroMenu:IsShown() and not env.BagsBar:IsShown())
assert(env.CharacterMicroButton:IsShown() and env.MainMenuBarBackpackButton:IsShown())
for name, original in pairs(originals) do
    assert(env[name]:GetScript("OnShow") == original, "lost native OnShow on " .. name)
    local expectedHooks = (name == "MicroMenu" or name == "BagsBar") and 1 or 0
    assert(env[name]:GetHookCount("OnShow") == expectedHooks,
        "unexpected hide hook count on " .. name .. " (secure buttons must not be re-hooked)")
end

-- Blizzard's OnShow executes; the container re-hide must wait until after that
-- call finishes.
local previousOnShow = nativeOnShow
env.MicroMenu:BlizzardShow()
assert(nativeOnShow == previousOnShow + 1, "Blizzard OnShow no longer runs")
assert(env.MicroMenu:IsShown(), "reentrant hide inside native OnShow")
flush()
assert(not env.MicroMenu:IsShown(), "native container re-show did not re-hide")
env.CharacterMicroButton:BlizzardShow()
flush()
assert(env.CharacterMicroButton:IsShown(), "re-hid a native secure child button")
env.StoreMicroButton:BlizzardShow()
flush()
assert(env.StoreMicroButton:IsShown(), "hid a native secure button outside the container")

-- Re-show in combat remains untouched until the combat-end apply. The secure
-- bag button is not hidden at all, so it must stay shown throughout.
combat = true
local previousMutations = nativeMutations
env.BagsBar:BlizzardShow()
env.MainMenuBarBackpackButton:BlizzardShow()
flush()
assert(nativeMutations == previousMutations, "hide hook mutated a native frame during combat")
assert(env.BagsBar:IsShown() and env.MainMenuBarBackpackButton:IsShown())
combat = false
fire("PLAYER_REGEN_ENABLED")
flush()
assert(not env.BagsBar:IsShown(), "combat-end container re-hide was not applied")
assert(env.MainMenuBarBackpackButton:IsShown(), "hid a native secure bag button")

-- Switching mode before a queued hide runs cancels that hide. Originally hidden
-- native buttons stay hidden instead of being force-shown on restoration.
env.EJMicroButton:BlizzardShow()
env.QFXSystemBarDB.nativeMicroMenu = 0
env.QFXSystemBarDB.bagBar = 0
fire("PLAYER_REGEN_ENABLED")
flush()
flush()
assert(env.MicroMenu:IsShown() and env.BagsBar:IsShown())
assert(env.CharacterMicroButton:IsShown() and env.EJMicroButton:IsShown())
assert(env.MainMenuBarBackpackButton:IsShown())
assert(env.StoreMicroButton:IsShown(), "lost a native visibility update while hidden")
assert(not env.CharacterBag0Slot:IsShown(), "force-showed an originally hidden bag slot")
for name, original in pairs(originals) do
    assert(env[name]:GetScript("OnShow") == original)
    local expectedHooks = (name == "MicroMenu" or name == "BagsBar") and 1 or 0
    assert(env[name]:GetHookCount("OnShow") == expectedHooks)
end
print("Native visibility: scripts, restoration, deferred hides and combat race passed")
