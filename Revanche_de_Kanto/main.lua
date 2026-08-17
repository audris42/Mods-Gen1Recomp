-- Revanche de Kanto pour Gen1Recomp 0.1.96+.
--
-- Aucun drapeau vanilla n'est efface. Le mod superpose un cycle de revanche
-- aux dresseurs ordinaires deja vaincus et range sa progression dans
-- save.modData via mod.save. Desactiver le mod restaure donc immediatement
-- le comportement vanilla.

return function(mod)
  local Runtime = require("src.mods.Runtime")
  local OverworldState = require("src.world.OverworldController")
  local MapScripts = require("src.script.MapScripts")

  local SAVE_KEY = "cycle_v1"
  local HOOK_NAME = "revanche_kanto.trainer_defeated"

  local HOME_MAPS = {
    PALLET_TOWN = true,
    REDS_HOUSE_2F = true,
  }

  -- La Ligue possede deja son propre mecanisme de revanche. La laisser au
  -- moteur evite de perturber ses portes, son enchainement et le Hall of Fame.
  local LEAGUE_MAPS = {
    LORELEIS_ROOM = true,
    BRUNOS_ROOM = true,
    AGATHAS_ROOM = true,
    LANCES_ROOM = true,
    CHAMPIONS_ROOM = true,
    HALL_OF_FAME = true,
  }

  local function state()
    local value = mod.save:get(SAVE_KEY)
    if type(value) ~= "table" or type(value.eligible) ~= "table" then
      return nil
    end
    if type(value.won) ~= "table" then value.won = {} end
    return value
  end

  local function hallOfFameCount(save)
    if type(save and save.hallOfFame) ~= "table" then return 0 end
    return #save.hallOfFame
  end

  local function isVisible(save, mapId, obj)
    if type(OverworldState.objectVisible) ~= "function" then
      return not obj.hidden
    end
    return OverworldState.objectVisible(save, mapId, obj)
  end

  local function hasHandPortedTalk(mapId, textId)
    if not textId or type(MapScripts.talkScript) ~= "function" then
      return false
    end
    local ok, script = pcall(MapScripts.talkScript, mapId, textId)
    return ok and script ~= nil
  end

  -- Construit la liste depuis les donnees du jeu actif. Cela prend en charge
  -- Rouge, Bleu et Jaune sans adresses ROM, ainsi que les sauvegardes .sav
  -- importees qui ne possedent que les EVENT_BEAT_* d'origine.
  local function collectEligible(game)
    local eligible = {}
    local total = 0
    local save = game.save or {}
    local defeated = save.defeatedTrainers or {}
    local flags = save.flags or {}
    local maps = game.data and game.data.maps or {}

    for mapId, mapDef in pairs(maps) do
      if not LEAGUE_MAPS[mapId] then
        for _, obj in ipairs(mapDef.objects or {}) do
          if obj.trainerClass and obj.index
              and isVisible(save, mapId, obj)
              and not hasHandPortedTalk(mapId, obj.text) then
            local header = game.data:trainerHeader(mapDef.label, obj.index)
            local key = mapId .. "_obj_" .. tostring(obj.index)
            local wasBeaten = defeated[key] == true
              or (header and header.event and flags[header.event] == true)

            -- Un header d'evenement identifie les dresseurs ordinaires. Les
            -- Rivaux, boss et cadeaux-combats pilotes par scenario restent
            -- sous le controle de leur script d'origine.
            if wasBeaten and header and header.event then
              eligible[key] = true
              total = total + 1
            end
          end
        end
      end
    end

    return eligible, total
  end

  local function queueNotice(text)
    local world = mod.world
    local ow = world and world:overworld()
    if not (ow and ow.queueScript and ow.map) then return false end
    ow:queueScript({ { "show_text", text } })
    return true
  end

  local function beginCycle(game, hofCount, previous)
    local eligible, total = collectEligible(game)
    local nextState = {
      schema = 1,
      number = ((previous and previous.number) or 0) + 1,
      hallOfFameCount = hofCount,
      active = total > 0,
      completed = total == 0,
      eligible = eligible,
      won = {},
      wonCount = 0,
      total = total,
    }
    mod.save:set(SAVE_KEY, nextState)

    if total > 0 then
      queueNotice("LA REVANCHE DE\nKANTO COMMENCE!\f"
        .. tostring(total) .. " DRESSEURS\nveulent te defier\na nouveau!")
      mod.log:info("Cycle %d active avec %d dresseurs",
        nextState.number, total)
    else
      mod.log:warn("Aucun dresseur ordinaire vaincu n'a ete trouve")
    end
  end

  local function tryBeginCycle(mapId)
    if not HOME_MAPS[mapId] then return end
    local game = mod.game
    local save = game and game.save
    if not (save and save.flags and save.flags.EVENT_BEAT_CHAMPION_RIVAL) then
      return
    end

    local current = state()
    local hofCount = hallOfFameCount(save)
    local previousCount = current and tonumber(current.hallOfFameCount)
    local newLeagueWin = not current
      or previousCount == nil
      or hofCount > previousCount

    if newLeagueWin then
      beginCycle(game, hofCount, current)
    end
  end

  local function pendingRematch(npc)
    local current = state()
    return current ~= nil
      and current.active == true
      and npc ~= nil
      and npc.def ~= nil
      and npc.def.trainerClass ~= nil
      and current.eligible[npc.id] == true
      and current.won[npc.id] ~= true
  end

  -- Point d'injection stable pour le hot-reload : le remplacement direct est
  -- installe une seule fois, mais toute la politique vit dans le bus de hooks
  -- du Loader. A la desactivation/recharge, la chaine disparait et ce pont
  -- retombe automatiquement sur la methode vanilla.
  if not OverworldState._revancheKantoBaseTrainerDefeated then
    local vanillaTrainerDefeated = OverworldState.trainerDefeated
    OverworldState._revancheKantoBaseTrainerDefeated = vanillaTrainerDefeated

    function OverworldState:trainerDefeated(npc)
      return Runtime.call(HOOK_NAME, function(ow, target)
        return vanillaTrainerDefeated(ow, target)
      end, self, npc)
    end
  end

  mod.hooks:wrap(HOOK_NAME, function(nextFn, ow, npc)
    if pendingRematch(npc) then return false end
    return nextFn(ow, npc)
  end, 200)

  mod.events:on("map.entered", function(payload)
    tryBeginCycle(payload and payload.mapId)
  end)

  -- Fallback utile au chargement d'une sauvegarde ou apres un hot-reload :
  -- map.entered a normalement deja fait le travail, et ce second appel est
  -- idempotent tant que le compteur du Hall of Fame n'a pas augmente.
  mod.events:on("save.loaded", function(payload)
    local save = payload and payload.save
    tryBeginCycle(save and save.player and save.player.map)
  end)

  mod.events:on("battle.ended", function(payload)
    if not payload or payload.result ~= "win" then return end
    local battle = payload.battle
    local origin = battle and battle.checkpointOrigin
    if not (origin and origin.kind == "trainer_encounter" and origin.npcId) then
      return
    end

    local current = state()
    local npcId = origin.npcId
    if not (current and current.active and current.eligible[npcId]
        and not current.won[npcId]) then
      return
    end

    -- battle.ended est emis avant battle.onFinish. Enregistrer ici garantit
    -- que le retour sur la carte voit deja ce dresseur comme rebattu.
    current.won[npcId] = true
    current.wonCount = (tonumber(current.wonCount) or 0) + 1

    if current.wonCount >= (tonumber(current.total) or 0) then
      current.active = false
      current.completed = true
      queueNotice("TOUR TERMINE!\fTous les DRESSEURS\nde ce parcours sont\nvaincus!")
      mod.log:info("Cycle %d termine", tonumber(current.number) or 1)
    end

    mod.save:set(SAVE_KEY, current)
  end)

  -- Couvre un F5 effectue alors que le joueur se trouve deja au point de
  -- depart. Sur un demarrage normal, map.entered prendra le relais.
  local currentWorld = mod.world and mod.world:current()
  if currentWorld then tryBeginCycle(currentWorld.mapId) end

  mod.log:info("Revanche de Kanto 1.0.0 pret")
end
