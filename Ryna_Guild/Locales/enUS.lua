-- English (enUS): every string Guild by Ryna shows, keyed by the English text itself. `true` means "the
-- text is the key"; ns.L returns the key for anything no locale file translates, so English is always
-- the fallback. The other Locales/*.lua files are templates for translators, generated from this one:
-- after adding, changing or removing a string here, run (from the repository root)
--
--   node tools/strings.mjs --templates
--
-- which rewrites them with the same keys, keeping every translation already in them. Without
-- --templates it only checks that this list matches what the code uses (L["..."] and N("...")).
-- Debug lines (ns.Debug) are English on purpose and are not listed. A key the core addon's
-- Locales/enUS.lua already has isn't repeated here: Guild's L falls back to it.

local _, ns = ...
if ns.off then return end
local L = ns.L

-- Init.lua
-- /ryna's help line for the command.
L["/ryna guild: your guild's roster, what changed, and who has gone quiet"] = true
L["Guild needs Ryna's window, which this version of Ryna Core doesn't have."] = true

-- Section.lua
-- The section's name in the window's rail, and the title when no guild is known.
L["Guild"] = true
-- The section's title: the guild's name, then the view ("Emberwake › Roster").
L["%s › %s"] = true
-- The views in the section's picker.
L["Roster"] = true
L["Activity"] = true
-- %d is 14, 30, 60 or 90.
L["Quiet %d days"] = true
-- Column headings.
L["Name"] = true
L["Rank"] = true
L["Level"] = true
L["Zone"] = true
L["Note"] = true
L["Last online"] = true
L["Away"] = true
L["When"] = true
L["What changed"] = true
-- A member who is in the game now (the Last online column, and a tile's label).
L["Online"] = true
-- How long a quiet member has been away; always 14 or more.
L["%d days"] = true
-- The tiles above the list.
L["Members"] = true
L["Quiet 30 days"] = true
L["Joined this week"] = true
-- A change to the roster, as a sentence. The first %s is the member's name.
L["%s joined the guild"] = true
L["%s left the guild"] = true
L["%s reached level %d"] = true
-- The second %s is the rank's name.
L["%s was promoted to %s"] = true
L["%s was demoted to %s"] = true
L["%s cleared their note"] = true
-- The second %s is the new note.
L["%s changed their note: %s"] = true
-- %d is 14 or more.
L["%s came back after %d days"] = true
-- An empty list, by why it is empty.
L["This character isn't in a guild, or Chronicle hasn't read its roster yet. "
  .. "Chronicle reads it at login and every ten minutes."] = true
L["Nothing has changed since Guild started watching. Who joins, leaves, levels or changes rank shows here."] = true
L["Nobody has been away that long."] = true
L["Nobody matches."] = true
-- The footer. %s is "5 minutes ago".
L["The roster as Chronicle read it %s. Guild only shows it: it changes nothing in your guild."] = true
-- In place of "5 minutes ago" when the time isn't known.
L["at some time"] = true
