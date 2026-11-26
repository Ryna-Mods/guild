# Guild by Ryna

A mod of [Ryna](https://github.com/Ryna-Mods/ryna) for World of Warcraft: Forever. Your guild, in
Ryna's window: `/ryna guild`.

- **Roster**: every member with rank, level, zone, note and when they were last on. Online members
  first; the search box reads names, ranks, zones and notes.
- **Activity**: what changed since Guild last looked: who joined, left, levelled, was promoted or
  demoted, changed their note, or came back after two weeks or more away.
- **Quiet**: members not seen for 14, 30, 60 or 90 days, longest away first.

This version only shows. It changes no note, rank or membership, and sends nothing to other
players. Officers' tools (a click each, never a batch), events and attendance are designed and not
built yet.

## What it keeps

Guild needs **Chronicle**, which reads the roster at login and every ten minutes. Guild compares
each reading with the one before and keeps the differences in your saved file, under
`RynaDB.guild`: the newest 500 changes for each guild. That is what any member sees in the game's
own guild pane, written down over time. Officer notes are never copied into the list of changes.

A guild's first reading is only kept, never compared, so the list starts empty. A reading with
fewer than half the members of the last one is skipped: the roster loads in pieces, and a
half-loaded one would say most of the guild had left.

## Installing

Guild needs **Ryna Core** (the folder `Ryna_Core`), 0.5.1 or newer, and **Chronicle by Ryna**. Unzip
`Ryna_Guild-<version>.zip` from this repository's releases into `Interface/AddOns` beside them.

## Working on it

`Ryna_Guild/` is the addon:

- `Activity.lua`: the difference between two readings of a roster, and what is kept of each guild.
- `Section.lua`: the section of Ryna's window, its views, rows, tiles and sentences.
- `Mod.lua`, `Init.lua`: the namespace and API-level gate, the `/ryna guild` command and the
  registration with the core.

`scripts/check.sh` runs everything CI does: luacheck, a Lua 5.1 parse of every file, the strings
check, and the tests in `test/` against a stand-in for the core's mod API.

MIT licensed.
