-- Addon/Core/Portrait.lua — shared masked portrait cutout for PortraitFrameTemplate
-- panels. Drops a square portrait texture into the nineslice corner cutout with a
-- circular TempPortraitAlphaMask, at the geometry verified-good on CharacterFrame
-- (retail PortraitFrameBaseTemplate, SharedUIPanelTemplates.xml:551-575).
--
-- Extracted verbatim from CharacterPanel/Portrait.lua `applyPortraitGeometry` and
-- BankFrame.lua `modernizePortrait` (the BankFrame copy literally said "copied
-- verbatim from CharacterPanel/Portrait.lua"). Both bodies were geometry-identical;
-- this is the single source of truth.
--
-- Caller still owns WHAT the portrait shows (NPC face / class icon / asset) — this
-- helper only does geometry + circular mask + draw layer.
--
-- USAGE
--   EJ.portrait.ApplyCutout(_G.CharacterFramePortrait, _G.CharacterFrame)
--   EJ.portrait.ApplyCutout(_G.BankPortraitTexture,    _G.BankFrame)
--
-- opts (all optional):
--   size     default 62
--   anchor   default { "TOPLEFT", -5, 7 }  -- {point, x, y}; point on tex = relPoint on parent
--   layer    default "ARTWORK"  -- above BORDER streaks, below the OVERLAY metal corner
--   sublevel default nil        -- draw-layer sublevel (held-bag portraits use BACKGROUND/5)
--   mask     default true       -- false to skip the TempPortraitAlphaMask circular clip
--   maskInset default {2,0,-2,4} -- {tlX, tlY, brX, brY} circle inset from the tex edges. The
--                                   62px PortraitFrame cutout uses the default; the 36px
--                                   held-bag portrait uses {1,0,-1,2} (the same inset scaled).
--
-- Idempotent: guarded by tex._ejCutout. The created mask is exposed as tex._ejMask
-- (preserves the field both original call sites set, so dependent code keeps working).

EJ = EJ or {}
EJ.portrait = EJ.portrait or {}

local MASK_TEX = "Interface\\CharacterFrame\\TempPortraitAlphaMask"

function EJ.portrait.ApplyCutout(tex, parent, opts)
  if not tex or not parent then return end
  if tex._ejCutout then return end
  opts = opts or {}

  local size   = opts.size  or 62
  local layer  = opts.layer or "ARTWORK"
  local anchor = opts.anchor or { "TOPLEFT", -5, 7 }
  local point  = anchor[1]
  local mi     = opts.maskInset or { 2, 0, -2, 4 }

  tex:ClearAllPoints()
  tex:SetPoint(point, parent, point, anchor[2], anchor[3])
  tex:SetSize(size, size)
  -- Draw layer. The nineslice corners (incl. the PortraitMetal corner with its
  -- circular cutout) sit at OVERLAY; TopTileStreaks at BORDER. ARTWORK is the
  -- layer between, so the corner's portrait cutout frames the icon instead of
  -- being covered by it.
  tex:SetDrawLayer(layer, opts.sublevel)

  -- Circle mask. Era exposes Frame:CreateMaskTexture + Texture:AddMaskTexture.
  -- TempPortraitAlphaMask is a vanilla-era asset (used by the original character
  -- frame's portrait clipping); resolves via path on Era.
  if opts.mask ~= false and tex.AddMaskTexture and parent.CreateMaskTexture and not tex._ejMask then
    -- ClassicAPI exposes CreateMaskTexture as a method but its stub RETURNS NIL (mask textures
    -- are a no-op on 3.3.5a), so guard the result — otherwise mask:SetTexture errors and aborts
    -- the whole window build. Without the mask the portrait is an unclipped square (the known,
    -- non-fatal cosmetic gap), not a crash.
    local mask = parent:CreateMaskTexture()
    if mask then
      -- 3-arg SetTexture: file, hWrapMode, vWrapMode.
      mask:SetTexture(MASK_TEX, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
      mask:SetPoint("TOPLEFT",     tex, "TOPLEFT",     mi[1], mi[2])
      mask:SetPoint("BOTTOMRIGHT", tex, "BOTTOMRIGHT", mi[3], mi[4])
      tex:AddMaskTexture(mask)
      tex._ejMask = mask
    end
  end

  tex._ejCutout = true
end
