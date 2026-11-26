-- Guild against a stand-in for the core's mod API: the differences between two readings of a roster
-- (Activity.lua), what is kept in RynaDB.guild, and the rows, tiles and words of the window's section
-- (Section.lua). From the repository root, with Lua 5.1 (what the game runs) or later:
--
--   lua5.1 test/guild_test.lua
-- luacheck: ignore 1

local ADDON = "Ryna_Guild/"
local failures, checks = 0, 0
local function check(cond, what)
  checks = checks + 1
  if not cond then
    failures = failures + 1
    print("FAIL: " .. what)
  end
end

local DAY = 86400
local now = 1800000000
local db = { characters = {}, guilds = {} }
local handlers, commands, debounced, printed, opened, refreshed = {}, {}, {}, {}, nil, 0
local section

local function passResults(ok, ...)
  if ok then return ... end
  return nil
end

_G.Ryna = {
  API = 2, VERSION = "test", L = setmetatable({}, { __index = function(_, k) return k end }),
  Try = function(fn, ...)
    if type(fn) ~= "function" then return nil end
    return passResults(pcall(fn, ...))
  end,
  Fn = function() return nil end,
  IsSecret = function() return false end,
  NonEmpty = function(v) if type(v) == "string" and v ~= "" then return v end end,
  Now = function() return now end,
  Print = function(m) printed[#printed + 1] = m end,
  Debug = function() end,
  Run = function(_, fn, ...) return fn(...) end,
  Debounce = function(key, _, fn) debounced[key] = fn end,
  On = function(event, f) handlers[event] = f end,
  Ago = function(t)
    if type(t) ~= "number" then return nil end
    return string.format("%d days ago", math.floor((now - t) / DAY))
  end,
  DB = function() return db end,
  RegisterMod = function(spec) _G.registered = spec return true end,
  Slash = { Add = function(spec) commands[spec.word] = spec end },
  Window = {
    AddSection = function(spec) section = spec return true end,
    ClassColor = function(class) return "|c" .. tostring(class) .. ":" end,
    Match = function(text, search)
      if search == "" then return true end
      return type(text) == "string" and text:lower():find(search, 1, true) ~= nil
    end,
    Open = function(key) opened = key end,
    Refresh = function() refreshed = refreshed + 1 end,
  },
}

local ns = {}
for _, file in ipairs({ "Mod.lua", "Locales/enUS.lua", "Activity.lua", "Section.lua", "Init.lua" }) do
  assert(loadfile(ADDON .. file))("Ryna_Guild", ns)
end
local A, S = ns.Activity, ns.Section
check(not ns.off and _G.registered and _G.registered.id == "guild", "Guild registers as a mod")
check(section and section.key == "guild" and section.group == "world" and section.characters == "one",
  "and adds one section to the window")

-- A roster as Chronicle keeps it. ---------------------------------------------------------------------
local function member(guid, name, class, level, rankIndex, rankName, over)
  local m = { guid = guid, fullName = name, class = class, level = level, rankIndex = rankIndex,
    rankName = rankName, zone = "Ironforge", note = "", online = false, lastOnlineAt = now - 2 * DAY }
  for k, v in pairs(over or {}) do m[k] = v end
  return m
end

local KEY = "Emberwake-6931"
local function reading(asOf, roster)
  db.guilds[KEY] = { guid = KEY, name = "Emberwake", rosterAsOf = asOf, roster = roster }
  return db.guilds[KEY]
end
db.characters.me = { guild = { guid = KEY, name = "Emberwake" } }
db.characters.loner = {}

local first = {
  member("P-1", "Tamsin Harrow", "DRUID", 32, 1, "Officer", { online = true, note = "Herbs" }),
  member("P-2", "Brannoc Vale", "WARRIOR", 42, 3, "Initiate"),
  member("P-3", "Odette Farrow", "WARLOCK", 36, 2, "Member", { lastOnlineAt = now - 34 * DAY }),
  member("P-4", "Sable Wick", "WARLOCK", 20, 2, "Member"),
  member("P-5", "Halden Rook", "SHAMAN", 25, 2, "Member", { lastOnlineAt = now - 22 * DAY }),
  member(nil, "Wren Talbot", "HUNTER", 28, 2, "Member", { lastOnlineAt = now - 61 * DAY }),
}

-- The first reading is kept, and says nothing. --------------------------------------------------------
check(A.Take(reading(now, first)) == "first", "a guild's first reading is only kept")
check(#db.guild.guilds[KEY].activity == 0 and db.guild.guilds[KEY].count == 6, "with no activity and its size")
check(db.guild.guilds[KEY].members["Wren Talbot"] ~= nil, "a member without a GUID is kept by name")
check(A.Take(db.guilds[KEY]) == "same", "the same reading again is not compared twice")

-- The second: one of each change. ---------------------------------------------------------------------
now = now + 600
local second = {
  member("P-1", "Tamsin Harrow", "DRUID", 33, 1, "Officer", { online = true, note = "Herbs, will craft" }),
  member("P-2", "Brannoc Stone", "WARRIOR", 42, 2, "Member"), -- renamed, promoted
  member("P-3", "Odette Farrow", "WARLOCK", 36, 3, "Initiate", { lastOnlineAt = now - 34 * DAY }), -- demoted
  member("P-5", "Halden Rook", "SHAMAN", 25, 2, "Member", { online = true }), -- back after 22 days
  member("P-6", "Perrin Locke", "ROGUE", 19, 3, "Initiate", { officerNote = "watch this one" }),
  member(nil, "Wren Talbot", "HUNTER", 28, 2, "Member", { lastOnlineAt = now - 61 * DAY }),
}
check(A.Take(reading(now, second)) == 7, "seven differences in the second reading")
local act = db.guild.guilds[KEY].activity
local function has(kind, name)
  for _, e in ipairs(act) do
    if e.kind == kind and e.name == name then return e end
  end
end
check(has("join", "Perrin Locke") and has("leave", "Sable Wick"), "someone joined and someone left")
local lvl = has("level", "Tamsin Harrow")
check(lvl and lvl.a == 32 and lvl.b == 33, "a level, from and to")
local up, down = has("rank", "Brannoc Stone"), has("rank", "Odette Farrow")
check(up and up.up == true and up.b == "Member", "a promotion, by the lower rank index, under the new name")
check(down and down.up == false and down.b == "Initiate", "a demotion")
check(not has("join", "Brannoc Stone") and not has("leave", "Brannoc Vale"), "a rename is neither a leave nor a join")
check(has("note", "Tamsin Harrow").b == "Herbs, will craft", "a public note's new text")
local back = has("back", "Halden Rook")
check(back and back.a == 22, "back after the days they were away")
for _, e in ipairs(act) do
  for _, v in pairs(e) do check(v ~= "watch this one", "an officer note is never copied into the activity") end
end
check(not has("back", "Tamsin Harrow"), "someone who was on last time isn't back")

-- A half-loaded roster is skipped whole. --------------------------------------------------------------
now = now + 600
check(A.Take(reading(now, { second[1], second[2] })) == "partial", "two members after six is a partial reading")
check(#act == 7 and db.guild.guilds[KEY].count == 6, "which changes nothing kept")
reading(now, second)

-- The cap. --------------------------------------------------------------------------------------------
do
  local kept = db.guild.guilds[KEY]
  local filler = {}
  for i = 1, 600 do filler[i] = { at = now, kind = "level", name = "x" .. i, b = 2 } end
  kept.activity = filler
  now = now + 600
  local third = {}
  for i, m in ipairs(second) do third[i] = m end
  third[#third + 1] = member("P-7", "Lysa Thorne", "PALADIN", 22, 3, "Initiate")
  A.Take(reading(now, third))
  check(#filler == 500 and filler[500].name == "Lysa Thorne" and filler[1].name == "x102",
    "at most 500 changes: the newest kept, the oldest dropped")
  act[#act + 1] = filler[500]
  kept.activity = act
end

-- The event, as the game sends it. ---------------------------------------------------------------------
handlers.GUILD_ROSTER_UPDATE()
check(type(debounced["guild-activity"]) == "function", "a roster update waits a moment, then scans")
debounced["guild-activity"]()
check(refreshed > 0, "and the section is redrawn")

-- The section: the roster. ----------------------------------------------------------------------------
local function ctx(over)
  local c = { character = "me", current = "me", search = "", filter = nil }
  for k, v in pairs(over or {}) do c[k] = v end
  return c
end
local rows = section.rows(ctx())
check(#rows == 7, "a row for each member")
check(rows[1].cells[6]:find("Online", 1, true) and rows[2].cells[6]:find("Online", 1, true), "online members first")
check(rows[1].cells[1] == "Halden Rook" and rows[2].cells[1] == "Tamsin Harrow", "by name among the online")
check(rows[#rows].cells[1] == "Wren Talbot" and rows[#rows].cells[6] == "61 days ago", "longest away last")
check(rows[2].color == "|cDRUID:" and rows[2].cells[2] == "Officer" and rows[2].cells[3] == "33",
  "a row's class colour, rank and level")
check(#section.rows(ctx({ search = "craft" })) == 1 and #section.rows(ctx({ search = "initiate" })) == 3,
  "the search reads names, ranks, zones and notes")
check(section.title(ctx()) == "Emberwake › Roster", "the title is the guild and the view")
local tiles = section.tiles(ctx())
check(tiles[1].value == "7" and tiles[2].value == "2" and tiles[3].value == "2" and tiles[4].value == "2",
  "tiles: members, online, quiet 30 days, joined this week")
check(section.footer(ctx()):find("0 days ago", 1, true), "the footer says how old the reading is")

-- Quiet. ----------------------------------------------------------------------------------------------
local quiet = section.rows(ctx({ filter = "quiet30" }))
check(#quiet == 2 and quiet[1].cells[1] == "Wren Talbot" and quiet[1].cells[5] == "61 days"
  and quiet[2].cells[1] == "Odette Farrow", "quiet 30 days: longest away first")
check(#section.rows(ctx({ filter = "quiet90" })) == 0 and section.empty(ctx({ filter = "quiet90" })) ==
  "Nobody has been away that long.", "an empty quiet list says so")
check(section.title(ctx({ filter = "quiet60" })) == "Emberwake › Quiet 60 days", "its title")
check(#section.columns(ctx({ filter = "quiet14" })) == 5 and #section.columns(ctx()) == 6, "its own columns")
check(#section.filter(ctx()) == 6, "six views in the picker")

-- Activity. -------------------------------------------------------------------------------------------
local activity = section.rows(ctx({ filter = "activity" }))
check(#activity == 8 and activity[1].cells[2] == "|cPALADIN:Lysa Thorne|r joined the guild", "the newest change first")
local function sentence(text)
  for _, r in ipairs(activity) do
    if r.cells[2] == text then return true end
  end
end
check(sentence("|cWARRIOR:Brannoc Stone|r was promoted to Member"), "a promotion as a sentence")
check(sentence("|cWARLOCK:Odette Farrow|r was demoted to Initiate"), "a demotion")
check(sentence("|cDRUID:Tamsin Harrow|r reached level 33"), "a level")
check(sentence("|cDRUID:Tamsin Harrow|r changed their note: Herbs, will craft"), "a note")
check(sentence("|cSHAMAN:Halden Rook|r came back after 22 days"), "someone back")
check(sentence("|cWARLOCK:Sable Wick|r left the guild"), "someone gone")
check(S.Sentence({ kind = "note", name = "A", b = "" }) == "|cnil:A|r cleared their note", "a note cleared")
check(#section.rows(ctx({ filter = "activity", search = "promoted" })) == 1, "the search reads the sentences")

-- No guild. -------------------------------------------------------------------------------------------
local alone = ctx({ character = "loner" })
check(#section.rows(alone) == 0 and #section.tiles(alone) == 0 and section.footer(alone) == "",
  "a character in no guild")
check(section.empty(alone):find("isn't in a guild", 1, true) and section.title(alone) == "Guild › Roster", "says so")
check(#section.rows(ctx({ character = nil })) == 7, "All characters means the one you're on")

-- The version moves with a new reading. ----------------------------------------------------------------
local v = section.version()
now = now + 600
A.Take(reading(now, db.guilds[KEY].roster))
check(section.version() ~= v, "a new reading changes the section's version")

-- /ryna guild, and login. -------------------------------------------------------------------------------
commands.guild.run()
check(opened == "guild", "/ryna guild opens the section")
db.guild = nil
_G.registered.onLogin()
check(db.guild.guilds[KEY] ~= nil, "at login the roster already there is taken in")
check(#printed == 0, "Guild says nothing in chat unasked")

print(string.format("guild: %d checks, %d failed", checks, failures))
os.exit(failures == 0 and 0 or 1)
