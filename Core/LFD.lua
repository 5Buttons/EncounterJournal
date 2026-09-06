-- Addon/Core/LFD.lua — "Find Group" bridge into the 3.3.5 Dungeon Finder.
--
-- Retail's journal has no queue button for old dungeons, but 3.3.5 DOES have a native LFD
-- system covering classic/TBC/WotLK dungeons — a genuinely useful 3.3.5-only addition. We map
-- a journal instance to its LFGDungeons entries by NAME at runtime (one cached
-- GetLFGDungeonInfo id scan — no baked ID table to maintain or get wrong), and the button
-- opens the LFD window in "Specific Dungeon" mode with exactly that dungeon's rows (normal +
-- heroic share the name) ticked. Raids aren't LFD-queueable on 3.3.5 → Available() is false.
-- Every FrameXML touch is guarded: worst case the button just opens the Dungeon Finder.

local EJ = EJ
EJ.lfd = EJ.lfd or {}
local M = EJ.lfd

local MAX_SCAN = 350   -- LFGDungeons ids top out well below this on 3.3.5

local byName   -- lazily-built: normalized dungeon name → { dungeonID, ... }

local function norm(s)
  s = (s or ""):lower():gsub("^the ", "")
  return (s:gsub("%s+", " "))
end

local function buildMap()
  byName = {}
  if not GetLFGDungeonInfo then return end
  for id = 1, MAX_SCAN do
    -- pcall: some builds error on holes in the id range instead of returning nil
    local ok, name = pcall(GetLFGDungeonInfo, id)
    if ok and name and name ~= "" then
      local k = norm(name)
      byName[k] = byName[k] or {}
      byName[k][#byName[k] + 1] = id
    end
  end
end

-- Can this journal instance be queued? (dungeon + present in the LFD list + LFD UI loaded)
function M.Available(inst)
  if not inst or inst.isRaid then return false end
  if not (GetLFGDungeonInfo and _G.LFDParentFrame) then return false end
  if not byName then buildMap() end
  local ids = byName[norm(inst.name)]
  return (ids and #ids > 0) and true or false
end

-- Open the Dungeon Finder in Specific-Dungeon mode with ONLY this dungeon ticked.
function M.FindGroup(inst)
  if InCombatLockdown and InCombatLockdown() then return end
  if not M.Available(inst) then return end
  local ids = byName[norm(inst.name)]
  pcall(function()
    if ShowUIPanel and _G.LFDParentFrame then ShowUIPanel(_G.LFDParentFrame) end
    if LFDQueueFrame_SetType then LFDQueueFrame_SetType("specific") end
    if type(LFGEnabledList) == "table" then
      -- untick everything first (collect keys before writing — the setter mutates the table),
      -- then tick our rows. Prefer the FrameXML setter (keeps the header tri-states right).
      local keys = {}
      for id in pairs(LFGEnabledList) do keys[#keys + 1] = id end
      for _, id in ipairs(keys) do
        if LFGDungeonList_SetDungeonEnabled then LFGDungeonList_SetDungeonEnabled(id, false)
        else LFGEnabledList[id] = false end
      end
      for _, id in ipairs(ids) do
        if LFGDungeonList_SetDungeonEnabled then LFGDungeonList_SetDungeonEnabled(id, true)
        else LFGEnabledList[id] = true end
      end
      if LFDQueueFrameSpecificList_Update then LFDQueueFrameSpecificList_Update() end
    end
  end)
end
