-- Visible wild Pokemon for Gen1Recomp 0.1.98 / mod API 2.
-- The mod reads the merged encounter tables at runtime. It never reads,
-- writes, patches, or bundles a ROM or a save file.

return function(mod)
  local game
  local activeMapId
  local visible = {}
  local pendingBattle = false

  local MAX_VISIBLE = 4
  local DEFAULT_BUCKETS = { 51, 102, 141, 166, 191, 216, 229, 242, 253, 256 }

  local exactSprites = {
    PIKACHU = "SPRITE_PIKACHU",
    SANDSHREW = "SPRITE_SANDSHREW",
    ODDISH = "SPRITE_ODDISH",
    BULBASAUR = "SPRITE_BULBASAUR",
    JIGGLYPUFF = "SPRITE_JIGGLYPUFF",
    CLEFAIRY = "SPRITE_CLEFAIRY",
    CHANSEY = "SPRITE_CHANSEY",
    SEEL = "SPRITE_SEEL",
    SNORLAX = "SPRITE_SNORLAX",
  }

  local birds = {
    PIDGEY = true, PIDGEOTTO = true, PIDGEOT = true,
    SPEAROW = true, FEAROW = true, FARFETCHD = true,
    DODUO = true, DODRIO = true, ARTICUNO = true,
    ZAPDOS = true, MOLTRES = true,
  }

  local fairies = {
    CLEFAIRY = true, CLEFABLE = true, JIGGLYPUFF = true,
    WIGGLYTUFF = true, CHANSEY = true, MEW = true,
  }

  local function spriteFor(species)
    local sprites = game and game.data and game.data.sprites or {}
    local exact = exactSprites[species]
    if exact and sprites[exact] then return exact end
    if species == "SNORLAX" and sprites.SPRITE_SNORLAX then
      return "SPRITE_SNORLAX"
    end
    if species == "SEEL" and sprites.SPRITE_SEEL then return "SPRITE_SEEL" end
    if birds[species] and sprites.SPRITE_BIRD then return "SPRITE_BIRD" end
    if fairies[species] and sprites.SPRITE_FAIRY then return "SPRITE_FAIRY" end
    return sprites.SPRITE_MONSTER and "SPRITE_MONSTER" or "SPRITE_BIRD"
  end

  -- Same cumulative slot weights as Gen 1. A modded encounter table may
  -- supply its own buckets and they take precedence.
  local function pickEncounter(grass)
    if not grass or type(grass.slots) ~= "table" or #grass.slots == 0 then
      return nil
    end
    local buckets = grass.buckets or DEFAULT_BUCKETS
    local pick = love.math.random(0, 255)
    for i, threshold in ipairs(buckets) do
      if pick < threshold then
        local slot = grass.slots[i]
        if slot and slot.species and slot.level then
          return { species = slot.species, level = slot.level }
        end
        return nil
      end
    end
    return nil
  end

  local function clearVisible()
    for id in pairs(visible) do mod.world:removeNpc(id) end
    visible = {}
  end

  local function occupied(ow, x, y)
    if ow.player and ow.player.cellX == x and ow.player.cellY == y then
      return true
    end
    for _, entity in ipairs(ow.entities or {}) do
      if entity.cellX == x and entity.cellY == y then return true end
      if entity.targetX == x and entity.targetY == y then return true end
    end
    return false
  end

  local function grassCells(ow)
    local cells = {}
    local map = ow and ow.map
    if not map or not map.isGrassCell then return cells end
    for y = 0, map.heightCells - 1 do
      for x = 0, map.widthCells - 1 do
        if map:isGrassCell(x, y) and not occupied(ow, x, y) then
          cells[#cells + 1] = { x = x, y = y }
        end
      end
    end
    return cells
  end

  local function spawnForMap(mapId)
    clearVisible()
    pendingBattle = false
    activeMapId = mapId

    local encounterDef = game and game.data and game.data.encounters
      and game.data.encounters[mapId]
    local grass = encounterDef and encounterDef.grass
    if not grass or grass.rate == 0 then return end

    local ow = mod.world:overworld()
    if not ow or not ow.map or ow.map.id ~= mapId then return end
    local cells = grassCells(ow)
    if #cells == 0 then return end

    -- One visible Pokemon per roughly 24 grass cells, capped to keep routes
    -- readable and to avoid crowding narrow patches.
    local count = math.min(MAX_VISIBLE, math.max(1, math.floor(#cells / 24 + 0.5)))
    for _ = 1, count do
      if #cells == 0 then break end
      local cellIndex = love.math.random(#cells)
      local cell = table.remove(cells, cellIndex)
      local encounter = pickEncounter(grass)
      if encounter then
        local id, err = mod.world:spawnNpc(mapId, {
          name = "VISIBLE_WILD_POKEMON",
          x = cell.x,
          y = cell.y,
          sprite = spriteFor(encounter.species),
          movement = "WALK",
          range = "ANY_DIR",
        })
        if id then
          visible[id] = encounter
        else
          mod.log:warn("Impossible d'afficher %s: %s",
            tostring(encounter.species), tostring(err))
        end
      end
    end
  end

  mod.events:on("game.ready", function(ev)
    game = ev.game
  end)

  mod.events:on("map.entered", function(ev)
    if game then spawnForMap(ev.mapId) end
  end)

  mod.events:on("map.exited", function()
    clearVisible()
    activeMapId = nil
  end)

  mod.events:on("battle.ended", function()
    -- The map remains underneath the battle state, so no map.entered event
    -- fires when the player returns. Re-arm contact encounters here.
    pendingBattle = false
  end)

  -- Visible encounters replace random grass encounters. Fishing and scripted
  -- wild battles do not pass through this grass-roll suppression.
  mod.hooks:wrap("encounter.roll", function(_next, _encounterDef, ctx)
    if ctx and ctx.terrain == "grass" then return nil end
    return _next(_encounterDef, ctx)
  end)

  -- The Pokemon is a blocking runtime NPC. Pressing a direction into its cell
  -- reaches this hook with reason == "entity"; remove it, then use the public
  -- battle handoff so evolution, blackout, music, and return-to-map all remain
  -- engine-owned.
  mod.hooks:wrap("movement.collision", function(next_, allowed, ctx)
    local result = next_(allowed, ctx)
    if result or pendingBattle or not game or not ctx then return result end
    local ow = mod.world:overworld()
    if not ow or ctx.mover ~= ow.player or ow.map.id ~= activeMapId then
      return result
    end
    for id, encounter in pairs(visible) do
      local hit = false
      for _, entity in ipairs(ow.entities or {}) do
        if entity.id == id then
          hit = (entity.cellX == ctx.toX and entity.cellY == ctx.toY)
            or (entity.targetX == ctx.toX and entity.targetY == ctx.toY)
          break
        end
      end
      if hit then
          pendingBattle = true
          visible[id] = nil
          mod.world:removeNpc(id)
          local ok, err = mod.world:startWildBattle(encounter.species, encounter.level)
          if not ok then
            pendingBattle = false
            mod.log:error("Combat visible impossible: %s", tostring(err))
          end
          break
      end
    end
    return result
  end)
end
