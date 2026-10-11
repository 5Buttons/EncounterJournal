-- Addon/EncounterJournal/Assets.lua — register the Encounter Journal chrome + data-tier BLPs.
--
-- Per Law 3 / Hard Rule #10 (extract, don't approximate; same-FDID-≠-same-art): the
-- journal's interior chrome is legacy fixed-texture art, NOT modern atlas/NineSlice. The
-- master sheet UI-EncounterJournalTextures holds the bulk of it as VIRTUAL TEXCOORD
-- SLICES (dungeon/boss buttons, the 4 info tabs + their icons, paper-header 3-slices,
-- filter buttons, map buttons, loot-frame bgs, page headers) — those texcoords are
-- transcribed from retail's Blizzard_EncounterJournal.xml:3-317 into the EJ.ej.SLICES table
-- further down in this file (was Slices.lua); the full-image BLPs are shipped + registered here.
-- Also here: the BossesGen portrait overrides (was the tail of vanilla_data.lua).
--
-- Provenance (all extracted build-pinned 12.0.5.67451 via wago.tools/api/casc/<FDID>;
-- path + FDID from .scratch/atlas/ManifestInterfaceData.csv):
--   522972  UI-EncounterJournalTextures        master chrome sheet (512x1024) — slice host
--   522973  UI-EncounterJournalTextures_Tile   h-tiled mid-pieces (paper headers / filter bars)
--   527422  UI-EJ-LOREBG-Default               generic instance lore-panel background
--   527690  UI-EJ-BossModelPaperFrame          model-tab paper frame around the 3D model
--   605327/605326/605329  UI-EJ-{Classic,BurningCrusade,WrathoftheLichKing}  tier backgrounds
--   521749  UI-EJ-Icons                        legacy section flag icons (8x2 grid; fallback)
--   7494373 UICombatTimelineWarningIcons       MODERN section flag sheet (icons_16x16_* atlases)
--   521753  UI-EJ-PortraitIcon                 window portrait (the journal book icon)
--   521743  UI-EJ-BACKGROUND-Default           model-scene backdrop
--   521744  UI-EJ-BOSS-Default                 generic boss-button creature plate
--   521750  UI-EJ-JournalBG                    journal page background fill
--   521748  UI-EJ-HeroicTextIcon               heroic difficulty badge
--
-- 2026-09-05: the per-instance Backdrops/Lore/Bosses sets were completed from the DragonUI_NewEra
-- reference (its Textures/EncounterJournal ships the same retail extracts): +7 backdrops, +7 lore
-- splashes, +116 boss plates, and the 23 SQUARE 128x128 WotLK instance icons (237592…366689 —
-- the dungeon-finder-style art NewEra uses for the Wrath grid) which also stand in for the seven
-- WotLK ButtonFileDataIDs (608192, 608204-608206, 608210, 608221, 1396583) retail's DB2 names but
-- no extract of ours carries.

local A = {
  { 522972, "522972-ui-encounterjournaltextures.blp" },
  { 522973, "522973-ui-encounterjournaltextures-tile.blp" },
  { 527422, "527422-ui-ej-lorebg-default.blp" },
  { 527690, "527690-ui-ej-bossmodelpaperframe.blp" },
  { 605327, "605327-ui-ej-classic.blp" },
  { 605326, "UI-EJ-BurningCrusade.blp" },
  { 605329, "UI-EJ-WrathoftheLichKing.blp" },
  { 521749, "521749-ui-ej-icons.blp" },
  { 7494373, "7494373-uicombattimelinewarningicons.blp" },   -- modern icons_16x16_* flag sheet
  { 521753, "521753-ui-ej-portraiticon.blp" },
  { 521743, "521743-ui-ej-background-default.blp" },
  { 521744, "521744-ui-ej-boss-default.blp" },
  { 521750, "521750-ui-ej-journalbg.blp" },
  { 521748, "521748-ui-ej-heroictexticon.blp" },
}

-- Per-instance grid-button splash images (JournalInstance.ButtonFileDataID) — the
-- EncounterInstanceButtonTemplate's `bgImage` (BACKGROUND), the dominant visual under the
-- UI-EJ-DungeonButton frame. Confirmed via /neprobe ej (bgImage = ButtonFileDataID, crop
-- texcoord 0,0.6836,0,0.7422). Classic set with descriptive root filenames.
local BTN = {
  { 608196,  "608196-ejbutton-blackrock-depths.blp" },
  { 608197,  "608197-ejbutton-lower-blackrock-spire.blp" },
  { 608202,  "608202-ejbutton-gnomeregan.blp" },
  { 608209,  "608209-ejbutton-maraudon.blp" },
  { 608225,  "608225-ejbutton-uldaman.blp" },
  { 608229,  "608229-ejbutton-wailing-caverns.blp" },
  { 608230,  "608230-ejbutton-zulfarrak.blp" },
  { 1396586, "1396586-ejbutton-molten-core.blp" },
  { 1396580, "1396580-ejbutton-blackwing-lair.blp" },
  { 1396591, "1396591-ejbutton-ruins-of-ahnqiraj.blp" },
  { 1396593, "1396593-ejbutton-temple-of-ahnqiraj.blp" },
  { 608211, "608211-ejbutton-ragefire-chasm.blp" },
  { 522352, "522352-ejbutton-deadmines.blp" },
  { 522358, "522358-ejbutton-shadowfang-keep.blp" },
  { 608195, "608195-ejbutton-blackfathom-deeps.blp" },
  { 608213, "608213-ejbutton-razorfen-kraul.blp" },
  { 608212, "608212-ejbutton-razorfen-downs.blp" },
  { 608223, "608223-ejbutton-stockade.blp" },
  { 608217, "608217-ejbutton-sunken-temple.blp" },
  { 608200, "608200-ejbutton-dire-maul.blp" },
  { 608216, "608216-ejbutton-stratholme.blp" },
  { 608215, "608215-ejbutton-scholomance.blp" },
  { 608214, "608214-ejbutton-scarlet-monastery.blp" },
  -- cross-tier raid seeds (Naxxramas + Onyxia's Lair + Zul'Gurub)
  { 1396587, "1396587-ejbutton-naxxramas.blp" },
  { 1396589, "1396589-ejbutton-onyxias-lair.blp" },
  { 522364,  "522364-ejbutton-zulgurub.blp" },
}

-- The 23 SQUARE (128x128) WotLK instance icons — a different source than the 256x128 widescreen
-- splashes above (dungeon-finder-style art). Retail's widescreen crop over-crops them into a
-- sliver, so EJ.ej.SetButtonTexCoord (below) picks a centred vertical band for these instead.
local SQUARE = {
  { 237592, "237592-ejbutton-ahnkalet.blp" },
  { 237593, "237593-ejbutton-azjolnerub.blp" },
  { 237594, "237594-ejbutton-chamberofaspects.blp" },
  { 237595, "237595-ejbutton-draktharon.blp" },
  { 237596, "237596-ejbutton-gundrak.blp" },
  { 237598, "237598-ejbutton-hallsoflightning.blp" },
  { 237599, "237599-ejbutton-hallsofstone.blp" },
  { 237600, "237600-ejbutton-malygos.blp" },
  { 237601, "237601-ejbutton-oldstratholme.blp" },
  { 237602, "237602-ejbutton-thenexus.blp" },
  { 237603, "237603-ejbutton-theoculus.blp" },
  { 237604, "237604-ejbutton-theviolethold.blp" },
  { 237605, "237605-ejbutton-utgarde.blp" },
  { 237606, "237606-ejbutton-utgardepinnacle.blp" },
  { 303841, "303841-ejbutton-vaultofarchavon.blp" },
  { 304502, "304502-ejbutton-ulduarraid.blp" },
  { 311220, "311220-ejbutton-argentdungeon.blp" },
  { 311221, "311221-ejbutton-argentraid.blp" },
  { 336389, "336389-ejbutton-hallsofreflection.blp" },
  { 336390, "336390-ejbutton-icecrowncitadel.blp" },
  { 336391, "336391-ejbutton-pitofsaron.blp" },
  { 336392, "336392-ejbutton-theforgeofsouls.blp" },
  { 366689, "366689-ejbutton-rubysanctum.blp" },
}

-- DB2 ButtonFileDataIDs (what wotlk_data.lua carries) with no shipped widescreen splash → the
-- matching square icon stands in. These aliases are ALSO square for cropping purposes.
local SQUARE_ALIAS = {
  [608192]  = 237592,   -- Ahn'kahet: The Old Kingdom
  [608204]  = 237598,   -- Halls of Lightning
  [608205]  = 336389,   -- Halls of Reflection
  [608206]  = 237599,   -- Halls of Stone
  [608210]  = 336391,   -- Pit of Saron
  [608221]  = 237602,   -- The Nexus
  [1396583] = 336390,   -- Icecrown Citadel
}

-- Texture preloader. Era streams addon BLPs LAZILY: a texture path set on a frame that
-- isn't streamed-in yet may not finish loading before the journal first paints, and nothing
-- forces a repaint — so grid splashes show up intermittently (the "50/50 blank button" bug,
-- worse the first time a session touches an uncached BLP). We warm the cache at addon load by
-- binding every EJ BLP to a resident texture on a shown (but invisible, off-screen 1px)
-- holder, keeping the files streamed-in and ready by the time the grid/lore/model render.
EJ.ej = EJ.ej or {}
local preloadHolder, preloaded = nil, {}
function EJ.ej.Preload(path)
  if not path or preloaded[path] then return end
  preloaded[path] = true
  if not preloadHolder then
    preloadHolder = CreateFrame("Frame", "EJ_EJArtPreload", UIParent)
    preloadHolder:SetSize(1, 1)
    preloadHolder:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -10, 10)   -- off-screen
    preloadHolder:SetAlpha(0); preloadHolder:Show()                   -- shown ⇒ textures stream
    preloadHolder.tex = {}
  end
  local t = preloadHolder:CreateTexture(nil, "BACKGROUND")
  t:SetAllPoints(preloadHolder); t:SetTexture(path)
  preloadHolder.tex[#preloadHolder.tex + 1] = t
end

local _P = "Interface\\AddOns\\EncounterJournal\\Art\\EncounterJournal\\"
for _, e in ipairs(A) do
  EJ.tex.RegisterLocal(e[1], _P .. e[2]); EJ.ej.Preload(_P .. e[2])
end
for _, e in ipairs(BTN) do
  EJ.tex.RegisterLocal(e[1], _P .. e[2]); EJ.ej.Preload(_P .. e[2])
end

-- Square icons + the DB2-id aliases onto them. The set is exported so the grid can pick the crop.
EJ.ej.SQUARE_BUTTON_FDID = {}
local squarePath = {}
for _, e in ipairs(SQUARE) do
  EJ.tex.RegisterLocal(e[1], _P .. e[2]); EJ.ej.Preload(_P .. e[2])
  EJ.ej.SQUARE_BUTTON_FDID[e[1]] = true
  squarePath[e[1]] = _P .. e[2]
end
for dbid, sq in pairs(SQUARE_ALIAS) do
  if squarePath[sq] and not EJ.tex.localFiles[dbid] then
    EJ.tex.RegisterLocal(dbid, squarePath[sq])
    EJ.ej.SQUARE_BUTTON_FDID[dbid] = true
  end
end

-- Apply the right TexCoord for an instance-button splash given its FDID: retail's widescreen crop
-- for the 256x128 art, a centred "cover" band for the square icons (so a 174x96 target isn't
-- stretched), and the full texture when a square source lands in a square target (the 40x40
-- back-button portrait).
function EJ.ej.SetButtonTexCoord(tex, fdid, targetIsSquare)
  if fdid and EJ.ej.SQUARE_BUTTON_FDID[fdid] then
    if targetIsSquare then tex:SetTexCoord(0, 1, 0, 1)
    else tex:SetTexCoord(0, 1, 0.2241379, 0.7758621) end
  else
    tex:SetTexCoord(0, 0.68359375, 0, 0.7421875)
  end
end

-- Per-instance model-tab backdrops (JournalInstance.BGFileDataID) — the ModelScene
-- `dungeonBG` (probe: 512x512 file, shown 394x425 via flipped crop 0.7695,0,0,0.8301).
-- Complete set across Classic + TBC + WotLK (every BLP under Backdrops\). Unshipped FDIDs →
-- neutral default (see the deferred art fallback at the bottom of this file).
for _, fd in ipairs({
                      522336, 522342, 522347, 522348, 608153, 608154, 608155, 608156, 608157, 608158, 608159, 608160,
                      608161, 608162, 608163, 608164, 608165, 608166, 608167, 608168, 608169, 608170, 608171, 608172,
                      608173, 608174, 608175, 608176, 608177, 608178, 608179, 608180, 608181, 608182, 608183, 608184,
                      608185, 608186, 608187, 608188, 608189, 608190, 608191, 1396453, 1396454, 1396455, 1396456, 1396457,
                      1396458, 1396459, 1396460, 1396461, 1396462, 1396463, 1396464, 1396465, 1396466, 1396467, 1396468, 1396469,
                      1396470,
}) do
  local path = _P .. "Backdrops\\" .. fd .. ".blp"
  EJ.tex.RegisterLocal(fd, path); EJ.ej.Preload(path)
end

-- Per-instance lore-panel backgrounds (JournalInstance.LoreFileDataID) — the splash artwork
-- behind the instance description on the dungeon landing page (EncounterPage loreBG). Shipped
-- local under Lore\; register + preload so the landing art is warm. Complete set (every BLP
-- under Lore\).
for _, fd in ipairs({
                      526404, 526410, 526415, 526416, 608231, 608232, 608233, 608234, 608235, 608236, 608237, 608238,
                      608239, 608240, 608241, 608242, 608243, 608244, 608245, 608246, 608247, 608248, 608249, 608250,
                      608251, 608252, 608253, 608254, 608255, 608256, 608257, 608258, 608259, 608260, 608261, 608262,
                      608263, 608264, 608265, 608266, 608267, 608312, 608313, 1396498, 1396499, 1396500, 1396501, 1396502,
                      1396503, 1396504, 1396505, 1396506, 1396507, 1396508, 1396509, 1396510, 1396511, 1396512, 1396513, 1396514,
                      1396515,
}) do
  local path = _P .. "Lore\\" .. fd .. ".blp"
  EJ.tex.RegisterLocal(fd, path); EJ.ej.Preload(path)
end

-- Per-instance grid-button splashes for TBC + WotLK instances (JournalInstance.ButtonFileDataID).
-- Unlike the Classic BTN table (descriptive root filenames), these come from named
-- UI-EJ-DUNGEONBUTTON-<Instance> BLPs and ship as Buttons\<fdid>.blp (BTN-table FDIDs excluded).
-- Registering here makes the real art WIN over the neutral default the art fallback below sets.
for _, fd in ipairs({ 608193, 608194, 608198, 608199, 608201, 608203, 608207, 608208, 608218,
                      608219, 608220, 608222, 608224, 608226, 608227, 608228,
                      1396579, 1396581, 1396582, 1396584, 1396585, 1396588,
                      1396590, 1396592, 1396594, 1396595, 1396596 }) do
  local path = _P .. "Buttons\\" .. fd .. ".blp"
  EJ.tex.RegisterLocal(fd, path); EJ.ej.Preload(path)
end

-- Per-boss portrait plates (JournalEncounterCreature.FileDataID → encounter.creature.file).
-- The encounter-page boss button draws this; a raw unshipped FDID renders RED. Complete set
-- (every BLP under Bosses\ — 419 plates across all three tiers).
-- NO Preload here (400+ portraits resident at login = wasteful) — registration alone resolves
-- the path; the plate streams in when its boss page opens. Bosses with no shipped art fall to
-- the generic plate 521744 via the deferred art fallback at the bottom of this file.
for _, fd in ipairs({
                      69420, 522189, 522190, 522205, 522206, 522209, 522210, 522213, 522214, 522217, 522225, 522228,
                      522230, 522231, 522233, 522234, 522235, 522236, 522238, 522242, 522243, 522247, 522249, 522251,
                      522254, 522261, 522263, 522278, 522279, 522280, 607529, 607531, 607532, 607533, 607534, 607535,
                      607536, 607537, 607538, 607540, 607541, 607542, 607544, 607546, 607547, 607548, 607549, 607550,
                      607551, 607553, 607555, 607556, 607558, 607559, 607560, 607561, 607562, 607563, 607564, 607565,
                      607566, 607567, 607568, 607569, 607570, 607571, 607572, 607573, 607574, 607575, 607582, 607583, 607584, 607585,
                      607587, 607589, 607590, 607591, 607592, 607593, 607594, 607595, 607596, 607597, 607600, 607601,
                      607602, 607603, 607605, 607606, 607610, 607611, 607614, 607615, 607618, 607620, 607621, 607622,
                      607623, 607624, 607625, 607626, 607628, 607629, 607630, 607631, 607633, 607634, 607635, 607637,
                      607639, 607641, 607643, 607644, 607645, 607647, 607649, 607650, 607651, 607652, 607653, 607654,
                      607655, 607656, 607657, 607658, 607659, 607660, 607663, 607664, 607665, 607666, 607667, 607669,
                      607670, 607671, 607672, 607673, 607674, 607676, 607678, 607679, 607680, 607683, 607684, 607685,
                      607686, 607687, 607688, 607689, 607690, 607692, 607693, 607694, 607695, 607696, 607697, 607698,
                      607699, 607702, 607703, 607705, 607706, 607707, 607708, 607710, 607711, 607712, 607713, 607714,
                      607715, 607716, 607717, 607718, 607719, 607720, 607721, 607723, 607724, 607725, 607726, 607727,
                      607728, 607729, 607734, 607735, 607736, 607737, 607738, 607739, 607740, 607741, 607742, 607743,
                      607744, 607745, 607747, 607749, 607750, 607751, 607752, 607753, 607755, 607756, 607757, 607759,
                      607760, 607761, 607763, 607765, 607767, 607768, 607769, 607771, 607772, 607773, 607774, 607775,
                      607776, 607777, 607778, 607779, 607780, 607782, 607784, 607785, 607787, 607788, 607789, 607790,
                      607791, 607792, 607793, 607794, 607795, 607796, 607797, 607798, 607801, 607802, 607803, 607805,
                      607806, 607808, 607809, 607810, 607811, 607812, 607814, 607815, 607816, 607817, 607818, 607819,
                      607820, 607821, 607822, 607823, 607824, 607825, 608309, 608310, 608311, 608314, 608315, 630818,
                      630835, 630838, 630853, 1064175, 1064178, 1064179, 1064180, 1064181, 1064182, 1064183, 1064184, 1378964,
                      1378965, 1378966, 1378967, 1378968, 1378969, 1378970, 1378971, 1378972, 1378973, 1378974, 1378975, 1378976,
                      1378977, 1378978, 1378979, 1378980, 1378981, 1378982, 1378983, 1378984, 1378985, 1378986, 1378987, 1378988,
                      1378989, 1378990, 1378991, 1378992, 1378993, 1378994, 1378995, 1378996, 1378997, 1378998, 1378999, 1379000,
                      1379001, 1379002, 1379004, 1379005, 1379006, 1379007, 1379008, 1379009, 1379010, 1379011, 1379012, 1379013,
                      1379014, 1379015, 1379016, 1379017, 1379018, 1379019, 1379020, 1379021, 1379022, 1379023, 1379025, 1385712,
                      1385713, 1385714, 1385715, 1385716, 1385717, 1385718, 1385719, 1385720, 1385721, 1385722, 1385723, 1385724,
                      1385725, 1385726, 1385727, 1385728, 1385729, 1385730, 1385731, 1385732, 1385733, 1385734, 1385735, 1385736,
                      1385737, 1385738, 1385739, 1385740, 1385741, 1385742, 1385743, 1385744, 1385745, 1385746, 1385747, 1385748,
                      1385749, 1385750, 1385751, 1385752, 1385753, 1385754, 1385755, 1385756, 1385757, 1385758, 1385759, 1385760,
                      1385761, 1385762, 1385763, 1385764, 1385765, 1385766, 1385767, 1385768, 1385769, 1385770, 1385771, 1385772,
                      1385773, 1385774, 1390436, 1390437, 1390438, 1390439, 1390440, 1390441, 1390442, 1390443, 4776138, 5875505, 5875506, 5875507,
                      5875508, 5875509, 5875510, 5875511, 5875512, 7524258, 7526001,
}) do
  EJ.tex.RegisterLocal(fd, _P .. "Bosses\\" .. fd .. ".blp")
end

-- ===== CHROME SLICES (was Slices.lua) =====

-- Texcoord slice table for the legacy journal
-- chrome sheets, transcribed VERBATIM from retail Cata
-- Blizzard_EncounterJournal.xml:4-317 (build 12.0.5.67451). These are the virtual
-- <Texture> slices the journal carves out of the two master BLPs (shipped local above via
-- Assets.lua). NOT modern atlas members — they're not in Generated/AtlasData.lua, so we
-- carry their texcoords ourselves.
--
--   fdid 522972 = UI-EncounterJournalTextures        (master sheet, 512x1024)
--   fdid 522973 = UI-EncounterJournalTextures_Tile   (h-tiled mid-pieces, 64x512)
--
-- Each entry: { fdid, w, h, l, r, t, b }. l/r/t/b are the LITERAL left/right/top/bottom
-- attribute values from the XML — several are intentionally flipped (top>bottom for a
-- vertical flip; left>right for a horizontal flip, e.g. RightPageHeader). Preserve as-is;
-- SetTexCoord(l, r, t, b) reproduces the flip.

local M, T = 522972, 522973

EJ.ej.SLICES = {
  -- _Tile sheet (522973) — horizontally tiled mid-pieces
  ["_FilterButtonUp-Mid"]          = { T, 64, 26, 0, 1, 0.00195313, 0.05273438 },
  ["_FilterButtonDown-Mid"]        = { T, 64, 26, 0, 1, 0.05664063, 0.10742188 },
  ["_FilterButtonHighlight-Mid"]   = { T, 64, 26, 0, 1, 0.11132813, 0.16210938 },
  ["_PaperHeader-UnSelectDown-Mid"]= { T, 64, 29, 0, 1, 0.28320313, 0.33984375 },
  ["_PaperHeader-UnSelectUp-Mid"]  = { T, 64, 29, 0, 1, 0.34375000, 0.40039063 },
  ["_PaperHeader-SelectDown-Mid"]  = { T, 64, 29, 0, 1, 0.40429688, 0.46093750 },
  ["_PaperHeader-Highlight-Mid"]   = { T, 64, 29, 0, 1, 0.46484375, 0.52148438 },
  ["_DungeonGridTab-MidHighlight"] = { T, 64, 36, 0, 1, 0.59570313, 0.52539063 },
  ["_DungeonGridTab-MidSelect"]    = { T, 64, 36, 0, 1, 0.66992188, 0.59960938 },
  ["_DungeonGridTab-Mid"]          = { T, 64, 36, 0, 1, 0.74414063, 0.67382813 },

  -- Master sheet (522972)
  ["UI-EJ-AbilityIconBorder"]            = { M, 20, 20, 0.00195313, 0.04101563, 0.00097656, 0.02050781 },
  -- description parchment box + bottom border (SharedUIPanelTemplates.xml; same master sheet)
  ["UI-PaperOverlay-AbilityTextBG"]         = { M, 256, 80, 0.00195313, 0.50195313, 0.02246094, 0.10058594 },
  ["UI-PaperOverlay-AbilityTextBottomBorder"] = { M, 243, 9, 0.04492188, 0.51953125, 0.00097656, 0.00976563 },
  ["UI-EJ-DungeonGridTab-SelectedGlow"]  = { M, 64, 15, 0.52343750, 0.64843750, 0.01562500, 0.00097656 },
  ["UI-EJ-DungeonGridTab-Shadow"]        = { M, 128, 15, 0.65234375, 0.90234375, 0.00097656, 0.01562500 },
  ["UI-EJ-ReturnToDefault"]              = { M, 21, 20, 0.90625000, 0.94726563, 0.00097656, 0.02050781 },
  ["UI-EJ-BossModelButton"]              = { M, 64, 61, 0.50585938, 0.63085938, 0.02246094, 0.08203125 },
  ["UI-EJ-CreatureHeaderFrameSm-bg"]     = { M, 45, 44, 0.63476563, 0.72265625, 0.02246094, 0.06542969 },
  ["UI-EJ-FilterButtonDown"]             = { M, 26, 26, 0.63476563, 0.68554688, 0.06738281, 0.09277344 },
  ["UI-EJ-CreatureHeaderFrameSm"]        = { M, 45, 44, 0.72656250, 0.81445313, 0.02246094, 0.06542969 },
  ["UI-EJ-FilterButtonHighlight"]        = { M, 26, 26, 0.72656250, 0.77734375, 0.06738281, 0.09277344 },
  ["UI-EJ-DungeonGridTab-Left"]          = { M, 12, 36, 0.81835938, 0.84179688, 0.05761719, 0.02246094 },
  ["UI-EJ-DungeonGridTab-LeftHighlight"] = { M, 12, 36, 0.81835938, 0.84179688, 0.09472656, 0.05957031 },
  ["UI-EJ-DungeonGridTab-LeftSelect"]    = { M, 12, 36, 0.84570313, 0.86914063, 0.05761719, 0.02246094 },
  ["UI-EJ-DungeonGridTab-Right"]         = { M, 12, 36, 0.84570313, 0.86914063, 0.09472656, 0.05957031 },
  ["UI-EJ-DungeonGridTab-RightHighlight"]= { M, 12, 36, 0.87304688, 0.89648438, 0.05761719, 0.02246094 },
  ["UI-EJ-DungeonGridTab-RightSelect"]   = { M, 12, 36, 0.87304688, 0.89648438, 0.09472656, 0.05957031 },
  ["UI-EJ-FilterButtonSelect"]           = { M, 26, 26, 0.90039063, 0.95117188, 0.02246094, 0.04785156 },
  ["UI-EJ-SearchIconFrameSm"]            = { M, 22, 22, 0.95507813, 0.99804688, 0.02246094, 0.04394531 },
  ["UI-EJ-FilterButtonUp"]               = { M, 26, 26, 0.90039063, 0.95117188, 0.04980469, 0.07519531 },
  ["UI-EJ-BossButton-Down"]              = { M, 325, 55, 0.00195313, 0.63671875, 0.10253906, 0.15625000 },
  ["UI-EJ-MapButtonSm-Down"]             = { M, 50, 50, 0.64062500, 0.73828125, 0.10253906, 0.15136719 },
  ["UI-EJ-MapButtonSm-Highlight"]        = { M, 50, 50, 0.74218750, 0.83984375, 0.10253906, 0.15136719 },
  ["UI-EJ-MapButtonSm-Selection"]        = { M, 50, 50, 0.84375000, 0.94140625, 0.10253906, 0.15136719 },
  ["UI-EJ-BossButton-Highlight"]         = { M, 325, 55, 0.00195313, 0.63671875, 0.15820313, 0.21191406 },
  ["UI-EJ-MapButtonSm-Up"]               = { M, 50, 50, 0.64062500, 0.73828125, 0.15820313, 0.20703125 },
  ["UI-EJ-PaperHeader-Highlight-Left"]   = { M, 64, 29, 0.74218750, 0.86718750, 0.15820313, 0.18652344 },
  ["UI-EJ-PaperHeader-Highlight-Right"]  = { M, 64, 29, 0.87109375, 0.99609375, 0.15820313, 0.18652344 },
  ["UI-EJ-BossButton-Up"]                = { M, 325, 55, 0.00195313, 0.63671875, 0.21386719, 0.26757813 },
  ["UI-EJ-PaperHeader-SelectDown-Left"]  = { M, 64, 29, 0.64062500, 0.76562500, 0.21386719, 0.24218750 },
  ["UI-EJ-PaperHeader-SelectDown-Right"] = { M, 64, 29, 0.76953125, 0.89453125, 0.21386719, 0.24218750 },
  ["UI-EJ-BossNameShadow"]               = { M, 395, 63, 0.00195313, 0.77343750, 0.26953125, 0.33105469 },
  ["UI-EJ-MapButtonLg-Down"]             = { M, 62, 61, 0.77734375, 0.89843750, 0.26953125, 0.32910156 },
  ["UI-EJ-Tab-BossIcon-Selected"]        = { M, 48, 43, 0.90234375, 0.99609375, 0.26953125, 0.31152344 },
  ["UI-EJ-DungeonButton-Down"]           = { M, 174, 96, 0.00195313, 0.34179688, 0.33300781, 0.42675781 },
  ["UI-EJ-DungeonButton-Highlight"]      = { M, 174, 96, 0.34570313, 0.68554688, 0.33300781, 0.42675781 },
  ["UI-EJ-MapButtonLg-Highlight"]        = { M, 62, 61, 0.68945313, 0.81054688, 0.33300781, 0.39257813 },
  ["UI-EJ-MapButtonLg-Select"]           = { M, 62, 61, 0.81445313, 0.93554688, 0.33300781, 0.39257813 },
  ["UI-EJ-DungeonButton-Up"]             = { M, 174, 96, 0.00195313, 0.34179688, 0.42871094, 0.52246094 },
  ["UI-EJ-DungeonNameBg"]                = { M, 256, 64, 0.34570313, 0.84570313, 0.42871094, 0.49121094 },
  ["UI-EJ-PaperHeader-SelectUp-Right"]   = { M, 64, 29, 0.34570313, 0.47070313, 0.49316406, 0.52148438 },
  ["UI-EJ-PaperHeader-UnSelectDown-Left"]= { M, 64, 29, 0.47460938, 0.59960938, 0.49316406, 0.52148438 },
  ["UI-EJ-PaperHeader-UnSelectDown-Right"]={ M, 64, 29, 0.60351563, 0.72851563, 0.49316406, 0.52148438 },
  ["UI-EJ-MapButtonLg-Up"]               = { M, 62, 61, 0.84960938, 0.97070313, 0.42871094, 0.48828125 },
  ["UI-EJ-PaperHeader-UnSelectUp-Left"]  = { M, 64, 29, 0.84960938, 0.97460938, 0.49023438, 0.51855469 },
  ["UI-EJ-DungeonLootFrame"]             = { M, 369, 64, 0.00195313, 0.72265625, 0.52441406, 0.58691406 },
  ["UI-EJ-PaperHeader-UnSelectUp-Right"] = { M, 64, 29, 0.72656250, 0.85156250, 0.52441406, 0.55273438 },
  ["UI-EJ-Tab-BossIcon-UnSelected"]      = { M, 48, 43, 0.85546875, 0.94921875, 0.52441406, 0.56640625 },
  ["UI-EJ-FilterBar"]                    = { M, 320, 28, 0.00195313, 0.62695313, 0.58886719, 0.61621094 },
  ["UI-EJ-SearchBarHighlightSm"]         = { M, 128, 27, 0.63085938, 0.88085938, 0.58886719, 0.61523438 },
  ["UI-EJ-LootFrame"]                    = { M, 321, 45, 0.00195313, 0.62890625, 0.61816406, 0.66210938 },
  ["UI-EJ-Tab-LootIcon-Selected"]        = { M, 48, 43, 0.63281250, 0.72656250, 0.61816406, 0.66015625 },
  ["UI-EJ-Tab-LootIcon-UnSelected"]      = { M, 48, 43, 0.73046875, 0.82421875, 0.61816406, 0.66015625 },
  ["UI-EJ-LoreTextCover-Bottom"]         = { M, 386, 29, 0.00195313, 0.75585938, 0.66406250, 0.69238281 },
  ["UI-EJ-LoreTextCover-Top"]            = { M, 386, 32, 0.00195313, 0.75585938, 0.69433594, 0.72558594 },
  ["UI-EJ-MainTextCover-Bottom"]         = { M, 386, 43, 0.00195313, 0.75585938, 0.72753906, 0.76953125 },
  ["UI-EJ-MainTextCover-Top"]            = { M, 386, 13, 0.00195313, 0.75585938, 0.77148438, 0.78417969 },
  ["UI-EJ-MoreTextBelowHighlight"]       = { M, 259, 17, 0.00195313, 0.50781250, 0.78613281, 0.80273438 },
  ["UI-EJ-SearchBarHighlightLg"]         = { M, 256, 47, 0.00195313, 0.50195313, 0.80468750, 0.85058594 },
  ["UI-EJ-ShowMapBG"]                    = { M, 171, 50, 0.00195313, 0.33593750, 0.85253906, 0.90136719 },
  ["UI-EJ-Tab-Highlight"]                = { M, 63, 57, 0.00195313, 0.12500000, 0.90332031, 0.95898438 },
  ["UI-EJ-Tab-Selected"]                 = { M, 63, 57, 0.12890625, 0.25195313, 0.90332031, 0.95898438 },
  ["UI-EJ-Tab-UnSelected"]               = { M, 63, 57, 0.25585938, 0.37890625, 0.90332031, 0.95898438 },
  ["UI-EJ-Tab-ModelIcon-Selected"]       = { M, 48, 43, 0.80468750, 0.90039063, 0.66210938, 0.70507813 },
  ["UI-EJ-Tab-ModelIcon-UnSelected"]     = { M, 48, 43, 0.90234375, 1.00000000, 0.66210938, 0.70507813 },
  ["UI-EJ-LeftPageHeader"]               = { M, 386, 39, 0.00000000, 0.75585938, 0.95996094, 1.00000000 },
  ["UI-EJ-RightPageHeader"]              = { M, 386, 39, 0.75585938, 0.00000000, 0.95996094, 1.00000000 },
  ["UI-EJ-Tab-AbilitiesIcon-Selected"]   = { M, 48, 43, 0.80664063, 0.89843750, 0.70703125, 0.74804688 },
  ["UI-EJ-Tab-AbilitiesIcon-UnSelected"] = { M, 48, 43, 0.90429688, 0.99609375, 0.70703125, 0.74804688 },
  ["UI-EJ-Header-Overview"]              = { M, 327, 30, 0.35937500, 0.99609375, 0.85253906, 0.88085938 },
}

-- Apply a slice to a Texture: bind the LOCAL sheet BLP (same-FDID-≠-same-art) + texcoords,
-- optionally size to the slice's native dimensions.
function EJ.ej.ApplySlice(tex, name, setSize)
  local s = EJ.ej.SLICES[name]
  if not s then return false end
  tex:SetTexture(EJ.tex.localFiles[s[1]] or s[1])
  tex:SetTexCoord(s[4], s[5], s[6], s[7])
  if setSize then tex:SetSize(s[2], s[3]) end
  return true
end

-- ===== BOSSESGEN PORTRAIT OVERRIDES (was the tail of vanilla_data.lua) =====

-- Wires the LOCALLY-GENERATED boss portraits
-- (the cmangos standin bosses that retail never gave an EJ portrait) into the journal WITHOUT
-- editing the auto-generated Data.lua. Generated by the /ne ejportrait capture pipeline (see
-- memory project_ej_boss_portraits): each model rendered on magenta, cut to a 128x64 BLP keyed
-- by its creatureDisplayID, shipped under Art/EncounterJournal/BossesGen/<displayID>.blp.
--
-- Mechanism: register each generated BLP under a local key == its displayID, then patch
-- EJ.ej.DATA so every standin creature with a generated portrait resolves `file` to that key
-- (EncounterPage reads `EJ.tex.localFiles[cr.file] or cr.file`). Survives a vanilla_data.lua re-gen
-- because it is an overlay: the BLPs are registered here at load, the DATA patch runs from the
-- PLAYER_LOGIN pass below (applyPortraitOverrides). Grows as more
-- batches (the wide/beast set) are generated — just add the displayIDs.

-- displayIDs with a shipped BossesGen/<id>.blp.
local GEN = {
  -- humanoid batch (43)
  517, 1621, 2040, 2041, 2042, 2043, 2044, 2149, 2353, 2605, 2606, 3222, 3223, 3250, 4642,
  4939, 5266, 6097, 6110, 6124, 7970, 8055, 10248, 10901, 11069, 11070, 11072, 11073, 11288,
  11311, 11382, 11396, 11429, 11492, 11835, 15216, 15217, 15218, 15219, 15220, 15267, 15268, 15269,
  -- wide/beast batch (26) — first pass; some beasts pending per-model head tuning
  522, 524, 825, 1773, 1816, 2007, 2142, 2352, 2450, 2837, 4644, 4652, 4979, 5027, 7534, 7845,
  7864, 7919, 7971, 8390, 10433, 11179, 11611, 12073, 15288, 15295,
}

local GEN_P = _P .. "BossesGen\\"
local have = {}
for _, did in ipairs(GEN) do
  local path = GEN_P .. did .. ".blp"
  if EJ.tex and EJ.tex.RegisterLocal then EJ.tex.RegisterLocal(did, path) end
  if EJ.ej.Preload then EJ.ej.Preload(path) end
  have[did] = true
end

-- Patch the seeded data: point each standin creature at its generated portrait. Assets.lua loads
-- BEFORE the *_data.lua files, so this runs from the deferred PLAYER_LOGIN pass below (ahead of
-- the neutral plate fallback); the BLP registration above happens at load like everything else.
local function applyPortraitOverrides()
  local data = EJ.ej.DATA
  if not data then return end
  for _, inst in ipairs(data.instances or {}) do
    for _, enc in ipairs(inst.encounters or {}) do
      local cr = enc.creatures and enc.creatures[1]
      if cr and cr.display and have[cr.display] and (cr.file == 521744 or not cr.file) then
        cr.file = cr.display
      end
    end
  end
end

-- Neutral art fallback (folded in from the former art_fallback.lua). A raw retail FDID with no
-- shipped BLP renders SOLID RED on 3.3.5a; this points any instance bg/button/lore + boss
-- creature.file FDID that nothing above registered at a shipped neutral default. It must run
-- AFTER every *_data.lua has populated EJ.ej.DATA — but Assets.lua loads BEFORE them, so the
-- pass is DEFERRED to PLAYER_LOGIN (all addon files have executed by then; the journal isn't
-- built until the user opens it, well after login). Real art always wins via the localFiles guard.
local PH_BG   = _P .. "521743-ui-ej-background-default.blp"  -- model-tab backdrop default
local PH_BTN  = _P .. "605327-ui-ej-classic.blp"             -- grid splash default (tier bg)
local PH_LRE  = _P .. "527422-ui-ej-lorebg-default.blp"      -- lore-panel default
local PH_BOSS = _P .. "521744-ui-ej-boss-default.blp"        -- generic boss portrait plate
local function ph(fd, path)
  if fd and fd > 0 and not EJ.tex.localFiles[fd] then EJ.tex.RegisterLocal(fd, path) end
end
local fbWatcher = CreateFrame("Frame")
fbWatcher:RegisterEvent("PLAYER_LOGIN")
fbWatcher:SetScript("OnEvent", function(self)
  self:UnregisterAllEvents()
  if not (EJ.ej.DATA and EJ.ej.DATA.instances) then return end
  applyPortraitOverrides()   -- BossesGen plates first, so a generated portrait never loses to the neutral plate
  for _, inst in ipairs(EJ.ej.DATA.instances) do
    ph(inst.bgFDID, PH_BG); ph(inst.buttonFDID, PH_BTN); ph(inst.loreFDID, PH_LRE)
    for _, enc in ipairs(inst.encounters or {}) do
      for _, cr in ipairs(enc.creatures or {}) do ph(cr.file, PH_BOSS) end
    end
  end
end)
