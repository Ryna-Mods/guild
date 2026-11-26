-- Mod: Guild's namespace, built from the core's mod API (the `Ryna` table, the core addon's Mods.lua).
-- Guild shows the player's guild in Ryna's window (ryna_agent docs/ryna-agent-cores-mods.md 7.8): the
-- roster, what changed between two readings of it, and who has gone quiet. Chronicle reads the roster
-- (RynaDB.guilds, at login and every ten minutes); Guild reads that and keeps what it works out under
-- RynaDB.guild: the last reading it compared and the list of changes (Activity.lua).
--
-- This version does nothing in the game: it changes no note, rank or membership, and sends nothing
-- to other players. What it keeps about guild members is what the guild pane shows any member.
--
-- Every file starts with `if ns.off then return end`: without the mod API (a core addon from before
-- it), Guild loads nothing at all, and says nothing either.

local addonName, ns = ...

local R = _G.Ryna
-- The core API level this mod needs is the TOC's (## X-Ryna-API), the one place it is written;
-- on a core below it nothing loads, and the core's Mods tab says why.
local needs, known = 1, false
do
  local read = (_G.C_AddOns and _G.C_AddOns.GetAddOnMetadata) or _G.GetAddOnMetadata
  local ok, level = pcall(function() return tonumber(read(addonName, "X-Ryna-API")) end)
  if ok and level then needs, known = level, true end
end
-- Nor on a core that no longer serves this mod's level (R.API_MIN, absent on a core before it);
-- only when the TOC's level could be read, so a client that won't say never turns the mod off.
local tooOld = known and type(R) == "table" and type(R.API_MIN) == "number" and needs < R.API_MIN
if type(R) ~= "table" or type(R.API) ~= "number" or R.API < needs or tooOld or type(R.RegisterMod) ~= "function" then
  ns.off = true
  return
end

ns.NAME = addonName
ns.API = R

-- The version is the TOC's, so there is no second copy to keep in step.
local metadata = (_G.C_AddOns and _G.C_AddOns.GetAddOnMetadata) or _G.GetAddOnMetadata
ns.VERSION = R.Try(metadata, addonName, "Version")

for _, name in ipairs({ "Try", "Fn", "IsSecret", "NonEmpty", "Now", "Print", "Debug", "Run", "Debounce", "On",
  "Ago" }) do
  ns[name] = R[name]
end

-- Guild's strings (Locales/), falling back to the core's (Ryna.L), which fall back to the key.
ns.L = setmetatable({}, {
  __index = function(_, key) return R.L[key] end,
  __newindex = function(t, key, value)
    if type(value) == "string" and value ~= "" then rawset(t, key, value) end
  end,
})
