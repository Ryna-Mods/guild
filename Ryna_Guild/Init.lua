-- Init: Guild registers with the core (Ryna.RegisterMod). Loaded last, so every handler exists. At
-- login it takes in whatever roster Chronicle already holds; /ryna guild opens its section.

local _, ns = ...
if ns.off then return end
local L = ns.L

ns.API.RegisterMod({
  id = "guild",
  addon = ns.NAME,
  name = "Guild",
  version = ns.VERSION,
  onLogin = function()
    ns.Run("guild scan", ns.Activity.Scan)
  end,
})

local Slash = ns.API.Slash
if type(Slash) == "table" and type(Slash.Add) == "function" then
  Slash.Add({
    word = "guild",
    order = 76,
    help = L["/ryna guild: your guild's roster, what changed, and who has gone quiet"],
    run = function()
      local RW = ns.API.Window
      if ns.Section.registered and type(RW.Open) == "function" then
        RW.Open(ns.Section.KEY)
      else
        ns.Print(L["Guild needs Ryna's window, which this version of Ryna Core doesn't have."])
      end
    end,
  })
end
