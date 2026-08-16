local mod = ...

-- Give the imported Coin Case a native Gen1Recomp item effect.
mod.content.item_effects:register("COIN_CASE_9999", {
  field = true,
  battle = false,
  use = function(ctx)
    ctx.save.coins = 9999
    return "failed", { "Coin count:\n9999" }
  end,
})

mod.content.items:patch("COIN_CASE", {
  effect = "COIN_CASE_9999",
})

-- Restore the balance every logic tick. The wrapper runs before the normal
-- game update, so a casino purchase or bet is restored on the next tick.
mod.hooks:wrap("input.step", function(next, game, dt)
  next(game, dt)

  local save = game and game.save
  local inventory = save and save.inventory
  if inventory and (inventory.COIN_CASE or 0) > 0 then
    save.coins = 9999
  end
end)
