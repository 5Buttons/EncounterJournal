-- Addon/Core/WorldMap.lua — "Show Map" support for the Encounter Journal.
--this should able to get working with Trimitor Map patc: https://github.com/Trimitor/WDM-patch
local EJ = EJ
EJ.worldmap = EJ.worldmap or {}

-- Open the world map to an instance's dungeon map (the first encounter with UiMapID > 0). Returns
-- true if a map id was found and applied. No-op in combat, or if WorldMapFrame / a uiMap is absent.
function EJ.worldmap.ShowInstanceMap(inst)
  if InCombatLockdown() then return false end
  if not inst then return false end
  local uiMap = 0
  for _, e in ipairs(inst.encounters or {}) do
    if e.uiMapID and e.uiMapID > 0 then uiMap = e.uiMapID; break end
  end
  if uiMap == 0 then return false end
  local wmf = _G.WorldMapFrame
  if not wmf then return false end
  return (pcall(function()
    if not wmf:IsShown() then
      if _G.ToggleWorldMap then ToggleWorldMap() elseif _G.ShowUIPanel then ShowUIPanel(wmf) end
    end
    if wmf.SetMapID then wmf:SetMapID(uiMap) end
  end))
end
