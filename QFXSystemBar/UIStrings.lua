local addonName, ns = ...

-- ========================================================================
-- English-source UI text model
-- ------------------------------------------------------------------------
-- Rule for the whole addon UI:
--   * Code stores only stable English source keys.
--   * Locale files translate those English source keys.
--   * Controls are rendered through ns.UIText/ns.SetUIText.
--   * Tooltips store source keys and translate at hover time.
--   * SavedVariables store only stable IDs/values, never localized labels.
-- ========================================================================

local function NormalizeKey(key)
    if key == nil then return "" end
    if type(key) ~= "string" then return tostring(key) end
    if ns.NormalizeLocaleKey then return ns.NormalizeLocaleKey(key) end
    return key
end

function ns.UIKey(key)
    return NormalizeKey(key)
end

function ns.UIText(key)
    key = NormalizeKey(key)
    if key == "" then return "" end
    if ns.IsEnglishLocaleActive and ns.IsEnglishLocaleActive() and ns.GetEnglishSourceText then
        return ns.GetEnglishSourceText(key)
    end
    if ns.T then return ns.T(key) end
    local L = ns.L
    return (L and L[key]) or key
end

function ns.UIFormat(key, ...)
    local ok, text = pcall(string.format, ns.UIText(key), ...)
    if ok then return text end
    return ns.UIText(key)
end

-- Weak-key registry.  It is not the source of truth; it only lets already
-- created persistent controls refresh without rebuilding.  New pages still use
-- English source keys from Options.lua/Config.lua when they are created.
ns.UITextRegistry = ns.UITextRegistry or setmetatable({}, { __mode = "k" })

function ns.SetUIText(object, key, prefix, suffix)
    if not object or not object.SetText then return object end
    key = NormalizeKey(key)
    object.qfxTextKey = key
    object.qfxTextPrefix = prefix or ""
    object.qfxTextSuffix = suffix or ""
    ns.UITextRegistry[object] = {
        key = key,
        prefix = object.qfxTextPrefix,
        suffix = object.qfxTextSuffix,
    }
    object:SetText((object.qfxTextPrefix or "") .. ns.UIText(key) .. (object.qfxTextSuffix or ""))
    return object
end

function ns.RefreshUIText(object)
    if not object or not object.SetText then return end
    local info = ns.UITextRegistry and ns.UITextRegistry[object]
    local key = object.qfxTextKey or (info and info.key)
    if not key then return end
    local prefix = object.qfxTextPrefix or (info and info.prefix) or ""
    local suffix = object.qfxTextSuffix or (info and info.suffix) or ""
    object:SetText(prefix .. ns.UIText(key) .. suffix)
end

function ns.RefreshRegisteredUIText()
    for object in pairs(ns.UITextRegistry or {}) do
        ns.RefreshUIText(object)
    end
end

function ns.SetUITooltip(owner, titleKey, bodyKey)
    if not owner or not owner.SetScript then return end
    owner.qfxTooltipTitleKey = NormalizeKey(titleKey)
    owner.qfxTooltipBodyKey = NormalizeKey(bodyKey)
    owner:SetScript("OnEnter", function(self)
        local body = self.qfxTooltipBodyKey
        if not body or body == "" then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:ClearLines()
        GameTooltip:AddLine(ns.UIText(self.qfxTooltipTitleKey), 1, 1, 1)
        GameTooltip:AddLine(ns.UIText(body), 0.85, 0.85, 0.85, true)
        GameTooltip:Show()
    end)
    owner:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end

function ns.GetOptionTextKey(opt)
    if not opt then return "" end
    return NormalizeKey(opt.textKey or opt.nameKey or opt.labelKey or opt.name or "")
end

function ns.GetOptionTooltipKey(opt)
    if not opt then return "" end
    return NormalizeKey(opt.tooltipKey or opt.tooltip or "")
end

function ns.MakeOption(data)
    data = data or {}
    if data.nameKey then
        data.nameKey = NormalizeKey(data.nameKey)
    elseif data.name then
        data.nameKey = NormalizeKey(data.name)
    end

    if data.tooltipKey then
        data.tooltipKey = NormalizeKey(data.tooltipKey)
    elseif data.tooltip then
        data.tooltipKey = NormalizeKey(data.tooltip)
    end

    if data.textKey then
        data.textKey = NormalizeKey(data.textKey)
    elseif data.text then
        data.textKey = NormalizeKey(data.text)
    end

    -- Do not keep localized display copies.  Older code paths may read name or
    -- tooltip, so mirror the canonical English source key only.
    data.name = data.nameKey
    data.tooltip = data.tooltipKey
    data.text = data.textKey
    return data
end

function ns.MakeOptionEntries(entries)
    local out = {}
    for i, item in ipairs(entries or {}) do
        out[i] = {
            value = item.value ~= nil and item.value or item[1],
            textKey = NormalizeKey(item.textKey or item.text or item.name or item[2]),
        }
    end
    return out
end
