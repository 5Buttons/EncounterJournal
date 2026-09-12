-- Addon/Core/NavBar.lua — shared breadcrumb NavBar helper, reimplemented for 3.3.5a, with TWO
-- skins (read from EJ.skin at build time):
--
--   CLASSIC (default) — the authentic Encounter Journal breadcrumb: a dark tiled bar (CS_Help
--     textures), a HOME button with a shadow-overlay cap, overlapping "tab" crumbs joined by ">"
--     arrows, a ▾ menu-arrow on crumbs that offer a jump list, and an overflow ▾ when the crumbs
--     don't fit. Ported from the Ascension EJ's 3.3.5-native EJ_NavBarTemplate
--     (EncounterJournal-main/Frames/NavigationBar/NavigationBar.xml) — art copied to Art/NavBar/.
--
--   DRAGONFLIGHT — the plain-text breadcrumb ([Home] › [Crumb] › [Crumb ▾]) kept from the
--     original port; a differentiated, lighter-weight variant.
--
-- 3.3.5a has NO NavBarTemplate / NavButtonTemplate (Cata+ FrameXML; ClassicAPI doesn't ship them),
-- so both skins are built from plain Buttons + textures here.
--
-- USAGE (unchanged across skins — the EncounterJournal/Search.lua consumer doesn't branch):
--   local navBar = EJ.navbar.Build(parent, {
--     name = "EJ_FooNavBar", home = { name = HOME, OnClick = fn }, strata = , frameLevel = ,
--   })
--   navBar:SetPoint(...); navBar:SetSize(...)
--   EJ.navbar.Refresh(navBar, { { name=, id=, OnClick=, listFunc= }, ... })

EJ = EJ or {}
EJ.navbar = EJ.navbar or {}

-- True unless the user explicitly selected the Dragonflight skin (classic is the default/fallback).
local function classicSkin()
  return not (EJ.skin and EJ.skin.Is and EJ.skin.Is(EJ.skin.DRAGONFLIGHT))
end

-- ===========================================================================================
--  Shared: inset border (ui-frame-inner* @ BORDER/-5) — mirrors retail WorldMapNavBarTemplate.
-- ===========================================================================================
function EJ.navbar.BuildInsetBorder(navBar)
  if not navBar or navBar._ejInsetBorder then return navBar and navBar._ejInsetBorder end
  if not (EJ.tex and EJ.tex.SetAtlas) then return end

  local bl = navBar:CreateTexture(nil, "BORDER", nil, -5)
  EJ.tex.SetAtlas(bl, "ui-frame-innerbotleftcorner", false); bl:SetSize(6, 6)
  bl:SetPoint("BOTTOMLEFT", navBar, "BOTTOMLEFT", -3, -3)

  local br = navBar:CreateTexture(nil, "BORDER", nil, -5)
  EJ.tex.SetAtlas(br, "ui-frame-innerbotright", false); br:SetSize(6, 6)
  br:SetPoint("BOTTOMRIGHT", navBar, "BOTTOMRIGHT", 3, -3)

  local bot = navBar:CreateTexture(nil, "BORDER", nil, -5)
  EJ.tex.SetAtlas(bot, "_ui-frame-innerbottile", false); bot:SetHorizTile(true); bot:SetHeight(3)
  bot:SetPoint("BOTTOMLEFT", bl, "BOTTOMRIGHT", 0, 0)
  bot:SetPoint("BOTTOMRIGHT", br, "BOTTOMLEFT", 0, 0)

  local lt = navBar:CreateTexture(nil, "BORDER", nil, -5)
  EJ.tex.SetAtlas(lt, "!ui-frame-innerlefttile", false); lt:SetVertTile(true); lt:SetWidth(3)
  lt:SetPoint("TOPLEFT", navBar, "TOPLEFT", -3, 0)
  lt:SetPoint("BOTTOMLEFT", bl, "TOPLEFT", 0, 0)

  local rt = navBar:CreateTexture(nil, "BORDER", nil, -5)
  EJ.tex.SetAtlas(rt, "!ui-frame-innerrighttile", false); rt:SetVertTile(true); rt:SetWidth(3)
  rt:SetPoint("TOPRIGHT", navBar, "TOPRIGHT", 3, 0)
  rt:SetPoint("BOTTOMRIGHT", br, "TOPRIGHT", 0, 0)

  navBar._ejInsetBorder = { bottomLeft = bl, bottomRight = br, bottom = bot, left = lt, right = rt }
  return navBar._ejInsetBorder
end

-- ===========================================================================================
--  CLASSIC skin — authentic CS_Help breadcrumb.
-- ===========================================================================================
local ART = "Interface\\AddOns\\EncounterJournal\\Art\\NavBar\\"
local CS, CST = ART .. "CS_HelpTextures", ART .. "CS_HelpTextures_Tile"
-- texcoords transcribed verbatim from NavigationBar.xml (SetTexCoord(left, right, top, bottom)).
local C = {
  barBG     = { 0, 1, 0.18750000, 0.25390625 },   -- navbar background (tiled)
  barShade  = { 0, 1, 0.25781250, 0.32421875 },   -- subtle overlay gradient (tiled)
  btnUp     = { 0, 1, 0.06250000, 0.12109375 },   -- nav button body (tiled)
  btnDown   = { 0, 1, 0.12500000, 0.18359375 },   -- nav button pushed (tiled)
  btnHi     = { 0.00195313, 0.25195313, 0.65625000, 0.92187500 },
  arrowUp   = { 0.88867188, 0.92968750, 0.29687500, 0.53125000 },  -- ">" joiner
  arrowDown = { 0.63281250, 0.67382813, 0.75781250, 0.99218750 },
  selected  = { 0.00195313, 0.25195313, 0.37500000, 0.64062500 },  -- current-crumb glow
  ovUp      = { 0.54296875, 0.62890625, 0.75781250, 0.99218750 },  -- overflow ▾ normal
  ovDown    = { 0.45312500, 0.53906250, 0.75781250, 0.99218750 },  -- overflow ▾ pushed
}
local NAV_H, ARROW_W = 30, 21
-- Per-button anchor offset for the NEXT crumb (retail `xoffset`, NavigationBar.xml OnLoad): only the
-- HOME button (-15, its tapered cap art overlaps the next crumb) and the OVERFLOW ▾ (-18) pull the
-- following crumb in. Plain NavButtons have NO xoffset (nil → 0): the next crumb starts exactly at
-- their right edge and the 21px ">" joiner (anchored off that edge) draws over the next crumb's
-- left 20px — which is why crumb labels sit at LEFT+20. Using -15 for every crumb (the old
-- port) shifted every crumb after the first 15px left, hiding the label's first letters under
-- the ">" and cutting the chain short (visible as soon as a boss crumb followed the instance).
local HOME_XOFF, OVERFLOW_XOFF = -15, -18

-- The ▾ menu-arrow sub-button (UI-SquareButton art) shown on crumbs that offer a jump list.
local function makeMenuArrow(b)
  local mb = CreateFrame("Button", nil, b)
  mb:SetSize(27, 31)
  mb:SetPoint("RIGHT", b, "TOPRIGHT", -2, -15)
  mb:SetFrameLevel(b:GetFrameLevel() + 2)
  local nt = mb:CreateTexture(nil, "ARTWORK"); nt:SetTexture(ART .. "UI-SquareButton-Up");   nt:SetSize(32, 32); nt:SetPoint("CENTER"); nt:SetAlpha(0); mb._nt = nt
  local pt = mb:CreateTexture(nil, "ARTWORK"); pt:SetTexture(ART .. "UI-SquareButton-Down"); pt:SetSize(32, 32); pt:SetPoint("CENTER"); pt:SetAlpha(0); mb._pt = pt
  local hl = mb:CreateTexture(nil, "HIGHLIGHT"); hl:SetTexture(ART .. "UI-Common-MouseHilight"); hl:SetBlendMode("ADD"); hl:SetSize(32, 32); hl:SetPoint("CENTER")
  local art = mb:CreateTexture(nil, "OVERLAY"); art:SetTexture(ART .. "SquareButtonTextures"); art:SetSize(12, 12); art:SetPoint("CENTER", 0, -1)
  art:SetTexCoord(0.45312500, 0.64062500, 0.20312500, 0.01562500); mb._art = art   -- ▾ (v-flipped)
  mb:SetScript("OnEnter", function(self) self._nt:SetAlpha(1) end)
  mb:SetScript("OnLeave", function(self) self._nt:SetAlpha(0); self._pt:SetAlpha(0) end)
  mb:SetScript("OnMouseDown", function(self) self._pt:SetAlpha(1); self._art:SetPoint("CENTER", -1, -2) end)
  mb:SetScript("OnMouseUp",   function(self) self._pt:SetAlpha(0); self._art:SetPoint("CENTER", 0, -1) end)
  return mb
end

-- Apply the nav-button skin (tiled body + ">" arrows + selected glow) to a pooled Button.
local function styleNavButton(b)
  local n = b:CreateTexture(nil, "BACKGROUND"); n:SetTexture(CST); n:SetHorizTile(true); n:SetAllPoints(b); n:SetTexCoord(unpack(C.btnUp));   b:SetNormalTexture(n)
  local p = b:CreateTexture(nil, "BACKGROUND"); p:SetTexture(CST); p:SetHorizTile(true); p:SetAllPoints(b); p:SetTexCoord(unpack(C.btnDown)); b:SetPushedTexture(p)
  local h = b:CreateTexture(nil, "HIGHLIGHT"); h:SetTexture(CS); h:SetBlendMode("ADD"); h:SetAllPoints(b); h:SetTexCoord(unpack(C.btnHi)); b:SetHighlightTexture(h)

  -- ">" joiner: two textures (up/down) anchored just off the right edge; arrowDown flashes on press.
  b.arrowUp = b:CreateTexture(nil, "OVERLAY"); b.arrowUp:SetTexture(CS); b.arrowUp:SetSize(ARROW_W, NAV_H)
  b.arrowUp:SetPoint("LEFT", b, "RIGHT", 0, 0); b.arrowUp:SetTexCoord(unpack(C.arrowUp))
  b.arrowDown = b:CreateTexture(nil, "OVERLAY"); b.arrowDown:SetTexture(CS); b.arrowDown:SetSize(ARROW_W, NAV_H)
  b.arrowDown:SetPoint("LEFT", b, "RIGHT", 0, 0); b.arrowDown:SetTexCoord(unpack(C.arrowDown)); b.arrowDown:Hide()

  -- current-crumb glow (shown on the last crumb only).
  b.sel = b:CreateTexture(nil, "OVERLAY"); b.sel:SetTexture(CS); b.sel:SetAllPoints(b); b.sel:SetTexCoord(unpack(C.selected)); b.sel:Hide()

  b.label = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  b.label:SetPoint("LEFT", b, "LEFT", 20, 0); b.label:SetJustifyH("LEFT")

  b:SetScript("OnMouseDown", function(self) if self:IsEnabled() then self.arrowUp:Hide(); self.arrowDown:Show() end end)
  b:SetScript("OnMouseUp",   function(self) self.arrowDown:Hide(); self.arrowUp:Show() end)
  return b
end

-- HOME button: shadow-overlay cap on the left + width-tapered CS_Help body texcoords.
local function buildClassicHome(navBar, opts)
  local b = CreateFrame("Button", (opts.name and opts.name .. "HomeButton") or nil, navBar)
  b:SetHeight(NAV_H)
  local n = b:CreateTexture(nil, "BACKGROUND"); n:SetTexture(CS); n:SetAllPoints(b); b:SetNormalTexture(n)
  local p = b:CreateTexture(nil, "BACKGROUND"); p:SetTexture(CS); p:SetAllPoints(b); b:SetPushedTexture(p)
  local h = b:CreateTexture(nil, "HIGHLIGHT"); h:SetTexture(CS); h:SetBlendMode("ADD"); h:SetAllPoints(b); b:SetHighlightTexture(h)
  local shadow = b:CreateTexture(nil, "OVERLAY"); shadow:SetTexture(ART .. "ShadowOverlay-Left"); shadow:SetSize(30, 30); shadow:SetPoint("LEFT", b, "LEFT", 0, 0)
  b.label = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  b.label:SetPoint("LEFT", b, "LEFT", 10, 0); b.label:SetPoint("RIGHT", b, "RIGHT", -16, 0); b.label:SetJustifyH("LEFT")
  b.label:SetText((opts.home and opts.home.name) or HOME or "Home")
  -- width-tapered texcoords (XML OnLoad recipe): wider text reveals more of the cap.
  local newWidth = math.min(128, b.label:GetStringWidth() + 50)
  local off = (newWidth / 128) * 0.25
  n:SetTexCoord(0.70312500 - off, 0.70312500, 0.00781250, 0.24218750)
  p:SetTexCoord(0.70312500 - off, 0.70312500, 0.25781250, 0.49218750)
  h:SetTexCoord(0.70312500 - off, 0.71312500, 0.50781250, 0.74218750)
  b:SetWidth(newWidth)
  b._xoffset = HOME_XOFF
  b._home = opts.home
  b:SetScript("OnClick", function() if b._home and b._home.OnClick then b._home.OnClick() end end)
  return b
end

-- The left-anchored overflow ▾ button: pops a menu of the crumbs that didn't fit.
local function getOverflowButton(navBar)
  if navBar._overflow then return navBar._overflow end
  local b = CreateFrame("Button", nil, navBar)
  b:SetSize(44, NAV_H)
  local n = b:CreateTexture(nil, "BACKGROUND"); n:SetTexture(CS); n:SetAllPoints(b); n:SetTexCoord(unpack(C.ovUp));   b:SetNormalTexture(n)
  local p = b:CreateTexture(nil, "BACKGROUND"); p:SetTexture(CS); p:SetAllPoints(b); p:SetTexCoord(unpack(C.ovDown)); b:SetPushedTexture(p)
  local h = b:CreateTexture(nil, "HIGHLIGHT"); h:SetTexture(CS); h:SetBlendMode("ADD"); h:SetAlpha(0.4); h:SetAllPoints(b); h:SetTexCoord(unpack(C.ovUp)); b:SetHighlightTexture(h)
  b._xoffset = OVERFLOW_XOFF
  navBar._overflow = b
  b:Hide()
  return b
end

local function getClassicCrumb(navBar, i)
  local b = navBar._crumbs[i]
  if b then return b end
  b = CreateFrame("Button", nil, navBar)
  b:SetHeight(NAV_H)
  styleNavButton(b)
  b._xoffset = 0                               -- plain NavButton: next crumb butts against our right edge
  b.menuArrow = makeMenuArrow(b); b.menuArrow:Hide()
  navBar._crumbs[i] = b
  return b
end

-- Lay out the home + crumb chain LEFT-to-RIGHT. Each button is anchored to its predecessor's
-- RIGHT edge shifted by the predecessor's `_xoffset` (Home -15 / overflow -18 / crumbs 0 — see
-- HOME_XOFF above; mirrors retail NavBar_CheckLength's `xoffset = navList[i].xoffset or 0`).
-- Home and the LAST (current) crumb are always shown; if the natural chain is wider than the
-- bar, the MIDDLE crumbs collapse into the overflow ▾ (it lists them as a jump menu). A
-- descending frame-level run makes each crumb's ">" joiner draw over its right-hand neighbour.
-- Overflow effectively never triggers in practice (≤4 short crumbs on a 500px bar) but is
-- handled for safety.
local function classicLayout(navBar)
  local list = navBar._navList                 -- { homeBtn, crumb1, crumb2, ... }
  local overflow = navBar._overflow
  local n = #list
  local maxWidth = (navBar:GetWidth() or 500) - 20

  -- Per-crumb state: only the last crumb is the "current" (selected glow, no joiner, disabled).
  for i, b in ipairs(list) do
    local isLast = (i == n)
    if b.sel then b.sel:SetShown(isLast and i > 1) end
    if b.arrowUp then b.arrowUp:SetShown(not isLast) end
    if b.arrowDown then b.arrowDown:Hide() end
    if b.Disable then if isLast then b:Disable() else b:Enable() end end
  end

  -- Decide which middle crumbs (2..n-1) fit. Home[1] + last[n] are always kept.
  local hidden = {}
  local visible = { list[1] }                  -- always starts with Home
  if n >= 2 then
    local used = list[1]:GetWidth() + list[n]:GetWidth()
    for i = 2, n - 1 do
      local b = list[i]
      if used + b:GetWidth() <= maxWidth then
        used = used + b:GetWidth()             -- retail sums plain widths (xoffsets ignored)
        visible[#visible + 1] = b
      else
        b:Hide()
        hidden[#hidden + 1] = { text = b.label:GetText(), func = b._jump }
      end
    end
  end

  -- Wire / place the overflow button (only when something collapsed).
  if overflow then
    if #hidden > 0 then
      overflow:Show()
      visible[#visible + 1] = overflow         -- sits between the kept middle crumbs and the tail
      overflow:SetScript("OnClick", function()
        if EJ.dropdown and EJ.dropdown.OpenMenu then EJ.dropdown.OpenMenu(overflow, hidden) end
      end)
    else
      overflow:Hide()
    end
  end
  if n >= 2 then visible[#visible + 1] = list[n] end   -- the current crumb, last

  -- Anchor the kept chain left-to-right; frame levels descend so joiners overlap correctly.
  local topLevel = navBar:GetFrameLevel() + #visible + 1
  local prev
  for i, b in ipairs(visible) do
    b:Show()
    b:ClearAllPoints()
    if prev then b:SetPoint("LEFT", prev, "RIGHT", prev._xoffset or 0, 0)
    else         b:SetPoint("LEFT", navBar, "LEFT", 0, 0) end
    b:SetFrameLevel(topLevel - i)
    prev = b
  end
end

local function classicRefresh(navBar, hierarchy)
  for _, b in ipairs(navBar._crumbs) do b:Hide() end
  local list = { navBar._homeBtn }

  if hierarchy then
    for i, d in ipairs(hierarchy) do
      local b = getClassicCrumb(navBar, i)
      b.label:SetText(d.name or "")
      local hasMenu = type(d.listFunc) == "function"
      b._jump = d.OnClick
      b:SetWidth(b.label:GetStringWidth() + (hasMenu and 53 or 30))
      b.menuArrow:SetShown(hasMenu)
      if hasMenu then
        b.menuArrow:SetScript("OnMouseDown", function(self)
          self._pt:SetAlpha(1); self._art:SetPoint("CENTER", -1, -2)
          if EJ.dropdown and EJ.dropdown.OpenMenu then EJ.dropdown.OpenMenu(self, d.listFunc()) end
        end)
      end
      b:SetScript("OnClick", function()
        if d.OnClick then d.OnClick()
        elseif hasMenu and EJ.dropdown and EJ.dropdown.OpenMenu then EJ.dropdown.OpenMenu(b, d.listFunc()) end
      end)
      b:Show()
      list[#list + 1] = b
    end
  end

  navBar._navList = list
  classicLayout(navBar)
end

-- ===========================================================================================
--  DRAGONFLIGHT skin — plain-text breadcrumb (the original port).
-- ===========================================================================================
local DF_CRUMB_H, DF_ARROW_W = 22, 14

local function dfGetSep(navBar, i)
  local s = navBar._seps[i]
  if s then return s end
  s = navBar:CreateFontString(nil, "OVERLAY", "GameFontDisable")
  s:SetText("›"); navBar._seps[i] = s
  return s
end

local function dfGetCrumb(navBar, i)
  local b = navBar._crumbs[i]
  if b then return b end
  b = CreateFrame("Button", nil, navBar)
  b:SetHeight(DF_CRUMB_H)
  b.label = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  b.label:SetPoint("LEFT", b, "LEFT", 4, 0); b.label:SetTextColor(1, 0.82, 0)
  local hl = b:CreateTexture(nil, "HIGHLIGHT"); hl:SetAllPoints(b)
  hl:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight"); hl:SetBlendMode("ADD"); hl:SetAlpha(0.35)
  b.arrow = CreateFrame("Button", nil, b)
  b.arrow:SetSize(DF_ARROW_W, DF_CRUMB_H); b.arrow:SetPoint("LEFT", b.label, "RIGHT", 1, 0)
  b.arrow.tex = b.arrow:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  b.arrow.tex:SetPoint("CENTER", b.arrow, "CENTER", 0, -1); b.arrow.tex:SetText("v"); b.arrow:Hide()
  navBar._crumbs[i] = b
  return b
end

local function dfRefresh(navBar, hierarchy)
  for _, b in ipairs(navBar._crumbs) do b:Hide() end
  for _, s in ipairs(navBar._seps)   do s:Hide() end
  local entries = {}
  if navBar._home then entries[#entries + 1] = { name = navBar._home.name, OnClick = navBar._home.OnClick } end
  if hierarchy then for _, d in ipairs(hierarchy) do entries[#entries + 1] = d end end

  local prev
  for i, d in ipairs(entries) do
    if i > 1 then
      local s = dfGetSep(navBar, i); s:ClearAllPoints(); s:SetPoint("LEFT", prev, "RIGHT", 3, 0); s:Show(); prev = s
    end
    local b = dfGetCrumb(navBar, i)
    b.label:SetText(d.name or "")
    local hasMenu = type(d.listFunc) == "function"
    if hasMenu then
      b.arrow:Show()
      b.arrow:SetScript("OnClick", function()
        if EJ.dropdown and EJ.dropdown.OpenMenu then EJ.dropdown.OpenMenu(b.arrow, d.listFunc()) end
      end)
    else
      b.arrow:Hide(); b.arrow:SetScript("OnClick", nil)
    end
    b:SetScript("OnClick", function()
      if d.OnClick then d.OnClick()
      elseif hasMenu and EJ.dropdown and EJ.dropdown.OpenMenu then EJ.dropdown.OpenMenu(b, d.listFunc()) end
    end)
    b:SetWidth(b.label:GetStringWidth() + 8 + (hasMenu and (DF_ARROW_W + 1) or 0))
    b:ClearAllPoints()
    if prev then b:SetPoint("LEFT", prev, "RIGHT", 3, 0) else b:SetPoint("LEFT", navBar, "LEFT", 6, 0) end
    b:Show(); prev = b
  end
end

-- ===========================================================================================
--  Public API — Build / Refresh dispatch on the active skin.
-- ===========================================================================================
function EJ.navbar.Build(parent, opts)
  opts = opts or {}
  local navBar = CreateFrame("Frame", opts.name, parent)
  if opts.strata then navBar:SetFrameStrata(opts.strata) end
  if opts.frameLevel then navBar:SetFrameLevel(opts.frameLevel) end
  navBar._home   = opts.home
  navBar._crumbs = {}
  navBar._seps   = {}
  navBar._classic = classicSkin()

  if navBar._classic then
    -- dark tiled bar + subtle overlay shade beneath the buttons.
    local bg = navBar:CreateTexture(nil, "BACKGROUND", nil, 0); bg:SetTexture(CST); bg:SetHorizTile(true); bg:SetAllPoints(navBar); bg:SetTexCoord(unpack(C.barBG))
    local shade = navBar:CreateTexture(nil, "BACKGROUND", nil, 1); shade:SetTexture(CST); shade:SetHorizTile(true); shade:SetAllPoints(navBar); shade:SetTexCoord(unpack(C.barShade))
    navBar._bg, navBar._shade = bg, shade
    navBar._homeBtn = buildClassicHome(navBar, opts)
    getOverflowButton(navBar)
  end

  EJ.navbar.BuildInsetBorder(navBar)
  return navBar
end

function EJ.navbar.Refresh(navBar, hierarchy)
  if not navBar then return end
  if navBar._classic then classicRefresh(navBar, hierarchy)
  else dfRefresh(navBar, hierarchy) end
end
