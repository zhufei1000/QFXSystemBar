local _, ns = ...
local API={}
_G.QFXSystemBarAPI=API
function API.OpenOptions(key)
    local manager=rawget(_G,"QFXAddonManagerAPI")
    if manager and manager.OpenAddonSettings then return manager.OpenAddonSettings("QFXSystemBar",key) end
    if ns.EnsureConfigLoaded() then
        if key and ns.SelectConfigPage then return ns.SelectConfigPage(key) end
        ns.OpenConfigFrame()
    end
end
-- Explicit native fallback for the manager's "open options" action.
function API.OpenNativeOptions(key)
    if not ns.EnsureConfigLoaded() then return false end
    if key and ns.SelectNativeConfigPage then
        if ns.SelectNativeConfigPage(key) then return true end
    end
    if ns.OpenNativeConfigFrame then return ns.OpenNativeConfigFrame() end
    return false
end

function API.GetSettingsDefinition(context)
    if not ns.EnsureConfigLoaded() or not ns.GetManagerSettingsDefinition then return nil end
    return ns.GetManagerSettingsDefinition(context)
end
