-- Addon/EncounterJournal/EJApi.lua — the RETAIL Encounter Journal API (the EJ_* globals,
-- C_EncounterJournal and EncounterJournal_OpenJournal) re-created over EJ.ej.DATA, so retail-era
-- addon code that reads the journal (Details!'s encounter tooling, DetailsFramework's
-- EncounterJournal wrapper, tooltip "open in journal" hooks, …) works on 3.3.5a. Read-only and
-- data-driven; the journal window itself never calls these.
--
-- Signatures follow what such addons actually call: the Cata/MoP-era flat return lists
-- (EJ_GetSectionInfo's 14 returns, EJ_GetEncounterInfo's 8) plus the 7.0+ table forms
-- (C_EncounterJournal.GetSectionInfo / GetLootInfoByIndex). 3.3.5a specifics:
--   * No |Hjournal: hyperlinks exist on this client → every `link` return is nil.
--   * ENCOUNTER_START's dungeonEncounterID does not exist in 3.3.5's combat log; the
--     JournalEncounter id is returned in that slot too.
--   * Difficulty ids are retail's: 1 Normal / 2 Heroic (5-man), 3 10N, 4 25N, 5 10H, 6 25H — the
--     same numbers the loot `diff` bitmask bits use, so EJ_SetDifficulty filters loot like the window.
--   * EJ_GetInstanceForMap takes what GetCurrentMapAreaID() returns — on 3.3.5 that is the
--     WorldMapArea.dbc id + 1 (Blizzard's own 3.3.5 WorldMapFrame.lua calls
--     SetMapByID(GetCurrentMapAreaID() - 1)) — and falls back to a Map.dbc id; worldmap_ids.lua holds
--     the dbc ids. dungeonAreaMapID returns the raw WorldMapArea.dbc id, which is what SetMapByID
--     takes here (the 3.3.5 analogue of retail's uiMapID) — so it is GetCurrentMapAreaID() - 1, not
--     equal to it.
--   * Texture returns are the shipped BLP paths (a raw FileDataID renders red here); an unshipped
--     one is returned as the number, like retail would.
--   * Loot rows resolve through GetItemInfo, else the baked name / item_info.lua fallbacks.

local EJ = _G.EJ
EJ.ej = EJ.ej or {}

local S = { tier = nil, instance = nil, encounter = nil, difficulty = nil,
            classFilter = 0, specFilter = 0, slotFilter = 0, search = nil, results = nil }

-- Cata-era Map.dbc ids the DB2 rosters carry for revamped Classic dungeons; 3.3.5 uses the originals.
local MAP_FIX = { [1004] = 189, [1007] = 289, [859] = 309 }   -- Scarlet Monastery, Scholomance, Zul'Gurub

-- 3.3.5's GetCurrentMapAreaID() returns WorldMapArea.dbc id + 1, while SetMapByID() takes the dbc id
-- (see worldmap_ids.lua). Subtracted from the id retail-style callers hand EJ_GetInstanceForMap.
local WORLDMAP_GET_OFFSET = 1

local TIER = {
  { name = EXPANSION_NAME0 or "Classic" },
  { name = EXPANSION_NAME1 or "The Burning Crusade" },
  { name = EXPANSION_NAME2 or "Wrath of the Lich King" },
}

local function instances() return (EJ.ej.DATA and EJ.ej.DATA.instances) or {} end
local function tierOf(inst)
  if inst.tier then return inst.tier end
  if inst._wotlk then return 3 elseif inst._tbc then return 2 end
  return 1
end
local function mapOf(inst) return MAP_FIX[inst.mapID or 0] or inst.mapID end
local function tex(fdid)
  if not fdid or fdid == 0 then return nil end
  return (EJ.tex and EJ.tex.localFiles and EJ.tex.localFiles[fdid]) or fdid
end
local function nz(v) if v and v ~= 0 then return v end return nil end

-- Lazy indexes over the (static) dataset.
local byInst, byEnc, bySec, encInst, tierLists, mapToArea
local function index()
  if byInst then return end
  byInst, byEnc, bySec, encInst, tierLists = {}, {}, {}, {}, { {}, {}, {} }
  for i, inst in ipairs(instances()) do
    byInst[inst.id] = inst
    inst._ejOrder = i   -- data order = the DB2 roster order; keeps the sort below stable
    local tl = tierLists[tierOf(inst)]
    if tl then tl[#tl + 1] = inst end
    for _, enc in ipairs(inst.encounters or {}) do
      byEnc[enc.id] = enc; encInst[enc.id] = inst
      for _, s in ipairs(enc.sections or {}) do bySec[s.id] = s end
    end
  end
  for _, tl in ipairs(tierLists) do
    table.sort(tl, function(a, b)
      if (a.isRaid and true or false) ~= (b.isRaid and true or false) then return not a.isRaid end
      if (a.minLevel or 0) ~= (b.minLevel or 0) then return (a.minLevel or 0) < (b.minLevel or 0) end
      return (a._ejOrder or 0) < (b._ejOrder or 0)
    end)
  end
  mapToArea = {}   -- Map.dbc id -> WorldMapArea.dbc id (what SetMapByID takes on 3.3.5)
  for area, map in pairs(EJ.ej.WORLDMAP_AREA_TO_MAP or {}) do
    if not mapToArea[map] then mapToArea[map] = area end
  end
end
EJ.ej.ResetApiIndex = function() byInst = nil end   -- after a data overlay is applied late

local function rootSection(enc)
  if enc.rootSection and enc.rootSection ~= 0 then return enc.rootSection end
  return enc.sections and enc.sections[1] and enc.sections[1].id or nil
end
local function buckets(inst)
  if EJ.ej.InstanceDiffBuckets then return EJ.ej.InstanceDiffBuckets(inst) end
  return {}
end
local function currentDifficulty(inst)
  if S.difficulty then return S.difficulty end
  local b = inst and buckets(inst)
  return b and b[1] or 1
end

-- ── Tiers ──────────────────────────────────────────────────────────────────────────────────
function EJ_GetNumTiers() return #TIER end
function EJ_GetTierInfo(i) local t = TIER[i]; if t then return t.name, nil end end
function EJ_SelectTier(i) if TIER[i] then S.tier = i end end
function EJ_GetCurrentTier() return S.tier or 3 end

-- ── Instances ──────────────────────────────────────────────────────────────────────────────
local function instanceInfo(inst)
  return inst.name, inst.desc or "", tex(inst.bgFDID), tex(inst.buttonFDID), tex(inst.loreFDID),
         (mapToArea and mapToArea[mapOf(inst)]) or 0, nil, (#buckets(inst) >= 2), mapOf(inst), 0
end
function EJ_GetInstanceByIndex(idx, isRaid)
  index()
  local n, want = 0, isRaid and true or false
  for _, inst in ipairs(tierLists[S.tier or 3] or {}) do
    if (inst.isRaid and true or false) == want then
      n = n + 1
      if n == idx then return inst.id, instanceInfo(inst) end
    end
  end
end
function EJ_SelectInstance(id)
  index()
  if byInst[id] then S.instance, S.encounter, S.results = id, nil, nil; return true end
  return false
end
function EJ_GetCurrentInstance() return S.instance end
function EJ_GetInstanceInfo(id)
  index()
  local inst = byInst[id or S.instance or 0]
  if inst then return instanceInfo(inst) end
end
function EJ_InstanceIsRaid()
  index()
  local inst = byInst[S.instance or 0]
  return inst and inst.isRaid and true or false
end
local function instanceForMapDbc(map)
  if not map then return nil end
  for _, inst in ipairs(instances()) do
    if mapOf(inst) == map then return inst.id end
  end
end
-- mapID: what GetCurrentMapAreaID() returns on this client (WorldMapArea.dbc id + 1 on 3.3.5) — the
-- retail contract — else a Map.dbc id. The area reading goes first because the two id spaces overlap:
-- GetCurrentMapAreaID() in the Forge of Souls is 602, and Map.dbc 602 is Halls of Lightning.
-- Returns 0 when unknown.
function EJ_GetInstanceForMap(mapID)
  index()
  if not mapID then return 0 end
  local areaToMap = EJ.ej.WORLDMAP_AREA_TO_MAP or {}
  return instanceForMapDbc(areaToMap[mapID - WORLDMAP_GET_OFFSET]) or instanceForMapDbc(mapID) or 0
end
-- Not a retail function; handy on 3.3.5 where GetRealZoneText is often all an addon has.
function EJ_GetInstanceForZoneName(name)
  index()
  if not name or name == "" then return 0 end
  local n = name:lower()
  for _, inst in ipairs(instances()) do
    if (inst.name or ""):lower() == n then return inst.id end
  end
  return 0
end

-- ── Encounters ─────────────────────────────────────────────────────────────────────────────
local function encTuple(enc, inst)
  return enc.name, enc.desc or "", enc.id, rootSection(enc), nil, inst and inst.id, enc.id, inst and mapOf(inst)
end
function EJ_GetEncounterInfoByIndex(idx, instanceID)
  index()
  local inst = byInst[instanceID or S.instance or 0]
  local enc = inst and inst.encounters and inst.encounters[idx]
  if enc then return encTuple(enc, inst) end
end
function EJ_GetEncounterInfo(encID)
  index()
  local enc = byEnc[encID or 0]
  if enc then return encTuple(enc, encInst[enc.id]) end
end
function EJ_SelectEncounter(encID)
  index()
  local enc = byEnc[encID or 0]
  if enc then
    S.encounter = enc.id
    S.instance = encInst[enc.id] and encInst[enc.id].id or S.instance
    S.results = nil
    return true
  end
  return false
end
function EJ_GetCurrentEncounter() return S.encounter end

-- ── Creatures ──────────────────────────────────────────────────────────────────────────────
-- id, name, description, displayInfo, iconImage, uiModelSceneID
function EJ_GetCreatureInfo(idx, encID)
  index()
  local enc = byEnc[encID or S.encounter or 0]
  local cr = enc and enc.creatures and enc.creatures[idx]
  if cr then return idx, cr.name, "", cr.display or 0, tex(cr.file), nil end
end

-- ── Sections ───────────────────────────────────────────────────────────────────────────────
local function flagIndices(flags)
  local out = {}
  flags = flags or 0
  for i = 0, 13 do
    if bit.band(flags, bit.lshift(1, i)) ~= 0 then out[#out + 1] = i end
  end
  return out
end
local function depthOf(s)
  local d, p, guard = 0, s.parent, 0
  while p and p ~= 0 and bySec[p] and guard < 32 do
    d = d + 1; p = bySec[p].parent; guard = guard + 1
  end
  return d
end
-- Cata/MoP flat form: title, description, depth, abilityIcon, displayInfo, siblingID,
-- nextSectionID, filteredByDifficulty, link, startsOpen, flag1, flag2, flag3, flag4
function EJ_GetSectionInfo(sectionID)
  index()
  local s = bySec[sectionID or 0]
  if not s then return end
  local f = flagIndices(s.flags)
  return s.title or "", s.body or "", depthOf(s), (type(s.icon) == "string" and s.icon) or "",
         s.cdisp or 0, nz(s.sib), nz(s.child), false, nil, true, f[1], f[2], f[3], f[4]
end

-- ── Loot ───────────────────────────────────────────────────────────────────────────────────
local lootCache = {}
local function lootList()
  index()
  local inst = byInst[S.instance or 0]
  if not inst then return {} end
  local diff = currentDifficulty(inst)
  local key = (S.encounter or 0) .. ":" .. inst.id .. ":" .. tostring(diff) .. ":" .. tostring(S.slotFilter)
  if lootCache.key == key then return lootCache.list end
  local list, seen = {}, {}
  local encs = S.encounter and byEnc[S.encounter] and { byEnc[S.encounter] } or (inst.encounters or {})
  for _, enc in ipairs(encs) do
    for _, e in ipairs(enc.loot or {}) do
      local id = (type(e) == "table") and e.id or e
      local d  = (type(e) == "table") and e.diff or 0
      if id and not seen[id] and (not d or d == 0 or bit.band(d, bit.lshift(1, diff)) ~= 0) then
        seen[id] = true
        list[#list + 1] = { id = id, encID = enc.id, pct = (type(e) == "table") and e.pct or 0,
                            name = (type(e) == "table") and e.name or nil }
      end
    end
  end
  lootCache.key, lootCache.list = key, list
  return list
end
local function resolveLoot(e)
  local name, link, quality, _, _, itemType, itemSubType, _, equipLoc, icon = GetItemInfo(e.id)
  local ii = EJ.ej.ITEM_INFO and EJ.ej.ITEM_INFO[e.id]
  name = name or e.name or (ii and ii[1]) or ("item:" .. e.id)
  icon = icon or (ii and ii[3] and ("Interface\\Icons\\" .. ii[3])) or "Interface\\Icons\\INV_Misc_QuestionMark"
  return name, icon, (equipLoc and equipLoc ~= "" and _G[equipLoc]) or "", itemSubType or itemType or "", link, quality
end
function EJ_GetNumLoot() return #lootList() end
-- name, icon, slot, armorType, itemID, link, encounterID
function EJ_GetLootInfoByIndex(idx)
  local e = lootList()[idx]
  if not e then return end
  local name, icon, slot, armorType, link = resolveLoot(e)
  return name, icon, slot, armorType, e.id, link, e.encID
end
function EJ_GetLootInfo(itemID)
  for _, e in ipairs(lootList()) do
    if e.id == itemID then
      local name, icon, slot, armorType, link = resolveLoot(e)
      return name, icon, slot, armorType, e.id, link, e.encID
    end
  end
end
function EJ_IsLootListOutOfDate() return false end
function EJ_GetNumEncountersForLootByIndex() return 1 end
function EJ_GetLootFilter() return S.classFilter, S.specFilter end
function EJ_SetLootFilter(classID, specID) S.classFilter, S.specFilter = classID or 0, specID or 0 end
function EJ_ResetLootFilter() S.classFilter, S.specFilter = 0, 0 end
function EJ_GetSlotFilter() return S.slotFilter end
function EJ_SetSlotFilter(f) S.slotFilter = f or 0; lootCache.key = nil end
function EJ_ResetSlotFilter() S.slotFilter = 0; lootCache.key = nil end

-- ── Difficulty ─────────────────────────────────────────────────────────────────────────────
function EJ_SetDifficulty(d) S.difficulty = tonumber(d); lootCache.key = nil end
function EJ_GetDifficulty()
  index()
  return currentDifficulty(byInst[S.instance or 0])
end
function EJ_IsValidInstanceDifficulty(d)
  index()
  local inst = byInst[S.instance or 0]
  if not inst then return false end
  for _, b in ipairs(buckets(inst)) do if b == d then return true end end
  return false
end

-- ── Search ─────────────────────────────────────────────────────────────────────────────────
-- Result rows: id, stype, difficultyID, instanceID, encounterID, itemLink
-- (stype per retail EJ_STYPE_*: 1 instance, 2 encounter, 3 section, 4 item, 5 creature)
local function runSearch(text)
  local out = {}
  local needle = (text or ""):lower()
  if #needle < 2 then return out end
  index()
  for _, inst in ipairs(instances()) do
    if (inst.name or ""):lower():find(needle, 1, true) then
      out[#out + 1] = { inst.id, 1, 0, inst.id, nil, nil }
    end
    for _, enc in ipairs(inst.encounters or {}) do
      if (enc.name or ""):lower():find(needle, 1, true) then
        out[#out + 1] = { enc.id, 2, 0, inst.id, enc.id, nil }
      end
      for _, s in ipairs(enc.sections or {}) do
        if (s.title or ""):lower():find(needle, 1, true) then
          out[#out + 1] = { s.id, 3, 0, inst.id, enc.id, nil }
        end
      end
      for _, e in ipairs(enc.loot or {}) do
        local id = (type(e) == "table") and e.id or e
        local nm = (type(e) == "table") and e.name or nil
        if not nm and id and EJ.ej.ITEM_INFO and EJ.ej.ITEM_INFO[id] then nm = EJ.ej.ITEM_INFO[id][1] end
        if nm and nm:lower():find(needle, 1, true) then
          out[#out + 1] = { id, 4, 0, inst.id, enc.id, nil }
        end
      end
    end
  end
  return out
end
function EJ_SetSearch(text) S.search = text; S.results = runSearch(text) end
function EJ_ClearSearch() S.search, S.results = nil, nil end
function EJ_GetNumSearchResults() return S.results and #S.results or 0 end
function EJ_GetSearchResult(idx)
  local r = S.results and S.results[idx]
  if r then return r[1], r[2], r[3], r[4], r[5], r[6] end
end
function EJ_GetSearchSize() return EJ_GetNumSearchResults() end
function EJ_GetSearchProgress() return 1, 1 end
function EJ_IsSearchFinished() return true end

-- ── C_EncounterJournal (7.0+ table forms) ──────────────────────────────────────────────────
C_EncounterJournal = C_EncounterJournal or {}
C_EncounterJournal.IsEncounterComplete = C_EncounterJournal.IsEncounterComplete or function() return false end
function C_EncounterJournal.GetSectionInfo(sectionID)
  index()
  local s = bySec[sectionID or 0]
  if not s then return nil end
  return {
    title = s.title or "", description = s.body or "", headerType = (nz(s.child) and 1) or 0,
    abilityIcon = (type(s.icon) == "string" and s.icon) or nil, creatureDisplayID = s.cdisp or 0,
    siblingSectionID = nz(s.sib), firstChildSectionID = nz(s.child), filteredByDifficulty = false,
    link = nil, startsOpen = true, spellID = s.spell or 0, uiModelSceneID = nil,
  }
end
function C_EncounterJournal.GetSectionIconFlags(sectionID)
  index()
  local s = bySec[sectionID or 0]
  return s and flagIndices(s.flags) or {}
end
function C_EncounterJournal.GetLootInfoByIndex(idx)
  local e = lootList()[idx]
  if not e then return nil end
  local name, icon, slot, armorType, link = resolveLoot(e)
  return { itemID = e.id, encounterID = e.encID, name = name, icon = icon, slot = slot, armorType = armorType,
           link = link, handError = false, weaponTypeError = false, displayAsPerPlayerLoot = false,
           displayAsVeryRare = false, displayAsExtremelyRare = false }
end
function C_EncounterJournal.GetLootInfo(itemID)
  for _, e in ipairs(lootList()) do
    if e.id == itemID then
      local name, icon, slot, armorType, link = resolveLoot(e)
      return { itemID = e.id, encounterID = e.encID, name = name, icon = icon, slot = slot, armorType = armorType, link = link }
    end
  end
end
function C_EncounterJournal.GetEncountersOnMap() return {} end
function C_EncounterJournal.GetDungeonEntrancesForMap() return {} end
function C_EncounterJournal.GetInstanceForGameMap(mapID) return EJ_GetInstanceForMap(mapID) end

-- ── Navigation: what retail's tooltip/other-addon "open in journal" hooks call ──────────────
function EncounterJournal_LoadUI() end   -- the journal is always loaded here
-- (difficultyID, instanceID, encounterID, sectionID, creatureID, itemID) — retail's signature.
function EncounterJournal_OpenJournal(difficultyID, instanceID, encounterID, sectionID, creatureID, itemID)
  index()
  local inst = byInst[instanceID or 0]
  local enc = byEnc[encounterID or 0]
  if not inst and enc then inst = encInst[enc.id] end
  if not (EJ.ej.Open and EJ.ej.ShowInstance) then return end
  EJ.ej.Open()
  if inst then
    EJ.ej.ShowInstance(inst)
    if enc and EJ.ej.ShowBoss then
      EJ.ej.ShowBoss(enc)
      if itemID and EJ.ej.SelectTab then EJ.ej.SelectTab(2) end
    end
  end
end
