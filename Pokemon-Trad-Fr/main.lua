-- translation_source: a translation of the game into French.
--
-- Nothing here is translated yet.  Every table under lang/ starts with
-- empty strings; fill one in and it takes effect on the next boot, and
-- anything still empty keeps rendering in English.  That means a
-- half-finished translation is always playable, so you can ship early and
-- fill the long tail in later.
--
-- Read TRANSLATING.md before the first edit; the font is the part people
-- get wrong.
return function(mod)
  -- mod:read is the supported way into your own directory; the catalogs are
  -- plain Lua tables, so read and run them rather than require()ing them.
  local function catalog(name)
    local rel = "lang/" .. name .. ".lua"
    local body = mod:read(rel)
    if not body then return {} end
    local chunk, err = loadstring(body, rel)
    if not chunk then
      mod.log:warn("%s has a syntax error: %s", rel, tostring(err))
      return {}
    end
    local ok, table_ = pcall(chunk)
    if not ok or type(table_) ~= "table" then
      mod.log:warn("%s did not return a table: %s", rel, tostring(table_))
      return {}
    end
    return table_
  end

  -- An empty value means "not translated yet", never "translate to blank".
  local function each(name, apply)
    local n = 0
    for key, value in pairs(catalog(name)) do
      if type(value) == "string" and value ~= "" then
        apply(key, value)
        n = n + 1
      end
    end
    return n
  end

  -- ---- glyphs -------------------------------------------------------
  -- Text rendering through the bundled Plain Pixel TTF ("Plain Pixel
  -- Font" by Douglas Vautour (Burpy Fresh), CC-BY 4.0 -- see
  -- assets/fonts/plainpixel/README.md).  Registered, it replaces the tile
  -- font for ordinary characters, so a translation needs no glyph sheet
  -- at all; box borders and <PK>-style macros keep their tiles.  Options:
  -- { file = mod.assets:path("myfont.ttf"), size = 15, spacing = 0,
  --   yOffset = -6, bold = true } -- size is the font's design em (Plain
  -- Pixel only rasterizes cleanly at multiples of 15), bold thickens a
  -- 1px-stroke font that reads too light.
  -- Disabled on Gen1Recomp 0.1.96/macOS: registering this TTF globally can
  -- make every ordinary character disappear, including the Mod Manager UI.
  -- Keep the engine's built-in tile font so menus and other mods stay visible.

  -- Register the sheet BEFORE anything asks for a glyph on it.  base is
  -- the first code the page owns; 0x100 and up is free space above the
  -- vanilla pages, so a new alphabet never collides with them.
  for id, page in pairs(catalog("font")) do
    mod.content.font:register(id, page)
  end
  -- charmap: which byte sequence draws which code
  for seq, code in pairs(catalog("charmap")) do
    mod.content.font:register("charmap:" .. seq, { seq = seq, code = code })
  end

  -- ---- text ---------------------------------------------------------
  local counts = {}
  counts.dialogue = each("dialogue", function(id, value)
    mod.content.text:override(id, value)
  end)
  counts.strings = each("strings", function(source, value)
    mod.content.strings:override(source, value)
  end)
  counts.species = each("species_names", function(id, value)
    mod.content.pokemon:patch(id, { name = value })
  end)
  counts.moves = each("move_names", function(id, value)
    mod.content.moves:patch(id, { name = value })
  end)
  counts.items = each("item_names", function(id, value)
    mod.content.items:patch(id, { name = value })
  end)
  counts.trainers = each("trainer_names", function(id, value)
    mod.content.trainers:patch(id, { name = value })
  end)
  counts.statuses = each("status_labels", function(id, value)
    mod.content.statuses:patch(id, { label = value })
  end)
  -- Injected: localized Pokedex categories from generated lang/species_kinds.lua
  counts.species_kinds = each("species_kinds", function(id, value)
    mod.content.pokemon:patch(id, { dexEntry = { kind = value } })
  end)

  -- Injected: localized type display names from generated lang/type_names.lua
  -- Type names stay English in the type_chart registry so third-party
  -- mods that key colors/UI off TypeChart.displayName keep resolving,
  -- and are localized at draw time instead: every engine site renders
  -- the type name as a standalone Font.draw string, which is substituted
  -- below.
  local okType, TypeChart = pcall(require, "src.battle.TypeChart")
  local by_english = {}
  counts.type_names = each("type_names", function(typeId, localized)
    if okType and TypeChart and type(TypeChart.displayName) == "function" then
      local canonical = TypeChart.displayName(typeId)
      if type(canonical) == "string" and canonical ~= "" and canonical ~= localized then
        by_english[canonical] = localized
      end
    end
  end)
  if next(by_english) then
    local okFont, Font = pcall(require, "src.render.Font")
    if okFont and type(Font) == "table" then
      local function localize(text)
        if type(text) ~= "string" then return text end
        local localized = by_english[text]
        return type(localized) == "string" and localized or text
      end
      if type(Font.split) == "function" then
        local original_split = Font.split
        Font.split = function(text)
          return original_split(localize(text))
        end
      end
      if type(Font.draw) == "function" then
        local original_draw = Font.draw
        Font.draw = function(text, x, y, ...)
          return original_draw(localize(text), x, y, ...)
        end
      end
    end
  end


  -- ---- name entry ---------------------------------------------------
  -- The naming screen's letter grid.  Leave lang/naming.lua returning nil
  -- to keep the English alphabet.
  local grid = catalog("naming")
  if grid.upper then
    mod.hooks:on("ui.naming.grid", function(base, ctx)
      local want = ctx.lower and grid.lower or grid.upper
      return want or base
    end)
  end

  mod.events:on("game.ready", function()
    local total = 0
    for _, n in pairs(counts) do total = total + n end
    mod.log:info("French: %d strings translated", total)
  end)
  -- Injected: versioned catalogs for Pokémon Yellow.
  local okGame, GameVersion = pcall(require, "src.core.GameVersion")
  local yellow_game_version = okGame and type(GameVersion) == "table"
      and type(GameVersion.isYellow) == "function"
      and GameVersion.isYellow()
  if yellow_game_version then
    each("dialogue_yellow", function(id, value) mod.content.text:override(id, value) end)
    each("strings_yellow", function(id, value) mod.content.strings:override(id, value) end)
  end

  -- Injected: localize raw values only while OptionsMenu draws
  local raw_option_keys = {
    ["OG RED"] = true, ["OG BLUE"] = true, ["OG YELLOW"] = true,
    ["SGB"] = true, ["ADVANCED"] = true, ["OG INV"] = true,
    ["SGB INV"] = true, ["CLASSIC"] = true, ["GBC"] = true,
    ["WINDOWED"] = true, ["BORDERLESS"] = true,
    ["TREES"] = true, ["WATER"] = true, ["BLACK"] = true,
    ["OFF"] = true, ["1X"] = true, ["2X"] = true, ["3X"] = true,
    ["NORMAL"] = true,
  }
  local by_raw_option = {}
  each("strings", function(id, localized)
    if raw_option_keys[id] and localized ~= id then
      by_raw_option[id] = localized
    end
  end)
  if next(by_raw_option) then
    local okOptions, OptionsMenu = pcall(require, "src.ui.OptionsMenu")
    local okFont, Font = pcall(require, "src.render.Font")
    if okOptions and type(OptionsMenu) == "table" and type(OptionsMenu.draw) == "function"
        and okFont and type(Font) == "table" then
      local original_options_draw = OptionsMenu.draw
      local function localizeRawOption(text)
        if type(text) ~= "string" then return text end
        return by_raw_option[text] or text
      end
      OptionsMenu.draw = function(self, ...)
        local original_split, original_draw = Font.split, Font.draw
        if type(original_split) == "function" then
          Font.split = function(text) return original_split(localizeRawOption(text)) end
        end
        if type(original_draw) == "function" then
          Font.draw = function(text, x, y, ...)
            return original_draw(localizeRawOption(text), x, y, ...)
          end
        end
        local ok, result = pcall(original_options_draw, self, ...)
        Font.split, Font.draw = original_split, original_draw
        if ok then return result end
        error(result, 0)
      end
    end
  end

  -- Injected: localize hard-coded demo-battle thrower names
  local demo_names = catalog("demo_names")
  local function localizedDemoName(self, name)
    if type(name) == "string" then
      local localized = demo_names and demo_names[name]
      if type(localized) == "string" and localized ~= "" then
        return localized
      end
      if name == "PROF.OAK" then
        local trainers = self and self.game and self.game.data and self.game.data.trainers
        local oak = trainers and trainers.OPP_PROF_OAK
        if oak and type(oak.name) == "string" and oak.name ~= "" then
          return oak.name
        end
      end
    end
    return nil
  end
  local okDemo, BS = pcall(require, "src.battle.BattleState")
  if okDemo and type(BS) == "table" and type(BS.oldManThrow) == "function" then
    local original_oldManThrow = BS.oldManThrow
    BS.oldManThrow = function(self, ...)
      if type(self) == "table" then
        local canonical = self.demoName
        local localized = localizedDemoName(self, canonical)
        if type(localized) == "string" and localized ~= "" then
          self.demoName = localized
          local ok, result = pcall(original_oldManThrow, self, ...)
          self.demoName = canonical
          if ok then return result end
          error(result, 0)
        end
      end
      return original_oldManThrow(self, ...)
    end
  end
  -- Injected: the Pallet-intro thrower sprite is NOT overridden; with
  -- demoName kept canonical, the engine itself selects Prof. Oak's back
  -- pic for that demo (vanilla behavior).

  local literal_body = mod:read("lang/literal_handlers.lua")
  if literal_body then
    local chunk, err = loadstring(literal_body, "lang/literal_handlers.lua")
    if not chunk then error(err) end
    local setup = chunk()
    if type(setup) ~= "function" then error("literal_handlers.lua must return a function") end
    setup(mod)
  end

end
