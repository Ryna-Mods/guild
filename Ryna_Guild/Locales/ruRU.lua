-- Russian (ruRU) strings for Guild by Ryna. Loaded on every client, applied only when the game
-- runs in ruRU: GetLocale() is "ruRU".
--
-- How to translate:
--   - Each line is L["English"] = nil. Replace nil with your text in double quotes:
--       L["Take part in the census"] = "..."
--     A line left as nil shows the English, so a partial translation is fine.
--   - Keep every %s and %d, in the same order (WoW's string.format can't reorder them).
--   - Keep "||" as it is: it prints one "|" in chat. Inside a command (/ryna debug on||off||toggle,
--     /who, /reload) keep the words in English: they are what the player types.
--   - Plurals: a pair like "%d player" / "%d players" is used for 1 / everything else.
--     For a language with more forms, use the wording that reads best for most numbers.
--   - Keys are the English text and must stay exactly as they are; only change the values.
--   - Test: set the client's language (Battle.net -> Settings -> Game Settings -> Text Language,
--     or SET textLocale "ruRU" in WTF/Config.wtf, with that language installed), log in, then
--     /ryna, /ryna status and /ryna help.
-- This file is generated from enUS.lua by cores/wow/addon/tools/strings.mjs --templates, which keeps the
-- translations already here; run it after enUS.lua changes.

local _, ns = ...
if ns.off then return end
if ns.Locale() ~= "ruRU" then return end
local L = ns.L

-- Init.lua
-- /ryna's help line for the command.
L["/ryna guild: your guild's roster, what changed, and who has gone quiet"] = nil
L["Guild needs Ryna's window, which this version of Ryna Core doesn't have."] = nil

-- Section.lua
-- The section's name in the window's rail, and the title when no guild is known.
L["Guild"] = nil
-- The section's title: the guild's name, then the view ("Emberwake › Roster").
L["%s › %s"] = nil
-- The views in the section's picker.
L["Roster"] = nil
L["Activity"] = nil
-- %d is 14, 30, 60 or 90.
L["Quiet %d days"] = nil
-- Column headings.
L["Name"] = nil
L["Rank"] = nil
L["Level"] = nil
L["Zone"] = nil
L["Note"] = nil
L["Last online"] = nil
L["Away"] = nil
L["When"] = nil
L["What changed"] = nil
-- A member who is in the game now (the Last online column, and a tile's label).
L["Online"] = nil
-- How long a quiet member has been away; always 14 or more.
L["%d days"] = nil
-- The tiles above the list.
L["Members"] = nil
L["Quiet 30 days"] = nil
L["Joined this week"] = nil
-- A change to the roster, as a sentence. The first %s is the member's name.
L["%s joined the guild"] = nil
L["%s left the guild"] = nil
L["%s reached level %d"] = nil
-- The second %s is the rank's name.
L["%s was promoted to %s"] = nil
L["%s was demoted to %s"] = nil
L["%s cleared their note"] = nil
-- The second %s is the new note.
L["%s changed their note: %s"] = nil
-- %d is 14 or more.
L["%s came back after %d days"] = nil
-- An empty list, by why it is empty.
L["This character isn't in a guild, or Chronicle hasn't read its roster yet. "
  .. "Chronicle reads it at login and every ten minutes."] = nil
L["Nothing has changed since Guild started watching. Who joins, leaves, levels or changes rank shows here."] = nil
L["Nobody has been away that long."] = nil
L["Nobody matches."] = nil
-- The footer. %s is "5 minutes ago".
L["The roster as Chronicle read it %s. Guild only shows it: it changes nothing in your guild."] = nil
-- In place of "5 minutes ago" when the time isn't known.
L["at some time"] = nil
