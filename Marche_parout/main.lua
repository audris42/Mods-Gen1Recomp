-- Marche-Partout pour Gen1Recomp.
-- Les ROMs ne sont jamais modifiees : le mod change uniquement le verdict
-- de collision du moteur pendant son execution.

local mod = ...

mod.options:define({
  {
    key = "enabled",
    type = "toggle",
    label = "MARCHE-PARTOUT",
    default = true,
    help = "Traverse les murs, l'eau et les personnages. Les limites de carte restent protegees.",
  },
})

local function enabled()
  local ok, value = pcall(mod.options.get, mod.options, "enabled")
  if not ok or value == nil then return true end
  return value and true or false
end

local function isPlayer(mover)
  local ok, Game = pcall(require, "src.core.Game")
  if not ok or type(Game) ~= "table" then return false end
  local overworld = Game.overworld
  return overworld and overworld.player == mover
end

mod.hooks:wrap("movement.collision", function(next, allowed, ctx)
  allowed = next(allowed, ctx)

  if allowed or not enabled() or type(ctx) ~= "table" then
    return allowed
  end
  if not isPlayer(ctx.mover) then
    return allowed
  end

  -- Ne jamais ignorer les limites : les connexions de carte sont gerees
  -- avant ce hook, et autoriser une vraie sortie de tableau serait dangereux.
  if ctx.reason == "bounds" then
    return false
  end

  if ctx.reason == "tile" or ctx.reason == "entity" then
    ctx.reason = nil
    return true
  end

  return allowed
end)

-- Le moteur teste les rebords avant le hook movement.collision. Sans cette
-- interception, descendre lance encore le saut vanilla de deux cases alors
-- que remonter traverse deja le rebord normalement.
do
  local OverworldController = require("src.world.OverworldController")
  if not OverworldController._marchePartoutLedgeBase then
    local base = OverworldController.checkLedgeHop
    OverworldController._marchePartoutLedgeBase = base
    function OverworldController:checkLedgeHop(dir)
      if enabled() then return false end
      return base(self, dir)
    end
  end
end

mod.events:on("game.ready", function()
  mod.log:info("Marche-Partout charge (option: %s)", enabled() and "active" or "inactive")
end)
