-- Exercise the production mount list with a mocked journal and both factions.
local source = assert(io.open("QFXSystemBar_InfoBar/InfoBar.lua", "rb"))
local text = source:read("*a"):gsub("\r\n", "\n")
source:close()

local infoCode = assert(text:match("(local function GetMountInfo.-)\nlocal function GetMountActionName"))
local optionsCode = assert(text:match("(function ns%.GetMountDropdownOptions%(%).-\nend)\n\nlocal function SummonConfiguredMount"))

local factionGroup = "Horde"
local mounts = {
    [1] = { "Neutral", false, nil, false, true },
    [2] = { "Horde", true, 0, false, true },
    [3] = { "Alliance", true, 1, false, true },
    [4] = { "Hidden", false, nil, true, true },
    [5] = { "Uncollected", false, nil, false, false },
}
local env = setmetatable({
    ns = { MOUNT_RANDOM_VALUE = "random" },
    LT = function(s) return s end,
    GetMountActionIcon = function() return 99 end,
    UnitFactionGroup = function() return factionGroup end,
    C_MountJournal = {
        GetMountIDs = function() return { 1, 2, 3, 4, 5 } end,
        GetMountInfoByID = function(id)
            local m = mounts[id]
            return m[1], id + 100, id + 200, false, true, 0, false,
                m[2], m[3], m[4], m[5]
        end,
    },
}, { __index = _G })
assert(load(infoCode .. "\n" .. optionsCode, "mount-options", "t", env))()

local function checkFaction(group, expected)
    factionGroup = group
    local options = env.ns.GetMountDropdownOptions()
    local actual = {}
    for _, option in ipairs(options) do actual[option.value] = true end
    assert(#options == 4, group .. ": unexpected option count " .. #options)
    for _, value in ipairs(expected) do assert(actual[value], group .. ": missing " .. value) end
    assert(not actual["4"] and not actual["5"], group .. ": hidden or uncollected mount included")
end

checkFaction("Horde", { "none", "random", "1", "2" })
checkFaction("Alliance", { "none", "random", "1", "3" })
print("Mount faction option tests passed")
