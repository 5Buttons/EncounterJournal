-- Addon/EncounterJournal/worldmap_ids.lua — WorldMapArea.dbc id -> Map.dbc id for the maps the journal's
-- instances live on. Keys are the RAW WorldMapArea.dbc ids (the same numbers as the WorldMapAreaID list on
-- warcraft.wiki.gg), values the instance's Map.dbc id (inst.mapID in the data files).
--
-- 3.3.5a's map API is off by one against the DBC, in both directions. Blizzard's own 3.3.5 FrameXML
-- (WorldMapFrame.lua) uses WORLDMAP_WINTERGRASP_ID = 502 for DBC row 501 and calls
-- SetMapByID(GetCurrentMapAreaID() - 1):
--   GetCurrentMapAreaID()  returns  dbc id + 1     (The Nexus -> 521)
--   SetMapByID(id)         expects  dbc id         (The Nexus -> 520)
-- EJApi.lua does that translation (WORLDMAP_GET_OFFSET); keep this table in DBC ids so it can be checked
-- against the wiki. In-game check: stand in The Nexus, open the map, /dump GetCurrentMapAreaID() -> 521.
--
-- Hand-maintained (the worldmap.py generator that read the client DBC is gone, see README). Originally
-- read from a client carrying the WDM patch (github.com/Trimitor/WDM-patch, patch-enUS-M.MPQ).

local EJ = _G.EJ
EJ.ej = EJ.ej or {}

EJ.ej.WORLDMAP_AREA_TO_MAP = {
  -- ── Dungeon maps a stock 3.3.5a (build 12340) client ships ──────────────────────────────
  [520] = 576,  -- TheNexus (The Nexus)
  [521] = 595,  -- CoTStratholme (The Culling of Stratholme)
  [522] = 619,  -- Ahnkahet (Ahn'kahet: The Old Kingdom)
  [523] = 574,  -- UtgardeKeep (Utgarde Keep)
  [524] = 575,  -- UtgardePinnacle (Utgarde Pinnacle)
  [525] = 602,  -- HallsofLightning (Halls of Lightning)
  [526] = 599,  -- Ulduar77 (Halls of Stone)
  [527] = 616,  -- TheEyeofEternity (The Eye of Eternity)
  [528] = 578,  -- Nexus80 (The Oculus)
  [529] = 603,  -- Ulduar (Ulduar)
  [530] = 604,  -- Gundrak (Gundrak)
  [531] = 615,  -- TheObsidianSanctum (The Obsidian Sanctum)
  [532] = 624,  -- VaultofArchavon (Vault of Archavon)
  [533] = 601,  -- AzjolNerub (Azjol-Nerub)
  [534] = 600,  -- DrakTharonKeep (Drak'Tharon Keep)
  [535] = 533,  -- Naxxramas (Naxxramas)
  [536] = 608,  -- VioletHold (The Violet Hold)
  [542] = 650,  -- TheArgentColiseum (Trial of the Champion)
  [543] = 649,  -- TheArgentColiseum (Trial of the Crusader)
  [601] = 632,  -- TheForgeofSouls (The Forge of Souls)
  [602] = 658,  -- PitofSaron (Pit of Saron)
  [603] = 668,  -- HallsofReflection (Halls of Reflection)
  [604] = 631,  -- IcecrownCitadel (Icecrown Citadel)
  [609] = 724,  -- TheRubySanctum (The Ruby Sanctum)

  -- ── Cataclysm-era dungeon maps: only present with the WDM patch (patch-enUS-M.MPQ) ──────
  -- A stock client has no WorldMapArea rows above 609 for these instances: GetCurrentMapAreaID never
  -- returns them there and SetMapByID on them does nothing, so the rows are harmless without the patch.
  -- Scarlet Monastery, Scholomance, Zul'Gurub and Zul'Aman have no row yet (ids not verified).
  [680] = 389,  -- Ragefire (Ragefire Chasm)
  [686] = 209,  -- ZulFarrak (Zul'Farrak)
  [687] = 109,  -- TheTempleOfAtalHakkar (The Temple of Atal'hakkar)
  [688] = 48,   -- BlackfathomDeeps (Blackfathom Deeps)
  [690] = 34,   -- TheStockade (The Stockade)
  [691] = 90,   -- Gnomeregan (Gnomeregan)
  [692] = 70,   -- Uldaman (Uldaman)
  [696] = 409,  -- MoltenCore (Molten Core)
  [699] = 429,  -- DireMaul (Dire Maul - Capital Gardens)
  [704] = 230,  -- BlackrockDepths (Blackrock Depths)
  [710] = 540,  -- TheShatteredHalls (The Shattered Halls)
  [717] = 509,  -- RuinsofAhnQiraj (Ruins of Ahn'Qiraj)
  [718] = 249,  -- OnyxiasLair (Onyxia's Lair)
  [721] = 229,  -- BlackrockSpire (Lower Blackrock Spire)
  [722] = 558,  -- AuchenaiCrypts (Auchenai Crypts)
  [723] = 556,  -- SethekkHalls (Sethekk Halls)
  [724] = 555,  -- ShadowLabyrinth (Shadow Labyrinth)
  [725] = 542,  -- TheBloodFurnace (The Blood Furnace)
  [726] = 546,  -- TheUnderbog (The Underbog)
  [727] = 545,  -- TheSteamvault (The Steamvault)
  [728] = 547,  -- TheSlavePens (The Slave Pens)
  [729] = 553,  -- TheBotanica (The Botanica)
  [730] = 554,  -- TheMechanar (The Mechanar)
  [731] = 552,  -- TheArcatraz (The Arcatraz)
  [732] = 557,  -- ManaTombs (Mana-Tombs)
  [733] = 269,  -- CoTTheBlackMorass (The Black Morass)
  [734] = 560,  -- CoTHillsbradFoothills (Old Hillsbrad Foothills)
  [749] = 43,   -- WailingCaverns (Wailing Caverns)
  [750] = 349,  -- Maraudon (Maraudon)
  [755] = 469,  -- BlackwingLair (Blackwing Lair)
  [756] = 36,   -- TheDeadmines (Deadmines)
  [760] = 129,  -- RazorfenDowns (Razorfen Downs)
  [761] = 47,   -- RazorfenKraul (Razorfen Kraul)
  [764] = 33,   -- ShadowfangKeep (Shadowfang Keep)
  [765] = 329,  -- Stratholme (Stratholme - Main Gate)
  [766] = 531,  -- AhnQiraj (Temple of Ahn'Qiraj)
  [775] = 534,  -- CoTMountHyjal (The Battle for Mount Hyjal)
  [776] = 565,  -- GruulsLair (Gruul's Lair)
  [779] = 544,  -- MagtheridonsLair (Magtheridon's Lair)
  [780] = 548,  -- CoilfangReservoir (Serpentshrine Cavern)
  [782] = 550,  -- TempestKeep (The Eye)
  [789] = 580,  -- SunwellPlateau (Sunwell Plateau)
  [796] = 564,  -- BlackTemple (Black Temple)
  [797] = 543,  -- HellfireRamparts (Hellfire Ramparts)
  [798] = 585,  -- MagistersTerrace (Magisters' Terrace)
  [799] = 532,  -- Karazhan (Karazhan)
}
