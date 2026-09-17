-- Exercise the production deck logic without loading game UI code.
local file = assert(io.open("QFXSystemBar/Defaults.lua", "rb"))
local source = file:read("*a"):gsub("\r\n", "\n")
file:close()
local code = assert(source:match("(function ns%.RefreshRandomHearthstoneCache%(%).-\nend)\n\nlocal function GetItemIconMarkup")
    or source:match("(function ns%.RefreshRandomHearthstoneCache%(%).-\nend)\n\nfunction ns%.BuildHearthstoneMacro"))

local scans = 0
local available = { 101, 102, 103 }
local ns = {
    GetAvailableRandomHearthstones = function()
        scans = scans + 1
        local copy = {}
        for i, id in ipairs(available) do copy[i] = id end
        return copy
    end,
}
assert(load(code, "hearthstone-deck", "t", setmetatable({ ns = ns }, { __index = _G })))()

math.randomseed(17)
local first = {}
for _ = 1, 3 do first[#first + 1] = ns.PickRandomHearthstoneItemID("left") end
assert(scans == 1, "collection was rescanned for each draw")
local seen = {}
for _, id in ipairs(first) do seen[id] = true end
assert(seen[101] and seen[102] and seen[103], "deck did not cover all owned items")
local nextDraw = ns.PickRandomHearthstoneItemID("left")
assert(nextDraw ~= first[#first], "new deck repeated the previous draw")
assert(scans == 1, "new deck unnecessarily rescanned collection")

available = { 201 }
ns.RefreshRandomHearthstoneCache()
assert(ns.PickRandomHearthstoneItemID("left") == 201, "explicit refresh did not replace the deck")
assert(scans == 2, "explicit refresh did not rescan exactly once")
print("Random hearthstone deck tests passed")
