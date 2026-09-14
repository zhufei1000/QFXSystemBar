-- Regression coverage for QFXWidgets' owner-scoped refresh registry.
-- Run from the repository root: lua tests/QFXWidgets_refresh_test.lua
local function expect(condition, message)
    if not condition then error(message or "expectation failed", 2) end
end

-- A foreign addon may define this global; RegisterRefresh must not read it.
_G.owner = "some_foreign_owner"

local ns = {}
_G.QFXWidgets = nil
local chunk = assert(loadfile("QFXSystemBar_Config/QFXWidgets.lua"))
chunk("QFXWidgets", ns)
local W = _G.QFXWidgets
expect(type(W) == "table" and type(W.RegisterRefresh) == "function", "factory did not load")

local calls = {}

-- Two pages register callbacks; both must be refreshable.
W:BeginPage("p1")
W:RegisterRefresh(function() calls[#calls + 1] = "p1a" end)
W:EndPage()
W:BeginPage("p2")
W:RegisterRefresh(function() calls[#calls + 1] = "p2" end)
W:EndPage()
W:Refresh()
expect(#calls == 2, "both pages must refresh, got " .. #calls)

-- Rebuilding page 1 must drop only page 1's old callbacks.
calls = {}
W:BeginPage("p1")
W:RegisterRefresh(function() calls[#calls + 1] = "p1b" end)
W:EndPage()
W:Refresh()
expect(#calls == 2, "page 1 rebuild must leave p1b + p2, got " .. #calls)
expect(calls[1] ~= "p1a", "stale page 1 callback survived the rebuild")

-- RefreshPage only runs that owner's callbacks.
calls = {}
W:RefreshPage("p1")
expect(#calls == 1 and calls[1] == "p1b", "RefreshPage did not stay page-scoped")

-- Ownerless registrations (sub-tab strips) must still run on a global refresh.
W:RegisterRefresh(function() calls[#calls + 1] = "global" end)
W:Refresh()
expect(calls[#calls] == "global", "ownerless callback missing from global refresh")

-- ClearRefreshes(owner) must not touch other owners or ownerless callbacks.
W:ClearRefreshes("p1")
calls = {}
W:Refresh()
expect(#calls == 2, "ClearRefreshes(owner) dropped unrelated callbacks: " .. #calls)

print("QFXWidgets refresh registry tests passed")
