-- Addon/Core/NineSlice.lua — reusable retail-style nineslice walker.
--
-- WHY: Era ships NineSliceUtil.ApplyLayout (byte-identical to retail's
-- /retail/.../Blizzard_SharedXML/NineSlice.lua) AND a NineSliceLayouts table
-- (/era/.../Blizzard_SharedXML/Classic/NineSliceLayouts.lua), but the layouts
-- point at classic vanilla atlases (UI-Frame-TopLeftCornerNoPortrait etc.) and
-- ApplyLayout calls piece:SetAtlas() which doesn't know retail nicknames on
-- Era. Result: Era's NineSliceUtil silently no-ops for retail atlases.
--
-- This module mirrors retail's ApplyLayout walker but routes each piece's
-- atlas resolution through EJ.tex.SetAtlas, which IS aware of retail atlases
-- via Generated/AtlasData.lua + locally-shipped sheet BLPs.
--
-- USAGE:
--   EJ.nineslice.AddLayout("ButtonFrameTemplateNoPortrait", { ... })
--   EJ.nineslice.ApplyLayout(frame, "ButtonFrameTemplateNoPortrait")
--
-- The layout data shape matches retail's NineSliceLayouts entries (see
-- /retail/.../Mainline/NineSliceLayouts.lua) with one Era-specific addition:
-- each piece may include `w` and `h` overrides. Use this when the atlas
-- nickname resolves to a -2x high-DPI variant whose intrinsic dimensions
-- differ from retail's 1x render size.

EJ = EJ or {}
EJ.nineslice = EJ.nineslice or {}
EJ.nineslice.layouts = EJ.nineslice.layouts or {}

function EJ.nineslice.AddLayout(name, layout)
  EJ.nineslice.layouts[name] = layout
end

-- Look up or create the piece texture on the container, mirroring retail's
-- GetNineSlicePiece (NineSlice.lua:40-56).
local function getPiece(container, pieceName)
  local p = container[pieceName]
  if p then return p, true end
  if container.GetNineSlicePiece then
    p = container:GetNineSlicePiece(pieceName)
    if p then
      container[pieceName] = p
      return p, true
    end
  end
  p = container:CreateTexture()
  container[pieceName] = p
  return p, false
end

-- Tile flags. Era doesn't expose tilesHorizontally/tilesVertically in atlas
-- info for retail nicknames, so we derive from the well-known WoW atlas
-- naming convention: `_<name>` = horiz-tile, `!<name>` = vert-tile.
local function tileFlagsFromAtlasName(atlasName)
  if not atlasName or atlasName == "" then return false, false end
  local prefix = atlasName:sub(1, 1)
  return prefix == "_", prefix == "!"
end

-- After SetAtlas, optionally re-flip texcoord for mirrored pieces. Retail's
-- mirrorLayout reuses a single TopLeft asset for all four corners by flipping
-- texcoords. Mirrors retail's SetupTextureCoordinates (NineSlice.lua:58-79)
-- but runs POST-atlas — EJ.tex.SetAtlas writes the atlas slice via
-- SetTexture+SetTexCoord, so any pre-atlas texcoord set would be clobbered.
local function applyPostAtlasMirror(piece, setupInfo, pieceLayout, userLayout)
  local pieceMirrored = pieceLayout.mirrorLayout
  if pieceMirrored == nil then pieceMirrored = userLayout and userLayout.mirrorLayout end
  if not pieceMirrored then return end
  local entry = EJ_ATLAS and EJ_ATLAS[(pieceLayout.atlas or ""):lower()]
  if not entry then return end
  local L, R, T, B = entry.left, entry.right, entry.top, entry.bottom
  if setupInfo.mirrorHorizontal then L, R = R, L end
  if setupInfo.mirrorVertical   then T, B = B, T end
  piece:SetTexCoord(L, R, T, B)
end

local function setupCorner(container, piece, setupInfo, pieceLayout)
  piece:ClearAllPoints()
  piece:SetPoint(pieceLayout.point or setupInfo.point, container,
                 pieceLayout.relativePoint or setupInfo.point,
                 pieceLayout.x or 0, pieceLayout.y or 0)
end

local function setupEdge(container, piece, setupInfo, pieceLayout)
  piece:ClearAllPoints()
  local p1 = getPiece(container, setupInfo.relativePieces[1])
  local p2 = getPiece(container, setupInfo.relativePieces[2])
  piece:SetPoint(setupInfo.point, p1, setupInfo.relativePoint,
                 pieceLayout.x or 0, pieceLayout.y or 0)
  piece:SetPoint(setupInfo.relativePoint, p2, setupInfo.point,
                 pieceLayout.x1 or 0, pieceLayout.y1 or 0)
end

local function setupCenter(container, piece, setupInfo, pieceLayout)
  piece:ClearAllPoints()
  local tl = getPiece(container, "TopLeftCorner")
  local br = getPiece(container, "BottomRightCorner")
  piece:SetPoint("TOPLEFT",     tl, "BOTTOMRIGHT", pieceLayout.x  or 0, pieceLayout.y  or 0)
  piece:SetPoint("BOTTOMRIGHT", br, "TOPLEFT",     pieceLayout.x1 or 0, pieceLayout.y1 or 0)
end

-- Ordered piece list. Corners first so edges can anchor to them; center last
-- so it can anchor to opposite corners. Matches retail's nineSliceSetup
-- (NineSlice.lua:135-146).
local nineSliceSetup = {
  { pieceName = "TopLeftCorner",     point = "TOPLEFT",     fn = setupCorner },
  { pieceName = "TopRightCorner",    point = "TOPRIGHT",    mirrorHorizontal = true, fn = setupCorner },
  { pieceName = "BottomLeftCorner",  point = "BOTTOMLEFT",  mirrorVertical   = true, fn = setupCorner },
  { pieceName = "BottomRightCorner", point = "BOTTOMRIGHT", mirrorHorizontal = true, mirrorVertical = true, fn = setupCorner },
  { pieceName = "TopEdge",    point = "TOPLEFT",    relativePoint = "TOPRIGHT",
    relativePieces = { "TopLeftCorner",    "TopRightCorner"    },                          fn = setupEdge },
  { pieceName = "BottomEdge", point = "BOTTOMLEFT", relativePoint = "BOTTOMRIGHT",
    relativePieces = { "BottomLeftCorner", "BottomRightCorner" }, mirrorVertical = true,   fn = setupEdge },
  { pieceName = "LeftEdge",   point = "TOPLEFT",    relativePoint = "BOTTOMLEFT",
    relativePieces = { "TopLeftCorner",    "BottomLeftCorner"  },                          fn = setupEdge },
  { pieceName = "RightEdge",  point = "TOPRIGHT",   relativePoint = "BOTTOMRIGHT",
    relativePieces = { "TopRightCorner",   "BottomRightCorner" }, mirrorHorizontal = true, fn = setupEdge },
  { pieceName = "Center",     fn = setupCenter },
}

function EJ.nineslice.ApplyLayout(container, layoutName)
  local layout = EJ.nineslice.layouts[layoutName]
  if not layout then
    if EJ.Log then EJ.Log("NINESLICE", "MISS layout " .. tostring(layoutName)) end
    return false
  end

  for _, setup in ipairs(nineSliceSetup) do
    local pieceLayout = layout[setup.pieceName]
    if pieceLayout then
      local piece, existed = getPiece(container, setup.pieceName)
      if not existed then
        local layer    = container.layoutTextureLayer    or pieceLayout.layer or "BORDER"
        local subLevel = container.layoutTextureSubLevel or pieceLayout.subLevel
        piece:SetDrawLayer(layer, subLevel)
      end
      setup.fn(container, piece, setup, pieceLayout)
      EJ.tex.SetAtlas(piece, pieceLayout.atlas, false)
      -- Tile flags and mirror must run POST-atlas: EJ.tex.SetAtlas calls
      -- SetTexture which resets wrap mode, and SetTexCoord which overwrites
      -- any pre-set texcoord.
      local h, v = tileFlagsFromAtlasName(pieceLayout.atlas)
      piece:SetHorizTile(h)
      piece:SetVertTile(v)
      applyPostAtlasMirror(piece, setup, pieceLayout, layout)
      -- Explicit per-piece size override for -2x atlases whose intrinsic
      -- dimensions don't match retail's 1x render size. Use SetWidth/
      -- SetHeight individually so edges (which constrain one axis via dual
      -- anchors) can specify only their tile-perpendicular dimension without
      -- conflict.
      if pieceLayout.w then piece:SetWidth(pieceLayout.w)  end
      if pieceLayout.h then piece:SetHeight(pieceLayout.h) end
      piece:Show()
    end
  end

  if layout.disableSharpening then
    for _, setup in ipairs(nineSliceSetup) do
      local piece = container[setup.pieceName]
      if piece and piece.SetTexelSnappingBias then
        piece:SetTexelSnappingBias(0)
        piece:SetSnapToPixelGrid(false)
      end
    end
  end
  return true
end

function EJ.nineslice.HideLayout(container)
  for _, setup in ipairs(nineSliceSetup) do
    local p = container[setup.pieceName]
    if p then p:Hide() end
  end
end

-- TopTileStreaks — the horizontally-tiled decorative streak band that retail's
-- ButtonFrameBaseTemplate AND PortraitFrameTexturedBaseTemplate render just under
-- the title bar (SharedXML/Mainline/SharedUIPanelTemplates.xml:671 & :608 — both
-- identical: BORDER layer, atlas `_UI-Frame-TopTileStreaks`, horizTile, anchored
-- TOPLEFT(6,-21) / TOPRIGHT(-2,-21), height = atlas native). It is default-ON for
-- the whole ButtonFrame/PortraitFrame family; only a handful of frames
-- (FriendsFrame, GuildBank, WorldMap, AdventureMap, …) explicitly Hide() it.
--
-- Our panels strip Era's classic chrome wholesale (incl. Era's classic
-- TopTileStreaks, which uses the legacy `Interface\FrameGeneral\_UI-Frame` art),
-- so the modern band goes missing — this re-adds it. The modern atlas
-- `_UI-Frame-TopTileStreaks` resolves to locally-shipped sheet FDID 1723833
-- (registered in CharacterPanel/Assets.lua), so no extraction is needed.
--
-- The band is created on `frame` itself (BORDER) so it renders ABOVE the
-- BACKGROUND Bg fill and BELOW a separate NineSlice child frame — matching
-- retail's layer order. The atlas region spans the full sheet width
-- (left=0,right=1), so SetHorizTile tiles it cleanly; height is the fixed atlas
-- native band. An explicit SetHeight is REQUIRED — with only the two top anchors
-- and useAtlasSize=false, an un-sized texture would fall back to the full BLP
-- sheet height (the same trap as the combo-point pips).
--
-- opts (all optional): { parent, xL=6, xR=-2, y=-21, h=<atlas native>,
--                        layer="BORDER", subLevel }
function EJ.nineslice.ApplyTopTileStreaks(frame, opts)
  if not frame then return end
  opts = opts or {}
  local host = opts.parent or frame
  local t = frame._ejTopTileStreaks
  if not t then
    t = host:CreateTexture(nil, opts.layer or "BORDER", nil, opts.subLevel)
    frame._ejTopTileStreaks = t
  end
  t:ClearAllPoints()
  t:SetPoint("TOPLEFT",  host, "TOPLEFT",  opts.xL or 6,  opts.y or -21)
  t:SetPoint("TOPRIGHT", host, "TOPRIGHT", opts.xR or -2, opts.y or -21)
  if not (EJ.tex and EJ.tex.SetAtlas and EJ.tex.SetAtlas(t, "_UI-Frame-TopTileStreaks", false)) then
    t:Hide()
    return t
  end
  t:SetHorizTile(true)   -- SetAtlas resets wrap mode; re-assert horizontal tiling
  local entry = EJ_ATLAS and EJ_ATLAS["_ui-frame-toptilestreaks"]
  t:SetHeight(opts.h or (entry and entry.height) or 43)
  t:Show()
  return t
end

-- Hide Era's existing nineslice pieces on a frame that inherits one of the
-- classic ButtonFrameTemplate-family layouts. Era's ButtonFrameTemplate adds
-- the pieces as `frame.NineSlice.TopLeftCorner` etc. (when NineSlice was
-- applied via NineSliceUtil at frame-creation time), OR as direct child
-- pieces with various legacy names. We hide both surfaces to be safe.
function EJ.nineslice.HideClassicChrome(frame)
  if not frame then return end
  local nineSlice = frame.NineSlice
  if nineSlice then EJ.nineslice.HideLayout(nineSlice) end
  -- Some Era frames have the pieces directly on the frame, not on .NineSlice.
  EJ.nineslice.HideLayout(frame)
end

-- ===========================================================================================
-- Retail nineslice LAYOUT DATA (was Core/NineSliceLayouts.lua; folded in below the walker that
-- consumes it). Transcribed from /retail/.../Mainline/NineSliceLayouts.lua. Atlas names are the
-- retail nicknames; on Era they resolve through EJ.tex.SetAtlas → AtlasData → shipped sheet
-- BLPs. Must run after Core/Texture.lua (the RegisterLocal calls below need EJ.tex) — the TOC
-- already loads NineSlice.lua after Texture.lua.
--
-- Note: retail 12.0.5 consolidated UI-Frame-Metal-* art to high-DPI -2x sheets (no separate 1x
-- sheets exist in the atlas DB). On Era we use the -2x atlas names directly and supply `w`/`h`
-- overrides equal to the 1x render size.
-- ===========================================================================================

-- The mainline panel chrome. Used by LootFrame and most non-portrait frames
-- (character pane's secondary tabs, professions, mail, etc.).
-- Offsets mirror retail's ButtonFrameTemplateNoPortrait at
-- /retail/.../NineSliceLayouts.lua:43-54. Corner sizes are atlas-native
-- pixels at the 1x render size (atlas is -2x at 150x150, rendered at 75x75).
EJ.nineslice.AddLayout("ButtonFrameTemplateNoPortrait", {
  disableSharpening = true,
  -- Corners. Top corners are larger (75x75) because they include the decorative
  -- metal "ear" caps extending up beyond the frame; bottom corners are plain
  -- (32x32). All anchored just outside the frame edge per retail's offsets.
  TopLeftCorner     = { layer = "OVERLAY", atlas = "UI-Frame-Metal-CornerTopLeft-2x",     w = 75, h = 75, x = -8, y = 16 },
  TopRightCorner    = { layer = "OVERLAY", atlas = "UI-Frame-Metal-CornerTopRight-2x",    w = 75, h = 75, x =  4, y = 16 },
  BottomLeftCorner  = { layer = "OVERLAY", atlas = "UI-Frame-Metal-CornerBottomLeft-2x",  w = 32, h = 32, x = -8, y = -3 },
  BottomRightCorner = { layer = "OVERLAY", atlas = "UI-Frame-Metal-CornerBottomRight-2x", w = 32, h = 32, x =  4, y = -3 },
  -- Edges. The tile-perpendicular dimension is the BAND THICKNESS — the
  -- intrinsic width (for vert-tile `!` edges) or height (for horiz-tile `_`
  -- edges) of one tile unit's art. NOT the adjacent corner width — verified
  -- via retail's C_Texture.GetAtlasInfo:
  --   _UI-Frame-Metal-EdgeTop  → 32 × 75  (tile w × band h)
  --   !UI-Frame-Metal-EdgeLeft → 75 × 16  (band w × tile h)
  -- The band art itself contains the taper between wide-top and narrow-bottom
  -- corner widths; we set the band to its full intrinsic thickness and let the
  -- atlas's drawn taper handle the visual transition.
  TopEdge    = { layer = "OVERLAY", atlas = "_UI-Frame-Metal-EdgeTop-2x",    h = 75 },
  BottomEdge = { layer = "OVERLAY", atlas = "_UI-Frame-Metal-EdgeBottom-2x", h = 32 },
  LeftEdge   = { layer = "OVERLAY", atlas = "!UI-Frame-Metal-EdgeLeft-2x",   w = 75 },
  RightEdge  = { layer = "OVERLAY", atlas = "!UI-Frame-Metal-EdgeRight-2x",  w = 75 },
})

-- Register sheet BLPs. Three sheets total: corners on one, vert-tile edges on
-- another, horiz-tile edges on a third. Extracted from build 12.0.5.67451.
EJ.tex.RegisterLocal(2406979, "Interface\\AddOns\\EncounterJournal\\Art\\Common\\2406979-uiframe-metal-corners.blp")
EJ.tex.RegisterLocal(2406984, "Interface\\AddOns\\EncounterJournal\\Art\\Common\\2406984-uiframe-metal-edges-vert.blp")
EJ.tex.RegisterLocal(2406987, "Interface\\AddOns\\EncounterJournal\\Art\\Common\\2406987-uiframe-metal-edges-horiz.blp")

-- InsetFrameTemplate — the THIN GOLD inner border that wraps an inset's
-- content area. Transcribed VERBATIM from
-- retail/Blizzard_SharedXML/Mainline/NineSliceLayouts.lua:81-91. The corners
-- are 6x6, edges are 3 wide/tall. Layer=BORDER, sublevel=-5 so this draws
-- behind any content placed in the inset but above the inset's marble bg
-- (which is at BACKGROUND -5).
EJ.nineslice.AddLayout("InsetFrameTemplate", {
  TopLeftCorner     = { layer = "BORDER", subLevel = -5, atlas = "UI-Frame-InnerTopLeft",        w = 6, h = 6 },
  TopRightCorner    = { layer = "BORDER", subLevel = -5, atlas = "UI-Frame-InnerTopRight",       w = 6, h = 6 },
  BottomLeftCorner  = { layer = "BORDER", subLevel = -5, atlas = "UI-Frame-InnerBotLeftCorner",  w = 6, h = 6, x = 0, y = -1 },
  BottomRightCorner = { layer = "BORDER", subLevel = -5, atlas = "UI-Frame-InnerBotRight",       w = 6, h = 6, x = 0, y = -1 },
  TopEdge    = { layer = "BORDER", subLevel = -5, atlas = "_UI-Frame-InnerTopTile",   h = 3 },
  BottomEdge = { layer = "BORDER", subLevel = -5, atlas = "_UI-Frame-InnerBotTile",   h = 3 },
  LeftEdge   = { layer = "BORDER", subLevel = -5, atlas = "!UI-Frame-InnerLeftTile",  w = 3 },
  RightEdge  = { layer = "BORDER", subLevel = -5, atlas = "!UI-Frame-InnerRightTile", w = 3 },
})

-- PortraitFrameTemplate — same metal family as ButtonFrameTemplateNoPortrait
-- EXCEPT the top-left corner uses UI-Frame-PortraitMetal-CornerTopLeft, which
-- has a circular cutout/ring sized to wrap a 62x62 portrait. Offsets per
-- retail's PortraitFrameTemplate layout (NineSliceLayouts.lua:17-28):
--   TopLeftCorner x=-13 (vs -8 in NoPortrait) to widen the left overhang for
--   the portrait recess; bottom-left also x=-13 to align with that overhang.
-- Atlases: Core/AtlasData.lua "Window frame art" (Art/Frame/uiframemetal*.blp, 1x render sizes).
EJ.nineslice.AddLayout("PortraitFrameTemplate", {
  disableSharpening = true,
  TopLeftCorner     = { layer = "OVERLAY", atlas = "UI-Frame-PortraitMetal-CornerTopLeft", w = 75, h = 75, x = -13, y = 16 },
  TopRightCorner    = { layer = "OVERLAY", atlas = "UI-Frame-Metal-CornerTopRight",        w = 75, h = 75, x =   4, y = 16 },
  BottomLeftCorner  = { layer = "OVERLAY", atlas = "UI-Frame-Metal-CornerBottomLeft",      w = 32, h = 32, x = -13, y = -3 },
  BottomRightCorner = { layer = "OVERLAY", atlas = "UI-Frame-Metal-CornerBottomRight",     w = 32, h = 32, x =   4, y = -3 },
  TopEdge    = { layer = "OVERLAY", atlas = "_UI-Frame-Metal-EdgeTop",    h = 75 },
  BottomEdge = { layer = "OVERLAY", atlas = "_UI-Frame-Metal-EdgeBottom", h = 32 },
  LeftEdge   = { layer = "OVERLAY", atlas = "!UI-Frame-Metal-EdgeLeft",   w = 75 },
  RightEdge  = { layer = "OVERLAY", atlas = "!UI-Frame-Metal-EdgeRight",  w = 75 },
})

-- Dialog — retail's "clean diamond" border (NineSliceLayouts.lua:157 "Dialog", used by
-- DialogBorderTemplate → the ESC menu / modern dialogs). The DiamondMetal metal frame, NOT
-- Era's old busy UI-DialogBox-Border edge. -2x atlases (Era ships them); 128px 2x → 64 render.
-- D is the corner square + edge thickness (must match so corners/edges align). Edit Mode's
-- "EditModeDialog" uses 64 (reads thick); the GameMenu wants the relatively thin retail look,
-- so 32. Tunable — bump/drop to taste.
local D = 32
EJ.nineslice.AddLayout("Dialog", {
  -- Retail's DiamondMetal "Dialog" layout (NineSliceLayouts.lua:157) does NOT set
  -- disableSharpening — it leaves the chrome at the crisp engine default. We match it
  -- (we previously softened here, which read blurrier than retail). NOTE: our atlases
  -- are -2x downscaled (see header); if the crisp corners/edges shimmer in-client, the
  -- retail-faithful fix is 1x art or integer sizing, NOT re-adding disableSharpening.
  -- TODO(era-verify): confirm no -2x downscale shimmer on the 7 Dialog consumers.
  TopLeftCorner     = { layer = "OVERLAY", atlas = "UI-Frame-DiamondMetal-CornerTopLeft-2x",     w = D, h = D },
  TopRightCorner    = { layer = "OVERLAY", atlas = "UI-Frame-DiamondMetal-CornerTopRight-2x",    w = D, h = D },
  BottomLeftCorner  = { layer = "OVERLAY", atlas = "UI-Frame-DiamondMetal-CornerBottomLeft-2x",  w = D, h = D },
  BottomRightCorner = { layer = "OVERLAY", atlas = "UI-Frame-DiamondMetal-CornerBottomRight-2x", w = D, h = D },
  TopEdge    = { layer = "OVERLAY", atlas = "_UI-Frame-DiamondMetal-EdgeTop-2x",    h = D },
  BottomEdge = { layer = "OVERLAY", atlas = "_UI-Frame-DiamondMetal-EdgeBottom-2x", h = D },
  LeftEdge   = { layer = "OVERLAY", atlas = "!UI-Frame-DiamondMetal-EdgeLeft-2x",   w = D },
  RightEdge  = { layer = "OVERLAY", atlas = "!UI-Frame-DiamondMetal-EdgeRight-2x",  w = D },
})

-- PortraitFrameTemplateMinimizable — variant of PortraitFrameTemplate using
-- the "Double" right corner. Retail's NineSliceLayouts.lua:30-41 confirms:
-- frames that ship with a MaximizeMinimize button (WorldMapFrame, etc.) use
-- UI-Frame-Metal-CornerTopRightDouble — a wider corner art with built-in
-- space for the 24×24 max/min + close buttons. Without this, the regular
-- CornerTopRight collides with the button row visually.
EJ.nineslice.AddLayout("PortraitFrameTemplateMinimizable", {
  disableSharpening = true,
  TopLeftCorner     = { layer = "OVERLAY", atlas = "UI-Frame-PortraitMetal-CornerTopLeft-2x",  w = 75, h = 75, x = -13, y = 16 },
  TopRightCorner    = { layer = "OVERLAY", atlas = "UI-Frame-Metal-CornerTopRightDouble-2x",   w = 75, h = 75, x =   4, y = 16 },
  BottomLeftCorner  = { layer = "OVERLAY", atlas = "UI-Frame-Metal-CornerBottomLeft-2x",       w = 32, h = 32, x = -13, y = -3 },
  BottomRightCorner = { layer = "OVERLAY", atlas = "UI-Frame-Metal-CornerBottomRight-2x",      w = 32, h = 32, x =   4, y = -3 },
  TopEdge    = { layer = "OVERLAY", atlas = "_UI-Frame-Metal-EdgeTop-2x",    h = 75 },
  BottomEdge = { layer = "OVERLAY", atlas = "_UI-Frame-Metal-EdgeBottom-2x", h = 32 },
  LeftEdge   = { layer = "OVERLAY", atlas = "!UI-Frame-Metal-EdgeLeft-2x",   w = 75 },
  RightEdge  = { layer = "OVERLAY", atlas = "!UI-Frame-Metal-EdgeRight-2x",  w = 75 },
})

-- ButtonFrameTemplateNoPortraitMinimizable — plain (no-portrait) metal frame WITH the
-- "Double" top-right corner that leaves room for the max/min + close button row. This is
-- the chrome a minimizable PORTRAIT frame swaps TO when minimized (portrait hidden) — same
-- Double right corner, plain (ring-less) left corner. Geometry from retail's
-- NineSliceLayouts.lua:56-66 (TopLeft x=-12 there, vs -8 on the non-minimizable NoPortrait).
-- Unlike its siblings ButtonFrameTemplateNoPortrait(:43) and …LessPadding(:68) — which DO set
-- disableSharpening — retail's Minimizable variant OMITS it, leaving the chrome crisp. We
-- match: no disableSharpening here (we previously softened it, reading blurrier than retail).
-- NOTE: our atlases are -2x downscaled; TODO(era-verify) the minimized Guild frame corners
-- stay crisp without shimmer; if they don't, use 1x art rather than re-softening.
-- All atlases already ship on FDID 2406979 (same sheet as the other metal corners).
EJ.nineslice.AddLayout("ButtonFrameTemplateNoPortraitMinimizable", {
  TopLeftCorner     = { layer = "OVERLAY", atlas = "UI-Frame-Metal-CornerTopLeft-2x",        w = 75, h = 75, x = -12, y = 16 },
  TopRightCorner    = { layer = "OVERLAY", atlas = "UI-Frame-Metal-CornerTopRightDouble-2x", w = 75, h = 75, x =   4, y = 16 },
  BottomLeftCorner  = { layer = "OVERLAY", atlas = "UI-Frame-Metal-CornerBottomLeft-2x",     w = 32, h = 32, x = -12, y = -3 },
  BottomRightCorner = { layer = "OVERLAY", atlas = "UI-Frame-Metal-CornerBottomRight-2x",    w = 32, h = 32, x =   4, y = -3 },
  TopEdge    = { layer = "OVERLAY", atlas = "_UI-Frame-Metal-EdgeTop-2x",    h = 75 },
  BottomEdge = { layer = "OVERLAY", atlas = "_UI-Frame-Metal-EdgeBottom-2x", h = 32 },
  LeftEdge   = { layer = "OVERLAY", atlas = "!UI-Frame-Metal-EdgeLeft-2x",   w = 75 },
  RightEdge  = { layer = "OVERLAY", atlas = "!UI-Frame-Metal-EdgeRight-2x",  w = 75 },
})

-- HeldBagLayout — variant of PortraitFrameTemplate with the SMALL portrait
-- corner. Used by retail's ContainerFrameTemplate and ContainerFrameCombined
-- Bags (Mainline/ContainerFrame.xml:220, 293) because retail's container
-- frames override their portrait to 36x36 (PortraitFrame.lua:101 +
-- ContainerFrame.lua:682) — the regular cornertopleft has a circular cutout
-- sized for the default 62x62 portrait, leaving empty space around 36x36.
-- The "small" variant has a tighter cutout matching the 36x36 size.
-- Source: retail Shared NineSliceLayouts.lua:361-372.
EJ.nineslice.AddLayout("HeldBagLayout", {
  disableSharpening = true,
  TopLeftCorner     = { layer = "OVERLAY", atlas = "UI-Frame-PortraitMetal-CornerTopLeftSmall-2x", w = 75, h = 75, x = -13, y = 16 },
  TopRightCorner    = { layer = "OVERLAY", atlas = "UI-Frame-Metal-CornerTopRight-2x",             w = 75, h = 75, x =   4, y = 16 },
  BottomLeftCorner  = { layer = "OVERLAY", atlas = "UI-Frame-Metal-CornerBottomLeft-2x",           w = 32, h = 32, x = -13, y = -3 },
  BottomRightCorner = { layer = "OVERLAY", atlas = "UI-Frame-Metal-CornerBottomRight-2x",          w = 32, h = 32, x =   4, y = -3 },
  TopEdge    = { layer = "OVERLAY", atlas = "_UI-Frame-Metal-EdgeTop-2x",    h = 75 },
  BottomEdge = { layer = "OVERLAY", atlas = "_UI-Frame-Metal-EdgeBottom-2x", h = 32 },
  LeftEdge   = { layer = "OVERLAY", atlas = "!UI-Frame-Metal-EdgeLeft-2x",   w = 75 },
  RightEdge  = { layer = "OVERLAY", atlas = "!UI-Frame-Metal-EdgeRight-2x",  w = 75 },
})

-- Action bar 1 chrome — two nineslice layers per retail's MainActionBar.
-- BorderArt single texture works on retail because the atlas DB has slice
-- metadata that the engine uses to render with constant-size corners +
-- tiling edges. Era's engine doesn't carry that metadata for retail
-- nicknames, so the single texture stretches as a flat strip. We
-- replicate the intended look by composing two nineslices via our walker.

-- NOTE: the "ActionBarFrameBackground" layout (a uniform ~20% dark fill ring from
-- frame-background-nineslice) was REMOVED 2026-06-19 — retail's main bar has no such
-- layer (MainActionBar.xml uses a single BorderArt), and ours stacked under the metal
-- BorderFrame, doubling the bar's drop shadow. See ActionBar1.lua bar-chrome comment.

-- Outer metal border that wraps the bar (top/bottom/left/right + corners).
EJ.nineslice.AddLayout("ActionBarFrame", {
  TopLeftCorner     = { atlas = "ui-hud-actionbar-frame-nineslice-cornertopleft",     w = 17, h = 16 },
  TopRightCorner    = { atlas = "ui-hud-actionbar-frame-nineslice-cornertopright",    w = 22, h = 16 },
  BottomLeftCorner  = { atlas = "ui-hud-actionbar-frame-nineslice-cornerbottomleft",  w = 17, h = 23 },
  BottomRightCorner = { atlas = "ui-hud-actionbar-frame-nineslice-cornerbottomright", w = 22, h = 23 },
  TopEdge    = { atlas = "_ui-hud-actionbar-frame-nineslice-edgetop",    h = 16 },
  BottomEdge = { atlas = "_ui-hud-actionbar-frame-nineslice-edgebottom", h = 23 },
  LeftEdge   = { atlas = "!ui-hud-actionbar-frame-nineslice-edgeleft",   w = 17 },
  RightEdge  = { atlas = "!ui-hud-actionbar-frame-nineslice-edgeright",  w = 22 },
})

-- ObjectiveTracker opacity background (retail Blizzard_ObjectiveTrackerContainer.xml:70-80 —
-- NineSlice "common-opacity-background", UniqueCornersLayout). Driven by the Edit Mode Opacity
-- slider (alpha = opacity/100). Piece sizes resolved from UiTextureAtlas (5147221/5147228/5147236).
-- The retail -30 left / +5 right padding lives on the host frame's anchor, not here.
EJ.nineslice.AddLayout("ObjectiveTrackerOpacityBackground", {
  TopLeftCorner     = { atlas = "common-opacity-background-nineslice-cornertopleft",     w = 12, h = 11 },
  TopRightCorner    = { atlas = "common-opacity-background-nineslice-cornertopright",    w = 14, h = 11 },
  BottomLeftCorner  = { atlas = "common-opacity-background-nineslice-cornerbottomleft",  w = 12, h = 13 },
  BottomRightCorner = { atlas = "common-opacity-background-nineslice-cornerbottomright", w = 14, h = 13 },
  TopEdge    = { atlas = "_common-opacity-background-nineslice-edgetop",    h = 11 },
  BottomEdge = { atlas = "_common-opacity-background-nineslice-edgebottom", h = 13 },
  LeftEdge   = { atlas = "!common-opacity-background-nineslice-edgeleft",   w = 12 },
  RightEdge  = { atlas = "!common-opacity-background-nineslice-edgeright",  w = 14 },
  Center     = { atlas = "common-opacity-background-nineslice-center" },
})
