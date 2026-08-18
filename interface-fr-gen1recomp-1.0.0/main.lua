-- Charge uniquement le catalogue du lanceur. L'id tardif et la priorité 200
-- permettent aussi de corriger dix libellés erronés du pack principal.
return function(mod)
  local path = "lang/strings.lua"
  local body = mod:read(path)
  if not body then
    mod.log:warn("%s est introuvable", path)
    return
  end

  local chunk, err = loadstring(body, path)
  if not chunk then
    mod.log:warn("%s contient une erreur de syntaxe : %s", path, tostring(err))
    return
  end

  local ok, catalog = pcall(chunk)
  if not ok or type(catalog) ~= "table" then
    mod.log:warn("%s ne renvoie pas de table : %s", path, tostring(catalog))
    return
  end

  for source, translation in pairs(catalog) do
    if type(source) == "string" and type(translation) == "string"
        and translation ~= "" then
      mod.content.strings:override(source, translation)
    end
  end
end
