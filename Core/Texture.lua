-- Addon/Core/Texture.lua — the canonical atlas API for the rest of the addon.
--
-- WHY a shim instead of just calling Texture:SetAtlas:
--   1. Era's atlas table is empty for retail-modern nicknames (probe-confirmed:
--      C_Texture.GetAtlasInfo("UI-HUD-UnitFrame-Player-PortraitOn") returns nil).
--      Calling tex:SetAtlas(name) on Era no-ops or errors. We resolve via EJ_ATLAS
--      (generated from wago.tools' UiTextureAtlas[Member] CSV).
--   2. Same-FDID-≠-same-art (CLAUDE.md decision log): Era's CASC may ship vanilla-era
--      art at the same FDID. The shim prefers a ship-local copy registered via
--      EJ.tex.RegisterLocal(fdid, path), falling back to the FDID only if no local copy
--      is registered for that sheet.
--
-- USAGE:
--   EJ.tex.RegisterLocal(4631591, "Interface\\AddOns\\NewEra\\Art\\UnitFrame\\4631591-...blp")
--   EJ.tex.SetAtlas(myTexture, "UI-HUD-UnitFrame-Player-PortraitOn", true)  -- useAtlasSize

EJ = EJ or {}
EJ.tex = EJ.tex or {}

-- FDID -> addon-relative texture path. Sheets we've extracted from retail and ship in
-- /Addon/Art/*. Populated by per-frame asset registration files (e.g. PlayerFrame/Assets.lua).
EJ.tex.localFiles = EJ.tex.localFiles or {}

function EJ.tex.RegisterLocal(fdid, path)
  EJ.tex.localFiles[fdid] = path
end

-- Local BLP path registered for an FDID (RegisterLocal), or nil. Thin accessor so
-- consumers stop poking EJ.tex.localFiles directly.
function EJ.tex.Local(fdid)
  return EJ.tex.localFiles[fdid]
end

-- Resolved atlas rect (texcoords) for a nickname → left,right,top,bottom, or the full
-- 0,1,0,1 sheet if unknown. Consolidates the `entry = EJ_ATLAS[name:lower()]; l = entry
-- and entry.left or 0` destructure inlined across the flipbook/status-bar consumers.
function EJ.tex.GetAtlasRect(name)
  local entry = name and EJ_ATLAS and EJ_ATLAS[name:lower()]
  if not entry then return 0, 1, 0, 1 end
  return entry.left, entry.right, entry.top, entry.bottom
end

-- Resolve a dotted key path ("a.b.c") to root.a.b.c, or nil if any hop is missing. The
-- widget resolver duplicated verbatim across the unit frames (Player/Target/ToT/...).
function EJ.tex.ResolveKeyPath(root, path)
  local node = root
  for key in path:gmatch("[^.]+") do
    node = node and node[key]
    if not node then return nil end
  end
  return node
end

-- Apply an ATLAS_MAP { [keypath] = { name=, target=, useAtlasSize= } } to a frame's
-- resolved widgets: bars (target=="bar") via SetAtlasOnStatusBar, else SetAtlas. Missing
-- paths log under `label`. Consolidates the per-unit-frame applyAtlases loop.
function EJ.tex.ApplyAtlasMap(self, map, label)
  for path, entry in pairs(map) do
    local widget = EJ.tex.ResolveKeyPath(self, path)
    if widget then
      if entry.target == "bar" and widget.SetStatusBarTexture then
        EJ.tex.SetAtlasOnStatusBar(widget, entry.name)
      elseif widget.GetObjectType and widget:GetObjectType() == "MaskTexture" then
        -- Masks via SetAtlasMask so SetTexture keeps CLAMPTOBLACKADDITIVE wrap (plain
        -- SetAtlas resets wrap → the mask tiles/leaks).
        EJ.tex.SetAtlasMask(widget, entry.name)
      else
        EJ.tex.SetAtlas(widget, entry.name, entry.useAtlasSize)
      end
    elseif label then
      EJ.Log("ATLAS", "MISS path " .. label .. "." .. path)
    end
  end
end

-- Apply an atlas nickname to a texture. Returns true on success, false otherwise.
-- The shim swallows the failure rather than erroring — hard rule #12 (Hardcore fail-safe).
function EJ.tex.SetAtlas(tex, name, useAtlasSize, filterMode)
  if not (tex and name) then return false end
  local key = name:lower()
  local entry = EJ_ATLAS and EJ_ATLAS[key]
  if not entry then
    -- Optional fallback: when !!!ClassicAPI is loaded it adds texture:SetAtlas backed by its
    -- C_Texture.AtlasData — use an atlas registered there that EJ_ATLAS doesn't have. Every atlas
    -- the journal needs is in EJ_ATLAS (Core/AtlasData.lua), so without ClassicAPI this is a miss.
    -- Original-case name: ClassicAPI's AtlasData is case-sensitive, unlike EJ_ATLAS's keys.
    if tex.SetAtlas and C_Texture and C_Texture.GetAtlasExists and C_Texture.GetAtlasExists(name) then
      tex:SetAtlas(name, useAtlasSize)
      return true
    end
    if EJ.Log then EJ.Log("ATLAS", "MISS atlas " .. tostring(name)) end
    return false
  end
  local source = (entry.path or EJ.tex.localFiles[entry.file])
  -- 3.3.5a: Texture:SetTexture cannot read a raw FileDataID (it renders the red "missing"
  -- square while reporting success), so an EJ_ATLAS entry whose sheet isn't shipped locally is a
  -- MISS — callers then keep their native art instead of a red block. Likewise the 4th filterMode
  -- arg is an Era/retail extension; 3.3.5a takes the bare path (a 4-arg call can error on some
  -- builds), so the LINEAR hint the New Era source passed is dropped here.
  if type(source) ~= "string" then
    if EJ.Log then EJ.Log("ATLAS", "NO-LOCAL atlas " .. tostring(name) .. " (fdid " .. tostring(entry.file) .. ")") end
    return false
  end
  tex:SetTexture(source)
  tex:SetTexCoord(entry.left, entry.right, entry.top, entry.bottom)
  if useAtlasSize and entry.width and entry.height then
    tex:SetSize(entry.width, entry.height)
  end
  -- 9-slice (retail parity). Many atlas elements are authored as nine-slices: the engine's
  -- own SetAtlas reads the element's slice margins and renders fixed corners/edges while only
  -- the thin middle stretches. Our shim does a plain SetTexCoord, which STRETCHES the whole
  -- art — so a rounded-rect background (bar BG, nameplate border, chrome frame) balloons its
  -- corners into a pill and blurs (proven on the CooldownViewer BuffBar: element 30191 carries
  -- margins 121,7,10,11). Reproduce the engine by applying the element's margins from the
  -- generated EJ_ATLAS_SLICE table. Margins are in the named element's own pixel space (so the
  -- -2x nicknames carry pre-doubled values) and are interpreted relative to the texcoord region
  -- we just set (confirmed in-client). Clear stale margins when the new atlas isn't sliced, so a
  -- pooled/re-used texture doesn't keep a previous element's slice. Era-gated on the setter.
  -- Skip MaskTextures: slicing a clip mask would corrupt its alpha clip. (The only sliced atlas
  -- that can reach a mask — ui-hud-nameplates-aggro-mask — routes through SetAtlasMask, not here.)
  if tex.SetTextureSliceMargins and not (tex.GetObjectType and tex:GetObjectType() == "MaskTexture") then
    local slice = EJ_ATLAS_SLICE and EJ_ATLAS_SLICE[key]
    if slice then
      if tex.SetTextureSliceMode then tex:SetTextureSliceMode(slice.mode or 0) end
      tex:SetTextureSliceMargins(slice.l, slice.t, slice.r, slice.b)
      tex._ejSliced = true
    elseif tex._ejSliced then          -- only clear a slice WE applied (don't touch others)
      if tex.ClearTextureSlice then tex:ClearTextureSlice() else tex:SetTextureSliceMargins(0, 0, 0, 0) end
      tex._ejSliced = nil
    end
  end
  return true
end

-- Match retail's STATIONARY HUD bar textures (CooldownViewer buff bar / our fixed Edit-Mode
-- PRD / nameplate health bar). Probed live on retail's BuffBarCooldownViewer: EVERY bar texture
-- (fill, BarBG, Pip, even the icon) renders with texelSnappingBias = 0.3 and the engine-default
-- pixel-grid snapping (ON). bias 0.3 nudges texel sampling onto the pixel grid → crisp 1px
-- borders; bias 0 (what we briefly used, copied from the FLOATING PRD's XML which softens because
-- it slides under the player) is what blurred them. Our PRD is a fixed frame, so it wants these
-- same crisp values. API present on Era (SimpleTextureBaseAPIDocumentation.lua:355,376).
function EJ.tex.SmoothBarTex(tex)
  if not tex then return end
  if tex.SetSnapToPixelGrid then tex:SetSnapToPixelGrid(true) end
  if tex.SetTexelSnappingBias then tex:SetTexelSnappingBias(0.3) end
end

-- Inline-text markup for an atlas element — our CreateAtlasMarkup. The client's
-- CreateAtlasMarkup only resolves ENGINE-known atlases; ours live in EJ_ATLAS over local
-- BLPs, so build the |T form with explicit texcoords instead:
--   |Tpath:h:w:0:0:fileW:fileH:l:r:t:b|t
-- The engine only uses l/fileW etc. as RATIOS, so any consistent base works — 1024 keeps
-- rounding error ≤0.1%. Returns nil when the atlas (or its local sheet) is unknown, so
-- callers can degrade to undecorated text (hard rule #12).
function EJ.tex.AtlasMarkup(name, width, height)
  if not name then return nil end
  local entry = EJ_ATLAS and EJ_ATLAS[name:lower()]
  if not entry then return nil end
  local path = (entry.path or EJ.tex.localFiles[entry.file])
  if not path then return nil end                 -- markup can't express a bare FDID reliably
  local B = 1024
  return ("|T%s:%d:%d:0:0:%d:%d:%d:%d:%d:%d|t"):format(
    path, height or entry.height or 16, width or entry.width or 16, B, B,
    math.floor(entry.left * B + 0.5), math.floor(entry.right * B + 0.5),
    math.floor(entry.top * B + 0.5),  math.floor(entry.bottom * B + 0.5))
end

-- Same as SetAtlas but for MaskTexture — sets CLAMPTOBLACKADDITIVE wrap modes so the
-- mask's alpha is 0 outside its drawn bounds. Required for retail-style masks that
-- clip a source texture to a defined shape (the alternative — default REPEAT wrap —
-- tiles the mask alpha infinitely, which on a small mask like IconFrame-Mask makes
-- the source visible WAY beyond the intended clip region).
--
-- Retail XML pattern: <MaskTexture atlas="..." vWrapMode="CLAMPTOBLACKADDITIVE"
-- hWrapMode="CLAMPTOBLACKADDITIVE">. Mirrors that.
function EJ.tex.SetAtlasMask(maskTex, name)
  if not (maskTex and name) then return false end
  local entry = EJ_ATLAS and EJ_ATLAS[name:lower()]
  if not entry then
    if EJ.Log then EJ.Log("ATLAS", "MISS mask atlas " .. tostring(name)) end
    return false
  end
  local source = (entry.path or EJ.tex.localFiles[entry.file]) or entry.file
  maskTex:SetTexture(source, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE", "LINEAR")
  maskTex:SetTexCoord(entry.left, entry.right, entry.top, entry.bottom)
  return true
end

-- Apply an atlas to a StatusBar on Era — via a CUSTOM OVERLAY, not the bar's own texture.
--
-- Background: Era 1.15.x has neither Texture:SetAtlas (atlas resolution) nor
-- StatusBar:SetStatusBarTexCoord (source-rect lock). The engine recomputes the bar's
-- internal texture texcoord to (0, value/max, 0, 1) on every SetValue, and — based on
-- empirical flicker that persists despite OnValueChanged HookScript, OnMinMaxChanged,
-- hooksecurefunc on SetValue/SetMinMaxValues, and a per-frame central OnUpdate updater —
-- the engine ALSO recomputes texcoord during the layout phase after all scripts have
-- fired but before render. No script-level hook can win that race.
--
-- Solution: stop fighting the engine. The bar's internal texture still exists (engine
-- still tracks value, child segments like heal prediction still anchor to it via
-- GetStatusBarTexture), but we set its alpha=0 so its texcoord flicker is invisible.
-- We draw the visible fill ourselves via a custom Texture overlay on the bar's
-- ARTWORK layer that we control absolutely — engine never touches its texcoord.
local function updateAtlasOverlay(bar)
  local a = bar._ejAtlas
  local overlay = bar._ejOverlay
  if not (a and overlay) then return end
  local minV, maxV = bar:GetMinMaxValues()
  minV, maxV = minV or 0, maxV or 1
  local denom = (maxV ~= minV) and (maxV - minV) or 1
  local v = bar:GetValue() or minV
  local f = (v - minV) / denom
  if not f or f ~= f then f = 0 end  -- nil/NaN guard
  if f < 0 then f = 0 elseif f > 1 then f = 1 end
  local barW = bar:GetWidth() or 0
  local barH = bar:GetHeight() or 0
  -- Zero width edge case: SetSize(0, H) may trigger WoW's engine to fall back to the
  -- texture's intrinsic dimensions instead of rendering 0px wide (observed as a
  -- screen-wide bar fill on dead targets where value=0). Hide the overlay outright.
  if barW <= 0 or barH <= 0 or f <= 0 then
    overlay:Hide()
  else
    overlay:Show()
    overlay:SetSize(barW * f, barH)
    local atlasW = a.right - a.left
    overlay:SetTexCoord(a.left, a.left + atlasW * f, a.top, a.bottom)
  end
  -- Belt-and-suspenders: keep engine bar texture invisible in case any Era code path
  -- (SetStatusBarColor with 4-arg alpha, etc.) resets it.
  local engineTex = bar:GetStatusBarTexture()
  if engineTex then engineTex:SetAlpha(0) end
  -- Force overlay vertex-color alpha to 1 every tick. Era's
  -- CompactUnitFrame_UpdateHealthColor calls SetStatusBarColor(r,g,b) with 3 args,
  -- which preserves whatever alpha was last set on the bar texture — and that
  -- alpha was 0 by the time our hook landed, so the overlay inherited 0.
  -- Reading the overlay's own vc and re-setting alpha=1 is cheap and robust
  -- regardless of what code path mutated the color.
  local ovR, ovG, ovB = overlay:GetVertexColor()
  if ovR then overlay:SetVertexColor(ovR, ovG, ovB, 1) end
end
EJ.tex._updateAtlasOverlay = updateAtlasOverlay  -- exposed for diagnostics

-- Set of StatusBars whose overlays we maintain. A central updater walks them every
-- render tick as belt-and-suspenders against any path we don't hook (e.g., a SetValue
-- called from C code via secure handlers).
EJ.tex.atlasBars = EJ.tex.atlasBars or {}

local atlasUpdater
local function ensureAtlasUpdater()
  if atlasUpdater then return end
  atlasUpdater = CreateFrame("Frame")
  atlasUpdater:SetScript("OnUpdate", function()
    for bar in pairs(EJ.tex.atlasBars) do
      updateAtlasOverlay(bar)
    end
  end)
end

function EJ.tex.SetAtlasOnStatusBar(bar, name, filterMode)
  if not (bar and name) then return false end
  local entry = EJ_ATLAS and EJ_ATLAS[name:lower()]
  if not entry then
    if EJ.Log then EJ.Log("ATLAS", "MISS atlas " .. tostring(name)) end
    return false
  end
  local source = (entry.path or EJ.tex.localFiles[entry.file]) or entry.file

  -- Engine bar texture: still set so SetValue/min-max math works and child segments
  -- (heal prediction etc.) can anchor to GetStatusBarTexture's right edge. We don't
  -- bother setting texcoord — engine will overwrite — instead hide it via alpha=0.
  bar:SetStatusBarTexture(source)
  local engineTex = bar:GetStatusBarTexture()
  if engineTex then
    engineTex:SetAlpha(0)
    -- Same filterMode fix as SetAtlas — see comment there.
    if engineTex.SetTexture then engineTex:SetTexture(source, nil, nil, filterMode or "LINEAR") end
  end

  -- Visible overlay we fully control. Pinned at one corner (TOPLEFT) only — DUAL
  -- anchors of TOPLEFT+BOTTOMLEFT leave width undefined and the texture falls back
  -- to its intrinsic BLP sheet width (1024), ignoring SetSize. With a single anchor,
  -- SetSize is authoritative. Re-anchor unconditionally because /reload preserves
  -- the texture object (Lua tables persist across reload) with whatever anchors
  -- were in effect before. ARTWORK sublevel 0 (same as engine bar, but created
  -- later so renders above by creation order; heal prediction Fill sits at sublevel
  -- 1, above us).
  if not bar._ejOverlay then
    bar._ejOverlay = bar:CreateTexture(nil, "ARTWORK", nil, 0)
  end
  bar._ejOverlay:ClearAllPoints()
  bar._ejOverlay:SetPoint("TOPLEFT", bar, "TOPLEFT", 0, 0)
  bar._ejOverlay:SetTexture(source, nil, nil, filterMode or "LINEAR")
  EJ.tex.SmoothBarTex(bar._ejOverlay)   -- retail-parity: no pixel-grid snap on bar fills
  bar._ejAtlas = { left = entry.left, right = entry.right, top = entry.top, bottom = entry.bottom }
  bar._ejOverlayAtlasName = name  -- remembered so callers can restore after a flat-color swap
  EJ.tex.atlasBars[bar] = true
  ensureAtlasUpdater()

  -- Script hooks update the overlay on value/range changes. Combined with the central
  -- OnUpdate, this is fully reactive — but unlike the texcoord-on-internal-texture
  -- approach, the overlay's texcoord doesn't get clobbered by the engine's layout pass.
  if not bar._ejAtlasValueHooked then
    bar._ejAtlasValueHooked = true
    bar:HookScript("OnValueChanged",  updateAtlasOverlay)
    bar:HookScript("OnMinMaxChanged", updateAtlasOverlay)
    bar:HookScript("OnSizeChanged",   updateAtlasOverlay)
    hooksecurefunc(bar, "SetValue",        function(self) updateAtlasOverlay(self) end)
    hooksecurefunc(bar, "SetMinMaxValues", function(self) updateAtlasOverlay(self) end)
    -- Mirror SetStatusBarColor's tint onto the overlay. Force alpha to 1:
    -- the engine bar texture's alpha is 0 (we hide it that way), so
    -- GetStatusBarColor() returns that 0 in the 4th slot — but the OVERLAY is
    -- what carries the visible fill and must stay opaque. Bug symptom: bar
    -- fill renders red-but-alpha-0 → invisible. (Lua trap: `0 or 1` is 0, not 1.)
    hooksecurefunc(bar, "SetStatusBarColor", function(self, r, g, b)
      if self._ejOverlay then self._ejOverlay:SetVertexColor(r or 1, g or 1, b or 1, 1) end
    end)
    local cr, cg, cb = bar:GetStatusBarColor()
    if cr then bar._ejOverlay:SetVertexColor(cr, cg, cb, 1) end
  end
  updateAtlasOverlay(bar)
  return true
end

-- Convenience: returns true if the atlas exists in EJ_ATLAS (regardless of whether we
-- have a local copy of its sheet).
function EJ.tex.HasAtlas(name)
  if not name then return false end
  if EJ_ATLAS and EJ_ATLAS[name:lower()] ~= nil then return true end
  -- 3.3.5 bridge: also report atlases registered with !!!ClassicAPI's C_Texture (see SetAtlas).
  return (C_Texture and C_Texture.GetAtlasExists and C_Texture.GetAtlasExists(name)) or false
end

-- The retail aura debuff-border crop (UI-Debuff-Overlays, the rounded square frame retail tints by
-- dispel type). One source for the texture path + the exact texcoords, shared by the party + raid +
-- unit-frame aura cells so the crop can't drift. Tint via SetVertexColor afterwards.
function EJ.tex.DebuffBorder(tex)
  if not tex then return end
  tex:SetTexture("Interface\\Buttons\\UI-Debuff-Overlays")
  tex:SetTexCoord(0.296875, 0.5703125, 0, 0.515625)
end

-- Uniform spell/item icon zoom-crop (EJ.tex.CropIcon). Era's legacy 64px icon art bakes a border
-- ring into the texture, and the ring's width/style is INCONSISTENT across icons (thick gold, thin
-- grey, none). Modern retail icons are borderless — the frame draws the one border — so showing Era
-- icons at 0–1 texcoords reveals their baked rings inside our retail-style chrome, double-bordered and
-- mismatched. Cropping an 8% inset (the ElvUI/Masque "Zoomed" standard) hides the ring so every icon
-- shows only its art, with the frame supplying the single consistent border. SetTexCoord persists
-- across SetTexture, so this is set-once at icon-region creation — no per-update re-apply. Composes
-- with corner MaskTextures (the crop selects the source sub-rect; the mask rounds the displayed quad).
local ICON_CROP = 0.08
EJ.tex.ICON_CROP = ICON_CROP
function EJ.tex.CropIcon(tex, inset)
  if not tex or not tex.SetTexCoord then return end
  local i = inset or ICON_CROP
  tex:SetTexCoord(i, 1 - i, i, 1 - i)
end

-- Modern per-dispel-type debuff border (retail AuraUtil.SetAuraBorderAtlas, Mainline/AuraUtil.lua:20):
-- a PRE-COLOURED atlas, NOT a vertex tint. `showDispel` picks the `-icon` (dispel-symbol) variant over
-- the plain `-noicon` glow. Clears any inherited tint to white so the art isn't double-coloured.
-- One source for the dispel→atlas mapping, shared by the standalone DebuffFrame + every unit-frame
-- aura cell so the border can't drift (supersedes the legacy tinted DebuffBorder above on those cells).
-- Caller owns size/anchor (the modern art is a ~1.33x glow centred on the icon — see each frame).
EJ.tex.DISPEL_BORDER = {
  Magic   = { basic = "ui-debuff-border-magic-noicon-2x",   dispel = "ui-debuff-border-magic-icon-2x" },
  Curse   = { basic = "ui-debuff-border-curse-noicon-2x",   dispel = "ui-debuff-border-curse-icon-2x" },
  Disease = { basic = "ui-debuff-border-disease-noicon-2x", dispel = "ui-debuff-border-disease-icon-2x" },
  Poison  = { basic = "ui-debuff-border-poison-noicon-2x",  dispel = "ui-debuff-border-poison-icon-2x" },
  Bleed   = { basic = "ui-debuff-border-bleed-noicon-2x",   dispel = "ui-debuff-border-bleed-icon-2x" },
}
local DISPEL_BORDER_NONE = "ui-debuff-border-default-noicon-2x"  -- nil/"" type (no -icon variant)
function EJ.tex.DispelBorder(border, debuffType, showDispel)
  if not border then return false end
  local info  = EJ.tex.DISPEL_BORDER[debuffType or ""]
  local atlas = info and ((showDispel and info.dispel) or info.basic) or DISPEL_BORDER_NONE
  border:SetVertexColor(1, 1, 1)
  if EJ.tex.SetAtlas(border, atlas, false) then border:Show(); return true end
  return false
end

-- The bags auto-sort / cleanup button face (bags-button-autosort up/down). Creates + assigns the
-- Normal + Pushed textures filling the button; caller owns size/anchor/highlight/OnClick (the bag,
-- combined-bag, and bank cleanup buttons share this face but keep their own highlight art).
function EJ.tex.AutoSortButton(btn)
  if not btn then return end
  local n = btn:CreateTexture(nil, "ARTWORK")
  EJ.tex.SetAtlas(n, "bags-button-autosort-up", false); n:SetAllPoints(btn); btn:SetNormalTexture(n)
  local p = btn:CreateTexture(nil, "ARTWORK")
  EJ.tex.SetAtlas(p, "bags-button-autosort-down", false); p:SetAllPoints(btn); btn:SetPushedTexture(p)
end
