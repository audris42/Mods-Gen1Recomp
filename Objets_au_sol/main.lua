-- Objets au sol pour Gen1Recomp 0.1.98+
--
-- Ce mod ne lit et ne modifie aucune ROM. Il affiche les emplacements
-- d'objets caches deja extraits par Gen1Recomp dans Game.data.field.

return function(mod)
  local OverworldState = require("src.world.OverworldController")
  local originalDrawUI = OverworldState.drawUI
  local originalInteract = OverworldState.interact
  local game

  -- Petit losange de 8 x 8 pixels, dessine dans l'espace ecran Game Boy.
  -- Le clignotement reste discret et ne depend pas de la vitesse du jeu.
  local function drawMarker(x, y)
    local pulse = math.floor(os.clock() * 4) % 2
    local light = pulse == 0 and 1 or 0.78

    love.graphics.setColor(0, 0, 0, 0.85)
    love.graphics.polygon("fill",
      x + 4, y, x + 8, y + 4, x + 4, y + 8, x, y + 4)
    love.graphics.setColor(light, light, light, 1)
    love.graphics.polygon("fill",
      x + 4, y + 1, x + 7, y + 4, x + 4, y + 7, x + 1, y + 4)
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle("fill", x + 3, y + 3, 3, 3)
    love.graphics.setColor(1, 1, 1, 1)
  end

  local function drawHiddenItems(self)
    if not game or not game.data or not game.save or not self.map then return end

    local field = game.data.field
    local hidden = field and field.hiddenItems
    local items = hidden and hidden[self.map.id]
    if not items then return end

    local taken = game.save.hiddenTaken or {}
    local cam = self.camera
    if not cam then return end

    for _, item in ipairs(items) do
      local key = self.map.id .. "_" .. item.x .. "_" .. item.y
      if not taken[key] then
        -- Une cellule de carte Gen 1 mesure 16 x 16 pixels. Le marqueur est
        -- centre sur la cellule et suit exactement la camera de l'overworld.
        local x = math.floor(item.x * 16 - cam.x + 4)
        local y = math.floor(item.y * 16 - cam.y + 4)
        if x > -8 and x < 160 and y > -8 and y < 144 then
          drawMarker(x, y)
        end
      end
    end
  end

  OverworldState.drawUI = function(self, ...)
    drawHiddenItems(self)
    return originalDrawUI(self, ...)
  end

  -- Certains emplacements extraits sont poses sur un decor dont les cases
  -- voisines ne permettent pas toujours de reproduire confortablement
  -- l'orientation attendue par le jeu original. A rend donc l'objet actif
  -- depuis sa case ou l'une des quatre cases directement voisines.
  OverworldState.interact = function(self, ...)
    if game and game.data and game.save and self.map and self.player then
      local field = game.data.field
      local hidden = field and field.hiddenItems
      local items = hidden and hidden[self.map.id]
      local taken = game.save.hiddenTaken or {}
      local px, py = self.player.cellX, self.player.cellY

      for _, item in ipairs(items or {}) do
        local key = self.map.id .. "_" .. item.x .. "_" .. item.y
        local distance = math.abs(item.x - px) + math.abs(item.y - py)
        if not taken[key] and distance <= 1 then
          if self:tryHiddenObject(item.x, item.y) then return end
        end
      end
    end
    return originalInteract(self, ...)
  end

  mod.events:on("game.ready", function(payload)
    game = payload and payload.game
    mod.log:info("Objets au sol 1.0.0 actif (Rouge/Bleu/Jaune)")
  end)
end
