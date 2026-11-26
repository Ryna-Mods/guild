-- Activity: what changed in a guild between two readings of its roster (docs 7.8, "Activity is a
-- difference"). Chronicle writes each reading to RynaDB.guilds[key] with the time it was taken
-- (rosterAsOf); a moment after the roster updates, Guild compares that reading with the last one it
-- kept and appends the differences:
--
--   RynaDB.guild.guilds[key] = {
--     asOf     = the reading last compared,
--     members  = { [id] = { name, class, level, rankIndex, rankName, note, seen } },
--     activity = { { at, kind, id, name, class, a, b }, ... }   oldest first, at most MAX_EVENTS
--   }
--
-- A member's id is their GUID, so a rename is neither a leave nor a join; a row without one is
-- matched by name. kind is "join", "leave", "level" (a, b: the levels), "rank" (a, b: the rank
-- names, up = true for a promotion), "note" (b: the new public note) or "back" (a: days away).
-- Officer notes are never copied here. The first reading of a guild is only kept, never compared:
-- a guild seen for the first time didn't just gain all its members. A reading with fewer than
-- half the members of the last is skipped whole: the roster loads in pieces, and a half-loaded
-- one would say that most of the guild left.

local _, ns = ...
if ns.off then return end

local A = {}
ns.Activity = A

A.MAX_EVENTS = 500
A.BACK_DAYS = 14
A.version = 0 -- raised whenever a guild's kept reading or activity changes (the window's section)

local DAY = 86400

local function idOf(row)
  return ns.NonEmpty(row.guid) or ns.NonEmpty(row.fullName)
end

-- One reading as Guild keeps it: by member id, only what a difference is taken over.
function A.Snapshot(roster, asOf)
  local members, count = {}, 0
  for _, row in ipairs(roster) do
    local id = type(row) == "table" and idOf(row)
    if id then
      count = count + 1
      members[id] = {
        name = row.fullName, class = row.class, level = row.level, rankIndex = row.rankIndex,
        rankName = row.rankName, note = row.note,
        seen = row.online and asOf or row.lastOnlineAt,
      }
    end
  end
  return members, count
end

local function event(at, kind, id, m, a, b)
  return { at = at, kind = kind, id = id, name = m.name, class = m.class, a = a, b = b }
end

-- The differences from `before` to `after` (two Snapshots), as events dated `at`, in a steady order:
-- by kind as listed above, then by name.
function A.Diff(before, after, at)
  local out = {}
  for id, m in pairs(after) do
    local was = before[id]
    if not was then
      out[#out + 1] = event(at, "join", id, m)
    else
      if type(m.level) == "number" and type(was.level) == "number" and m.level > was.level then
        out[#out + 1] = event(at, "level", id, m, was.level, m.level)
      end
      if type(m.rankIndex) == "number" and type(was.rankIndex) == "number" and m.rankIndex ~= was.rankIndex then
        local e = event(at, "rank", id, m, was.rankName, m.rankName)
        e.up = m.rankIndex < was.rankIndex -- rank 0 is the guild master
        out[#out + 1] = e
      end
      if (m.note or "") ~= (was.note or "") then
        out[#out + 1] = event(at, "note", id, m, nil, m.note or "")
      end
      -- Back: seen in this reading, and last seen long before the reading before it.
      if type(m.seen) == "number" and m.seen >= at and type(was.seen) == "number" then
        local days = math.floor((at - was.seen) / DAY)
        if days >= A.BACK_DAYS then out[#out + 1] = event(at, "back", id, m, days) end
      end
    end
  end
  for id, was in pairs(before) do
    if not after[id] then out[#out + 1] = event(at, "leave", id, was) end
  end
  local order = { join = 1, leave = 2, level = 3, rank = 4, note = 5, back = 6 }
  table.sort(out, function(x, y)
    if order[x.kind] ~= order[y.kind] then return order[x.kind] < order[y.kind] end
    return tostring(x.name) < tostring(y.name)
  end)
  return out
end

-- RynaDB.guild, made on first use.
function A.Store()
  local db = ns.API.DB()
  if type(db) ~= "table" then return nil end
  if type(db.guild) ~= "table" then db.guild = {} end
  if type(db.guild.guilds) ~= "table" then db.guild.guilds = {} end
  return db.guild
end

-- What Guild keeps of one guild (nil before its first reading).
function A.Kept(key)
  local store = A.Store()
  return store and store.guilds[key] or nil
end

-- Takes one of Chronicle's readings in: "first", "same", "partial" (skipped) or the number of
-- differences appended.
function A.Take(guild)
  local store = A.Store()
  if not store or type(guild) ~= "table" or type(guild.roster) ~= "table" or not guild.guid then return nil end
  local asOf = type(guild.rosterAsOf) == "number" and guild.rosterAsOf or ns.Now()
  local kept = store.guilds[guild.guid]
  if kept and kept.asOf == asOf then return "same" end
  local members, count = A.Snapshot(guild.roster, asOf)
  if not kept or type(kept.members) ~= "table" then
    store.guilds[guild.guid] = { asOf = asOf, members = members, count = count, activity = {} }
    A.version = A.version + 1
    return "first"
  end
  if count * 2 < (kept.count or 0) then
    ns.Debug("guild: a reading of %d members after one of %d is skipped as partly loaded", count, kept.count or 0)
    return "partial"
  end
  local events = A.Diff(kept.members, members, asOf)
  if type(kept.activity) ~= "table" then kept.activity = {} end
  for _, e in ipairs(events) do kept.activity[#kept.activity + 1] = e end
  while #kept.activity > A.MAX_EVENTS do table.remove(kept.activity, 1) end
  kept.asOf, kept.members, kept.count = asOf, members, count
  A.version = A.version + 1
  if #events > 0 then ns.Debug("guild: %d changes in %s", #events, tostring(guild.name)) end
  return #events
end

-- Every guild Chronicle has a reading of.
function A.Scan()
  local db = ns.API.DB()
  if type(db) ~= "table" or type(db.guilds) ~= "table" then return end
  for _, guild in pairs(db.guilds) do A.Take(guild) end
  if ns.Section and ns.Section.Changed then ns.Section.Changed() end
end

-- Chronicle reads the roster two seconds after the client says it changed; Guild a little after that.
ns.On("GUILD_ROSTER_UPDATE", function() ns.Debounce("guild-activity", 4, A.Scan) end)
