-- Reel Time pour Gen1Recomp.
-- Affiche l'heure locale de l'ordinateur sans modifier la ROM ni la sauvegarde.
return function(mod)
  local Font = require("src.render.Font")
  local OverworldState = require("src.world.OverworldController")
  local Renderer = require("src.render.Renderer")

  mod.options:define({
    {
      key = "visible", type = "toggle", label = "HORLOGE", default = true,
      help = "Affiche l'heure reelle dans le coin superieur droit.",
    },
    {
      key = "format", type = "choice", label = "FORMAT", default = "24h",
      choices = { { "24 H", "24h" }, { "12 H", "12h" } },
      help = "Choisit le format d'affichage de l'heure.",
    },
  })

  local function option(key, fallback)
    local ok, value = pcall(mod.options.get, mod.options, key)
    if ok and value ~= nil then return value end
    return fallback
  end

  local warned = false
  local function clockText()
    if not os or type(os.date) ~= "function" then
      if not warned then
        warned = true
        mod.log:warn("Horloge indisponible: os.date n'est pas accessible")
      end
      return nil
    end

    local ok, value = pcall(os.date, option("format", "24h") == "12h" and "%I:%M %p" or "%H:%M")
    if not ok then return nil end
    return value
  end

  local function drawClock(surfaceWidth)
    if not option("visible", true) then return end
    local text = clockText()
    if not text then return end

    surfaceWidth = surfaceWidth or 160
    local textWidth = Font.width(text)
    local boxWidth = textWidth + 6
    local x, y = surfaceWidth - boxWidth - 2, 2
    local oldColor = { love.graphics.getColor() }
    local oldLineWidth = love.graphics.getLineWidth and love.graphics.getLineWidth() or 1

    love.graphics.setColor(1, 1, 1, 0.92)
    love.graphics.rectangle("fill", x, y, boxWidth, 12)
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle("line", x, y, boxWidth, 12)
    Font.draw(text, x + 3, y + 2)

    if love.graphics.setLineWidth then love.graphics.setLineWidth(oldLineWidth) end
    love.graphics.setColor(oldColor[1] or 1, oldColor[2] or 1, oldColor[3] or 1, oldColor[4] or 1)
  end

  -- Vue 2D classique : l'horloge est dessinee au-dessus de l'interface du jeu.
  if not OverworldState._realClockDrawWrapped then
    OverworldState._realClockDrawWrapped = true
    local baseDrawUI = OverworldState.drawUI
    function OverworldState:drawUI(...)
      local result = baseDrawUI(self, ...)
      local Game = require("src.core.Game")
      if not (Game.renderer and Game.renderer.worldOverride) then
        drawClock(160)
      end
      return result
    end
  end

  -- Modes de rendu qui dessinent le monde dans une surface haute resolution.
  if not Renderer._realClockEndWrapped then
    Renderer._realClockEndWrapped = true
    local baseEndFrame = Renderer.endFrame
    function Renderer:endFrame(zones, worldZones)
      if self.worldOverride and self.worldOverride.getWidth then
        local world = self.worldOverride
        local previousCanvas = love.graphics.getCanvas()
        pcall(function()
          love.graphics.setCanvas(world)
          love.graphics.push()
          love.graphics.origin()
          local scale = 2
          love.graphics.scale(scale, scale)
          drawClock(world:getWidth() / scale)
          love.graphics.pop()
        end)
        if previousCanvas then love.graphics.setCanvas(previousCanvas) else love.graphics.setCanvas() end
      end
      return baseEndFrame(self, zones, worldZones)
    end
  end

  mod.log:info("Reel Time 1.0.0 pret")
end
