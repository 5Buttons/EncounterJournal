-- Addon/Core/ItemButton.lua — shared item-rarity (quality) border coloring.
--
-- Retail draws a colored frame around every item button (bags, paperdoll,
-- merchant, mail, bank, trade, loot, quest rewards, tooltip, static popups,
-- equipment flyout) through ONE global: SetItemButtonQuality. It tints the
-- button's `IconBorder` texture (Interface\Common\WhiteIconFrame, OVERLAY) by
-- quality — see retail Blizzard_ItemButton/Mainline/ItemButtonTemplate.lua:210
-- (SetItemButtonQuality_Base) + ColorManager.GetColorDataForBagItemQuality.
--
-- Era ships the WHOLE pipeline (the IconBorder texture on every ItemButton,
-- BAG_ITEM_QUALITY_COLORS, C_Item.GetItemQualityColor) but DELIBERATELY
-- neutered the one function: era Blizzard_ItemButton/Classic/ItemButtonTemplate
-- .lua:116-135 comments out the coloring body and ends with an unconditional
-- `button.IconBorder:Hide()` ("No quality borders for Classic"). Every native
-- caller (bank :128, mail :195/443/896, trade :106/156, quest rewards :555+,
-- native bags ContainerFrame_Shared:558, tooltip, static popups, equipment
-- flyout) still CALLS it — they just hit the no-op.
--
-- So we resurrect it with ONE hooksecurefunc: Era's no-op runs (hides the
-- border), our post-hook re-colors. Result: every native + addon caller lights
-- up for free, with zero new call sites. Why hooksecurefunc and not an
-- overwrite (Hard Rule #4): the hook is taint-contained, so it can't taint the
-- secure bag/bank/merchant item buttons it runs on; and it only touches
-- IconBorder — a Texture region no secure code reads, whose Show/Hide +
-- SetVertexColor are NOT protected actions — so it is safe even in combat.
--
-- Color policy (user-confirmed, retail-exact): use BAG_ITEM_QUALITY_COLORS,
-- which maps Common(1)->gray (border SHOWN, faint) and has no Poor(0) entry
-- (border hidden). Identical to retail's GetColorDataForBagItemQuality. Empty
-- slots pass quality=nil -> hidden.

local EJ = EJ
EJ.itembtn = EJ.itembtn or {}
local M = EJ.itembtn

-- SHIPPED retail art (FDID 651080), not the client path: Era never renders WhiteIconFrame
-- natively (its only consumer is the neutered SetItemButtonQuality), and in-client probing
-- (2026-06-10, quest rewards: border shown=true, quality-tinted, OVERLAY — yet nothing painted)
-- showed Era's CASC copy renders no pixels. Same-FDID-≠-same-art, the path edition: ship the
-- modern file and reference it directly.
local WHITE_FRAME = [[Interface\AddOns\EncounterJournal\Art\Common\651080-whiteiconframe.blp]]
M.WHITE_FRAME = WHITE_FRAME   -- shared with the EJ loot rows (the client path draws nothing on 3.3.5)

-- The quality->color source. BAG_ITEM_QUALITY_COLORS (era Constants.lua:69) is
-- the retail-faithful table: Common is a gray (shown), Poor is absent (hidden).
local function colorFor(quality)
  if not quality then return nil end
  return BAG_ITEM_QUALITY_COLORS and BAG_ITEM_QUALITY_COLORS[quality]
end

-- Apply the quality border to one button's IconBorder. Safe on any button
-- carrying an IconBorder texture (ItemButtonTemplate + every descendant). No-op
-- on buttons without one (returns quietly).
function M.ApplyQuality(button, quality)
  if not button then return end
  local b = button.IconBorder
  if not b and button.GetName and button:GetName() then
    b = _G[button:GetName() .. "IconBorder"]
  end
  if not b then return end

  local c = colorFor(quality)
  if c then
    b:SetTexture(WHITE_FRAME)
    b:SetVertexColor(c.r, c.g, c.b)
    b:Show()
  else
    b:Hide()
  end
end

-- Resurrect the neutered global. Era's Blizzard_ItemButton loads before any
-- addon, so SetItemButtonQuality exists at parse time. The post-hook runs after
-- Era's no-op (which leaves IconBorder hidden), re-coloring per the real quality.
if SetItemButtonQuality then
  hooksecurefunc("SetItemButtonQuality", function(button, quality)
    M.ApplyQuality(button, quality)
  end)
end

-- Normalize Era's inconsistent baked ITEM icon borders (8% zoom). SetItemButtonTexture is the single
-- global every item button (bags, bank, merchant, character, equipment flyout, loot, …) routes its
-- icon through, so one post-hook crops them all. Idempotent — SetTexCoord persists across SetTexture,
-- so re-applying on each call is free. Icon resolved exactly as Era does (ItemButtonTemplate.lua:48).
if SetItemButtonTexture and EJ.tex and EJ.tex.CropIcon then
  hooksecurefunc("SetItemButtonTexture", function(button)
    if not button then return end
    local icon = button.Icon or button.icon or (button.GetName and button:GetName() and _G[button:GetName() .. "IconTexture"])
    EJ.tex.CropIcon(icon)
  end)
end

-- Quality TEXT coloring — reads ITEM_QUALITY_COLORS (the brighter text table, the
-- one with .hex), NOT the BAG_ITEM_QUALITY_COLORS border table above. Two tables,
-- two retail policies: borders mute Common to gray and hide Poor; text colors every
-- quality at full saturation. Shared by the AH lists, loot frames, EJ loot, quest
-- rewards, merchant — anywhere an item NAME is colored by rarity.

-- The {r, g, b, hex} entry for a quality, or nil (nil quality / table absent).
-- Callers keep their own fallback (white vs NORMAL_FONT_COLOR vs no-op) — those
-- divergences mirror the different retail frames, don't normalize them.
function M.TextColor(quality)
  return quality and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality] or nil
end

-- Wrap an item name in its quality's hex color escape ("|cff...name|r").
-- Unknown/uncolorable quality returns the name unwrapped.
function M.WrapTextByQuality(name, quality)
  local c = M.TextColor(quality)
  if c and c.hex then return c.hex .. (name or "") .. "|r" end
  return name or ""
end
