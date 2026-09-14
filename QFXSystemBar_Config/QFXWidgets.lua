--[[============================================================================
QFXWidgets -- drop-in settings widget factory for QFX addons (single file).

HOW TO USE
  1. Copy this file into your addon folder and add it to the .toc.
  2. In every file:
        local addonName, ns = ...
        local W = QFXWidgets          -- or ns.QFXWidgets
  3. Build rows against any parent frame (your own panel / scroll child):
        local row, h = W:SectionHeader(parent, "GENERAL", y); y = y - h
        row, h = W:DualRow(parent, y,
            { type = "toggle", text = "Enable", getValue = ..., setValue = ... },
            { type = "slider", text = "Size", min = 10, max = 40, step = 1,
              getValue = ..., setValue = ... }); y = y - h
        row, h = W:WideButton(parent, "Open Full Settings", y, onClick); y = y - h
        y = W:Note(parent, y, "Some hint text.")
  4. On page refresh / reopen call W:Refresh() (re-reads every getValue and
     re-applies disabled states). Call W:ClearRefreshes() before rebuilding a page.
  5. For a scrollable page (own window / long page):
        local page = W:ScrollPage(parent)          -- parent must already be sized
        local y = -W.Theme.pad
        ... build rows into page.content ...
        page:SetContentHeight(-y + W.Theme.pad)    -- shows the scrollbar if needed
     The scrollbar is self-drawn (wheel + thumb drag) and hides when all fits.

CFG TYPES (DualRow left/right slot)
  { type = "label",  text }
  { type = "toggle", text, getValue, setValue, tooltip, disabled, disabledTooltip }
  { type = "slider", text, min, max, step, getValue, setValue, tooltip,
    trackWidth, valueSuffix, steppers = false, disabled, disabledTooltip }
      -- default: a +/- stepper column sits right of the value box (click =
      -- one step, clamped, dimmed at both ends; steppers = false to drop it)
  { type = "dropdown", text, values, order, getValue, setValue, tooltip,
    width, disabled, disabledTooltip }
  { type = "segmented", text, values, order, getValue, setValue, minWidth,
    tooltip, onSelect, disabled, disabledTooltip }
      -- 2-4 mutually exclusive pills, right-aligned, active = accent fill
  { type = "button", text, onClick, width, disabled, disabledTooltip }
  { type = "buttonRow", gap, buttons = { { text, onClick, width, tooltip,
    disabled, disabledTooltip }, ... } }  -- right-aligned cluster (nudge pads)
  { type = "color",  text, getValue, setValue, tooltip, alpha = true }
      -- get/set r, g, b [, a]; alpha = true shows the alpha channel in the picker
  { type = "colorMode", text, modes, order, customKey = "custom", getMode, setMode,
    getColor, setColor, defaultColor, defaultMode, alpha, tooltip, resetTooltip }
      -- mode dropdown + color swatch (visible while mode == customKey) + reset
  { type = "keybind", text, getValue, setValue, tooltip, width, noneText,
    captureText, conflicts, clearOnRightClick }
      -- click to capture (keyboard / mouse wheel / side buttons), Esc cancels,
      -- right-click clears; conflicts(key) -> name turns the label red
  { type = "input",  text, getValue, setValue, tooltip, width, numeric }

EXTRA CONTROLS
  W:ResetRows(parent)   optional: restart the zebra stripes at a page start
                        (SectionHeader also resets them automatically).
  W:CheckboxDropdown(parent, width, frameLevel, items, getFn, setFn, opts)
      items = { { key, label, tooltip }, ... }; getFn(key) -> bool;
      setFn(key, value). Returns dropdownButton, refreshFn.
  W:ColorSwatch(parent, frameLevel, getFn, setFn, opts)
      getFn -> r, g, b; setFn(r, g, b). Returns swatchButton.
  W:Tabs(parent, y, items, getActive, onSelect, opts)      -- frame, height
  W:CheckGrid(parent, y, columns, entries, opts)           -- frame, height
  W:ReorderList(parent, y, { items, onChange, rowH })      -- frame, height
  W:Cog(anchor, { title, rows, width, onReset })           -- cog, openFn
  W:SearchableDropdown(parent, width, level, items, getValue, setValue, opts)
      -- dd, refreshFn; items table or function, re-read on every open.
      -- items = { { key, label, tooltip, group, action = { text | icon,
      --   tooltip, onClick(key) } }, ... } -- groups render as headings;
      -- action renders a small right-aligned button (preview/test/remove)
  W:Segmented(parent, level, values, order, getValue, setValue, opts)
      -- region, refreshFn, firstBtn (caller anchors the region)
  W:ScrollPage(parent, opts)     -- page { frame, content, SetContentHeight(h), ... }
  W:MultilineBox(parent, y, cfg) -- frame, height (GetText/SetText/Commit)
  W:Confirm(opts | text)         -- modal confirm dialog (accept/cancel callbacks)
  W:MediaList(kind) / W:MediaValues(kind) / W:FetchMedia(kind, name)
  W:PreviewSound(name, channel)  -- SharedMedia helpers (all optional)
  W:StatusRow(parent, y, { label, getText, color, wrap })  -- frame, height
  W:ResetRow(parent, y, { label, buttons = { { text, onReset, confirm } } })
  W:TabPanel(parent, y, { tabs = { { key, label, build } }, getActive, onSelect })
      -- frame, height, api (GetContent(key), Show(key), Refresh())
  W:ListRows(parent, y, { items, rowH, columns, header, rowBuilder, rowUpdate })
      -- frame, height, api (Render(), GetRow(i), GetCount(), ColumnX(i))
  W:CheckGrid(parent, y, cols, entries, { maxSelected, limitTooltip, groups })
      -- entries may carry group, icon, help; maxSelected dims/blocks extras
  W:ColorGrid(parent, y, cols, entries, opts)  -- per-cell color swatches
  W:Slider(parent, y, cfg)       -- full-width slider, label above the track
  W:IconPicker(parent, level, getValue, setValue, { items, tooltip, size })
      -- icon button + searchable menu; items may carry .icon
  W:SpellIconItems({ id | { id, label }, ... }) -- items with spell textures
  W:MakeMenu(anchor, spec)       -- custom menu (see spec at its definition):
      -- item lists scroll past maxH/maxVisible, rows may set disabled /
      -- disabledTooltip, spec.dynamic + anchor._invalidateMenu() rebuild rows.
  W:BeginPage(owner) ... W:EndPage()  -- scope RegisterRefresh calls to a page;
      -- BeginPage also drops that page's old callbacks. W:RefreshPage(owner)
      -- refreshes one page, W:Refresh() still refreshes everything.
  W:IsCombatLocked() / W:InCombatLocked() -- true while the client is locked
  W:IsDisabled(cfg) -- explicit disabled OR cfg.blockInCombat in combat
  W.SkinFrame(frame, opts) -- factory bg + border on a host window
  W.Surface / W.Border -- raw draw helpers for custom chrome
  W.IsSecret(v) -- 12.x secret-value guard for custom measured text

SKIN
  ONE custom-drawn renderer (QFXUI blue/navy). Every control is drawn by this
  file with solid color textures (the dropdown chevron is a small square
  mosaic); Blizzard assets are only used for the color picker popup and the
  options gear texture.
    W:SetArrowTexture(path | false)  -- dropdown arrow (default: the V PNG in
                                    QFXWidgets\Media, drawn V if unavailable)
    W:SetSkin{ accent = {...}, controlBg = {...} }  -- override any token
    W:SetSkin()                                     -- restore stock skin
  Layout tokens live in W.Theme (row heights, paddings, zebra, label gap).

NOTES
  * No AceGUI, no external media.
  * English-first sizing: labels live in the left column, controls are
    right-anchored; long labels ellipsize and show the full text on hover
    (the clamp retries one frame later if the row was not sized yet).
  * Combat: pass blockInCombat = true on a cfg to keep it read-only while the
    client is locked (optional combatTooltip for the reason). Call W:Refresh()
    on PLAYER_REGEN_ENABLED so the control comes back when combat ends.
  * Pages: wrap the build in W:BeginPage(owner)/W:EndPage() and rebuilds stay
    leak-free (old callbacks of that owner are dropped first); W:Refresh(owner)
    / W:RefreshPage(owner) refresh only one page.
  * Menus sit on FULLSCREEN_DIALOG level 200 and close through a full-screen
    click catcher (deterministic; no GetMouseFocus guessing). Lists longer
    than maxH/maxVisible scroll with a self-drawn bar.
  * Singleton: if another copy already loaded, this file reuses it (version
    checked), so copying it into several addons never duplicates memory.
  * No SavedVariables, no events, no OnUpdate -- the factory only builds
    frames. All state stays in your addon's getValue/setValue closures.

TODO -- NOT IMPLEMENTED YET (build only when a page needs it)
  * self-drawn color picker popup (HSV / hex / recent / favorites) -- the color
    controls currently open Blizzard's ColorPickerFrame
  * self-drawn reset icon for the colorMode row (currently a text "R")
  * scroll page: smooth/clamped wheel only -- no keyboard (PgUp/PgDn) support
  * TripleRow / free-width column layouts
  * icon picker: atlas / item-icon sources (spell list works via SpellIconItems)
  * self-drawn tooltip skin (GameTooltip stays native)
  * ReorderList: internal scroll + auto-scroll while dragging long lists
  * ListRows: optional drag-reorder / row selection / built-in zebra restart
    (call W:ResetRows(listFrame) before api.Render() to restart stripes)
  * SearchableDropdown: arrow-key row navigation (Enter picks the first match)
============================================================================]]

local addonName, ns = ...

local VERSION = 20 -- bumped on API growth/fixes; older copies must not win
local F = rawget(_G, "QFXWidgets")

if type(F) == "table" and (tonumber(F.VERSION) or 0) >= VERSION then
    if ns then ns.QFXWidgets = F end
    return -- newer copy already loaded: reuse it (no duplicate tables/frames)
end

F = type(F) == "table" and F or {}
_G.QFXWidgets = F
F.VERSION = VERSION
if ns then ns.QFXWidgets = F end

local unpack = unpack or table.unpack
local floor = math.floor

-------------------------------------------------------------------------------
-- Theme (host must call :SetTheme before building rows to restyle)
-------------------------------------------------------------------------------
F.Theme = F.Theme or {
    font         = (rawget(_G, "STANDARD_TEXT_FONT") or "Fonts\\FRIZQT__.TTF"),
    rowH         = 32, -- compact rows
    sliderRowH   = 38, -- slider rows are taller: min/max labels sit under the track
    wideButtonH  = 34,
    headerH      = 28,
    labelSize    = 12,
    labelColor   = { 1, 1, 1, 0.9 },
    mutedColor   = { 1, 1, 1, 0.45 },
    sectionSize  = 11,
    sectionColor = { 0.05, 0.82, 0.62, 1 },
    lineColor    = { 1, 1, 1, 0.08 },
    pad          = 10,
    sidePad      = 10,
    rightPad     = 16,
    labelGap     = 8,  -- gap between the clamped label and its control
    trackWidth   = 110,
    controlH     = 20,
    -- alternating row background (nil entry = no zebra)
    rowBgOdd     = { 1, 1, 1, 0.02 },
    rowBgEven    = { 1, 1, 1, 0.01 },
}

function F:SetTheme(t)
    if type(t) ~= "table" then return end
    for k, v in pairs(t) do self.Theme[k] = v end
end

-------------------------------------------------------------------------------
-- Refresh registry
-------------------------------------------------------------------------------
F._refresh = F._refresh or {}

function F:RegisterRefresh(fn)
    if type(fn) ~= "function" then return end
    self._refresh[#self._refresh + 1] = { fn = fn, owner = owner or self._refreshScope }
end

-- Drop refresh callbacks: no argument clears everything, an owner clears only
-- that owner's callbacks (used by BeginPage on rebuild).
function F:ClearRefreshes(owner)
    if owner == nil then
        local l = self._refresh
        for i = #l, 1, -1 do l[i] = nil end
        return
    end
    local out = {}
    for i = 1, #self._refresh do
        local e = self._refresh[i]
        if e.owner ~= owner then out[#out + 1] = e end
    end
    self._refresh = out
end

-- Refresh(owner): no argument refreshes every page, an owner refreshes only
-- that page's callbacks. Errors are counted (F.lastRefreshError) instead of
-- being silently swallowed forever.
function F:Refresh(owner)
    local l = self._refresh
    for i = 1, #l do
        local e = l[i]
        if owner == nil or e.owner == owner then
            local ok, err = pcall(e.fn)
            if not ok then self.lastRefreshError = err end
        end
    end
end

-- Page scoping: call BeginPage(owner) before rebuilding a page and EndPage()
-- after; every RegisterRefresh inside gets that owner, old callbacks of the
-- same owner are dropped first, and RefreshPage(owner) refreshes just that page.
function F:BeginPage(owner)
    if owner == nil then return end
    self:ClearRefreshes(owner)
    self._refreshScope = owner
end

function F:EndPage()
    self._refreshScope = nil
end

function F:RefreshPage(owner)
    self:Refresh(owner)
end

-------------------------------------------------------------------------------
-- Small helpers
-------------------------------------------------------------------------------
local function Font(parent, size, r, g, b, a)
    local T = F.Theme
    local fs = parent:CreateFontString(nil, "OVERLAY")
    fs:SetFont(T.font, size or T.labelSize, "")
    if r then fs:SetTextColor(r, g, b, a or 1) end
    return fs
end
F.Font = Font

local function ContentWidth(parent)
    local T = F.Theme
    local w = parent and parent.GetWidth and parent:GetWidth() or 0
    w = (tonumber(w) or 0) - T.pad * 2
    if w < 120 then w = 120 end
    return w
end
F.ContentWidth = ContentWidth

local function AttachTooltip(target, title, text)
    if not (target and (title or text)) then return end
    target:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(title or "", 1, 1, 1)
        if text then GameTooltip:AddLine(text, 1, 1, 1, true) end
        GameTooltip:Show()
    end)
    target:SetScript("OnLeave", function() GameTooltip:Hide() end)
end
F.AttachTooltip = AttachTooltip

-------------------------------------------------------------------------------
-- Alternating row backgrounds (zebra) + label clamp
-------------------------------------------------------------------------------
F._rowCounts = F._rowCounts or setmetatable({}, { __mode = "k" })

-- Optional: call at page start so every page begins on the same stripe.
function F:ResetRows(parent)
    self._rowCounts[parent] = 0
end

local function RowBg(frame, parent, self)
    local count = (self._rowCounts[parent] or 0) + 1
    self._rowCounts[parent] = count
    local S = self.Skin
    local color
    if count % 2 == 1 then
        color = (S and S.rowBgOdd) or self.Theme.rowBgOdd
    else
        color = (S and S.rowBgEven) or self.Theme.rowBgEven
    end
    if not color then return end
    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(color[1], color[2], color[3], color[4] or 1)
end

-- 12.x secret values: any comparison/size made from one must be skipped.
local function IsSecret(v)
    return issecretvalue and issecretvalue(v) and true or false
end
F.IsSecret = IsSecret

-- Ellipsize `fs` to `maxW`: sets the text and returns the shown string, truncated.
local function TruncateToFit(fs, text, maxW)
    text = text or ""
    fs:SetText(text)
    if not (maxW and maxW > 0) then return text, false end
    if IsSecret(maxW) then return text, false end
    local w = fs:GetStringWidth()
    if IsSecret(w) then return text, false end
    if (w or 0) <= maxW then return text, false end
    local ell = "..."
    local lo, hi = 0, #text
    while lo < hi do
        local mid = floor((lo + hi + 1) / 2)
        fs:SetText(text:sub(1, mid) .. ell)
        local mw = fs:GetStringWidth()
        if IsSecret(mw) then break end
        if (mw or 0) <= maxW then lo = mid else hi = mid - 1 end
    end
    fs:SetText(text:sub(1, lo) .. ell)
    return text:sub(1, lo) .. ell, true
end
F.TruncateToFit = TruncateToFit

-- Bind a row label to its control's left edge, ellipsize on overflow, and show
-- the full text (plus the cfg tooltip) on hover. When the row is not sized yet
-- (width 0 right after building) the clamp is deferred one frame and retried,
-- so long / CJK labels always ellipsize instead of overrunning the control.
local function FitLabel(region, cfg, self)
    local label = region._label
    if not label then return end
    local T = self.Theme
    local control = region._control
    local gap = T.labelGap or 8
    label:SetJustifyH("LEFT")
    if label.SetWordWrap then label:SetWordWrap(false) end
    if label.SetMaxLines then label:SetMaxLines(1) end
    if control then
        label:SetPoint("RIGHT", control, "LEFT", -gap, 0)
    else
        label:SetPoint("RIGHT", region, "RIGHT", -(T.rightPad or 16), 0)
    end
    local full = cfg.text or ""
    local function Clamp()
        local w = label:GetWidth()
        if w == nil or w <= 0 then return false end
        local _, truncated = TruncateToFit(label, full, w)
        region._labelTruncated = truncated or nil
        local tip = cfg.tooltip
        if truncated then
            AttachTooltip(label, full, tip)
        elseif tip and tip ~= "" then
            AttachTooltip(label, nil, tip)
        end
        return true
    end
    if not Clamp() and C_Timer and C_Timer.After then
        C_Timer.After(0, Clamp)
    end
end

local function ResolveLabel(values, order, key)
    local v = values and values[key]
    if type(v) == "table" then return v.text or tostring(key) end
    if v ~= nil then return v end
    return tostring(key)
end
F.ResolveLabel = ResolveLabel

-- Dim + block a control (optional reason tooltip on the blocker).
-- Combat lockdown convention: cfg.blockInCombat keeps a control read-only in
-- combat (the standard cause of taint on protected writes). Hosts should also
-- call W:Refresh() on PLAYER_REGEN_ENABLED so the state updates when combat ends.
local function IsCombatLocked()
    return (InCombatLockdown and InCombatLockdown()) and true or false
end
F.IsCombatLocked = IsCombatLocked
F.InCombatLocked = IsCombatLocked

-- Is this cfg disabled right now (explicit disabled() or combat lockdown)?
local function ConfigDisabled(cfg)
    if not cfg then return false end
    if cfg.disabled and cfg.disabled() then return true end
    if cfg.blockInCombat and IsCombatLocked() then return true end
    return false
end
-- Is this cfg disabled right now? (method form for hosts: W:IsDisabled(cfg))
function F:IsDisabled(cfg)
    return ConfigDisabled(cfg)
end

local function ApplyDisabled(region, control, cfg)
    local disabled = cfg and cfg.disabled
    local tip = cfg and cfg.disabledTooltip
    local blockInCombat = cfg and cfg.blockInCombat
    if not disabled and not tip and not blockInCombat then return end
    local block
    local function Refresh()
        local off = (disabled and disabled() and true or false)
        local combat = blockInCombat and IsCombatLocked() or false
        if combat then off = true end
        if not block then
            block = CreateFrame("Frame", nil, region)
            block:SetAllPoints()
            block:SetFrameLevel(region:GetFrameLevel() + 12)
            block:EnableMouse(true)
            block:Hide()
            block:SetScript("OnEnter", function(self)
                local reason
                if combat then
                    reason = (cfg and cfg.combatTooltip) or "Not available in combat"
                elseif type(tip) == "function" then
                    reason = tip()
                else
                    reason = tip
                end
                if reason and reason ~= "" then
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    GameTooltip:SetText(reason, 1, 1, 1, 1, true)
                    GameTooltip:Show()
                end
            end)
            block:SetScript("OnLeave", function() GameTooltip:Hide() end)
        end
        if control and control.SetAlpha then control:SetAlpha(off and 0.35 or 1) end
        local extra = region and region._dimTargets
        if extra then
            for i = 1, #extra do
                local f = extra[i]
                if f and f.SetAlpha then f:SetAlpha(off and 0.35 or 1) end
            end
        end
        block:SetShown(off)
    end
    F:RegisterRefresh(Refresh)
    Refresh()
end

-------------------------------------------------------------------------------
-- Thin strips (1px borders/dividers) must never round to 0 and vanish at
-- fractional UI scales; disable pixel snapping on them (EUI does the same).
local function NoSnap(t)
    if t and t.SetSnapToPixelGrid then t:SetSnapToPixelGrid(false) end
    if t and t.SetTexelSnappingBias then t:SetTexelSnappingBias(0) end
    return t
end
F.NoSnap = NoSnap

-- SectionHeader / Note / Spacer / WideButton
-------------------------------------------------------------------------------
function F:SectionHeader(parent, text, y, opts)
    opts = opts or {}
    local T = self.Theme
    local h = opts.height or T.headerH
    local S = self.Skin
    local sc = (S and S.sectionText) or T.sectionColor
    local lc = (S and S.line) or T.lineColor
    self._rowCounts[parent] = 0 -- every section restarts the zebra stripes
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(ContentWidth(parent), h)
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT", T.pad, y)
    local label = Font(frame, T.sectionSize, sc[1], sc[2], sc[3], sc[4] or 1)
    label:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 8)
    label:SetText(text or "")
    frame._label = label
    local line = NoSnap(frame:CreateTexture(nil, "ARTWORK"))
    line:SetHeight(1)
    line:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    line:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    line:SetColorTexture(lc[1], lc[2], lc[3], lc[4] or 1)
    frame._refresh = function() end
    return frame, h
end

function F:Note(parent, y, text, opts)
    opts = opts or {}
    local T = self.Theme
    local S = self.Skin
    local mc = (S and S.textMuted) or T.mutedColor
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT", T.pad, y)
    local fs = Font(frame, opts.size or 12, mc[1], mc[2], mc[3], mc[4] or 1)
    fs:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    fs:SetPoint("RIGHT", frame, "RIGHT", 0, 0)
    fs:SetJustifyH("LEFT")
    if fs.SetWordWrap then fs:SetWordWrap(true) end
    fs:SetText(text or "")
    local h = (fs.GetStringHeight and fs:GetStringHeight()) or 16
    h = math.max(18, h + 6)
    frame:SetSize(ContentWidth(parent), h)
    frame._text = fs
    frame._refresh = function()
        if fs.SetText and frame._textFn then fs:SetText(frame._textFn() or "") end
    end
    if opts.textFn then
        frame._textFn = opts.textFn
        fs:SetText(opts.textFn() or "")
    end
    return y - h, frame -- second return is for hosts that keep row references
end

function F:Spacer(parent, y, height)
    return y - (height or 12)
end

function F:WideButton(parent, text, y, onClick, opts)
    opts = opts or {}
    local T = self.Theme
    local h = opts.height or T.wideButtonH or 34
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(ContentWidth(parent), h + 8)
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT", T.pad, y)
    RowBg(frame, parent, self)
    local S = self.Skin
    if S and S.wideButton then
        S.wideButton(frame, text or "", onClick, opts)
    end
    frame._refresh = function() end
    return frame, h + 8
end

-------------------------------------------------------------------------------
-- DualRow + slot controls
-------------------------------------------------------------------------------
local function BuildLabel(region, cfg)
    local T = F.Theme
    local label = Font(region, T.labelSize, T.labelColor[1], T.labelColor[2], T.labelColor[3], T.labelColor[4])
    label:SetPoint("LEFT", region, "LEFT", T.sidePad, 0)
    label:SetJustifyH("LEFT")
    if label.SetWordWrap then label:SetWordWrap(false) end
    if label.SetMaxLines then label:SetMaxLines(1) end
    label:SetText(cfg.text or "")
    region._label = label
    return label
end

-------------------------------------------------------------------------------
-- QFXUI skin: ALL controls are custom-drawn here (flat solid-color surfaces,
-- no external media, no Blizzard templates besides the vanilla chat arrow and
-- options gear textures). A host can override any token with
--   W:SetSkin{ accent = {...}, controlBg = {...}, rowControlH = 20, ... }
-- Everything not overridden keeps the defaults below.
-------------------------------------------------------------------------------
local QFXSkin = {
    name = "qfxui",

    -- surfaces
    controlBg    = { 0.070, 0.125, 0.195, 0.95 }, -- dark blue control fill
    controlBgHi  = { 0.110, 0.190, 0.285, 0.98 }, -- hover fill
    border       = { 0.150, 0.300, 0.480, 0.95 }, -- steel-blue frame (calmer)
    borderHi     = { 0.230, 0.440, 0.680, 1 },    -- hover / focus frame (calmer)
    trackBg      = { 0.080, 0.140, 0.215, 0.95 },
    trackFill    = { 0.290, 0.610, 0.980, 0.95 }, -- accent fill
    knob         = { 0.850, 0.920, 0.990, 1 },
    accent       = { 0.290, 0.610, 0.980, 1 },    -- #4a9cfa
    accentDim    = { 0.290, 0.610, 0.980, 0.35 },
    selected     = { 0.290, 0.610, 0.980, 0.20 }, -- selected row wash
    danger       = { 1.00, 0.35, 0.35, 1 },
    good         = { 0.30, 0.90, 0.45, 1 },
    buttonBg     = { 0.080, 0.150, 0.230, 0.95 },
    buttonBgHi   = { 0.120, 0.220, 0.330, 1 },
    buttonBorder = { 0.170, 0.330, 0.510, 0.95 },
    text         = { 0.900, 0.945, 0.985, 1 },
    textMuted    = { 0.520, 0.660, 0.800, 1 },
    menuBg       = { 0.045, 0.080, 0.125, 0.98 },
    rowHover     = { 0.290, 0.610, 0.980, 0.14 },
    sectionText  = { 0.620, 0.830, 1.00, 1 },     -- section headers / category text
    line         = { 0.180, 0.360, 0.560, 0.55 }, -- separator line

    rowBgOdd     = { 0.290, 0.610, 0.980, 0.045 }, -- zebra: subtle blue wash
    rowBgEven    = { 0.290, 0.610, 0.980, 0.015 },

    -- sizes (compact)
    textSize    = 12,
    menuRowH    = 20,
    toggleW     = 30,
    toggleH     = 16,
    togglePad   = 2,
    toggleAnim  = true,
    toggleAnimDur = 0.075,
    -- OFF must read as a switch: a near-background track looked like a bare block
    toggleTrackOff = { 0.280, 0.330, 0.420, 0.70 },
    toggleTrackOn  = { 0.130, 0.270, 0.420, 0.95 }, -- same muted blue as selectedFill
    toggleKnobOff  = { 1.000, 1.000, 1.000, 0.55 },
    toggleKnobOn   = { 1.000, 1.000, 1.000, 1.00 },
    knobSize    = 12,
    trackH      = 3,
    thumbW      = 8,
    thumbH      = 14,
    valueBoxW   = 44,
    rowControlH = 20,
    buttonH     = 20,
    buttonMinW  = 88,
    stepperW    = 18, -- slider +/- column (flush right of the value box)
    stepperGap  = 0,  -- gap between the value box and the stepper column
    segMinW     = 38, -- segmented pill: min width / text padding / gap
    segPadX     = 16,
    segGap      = 1,
    -- selected fills: a muted blue instead of a full-bright accent wash
    selectedFill = { 0.130, 0.270, 0.420, 0.95 },
    selectedLine = { 0.230, 0.440, 0.680, 1 }, -- tab underline / thin selected lines
    selectedText = { 0.920, 0.960, 1.000, 1 },
    segOnText   = { 0.920, 0.960, 1.000, 1 }, -- text on the selected pill
}

local function QfxSurface(parent, layer, sub, c)
    local t = parent:CreateTexture(nil, layer or "BACKGROUND", nil, sub or 0)
    if c then t:SetColorTexture(c[1], c[2], c[3], c[4] or 1) else t:SetColorTexture(0, 0, 0, 0) end
    return t
end

local function QfxBorder(parent, level, c, alpha, size)
    local f = CreateFrame("Frame", nil, parent)
    f:SetAllPoints()
    f:SetFrameLevel((level or parent:GetFrameLevel()) + 5)
    local bs = size or 1
    -- EUI-style pixel sizing: express the border in PHYSICAL pixels at the
    -- frame's effective scale, so a 1px border never rounds away or gets shaved
    -- at fractional UI scales / positions.
    local function PixelSize()
        local es = 1
        if f.GetEffectiveScale then
            local ok, v = pcall(f.GetEffectiveScale, f)
            if ok and type(v) == "number" and v > 0 then es = v end
        end
        local one = 1 / es
        return math.max(one, math.floor(bs + 0.5) * one)
    end
    local s = PixelSize()
    local edges = {}
    local function Edge()
        local t = f:CreateTexture(nil, "OVERLAY")
        if t.SetSnapToPixelGrid then t:SetSnapToPixelGrid(false) end
        if t.SetTexelSnappingBias then t:SetTexelSnappingBias(0) end
        edges[#edges + 1] = t
        return t
    end
    -- every strip sits INSIDE the frame by s, so the border is never clipped
    -- by the frame's own edges and the corners fuse seamlessly
    local top = Edge()
    top:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -s)
    top:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, -s)
    top:SetHeight(s)
    local bottom = Edge()
    bottom:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, s)
    bottom:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, s)
    bottom:SetHeight(s)
    local left = Edge()
    left:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -s)
    left:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, s)
    left:SetWidth(s)
    local right = Edge()
    right:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, -s)
    right:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, s)
    right:SetWidth(s)

    local function SetBorderColor(color, a)
        local aa = (color[4] or 1) * (a or 1)
        for i = 1, #edges do
            edges[i]:SetColorTexture(color[1], color[2], color[3], aa)
        end
    end
    if c then SetBorderColor(c, alpha) end
    f._setBorder = SetBorderColor
    return f
end

-- Drawing helpers for host windows (panels, nav buttons, custom chrome).
F.Surface = QfxSurface
F.Border = QfxBorder

-- W:SkinFrame(frame, opts): factory background + border on an existing frame
-- (replaces SetBackdrop for host windows). opts = { bg, border, alpha,
-- borderSize, inset }. Uses the active skin tokens when a color is omitted.
function F:SkinFrame(frame, opts)
    opts = opts or {}
    local S = self:Tokens()
    local tex = QfxSurface(frame, "BACKGROUND", 0, opts.bg or S.menuBg)
    if opts.inset then
        tex:SetPoint("TOPLEFT", frame, "TOPLEFT", opts.inset, -opts.inset)
        tex:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -opts.inset, opts.inset)
    else
        tex:SetAllPoints()
    end
    QfxBorder(frame, frame:GetFrameLevel(), opts.border or S.border, opts.alpha or 1, opts.borderSize or 1)
    frame._skinBg = tex
    return frame
end

local function IsDescendantOf(frame, ancestor)
    local f, guard = frame, 0
    while f and guard < 24 do
        if f == ancestor then return true end
        f = f:GetParent()
        guard = guard + 1
    end
    return false
end

-- Shared custom menu. spec = { items (table|function), width, maxH, maxVisible,
-- multi, dynamic, checked(key), disabled(key), disabledTooltip(key),
-- labelFor(key), onPick(key), refresh() }. Long item lists scroll (self-drawn
-- bar, wheel + thumb drag); items may disable themselves (item.disabled /
-- item.disabledTooltip); the menu matches the dropdown's scale and sits on the
-- FULLSCREEN_DIALOG strata. Returns menu, refresh. dd._invalidateMenu()
-- rebuilds the rows from spec.items (use it with spec.dynamic for lists that
-- change at runtime).
-- Shared custom menu. spec = { items (table|function), width, maxH, maxVisible,
-- multi, dynamic, checked(key), disabled(key), disabledTooltip(key),
-- labelFor(key), onPick(key), refresh() }. Lists that fit render directly in
-- the menu (like the pre-scroll version); long lists switch to a ScrollFrame
-- with a self-drawn bar, wheel and thumb drag. Items may disable themselves
-- (item.disabled / item.disabledTooltip). Returns menu, refresh.
-- dd._invalidateMenu() rebuilds the rows from spec.items.
local function MakeQfxMenu(dd, S, spec)
    local rowH = S.menuRowH
    local pad = 4
    local menu = CreateFrame("Frame", nil, UIParent)
    menu:SetFrameStrata("FULLSCREEN_DIALOG")
    if menu.SetFrameLevel then menu:SetFrameLevel(200) end
    if menu.SetClampedToScreen then menu:SetClampedToScreen(true) end
    menu:EnableMouse(true)
    menu:EnableMouseWheel(true)
    menu:Hide()

    local bg = QfxSurface(menu, "BACKGROUND", 0, S.menuBg)
    bg:SetAllPoints()
    QfxBorder(menu, menu:GetFrameLevel(), S.border, 1, 1)

    local rows = {}
    local maxH = spec.maxH or ((spec.maxVisible or 14) * rowH + pad * 2)
    local contentH, viewH, offset = 0, 0, 0
    local scrollMode = false
    local viewport, content, bar, thumb

    local function Items()
        local it = spec.items
        if type(it) == "function" then it = it() end
        return it or {}
    end
    local function ItemDisabled(item, key)
        if spec.disabled and spec.disabled(key) then return true end
        local d = item.disabled
        if type(d) == "function" then return d(key) and true or false end
        return d and true or false
    end
    local function ItemDisabledTip(item, key)
        local t = item.disabledTooltip
        if type(t) == "function" then return t(key) end
        return t or spec.disabledTooltip
    end

    local Layout -- forward declaration (used by the scrollbar thumb below)

    -- long lists get a viewport + self-drawn scrollbar (created on first need)
    local function EnsureScrollUi()
        if viewport then return end
        viewport = CreateFrame("ScrollFrame", nil, menu)
        viewport:SetPoint("TOPLEFT", menu, "TOPLEFT", pad, -pad)
        viewport:SetPoint("BOTTOMRIGHT", menu, "BOTTOMRIGHT", -(pad + 6), pad)
        content = CreateFrame("Frame", nil, viewport)
        if viewport.SetScrollChild then viewport:SetScrollChild(content) end
        bar = CreateFrame("Frame", nil, menu)
        bar:SetWidth(4)
        bar:SetPoint("TOPRIGHT", menu, "TOPRIGHT", -pad, -pad)
        bar:SetPoint("BOTTOMRIGHT", menu, "BOTTOMRIGHT", -pad, pad)
        local barBg = QfxSurface(bar, "BACKGROUND", 0, S.controlBg)
        barBg:SetAllPoints()
        bar:Hide()
        thumb = CreateFrame("Button", nil, bar)
        thumb:SetWidth(4)
        local thumbTex = QfxSurface(thumb, "ARTWORK", 0, S.border)
        thumbTex:SetAllPoints()
        thumb:SetScript("OnEnter", function() thumbTex:SetColorTexture(S.borderHi[1], S.borderHi[2], S.borderHi[3], S.borderHi[4] or 1) end)
        thumb:SetScript("OnLeave", function() thumbTex:SetColorTexture(S.border[1], S.border[2], S.border[3], S.border[4] or 1) end)
        local dragging, dragY, dragOffset
        thumb:SetScript("OnMouseDown", function(_, button)
            if button ~= "LeftButton" or contentH <= viewH then return end
            dragging, dragY, dragOffset = true, select(2, GetCursorPosition()), offset
        end)
        thumb:SetScript("OnUpdate", function()
            if not dragging then return end
            if IsMouseButtonDown and not IsMouseButtonDown("LeftButton") then dragging = false return end
            local _, cy = GetCursorPosition()
            local scale = thumb:GetEffectiveScale() or 1
            local travel = viewH - (thumb:GetHeight() or 0)
            if travel <= 0 then return end
            local maxOff = math.max(0, contentH - viewH)
            offset = floor(math.max(0, math.min(maxOff, dragOffset + ((cy - dragY) / scale) * (maxOff / travel))) + 0.5)
            if viewport.SetVerticalScroll then viewport:SetVerticalScroll(offset) end
            Layout()
        end)
        thumb:SetScript("OnMouseUp", function() dragging = false end)
        thumb:SetScript("OnHide", function() dragging = false end)
    end

    function Layout()
        local width = spec.width or 210
        if bar then bar:SetShown(scrollMode) end
        local h = (contentH > 0 and contentH or rowH) + pad * 2
        if h > maxH then h = maxH end
        menu:SetSize(width, h)
        viewH = h - pad * 2
        local maxOff = math.max(0, contentH - viewH)
        if offset > maxOff then offset = maxOff end
        if offset < 0 then offset = 0 end
        if scrollMode and content then
            content:SetSize(math.max(1, width - pad * 2 - 6), math.max(1, contentH))
            if viewport.SetVerticalScroll then viewport:SetVerticalScroll(offset) end
        end
        local container = scrollMode and content or menu
        local inset = scrollMode and 0 or pad
        for i = 1, #rows do
            local r = rows[i]
            r:ClearAllPoints()
            r:SetPoint("TOPLEFT", container, "TOPLEFT", inset, -(i - 1) * rowH - inset)
            r:SetPoint("TOPRIGHT", container, "TOPRIGHT", -inset, -(i - 1) * rowH - inset)
        end
        if scrollMode and thumb then
            local thumbH = math.max(20, viewH * (viewH / contentH))
            thumb:SetHeight(math.min(viewH, thumbH))
            local travel = math.max(0, viewH - thumb:GetHeight())
            local ratio = maxOff > 0 and (offset / maxOff) or 0
            thumb:ClearAllPoints()
            thumb:SetPoint("TOPRIGHT", bar, "TOPRIGHT", 0, -travel * ratio)
        end
    end

    local function Build()
        local items = Items()
        scrollMode = (#items * rowH + pad * 2) > maxH
        if scrollMode then EnsureScrollUi() end
        local container = scrollMode and content or menu
        for i = #items + 1, #rows do
            rows[i]:Hide()
            rows[i] = nil
        end
        for i = 1, #items do
            local item = items[i]
            local row = rows[i]
            if not row then
                row = CreateFrame("Button", nil, container)
                row:SetHeight(rowH)
                local hl = row:CreateTexture(nil, "HIGHLIGHT")
                hl:SetAllPoints()
                hl:SetColorTexture(S.rowHover[1], S.rowHover[2], S.rowHover[3], S.rowHover[4])
                local check = QfxSurface(row, "ARTWORK", 0, S.accent)
                check:SetSize(10, 10)
                check:SetPoint("LEFT", row, "LEFT", 8, 0)
                local icon = row:CreateTexture(nil, "ARTWORK")
                icon:SetSize(14, 14)
                icon:SetPoint("LEFT", check, "RIGHT", 6, 0)
                icon:Hide()
                local lbl = Font(row, S.textSize, S.text[1], S.text[2], S.text[3], S.text[4])
                lbl:SetPoint("LEFT", check, "RIGHT", 8, 0)
                lbl:SetPoint("RIGHT", row, "RIGHT", -8, 0)
                lbl:SetJustifyH("LEFT")
                if lbl.SetWordWrap then lbl:SetWordWrap(false) end
                if lbl.SetMaxLines then lbl:SetMaxLines(1) end
                row._hl, row._check, row._label = hl, check, lbl
                row._icon = icon
                row:SetScript("OnClick", function(self2)
                    if self2._disabledNow then return end
                    if spec.onPick then spec.onPick(self2._key) end
                    if not spec.multi then menu:Hide() end
                    if spec.refresh then spec.refresh() end
                end)
                row:SetScript("OnEnter", function(self2)
                    local it = self2._item
                    if not it then return end
                    local tip = it.tooltip
                    if self2._disabledNow then tip = ItemDisabledTip(it, self2._key) or tip end
                    if tip then
                        GameTooltip:SetOwner(self2, "ANCHOR_RIGHT")
                        GameTooltip:SetText(it.label or tostring(self2._key), 1, 1, 1)
                        GameTooltip:AddLine(tip, 1, 1, 1, true)
                        GameTooltip:Show()
                    end
                end)
                row:SetScript("OnLeave", function() GameTooltip:Hide() end)
                rows[i] = row
            elseif row:GetParent() ~= container then
                row:SetParent(container)
            end
            row._key, row._item = item.key, item
            row._label:SetText(item.label or tostring(item.key))
            row:Show()
        end
        contentH = #items * rowH
        offset = 0
        Layout()
    end

    menu:SetScript("OnMouseWheel", function(_, delta)
        if not scrollMode then return end
        local maxOff = math.max(0, contentH - viewH)
        if maxOff <= 0 then return end
        offset = math.max(0, math.min(maxOff, offset - delta * 24))
        if viewport.SetVerticalScroll then viewport:SetVerticalScroll(offset) end
        Layout()
    end)

    function spec.refresh()
        for i = 1, #rows do
            local r = rows[i]
            local item = r._item
            if item then
                local dis = ItemDisabled(item, r._key)
                r._disabledNow = dis
                r:SetAlpha(dis and 0.4 or 1)
                if spec.checked then
                    r._check:SetShown(spec.checked(r._key) and true or false)
                else
                    r._check:Hide()
                end
                if spec.labelFor then r._label:SetText(spec.labelFor(r._key) or "") end
            end
        end
    end

    Build()
    spec.refresh()

    local function Close()
        if menu:IsShown() then menu:Hide() end
    end
    -- Outside-click catcher: a full-screen frame one level BELOW the menu.
    -- Deterministic (no GetMouseFocus guessing) and it cannot steal the menu's
    -- own clicks because the menu sits at a higher frame level.
    local catcher = CreateFrame("Frame", nil, UIParent)
    catcher:SetAllPoints()
    catcher:SetFrameStrata("FULLSCREEN_DIALOG")
    if catcher.SetFrameLevel then catcher:SetFrameLevel(190) end
    catcher:EnableMouse(true)
    catcher:Hide()
    catcher:SetScript("OnMouseDown", function() menu:Hide() end)
    menu:HookScript("OnHide", function() catcher:Hide() end)

    local function Open()
        if spec.dynamic then Build() end
        spec.refresh()
        Layout()
        menu:ClearAllPoints()
        menu:SetPoint("TOPLEFT", dd, "BOTTOMLEFT", 0, -2)
        catcher:Show()
        menu:Show()
    end

    menu._rows = rows
    menu._bar, menu._thumb, menu._viewport, menu._content = bar, thumb, viewport, content
    menu._catcher = catcher
    dd._menu = menu
    dd._openMenu = Open
    dd._closeMenu = Close
    dd._invalidateMenu = Build
    dd._refreshMenu = spec.refresh
    return menu, spec.refresh
end

-- Public custom menu (for pickers the factory does not cover): F:MakeMenu(anchor,
-- spec) -> menu, refresh. spec = { items (table|function), width, maxH,
-- maxVisible, multi, dynamic, checked(key), disabled(key), disabledTooltip(key),
-- labelFor(key), onPick(key), refresh() }. anchor._invalidateMenu() rebuilds.
function F:MakeMenu(anchor, spec)
    return MakeQfxMenu(anchor, self:Tokens(), spec or {})
end

-- Self-drawn downward chevron (a V): two 1px-stepped strokes of bar segments,
-- no media and no rotation, with pixel snapping disabled so the 2px strokes
-- stay solid at fractional UI scales.
local function MakeChevron(parent, w, color)
    local frame = CreateFrame("Frame", nil, parent)
    local width = math.max(8, math.floor(w or 10) + 1)
    local rows, step = 4, 2
    local stroke = 3
    frame:SetSize(width, rows * step)
    local function Bar(x, y, bw)
        local t = frame:CreateTexture(nil, "ARTWORK")
        if t.SetSnapToPixelGrid then t:SetSnapToPixelGrid(false) end
        if t.SetTexelSnappingBias then t:SetTexelSnappingBias(0) end
        t:SetColorTexture(color[1], color[2], color[3], color[4] or 1)
        t:SetSize(bw, step)
        t:SetPoint("TOPLEFT", frame, "TOPLEFT", x, -y)
    end
    for r = 0, rows - 1 do
        local y = r * step
        Bar(r, y, stroke)
        Bar(width - stroke - r, y, stroke)
    end
    return frame
end

-- Dropdown arrow: the clean V PNG shipped in QFXWidgets\Media\ when the addon
-- folder is installed; otherwise a self-drawn V fallback (single-file copies).
-- W:SetArrowTexture(path) overrides, W:SetArrowTexture(false) forces the drawn
-- one. Returns (arrowObject, labelRightInset).
local function MakeDropdownArrow(parent, S)
    local path = F.ArrowTexture
    if path == nil then
        local exists = false
        if C_AddOns and C_AddOns.DoesAddOnExist then
            exists = C_AddOns.DoesAddOnExist("QFXWidgets") and true or false
        elseif IsAddOnLoaded then
            exists = IsAddOnLoaded("QFXWidgets") ~= nil
        end
        path = exists and "Interface\\AddOns\\QFXWidgets\\Media\\arrow-down.png" or false
        F.ArrowTexture = path
    end
    local tint = S.textMuted or S.text
    if path then
        local tex = parent:CreateTexture(nil, "ARTWORK")
        if tex.SetSnapToPixelGrid then tex:SetSnapToPixelGrid(false) end
        if tex.SetTexelSnappingBias then tex:SetTexelSnappingBias(0) end
        tex:SetTexture(path)
        tex:SetSize(26, 26)
        tex:SetPoint("RIGHT", parent, "RIGHT", -2, 0)
        if tex.SetVertexColor then tex:SetVertexColor(tint[1], tint[2], tint[3], 1) end
        return tex, 22
    end
    local chev = MakeChevron(parent, 10, tint)
    chev:SetPoint("RIGHT", parent, "RIGHT", -6, 0)
    return chev, 19
end

function F:SetArrowTexture(path)
    self.ArrowTexture = path == false and false or path
    return self.ArrowTexture
end

local function MakeQfxDropdownButton(region, S, width)
    local btn = CreateFrame("Button", nil, region)
    btn:SetSize(width, S.rowControlH)
    btn:SetPoint("RIGHT", region, "RIGHT", -F.Theme.rightPad, 0)
    local bg = QfxSurface(btn, "BACKGROUND", 0, S.controlBg)
    bg:SetAllPoints()
    local brd = QfxBorder(btn, btn:GetFrameLevel(), S.border, 1, 1)
    local lbl = Font(btn, S.textSize, S.text[1], S.text[2], S.text[3], S.text[4])
    local arrow, labelInset = MakeDropdownArrow(btn, S)
    lbl:SetPoint("LEFT", btn, "LEFT", 8, 0)
    lbl:SetPoint("RIGHT", btn, "RIGHT", -(labelInset or 20), 0)
    lbl:SetJustifyH("LEFT")
    if lbl.SetWordWrap then lbl:SetWordWrap(false) end
    if lbl.SetMaxLines then lbl:SetMaxLines(1) end
    btn._bg, btn._label, btn._brd, btn._chevron = bg, lbl, brd, arrow
    btn:SetScript("OnEnter", function()
        bg:SetColorTexture(S.controlBgHi[1], S.controlBgHi[2], S.controlBgHi[3], S.controlBgHi[4])
        brd._setBorder(S.borderHi or S.border)
    end)
    btn:SetScript("OnLeave", function()
        bg:SetColorTexture(S.controlBg[1], S.controlBg[2], S.controlBg[3], S.controlBg[4])
        brd._setBorder(S.border)
    end)
    return btn
end

-- Borderless EUI-style switch: a track + a square knob with a 2px pad, colour
-- lerp and a short slide animation. No outline (an outline made the two states
-- look different in size and hid the knob).
local function QfxToggle(region, frame, cfg)
    local S = F.Skin
    local btn = CreateFrame("Button", nil, region)
    local TW, TH = S.toggleW, S.toggleH
    btn:SetSize(TW, TH)
    btn:SetPoint("RIGHT", region, "RIGHT", -F.Theme.rightPad, 0)
    local track = QfxSurface(btn, "BACKGROUND", 0, S.trackBg)
    track:SetAllPoints()
    local pad = S.togglePad or 2
    local knob = btn:CreateTexture(nil, "ARTWORK", nil, 1)
    if knob.SetSnapToPixelGrid then knob:SetSnapToPixelGrid(false) end
    if knob.SetTexelSnappingBias then knob:SetTexelSnappingBias(0) end
    local knobSize = math.max(6, TH - pad * 2)
    local offT = S.toggleTrackOff or S.trackBg
    local onT = S.toggleTrackOn or S.accent
    local offK = S.toggleKnobOff or S.knob
    local onK = S.toggleKnobOn or S.knob
    local function Lerp(a, b, p) return a + (b - a) * p end
    local function Apply(p)
        local x = Lerp(pad, TW - pad - knobSize, p)
        knob:ClearAllPoints()
        knob:SetPoint("TOPLEFT", btn, "TOPLEFT", x, -pad)
        knob:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", x, pad)
        knob:SetWidth(knobSize)
        track:SetColorTexture(
            Lerp(offT[1], onT[1], p), Lerp(offT[2], onT[2], p),
            Lerp(offT[3], onT[3], p), Lerp(offT[4] or 1, onT[4] or 1, p))
        knob:SetColorTexture(
            Lerp(offK[1], onK[1], p), Lerp(offK[2], onK[2], p),
            Lerp(offK[3], onK[3], p), Lerp(offK[4] or 1, onK[4] or 1, p))
    end
    local progress = (cfg.getValue and cfg.getValue()) and 1 or 0
    local target = progress
    local function Snap()
        local on = cfg.getValue and cfg.getValue() and true or false
        if btn._state == on then return end
        btn._state = on
        progress, target = on and 1 or 0, on and 1 or 0
        btn:SetScript("OnUpdate", nil)
        Apply(progress)
    end
    Snap()
    btn._qfx, btn._track, btn._knob = "toggle", track, knob
    btn:SetScript("OnClick", function()
        local on = not (cfg.getValue and cfg.getValue())
        if cfg.setValue then cfg.setValue(on and true or false) end
        btn._state = on
        target = on and 1 or 0
        if S.toggleAnim == false then
            progress = target
            Apply(progress)
            return
        end
        local dur = S.toggleAnimDur or 0.075
        btn._acc = 0
        btn:SetScript("OnUpdate", function(self2, elapsed)
            self2._acc = (self2._acc or 0) + elapsed
            local p = math.min(1, self2._acc / dur)
            progress = (target == 1) and p or (1 - p)
            Apply(progress)
            if p >= 1 then self2:SetScript("OnUpdate", nil) end
        end)
    end)
    AttachTooltip(btn, cfg.text, cfg.tooltip)
    region._control = btn
    ApplyDisabled(region, btn, cfg)
    F:RegisterRefresh(Snap)
    return btn
end

local function QfxSlider(region, frame, cfg)
    local S = F.Skin
    local T = F.Theme
    local minV = tonumber(cfg.min) or 0
    local maxV = tonumber(cfg.max) or 100
    local step = tonumber(cfg.step) or 1
    local trackW = cfg.trackWidth or T.trackWidth
    local suffix = cfg.valueSuffix or ""
    local withSteppers = cfg.steppers ~= false
    local stepperW = withSteppers and (tonumber(cfg.stepperWidth) or S.stepperW or 13) or 0

    local box = CreateFrame("EditBox", nil, region)
    box:SetSize(S.valueBoxW, S.rowControlH)
    box:SetPoint("RIGHT", region, "RIGHT", -(T.rightPad + (stepperW > 0 and (stepperW + (S.stepperGap or 2)) or 0)), 0)
    box:SetAutoFocus(false)
    local boxBg = QfxSurface(box, "BACKGROUND", 0, S.controlBg)
    boxBg:SetAllPoints()
    local boxBrd = QfxBorder(box, box:GetFrameLevel(), S.border, 1, 1)
    box:SetFont(T.font, S.textSize, "")
    box:SetTextColor(S.text[1], S.text[2], S.text[3], S.text[4])
    box:SetJustifyH("CENTER")
    box:SetTextInsets(2, 2, 0, 0)
    box._qfx = "valueBox"

    local slider = CreateFrame("Slider", nil, region)
    slider:SetOrientation("HORIZONTAL")
    slider:SetSize(trackW, S.rowControlH)
    slider:SetPoint("RIGHT", box, "LEFT", -8, 0)
    slider:SetMinMaxValues(minV, maxV)
    slider:SetValueStep(step)
    if slider.SetObeyStepOnDrag then slider:SetObeyStepOnDrag(true) end

    local track = QfxSurface(slider, "BACKGROUND", 0, S.trackBg)
    track:SetHeight(S.trackH)
    track:SetPoint("LEFT", slider, "LEFT", 0, 0)
    track:SetPoint("RIGHT", slider, "RIGHT", 0, 0)
    track:SetPoint("CENTER", slider, "CENTER", 0, 0)
    local fill = QfxSurface(slider, "ARTWORK", 0, S.trackFill)
    fill:SetHeight(S.trackH)
    fill:SetPoint("LEFT", slider, "LEFT", 0, 0)
    fill:SetPoint("CENTER", slider, "CENTER", 0, 0)

    local thumb = slider:CreateTexture(nil, "ARTWORK", nil, 1)
    thumb:SetColorTexture(S.knob[1], S.knob[2], S.knob[3], S.knob[4])
    thumb:SetSize(S.thumbW, S.thumbH)
    slider:SetThumbTexture(thumb)

    local low = Font(region, 10, S.textMuted[1], S.textMuted[2], S.textMuted[3], S.textMuted[4])
    low:SetPoint("TOPLEFT", slider, "BOTTOMLEFT", 0, -1)
    low:SetText(tostring(minV))
    local high = Font(region, 10, S.textMuted[1], S.textMuted[2], S.textMuted[3], S.textMuted[4])
    high:SetPoint("TOPRIGHT", slider, "BOTTOMRIGHT", 0, -1)
    high:SetText(tostring(maxV))

    local function Format(v)
        if IsSecret(v) then return "" end
        if step % 1 ~= 0 then
            local decimals = (step < 0.1) and 2 or 1
            return string.format("%." .. decimals .. "f", v) .. suffix
        end
        return tostring(v) .. suffix
    end
    -- snap anchored at min (a step like 2 with min 1 must still reach 1, 3, 5...)
    local function Snap(v)
        v = tonumber(v) or minV
        if step > 0 then v = minV + floor((v - minV) / step + 0.5) * step end
        if v < minV then v = minV elseif v > maxV then v = maxV end
        return v
    end
    local function Read()
        local v = cfg.getValue and cfg.getValue() or minV
        v = tonumber(v) or minV
        if v < minV then v = minV elseif v > maxV then v = maxV end
        return v
    end
    local function Render(v)
        local ratio = (maxV > minV) and ((v - minV) / (maxV - minV)) or 0
        if ratio < 0 then ratio = 0 elseif ratio > 1 then ratio = 1 end
        -- whole-pixel fill width (EUI does the same): a fractional width makes
        -- the fill edge shimmer while dragging
        fill:SetWidth(math.max(1, floor(trackW * ratio + 0.5)))
        if not box:HasFocus() then box:SetText(Format(v)) end
    end
    local function Push(v)
        if cfg.setValue then cfg.setValue(v) end
    end

    -- +/- steppers: stacked flush right of the value box (the pair is exactly
    -- as tall as the box); nudge by one step, clamped, dimmed at both ends
    local upBtn, downBtn
    if stepperW > 0 then
        local btnH = floor(S.rowControlH / 2)
        local function MakeStepper(glyph, dir)
            local b = CreateFrame("Button", nil, region)
            b:SetSize(stepperW, btnH)
            -- the +/- pair covers exactly the value box's height, flush right
            if dir > 0 then
                b:SetPoint("TOPLEFT", box, "TOPRIGHT", 0, 0)
            else
                b:SetPoint("BOTTOMLEFT", box, "BOTTOMRIGHT", 0, 0)
            end
            -- borderless (the buttons are tiny; an outline ate the glyph)
            local bg = QfxSurface(b, "BACKGROUND", 0, S.controlBg)
            bg:SetAllPoints()
            local fs = Font(b, math.max(12, S.textSize), S.text[1], S.text[2], S.text[3], S.text[4])
            fs:SetPoint("CENTER", b, "CENTER", 0, 0)
            fs:SetText(glyph)
            b._step = dir
            b._dim = fs
            local function SetBg(c)
                bg:SetColorTexture(c[1], c[2], c[3], c[4] or 1)
            end
            b:SetScript("OnEnter", function()
                if not ConfigDisabled(cfg) then SetBg(S.controlBgHi) end
            end)
            b:SetScript("OnLeave", function() SetBg(S.controlBg) end)
            b:SetScript("OnMouseDown", function() if not ConfigDisabled(cfg) then SetBg(S.controlBgHi) end end)
            b:SetScript("OnMouseUp", function() SetBg(S.controlBg) end)
            b:SetScript("OnClick", function()
                if ConfigDisabled(cfg) then return end
                local v = Snap(Read() + dir * step)
                slider._updating = true
                slider:SetValue(v)
                slider._updating = nil
                Render(v)
                Push(v)
            end)
            return b
        end
        upBtn = MakeStepper("+", 1)
        downBtn = MakeStepper("-", -1)
        region._dimTargets = { upBtn, downBtn }
    end
    local function SyncSteppers(v)
        if upBtn then upBtn._dim:SetTextColor((v >= maxV) and S.textMuted[1] or S.text[1], (v >= maxV) and S.textMuted[2] or S.text[2], (v >= maxV) and S.textMuted[3] or S.text[3], 1) end
        if downBtn then downBtn._dim:SetTextColor((v <= minV) and S.textMuted[1] or S.text[1], (v <= minV) and S.textMuted[2] or S.text[2], (v <= minV) and S.textMuted[3] or S.text[3], 1) end
    end

    slider._updating = true
    slider:SetValue(Read())
    slider._updating = nil
    Render(Read())
    SyncSteppers(Read())

    -- Drag handling (EUI-style): while dragging, only the visual follows; on
    -- release the value is committed once and the page refreshes once, so the
    -- host never gets a sweep per drag tick.
    local pageOwner = F._refreshScope
    slider:SetScript("OnMouseDown", function() slider._dragging = true end)
    slider:SetScript("OnHide", function() slider._dragging = false end)
    slider:SetScript("OnUpdate", function()
        if not slider._dragging then return end
        if IsMouseButtonDown and not IsMouseButtonDown("LeftButton") then
            -- the button was released outside (modifier stole the event)
            slider._dragging = false
            local v = Snap(Read())
            Render(v)
            SyncSteppers(v)
            Push(v)
            if pageOwner then F:Refresh(pageOwner) end
        end
    end)
    slider:SetScript("OnMouseUp", function()
        if not slider._dragging then return end
        slider._dragging = false
        local v = Snap(Read())
        slider._updating = true
        slider:SetValue(v)
        slider._updating = nil
        Render(v)
        SyncSteppers(v)
        Push(v)                              -- final commit once
        if pageOwner then F:Refresh(pageOwner) end -- one page refresh, not per tick
    end)
    slider:SetScript("OnValueChanged", function(_, value)
        if slider._updating then return end
        local v = Snap(value)
        Render(v)
        Push(v)
    end)

    local function CommitBox()
        local v = Snap(tonumber(box:GetText()) or Read())
        slider._updating = true
        slider:SetValue(v)
        slider._updating = nil
        Render(v)
        SyncSteppers(v)
        Push(v)
    end
    box:SetScript("OnEnterPressed", function(self)
        CommitBox()
        self:ClearFocus()
    end)
    box:SetScript("OnEscapePressed", function(self)
        Render(Read())
        SyncSteppers(Read())
        self:ClearFocus()
    end)
    box:SetScript("OnEditFocusGained", function(self)
        boxBrd._setBorder(S.borderHi or S.border)
        if self.HighlightText then self:HighlightText() end
    end)
    box:SetScript("OnEditFocusLost", function()
        boxBrd._setBorder(S.border)
        CommitBox()
    end)

    AttachTooltip(region._label or slider, cfg.text, cfg.tooltip)
    region._control = slider
    ApplyDisabled(region, slider, cfg)
    F:RegisterRefresh(function()
        if slider._dragging then return end -- never fight an in-progress drag
        local v = Read()
        slider._updating = true
        slider:SetValue(v)
        slider._updating = nil
        Render(v)
        SyncSteppers(v)
    end)
    return slider
end

-- Segmented pills: one row of adjacent buttons, exactly one active (accent fill).
local function QfxSegmented(region, frame, cfg)
    local S = F.Skin
    local T = F.Theme
    local values = cfg.values or {}
    local order = cfg.order
    if not order then
        order = {}
        for k in pairs(values) do order[#order + 1] = k end
        table.sort(order, function(a, b) return tostring(a) < tostring(b) end)
    end
    if #order == 0 then return end

    local gap = S.segGap or 1
    local meas = Font(region, S.textSize, 1, 1, 1, 1)
    meas:Hide()
    local widths, total = {}, 0
    for i = 1, #order do
        local labelText = ResolveLabel(values, order, order[i])
        meas:SetText(labelText)
        local mw = meas:GetStringWidth()
        if IsSecret(mw) or not mw then mw = #tostring(labelText) * 8 end
        local w = math.max(cfg.minWidth or S.segMinW or 38, mw + (S.segPadX or 16))
        widths[i] = w
        total = total + w + (i > 1 and gap or 0)
    end

    local btns = {}
    local cum = 0
    for i = #order, 1, -1 do
        local key = order[i]
        local b = CreateFrame("Button", nil, region)
        b:SetSize(widths[i], S.rowControlH)
        b:SetPoint("RIGHT", region, "RIGHT", -(T.rightPad + cum), 0)
        cum = cum + widths[i] + gap
        local bg = QfxSurface(b, "BACKGROUND", 0, S.controlBg)
        bg:SetAllPoints()
        -- borderless pills: the active one is an accent fill, the rest a flat surface
        local fs = Font(b, S.textSize, S.text[1], S.text[2], S.text[3], S.text[4])
        fs:SetPoint("CENTER", b, "CENTER", 0, 0)
        fs:SetText(ResolveLabel(values, order, key))
        b._key = key
        b._qfx = "segmented"
        b._bg, b._fs = bg, fs
        local keyTip = type(values[key]) == "table" and values[key].tooltip or nil
        local tipText = keyTip or cfg.tooltip
        b:SetScript("OnEnter", function(self)
            if not b._active then
                bg:SetColorTexture(S.controlBgHi[1], S.controlBgHi[2], S.controlBgHi[3], S.controlBgHi[4] or 1)
            end
            if cfg.text or tipText then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText(cfg.text or "", 1, 1, 1)
                if tipText then GameTooltip:AddLine(tipText, 1, 1, 1, true) end
                GameTooltip:Show()
            end
        end)
        b:SetScript("OnLeave", function()
            if not b._active then
                bg:SetColorTexture(S.controlBg[1], S.controlBg[2], S.controlBg[3], S.controlBg[4] or 1)
            end
            GameTooltip:Hide()
        end)
        b:SetScript("OnClick", function()
            if ConfigDisabled(cfg) then return end
            if cfg.setValue then cfg.setValue(key) end
            if cfg.onSelect then cfg.onSelect(key) end
            region._refresh()
        end)
        btns[i] = b
    end
    region._refresh = function()
        local cur = cfg.getValue and cfg.getValue()
        for i = 1, #order do
            local b = btns[i]
            local on = (cur == b._key)
            b._active = on
            local bgC = on and (S.selectedFill or S.accent) or S.controlBg
            b._bg:SetColorTexture(bgC[1], bgC[2], bgC[3], bgC[4] or 1)
            local tc = on and (S.segOnText or S.text) or S.text
            b._fs:SetTextColor(tc[1], tc[2], tc[3], tc[4] or 1)
        end
    end
    region._dimTargets = btns
    region._control = btns[#btns]
    ApplyDisabled(region, btns[#btns], cfg)
    F:RegisterRefresh(region._refresh)
    region._refresh()
    return btns[1]
end

local function QfxDropdown(region, frame, cfg)
    local S = F.Skin
    local dd = MakeQfxDropdownButton(region, S, cfg.width or 170)
    local values = cfg.values or {}
    local order = cfg.order
    if not order then
        order = {}
        for k in pairs(values) do order[#order + 1] = k end
        table.sort(order, function(a, b) return tostring(a) < tostring(b) end)
    end
    local function Current()
        local v = cfg.getValue and cfg.getValue()
        if v == nil then v = order[1] end
        return v
    end
    local function UpdateText()
        local text = ResolveLabel(values, order, Current())
        if dd._lastText == text then return end -- unchanged: no relayout per refresh
        dd._lastText = text
        dd._label:SetText(text)
    end
    local items = {}
    for i = 1, #order do
        local key = order[i]
        items[i] = {
            key = key,
            label = ResolveLabel(values, order, key),
            tooltip = type(values[key]) == "table" and values[key].tooltip or nil,
        }
    end
    local menu, refresh = MakeQfxMenu(dd, S, {
        items = items,
        width = cfg.menuWidth or math.max(170, cfg.width or 170),
        checked = function(k) return Current() == k end,
        onPick = function(k)
            if cfg.setValue then cfg.setValue(k) end
            UpdateText()
        end,
    })
    UpdateText()
    dd:SetScript("OnClick", function()
        if menu:IsShown() then menu:Hide() else dd._openMenu() end
    end)
    AttachTooltip(region._label, cfg.text, cfg.tooltip)
    region._control = dd
    ApplyDisabled(region, dd, cfg)
    F:RegisterRefresh(UpdateText)
    return dd
end

local function QfxCheckboxDropdown(region, frame, cfg)
    local S = F.Skin
    local dd = MakeQfxDropdownButton(region, S, cfg.width or 190)
    local items = cfg.items or {}
    local getFn, setFn = cfg.getFn, cfg.setFn
    local function Summary()
        if cfg.summaryFn then return cfg.summaryFn() end
        local n = 0
        for i = 1, #items do
            if getFn and getFn(items[i].key) then n = n + 1 end
        end
        if n == 0 then return cfg.noneText or "None" end
        return tostring(n) .. " / " .. tostring(#items)
    end
    local menu, refresh = MakeQfxMenu(dd, S, {
        items = items,
        width = cfg.menuWidth or math.max(190, cfg.width or 190),
        multi = true,
        checked = function(k) return getFn and getFn(k) end,
        onPick = function(k)
            if setFn then setFn(k, not (getFn and getFn(k))) end
            dd._label:SetText(Summary())
        end,
    })
    dd._label:SetText(Summary())
    dd:SetScript("OnClick", function()
        if menu:IsShown() then menu:Hide() else dd._openMenu() end
    end)
    AttachTooltip(region._label, cfg.text, cfg.tooltip)
    region._control = dd
    ApplyDisabled(region, dd, cfg)
    F:RegisterRefresh(function()
        dd._label:SetText(Summary())
        refresh()
    end)
    return dd
end

local function QfxButton(region, frame, cfg)
    local S = F.Skin
    local base = S.buttonBg or S.controlBg
    local hover = S.buttonBgHi or S.controlBgHi
    local btn = CreateFrame("Button", nil, region)
    btn:SetSize(cfg.width or S.buttonMinW, S.buttonH)
    btn:SetPoint("RIGHT", region, "RIGHT", -F.Theme.rightPad, 0)
    local bg = QfxSurface(btn, "BACKGROUND", 0, base)
    bg:SetAllPoints()
    local brd = QfxBorder(btn, btn:GetFrameLevel(), S.buttonBorder or S.border, 1, 1)
    local lbl = Font(btn, S.textSize, S.text[1], S.text[2], S.text[3], S.text[4])
    lbl:SetPoint("CENTER")
    lbl:SetText(cfg.text or "")
    btn:SetScript("OnEnter", function()
        bg:SetColorTexture(hover[1], hover[2], hover[3], hover[4])
        brd._setBorder(S.borderHi or S.buttonBorder or S.border)
    end)
    btn:SetScript("OnLeave", function()
        bg:SetColorTexture(base[1], base[2], base[3], base[4])
        brd._setBorder(S.buttonBorder or S.border)
    end)
    btn:SetScript("OnClick", function(self) if cfg.onClick then cfg.onClick(self) end end)
    AttachTooltip(btn, cfg.text, cfg.tooltip)
    region._control = btn
    ApplyDisabled(region, btn, cfg)
    F:RegisterRefresh(function() end)
    return btn
end

-- Right-aligned cluster of small buttons in one slot (nudge pads, Apply/Reset
-- pairs, ...). cfg = { gap, buttons = { { text, onClick, width, tooltip,
-- disabled, disabledTooltip }, ... } }. The last entry sits at the slot's right
-- edge; earlier entries stack leftwards. Returns the first button.
local function QfxButtonRow(region, frame, cfg)
    local S = F.Skin
    local T = F.Theme
    local gap = cfg.gap or 4
    local specs = cfg.buttons or {}
    local btns = {}
    local xOff = -T.rightPad
    for i = #specs, 1, -1 do
        local spec = specs[i]
        local btn = CreateFrame("Button", nil, region)
        local w = spec.width or 60
        btn:SetSize(w, S.rowControlH)
        btn:SetPoint("RIGHT", region, "RIGHT", xOff, 0)
        xOff = xOff - w - gap
        local base = S.buttonBg or S.controlBg
        local hover = S.buttonBgHi or S.controlBgHi
        local bg = QfxSurface(btn, "BACKGROUND", 0, base)
        bg:SetAllPoints()
        local brd = QfxBorder(btn, btn:GetFrameLevel(), S.buttonBorder or S.border, 1, 1)
        local lbl = Font(btn, S.textSize, S.text[1], S.text[2], S.text[3], S.text[4])
        lbl:SetPoint("CENTER", btn, "CENTER", 0, 0)
        lbl:SetText(spec.text or "")
        btn._bg, btn._brd, btn._lbl = bg, brd, lbl
        btn._qfx = "rowButton"
        local function Blocked()
            if spec.disabled and spec.disabled() then return true end
            if ConfigDisabled(cfg) then return true end
            return false
        end
        btn:SetScript("OnEnter", function(self2)
            if Blocked() then return end
            bg:SetColorTexture(hover[1], hover[2], hover[3], hover[4] or 1)
            brd._setBorder(S.borderHi or S.buttonBorder or S.border)
            if spec.tooltip then
                GameTooltip:SetOwner(self2, "ANCHOR_RIGHT")
                GameTooltip:SetText(spec.text or "", 1, 1, 1)
                GameTooltip:AddLine(spec.tooltip, 1, 1, 1, true)
                GameTooltip:Show()
            end
        end)
        btn:SetScript("OnLeave", function()
            bg:SetColorTexture(base[1], base[2], base[3], base[4] or 1)
            brd._setBorder(S.buttonBorder or S.border)
            GameTooltip:Hide()
        end)
        btn:SetScript("OnClick", function(self2)
            if Blocked() then return end
            if spec.onClick then spec.onClick(self2) end
        end)
        btns[i] = btn
    end
    region._dimTargets = btns
    ApplyDisabled(region, btns[1], cfg)
    F:RegisterRefresh(function()
        for i = 1, #btns do
            local spec = specs[i]
            local off = (spec.disabled and spec.disabled() and true or false) or ConfigDisabled(cfg)
            btns[i]:SetAlpha(off and 0.35 or 1)
        end
    end)
    return btns[1]
end

local function QfxInput(region, frame, cfg)
    local S = F.Skin
    local box = CreateFrame("EditBox", nil, region)
    box:SetSize(cfg.width or 100, S.rowControlH)
    box:SetPoint("RIGHT", region, "RIGHT", -F.Theme.rightPad, 0)
    box:SetAutoFocus(false)
    local bg = QfxSurface(box, "BACKGROUND", 0, S.controlBg)
    bg:SetAllPoints()
    QfxBorder(box, box:GetFrameLevel(), S.border, 1, 1)
    box:SetFont(F.Theme.font, S.textSize, "")
    box:SetTextColor(S.text[1], S.text[2], S.text[3], S.text[4])
    box:SetJustifyH("LEFT")
    box:SetTextInsets(6, 4, 0, 0)
    local function Read()
        local v = cfg.getValue and cfg.getValue()
        return tostring(v or "")
    end
    box:SetText(Read())
    local function Commit()
        local text = box:GetText() or ""
        if cfg.numeric then
            local n = tonumber(text)
            if n == nil then box:SetText(Read()) return end
            text = n
        end
        if cfg.setValue then cfg.setValue(text) end
    end
    box:SetScript("OnEnterPressed", function(self) Commit(); self:ClearFocus() end)
    box:SetScript("OnEditFocusLost", Commit)
    box:SetScript("OnEscapePressed", function(self) self:SetText(Read()); self:ClearFocus() end)
    AttachTooltip(region._label, cfg.text, cfg.tooltip)
    region._control = box
    ApplyDisabled(region, box, cfg)
    F:RegisterRefresh(function()
        if not box:HasFocus() then box:SetText(Read()) end
    end)
    return box
end

-- Color swatch with optional alpha (opt.alpha). getFn -> r, g, b [, a];
-- setFn(r, g, b [, a]). Returns the button; call btn._update() to repaint.
local function MakeQfxColorSwatch(parent, size, getFn, setFn, opts)
    opts = opts or {}
    local S = F.Skin
    local sw = CreateFrame("Button", nil, parent)
    sw:SetSize(size or 22, size or 22)
    local tex = QfxSurface(sw, "ARTWORK", 0, { 1, 1, 1, 1 })
    tex:SetAllPoints()
    -- no outline at rest (it shrank the colour area); the hover outline is the
    -- EUI "lazy border" idea
    local brd = QfxBorder(sw, sw:GetFrameLevel(), S.borderHi or S.border, 1, 1)
    brd:Hide()
    local function Read()
        local r, g, b, a = getFn and getFn()
        return r or 1, g or 1, b or 1, a or 1
    end
    local function Update()
        local r, g, b, a = Read()
        local shown = opts.alpha and a or 1
        if sw._r == r and sw._g == g and sw._b == b and sw._a == shown then return end
        sw._r, sw._g, sw._b, sw._a = r, g, b, shown
        tex:SetColorTexture(r, g, b, shown)
    end
    sw._update = Update
    sw._qfx = "swatch"
    Update()
    sw:SetScript("OnClick", function()
        local r, g, b, a = Read()
        local function Apply()
            local nr, ng, nb
            if ColorPickerFrame.GetColorRGB then
                nr, ng, nb = ColorPickerFrame:GetColorRGB()
            else
                local c = ColorPickerFrame.Content and ColorPickerFrame.Content.ColorPicker
                if c and c.GetColorRGB then nr, ng, nb = c:GetColorRGB() end
            end
            local na = a
            if opts.alpha and ColorPickerFrame.GetColorAlpha then
                na = ColorPickerFrame:GetColorAlpha() or a
            end
            if nr and setFn then setFn(nr, ng, nb, na) end
            Update()
        end
        local function Cancel(prev)
            if setFn and prev then setFn(prev.r, prev.g, prev.b, prev.a) end
            Update()
        end
        if ColorPickerFrame.SetupColorPickerAndShow then
            ColorPickerFrame:SetupColorPickerAndShow({
                r = r, g = g, b = b, a = a, hasOpacity = opts.alpha and true or false,
                swatchFunc = Apply, opacityFunc = Apply, cancelFunc = Cancel,
            })
        else
            ColorPickerFrame.func = Apply
            ColorPickerFrame.cancelFunc = Cancel
            ColorPickerFrame.previousValues = { r = r, g = g, b = b, a = a }
            ColorPickerFrame:SetColorRGB(r, g, b)
            ColorPickerFrame:Show()
        end
    end)
    sw:SetScript("OnEnter", function(self2)
        brd:Show()
        if opts.text or opts.tooltip then
            GameTooltip:SetOwner(self2, "ANCHOR_RIGHT")
            GameTooltip:SetText(opts.text or "", 1, 1, 1)
            if opts.tooltip then GameTooltip:AddLine(opts.tooltip, 1, 1, 1, true) end
            GameTooltip:Show()
        end
    end)
    sw:SetScript("OnLeave", function()
        brd:Hide()
        GameTooltip:Hide()
    end)
    return sw, Update
end

local function QfxColor(region, frame, cfg)
    local sw, Update = MakeQfxColorSwatch(region, 22, cfg.getValue, cfg.setValue,
        { alpha = cfg.alpha, text = cfg.text, tooltip = cfg.tooltip })
    sw:SetPoint("RIGHT", region, "RIGHT", -F.Theme.rightPad, 0)
    region._control = sw
    ApplyDisabled(region, sw, cfg)
    F:RegisterRefresh(Update)
    return sw
end

-- Dropdown mode (class color / original / custom ...) + custom color swatch +
-- reset. cfg = { text, tooltip, modes = { key = label }, order, customKey,
-- getMode, setMode, getColor, setColor, defaultColor, defaultMode, alpha,
-- width, resetTooltip, disabled, disabledTooltip }. The swatch only shows while
-- the mode is customKey; clicking it opens the picker (which also works if the
-- host switches to the custom mode itself).
local function QfxColorMode(region, frame, cfg)
    local S = F.Skin
    local T = F.Theme
    local values = cfg.modes or {}
    local order = cfg.order
    if not order then
        order = {}
        for k in pairs(values) do order[#order + 1] = k end
        table.sort(order, function(a, b) return tostring(a) < tostring(b) end)
    end
    local customKey = cfg.customKey or "custom"

    local reset = CreateFrame("Button", nil, region)
    reset:SetSize(16, 16)
    reset:SetPoint("RIGHT", region, "RIGHT", -T.rightPad, 0)
    reset._qfx = "reset"
    local resetLbl = Font(reset, S.textSize, S.textMuted[1], S.textMuted[2], S.textMuted[3], 1)
    resetLbl:SetPoint("CENTER", reset, "CENTER", 0, 0)
    resetLbl:SetText("R")
    reset:SetScript("OnEnter", function() resetLbl:SetTextColor(S.text[1], S.text[2], S.text[3], 1) end)
    reset:SetScript("OnLeave", function() resetLbl:SetTextColor(S.textMuted[1], S.textMuted[2], S.textMuted[3], 1) end)
    reset:SetScript("OnClick", function()
        if cfg.setColor and cfg.defaultColor then
            local d = cfg.defaultColor
            if type(d) == "function" then d = d() end
            if type(d) == "table" then cfg.setColor(d[1], d[2], d[3], d[4]) end
        end
        if cfg.setMode and cfg.defaultMode then cfg.setMode(cfg.defaultMode) end
        region._refresh()
    end)
    AttachTooltip(reset, cfg.text, cfg.resetTooltip or "Reset to default")

    local swatch
    if cfg.getColor and cfg.setColor then
        swatch = MakeQfxColorSwatch(region, 20, cfg.getColor, cfg.setColor, { alpha = cfg.alpha })
        swatch:SetPoint("RIGHT", reset, "LEFT", -4, 0)
    end

    local dd = MakeQfxDropdownButton(region, S, cfg.width or 104)
    dd:ClearAllPoints()
    dd:SetPoint("RIGHT", swatch and swatch or reset, "LEFT", -4, 0)
    local function Current()
        local m = cfg.getMode and cfg.getMode()
        if m == nil then m = order[1] end
        return m
    end
    local items = {}
    for i = 1, #order do
        items[i] = { key = order[i], label = ResolveLabel(values, order, order[i]) }
    end
    local function UpdateText()
        dd._label:SetText(ResolveLabel(values, order, Current()))
        if swatch then swatch:SetShown(Current() == customKey) end
    end
    local menu, refresh = MakeQfxMenu(dd, S, {
        items = items,
        width = cfg.menuWidth or math.max(140, cfg.width or 104),
        checked = function(k) return Current() == k end,
        onPick = function(k)
            if cfg.setMode then cfg.setMode(k) end
            UpdateText()
        end,
    })
    UpdateText()
    dd:SetScript("OnClick", function()
        if menu:IsShown() then menu:Hide() else dd._openMenu() end
    end)
    AttachTooltip(region._label, cfg.text, cfg.tooltip)
    region._refresh = function()
        UpdateText()
        refresh()
    end
    region._control = dd
    region._dimTargets = { reset, swatch }
    ApplyDisabled(region, dd, cfg)
    F:RegisterRefresh(region._refresh)
    return dd
end

-- Keybind capture button. cfg = { text, tooltip, getValue, setValue, width,
-- noneText, captureText, conflicts = function(key) -> name|nil, clearOnRightClick
-- (default true), disabled, disabledTooltip }. Keys are stored WoW-style
-- ("CTRL-SHIFT-A", "BUTTON4", "MOUSEWHEELUP"); "" means unbound.
local KeybindModKeys = {
    LSHIFT = true, RSHIFT = true, LCTRL = true, RCTRL = true,
    LALT = true, RALT = true, UNKNOWN = true,
}
local function QfxKeybind(region, frame, cfg)
    local S = F.Skin
    local key = CreateFrame("Button", nil, region)
    key:SetSize(cfg.width or 120, S.rowControlH)
    key:SetPoint("RIGHT", region, "RIGHT", -F.Theme.rightPad, 0)
    local bg = QfxSurface(key, "BACKGROUND", 0, S.controlBg)
    bg:SetAllPoints()
    local brd = QfxBorder(key, key:GetFrameLevel(), S.border, 1, 1)
    local lbl = Font(key, S.textSize, S.text[1], S.text[2], S.text[3], S.text[4])
    lbl:SetPoint("CENTER", key, "CENTER", 0, 0)
    if lbl.SetWordWrap then lbl:SetWordWrap(false) end
    if lbl.SetMaxLines then lbl:SetMaxLines(1) end

    local catcher = CreateFrame("Frame", nil, key)
    catcher:SetAllPoints()
    if catcher.EnableKeyboard then catcher:EnableKeyboard(true) end
    if catcher.EnableMouse then catcher:EnableMouse(true) end
    if catcher.EnableMouseWheel then catcher:EnableMouseWheel(true) end
    catcher:Hide()
    key._catcher = catcher
    key._label = lbl
    key._bg, key._brd = bg, brd

    local function Read() return cfg.getValue and cfg.getValue() or "" end
    local function Display(v)
        if not v or v == "" then return cfg.noneText or "Not Bound" end
        return (v:gsub("-", "+"))
    end
    local capturing = false
    local function Repaint()
        if capturing then
            lbl:SetText(cfg.captureText or "Press a key...")
            brd._setBorder(S.borderHi or S.border)
            return
        end
        local v = Read()
        local conflict = (v ~= "" and cfg.conflicts) and cfg.conflicts(v) or nil
        if conflict then
            lbl:SetTextColor(S.danger[1], S.danger[2], S.danger[3], S.danger[4] or 1)
        else
            lbl:SetTextColor(S.text[1], S.text[2], S.text[3], S.text[4] or 1)
        end
        lbl:SetText(Display(v))
        brd._setBorder(S.border)
    end
    local function Mods()
        local out = ""
        if IsControlKeyDown and IsControlKeyDown() then out = out .. "CTRL-" end
        if IsShiftKeyDown and IsShiftKeyDown() then out = out .. "SHIFT-" end
        if IsAltKeyDown and IsAltKeyDown() then out = out .. "ALT-" end
        return out
    end
    local function StopCapture()
        if not capturing then return end
        capturing = false
        catcher:Hide()
        if catcher.SetPropagateKeyboardInput then catcher:SetPropagateKeyboardInput(true) end
        Repaint()
    end
    local function Commit(v)
        if cfg.setValue then cfg.setValue(v or "") end
        StopCapture()
    end

    local function StartCapture()
        if ConfigDisabled(cfg) then return end
        capturing = true
        catcher:Show()
        if catcher.SetPropagateKeyboardInput then catcher:SetPropagateKeyboardInput(false) end
        Repaint()
    end
    key:SetScript("OnClick", function(_, button)
        if button == "RightButton" and cfg.clearOnRightClick ~= false then
            Commit("")
        else
            StartCapture()
        end
    end)
    key:SetScript("OnEnter", function(self2)
        bg:SetColorTexture(S.controlBgHi[1], S.controlBgHi[2], S.controlBgHi[3], S.controlBgHi[4] or 1)
        brd._setBorder(S.borderHi or S.border)
        if cfg.text or cfg.tooltip then
            GameTooltip:SetOwner(self2, "ANCHOR_RIGHT")
            GameTooltip:SetText(cfg.text or "", 1, 1, 1)
            if cfg.tooltip then GameTooltip:AddLine(cfg.tooltip, 1, 1, 1, true) end
            GameTooltip:Show()
        end
    end)
    key:SetScript("OnLeave", function()
        bg:SetColorTexture(S.controlBg[1], S.controlBg[2], S.controlBg[3], S.controlBg[4] or 1)
        if not capturing then brd._setBorder(S.border) end
        GameTooltip:Hide()
    end)

    catcher:SetScript("OnKeyDown", function(_, k)
        if not capturing then return end
        local up = strupper and strupper(k or "") or string.upper(k or "")
        if up == "ESCAPE" then StopCapture() return end
        if KeybindModKeys[up] then return end
        Commit(Mods() .. up)
    end)
    catcher:SetScript("OnMouseWheel", function(_, delta)
        if not capturing then return end
        Commit(Mods() .. ((delta or 0) > 0 and "MOUSEWHEELUP" or "MOUSEWHEELDOWN"))
    end)
    catcher:SetScript("OnMouseDown", function(_, button)
        if not capturing then return end
        if button == "LeftButton" or button == "RightButton" then return end
        Commit(Mods() .. (strupper and strupper(button) or string.upper(button)))
    end)
    catcher:RegisterEvent("GLOBAL_MOUSE_DOWN")
    catcher:SetScript("OnEvent", function(self2)
        if not capturing then return end
        local focus = GetMouseFocus and GetMouseFocus() or nil
        if focus and (IsDescendantOf(focus, key) or IsDescendantOf(focus, self2)) then return end
        StopCapture()
    end)

    Repaint()
    region._control = key
    ApplyDisabled(region, key, cfg)
    F:RegisterRefresh(Repaint)
    return key
end

QFXSkin.wideButton = function(frame, text, onClick, opts)
    local S = F.Skin
    local base = S.buttonBg or S.controlBg
    local hover = S.buttonBgHi or S.controlBgHi
    local btn = CreateFrame("Button", nil, frame)
    btn:SetSize(opts.width or math.min(280, frame:GetWidth()), 24)
    btn:SetPoint("CENTER", frame, "CENTER", 0, 0)
    local bg = QfxSurface(btn, "BACKGROUND", 0, base)
    bg:SetAllPoints()
    local brd = QfxBorder(btn, btn:GetFrameLevel(), S.buttonBorder or S.border, 1, 1)
    local lbl = Font(btn, S.textSize, S.text[1], S.text[2], S.text[3], S.text[4])
    lbl:SetPoint("CENTER")
    lbl:SetText(text or "")
    btn:SetScript("OnEnter", function()
        bg:SetColorTexture(hover[1], hover[2], hover[3], hover[4])
        brd._setBorder(S.borderHi or S.buttonBorder or S.border)
    end)
    btn:SetScript("OnLeave", function()
        bg:SetColorTexture(base[1], base[2], base[3], base[4])
        brd._setBorder(S.buttonBorder or S.border)
    end)
    btn:SetScript("OnClick", function(self2) if onClick then onClick(self2) end end)
    frame._button = btn
end

QFXSkin.toggle = QfxToggle
QFXSkin.slider = QfxSlider
QFXSkin.segmented = QfxSegmented
QFXSkin.dropdown = QfxDropdown
QFXSkin.checkboxDropdown = QfxCheckboxDropdown
QFXSkin.button = QfxButton
QFXSkin.buttonRow = QfxButtonRow
QFXSkin.input = QfxInput
QFXSkin.color = QfxColor
QFXSkin.colorMode = QfxColorMode
QFXSkin.keybind = QfxKeybind

F.Skins = { qfx = QFXSkin }

-- Skin token override: pass a table and any token not supplied keeps the QFXUI
-- default. Passing nil/"qfx" restores the stock skin.
function F:SetSkin(skin)
    if type(skin) == "table" then
        local merged = {}
        for k, v in pairs(QFXSkin) do merged[k] = v end
        for k, v in pairs(skin) do merged[k] = v end
        self.Skin = merged
    else
        self.Skin = QFXSkin
    end
    return self.Skin
end

F.Skin = QFXSkin

local function BuildSlot(self, skin, region, cfg)
    if type(cfg) ~= "table" then return end
    local label = BuildLabel(region, cfg)
    if cfg.type == "label" or cfg.type == nil then
        region._control = nil
        FitLabel(region, cfg, self)
        return
    end
    local builder = skin and skin[cfg.type]
    if builder then
        builder(region, region:GetParent(), cfg)
    else
        label:SetText((cfg.text or "") .. " (?)")
    end
    FitLabel(region, cfg, self)
end

function F:DualRow(parent, y, leftCfg, rightCfg)
    local T = self.Theme
    local totalW = ContentWidth(parent)
    local h = T.rowH
    if (leftCfg and leftCfg.type == "slider") or (rightCfg and rightCfg.type == "slider") then
        h = math.max(h, T.sliderRowH or 46)
    end
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(totalW, h)
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT", T.pad, y)

    local halfW = floor(totalW / 2)
    local leftRegion = CreateFrame("Frame", nil, frame)
    leftRegion:SetSize(rightCfg and halfW or totalW, h)
    leftRegion:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    local rightRegion = CreateFrame("Frame", nil, frame)
    rightRegion:SetSize(halfW, h)
    rightRegion:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    frame._leftRegion = leftRegion
    frame._rightRegion = rightRegion

    RowBg(frame, parent, self)
    local skin = self.Skin
    BuildSlot(self, skin, leftRegion, leftCfg)
    BuildSlot(self, skin, rightRegion, rightCfg)

    if rightCfg then
        local div = NoSnap(frame:CreateTexture(nil, "ARTWORK"))
        div:SetColorTexture(T.lineColor[1], T.lineColor[2], T.lineColor[3], T.lineColor[4])
        div:SetWidth(1)
        div:SetPoint("TOP", frame, "TOP", 0, -4)
        div:SetPoint("BOTTOM", frame, "BOTTOM", 0, 4)
    end

    frame._refresh = function()
        -- Per-control refreshers are registered globally; this hook exists so a
        -- host that keeps row references can refresh one row on demand.
    end
    return frame, h
end

-------------------------------------------------------------------------------
-- Standalone: checkbox dropdown / color swatch (right-anchored helpers)
-------------------------------------------------------------------------------
function F:CheckboxDropdown(parent, width, frameLevel, items, getFn, setFn, opts)
    opts = opts or {}
    local T = self.Theme
    local region = CreateFrame("Frame", nil, parent)
    region:SetSize(width or 190, T.controlH)
    if opts.point and opts.relPoint then
        region:SetPoint(opts.point, parent, opts.relPoint, opts.x or 0, opts.y or 0)
    else
        region:SetPoint("RIGHT", parent, "RIGHT", -T.rightPad, opts.y or 0)
    end
    region:SetFrameLevel((frameLevel or parent:GetFrameLevel()) + 2)
    local maker = (self.Skin and self.Skin.checkboxDropdown) or QFXSkin.checkboxDropdown
    return maker(region, parent, {
        width = width or 190,
        items = items,
        getFn = getFn,
        setFn = setFn,
        summaryFn = opts.summaryFn,
        noneText = opts.noneText,
        tooltip = opts.tooltip,
        text = opts.text,
    })
end

function F:ColorSwatch(parent, frameLevel, getFn, setFn, opts)
    opts = opts or {}
    local T = self.Theme
    local region = CreateFrame("Frame", nil, parent)
    region:SetSize(opts.width or 24, opts.height or 24)
    region:SetPoint(opts.point or "RIGHT", parent, opts.relPoint or opts.point or "RIGHT", opts.x or -T.rightPad, opts.y or 0)
    region:SetFrameLevel((frameLevel or parent:GetFrameLevel()) + 2)
    local maker = (self.Skin and self.Skin.color) or QFXSkin.color
    local sw = maker(region, parent, { getValue = getFn, setValue = setFn, text = opts.text, tooltip = opts.tooltip })
    return sw, function() end
end

-- Standalone segmented pills: F:Segmented(parent, frameLevel, values, order,
-- getValue, setValue, opts) -> region, refresh, firstButton. The caller anchors
-- the returned region; the pills right-align to its right edge.
function F:Segmented(parent, frameLevel, values, order, getValue, setValue, opts)
    opts = opts or {}
    local T = self.Theme
    local region = CreateFrame("Frame", nil, parent)
    region:SetSize(opts.width or 160, (self.Skin and self.Skin.rowControlH) or T.controlH)
    if opts.point and opts.relPoint then
        region:SetPoint(opts.point, parent, opts.relPoint, opts.x or 0, opts.y or 0)
    else
        region:SetPoint("RIGHT", parent, "RIGHT", -T.rightPad, opts.y or 0)
    end
    region:SetFrameLevel((frameLevel or parent:GetFrameLevel()) + 2)
    local first = QfxSegmented(region, parent, {
        values = values,
        order = order,
        getValue = getValue,
        setValue = setValue,
        minWidth = opts.minWidth,
        text = opts.text,
        tooltip = opts.tooltip,
        disabled = opts.disabled,
        disabledTooltip = opts.disabledTooltip,
        onSelect = opts.onSelect,
    })
    return region, region._refresh, first
end

-------------------------------------------------------------------------------
-- Advanced controls (custom-drawn, drawn with the active skin tokens).
-------------------------------------------------------------------------------

-- Active drawing tokens (kept as a function for callers that build custom rows).
function F:Tokens()
    return self.Skin or QFXSkin
end

-- Tabs / segmented row. items = { { key, label }, ... };
-- getActive() -> key; onSelect(key). Returns frame, height.
function F:Tabs(parent, y, items, getActive, onSelect, opts)
    opts = opts or {}
    local S = self:Tokens()
    local T = self.Theme
    local h = opts.height or 24
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(ContentWidth(parent), h + 2)
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT", T.pad, y)

    local btns = {}
    local function Refresh()
        local active = getActive and getActive()
        for i = 1, #btns do
            local b = btns[i]
            local on = b._key == active
            b._label:SetTextColor(on and S.sectionText[1] or S.textMuted[1],
                on and S.sectionText[2] or S.textMuted[2],
                on and S.sectionText[3] or S.textMuted[3], 1)
            b._underline:SetShown(on)
        end
    end

    local x = 0
    for i = 1, #items do
        local it = items[i]
        local btn = CreateFrame("Button", nil, frame)
        local lbl = Font(btn, T.labelSize, S.textMuted[1], S.textMuted[2], S.textMuted[3], 1)
        lbl:SetPoint("CENTER", btn, "CENTER", 0, 1)
        lbl:SetText(it.label or tostring(it.key))
        local w = math.max(48, (lbl:GetStringWidth() or 40) + (opts.padX or 22))
        btn:SetSize(w, h)
        btn:SetPoint("LEFT", frame, "LEFT", x, 0)
        x = x + w + (opts.gap or 4)
        local ul = btn:CreateTexture(nil, "ARTWORK")
        ul:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", 6, 0)
        ul:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -6, 0)
        ul:SetHeight(2)
        local sc = S.selectedLine or S.borderHi or S.accent
        ul:SetColorTexture(sc[1], sc[2], sc[3], 1)
        ul:Hide()
        btn._key, btn._label, btn._underline = it.key, lbl, ul
        btn:SetScript("OnEnter", function() lbl:SetTextColor(S.text[1], S.text[2], S.text[3], 1) end)
        btn:SetScript("OnLeave", function() Refresh() end)
        btn:SetScript("OnClick", function()
            if onSelect then onSelect(it.key) end
            Refresh()
        end)
        btns[#btns + 1] = btn
    end
    Refresh()
    self:RegisterRefresh(Refresh)
    return frame, h + 2
end

-- Tab panel: a Tabs strip with real content switching (each tab owns a content
-- frame that is built once and then shown/hidden).
--   local panel, h, api = W:TabPanel(parent, y, {
--       tabs = { { key = "a", label = "A", build = function(content, key)
--                    local cy = 0
--                    ... build rows into content, decreasing cy ...
--                    return -cy end }, ... },
--       getActive = function() return state.tab end,
--       onSelect  = function(key) state.tab = key end,
--       height = 220,   -- optional fixed content height (else auto from build)
--       onResize = function(panel, totalH) end })
--   api.GetContent(tabKey) returns the tab's content frame.
function F:TabPanel(parent, y, opts)
    opts = opts or {}
    local T = self.Theme
    local tabs = opts.tabs or {}

    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(parent:GetWidth() or 0, 1)
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, y)

    local contentFrames, maxH = {}, 0
    local strip, stripH
    local function Layout()
        local h = stripH + 4 + (opts.height or maxH)
        frame:SetHeight(h)
        if opts.onResize then opts.onResize(frame, h) end
    end
    local function Show(key)
        local cf = contentFrames[key]
        if not cf then
            cf = CreateFrame("Frame", nil, frame)
            cf:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -(stripH + 4))
            cf:SetWidth(frame:GetWidth())
            local build
            for i = 1, #tabs do
                if tabs[i].key == key then build = tabs[i].build end
            end
            local ch = 0
            if build then ch = build(cf, key) or 0 end
            if ch > maxH then maxH = ch end
            cf:SetHeight(opts.height or math.max(1, ch))
            contentFrames[key] = cf
        end
        for _, other in pairs(contentFrames) do other:Hide() end
        cf:Show()
        Layout()
    end

    strip, stripH = self:Tabs(frame, 0, tabs, opts.getActive, function(key)
        Show(key)
        if opts.onSelect then opts.onSelect(key) end
    end, opts.tabOpts)

    frame._api = {
        Show = function(_, key) Show(key) end,
        GetContent = function(_, key) return contentFrames[key] end,
        Refresh = function() Layout() end,
    }
    local current = (opts.getActive and opts.getActive()) or (tabs[1] and tabs[1].key)
    if current then Show(current) end
    Layout()
    return frame, frame:GetHeight(), frame._api
end

-- Multi-column checkbox grid. entries = { { label, getValue, setValue,
-- tooltip | help, disabled, disabledTooltip, group, icon }, ... }.
-- opts = { gap, rowH, groupH, maxSelected (number|function), limitTooltip }.
-- Grouped entries render a full-width heading whenever e.group changes;
-- maxSelected dims (and blocks) unchecked cells once the limit is reached.
function F:CheckGrid(parent, y, columns, entries, opts)
    opts = opts or {}
    local S = self:Tokens()
    local T = self.Theme
    local cols = math.max(1, tonumber(columns) or 2)
    local contentW = ContentWidth(parent)
    local gap = opts.gap or 12
    local cellW = floor((contentW - gap * (cols - 1)) / cols)
    local cellH = opts.rowH or 22
    local groupH = opts.groupH or 20
    entries = entries or {}

    local layout, yOff, col = {}, 0, 0
    local lastGroup
    for i = 1, #entries do
        local e = entries[i]
        if e.group ~= nil and e.group ~= lastGroup then
            lastGroup = e.group
            if col ~= 0 then yOff = yOff + cellH; col = 0 end
            layout[#layout + 1] = { kind = "group", label = e.group, top = yOff }
            yOff = yOff + groupH
        end
        layout[#layout + 1] = { kind = "cell", entry = e, col = col, top = yOff }
        col = col + 1
        if col >= cols then col = 0; yOff = yOff + cellH end
    end
    local totalH = yOff + (col > 0 and cellH or 0) + 4

    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(contentW, totalH)
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT", T.pad, y)
    frame._qfx = "checkGrid"

    local function MaxN()
        local m = opts.maxSelected
        if type(m) == "function" then m = m() end
        return tonumber(m)
    end
    local function Count()
        local n = 0
        for i = 1, #entries do
            if entries[i].getValue and entries[i].getValue() then n = n + 1 end
        end
        return n
    end
    local renders = {}
    local function RenderAll()
        for i = 1, #renders do renders[i]() end
    end

    for i = 1, #layout do
        local item = layout[i]
        if item.kind == "group" then
            local gl = Font(frame, T.labelSize, S.sectionText[1], S.sectionText[2], S.sectionText[3], 1)
            gl:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -item.top - 2)
            gl:SetText(tostring(item.label or ""))
        else
            local e = item.entry
            local cell = CreateFrame("Frame", nil, frame)
            cell:SetSize(cellW, cellH)
            cell:SetPoint("TOPLEFT", frame, "TOPLEFT", item.col * (cellW + gap), -item.top - 2)

            local icon
            local x = 0
            if e.icon then
                icon = cell:CreateTexture(nil, "ARTWORK")
                icon:SetSize(14, 14)
                icon:SetPoint("LEFT", cell, "LEFT", 0, 0)
                icon:SetTexture(e.icon)
                x = 18
            end
            local cb = CreateFrame("Button", nil, cell)
            cb._qfx = "checkcell"
            cb:SetSize(16, 16)
            cb:SetPoint("LEFT", cell, "LEFT", x, 0)
            local box = QfxSurface(cb, "BACKGROUND", 0, S.controlBg)
            box:SetAllPoints()
            local brd = QfxBorder(cb, cb:GetFrameLevel(), S.border, 1, 1)
            local mark = QfxSurface(cb, "ARTWORK", 1, S.accent)
            mark:SetPoint("TOPLEFT", cb, "TOPLEFT", 3, -3)
            mark:SetPoint("BOTTOMRIGHT", cb, "BOTTOMRIGHT", -3, 3)

            local lbl = Font(cell, T.labelSize, S.text[1], S.text[2], S.text[3], S.text[4])
            lbl:SetPoint("LEFT", cb, "RIGHT", 6, 0)
            lbl:SetPoint("RIGHT", cell, "RIGHT", 0, 0)
            lbl:SetJustifyH("LEFT")
            TruncateToFit(lbl, e.label or e.text or "", cellW - 26 - x)

            local block
            local function EnsureBlock()
                if block then return end
                block = CreateFrame("Frame", nil, cell)
                block:SetAllPoints()
                block:SetFrameLevel(cell:GetFrameLevel() + 8)
                block:EnableMouse(true)
                block:Hide()
                block:SetScript("OnEnter", function(self2)
                    local reason
                    if e.disabled and e.disabled() and e.disabledTooltip then
                        reason = type(e.disabledTooltip) == "function" and e.disabledTooltip() or e.disabledTooltip
                    elseif cb._blocked then
                        reason = opts.limitTooltip or "Selection limit reached"
                    end
                    if reason and reason ~= "" then
                        GameTooltip:SetOwner(self2, "ANCHOR_RIGHT")
                        GameTooltip:SetText(reason, 1, 1, 1, 1, true)
                        GameTooltip:Show()
                    end
                end)
                block:SetScript("OnLeave", function() GameTooltip:Hide() end)
            end
            local function Render()
                local on = e.getValue and e.getValue() and true or false
                local off = e.disabled and e.disabled() and true or false
                local limit = MaxN()
                local overLimit = limit ~= nil and not on and Count() >= limit
                mark:SetShown(on)
                cb._blocked = overLimit or off
                local a = (overLimit or off) and 0.35 or 1
                cb:SetAlpha(a)
                lbl:SetAlpha(a)
                if icon then icon:SetAlpha(a) end
                if off or (overLimit and opts.limitTooltip) then
                    EnsureBlock()
                    block:SetShown(true)
                elseif block then
                    block:Hide()
                end
            end
            renders[#renders + 1] = Render
            Render()

            cb:SetScript("OnEnter", function() brd._setBorder(S.borderHi or S.border) end)
            cb:SetScript("OnLeave", function() brd._setBorder(S.border) end)
            cb:SetScript("OnClick", function()
                if cb._blocked then return end
                if e.setValue then e.setValue(not (e.getValue and e.getValue())) end
                RenderAll()
            end)
            if e.tooltip or e.help then AttachTooltip(lbl, e.label, e.tooltip or e.help) end
        end
    end

    frame.Count = function() return Count() end
    self:RegisterRefresh(RenderAll)
    return frame, totalH
end

-- Searchable dropdown for long lists (spell / media pickers).
-- itemsTableOrFn -> { { key, label, tooltip }, ... } (re-evaluated on open).
-- Returns dropdownButton, refreshFn.
function F:SearchableDropdown(parent, width, frameLevel, itemsTableOrFn, getValue, setValue, opts)
    opts = opts or {}
    local S = self:Tokens()
    local T = self.Theme
    local ddW = width or 220

    local region = CreateFrame("Frame", nil, parent)
    region:SetSize(ddW, T.controlH)
    if opts.point then
        region:SetPoint(opts.point, parent, opts.relPoint or opts.point, opts.x or 0, opts.y or 0)
    else
        region:SetPoint("RIGHT", parent, "RIGHT", -T.rightPad, opts.y or 0)
    end
    region:SetFrameLevel((frameLevel or parent:GetFrameLevel()) + 2)

    local dd = MakeQfxDropdownButton(region, S, ddW)

    local function Source()
        local src = type(itemsTableOrFn) == "function" and itemsTableOrFn() or itemsTableOrFn
        return src or {}
    end
    local function LabelFor(key)
        local src = Source()
        for i = 1, #src do
            if src[i].key == key then return src[i].label or tostring(key) end
        end
        return tostring(key or "")
    end
    local function UpdateLabel()
        local key = getValue and getValue()
        dd._label:SetText(key ~= nil and LabelFor(key) or (opts.placeholder or ""))
    end
    UpdateLabel()

    local rowH = S.menuRowH
    local maxRows = math.max(3, opts.maxVisible or 10)
    local SEARCH_H = 22
    local menuW = opts.menuWidth or ddW
    local menu = CreateFrame("Frame", nil, UIParent)
    menu:SetFrameStrata("FULLSCREEN_DIALOG")
    if menu.SetFrameLevel then menu:SetFrameLevel(200) end
    if menu.SetClampedToScreen then menu:SetClampedToScreen(true) end
    menu:EnableMouse(true)
    menu:EnableMouseWheel(true)
    menu:Hide()
    menu:SetSize(menuW, SEARCH_H + rowH * maxRows + 8)
    if menu.SetScale and dd.GetEffectiveScale and UIParent and UIParent.GetEffectiveScale then
        local ds, us = dd:GetEffectiveScale(), UIParent:GetEffectiveScale()
        if ds and us and us > 0 then menu:SetScale(ds / us) end
    end
    local bg = QfxSurface(menu, "BACKGROUND", 0, S.menuBg)
    bg:SetAllPoints()
    QfxBorder(menu, menu:GetFrameLevel(), S.border, 1, 1)

    local search = CreateFrame("EditBox", nil, menu)
    search:SetSize(menuW - 12, SEARCH_H - 4)
    search:SetPoint("TOPLEFT", menu, "TOPLEFT", 6, -4)
    search:SetAutoFocus(false)
    search:SetFont(T.font, S.textSize, "")
    search:SetTextColor(S.text[1], S.text[2], S.text[3], S.text[4])
    search:SetTextInsets(4, 4, 0, 0)
    local searchBg = QfxSurface(search, "BACKGROUND", 0, S.controlBg)
    searchBg:SetAllPoints()
    QfxBorder(search, search:GetFrameLevel(), S.border, 1, 1)

    local rowTop = -(SEARCH_H + 4)
    local rowFrames = {}
    for i = 1, maxRows do
        local row = CreateFrame("Button", nil, menu)
        row:SetPoint("TOPLEFT", menu, "TOPLEFT", 4, rowTop - (i - 1) * rowH)
        row:SetPoint("TOPRIGHT", menu, "TOPRIGHT", -4, rowTop - (i - 1) * rowH)
        row:SetHeight(rowH)
        local hl = row:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints()
        hl:SetColorTexture(S.rowHover[1], S.rowHover[2], S.rowHover[3], S.rowHover[4])
        local check = QfxSurface(row, "ARTWORK", 0, S.accent)
        check:SetSize(8, 8)
        check:SetPoint("LEFT", row, "LEFT", 8, 0)
        local icon = row:CreateTexture(nil, "ARTWORK")
        icon:SetSize(14, 14)
        icon:SetPoint("LEFT", check, "RIGHT", 6, 0)
        icon:Hide()
        local lbl = Font(row, S.textSize, S.text[1], S.text[2], S.text[3], S.text[4])
        lbl:SetPoint("LEFT", check, "RIGHT", 8, 0)
        lbl:SetPoint("RIGHT", row, "RIGHT", -8, 0)
        lbl:SetJustifyH("LEFT")
        local act = CreateFrame("Button", nil, row)
        act:SetSize(16, 16)
        act:SetPoint("RIGHT", row, "RIGHT", -4, 0)
        local actIcon = act:CreateTexture(nil, "ARTWORK")
        actIcon:SetAllPoints()
        actIcon:Hide()
        local actText = Font(act, S.textSize, S.textMuted[1], S.textMuted[2], S.textMuted[3], 1)
        actText:SetPoint("CENTER", act, "CENTER", 0, 0)
        actText:Hide()
        act:Hide()
        act:SetScript("OnEnter", function(self2)
            actText:SetTextColor(S.text[1], S.text[2], S.text[3], 1)
            local tip = row._action and row._action.tooltip
            if tip then
                GameTooltip:SetOwner(self2, "ANCHOR_RIGHT")
                GameTooltip:SetText(tip, 1, 1, 1, 1, true)
                GameTooltip:Show()
            end
        end)
        act:SetScript("OnLeave", function()
            actText:SetTextColor(S.textMuted[1], S.textMuted[2], S.textMuted[3], 1)
            GameTooltip:Hide()
        end)
        act:SetScript("OnClick", function()
            if row._action and row._action.onClick and row._key ~= nil then
                row._action.onClick(row._key)
            end
        end)
        row._hl, row._check, row._label = hl, check, lbl
        row._icon = icon
        row._actionBtn, row._actionIcon, row._actionText = act, actIcon, actText
        row:SetScript("OnClick", function(self2)
            if self2._kind == "item" and self2._key ~= nil and setValue then setValue(self2._key) end
            if self2._kind == "item" then
                UpdateLabel()
                menu:Hide()
            end
        end)
        rowFrames[i] = row
    end

    local filtered, display, offset, selIndex = {}, {}, 0, 0
    local function RefreshList()
        local q = (search:GetText() or ""):lower()
        local src = Source()
        filtered = {}
        for i = 1, #src do
            local it = src[i]
            local label = it.label or tostring(it.key)
            if q == "" or label:lower():find(q, 1, true) then
                filtered[#filtered + 1] = it
            end
        end
        display = {}
        local lastGroup
        for i = 1, #filtered do
            local it = filtered[i]
            if opts.groups ~= false and it.group ~= nil and it.group ~= lastGroup then
                display[#display + 1] = { kind = "group", label = it.group }
            end
            lastGroup = it.group
            display[#display + 1] = { kind = "item", item = it }
        end
        if offset > math.max(0, #display - maxRows) then
            offset = math.max(0, #display - maxRows)
        end
        if offset < 0 then offset = 0 end
        if selIndex >= #display then selIndex = math.max(0, #display - 1) end
        local current = getValue and getValue()
        for i = 1, maxRows do
            local row = rowFrames[i]
            local d = display[offset + i]
            if d and d.kind == "group" then
                row._kind, row._key, row._action = "group", nil, nil
                row._check:Hide()
                row._icon:Hide()
                row._actionBtn:Hide()
                row._label:ClearAllPoints()
                row._label:SetPoint("LEFT", row, "LEFT", 8, 0)
                row._label:SetPoint("RIGHT", row, "RIGHT", -8, 0)
                row._label:SetTextColor(S.sectionText[1], S.sectionText[2], S.sectionText[3], 1)
                TruncateToFit(row._label, d.label or "", menuW - 24)
                row:Show()
            elseif d then
                local it = d.item
                local hasAction = it.action and true or false
                row._kind, row._key, row._action = "item", it.key, it.action
                row._check:Show()
                row._label:SetTextColor(S.text[1], S.text[2], S.text[3], S.text[4])
                row._label:ClearAllPoints()
                if it.icon then
                    row._icon:SetTexture(it.icon)
                    row._icon:Show()
                    row._label:SetPoint("LEFT", row._icon, "RIGHT", 6, 0)
                else
                    row._icon:Hide()
                    row._label:SetPoint("LEFT", row._check, "RIGHT", 8, 0)
                end
                if hasAction then
                    row._label:SetPoint("RIGHT", row._actionBtn, "LEFT", -4, 0)
                else
                    row._label:SetPoint("RIGHT", row, "RIGHT", -8, 0)
                end
                TruncateToFit(row._label, it.label or tostring(it.key),
                    menuW - 34 - (hasAction and 22 or 0) - (it.icon and 20 or 0))
                row._check:SetShown(current == it.key)
                if hasAction then
                    row._actionBtn:Show()
                    if it.action.icon then
                        row._actionIcon:SetTexture(it.action.icon)
                        row._actionIcon:Show()
                        row._actionText:Hide()
                    else
                        row._actionIcon:Hide()
                        row._actionText:SetText(it.action.text or opts.actionText or ">")
                        row._actionText:Show()
                    end
                else
                    row._actionBtn:Hide()
                end
                row:Show()
            else
                row._kind, row._key, row._action = nil, nil, nil
                row:Hide()
            end
        end
    end

    local function OpenMenu()
        search:SetText("")
        offset, selIndex = 0, 0
        RefreshList()
        menu:ClearAllPoints()
        menu:SetPoint("TOPLEFT", dd, "BOTTOMLEFT", 0, -2)
        menu:Show()
        search:SetFocus()
        menu._shown = true
    end
    dd:SetScript("OnClick", function()
        if menu:IsShown() then menu:Hide() else OpenMenu() end
    end)

    search:SetScript("OnTextChanged", function()
        offset, selIndex = 0, 0
        RefreshList()
    end)
    search:SetScript("OnEscapePressed", function(self2)
        self2:ClearFocus()
        menu:Hide()
    end)
    search:SetScript("OnEnterPressed", function()
        for i = 1, #display do
            local d = display[i]
            if d.kind == "item" then
                if setValue then setValue(d.item.key) end
                UpdateLabel()
                break
            end
        end
        menu:Hide()
    end)
    menu:SetScript("OnMouseWheel", function(_, delta)
        local maxOff = math.max(0, #display - maxRows)
        offset = math.max(0, math.min(maxOff, offset - delta))
        RefreshList()
    end)
    menu:RegisterEvent("GLOBAL_MOUSE_DOWN")
    menu:SetScript("OnEvent", function(self2)
        if not self2:IsShown() then return end
        local focus = GetMouseFocus and GetMouseFocus() or nil
        if focus and (IsDescendantOf(focus, self2) or IsDescendantOf(focus, dd)) then return end
        if search:HasFocus() then search:ClearFocus() end
        self2:Hide()
    end)

    dd._menu = menu
    dd._search = search
    dd._refreshList = RefreshList
    dd._openMenu = OpenMenu
    region._control = dd
    AttachTooltip(dd, nil, opts.tooltip)
    F:RegisterRefresh(UpdateLabel)
    return dd, UpdateLabel
end

-- Data-driven list rows (tables / editors with several controls per row).
--   local list, h, api = W:ListRows(parent, y, {
--       items = function() return data end,       -- or a table
--       rowH = 24,
--       columns = { 120, 90, 70 },                -- optional widths
--       header  = { "Spell", "Type", "Voice" },   -- optional header labels
--       rowBuilder = function(row, item, index, api) ... build row controls ... end,
--       rowUpdate  = function(row, item, index, api) ... refresh row ... end,
--   })
--   api.Render() re-reads items, repositions rows and calls rowUpdate;
--   api.GetRow(i), api.GetCount(), api.ColumnX(i), api.ColumnW(i) are provided.
-- rowBuilder runs once per row frame (keep closures reading row._item);
-- rowUpdate runs on every Render for now visible rows.
function F:ListRows(parent, y, opts)
    opts = opts or {}
    local T = self.Theme
    local rowH = opts.rowH or 24
    local contentW = ContentWidth(parent)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT", T.pad, y)

    local columns = opts.columns or {}
    local colX, colW = {}, {}
    local cx = 0
    for i = 1, #columns do
        local c = columns[i]
        local w = (type(c) == "table" and c.width) or c
        colX[i], colW[i] = cx, w
        cx = cx + (tonumber(w) or 0) + (opts.columnGap or 8)
    end

    local headerH = 0
    local header
    if opts.header then
        headerH = opts.headerH or 20
        header = CreateFrame("Frame", nil, frame)
        header:SetSize(contentW, headerH)
        header:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
        for i = 1, #opts.header do
            local lbl = Font(header, T.labelSize, 0.62, 0.83, 1, 1)
            lbl:SetPoint("LEFT", header, "LEFT", colX[i] or 0, 0)
            lbl:SetText(tostring(opts.header[i] or ""))
        end
    end

    local rows = {}
    local api = {
        GetRow = function(_, i) return rows[i] end,
        GetCount = function() return #rows end,
        ColumnX = function(_, i) return colX[i] or 0 end,
        ColumnW = function(_, i) return colW[i] end,
        Render = function() end,
    }
    local function Render()
        local src = (type(opts.items) == "function" and opts.items()) or opts.items or {}
        for i = 1, math.max(#src, #rows) do
            local row, item = rows[i], src[i]
            if item and not row then
                row = CreateFrame("Frame", nil, frame)
                row:SetSize(contentW, rowH)
                RowBg(row, frame, self)
                row:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -headerH - (i - 1) * rowH - 2)
                rows[i] = row
                if opts.rowBuilder then opts.rowBuilder(row, item, i, api) end
            end
            if row then
                row._item, row._index = item, i
                if item then
                    row:Show()
                    if opts.rowUpdate then opts.rowUpdate(row, item, i, api) end
                else
                    row:Hide()
                end
            end
        end
        frame:SetSize(contentW, headerH + #src * rowH + 4)
    end
    api.Render = function() Render() end
    Render()
    return frame, frame:GetHeight(), api
end

-- Drag-to-reorder list. opts = { items = table | function, onChange(keys),
-- rowH, disabled, labelMaxW }. Returns frame, height.
function F:ReorderList(parent, y, opts)
    opts = opts or {}
    local S = self:Tokens()
    local T = self.Theme
    local rowH = opts.rowH or 22
    local contentW = ContentWidth(parent)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT", T.pad, y)

    local order = {}
    local rows = {}
    local dragging

    local function Load()
        local src = (type(opts.items) == "function" and opts.items()) or opts.items or {}
        for i = 1, #src do order[i] = src[i] end
        for i = #src + 1, #order do order[i] = nil end
    end

    local function Render()
        for i = 1, #rows do
            local row = rows[i]
            local it = order[i]
            if it then
                row._key = it.key
                TruncateToFit(row._label, it.label or tostring(it.key), contentW - 30)
                row:ClearAllPoints()
                row:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -(i - 1) * rowH - 2)
                row:Show()
            else
                row._key = nil
                row:Hide()
            end
        end
        frame:SetSize(contentW, math.max(1, #order) * rowH + 4)
    end

    local function EnsureRow(i)
        local row = rows[i]
        if row then return row end
        row = CreateFrame("Button", nil, frame)
        row:SetSize(contentW, rowH)
        row:SetFrameLevel(frame:GetFrameLevel() + 1)
        -- borderless rows (only the surface + grip handle)
        local bg = QfxSurface(row, "BACKGROUND", 0, S.controlBg)
        bg:SetAllPoints()
        bg:SetAlpha(0.65)
        local handle = Font(row, T.labelSize, S.textMuted[1], S.textMuted[2], S.textMuted[3], 1)
        handle:SetPoint("LEFT", row, "LEFT", 8, 0)
        handle:SetText("=")  -- simple drag grip
        local lbl = Font(row, T.labelSize, S.text[1], S.text[2], S.text[3], S.text[4])
        lbl:SetPoint("LEFT", handle, "RIGHT", 8, 0)
        lbl:SetPoint("RIGHT", row, "RIGHT", -8, 0)
        lbl:SetJustifyH("LEFT")
        row._label, row._bg, row._handle = lbl, bg, handle

        local function Finish()
            if dragging ~= row then return end
            dragging = nil
            row:SetScript("OnUpdate", nil)
            row:SetAlpha(1)
            bg:SetAlpha(0.65)
            if opts.onChange then
                local keys = {}
                for i = 1, #order do keys[i] = order[i].key end
                opts.onChange(keys)
            end
        end
        row:SetScript("OnMouseDown", function(self2)
            if opts.disabled and opts.disabled() then return end
            dragging = self2
            self2:SetAlpha(0.85)
            bg:SetAlpha(1)
            self2:SetScript("OnUpdate", function(_, elapsed)
                if dragging ~= self2 then return end
                if IsMouseButtonDown and not IsMouseButtonDown("LeftButton") then Finish() return end
                self2._acc = (self2._acc or 0) + elapsed
                if self2._acc < 0.05 then return end
                self2._acc = 0
                local _, cy = GetCursorPosition()
                local scale = UIParent:GetEffectiveScale()
                cy = cy / scale
                local idx
                for i = 1, #order do if rows[i] == self2 then idx = i break end end
                if not idx then return end
                -- swap up
                local up = rows[idx - 1]
                if up and cy > (up:GetTop() + up:GetBottom()) / 2 then
                    order[idx], order[idx - 1] = order[idx - 1], order[idx]
                    Render()
                    return
                end
                local down = rows[idx + 1]
                if down and cy < (down:GetTop() + down:GetBottom()) / 2 then
                    order[idx], order[idx + 1] = order[idx + 1], order[idx]
                    Render()
                end
            end)
        end)
        row:SetScript("OnMouseUp", Finish)
        row:SetScript("OnHide", Finish)
        rows[i] = row
        return row
    end

    Load()
    local count = #order
    for i = 1, count do
        local row = EnsureRow(i)
        row:SetSize(contentW, rowH)
    end
    Render()
    return frame, frame:GetHeight()
end

-- Cog button + popup settings for one row. opts = { title, rows = {...DualRow
-- left cfgs...}, width, onReset, resetText, size, x, y }. Returns cog, openFn.
function F:Cog(anchor, opts)
    opts = opts or {}
    local S = self:Tokens()
    local T = self.Theme

    local btn = CreateFrame("Button", nil, anchor)
    local sz = opts.size or 16
    btn:SetSize(sz, sz)
    if opts.point then
        btn:SetPoint(opts.point, anchor, opts.relPoint or opts.point, opts.x or 0, opts.y or 0)
    else
        btn:SetPoint("RIGHT", anchor, "RIGHT", opts.x or -T.rightPad, opts.y or 0)
    end
    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints()
    icon:SetTexture("Interface\\Buttons\\UI-OptionsButton")
    icon:SetDesaturated(true)
    btn:SetAlpha(0.45)
    btn:SetScript("OnEnter", function(self2) self2:SetAlpha(0.85) end)
    btn:SetScript("OnLeave", function(self2) if not (opts.keepAlpha) then self2:SetAlpha(0.45) end end)

    local popup = CreateFrame("Frame", nil, UIParent)
    popup:SetFrameStrata("FULLSCREEN_DIALOG")
    if popup.SetFrameLevel then popup:SetFrameLevel(200) end
    if popup.SetClampedToScreen then popup:SetClampedToScreen(true) end
    popup:EnableMouse(true)
    popup:Hide()
    local popupW = opts.width or 250
    popup:SetSize(popupW, 20)
    if popup.SetScale and btn.GetEffectiveScale and UIParent and UIParent.GetEffectiveScale then
        local ds, us = btn:GetEffectiveScale(), UIParent:GetEffectiveScale()
        if ds and us and us > 0 then popup:SetScale(ds / us) end
    end
    local bg = QfxSurface(popup, "BACKGROUND", 0, S.menuBg)
    bg:SetAllPoints()
    QfxBorder(popup, popup:GetFrameLevel(), S.border, 1, 1)
    if opts.title then
        local title = Font(popup, T.labelSize, S.sectionText[1], S.sectionText[2], S.sectionText[3], 1)
        title:SetPoint("TOPLEFT", popup, "TOPLEFT", 10, -8)
        title:SetText(opts.title)
    end

    self._rowCounts[popup] = 0
    local py = -28
    if opts.rows then
        for i = 1, #opts.rows do
            local row, h = self:DualRow(popup, py, opts.rows[i], nil)
            py = py - h
        end
    end
    if opts.onReset then
        local _, h = self:WideButton(popup, opts.resetText or "Reset", py - 2, function()
            opts.onReset()
            self:Refresh()
        end)
        py = py - h
    end
    popup:SetHeight(math.abs(py) + 8)

    local function Open()
        popup:ClearAllPoints()
        popup:SetPoint("TOPRIGHT", btn, "BOTTOMLEFT", 0, 4)
        popup:Show()
        self:Refresh()
    end
    btn:SetScript("OnClick", function()
        if popup:IsShown() then popup:Hide() else Open() end
    end)
    popup:RegisterEvent("GLOBAL_MOUSE_DOWN")
    popup:SetScript("OnEvent", function(self2)
        if not self2:IsShown() then return end
        local focus = GetMouseFocus and GetMouseFocus() or nil
        if focus and (IsDescendantOf(focus, self2) or IsDescendantOf(focus, btn)) then return end
        self2:Hide()
    end)
    popup:HookScript("OnHide", function() btn:SetAlpha(0.45) end)

    return btn, Open
end

-------------------------------------------------------------------------------
-- Scrollable page (self-drawn scrollbar: wheel + thumb drag, no templates)
-------------------------------------------------------------------------------
-- Standard flow:
--   local page = W:ScrollPage(parent)              -- or { width, height }
--   local y = -W.Theme.pad
--   ... build rows into page.content, decreasing y ...
--   page:SetContentHeight(-y + W.Theme.pad)
-- page.frame is the container (anchor it yourself unless opts.point given);
-- page.content is the frame rows are built into; the scrollbar hides itself
-- when everything fits. opts: { width, height, point, relPoint, x, y, padding,
-- barWidth, scrollStep, onScroll(offset, maxOffset) }.
-- Scrollable page (real scroll frame -> content is CLIPPED to the page; the
-- scrollbar itself is self-drawn: wheel + thumb drag, no templates).
-------------------------------------------------------------------------------
-- Standard flow:
--   local page = W:ScrollPage(parent)              -- or { width, height }
--   local y = -W.Theme.pad
--   ... build rows into page.content, decreasing y ...
--   page:SetContentHeight(-y + W.Theme.pad)
-- page.frame is the container (anchor it yourself unless opts.point given);
-- page.content is the frame rows are built into; the scrollbar hides itself
-- when everything fits (opts.reserveBar keeps its width reserved so row widths
-- never change). opts: { width, height, point, relPoint, x, y, padding,
-- barWidth, scrollStep, reserveBar, onScroll(offset, maxOffset) }.
function F:ScrollPage(parent, opts)
    opts = opts or {}
    local T = self.Theme
    local S = self:Tokens()
    local barW = opts.barWidth or 4
    local step = opts.scrollStep or 40
    local reserveBar = opts.reserveBar and true or false

    local holder = CreateFrame("Frame", nil, parent)
    if opts.width and opts.height then
        holder:SetSize(opts.width, opts.height)
    else
        holder:SetAllPoints(parent)
    end
    if opts.point then
        holder:SetPoint(opts.point, parent, opts.relPoint or opts.point, opts.x or 0, opts.y or 0)
    end
    holder:EnableMouseWheel(true)
    holder._qfx = "scrollPage"

    local viewport = CreateFrame("ScrollFrame", nil, holder)
    viewport:SetPoint("TOPLEFT", holder, "TOPLEFT", 0, 0)
    local content = CreateFrame("Frame", nil, viewport)
    content:SetPoint("TOPLEFT", viewport, "TOPLEFT", 0, 0)
    if viewport.SetScrollChild then viewport:SetScrollChild(content) end

    local bar = CreateFrame("Frame", nil, holder)
    bar:SetWidth(barW)
    bar:SetPoint("TOPRIGHT", holder, "TOPRIGHT", 0, 0)
    bar:SetPoint("BOTTOMRIGHT", holder, "BOTTOMRIGHT", 0, 0)
    local barBg = QfxSurface(bar, "BACKGROUND", 0, S.controlBg)
    barBg:SetAllPoints()
    local thumb = CreateFrame("Button", nil, bar)
    thumb:SetWidth(barW)
    local thumbTex = QfxSurface(thumb, "ARTWORK", 0, S.border)
    thumbTex:SetAllPoints()
    thumb:SetScript("OnEnter", function() thumbTex:SetColorTexture(S.borderHi[1], S.borderHi[2], S.borderHi[3], S.borderHi[4] or 1) end)
    thumb:SetScript("OnLeave", function() thumbTex:SetColorTexture(S.border[1], S.border[2], S.border[3], S.border[4] or 1) end)
    bar:Hide()

    local offset, maxOffset, contentH, viewH = 0, 0, 0, 0

    local function Layout()
        local w = holder:GetWidth() or 0
        viewH = holder:GetHeight() or 0
        maxOffset = math.max(0, contentH - viewH)
        local barShown = maxOffset > 0.5
        bar:SetShown(barShown)
        local innerW = w - ((barShown or reserveBar) and (barW + 2) or 0)
        viewport:SetSize(math.max(1, innerW), math.max(1, viewH))
        content:SetSize(math.max(1, innerW), math.max(1, contentH))
        if offset > maxOffset then offset = maxOffset end
        if offset < 0 then offset = 0 end
        offset = floor(offset + 0.5) -- whole-pixel scroll: no shaved edge at the clip line
        if viewport.SetVerticalScroll then viewport:SetVerticalScroll(offset) end
        if barShown then
            local thumbH = math.max(24, viewH * (viewH / contentH))
            thumb:SetHeight(math.min(viewH, thumbH))
            local travel = math.max(0, viewH - thumb:GetHeight())
            local ratio = (maxOffset > 0) and (offset / maxOffset) or 0
            thumb:ClearAllPoints()
            thumb:SetPoint("TOPRIGHT", bar, "TOPRIGHT", 0, -travel * ratio)
        end
    end

    local function ScrollTo(v)
        offset = math.max(0, math.min(v or 0, maxOffset))
        Layout()
        if opts.onScroll then opts.onScroll(offset, maxOffset) end
    end

    holder:SetScript("OnMouseWheel", function(_, delta)
        if maxOffset <= 0 then return end
        ScrollTo(offset - delta * step)
    end)
    holder:SetScript("OnSizeChanged", Layout)
    holder:SetScript("OnShow", Layout)

    local dragging, dragY, dragOffset
    thumb:SetScript("OnMouseDown", function(_, button)
        if button ~= "LeftButton" or maxOffset <= 0 then return end
        dragging, dragY, dragOffset = true, select(2, GetCursorPosition()), offset
    end)
    thumb:SetScript("OnUpdate", function()
        if not dragging then return end
        if IsMouseButtonDown and not IsMouseButtonDown("LeftButton") then dragging = false return end
        local _, cy = GetCursorPosition()
        local scale = thumb:GetEffectiveScale() or 1
        local travel = viewH - (thumb:GetHeight() or 0)
        if travel <= 0 then return end
        ScrollTo(dragOffset + ((cy - dragY) / scale) * (maxOffset / travel))
    end)
    thumb:SetScript("OnMouseUp", function() dragging = false end)
    thumb:SetScript("OnHide", function() dragging = false end)

    Layout()
    return {
        frame = holder,
        content = content,
        viewport = viewport,
        scrollBar = bar,
        thumb = thumb,
        ScrollTo = function(_, v) return ScrollTo(v) end,
        GetOffset = function() return offset end,
        GetMaxOffset = function() return maxOffset end,
        SetContentHeight = function(_, h)
            contentH = h or 0
            content:SetHeight(math.max(contentH, viewH))
            Layout()
        end,
        Refresh = Layout,
    }
end

-------------------------------------------------------------------------------
-- Multiline text box (import / export / long text, self-drawn frame)
-------------------------------------------------------------------------------
-- F:MultilineBox(parent, y, cfg) -> frame, height
-- cfg = { label, hint, height = 120, rows, text?, getValue, setValue, readOnly,
-- maxLetters, commitOnEnter, selectAllOnFocus (default true), onCommit }
-- frame:GetText() / frame:SetText(v) / frame:Commit() are provided.
function F:MultilineBox(parent, y, cfg)
    cfg = cfg or {}
    local S = self:Tokens()
    local T = self.Theme
    local boxH = cfg.height or ((cfg.rows and (cfg.rows * 14 + 10)) or 120)
    local hasLabel, hasHint = cfg.label and true or false, cfg.hint and true or false
    local totalH = boxH + (hasLabel and 18 or 0) + (hasHint and 16 or 0) + 4

    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(ContentWidth(parent), totalH)
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT", T.pad, y)

    local top = 0
    if hasLabel then
        local lbl = Font(frame, T.labelSize, S.sectionText[1], S.sectionText[2], S.sectionText[3], 1)
        lbl:SetPoint("TOPLEFT", frame, "TOPLEFT", T.sidePad, 0)
        lbl:SetText(cfg.label)
        top = -18
    end

    local box = CreateFrame("EditBox", nil, frame)
    box:SetSize(ContentWidth(frame) - T.sidePad * 2, boxH)
    box:SetPoint("TOPLEFT", frame, "TOPLEFT", T.sidePad, top - 2)
    box:SetMultiLine(true)
    box:SetAutoFocus(false)
    if box.SetMaxLetters then box:SetMaxLetters(cfg.maxLetters or 0) end
    if box.SetJustifyV then box:SetJustifyV("TOP") end
    local bg = QfxSurface(box, "BACKGROUND", 0, S.controlBg)
    bg:SetAllPoints()
    local brd = QfxBorder(box, box:GetFrameLevel(), S.border, 1, 1)
    box:SetFont(T.font, S.textSize, "")
    box:SetTextColor(S.text[1], S.text[2], S.text[3], S.text[4])
    box:SetJustifyH("LEFT")
    box:SetTextInsets(6, 6, 4, 4)

    local function Read()
        local v = cfg.getValue and cfg.getValue() or cfg.text or ""
        return tostring(v or "")
    end
    local function Commit()
        if cfg.readOnly then return end
        local text = box:GetText() or ""
        if cfg.setValue then cfg.setValue(text) end
        if cfg.onCommit then cfg.onCommit(text) end
    end
    box:SetText(Read())
    if cfg.readOnly then
        box:SetScript("OnChar", function() end)
    end
    box:SetScript("OnEnterPressed", function(self2)
        if cfg.commitOnEnter then
            Commit()
            self2:ClearFocus()
        end
    end)
    box:SetScript("OnEscapePressed", function(self2)
        self2:SetText(Read())
        self2:ClearFocus()
    end)
    box:SetScript("OnEditFocusGained", function(self2)
        brd._setBorder(S.borderHi or S.border)
        if cfg.selectAllOnFocus ~= false and (cfg.readOnly or cfg.selectAllOnFocus) and self2.HighlightText then
            self2:HighlightText()
        end
    end)
    box:SetScript("OnEditFocusLost", function()
        brd._setBorder(S.border)
        Commit()
        if not cfg.readOnly then box:SetText(Read()) end
    end)

    if hasHint then
        local hint = Font(frame, S.textSize - 1, S.textMuted[1], S.textMuted[2], S.textMuted[3], S.textMuted[4])
        hint:SetPoint("TOPLEFT", box, "BOTTOMLEFT", 2, -3)
        hint:SetText(cfg.hint)
    end

    AttachTooltip(frame, cfg.label or cfg.text, cfg.tooltip)
    frame._box = box
    frame.GetText = function() return box:GetText() end
    frame.SetText = function(_, v) box:SetText(tostring(v or "")) end
    frame.Commit = function() Commit() end
    F:RegisterRefresh(function()
        if not box:HasFocus() then box:SetText(Read()) end
    end)
    return frame, totalH
end

-------------------------------------------------------------------------------
-- Confirmation dialog (self-drawn, Esc / backdrop click cancels)
-------------------------------------------------------------------------------
-- W:Confirm(opts) or W:Confirm("text") -> dialog
-- opts = { title, text, acceptText, cancelText, onAccept, onCancel, width,
-- danger = true (red accept button) }. dialog:Close() hides it.
function F:Confirm(opts)
    if type(opts) == "string" then opts = { text = opts } end
    opts = opts or {}
    local S = self:Tokens()
    local T = self.Theme

    local dim = CreateFrame("Frame", nil, UIParent)
    dim:SetAllPoints()
    dim:SetFrameStrata("DIALOG")
    dim:EnableMouse(true)
    if dim.EnableKeyboard then dim:EnableKeyboard(true) end
    local dimTex = dim:CreateTexture(nil, "BACKGROUND")
    dimTex:SetAllPoints()
    dimTex:SetColorTexture(0, 0, 0, 0.45)

    local w = opts.width or 360
    local panel = CreateFrame("Frame", nil, dim)
    panel:SetSize(w, 10)
    panel:SetPoint("CENTER", dim, "CENTER", 0, 0)
    panel:EnableMouse(true)
    local bg = QfxSurface(panel, "BACKGROUND", 0, S.menuBg)
    bg:SetAllPoints()
    QfxBorder(panel, panel:GetFrameLevel(), S.border, 1, 1)

    local title = Font(panel, T.labelSize, S.sectionText[1], S.sectionText[2], S.sectionText[3], 1)
    title:SetPoint("TOPLEFT", panel, "TOPLEFT", 14, -12)
    title:SetText(opts.title or "Confirm")

    local text = Font(panel, S.textSize, S.text[1], S.text[2], S.text[3], S.text[4])
    text:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)
    text:SetPoint("RIGHT", panel, "RIGHT", -14, 0)
    text:SetJustifyH("LEFT")
    if text.SetWordWrap then text:SetWordWrap(true) end
    text:SetText(opts.text or "")
    local textH = (text.GetStringHeight and text:GetStringHeight()) or 20
    if textH < 16 then textH = 16 end

    local closed = false
    local function Finish(accepted)
        if closed then return end
        closed = true
        dim:Hide()
        if accepted then
            if opts.onAccept then opts.onAccept() end
        else
            if opts.onCancel then opts.onCancel() end
        end
    end

    local function MakeButton(txt, xOff, isAccept)
        local b = CreateFrame("Button", nil, panel)
        local bw, bh = 92, 24
        b:SetSize(bw, bh)
        b:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", xOff, 12)
        local base = isAccept and opts.danger and S.danger or (isAccept and S.accent or S.buttonBg)
        local bbg = QfxSurface(b, "BACKGROUND", 0, base)
        bbg:SetAllPoints()
        local bbrd = QfxBorder(b, b:GetFrameLevel(), S.border, 1, 1)
        local blbl = Font(b, S.textSize, 0.98, 0.99, 1, 1)
        blbl:SetPoint("CENTER", b, "CENTER", 0, 0)
        blbl:SetText(txt)
        b:SetScript("OnEnter", function()
            bbg:SetColorTexture(base[1] * 1.25, base[2] * 1.25, base[3] * 1.25, base[4] or 1)
            bbrd._setBorder(S.borderHi or S.border)
        end)
        b:SetScript("OnLeave", function()
            bbg:SetColorTexture(base[1], base[2], base[3], base[4] or 1)
            bbrd._setBorder(S.border)
        end)
        b:SetScript("OnClick", function() Finish(isAccept) end)
        return b
    end
    local accept = MakeButton(opts.acceptText or "Confirm", -14, true)
    local cancel = MakeButton(opts.cancelText or "Cancel", -114, false)

    panel:SetHeight(12 + 16 + 10 + textH + 12 + 24 + 12)
    dim:SetScript("OnKeyDown", function(_, k)
        if k == "ESCAPE" then Finish(false) end
    end)
    dim:SetScript("OnMouseDown", function(_, button)
        if button == "LeftButton" then Finish(false) end
    end)
    dim:Show()
    dim._accept, dim._cancel, dim._panel = accept, cancel, panel
    dim.Close = function(_, accepted) Finish(accepted and true or false) end
    return dim
end

-------------------------------------------------------------------------------
-- SharedMedia helpers (LibSharedMedia-3.0 loaded by any host; all optional)
-------------------------------------------------------------------------------
-- W:LSM() -> media object or nil
-- W:MediaList(kind) -> sorted { { key = name, label = name }, ... }
--   kind: "sound" | "font" | "statusbar" | "background" | "border"
--   Feed MediaList straight into W:SearchableDropdown / values + order.
-- W:MediaValues(kind) -> values, order (for { type = "dropdown" } cfgs)
-- W:FetchMedia(kind, name) -> path | nil (SetFont / SetTexture / PlaySoundFile)
-- W:PreviewSound(name, channel) -> bool (plays a SharedMedia sound)
function F:LSM()
    if self._lsm ~= nil then return self._lsm or nil end
    local ok, media = false, nil
    if LibStub then ok, media = pcall(LibStub, "LibSharedMedia-3.0", true) end
    self._lsm = (ok and media) or false
    return self._lsm or nil
end

function F:MediaList(kind)
    local media = self:LSM()
    local out, seen = {}, {}
    if media and media.HashTable then
        local ok, tbl = pcall(media.HashTable, media, kind)
        if ok and type(tbl) == "table" then
            for name in pairs(tbl) do
                if not seen[name] then
                    seen[name] = true
                    out[#out + 1] = { key = name, label = name }
                end
            end
        end
    end
    if media and media.List then
        local ok, names = pcall(media.List, media, kind)
        if ok and type(names) == "table" then
            for i = 1, #names do
                local name = names[i]
                if name and not seen[name] then
                    seen[name] = true
                    out[#out + 1] = { key = name, label = name }
                end
            end
        end
    end
    table.sort(out, function(a, b) return a.label < b.label end)
    return out
end

function F:MediaValues(kind)
    local list = self:MediaList(kind)
    local values, order = {}, {}
    for i = 1, #list do
        values[list[i].key] = list[i].label
        order[i] = list[i].key
    end
    return values, order
end

function F:FetchMedia(kind, name)
    local media = self:LSM()
    if not (media and media.Fetch and name and name ~= "") then return nil end
    local ok, path = pcall(media.Fetch, media, kind, name)
    if ok and path and path ~= "" then return path end
    return nil
end

function F:PreviewSound(name, channel)
    local path = self:FetchMedia("sound", name) or (name ~= "" and name or nil)
    if path and PlaySoundFile then
        local ok = pcall(PlaySoundFile, path, channel or "Master")
        return ok
    end
    return false
end

-------------------------------------------------------------------------------
-- Icon picker (icon button + searchable dropdown with per-row icons)
-------------------------------------------------------------------------------
-- W:IconPicker(parent, frameLevel, getValue, setValue, opts)
--   -> button, refreshFn. opts = { items = table|function (as SearchableDropdown,
--   each item may carry .icon), width, size, tooltip, placeholder }.
-- W:SpellIconItems(list) -> items from { id | { id, label }, ... } using the
--   spell texture of each id (falls back to the question mark icon).
function F:SpellIconItems(list)
    local out = {}
    for i = 1, #(list or {}) do
        local e = list[i]
        local id = type(e) == "table" and (e.id or e.key) or e
        local label = type(e) == "table" and (e.label or tostring(id)) or tostring(id)
        local icon = (C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(id))
            or (GetSpellTexture and GetSpellTexture(id))
            or "Interface\\ICONS\\INV_Misc_QuestionMark"
        out[i] = { key = id, label = label, icon = icon }
    end
    return out
end

function F:IconPicker(parent, frameLevel, getValue, setValue, opts)
    opts = opts or {}
    local S, T = self:Tokens(), self.Theme
    local dd = self:SearchableDropdown(parent, opts.width or 240, frameLevel, opts.items, getValue, setValue, opts)
    local holder = dd:GetParent()

    local sz = opts.size or 20
    local btn = CreateFrame("Button", nil, holder)
    btn:SetSize(sz, sz)
    btn:SetPoint("RIGHT", holder, "RIGHT", -T.rightPad, 0)
    local bg = QfxSurface(btn, "BACKGROUND", 0, S.controlBg)
    bg:SetAllPoints()
    local brd = QfxBorder(btn, btn:GetFrameLevel(), S.border, 1, 1)
    local tex = btn:CreateTexture(nil, "ARTWORK")
    tex:SetAllPoints()
    tex:Hide()
    local fallback = Font(btn, S.textSize, S.textMuted[1], S.textMuted[2], S.textMuted[3], 1)
    fallback:SetPoint("CENTER", btn, "CENTER", 0, 0)
    fallback:SetText("?")

    local function Update()
        local key = getValue and getValue()
        local src = type(opts.items) == "function" and opts.items() or opts.items or {}
        local icon
        for i = 1, #src do
            if src[i].key == key then icon = src[i].icon end
        end
        if icon then
            tex:SetTexture(icon)
            tex:Show()
            fallback:Hide()
        else
            tex:Hide()
            fallback:Show()
        end
    end
    Update()

    btn:SetScript("OnClick", function() dd._openMenu() end)
    btn:SetScript("OnEnter", function(self2)
        brd._setBorder(S.borderHi or S.border)
        local tip = opts.tooltip
        if tip then
            GameTooltip:SetOwner(self2, "ANCHOR_RIGHT")
            GameTooltip:SetText(tip, 1, 1, 1, 1, true)
            GameTooltip:Show()
        end
    end)
    btn:SetScript("OnLeave", function()
        brd._setBorder(S.border)
        GameTooltip:Hide()
    end)

    btn._tex, btn._fallback, btn._dropdown = tex, fallback, dd
    dd:Hide() -- the icon button is the opener; the menu still anchors to dd
    F:RegisterRefresh(Update)
    return btn, Update
end

-------------------------------------------------------------------------------
-- Status row (dynamic text, optional label + color)
-------------------------------------------------------------------------------
-- W:StatusRow(parent, y, opts) -> frame, height
-- opts = { label, getText (string|function), color (table|function),
--          wrap, height }. Refreshed by W:Refresh(); frame:Update() forces one.
function F:StatusRow(parent, y, opts)
    opts = opts or {}
    local S, T = self:Tokens(), self.Theme
    local h = opts.height or 18
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(ContentWidth(parent), h)
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT", T.pad, y)

    local x = T.sidePad
    if opts.label then
        local lbl = Font(frame, T.labelSize, S.textMuted[1], S.textMuted[2], S.textMuted[3], S.textMuted[4])
        lbl:SetPoint("LEFT", frame, "LEFT", x, 0)
        lbl:SetText(opts.label)
        local lw = lbl.GetStringWidth and lbl:GetStringWidth() or nil
        if IsSecret(lw) or not lw then lw = #tostring(opts.label) * 8 end
        x = x + lw + 8
    end
    local val = Font(frame, S.textSize, S.text[1], S.text[2], S.text[3], S.text[4])
    val:SetPoint("LEFT", frame, "LEFT", x, 0)
    val:SetPoint("RIGHT", frame, "RIGHT", -T.rightPad, 0)
    val:SetJustifyH("LEFT")
    if opts.wrap then
        if val.SetWordWrap then val:SetWordWrap(true) end
    else
        if val.SetWordWrap then val:SetWordWrap(false) end
        if val.SetMaxLines then val:SetMaxLines(1) end
    end

    local function Update()
        local text = opts.getText
        if type(text) == "function" then text = text() end
        val:SetText(tostring(text or ""))
        local c = opts.color
        if type(c) == "function" then c = c() end
        if c then
            val:SetTextColor(c[1], c[2], c[3], c[4] or 1)
        else
            val:SetTextColor(S.text[1], S.text[2], S.text[3], S.text[4] or 1)
        end
    end
    Update()
    frame._value = val
    frame._qfx = "statusRow"
    frame._refresh = Update
    frame.Update = function() Update() end
    F:RegisterRefresh(Update)
    return frame, h
end

-------------------------------------------------------------------------------
-- Full-width slider row (label above the track, value box + steppers right)
-------------------------------------------------------------------------------
-- W:Slider(parent, y, cfg) -> frame, height. Same cfg fields as
-- { type = "slider" } (min, max, step, getValue, setValue, valueSuffix,
-- steppers, tooltip, disabled, disabledTooltip, trackWidth) plus:
--   cfg.label (defaults to cfg.text) and cfg.height.
-- Use it for long labels or full-width fine tuning; DualRow sliders stay
-- available for compact two-column pages.
function F:Slider(parent, y, cfg)
    cfg = cfg or {}
    local S, T = self:Tokens(), self.Theme
    local h = cfg.height or 58
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(ContentWidth(parent), h)
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT", T.pad, y)
    RowBg(frame, parent, self)

    local label = Font(frame, T.labelSize, S.text[1], S.text[2], S.text[3], S.text[4])
    label:SetPoint("TOPLEFT", frame, "TOPLEFT", T.sidePad, -2)
    label:SetText(cfg.label or cfg.text or "")

    local region = CreateFrame("Frame", nil, frame)
    region:SetSize(ContentWidth(parent), h - 18)
    region:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -18)
    region._label = label
    QfxSlider(region, frame, cfg)
    return frame, h
end

-------------------------------------------------------------------------------
-- Color grid (per-cell color swatches with labels, groups optional)
-------------------------------------------------------------------------------
-- W:ColorGrid(parent, y, columns, entries, opts) -> frame, height, countFn
-- entries = { { label, getValue -> r,g,b[,a], setValue(r,g,b[,a]), tooltip,
--   group, alpha, disabled, disabledTooltip }, ... }. Like CheckGrid but each
-- cell is a color swatch that opens the picker.
function F:ColorGrid(parent, y, columns, entries, opts)
    opts = opts or {}
    local S, T = self:Tokens(), self.Theme
    local cols = math.max(1, tonumber(columns) or 2)
    local contentW = ContentWidth(parent)
    local gap = opts.gap or 12
    local cellW = floor((contentW - gap * (cols - 1)) / cols)
    local cellH = opts.rowH or 22
    local groupH = opts.groupH or 20
    entries = entries or {}

    local layout, yOff, col = {}, 0, 0
    local lastGroup
    for i = 1, #entries do
        local e = entries[i]
        if e.group ~= nil and e.group ~= lastGroup then
            lastGroup = e.group
            if col ~= 0 then yOff = yOff + cellH; col = 0 end
            layout[#layout + 1] = { kind = "group", label = e.group, top = yOff }
            yOff = yOff + groupH
        end
        layout[#layout + 1] = { kind = "cell", entry = e, col = col, top = yOff }
        col = col + 1
        if col >= cols then col = 0; yOff = yOff + cellH end
    end
    local totalH = yOff + (col > 0 and cellH or 0) + 4

    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(contentW, totalH)
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT", T.pad, y)

    local swatches = {}
    for i = 1, #layout do
        local item = layout[i]
        if item.kind == "group" then
            local gl = Font(frame, T.labelSize, S.sectionText[1], S.sectionText[2], S.sectionText[3], 1)
            gl:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -item.top - 2)
            gl:SetText(tostring(item.label or ""))
        else
            local e = item.entry
            local cell = CreateFrame("Frame", nil, frame)
            cell:SetSize(cellW, cellH)
            cell:SetPoint("TOPLEFT", frame, "TOPLEFT", item.col * (cellW + gap), -item.top - 2)
            local sw = MakeQfxColorSwatch(cell, 16, e.getValue, e.setValue, { alpha = e.alpha })
            sw:SetPoint("LEFT", cell, "LEFT", 0, 0)
            swatches[#swatches + 1] = sw
            local lbl = Font(cell, T.labelSize, S.text[1], S.text[2], S.text[3], S.text[4])
            lbl:SetPoint("LEFT", sw, "RIGHT", 6, 0)
            lbl:SetPoint("RIGHT", cell, "RIGHT", 0, 0)
            lbl:SetJustifyH("LEFT")
            TruncateToFit(lbl, e.label or e.text or "", cellW - 26)
            if e.tooltip or e.help then AttachTooltip(lbl, e.label, e.tooltip or e.help) end
            if e.disabled or e.disabledTooltip then
                local disabled, tip = e.disabled, e.disabledTooltip
                local block
                local function RefreshDisabled()
                    local off = disabled and disabled() and true or false
                    if not block then
                        block = CreateFrame("Frame", nil, cell)
                        block:SetAllPoints()
                        block:SetFrameLevel(cell:GetFrameLevel() + 8)
                        block:EnableMouse(true)
                        block:Hide()
                        if tip then
                            block:SetScript("OnEnter", function(self2)
                                local reason = type(tip) == "function" and tip() or tip
                                if reason and reason ~= "" then
                                    GameTooltip:SetOwner(self2, "ANCHOR_RIGHT")
                                    GameTooltip:SetText(reason, 1, 1, 1, 1, true)
                                    GameTooltip:Show()
                                end
                            end)
                            block:SetScript("OnLeave", function() GameTooltip:Hide() end)
                        end
                    end
                    sw:SetAlpha(off and 0.35 or 1)
                    lbl:SetAlpha(off and 0.35 or 1)
                    block:SetShown(off)
                end
                self:RegisterRefresh(RefreshDisabled)
                RefreshDisabled()
            end
        end
    end
    F:RegisterRefresh(function()
        for i = 1, #swatches do swatches[i]._update() end
    end)
    return frame, totalH, function() return #swatches end
end

-------------------------------------------------------------------------------
-- Reset row ("Reset this page" style buttons on the right, optional label)
-------------------------------------------------------------------------------
-- W:ResetRow(parent, y, opts) -> frame, height
-- opts = { label, buttons = { { text, onReset, confirm, confirmText, danger }, ... },
--          buttonText, onReset, confirm, confirmText, width }
-- Rightmost button is the last entry. confirm = true asks W:Confirm first.
function F:ResetRow(parent, y, opts)
    opts = opts or {}
    local S, T = self:Tokens(), self.Theme
    local h = (T.wideButtonH or 34) + 6
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(ContentWidth(parent), h)
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT", T.pad, y)
    RowBg(frame, parent, self)

    if opts.label then
        local lbl = Font(frame, S.textSize, S.textMuted[1], S.textMuted[2], S.textMuted[3], S.textMuted[4])
        lbl:SetPoint("LEFT", frame, "LEFT", T.sidePad, 0)
        lbl:SetText(opts.label)
    end

    local specs = opts.buttons or { { text = opts.buttonText or "Reset", onReset = opts.onReset,
        confirm = opts.confirm, confirmText = opts.confirmText, danger = opts.danger } }
    local xOff = -T.rightPad
    local made = {}
    for i = #specs, 1, -1 do
        local spec = specs[i]
        local btn = CreateFrame("Button", nil, frame)
        local bw = spec.width or opts.width or 116
        btn:SetSize(bw, S.buttonH or 20)
        btn:SetPoint("RIGHT", frame, "RIGHT", xOff, 0)
        xOff = xOff - bw - 6
        local base = spec.danger and S.danger or (S.buttonBg or S.controlBg)
        local bg = QfxSurface(btn, "BACKGROUND", 0, base)
        bg:SetAllPoints()
        local brd = QfxBorder(btn, btn:GetFrameLevel(), S.buttonBorder or S.border, 1, 1)
        local lbl = Font(btn, S.textSize, 0.98, 0.99, 1, 1)
        lbl:SetPoint("CENTER", btn, "CENTER", 0, 0)
        lbl:SetText(spec.text or "Reset")
        btn:SetScript("OnEnter", function()
            bg:SetColorTexture(base[1] * 1.25, base[2] * 1.25, base[3] * 1.25, base[4] or 1)
            brd._setBorder(S.borderHi or S.border)
        end)
        btn:SetScript("OnLeave", function()
            bg:SetColorTexture(base[1], base[2], base[3], base[4] or 1)
            brd._setBorder(S.buttonBorder or S.border)
        end)
        btn:SetScript("OnClick", function()
            local function Run()
                if spec.onReset then spec.onReset() end
                self:Refresh()
            end
            if spec.confirm then
                self:Confirm({
                    title = spec.confirmTitle or spec.text or "Reset",
                    text = spec.confirmText or "Are you sure?",
                    acceptText = spec.acceptText, cancelText = spec.cancelText,
                    danger = true, onAccept = Run,
                })
            else
                Run()
            end
        end)
        if spec.tooltip then AttachTooltip(btn, spec.text, spec.tooltip) end
        btn._label = lbl
        made[#made + 1] = btn
    end
    frame._buttons = made
    frame._qfx = "resetRow"
    return frame, h
end

