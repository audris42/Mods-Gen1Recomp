-- Vol de Pokemon for Gen1Recomp 0.1.96+
-- Red, Blue and Yellow (Gen 1) only.

return function(mod)
  local BattleState = require("src.battle.BattleState")
  local Runtime = require("src.mods.Runtime")
  local Sound = require("src.core.Sound")
  local Strings = require("src.core.Strings")

  -- Keep the original implementation for wild, Safari, demo and link battles.
  -- The marker also prevents a development hot reload from wrapping twice.
  if BattleState._catchTrainerPokemonOriginalThrowBall then
    mod.log:warn("Vol de Pokemon est deja installe dans cette session")
    return
  end

  local originalThrowBall = BattleState.throwBall
  BattleState._catchTrainerPokemonOriginalThrowBall = originalThrowBall

  function BattleState:throwBall(ball)
    if self.kind ~= "trainer" then
      return originalThrowBall(self, ball)
    end

    self:sayAuto(self:romText(
      "_ItemUseText001",
      "%s used\n%s!",
      self.game.save.player.name,
      self.data.items[ball].name
    ))

    self:act(function()
      Sound.play(self.data, "Ball_Toss")
      self.lastBall = ball

      local caught, shakes = self:catchAttempt(ball)
      Runtime.emit("battle.ball_thrown", {
        battle = self,
        ball = ball,
        caught = caught,
        shakes = shakes,
      })

      self.nextInsert = (self.nextInsert or 0) + 1
      table.insert(self.queue, self.nextInsert, { wait = 20 })
      self:ballChain(self:tossAnimFor(ball), caught, shakes, ball)

      if caught then
        self:sayNextWaitSfx(
          Strings("All right!\n%s was\ncaught!", self.enemy.name),
          function() return Sound.play(self.data, "Caught_Mon") end
        )
        self:act(function()
          self:storeCaughtMon()
          self.result = "win"
        end)
      else
        self:sayNext(self:ballMissMessage(shakes))
        self:act(function()
          self:executeAction(self.enemy, self.player, self:enemyAction())
        end)
        self:queueResidual(self.player, self.enemy)
        self:act(function() self:endOfTurn() end)
      end
    end)
  end

  mod.log:info("Les Pokemon des dresseurs peuvent maintenant etre captures")
end

