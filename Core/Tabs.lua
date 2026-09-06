-- Core/Tabs.lua — the Dragonflight metal reskin for classic CharacterFrameTabButtonTemplate tabs
-- (the journal's Dungeons / Raids bottom tabs). Ported from DragonUI_NewEra/core/Tabs.lua.
--
-- The 6-piece classic tab template (Left/Middle/Right + *Disabled) is the same vanilla template on
-- 3.3.5a, so the reskin is a texture swap: every piece is re-pointed at the uiframe-tab /
-- uiframe-activetab atlases (sheet 4707839, coords in Core/AtlasData.lua) and re-anchored so the
-- caps overshoot the tab edges the way retail's art expects. The classic highlight is replaced by
-- a dim additive copy of the inactive art. Which of the two piece sets is visible (tab vs
-- activetab) is driven by the CALLER — the journal shows the *Disabled set on the selected tab and
-- the plain set on the others (see EncounterJournal.lua setTabArt) — because PanelTemplates'
-- Select/Deselect also re-anchors text and heights in ways that fight the custom sizing.
--
-- USAGE
--   EJ.tabs.ReskinClassicTab("EJ_EJDungeonsTab")
--   EJ.tabs.SizeToText(tab)          -- width = text + 24, min 70
--   EJ.tabs.SetActive(tab, bool)     -- swap art set + highlight alpha

EJ = EJ or {}
EJ.tabs = EJ.tabs or {}

local ATLAS_BY_SUFFIX = {
  Left           = "uiframe-tab-left",
  Right          = "uiframe-tab-right",
  Middle         = "_uiframe-tab-center",
  LeftDisabled   = "uiframe-activetab-left",
  RightDisabled  = "uiframe-activetab-right",
  MiddleDisabled = "_uiframe-activetab-center",
}

local SIZE_BY_SUFFIX = {
  Left           = { w = 35, h = 36 },
  Right          = { w = 37, h = 36 },
  Middle         = { h = 36 },
  LeftDisabled   = { w = 35, h = 42 },
  RightDisabled  = { w = 37, h = 42 },
  MiddleDisabled = { h = 42 },
}

EJ.tabs.H_INACTIVE, EJ.tabs.H_ACTIVE = 36, 42

local function setAtlas(tex, atlas)
  return tex and EJ.tex and EJ.tex.SetAtlas and EJ.tex.SetAtlas(tex, atlas, false)
end

-- The classic template's HIGHLIGHT is the wooden glow; replace it with a dim additive copy of the
-- inactive metal art so hovering an inactive tab lights it, and the active tab (alpha 0) stays put.
local function buildCustomHighlight(tab)
  if tab._ejCustomHL then return end
  local existing = tab.GetHighlightTexture and tab:GetHighlightTexture()
  if existing then existing:SetTexture(nil); existing:Hide() end

  local n = tab:GetName()
  local left, right = _G[n .. "Left"], _G[n .. "Right"]
  if not (left and right) then return end

  local hlLeft = tab:CreateTexture(nil, "HIGHLIGHT")
  if not setAtlas(hlLeft, "uiframe-tab-left") then hlLeft:Hide(); return end
  hlLeft:SetSize(35, 36)
  hlLeft:SetPoint("TOPLEFT", left, "TOPLEFT", 0, 0)
  hlLeft:SetBlendMode("ADD"); hlLeft:SetAlpha(0.4)

  local hlRight = tab:CreateTexture(nil, "HIGHLIGHT")
  setAtlas(hlRight, "uiframe-tab-right")
  hlRight:SetSize(37, 36)
  hlRight:SetPoint("TOPRIGHT", right, "TOPRIGHT", 0, 0)
  hlRight:SetBlendMode("ADD"); hlRight:SetAlpha(0.4)

  local hlMiddle = tab:CreateTexture(nil, "HIGHLIGHT")
  setAtlas(hlMiddle, "_uiframe-tab-center")
  hlMiddle:SetHorizTile(true)
  hlMiddle:SetHeight(36)
  hlMiddle:SetPoint("TOPLEFT",  hlLeft,  "TOPRIGHT", 0, 0)
  hlMiddle:SetPoint("TOPRIGHT", hlRight, "TOPLEFT",  0, 0)
  hlMiddle:SetBlendMode("ADD"); hlMiddle:SetAlpha(0.4)

  tab._ejCustomHL = { left = hlLeft, middle = hlMiddle, right = hlRight }
end

-- Reskin one tab in place. Returns true on success (false = the art isn't registered, so the tab
-- keeps its classic look and the caller's art toggling degrades to PanelTemplates' own).
function EJ.tabs.ReskinClassicTab(tabName)
  local tab = _G[tabName]
  if not tab or tab._ejTabReskinned then return tab and tab._ejTabReskinned or false end
  if not (EJ.tex and EJ.tex.AtlasEntry and EJ.tex.AtlasEntry("uiframe-tab-left")) then return false end

  for suffix, atlas in pairs(ATLAS_BY_SUFFIX) do
    local tex = _G[tabName .. suffix]
    if tex then
      setAtlas(tex, atlas)
      local sz = SIZE_BY_SUFFIX[suffix]
      if sz then
        if sz.w then tex:SetWidth(sz.w)  end
        if sz.h then tex:SetHeight(sz.h) end
      end
    end
  end

  local left, right, middle = _G[tabName .. "Left"], _G[tabName .. "Right"], _G[tabName .. "Middle"]
  local leftD, rightD, middleD = _G[tabName .. "LeftDisabled"], _G[tabName .. "RightDisabled"], _G[tabName .. "MiddleDisabled"]

  -- The caps overshoot the tab's own rect (retail's art has the rounded shoulders outside it).
  if left   then left:ClearAllPoints();   left:SetPoint("TOPLEFT",  tab, "TOPLEFT",  -3, 0) end
  if right  then right:ClearAllPoints();  right:SetPoint("TOPRIGHT", tab, "TOPRIGHT",  7, 0) end
  if leftD  then leftD:ClearAllPoints();  leftD:SetPoint("TOPLEFT",  tab, "TOPLEFT",  -1, 0) end
  if rightD then rightD:ClearAllPoints(); rightD:SetPoint("TOPRIGHT", tab, "TOPRIGHT",  8, 0) end
  if middle and left and right then
    middle:ClearAllPoints()
    middle:SetPoint("TOPLEFT",  left,  "TOPRIGHT", 0, 0)
    middle:SetPoint("TOPRIGHT", right, "TOPLEFT",  0, 0)
    middle:SetHorizTile(true)
  end
  if middleD and leftD and rightD then
    middleD:ClearAllPoints()
    middleD:SetPoint("TOPLEFT",  leftD,  "TOPRIGHT", 0, 0)
    middleD:SetPoint("TOPRIGHT", rightD, "TOPLEFT",  0, 0)
    middleD:SetHorizTile(true)
  end

  buildCustomHighlight(tab)
  tab._ejTabReskinned = true
  return true
end

-- Width from the label (text + 24, never under 70). Text measurement is unreliable while the
-- frame is hidden — callers re-run this from an OnShow hook.
function EJ.tabs.SizeToText(tab, minWidth, pad)
  if not tab then return end
  local text = _G[tab:GetName() .. "Text"]
  local w = minWidth or 70
  if text then text:SetWidth(0); w = math.max(w, math.floor((text:GetWidth() or 0) + (pad or 24))) end
  tab:SetWidth(w)
end

-- Selected → the gold "activetab" set (taller, raised); unselected → the plain metal set. Also
-- moves the label (active text sits 3px lower, like retail) and mutes the hover glow on the
-- active tab.
function EJ.tabs.SetActive(tab, selected)
  if not tab then return end
  local n = tab:GetName()
  local function show(suffix, on)
    local t = _G[n .. suffix]
    if t then if on then t:Show() else t:Hide() end end
  end
  show("Left",  not selected); show("Middle",  not selected); show("Right",  not selected)
  show("LeftDisabled", selected); show("MiddleDisabled", selected); show("RightDisabled", selected)
  tab:SetHeight(selected and EJ.tabs.H_ACTIVE or EJ.tabs.H_INACTIVE)
  local hl = tab._ejCustomHL
  if hl then
    local a = selected and 0 or 0.4
    hl.left:SetAlpha(a); hl.middle:SetAlpha(a); hl.right:SetAlpha(a)
  end
  local txt = _G[n .. "Text"]
  if txt then txt:ClearAllPoints(); txt:SetPoint("CENTER", tab, "CENTER", 0, selected and -3 or 0) end
end
