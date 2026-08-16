-- Generated qid-driven literal dialogue handlers.
return function(mod)
  local TextBox = mod.ui.TextBox
  local ChoiceBox = mod.ui.ChoiceBox
  mod.content.map_scripts:register("VIRIDIAN_CITY", {talk = {
    ["TEXT_VIRIDIANCITY_YOUNGSTER2"] = function(game, ow, npc, done)
      game.stack:push(TextBox.new(game, "Tu veux tout\nsavoir sur les 2\011types de chenille\011POKéMON?", function()
        game.stack:push(ChoiceBox.new(game, function(yes)
          game.stack:push(TextBox.new(game, yes and "Contrairement à\nCHENIPAN, ASPICOT\011est venimeux.\012Attention à son\nDARD-VENIN!" or "Bon. OK.", done))
        end))
      end))
    end,
  },
  })
  mod.content.map_scripts:register("MUSEUM_1F", {talk = {
    ["TEXT_MUSEUM1F_SCIENTIST1"] = function(game, ow, npc, done)
      if game.save.flags["EVENT_BOUGHT_MUSEUM_TICKET"] then
        game.stack:push(TextBox.new(game, "Prends tout ton\ntemps pour\011regarder!", done))
      else
        game.stack:push(TextBox.new(game, "50¥ le ticket\npour un enfant.\012Voulez-vous\nentrer?", function()
          game.stack:push(ChoiceBox.new(game, function(yes)
            if yes then
              if (game.save.money or 0) >= 50 then
                game.save.money = (game.save.money or 0) + (-50)
                game.save.flags["EVENT_BOUGHT_MUSEUM_TICKET"] = true
                game.stack:push(TextBox.new(game, "50¥! Parfait!\nMerci!", done))
              else
                game.stack:push(TextBox.new(game, "Vous n'avez pas\nassez d'argent.", done))
              end
            else
              game.stack:push(TextBox.new(game, "A bientôt!", done))
            end
          end))
        end))
      end
    end,
  },
    onStep = function(game, ow, x, y)
      if ((x == 9 and y == 4) or (x == 10 and y == 4)) and not game.save.flags["EVENT_BOUGHT_MUSEUM_TICKET"] then
        local function on_done() end
        game.stack:push(TextBox.new(game, "50¥ le ticket\npour un enfant.\012Voulez-vous\nentrer?", function()
          game.stack:push(ChoiceBox.new(game, function(yes)
            if yes then
              if (game.save.money or 0) >= 50 then
                game.save.money = (game.save.money or 0) + (-50)
                game.save.flags["EVENT_BOUGHT_MUSEUM_TICKET"] = true
                game.stack:push(TextBox.new(game, "50¥! Parfait!\nMerci!", on_done))
              else
                game.stack:push(TextBox.new(game, "Vous n'avez pas\nassez d'argent.", function()
                  ow:scriptMove(ow.player, "down", 1, on_done)
                end))
              end
            else
              game.stack:push(TextBox.new(game, "A bientôt!", function()
                ow:scriptMove(ow.player, "down", 1, on_done)
              end))
            end
          end))
        end))
        return true
      end
      return false
    end,
  })
  mod.content.map_scripts:register("BIKE_SHOP", {talk = {
    ["TEXT_BIKESHOP_CLERK"] = function(game, ow, npc, done)
      if (game.save.inventory["BICYCLE"] or 0) > 0 then
        game.stack:push(TextBox.new(game, "Comment se porte\nta BICYCLETTE?\012Tu peux aller sur\nla PISTE CYCLABLE\011et dans les\011GROTTES!", done))
      else
        if (game.save.inventory["BIKE_VOUCHER"] or 0) > 0 then
          game.stack:push(TextBox.new(game, "Oh! Mais c'est...\012Un BON pour\nune BICYCLETTE!\012OK! Voilà ta\nBICYCLETTE!", function()
            game.save.inventory["BIKE_VOUCHER"] = nil
            game.save.inventory["BICYCLE"] = 1
            game.save.flags["EVENT_GOT_BICYCLE"] = true
            game.stack:push(TextBox.new(game, "{PLAYER} échange\nle BON contre\011une BICYCLETTE.", done))
          end))
        else
          game.stack:push(TextBox.new(game, "Bienvenue au\nCYCLES A GOGO.\012Nous avons\njustement une\011belle bicyclette!", done))
        end
      end
    end,
  },
  })
  mod.content.map_scripts:register("BIKE_SHOP", {talk = {
    ["TEXT_BIKESHOP_MIDDLE_AGED_WOMAN"] = function(game, ow, npc, done)
      game.stack:push(TextBox.new(game, "Un VELO de ville,\nc'est ce qu'il y\011a de mieux!\012Il n'y a pas de\nporte-bagages sur\011un VTT!", done))
    end,
  },
  })
  mod.content.map_scripts:register("BIKE_SHOP", {talk = {
    ["TEXT_BIKESHOP_YOUNGSTER"] = function(game, ow, npc, done)
      if (game.save.flags["EVENT_GOT_BICYCLE"] or (game.save.inventory["BICYCLE"] or 0) > 0) then
        game.stack:push(TextBox.new(game, "Waou! \nTa BICYCLETTE est\011super cool!", done))
      else
        game.stack:push(TextBox.new(game, "Ces VELOS sont\nsuper mais ils\011sont très chers!", done))
      end
    end,
  },
  })
end
