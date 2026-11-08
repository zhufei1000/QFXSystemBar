-- The clock colon is two coloured squares over two larger black outline
-- backings. A backing drawn above its dot, or left shown while the dot is
-- hidden, reads as "two black dots" instead of a colon. Both invariants are
-- checked against the real closures extracted from the core file.
local coreFile = assert(io.open("QFXSystemBar/QFXSystemBar.lua", "rb"))
local core = coreFile:read("*a"):gsub("\r\n", "\n")
coreFile:close()

local function region()
    local value = { shown = true, alpha = 1, alphaWrites = 0, regions = {} }
    function value:Show() self.shown = true end
    function value:Hide() self.shown = false end
    function value:IsShown() return self.shown end
    function value:IsVisible() return self.shown end
    function value:SetAlpha(alpha) self.alpha = alpha; self.alphaWrites = self.alphaWrites + 1 end
    function value:GetAlpha() return self.alpha end
    function value:CreateFontString() return region() end
    function value:CreateTexture(name, layer, template, subLevel)
        local texture = region()
        texture.layer, texture.subLevel = layer, subLevel
        self.regions[#self.regions + 1] = texture
        return texture
    end
    return value
end

-- Creation must pin the backings below the dots with explicit sublevels;
-- same-layer regions have no guaranteed relative draw order.
local creationCode = assert(core:match("            if not btn%.timeHour then\n(.-)\n            end\n"))
local btn = region()
local creationEnv = setmetatable({ CreateFrame = function() return region() end }, { __index = _G })
creationEnv._G = creationEnv
assert(load("local btn = ...\n" .. creationCode, "colon region creation", "t", creationEnv))(btn)
for _, texture in ipairs({ btn.timeColonTopShadow, btn.timeColonBottomShadow, btn.timeColonTop, btn.timeColonBottom }) do
    assert(type(texture) == "table" and texture.layer == "OVERLAY", "colon region left the OVERLAY layer")
    assert(type(texture.subLevel) == "number", "colon region has no explicit draw sublevel")
end
assert(btn.timeColonTopShadow.subLevel < btn.timeColonTop.subLevel, "top outline backing can draw over its coloured dot")
assert(btn.timeColonBottomShadow.subLevel < btn.timeColonBottom.subLevel, "bottom outline backing can draw over its coloured dot")
assert(btn.timeColonTopShadow.subLevel == btn.timeColonBottomShadow.subLevel, "outline backings disagree on sublevel")
assert(btn.timeColonTop.subLevel == btn.timeColonBottom.subLevel, "coloured dots disagree on sublevel")
assert(#btn.timeColonAnchor.regions == 4, "colon regions are not all parented to the blink anchor")

-- The blink must fade the anchor only. Per-region Show/Hide churn reshuffles the
-- draw list and lets the backings outlive the dots.
local colonCode = assert(core:match("    local qfxColonBlinkTicker\n(.-)\n    local function UpdateTimeButton"))
local clockButtons, tickers = {}, {}
local host = region()
local env = setmetatable({
    QFXSystemBarFrame = host,
    IsMicroMenuEnabledNow = function() return true end,
    C_Timer = {
        NewTicker = function(interval, callback)
            local ticker = { interval = interval, callback = callback, Cancel = function(self) self.cancelled = true end }
            tickers[#tickers + 1] = ticker
            return ticker
        end,
    },
}, { __index = _G })
env._G = env
local chunk = "local qfxClockButtons = ...\nlocal qfxColonBlinkTicker\n" .. colonCode ..
    "\nlocal function Phase() return qfxColonBlinkVisible end" ..
    "\nreturn SetClockColonVisible, StartTimeColonPulse, StopAllClockColonPulses, TickClockColonBlink, StartClockColonBlinkTicker, Phase"
local setVisible, startPulse, stopAll, tick, startTicker, phase =
    assert(load(chunk, "colon blink ownership", "t", env))(clockButtons)

local function clockButton(outline)
    local button = region()
    button.timeColonAnchor = region()
    button.timeColonTop = button.timeColonAnchor:CreateTexture(nil, "OVERLAY", nil, 2)
    button.timeColonBottom = button.timeColonAnchor:CreateTexture(nil, "OVERLAY", nil, 2)
    button.timeColonTopShadow = button.timeColonAnchor:CreateTexture(nil, "OVERLAY", nil, 1)
    button.timeColonBottomShadow = button.timeColonAnchor:CreateTexture(nil, "OVERLAY", nil, 1)
    if not outline then
        button.timeColonTopShadow:Hide()
        button.timeColonBottomShadow:Hide()
    end
    return button
end

local function snapshot(button)
    local state = { tostring(button.timeColonAnchor.shown) }
    for _, key in ipairs({ "timeColonTop", "timeColonBottom", "timeColonTopShadow", "timeColonBottomShadow" }) do
        state[#state + 1] = tostring(button[key].shown)
        state[#state + 1] = tostring(button[key].alphaWrites)
    end
    return table.concat(state, ",")
end

local ticks = 0

for _, outline in ipairs({ true, false }) do
    local button = clockButton(outline)
    clockButtons[1] = button
    startPulse(button)
    local before = snapshot(button)
    local sawOn, sawOff = false, false
    for _ = 1, 200 do
        tick(); ticks = ticks + 1
        assert(snapshot(button) == before, "blink changed a colon region's shown state or own alpha")
        if button.timeColonAnchor.alpha == 1 then sawOn = true else sawOff = true end
    end
    assert(sawOn and sawOff, "colon stopped blinking")
    assert(button.timeColonTopShadow.shown == outline, "blink re-showed an outline backing disabled by the style")

    -- A rebuild landing on the off phase must not hide the freshly shown dots.
    local rebuilt = clockButton(outline)
    clockButtons[2] = rebuilt
    local rebuiltBefore = snapshot(rebuilt)
    startPulse(rebuilt)
    assert(snapshot(rebuilt) == rebuiltBefore, "rebuild during the off phase hid the new colon dots")
    assert(rebuilt.timeColonAnchor.alpha == (phase() and 1 or 0), "rebuilt colon did not inherit the blink phase")

    -- ApplyButtonVisuals owns Show/Hide: a hidden anchor stays hidden.
    rebuilt.timeColonAnchor:Hide()
    tick(); ticks = ticks + 1
    assert(not rebuilt.timeColonAnchor.shown, "blink re-showed an anchor hidden by the style")

    stopAll()
    assert(button.timeColonAnchor.alpha == 1 and rebuilt.timeColonAnchor.alpha == 1, "stopping the blink left the colon dark")
    assert(snapshot(button) == before, "stopping the blink changed region visibility")
    assert(tickers[#tickers].cancelled, "stop did not cancel the blink ticker")
    clockButtons[2] = nil
end

-- An alpha-hidden menu stops the blink and restores a solid colon.
local button = clockButton(true)
clockButtons[1] = button
startTicker()
assert(tickers[#tickers].interval == 1, "colon blink is not a one-second ticker")
host.alpha = 0
tick(); ticks = ticks + 1
assert(tickers[#tickers].cancelled and button.timeColonAnchor.alpha == 1, "alpha-hidden menu kept blinking or left the colon dark")
assert(phase() == true, "stopped blink did not reset to the solid phase")
setVisible(nil, false)
setVisible({}, false)

print(("ClockColonRendering_test: backings pinned below dots; %d blink ticks -> 0 region visibility changes"):format(ticks))