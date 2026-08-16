local SCREEN = "ShinyDexRBY"

return function(mod)
  mod.options:define({
    {
      key = "sort",
      label = "TRI SHINYDEX",
      type = "choice",
      default = "dex",
      choices = { { "No. DEX", "dex" }, { "NOM", "name" } },
    },
    {
      key = "show_missing",
      label = "VOIR MANQUANTS",
      type = "toggle",
      default = true,
    },
  })

  local SHINY_ATTACK_DV = {
    [2] = true, [3] = true, [6] = true, [7] = true,
    [10] = true, [11] = true, [14] = true, [15] = true,
  }
  local VERSION_SHORT = { red = "R", blue = "B", yellow = "J" }

  local function isShiny(mon)
    if type(mon) ~= "table" then return false end
    if mon.shiny == true then return true end

    local shinyMod = mod.find("SHINY_POKEMON")
    local exported = shinyMod and shinyMod.exports and shinyMod.exports.isShiny
    if type(exported) == "function" then
      local ok, result = pcall(exported, mon.dvs)
      if ok and result then return true end
    end

    local dv = mon.dvs
    if type(dv) ~= "table" then return false end
    return SHINY_ATTACK_DV[dv.attack] == true
      and dv.defense == 10 and dv.speed == 10 and dv.special == 10
  end

  local function blankState()
    return { seen = {}, caught = {}, encounters = {}, captures = {}, origin = {} }
  end

  local function state()
    local value = mod.save:get("dex", nil)
    if type(value) ~= "table" then value = blankState() end
    for key, empty in pairs(blankState()) do
      if type(value[key]) ~= "table" then value[key] = empty end
    end
    return value
  end

  local function versionOf(game)
    local id = game and game.save and game.save.version or "red"
    return VERSION_SHORT[id] or tostring(id):sub(1, 1):upper()
  end

  local function record(mon, caught, game, incrementEncounter, incrementCapture)
    if not isShiny(mon) or type(mon.species) ~= "string" then return false end
    local id, dex = mon.species, state()
    local changed = not dex.seen[id] or (caught and not dex.caught[id])
    dex.seen[id] = true
    if caught then dex.caught[id] = true end
    if not dex.origin[id] then dex.origin[id] = versionOf(game) end
    if incrementEncounter then
      dex.encounters[id] = (dex.encounters[id] or 0) + 1
      changed = true
    end
    if incrementCapture then
      dex.captures[id] = (dex.captures[id] or 0) + 1
      changed = true
    end
    if changed then mod.save:set("dex", dex) end
    return changed
  end

  local function scan(value, game, visited)
    if type(value) ~= "table" or visited[value] then return end
    visited[value] = true
    if value.species and (value.shiny ~= nil or value.dvs ~= nil) then
      record(value, true, game, false, false)
      return
    end
    for _, child in pairs(value) do scan(child, game, visited) end
  end

  local function scanOwned(game)
    if not (game and game.save) then return end
    local visited = {}
    scan(game.save.party, game, visited)
    scan(game.save.boxes, game, visited)
    scan(game.save.box, game, visited)
  end

  local function speciesRows()
    local rows = {}
    for id, pokemon in mod.content.pokemon:each() do
      if pokemon.dex then
        rows[#rows + 1] = {
          id = id, name = pokemon.name or id, dex = pokemon.dex,
        }
      end
    end
    return rows
  end

  local function counts(rows)
    local dex, seen, caught = state(), 0, 0
    for _, row in ipairs(rows or speciesRows()) do
      if dex.seen[row.id] then seen = seen + 1 end
      if dex.caught[row.id] then caught = caught + 1 end
    end
    return seen, caught
  end

  mod.events:on("game.ready", function(ev) scanOwned(ev and ev.game) end)
  mod.events:on("save.loaded", function(ev)
    if ev and ev.save then
      scanOwned({ save = ev.save })
    end
  end)
  mod.events:on("battle.started", function(ev)
    local battle = ev and ev.battle
    record(battle and battle.enemy and battle.enemy.mon, false,
      battle and battle.game, true, false)
  end)
  mod.events:on("pokemon.caught", function(ev)
    record(ev and ev.mon, true,
      ev and (ev.game or (ev.battle and ev.battle.game)), false, true)
  end)
  mod.events:on("pokemon.evolved", function(ev)
    record(ev and ev.mon, true, nil, false, false)
  end)
  mod.events:on("pokemon.received", function(ev)
    record(ev and ev.mon, true, nil, false, false)
  end)
  mod.events:on("trade.completed", function(ev)
    record(ev and ev.received, true, nil, false, false)
  end)

  mod.exports.isShiny = isShiny
  mod.exports.record = record
  mod.exports.data = state
  mod.exports.countSeen = function() return (counts()) end
  mod.exports.countCaught = function() return select(2, counts()) end

  mod.content.screens:register(SCREEN, {
    new = function(game, opts)
      opts = opts or {}
      scanOwned(game)
      local dex, rows = state(), speciesRows()
      if mod.options:get("sort") == "name" then
        table.sort(rows, function(a, b) return a.name < b.name end)
      else
        table.sort(rows, function(a, b)
          if a.dex ~= b.dex then return a.dex < b.dex end
          return a.id < b.id
        end)
      end

      local items, showMissing = {}, mod.options:get("show_missing")
      for _, row in ipairs(rows) do
        local known = dex.seen[row.id] or dex.caught[row.id]
        if showMissing or known then
          local name = known and row.name or "-----"
          local status = dex.caught[row.id] and "PRIS"
            or (dex.seen[row.id] and "VU" or "---")
          local origin = dex.origin[row.id] and (" " .. dex.origin[row.id]) or ""
          items[#items + 1] = {
            label = ("%03d %s"):format(row.dex, name),
            right = status .. origin,
            ball = dex.caught[row.id] or nil,
            value = known and row.id or nil,
          }
        end
      end

      local seen, caught = counts(rows)
      return mod.ui.ListMenu.new(game, "SHINYDEX RBY", items, {
        footer = ("VUS %3d PRIS %3d"):format(seen, caught),
        pageJump = true,
        keyRepeat = true,
        onCancel = opts.onCancel,
        onChoose = function(item)
          if item and item.value then
            mod.ui.push(game, "DexEntryMenu", {
              species = item.value,
              forceOwned = dex.caught[item.value] == true,
            })
          end
        end,
      })
    end,
  })

  mod.hooks:wrap("ui.start_menu.items", function(next, game, items)
    local out = next(game, items)
    if type(out) ~= "table" then return out end
    -- Le ShinyDex se debloque et se place avec le Pokedex normal.
    local anchor
    for _, item in ipairs(out) do
      local label = tostring(item.label or ""):upper()
      if label == "POKéDEX" or label == "POKEDEX"
          or label:find("DEX", 1, true) then
        anchor = item.label
        break
      end
    end
    if not anchor then return out end
    return mod.ui.insertAfter(out, anchor, {
      label = "SHINYDEX",
      onSelect = function()
        mod.ui.push(game, SCREEN, {
          onCancel = function() mod.ui.push(game, "StartMenu") end,
        })
      end,
    })
  end)
end
