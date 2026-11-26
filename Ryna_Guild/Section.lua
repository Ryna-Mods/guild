-- Section: Guild's section of Ryna's window (Ryna.Window.AddSection; docs 7.8, "In game first"). One
-- section with a picker of views, since the window gives a section one picker of its own:
--
--   Roster          every member: name (in the class's colour), rank, level, zone, note, last online
--   Activity        what changed between readings of the roster, newest first (Activity.lua)
--   Quiet N days    members not seen for 14, 30, 60 or 90 days, longest away first
--
-- The guild is the picked character's (the one you're on, under "All characters"), from the roster
-- Chronicle keeps in RynaDB.guilds. Nothing here acts: a row has no click.

local _, ns = ...
if ns.off then return end
local L = ns.L
local A = ns.Activity

local S = {}
ns.Section = S
S.KEY = "guild"

local RW = ns.API.Window
local DAY = 86400
local WEEK = 7 * DAY
local ACTIVITY = "activity"
local QUIET = { 14, 30, 60, 90 }
local ONLINE_COLOR = "|cff58c26a"

-- The picked character's guild as Chronicle last read it (nil when it has none, or none read yet).
function S.Guild(ctx)
  local db = ns.API.DB()
  if type(db) ~= "table" then return nil end
  local chars = db.characters
  local rec = type(chars) == "table" and chars[ctx.character or ctx.current]
  local key = type(rec) == "table" and type(rec.guild) == "table" and rec.guild.guid
  local guild = key and type(db.guilds) == "table" and db.guilds[key]
  if type(guild) == "table" and type(guild.roster) == "table" then return guild end
  return nil
end

-- The view the picker is on: nil (the roster), "activity", or a number of quiet days.
local function view(ctx)
  local f = ctx.filter
  if f == ACTIVITY then return ACTIVITY end
  local days = type(f) == "string" and tonumber(f:match("^quiet(%d+)$"))
  return days or nil
end

local function viewLabel(v)
  if v == ACTIVITY then return L["Activity"] end
  if type(v) == "number" then return string.format(L["Quiet %d days"], v) end
  return L["Roster"]
end

local function colored(name, class)
  return RW.ClassColor(class) .. tostring(name or "?") .. "|r"
end

local function awayDays(row, now)
  if row.online or type(row.lastOnlineAt) ~= "number" then return nil end
  return math.floor((now - row.lastOnlineAt) / DAY)
end

local function matches(row, search)
  if search == "" then return true end
  return RW.Match(row.fullName, search) or RW.Match(row.rankName, search) or RW.Match(row.zone, search)
    or RW.Match(row.note, search)
end

-- Roster ------------------------------------------------------------------------------------------------

local ROSTER_COLUMNS = {
  { title = L["Name"], width = 170 }, { title = L["Rank"], width = 96 },
  { title = L["Level"], width = 40, justify = "RIGHT" }, { title = L["Zone"], width = 126 },
  { title = L["Note"], width = 100 }, { title = L["Last online"], width = 84, justify = "RIGHT" },
}

function S.RosterRows(ctx, guild)
  local now, rows = ns.Now(), {}
  for _, m in ipairs(guild.roster) do
    if type(m) == "table" and matches(m, ctx.search) then
      local seen = m.online and now + 1 or (type(m.lastOnlineAt) == "number" and m.lastOnlineAt or 0)
      rows[#rows + 1] = {
        cells = { tostring(m.fullName or "?"), m.rankName or "", m.level and tostring(m.level) or "",
          m.zone or "", m.note or "",
          m.online and (ONLINE_COLOR .. L["Online"] .. "|r") or ns.Ago(m.lastOnlineAt) or "" },
        sort = { tostring(m.fullName or ""), m.rankIndex or 99, m.level or 0, m.zone or "", m.note or "", seen },
        color = RW.ClassColor(m.class), seen = seen,
      }
    end
  end
  -- Online first, then most recently seen; a name breaks a tie.
  table.sort(rows, function(x, y)
    if x.seen ~= y.seen then return x.seen > y.seen end
    return x.cells[1] < y.cells[1]
  end)
  return rows
end

-- Quiet -------------------------------------------------------------------------------------------------

local QUIET_COLUMNS = {
  { title = L["Name"], width = 190 }, { title = L["Rank"], width = 110 },
  { title = L["Level"], width = 40, justify = "RIGHT" }, { title = L["Note"], width = 176 },
  { title = L["Away"], width = 100, justify = "RIGHT" },
}

-- How many members have been away at least `days`.
function S.QuietCount(guild, days, now)
  local n = 0
  for _, m in ipairs(guild.roster) do
    local away = type(m) == "table" and awayDays(m, now)
    if away and away >= days then n = n + 1 end
  end
  return n
end

function S.QuietRows(ctx, guild, days)
  local now, rows = ns.Now(), {}
  for _, m in ipairs(guild.roster) do
    local away = type(m) == "table" and awayDays(m, now)
    if away and away >= days and matches(m, ctx.search) then
      rows[#rows + 1] = {
        cells = { tostring(m.fullName or "?"), m.rankName or "", m.level and tostring(m.level) or "",
          m.note or "", string.format(L["%d days"], away) },
        sort = { tostring(m.fullName or ""), m.rankIndex or 99, m.level or 0, m.note or "", away },
        color = RW.ClassColor(m.class), away = away,
      }
    end
  end
  table.sort(rows, function(x, y)
    if x.away ~= y.away then return x.away > y.away end
    return x.cells[1] < y.cells[1]
  end)
  return rows
end

-- Activity ----------------------------------------------------------------------------------------------

local ACTIVITY_COLUMNS = {
  { title = L["When"], width = 110 }, { title = L["What changed"], width = 506 },
}

-- One change as a sentence, the member's name in their class's colour.
function S.Sentence(e)
  local who = colored(e.name, e.class)
  if e.kind == "join" then return string.format(L["%s joined the guild"], who) end
  if e.kind == "leave" then return string.format(L["%s left the guild"], who) end
  if e.kind == "level" then return string.format(L["%s reached level %d"], who, e.b or 0) end
  if e.kind == "rank" then
    return string.format(e.up and L["%s was promoted to %s"] or L["%s was demoted to %s"], who, tostring(e.b or "?"))
  end
  if e.kind == "note" then
    if (e.b or "") == "" then return string.format(L["%s cleared their note"], who) end
    return string.format(L["%s changed their note: %s"], who, e.b)
  end
  if e.kind == "back" then return string.format(L["%s came back after %d days"], who, e.a or 0) end
  return who
end

function S.ActivityRows(ctx, guild)
  local kept = A.Kept(guild.guid)
  local list = kept and kept.activity or {}
  local rows = {}
  for i = #list, 1, -1 do -- newest first
    local e = list[i]
    local text = S.Sentence(e)
    if RW.Match(text, ctx.search) then
      rows[#rows + 1] = { cells = { ns.Ago(e.at) or "", text }, sort = { e.at or 0, tostring(e.name or "") } }
    end
  end
  return rows
end

-- The section -------------------------------------------------------------------------------------------

function S.Tiles(ctx)
  local guild = S.Guild(ctx)
  if not guild then return {} end
  local now, online = ns.Now(), 0
  for _, m in ipairs(guild.roster) do
    if type(m) == "table" and m.online then online = online + 1 end
  end
  local joined = 0
  local kept = A.Kept(guild.guid)
  for _, e in ipairs(kept and kept.activity or {}) do
    if e.kind == "join" and type(e.at) == "number" and now - e.at < WEEK then joined = joined + 1 end
  end
  return {
    { label = L["Members"], value = tostring(#guild.roster) },
    { label = L["Online"], value = tostring(online) },
    { label = L["Quiet 30 days"], value = tostring(S.QuietCount(guild, 30, now)) },
    { label = L["Joined this week"], value = tostring(joined) },
  }
end

function S.Rows(ctx)
  local guild = S.Guild(ctx)
  if not guild then return {} end
  local v = view(ctx)
  if v == ACTIVITY then return S.ActivityRows(ctx, guild) end
  if type(v) == "number" then return S.QuietRows(ctx, guild, v) end
  return S.RosterRows(ctx, guild)
end

function S.Empty(ctx)
  if not S.Guild(ctx) then
    return L["This character isn't in a guild, or Chronicle hasn't read its roster yet. "
      .. "Chronicle reads it at login and every ten minutes."]
  end
  local v = view(ctx)
  if v == ACTIVITY then
    return L["Nothing has changed since Guild started watching. Who joins, leaves, levels or changes rank shows here."]
  end
  if type(v) == "number" then return L["Nobody has been away that long."] end
  return L["Nobody matches."]
end

-- Changes with every reading Chronicle takes and everything Activity works out from one.
function S.Version()
  local db = ns.API.DB()
  local sum = 0
  for _, guild in pairs(type(db) == "table" and type(db.guilds) == "table" and db.guilds or {}) do
    if type(guild) == "table" and type(guild.rosterAsOf) == "number" then sum = sum + guild.rosterAsOf end
  end
  return tostring(A.version) .. ":" .. tostring(sum)
end

-- Redraws the section if it is the one on screen.
function S.Changed()
  if type(RW) == "table" and type(RW.Refresh) == "function" then RW.Refresh(S.KEY) end
end

S.available = type(RW) == "table" and type(RW.AddSection) == "function"

if S.available then
  local filter = { { value = nil, label = L["Roster"] }, { value = ACTIVITY, label = L["Activity"] } }
  for _, days in ipairs(QUIET) do
    filter[#filter + 1] = { value = "quiet" .. days, label = string.format(L["Quiet %d days"], days) }
  end
  S.registered = RW.AddSection({
    key = S.KEY, group = "world", order = 30, label = L["Guild"], characters = "one",
    title = function(ctx)
      local guild = S.Guild(ctx)
      return string.format(L["%s › %s"], guild and tostring(guild.name) or L["Guild"], viewLabel(view(ctx)))
    end,
    filter = function() return filter end,
    columns = function(ctx)
      local v = view(ctx)
      if v == ACTIVITY then return ACTIVITY_COLUMNS end
      if type(v) == "number" then return QUIET_COLUMNS end
      return ROSTER_COLUMNS
    end,
    rows = S.Rows, tiles = S.Tiles, empty = S.Empty, version = S.Version,
    footer = function(ctx)
      local guild = S.Guild(ctx)
      if not guild then return "" end
      return string.format(
        L["The roster as Chronicle read it %s. Guild only shows it: it changes nothing in your guild."],
        ns.Ago(guild.rosterAsOf) or L["at some time"])
    end,
  }) and true or false
end
