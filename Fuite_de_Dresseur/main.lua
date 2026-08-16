-- Fuite de Dresseur pour Gen1Recomp 0.1.96+.
-- Le mod ne modifie ni la ROM ni la sauvegarde : il retire uniquement le
-- refus special des combats de dresseurs dans BattleState:tryRun().

return function(mod)
  local BattleState = require("src.battle.BattleState")

  if BattleState._fuiteDeDresseurOriginalTryRun then
    mod.log:warn("Fuite de Dresseur est deja installe dans cette session")
    return
  end

  local originalTryRun = BattleState.tryRun
  BattleState._fuiteDeDresseurOriginalTryRun = originalTryRun

  function BattleState:tryRun()
    if self.kind ~= "trainer" then
      return originalTryRun(self)
    end

    -- La methode vanilla ne distingue le cas dresseur qu'au debut, avant
    -- d'appliquer la formule normale et de terminer le combat. La masquer le
    -- temps de cet appel permet de reutiliser toute cette logique sans la
    -- recopier. L'etat est restaure immediatement, meme en cas d'erreur.
    self.kind = "wild"
    local ok, result = pcall(originalTryRun, self)
    self.kind = "trainer"

    if not ok then
      error(result, 0)
    end

    -- Une fuite reussie doit valider le dresseur. Le moteur ne pose le
    -- drapeau de victoire et le drapeau d'evenement que pour le resultat
    -- "win" ; conserver "run" ferait immediatement relancer le combat.
    if self.result == "run" then
      self.result = "win"
    end
    return result
  end

  mod.log:info("La fuite est maintenant autorisee pendant les combats de dresseurs")
end
