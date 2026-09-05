-- Core/Compat.lua — gap-filler shims on top of !!!ClassicAPI (a HARD dependency).
--
-- The heavy lifting of emulating the modern/Era API on 3.3.5a is done by Tsoukie's
-- !!!ClassicAPI library, which EncounterJournal depends on (see the TOC). ClassicAPI already
-- provides: C_Timer (After/NewTimer/NewTicker), GetPhysicalScreenSize, working
-- texture:SetAtlas + C_Texture atlas data, NineSlice, SearchBoxTemplate, C_Item
-- (RequestLoadItemDataByID), C_Map.GetPlayerMapPosition, C_AddOns, and a base SOUNDKIT table.
--
-- This file only patches the handful of things the ported journal references that ClassicAPI
-- does NOT cover. Loaded first in our TOC, after ClassicAPI has fully loaded (dependency order),
-- so we ADD to its tables rather than create them. Every shim is define-if-absent.

-- ---------------------------------------------------------------------------------------
-- SOUNDKIT — ClassicAPI seeds a base table but omits the character-panel OPEN/CLOSE kits the
-- journal's WirePanelSounds uses (it has only IG_CHARACTER_INFO_TAB). Add them without
-- clobbering ClassicAPI's entries. 3.3.5 PlaySound takes these string names directly.
-- ---------------------------------------------------------------------------------------
SOUNDKIT = SOUNDKIT or {}
SOUNDKIT.IG_CHARACTER_INFO_OPEN  = SOUNDKIT.IG_CHARACTER_INFO_OPEN  or "igCharacterInfoOpen"
SOUNDKIT.IG_CHARACTER_INFO_CLOSE = SOUNDKIT.IG_CHARACTER_INFO_CLOSE or "igCharacterInfoClose"

-- ---------------------------------------------------------------------------------------
-- PortraitFrameTemplate metal chrome — the REAL retail art. (Was Core/Atlas335.lua, which
-- aliased the UI-Frame-Metal-* names onto ClassicAPI's DiamondMetal look-alike; we now ship the
-- actual retail pieces and register them against the real texcoords.)
--
-- ClassicAPI's NineSlice "PortraitFrameTemplate" layout (Util/NineSlice.lua:38-47) references the
-- UI-Frame-Metal-* atlas family but its AtlasInfo only registers UI-Frame-DiamondMetal-* (a
-- diamond-studded 32px look-alike) — so without help the metal layout draws nothing, and the
-- PortraitMetal-CornerTopLeft (the round portrait ring) was never registered at all (→ the
-- portrait showed as a bare square). We register every piece from the shipped retail sheets in
-- Art/Frame/ with texcoords transcribed from UiTextureAtlasMember.12.1.0.68301.csv (kept under
-- References/ — dev-only, not part of the shipped addon). ClassicAPI's nineslice then draws the
-- genuine retail metal frame.
--
-- SHEETS (retail UiTextureAtlasID → file, all under Art/Frame/):
--   1390 corners  → uiframemetal2x.blp            512×512 BGRA
--   1395 top/bot  → uiframemetalhorizontal2x.blp   64×256 BGRA   (_ = horiz-tile)
--   1394 sides    → uiframemetalvertical2x.blp     512×32 BGRA   (! = vert-tile, art is UPRIGHT)
--   950  streaks  → uiframehorizontal.blp          256×128 DXT
-- Runs at load, after ClassicAPI populated AtlasData.
-- ---------------------------------------------------------------------------------------
local AtlasData = C_Texture and C_Texture.AtlasData

-- PortraitFrameTemplate metal nineslice (ClassicAPI Util/NineSlice.lua:38-47).
-- CORNERS: real retail art shipped as Art/Frame/uiframemetal2x.blp (512×512, retail atlas 1390).
-- Texcoords from UiTextureAtlasMember.12.1.0.68301.csv (pixel coords ÷512); render W/H = the 1x
-- size (150px source → 75, 64px source → 32). This gives the smooth metal corners AND the round
-- PortraitMetal-CornerTopLeft ring around the portrait (which ClassicAPI never registered → the
-- top-left was bare before). EDGES + TopTileStreaks live on SEPARATE retail sheets (atlas 1394 /
-- 1395 / 950) not yet shipped, so they stay aliased to DiamondMetal for now.
local FRAME = "Interface\\AddOns\\EncounterJournal\\Art\\Frame\\"
-- Register a real-art atlas slice. (w,h)=1x render size; (L,R,T,B)=pixel coords on the sheet of
-- (sw,sh); tileH/tileV per the _/! prefix. ClassicAPI's nineslice SetAtlas(name,true) sizes the
-- piece to (w,h) and reads these tile flags (Util/NineSlice.lua:254-258).
local function regAt(name, sheet, w, h, L, R, T, B, sw, sh, tileH, tileV)
  if AtlasData and C_Texture.RegisterAtlas and not AtlasData[name] then
    C_Texture.RegisterAtlas(name, { w, h, L/sw, R/sw, T/sh, B/sh, tileH or false, tileV or false }, FRAME .. sheet, true)
  end
end

-- CORNERS — retail atlas 1390 sheet (uiframemetal2x.blp, 512×512). 150px source → 75 render,
-- 64px → 32. The PortraitMetal-CornerTopLeft is the round portrait ring ClassicAPI never had.
regAt("UI-Frame-PortraitMetal-CornerTopLeft", "uiframemetal2x.blp", 75, 75,   1, 151, 153, 303, 512, 512)
regAt("UI-Frame-Metal-CornerTopLeft",         "uiframemetal2x.blp", 75, 75,   1, 151,   1, 151, 512, 512)
regAt("UI-Frame-Metal-CornerTopRight",        "uiframemetal2x.blp", 75, 75, 153, 303,   1, 151, 512, 512)
regAt("UI-Frame-Metal-CornerBottomLeft",      "uiframemetal2x.blp", 32, 32, 153, 217, 153, 217, 512, 512)
regAt("UI-Frame-Metal-CornerBottomRight",     "uiframemetal2x.blp", 32, 32, 219, 283, 153, 217, 512, 512)

-- TOP/BOTTOM edges — retail atlas 1395 (uiframemetalhorizontal2x.blp, 64×256), `_` = horiz-tile.
-- H = band thickness (75 top to match the corners, 32 bottom); stretched between corners, tiled.
regAt("_UI-Frame-Metal-EdgeTop",    "uiframemetalhorizontal2x.blp", 32, 75, 0, 64,   1, 151, 64, 256, true, false)
regAt("_UI-Frame-Metal-EdgeBottom", "uiframemetalhorizontal2x.blp", 16, 32, 0, 32, 153, 217, 64, 256, true, false)

-- SIDE edges — retail atlas 1394 (uiframemetalvertical2x.blp, 512×32), `!` = vert-tile. The art
-- is stored UPRIGHT (thin vertical metal strips that tile down the side, NOT rotated — confirmed
-- by converting the sheet to PNG). W = band width (75, matching the corners), H = tile unit (16).
regAt("!UI-Frame-Metal-EdgeLeft",  "uiframemetalvertical2x.blp", 75, 16,   1, 151, 0, 32, 512, 32, false, true)
regAt("!UI-Frame-Metal-EdgeRight", "uiframemetalvertical2x.blp", 75, 16, 153, 303, 0, 32, 512, 32, false, true)

-- TopTileStreaks decorative band under the title (atlas 950, uiframehorizontal.blp 256×128, 1x).
-- Not a nineslice piece — the window's buildChrome SetAtlas("_UI-Frame-TopTileStreaks") finds it.
regAt("_UI-Frame-TopTileStreaks", "uiframehorizontal.blp", 256, 43, 0, 256, 1, 44, 256, 128, true, false)
