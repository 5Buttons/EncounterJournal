-- Core/AtlasData.lua — retail atlas COORDS + shipped-sheet registration for the modern chrome
-- pieces !!!ClassicAPI does NOT carry: the Dragonflight metal panel tabs, the RedButton close
-- button, the MinimalScrollBar family, the InsetFrameTemplate inner trim and the retail
-- UI-Background-Rock body fill.
--
-- Core/Texture.lua's EJ.tex.SetAtlas consults the global EJ_ATLAS table FIRST (lowercase atlas
-- name → { file=<FDID>, left, right, top, bottom, width, height }) and only then falls through to
-- ClassicAPI's C_Texture registry. Until this file existed EJ_ATLAS was nil in the standalone port,
-- so every one of these atlases silently missed and the chrome fell back to the classic 3.3.5 art
-- (wooden tabs, round X, stock scrollbar). The coordinates are transcribed from
-- DragonUI_NewEra/core/NineSliceLayouts.lua (itself from NewEra's generated AtlasData), and the
-- backing sheets ship under Art\Common\ (copied from the same source). Loads right after
-- Core/Texture.lua and before every consumer (NineSlice, PanelChrome, ScrollbarReskin, Tabs).

EJ = EJ or {}
EJ_ATLAS = EJ_ATLAS or {}

local COMMON = "Interface\\AddOns\\EncounterJournal\\Art\\Common\\"

local function reg(tbl)
  for name, info in pairs(tbl) do EJ_ATLAS[name:lower()] = info end
end

-- Resolve an atlas entry (our table only). Used by the tab reskin + the close button, which need
-- the raw rect to drive Button:SetXTexture(path) + GetXTexture():SetTexCoord on 3.3.5a.
function EJ.tex.AtlasEntry(name)
  return name and EJ_ATLAS[name:lower()] or nil
end

-- ---------------------------------------------------------------------------------------------
-- Shipped sheets (FDID → local BLP). Every atlas below points at one of these.
-- ---------------------------------------------------------------------------------------------
EJ.tex.RegisterLocal(374155,  COMMON .. "374155-uibackground-rock.blp")                      -- 1024x1024 DXT1 body fill
EJ.tex.RegisterLocal(1723831, COMMON .. "1723831-uiframe-inner.blp")                         -- inset corners (6x6)
EJ.tex.RegisterLocal(1723832, COMMON .. "1723832-uiframe-inner.blp")                         -- inset L/R tiles
EJ.tex.RegisterLocal(1723833, COMMON .. "1723833-uiframe-inner.blp")                         -- inset T/B band + streaks
EJ.tex.RegisterLocal(4698972, COMMON .. "4698972-redbutton-exit-2x.blp")                     -- RedButton close states
EJ.tex.RegisterLocal(4707839, COMMON .. "4707839-uiframe-tab.blp")                           -- DF metal panel tabs
EJ.tex.RegisterLocal(4331838, COMMON .. "4331838-minimal-scrollbar.blp")                     -- track caps + arrows
EJ.tex.RegisterLocal(4332072, COMMON .. "4332072-minimal-scrollbar-track-middle.blp")        -- !track-middle 1px tile
EJ.tex.RegisterLocal(5142784, COMMON .. "5142784-minimal-scrollbar-small-thumb-middle.blp")  -- thumb middle strip
EJ.tex.RegisterLocal(5142787, COMMON .. "5142787-minimal-scrollbar-small.blp")               -- thumb caps

-- ---------------------------------------------------------------------------------------------
-- InsetFrameTemplate inner border (the thin gold recess trim) — the retail rects, for anyone
-- applying the EJ.nineslice "InsetFrameTemplate" layout on a plain frame.
-- ---------------------------------------------------------------------------------------------
reg({
  ["ui-frame-innertopleft"]       = { file = 1723831, left = 0.757812, right = 0.804688, top = 0.554688, bottom = 0.601562, width = 6, height = 6 },
  ["ui-frame-innertopright"]      = { file = 1723831, left = 0.820312, right = 0.867188, top = 0.554688, bottom = 0.601562, width = 6, height = 6 },
  ["ui-frame-innerbotleftcorner"] = { file = 1723831, left = 0.632812, right = 0.679688, top = 0.554688, bottom = 0.601562, width = 6, height = 6 },
  ["ui-frame-innerbotright"]      = { file = 1723831, left = 0.695312, right = 0.742188, top = 0.554688, bottom = 0.601562, width = 6, height = 6 },
  ["!ui-frame-innerlefttile"]     = { file = 1723832, left = 0.484375, right = 0.531250, top = 0.000000, bottom = 1.000000, width = 3, height = 256 },
  ["!ui-frame-innerrighttile"]    = { file = 1723832, left = 0.562500, right = 0.609375, top = 0.000000, bottom = 1.000000, width = 3, height = 256 },
  ["_ui-frame-innertoptile"]      = { file = 1723833, left = 0.000000, right = 1.000000, top = 0.906250, bottom = 0.929688, width = 256, height = 3 },
  ["_ui-frame-innerbottile"]      = { file = 1723833, left = 0.000000, right = 1.000000, top = 0.867188, bottom = 0.890625, width = 256, height = 3 },
})

-- ---------------------------------------------------------------------------------------------
-- RedButton close-button family (sheet 4698972) — Core/PanelChrome.lua ModernizeCloseButton.
-- 7-col x 3-row grid of 36x38 cells: row1 normal / row2 disabled / row3 pressed; col2 = Exit,
-- col4 = Highlight.
-- ---------------------------------------------------------------------------------------------
reg({
  ["redbutton-exit-2x"]          = { file = 4698972, left = 0.152344, right = 0.292969, top = 0.007812, bottom = 0.304688, width = 36, height = 38 },
  ["redbutton-exit-disabled-2x"] = { file = 4698972, left = 0.152344, right = 0.292969, top = 0.320312, bottom = 0.617188, width = 36, height = 38 },
  ["redbutton-exit-pressed-2x"]  = { file = 4698972, left = 0.152344, right = 0.292969, top = 0.632812, bottom = 0.929688, width = 36, height = 38 },
  ["redbutton-highlight-2x"]     = { file = 4698972, left = 0.449219, right = 0.589844, top = 0.007812, bottom = 0.304688, width = 36, height = 38 },
})

-- ---------------------------------------------------------------------------------------------
-- Dragonflight metal panel tabs (sheet 4707839) — Core/Tabs.lua. "tab" = inactive (36 tall),
-- "activetab" = the selected gold tab (42 tall). The `_` centers are 1px-wide horizontal tiles.
-- ---------------------------------------------------------------------------------------------
reg({
  ["uiframe-tab-left"]          = { file = 4707839, left = 0.015625, right = 0.562500, top = 0.816406, bottom = 0.957031, width = 35, height = 36 },
  ["uiframe-tab-right"]         = { file = 4707839, left = 0.015625, right = 0.593750, top = 0.667969, bottom = 0.808594, width = 37, height = 36 },
  ["_uiframe-tab-center"]       = { file = 4707839, left = 0.000000, right = 0.015625, top = 0.175781, bottom = 0.316406, width = 1,  height = 36 },
  ["uiframe-activetab-left"]    = { file = 4707839, left = 0.015625, right = 0.562500, top = 0.496094, bottom = 0.660156, width = 35, height = 42 },
  ["uiframe-activetab-right"]   = { file = 4707839, left = 0.015625, right = 0.593750, top = 0.324219, bottom = 0.488281, width = 37, height = 42 },
  ["_uiframe-activetab-center"] = { file = 4707839, left = 0.000000, right = 0.015625, top = 0.003906, bottom = 0.167969, width = 1,  height = 42 },
})

-- ---------------------------------------------------------------------------------------------
-- MinimalScrollBar family (track/arrows 4331838, track middle 4332072, thumb caps 5142787, thumb
-- middle 5142784) — Core/ScrollbarReskin.lua. Registered by name exactly as that file asks for them.
-- ---------------------------------------------------------------------------------------------
reg({
  ["minimal-scrollbar-track-top"]    = { file = 4331838, left = 0.164062, right = 0.226562, top = 0.609375, bottom = 0.734375, width = 8, height = 8 },
  ["minimal-scrollbar-track-bottom"] = { file = 4331838, left = 0.085938, right = 0.148438, top = 0.765625, bottom = 0.890625, width = 8, height = 8 },
  ["!minimal-scrollbar-track-middle"]= { file = 4332072, left = 0.015625, right = 0.140625, top = 0.000000, bottom = 0.000977, width = 8, height = 1 },
  ["minimal-scrollbar-arrow-top"]         = { file = 4331838, left = 0.687500, right = 0.820312, top = 0.015625, bottom = 0.187500, width = 17, height = 11 },
  ["minimal-scrollbar-arrow-top-over"]    = { file = 4331838, left = 0.390625, right = 0.523438, top = 0.218750, bottom = 0.390625, width = 17, height = 11 },
  ["minimal-scrollbar-arrow-top-down"]    = { file = 4331838, left = 0.835938, right = 0.968750, top = 0.015625, bottom = 0.187500, width = 17, height = 11 },
  ["minimal-scrollbar-arrow-bottom"]      = { file = 4331838, left = 0.242188, right = 0.375000, top = 0.812500, bottom = 0.984375, width = 17, height = 11 },
  ["minimal-scrollbar-arrow-bottom-over"] = { file = 4331838, left = 0.539062, right = 0.671875, top = 0.015625, bottom = 0.187500, width = 17, height = 11 },
  ["minimal-scrollbar-arrow-bottom-down"] = { file = 4331838, left = 0.390625, right = 0.523438, top = 0.015625, bottom = 0.187500, width = 17, height = 11 },
  ["minimal-scrollbar-small-thumb-middle"]      = { file = 5142784, left = 0.484375, right = 0.609375, top = 0.000977, bottom = 0.699219, width = 8, height = 715 },
  ["minimal-scrollbar-small-thumb-middle-over"] = { file = 5142784, left = 0.328125, right = 0.453125, top = 0.000977, bottom = 0.699219, width = 8, height = 715 },
  ["minimal-scrollbar-small-thumb-middle-down"] = { file = 5142784, left = 0.171875, right = 0.296875, top = 0.000977, bottom = 0.699219, width = 8, height = 715 },
  ["minimal-scrollbar-small-thumb-top"]       = { file = 5142787, left = 0.312500, right = 0.437500, top = 0.843750, bottom = 0.968750, width = 8, height = 8 },
  ["minimal-scrollbar-small-thumb-top-over"]  = { file = 5142787, left = 0.468750, right = 0.593750, top = 0.843750, bottom = 0.968750, width = 8, height = 8 },
  ["minimal-scrollbar-small-thumb-top-down"]  = { file = 5142787, left = 0.468750, right = 0.593750, top = 0.687500, bottom = 0.812500, width = 8, height = 8 },
  ["minimal-scrollbar-small-thumb-bottom"]      = { file = 5142787, left = 0.609375, right = 0.734375, top = 0.484375, bottom = 0.609375, width = 8, height = 8 },
  ["minimal-scrollbar-small-thumb-bottom-over"] = { file = 5142787, left = 0.312500, right = 0.437500, top = 0.687500, bottom = 0.812500, width = 8, height = 8 },
  ["minimal-scrollbar-small-thumb-bottom-down"] = { file = 5142787, left = 0.765625, right = 0.890625, top = 0.484375, bottom = 0.609375, width = 8, height = 8 },
})
