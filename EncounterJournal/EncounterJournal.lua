-- Addon/EncounterJournal/EncounterJournal.lua — the EJ_EncounterJournal window shell. Builds the
-- journal window chrome + the instance-select grid (Dungeons/Raids tabs, expansion-tier
-- selector, search). The encounter view (boss list, ability/loot/model tabs) lives in
-- EncounterPage.lua; the breadcrumb navbar + search box in Search.lua.
--
-- Layout transcribed from retail Cata Blizzard_EncounterJournal.xml:1190-1300
-- (build 12.0.5.67451):
--   Frame "EncounterJournal" PortraitFrameTemplate 800x496 CENTER
--   inset  InsetFrameTemplate  TOPRIGHT(-4,-60) BOTTOMLEFT(4,5)
--   instanceSelect -> inset TOPLEFT(0,-2)/BOTTOMRIGHT(-3,0); bg, Title TOPLEFT(20,-15),
--                     ExpansionDropdown TOPRIGHT(-24,-10), ScrollBox 748x367 TOPLEFT(14,-50)
--
-- Built as a plain toplevel Show/Hide frame (NOT a UIPanel) — same as EJ_TalentFrame — so
-- the secure key toggle works in combat without Era's ShowUIPanel taint gate.
--
-- 2026-09-05 (visual parity with the DragonUI_NewEra journal): retail rock body fill (374155,
-- untinted), black inset well, Dragonflight metal Dungeons/Raids tabs (Core/Tabs.lua), RedButton
-- close, the grid page pinned above the inset's own border pieces, an EXPANSION-TIER selector in
-- place of the old continent/"All" filter (so the tier art behind the grid always matches what's
-- listed — the old "All" showed Classic art over Wrath dungeons), square-icon-aware splash crops,
-- a draggable window whose position persists, and a `/ej scale` knob.

EJ.ej = EJ.ej or {}

local FRAME_W, FRAME_H = 800, 496
local ART_EJ = "Interface\\AddOns\\EncounterJournal\\Art\\EncounterJournal\\"

-- Pixel-perfect scale (pin to 768/physH, never raw SetScale numbers) × the user's `/ej scale`
-- multiplier (persisted in EncounterJournalDB.ejScale; 1.0 = retail size). This is THE size knob
-- for the whole window — a raw SetScale elsewhere is overwritten by the pin on show/resize.
local function userScale()
  local s = EJ.db and tonumber(EJ.db.ejScale)
  if not s or s < 0.5 or s > 2 then return 1 end
  return s
end
local function pinScale(f) EJ.FrameUtil.PinPixelPerfect(f, userScale()) end

-- ── Expansion tiers ──────────────────────────────────────────────────────────────────────────
-- Each instance belongs to exactly one tier (vanilla_data → 1, tbc_data marks `_tbc` → 2,
-- wotlk_data marks `_wotlk` → 3). Mirrors retail Cata's EJ_TIER_DATA: the dropdown picks the tier,
-- the page art follows it, and the choice persists (EncounterJournalDB.ej.tier). First open
-- defaults to the tier the character's level belongs to.
local EJ_TIER = {
  [1] = { label = EXPANSION_NAME0 or "Classic",                bg = ART_EJ .. "605327-ui-ej-classic.blp" },
  [2] = { label = EXPANSION_NAME1 or "The Burning Crusade",    bg = ART_EJ .. "UI-EJ-BurningCrusade.blp" },
  [3] = { label = EXPANSION_NAME2 or "Wrath of the Lich King", bg = ART_EJ .. "UI-EJ-WrathoftheLichKing.blp" },
}
local function tierOf(inst)
  if not inst then return 1 end
  if inst.tier then return inst.tier end
  if inst._wotlk then return 3 end
  if inst._tbc then return 2 end
  return 1
end
local function defaultTier()
  local saved = EJ.db and EJ.db.ej and EJ.db.ej.tier
  if saved and EJ_TIER[saved] then return saved end
  local lvl = (UnitLevel and UnitLevel("player")) or 80
  if lvl >= 68 then return 3 elseif lvl >= 58 then return 2 end
  return 1
end
local function persistTier(t)
  if not EJ.db then return end
  EJ.db.ej = EJ.db.ej or {}
  EJ.db.ej.tier = t
end

local function classicSkin() return EJ.skin and EJ.skin.Is(EJ.skin.CLASSIC) end

-- Inset (recessed content well). retail: TOPRIGHT(-4,-60) BOTTOMLEFT(4,5). The thin gold inner
-- border is our nineslice "InsetFrameTemplate" layout (Core/NineSlice.lua, retail inner-trim
-- atlases in Core/AtlasData.lua); the fill is the near-black well the journal sits the tier art
-- in. Same in both skins.
local function buildInset(f)
  local inset = CreateFrame("Frame", "EJ_EncounterJournalInset", f)
  inset:SetPoint("TOPRIGHT",   f, "TOPRIGHT",   -4, -60)
  inset:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT",  4,  5)
  local bg = inset:CreateTexture("EJ_EncounterJournalInsetBg", "BACKGROUND", nil, -5)
  bg:SetAllPoints(inset)
  bg:SetTexture(0, 0, 0, 0.85)   -- 3.3.5 solid-colour SetTexture(r,g,b,a)
  inset.Bg = bg
  EJ.nineslice.ApplyLayout(inset, "InsetFrameTemplate")
  f.inset = inset
end

-- Window chrome, CLASSIC skin — the MoP Classic look: the Cata/MoP FrameGeneral UI-Frame border
-- (portrait ring, title bar, corners, side tiles), rock Bg, TopTileStreaks, title and the native
-- red-square close button. Rebuilt piece for piece from Blizzard's 4.x PortraitFrameTemplate
-- (same anchors and sizes) over our own copies of the art (Art/Frame/Classic, atlases
-- "classic-*" in Core/AtlasData.lua), so it needs no template library.
local function buildClassicChrome(f)
  local function piece(layer, sub, atlas, w, h)
    local t = f:CreateTexture(nil, layer, nil, sub)
    EJ.tex.SetAtlas(t, atlas, false)
    if w then t:SetWidth(w) end
    if h then t:SetHeight(h) end
    return t
  end

  local bg = f:CreateTexture(nil, "BACKGROUND", nil, -6)
  bg:SetTexture(EJ.tex.CLASSIC_ROCK)
  bg:SetHorizTile(true); bg:SetVertTile(true)
  bg:SetPoint("TOPLEFT", f, "TOPLEFT", 2, -21)
  bg:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -2, 2)
  f.Bg = bg

  -- title-bar fill behind the title text (4.x $parentTitleBg: BACKGROUND, TOPLEFT(2,-3)/TOPRIGHT(-25,-3))
  local titleBg = piece("BACKGROUND", 0, "classic-_UI-Frame-TitleTileBg", nil, 17)
  titleBg:SetPoint("TOPLEFT", f, "TOPLEFT", 2, -3)
  titleBg:SetPoint("TOPRIGHT", f, "TOPRIGHT", -25, -3)

  -- portrait (60x60) under the ring — the pre-masked round journal icon (no masking on 3.3.5)
  local portrait = f:CreateTexture(nil, "OVERLAY", nil, -1)
  portrait:SetSize(60, 60)
  portrait:SetPoint("TOPLEFT", f, "TOPLEFT", -6, 7)
  portrait:SetTexture(ART_EJ .. "ui-ej-portraiticon-round.tga")
  f.Portrait = portrait

  local ring = piece("OVERLAY", 0, "classic-UI-Frame-Portrait", 78, 78)
  ring:SetPoint("TOPLEFT", f, "TOPLEFT", -14, 11)
  local topRight = piece("OVERLAY", 0, "classic-UI-Frame-TopCornerRight", 33, 33)
  topRight:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 1)
  local top = piece("OVERLAY", 0, "classic-_UI-Frame-TitleTile", nil, 28)
  top:SetPoint("TOPLEFT", ring, "TOPRIGHT", 0, -10)
  top:SetPoint("TOPRIGHT", topRight, "TOPLEFT", 0, 0)

  local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  title:SetPoint("TOP", f, "TOP", 0, -4)
  title:SetPoint("LEFT", f, "LEFT", 60, 0)
  title:SetPoint("RIGHT", f, "RIGHT", -60, 0)
  title:SetText(ADVENTURE_JOURNAL or "Adventure Guide")
  f.Title = title

  local streaks = piece("BORDER", 0, "classic-_UI-Frame-TopTileStreaks", nil, 37)
  streaks:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -21)
  streaks:SetPoint("TOPRIGHT", f, "TOPRIGHT", -2, -21)
  local botLeft = piece("BORDER", 0, "classic-UI-Frame-BotCornerLeft", 14, 14)
  botLeft:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", -6, -5)
  local botRight = piece("BORDER", 0, "classic-UI-Frame-BotCornerRight", 11, 11)
  botRight:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, -5)
  local bottom = piece("BORDER", 0, "classic-_UI-Frame-Bot", nil, 9)
  bottom:SetPoint("BOTTOMLEFT", botLeft, "BOTTOMRIGHT", 0, 0)
  bottom:SetPoint("BOTTOMRIGHT", botRight, "BOTTOMLEFT", 0, 0)
  local left = piece("BORDER", 0, "classic-!UI-Frame-LeftTile", 16, nil)
  left:SetPoint("TOPLEFT", ring, "BOTTOMLEFT", 8, 0)
  left:SetPoint("BOTTOMLEFT", botLeft, "TOPLEFT", 0, 0)
  local right = piece("BORDER", 0, "classic-!UI-Frame-RightTile", 10, nil)
  right:SetPoint("TOPRIGHT", topRight, "BOTTOMRIGHT", 1, 0)
  right:SetPoint("BOTTOMRIGHT", botRight, "TOPRIGHT", 0, 0)

  -- UIPanelCloseButton's stock OnClick is HideParentPanel → HideUIPanel; this window is a plain
  -- toplevel frame (not a UIPanel), so hide it directly. Raised above the content pages.
  local close = CreateFrame("Button", "EJ_EncounterJournalCloseButton", f, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", f, "TOPRIGHT", 4, 5)
  close:SetScript("OnClick", function() f:Hide() end)
  close:SetFrameLevel(f:GetFrameLevel() + 10)
  f.CloseButton = close

  buildInset(f)
end

-- Window chrome, DRAGONFLIGHT skin — the NewEra recipe: rock body + TopTileStreaks + metal
-- nineslice (our PortraitFrameTemplate layout over the real retail sheets Core/AtlasData.lua
-- registers) + round portrait + title band + RedButton close + the black inset well.
local function buildChrome(f)
  if classicSkin() then return buildClassicChrome(f) end
  -- 0. Body fill — the retail UI-Background-Rock (FDID 374155) shipped under Art\Common and
  -- registered by Core/AtlasData.lua; drawn untinted (the "modern grey" every NewEra window has).
  -- BACKGROUND sublevel -6, TOPLEFT(4,-21)/BOTTOMRIGHT(0,0): the metal border covers the edges at
  -- OVERLAY, and a wider inset left a see-through gap at the sides. Falls back to the classic
  -- rock tile, then to a flat dark fill.
  local body = f:CreateTexture(nil, "BACKGROUND", nil, -6)
  local rock = (EJ.tex.localFiles and EJ.tex.localFiles[374155]) or EJ.tex.CLASSIC_ROCK
  if not pcall(function()
    body:SetTexture(rock)
    body:SetHorizTile(true); body:SetVertTile(true)
  end) or not body:GetTexture() then
    body:SetTexture(0.05, 0.05, 0.06, 0.95)   -- 3.3.5 solid-colour SetTexture(r,g,b,a)
  end
  body:SetPoint("TOPLEFT",     f, "TOPLEFT",     4, -21)
  body:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0,   0)
  f.bodyBg = body

  -- TopTileStreaks band below the title (retail BORDER layer, _UI-Frame-TopTileStreaks).
  local streaks = f:CreateTexture(nil, "BORDER")
  EJ.tex.SetAtlas(streaks, "_UI-Frame-TopTileStreaks", false)
  streaks:SetHorizTile(true); streaks:SetHeight(43)
  streaks:SetPoint("TOPLEFT",  f, "TOPLEFT",   6, -21)
  streaks:SetPoint("TOPRIGHT", f, "TOPRIGHT", -2, -21)
  f.topStreaks = streaks

  -- 1. Modern metal nineslice on a child frame.
  local ns = CreateFrame("Frame", nil, f)
  ns:SetAllPoints(f)
  ns:EnableMouse(false)
  EJ.nineslice.ApplyLayout(ns, "PortraitFrameTemplate")
  f.NineSlice = ns

  -- 2. Portrait — the pre-masked round journal icon (3.3.5 has no texture masking, so the round
  -- illusion is baked into the TGA's alpha; see README "How the chrome is built").
  local portrait = f:CreateTexture(nil, "ARTWORK")
  portrait:SetTexture(ART_EJ .. "ui-ej-portraiticon-round.tga")
  EJ.portrait.ApplyCutout(portrait, f, { size = 60, anchor = { "TOPLEFT", -4, 6 }, mask = false })
  f.Portrait = portrait

  -- 3. Title band.
  local tc = CreateFrame("Frame", nil, f)
  tc:SetFrameLevel(ns:GetFrameLevel() + 10)
  tc:SetPoint("TOPLEFT",  f, "TOPLEFT",  58, -1)
  tc:SetPoint("TOPRIGHT", f, "TOPRIGHT", -24, -1)
  tc:SetHeight(20)
  tc:EnableMouse(false)
  local title = tc:CreateFontString(nil, "OVERLAY")
  f.Title = title
  f.TitleContainer = tc
  EJ.panelchrome.SetTitle(f, ADVENTURE_JOURNAL or "Adventure Guide")

  -- 4. Close button — RedButton-Exit-2x (Core/AtlasData.lua + Art\Common); the helper keeps the
  -- native X if that art is missing. Raised above the nineslice so the metal corner can't eclipse it.
  local close = CreateFrame("Button", "EJ_EncounterJournalCloseButton", f, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", f, "TOPRIGHT", 1, 0)
  close:SetScript("OnClick", function() f:Hide() end)
  close:SetFrameLevel(ns:GetFrameLevel() + 10)
  EJ.panelchrome.ModernizeCloseButton(close)
  f.CloseButton = close

  -- 5. Inset.
  buildInset(f)
end

-- Instance-select page (the dungeon/raid grid landing).
local function buildInstanceSelect(f)
  local page = CreateFrame("Frame", "EJ_EncounterJournalInstanceSelect", f)
  page:SetPoint("TOPLEFT",     f.inset, "TOPLEFT",      0, -2)
  page:SetPoint("BOTTOMRIGHT", f.inset, "BOTTOMRIGHT", -3,  0)
  -- Pin above the inset's own border pieces: sibling frames at equal level draw in an
  -- unspecified order on 3.3.5a, and the inset's BORDER trim was sometimes painted OVER the tier
  -- art (a stray gold line / marble strip across the background).
  page:SetFrameLevel(f.inset:GetFrameLevel() + 2)
  f.instanceSelect = page

  local bg = page:CreateTexture(nil, "BACKGROUND")
  bg:SetTexture(EJ_TIER[1].bg)
  bg:SetAllPoints(page)
  bg:SetTexCoord(0, 1, 0, 1)
  page.bg = bg
  function page.SetTierBackground(tier)
    local td = EJ_TIER[tier]
    if td and td.bg then bg:SetTexture(td.bg); bg:SetTexCoord(0, 1, 0, 1) end
  end

  -- Page title — retail "DUNGEONS" TOPLEFT(20,-15).
  local title = page:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetJustifyH("LEFT")
  title:SetPoint("TOPLEFT", page, "TOPLEFT", 20, -15)
  title:SetText(DUNGEONS or "Dungeons")
  page.Title = title

  -- Expansion-tier dropdown. The classic UIDropDownMenu art carries ~16px of side padding, so
  -- the anchor compensates vs retail's (-24,-10).
  if not InCombatLockdown() and EJ.dropdown and EJ.dropdown.New then
    local dd = EJ.dropdown.New(page, "EJ_EncounterJournalExpansionDropdown", { width = 160 })
    dd:SetPoint("TOPRIGHT", page, "TOPRIGHT", -8, -8)
    page.ExpansionDropdown = dd
  end

  -- Real scroll viewport + modern reskinned scrollbar. retail: ScrollBox 748×367 at
  -- TOPLEFT(14,-50), bar in the right-hand gutter (Reskin x=12).
  local scrollFrame = CreateFrame("ScrollFrame", "EJ_EJInstanceScroll", page, "UIPanelScrollFrameTemplate")
  scrollFrame:SetPoint("TOPLEFT", page, "TOPLEFT", 14, -50)
  scrollFrame:SetSize(748, 367)
  local scroll = CreateFrame("Frame", nil, scrollFrame)
  scroll:SetSize(748, 1)
  scrollFrame:SetScrollChild(scroll)
  if EJ.scrollbar and EJ.scrollbar.Reskin then EJ.scrollbar.Reskin(scrollFrame, { hideIfUnscrollable = true, x = 12 }) end
  page.gridScrollFrame, page.gridScroll = scrollFrame, scroll

  -- Instance grid (pooled buttons) split by Dungeons / Raids bottom tabs.
  -- EncounterInstanceButtonTemplate = 174x96 (EJ.xml:319); 4-col grid.
  local COLS, BW, BH, GX, GY = 4, 174, 96, 9, 8
  local GRID_X_PAD = 4
  page.instButtons = {}

  local dungeons, raids, D = {}, {}, EJ.ej.DATA
  if D then
    for _, inst in ipairs(D.instances or {}) do
      local e = { name = inst.name, inst = inst, minLevel = inst.minLevel or 0, tier = tierOf(inst) }
      if inst.isRaid then raids[#raids + 1] = e else dungeons[#dungeons + 1] = e end
    end
    for _, d in ipairs(D.deferred or {}) do
      dungeons[#dungeons + 1] = { name = d.name, deferred = true, buttonFDID = d.buttonFDID,
                                  minLevel = d.minLevel or 0, tier = d.tier or 1 }
    end
    table.sort(dungeons, function(a, b) return (a.minLevel or 0) < (b.minLevel or 0) end)  -- level order
    table.sort(raids,    function(a, b) return (a.minLevel or 0) < (b.minLevel or 0) end)
  end
  local function tierHasInstances(tier)
    for _, e in ipairs(dungeons) do if e.tier == tier then return true end end
    for _, e in ipairs(raids)    do if e.tier == tier then return true end end
    return false
  end

  local function poolButton(i)
    local b = page.instButtons[i]
    if b then return b end
    b = CreateFrame("Button", nil, scroll)
    b:SetSize(BW, BH)
    -- per-instance splash at BACKGROUND (the dominant visual; texture + crop set per-entry in
    -- renderGrid). Inset 1px left/right + 3px off the bottom: the "Up" frame border's opaque edge
    -- is a touch narrower than the full 174x96 rect, so a SetAllPoints splash peeked out past the
    -- card border at the sides and into the row gap below.
    b.bgImage = b:CreateTexture(nil, "BACKGROUND")
    b.bgImage:SetPoint("TOPLEFT",     b, "TOPLEFT",      1, 0)
    b.bgImage:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -1, 3)
    b.bgImage:SetTexCoord(0, 0.68359375, 0, 0.7421875)
    -- UI-EJ-DungeonButton frame at ARTWORK (over the splash; its center is transparent).
    b.up = b:CreateTexture(nil, "ARTWORK"); EJ.ej.ApplySlice(b.up, "UI-EJ-DungeonButton-Up");        b.up:SetAllPoints(b); b:SetNormalTexture(b.up)
    b.hi = b:CreateTexture(nil, "HIGHLIGHT"); EJ.ej.ApplySlice(b.hi, "UI-EJ-DungeonButton-Highlight"); b.hi:SetAllPoints(b); b:SetHighlightTexture(b.hi)
    b.dn = b:CreateTexture(nil, "ARTWORK"); EJ.ej.ApplySlice(b.dn, "UI-EJ-DungeonButton-Down");      b.dn:SetAllPoints(b); b:SetPushedTexture(b.dn)
    b.label = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    b.label:SetPoint("BOTTOM", b, "BOTTOM", 0, 10); b.label:SetWidth(BW - 16); b.label:SetJustifyH("CENTER")
    -- fancy (Morpheus) font for the dungeon name, with a shadow for readability over the
    -- splash; fall back to the normal font if MORPHEUS.ttf isn't present (non-enUS).
    EJ.font.Set(b.label, EJ.font.MORPHEUS, 13, "", GameFontNormal)
    b.label:SetShadowColor(0, 0, 0, 1); b.label:SetShadowOffset(1, -1)
    page.instButtons[i] = b
    return b
  end

  function page.renderGrid(entries)
    for _, b in ipairs(page.instButtons) do b:Hide() end
    for i, e in ipairs(entries) do
      local b = poolButton(i)
      local col, row = (i - 1) % COLS, math.floor((i - 1) / COLS)
      b:ClearAllPoints()
      b:SetPoint("TOPLEFT", scroll, "TOPLEFT", GRID_X_PAD + col * (BW + GX), -row * (BH + GY))
      b.label:SetText(e.name)
      b.up:SetDesaturated(e.deferred and true or false)
      -- per-instance splash (seeded = full color; deferred = desaturated "coming soon")
      local fdid = e.buttonFDID or (e.inst and e.inst.buttonFDID)
      if fdid and fdid > 0 then
        b.bgImage:SetTexture(EJ.tex.localFiles[fdid] or fdid)
        if EJ.ej.SetButtonTexCoord then EJ.ej.SetButtonTexCoord(b.bgImage, fdid, false)
        else b.bgImage:SetTexCoord(0, 0.68359375, 0, 0.7421875) end
        b.bgImage:SetDesaturated(e.deferred and true or false)
        b.bgImage:Show()
      else
        b.bgImage:Hide()
      end
      b:SetScript("OnClick", nil); b:SetScript("OnEnter", nil); b:SetScript("OnLeave", nil)
      if e.deferred then
        b.label:SetTextColor(0.5, 0.5, 0.5)
        EJ.tooltip.Wire(b, function(_, tip)
          -- plain SetText/AddLine: GameTooltip_SetTitle / AddColoredLine are retail-only.
          tip:SetText(e.name, 1, 1, 1)
          tip:AddLine(e.deferredText or "Data coming soon", 0.5, 0.5, 0.5, true)
        end)
      else
        b.label:SetTextColor(1, 0.82, 0)
        b:SetScript("OnClick", function()
          if PlaySound then pcall(PlaySound, "igMainMenuOptionCheckBoxOn") end
          EJ.ej.ShowInstance(e.inst)
        end)
      end
      b:Show()
    end
    scroll:SetHeight(math.max(1, math.ceil(#entries / COLS) * (BH + GY)))  -- drives scroll range
    -- Force the ScrollFrame to recompute its child rect now. Without this, a render that happens
    -- while the frame is hidden (the build-time selectCat) leaves a stale 0-range, so the grid +
    -- scrollbar don't paint until some later interaction re-runs this.
    if scrollFrame.UpdateScrollChildRect then scrollFrame:UpdateScrollChildRect() end
  end

  -- Apply the tier to the active category, swap the page art, render, and re-apply any live
  -- search text (EJ.ej.FilterGrid narrows the rendered set).
  function page.applyInstanceFilter()
    local cat  = page._category or dungeons
    local tier = page._tier or defaultTier()
    page._tier = tier
    local out = {}
    for _, e in ipairs(cat) do
      if (e.tier or 1) == tier then out[#out + 1] = e end
    end
    page._activeEntries = out
    page.SetTierBackground(tier)
    page.renderGrid(out)
    local sb  = f._ejSearchBox
    local txt = (EJ.ej.ReadSearchText and EJ.ej.ReadSearchText(sb)) or ""
    if txt ~= "" and EJ.ej.FilterGrid then EJ.ej.FilterGrid(txt) end
  end

  -- Menu generator reads page state each open; one SetupMenu serves both categories.
  if page.ExpansionDropdown and page.ExpansionDropdown.SetupMenu then
    page.ExpansionDropdown:SetupMenu(function(_, root)
      for tier = 1, #EJ_TIER do
        local t = tier
        if tierHasInstances(t) then
          root:CreateRadio(EJ_TIER[t].label,
            function() return (page._tier or defaultTier()) == t end,
            function()
              page._tier = t
              persistTier(t)
              page.applyInstanceFilter()
            end)
        end
      end
    end)
  end

  -- Dungeons / Raids bottom tabs — classic CharacterFrameTabButtonTemplate reskinned to the
  -- Dragonflight metal tabs (Core/Tabs.lua; falls back to the classic art when the sheet is
  -- absent). Art/height/level are driven by hand (EJ.tabs.SetActive) rather than
  -- PanelTemplates_SelectTab, which re-anchors text and heights against the custom sizing.
  local dunTab = CreateFrame("Button", "EJ_EJDungeonsTab", f, "CharacterFrameTabButtonTemplate")
  dunTab:SetText(DUNGEONS or "Dungeons")
  local raidTab = CreateFrame("Button", "EJ_EJRaidsTab", f, "CharacterFrameTabButtonTemplate")
  raidTab:SetText(RAIDS or "Raids")
  page.dunTab, page.raidTab = dunTab, raidTab

  -- Classic skin keeps the native red tab art (the MoP look) and its PanelTemplates sizing.
  local classic = classicSkin()
  local reskinned = false
  if not classic and EJ.tabs and EJ.tabs.ReskinClassicTab then
    local ok1, r1 = pcall(EJ.tabs.ReskinClassicTab, "EJ_EJDungeonsTab")
    local ok2, r2 = pcall(EJ.tabs.ReskinClassicTab, "EJ_EJRaidsTab")
    reskinned = (ok1 and r1 and ok2 and r2) and true or false
  end

  local function sizeTab(tab)
    -- the classic pieces have a fixed-width Middle that only PanelTemplates_TabResize stretches
    if not reskinned and PanelTemplates_TabResize then PanelTemplates_TabResize(tab, 0)
    elseif EJ.tabs and EJ.tabs.SizeToText then EJ.tabs.SizeToText(tab)
    elseif EJ.tabs and EJ.tabs.ResizeTabMinimum then EJ.tabs.ResizeTabMinimum(tab) end
  end
  local function rechainTabs()
    dunTab:ClearAllPoints();  dunTab:SetPoint("TOPLEFT", f, "BOTTOMLEFT", 11, 2)
    -- classic tab art has transparent shoulders, so neighbours overlap (FriendsFrame uses -15)
    raidTab:ClearAllPoints(); raidTab:SetPoint("TOPLEFT", dunTab, "TOPRIGHT", reskinned and 1 or -15, 0)
  end
  local function setTabArt(tab, selected)
    if reskinned and EJ.tabs.SetActive then
      EJ.tabs.SetActive(tab, selected)
    elseif PanelTemplates_SelectTab and PanelTemplates_DeselectTab then
      if selected then PanelTemplates_SelectTab(tab) else PanelTemplates_DeselectTab(tab) end
    end
  end
  sizeTab(dunTab); sizeTab(raidTab)
  rechainTabs()

  local function selectCat(isRaid)
    -- a bottom tab always returns to the instance grid (retail) — works from a dungeon/boss page
    f._currentInstance = nil; f._currentBoss = nil
    if f.encounter then f.encounter:Hide() end
    page:Show()
    if EJ.ej.RefreshNavBar then EJ.ej.RefreshNavBar() end
    page._category = isRaid and raids or dungeons
    page._isRaid   = isRaid
    -- the expansion tier persists across the Dungeons↔Raids toggle (retail parity)
    page._tier = page._tier or defaultTier()
    if page.ExpansionDropdown and page.ExpansionDropdown.GenerateMenu then
      page.ExpansionDropdown:GenerateMenu()
    end
    page.applyInstanceFilter()

    -- selected → gold/active art, taller body, raised above its neighbour
    setTabArt(dunTab, not isRaid); setTabArt(raidTab, isRaid)
    sizeTab(dunTab); sizeTab(raidTab)
    rechainTabs()
    local base = f:GetFrameLevel()
    dunTab:SetFrameLevel(base + (isRaid and 4 or 10))
    raidTab:SetFrameLevel(base + (isRaid and 10 or 4))
    if page.Title then page.Title:SetText(isRaid and (RAIDS or "Raids") or (DUNGEONS or "Dungeons")) end
  end
  local function playPageTurn()
    if PlaySound then pcall(PlaySound, "igCharacterInfoTab") end
  end
  dunTab:SetScript("OnClick",  function() playPageTurn(); selectCat(false) end)
  raidTab:SetScript("OnClick", function() playPageTurn(); selectCat(true) end)
  page.SelectCategory = selectCat
  selectCat(false)   -- default to Dungeons

  -- Text measurement is unreliable until the frame has been shown once (the build runs while `f`
  -- is hidden, and the template's Text reports its XML width rather than the string width), so
  -- the build-time sizeTab overshoots. Re-size on show.
  f:HookScript("OnShow", function()
    sizeTab(dunTab); sizeTab(raidTab)
    rechainTabs()
  end)
end

-- ── Window position (draggable; persisted) ────────────────────────────────────────────────────
-- The retail journal is manager-positioned; NewEra made it draggable and remembers where you put
-- it. Once dragged, the window leaves the panel row (Core/PanelManager.lua MarkUserPlaced) and
-- opens at the saved point until `/ej resetpos`.
function EJ.ej.SavePosition(f)
  if not (f and EJ.db) then return end
  local p, _, rp, x, y = f:GetPoint(1)
  if not p then return end
  EJ.db.ejWindow = { point = p, relPoint = rp or p, x = x or 0, y = y or 0 }
  if EJ.panelmgr and EJ.panelmgr.MarkUserPlaced then EJ.panelmgr.MarkUserPlaced(f) end
end
function EJ.ej.RestorePosition(f)
  local t = EJ.db and EJ.db.ejWindow
  if not (f and t and t.point) then return false end
  f:ClearAllPoints()
  f:SetPoint(t.point, UIParent, t.relPoint or t.point, t.x or 0, t.y or 0)
  if EJ.panelmgr and EJ.panelmgr.MarkUserPlaced then EJ.panelmgr.MarkUserPlaced(f) end
  return true
end
function EJ.ej.ResetPosition()
  if EJ.db then EJ.db.ejWindow = nil end
  local f = EJ.ej.frame
  if not f then return end
  if EJ.panelmgr and EJ.panelmgr.ClearUserPlaced then EJ.panelmgr.ClearUserPlaced(f) end
  f:ClearAllPoints(); f:SetPoint("CENTER")
  if f:IsShown() and EJ.panelmgr and EJ.panelmgr.ScheduleReflow then EJ.panelmgr.ScheduleReflow() end
end

-- Build + toggle
local frame
local function build()
  if frame then return frame end
  -- Plain frame; both skins build their chrome by hand (buildClassicChrome / buildChrome).
  frame = CreateFrame("Frame", "EJ_EncounterJournal", UIParent)
  frame:SetSize(FRAME_W, FRAME_H)
  frame:SetPoint("CENTER")
  frame:SetFrameStrata("MEDIUM")   -- retail EncounterJournal: MEDIUM (default) + toplevel (Blizzard_EncounterJournal.xml:1333)
  frame:SetToplevel(true)
  -- Retail EJ open/close (Mainline/Blizzard_EncounterJournal.lua:751 + OnHide) — vanilla-native kits.
  EJ.FrameUtil.WirePanelSounds(frame, "igCharacterInfoOpen", "igCharacterInfoClose")
  frame:EnableMouse(true)       -- panel: swallow clicks so they don't fall through
  frame:SetClampedToScreen(true)
  -- Drag anywhere on the body (child buttons keep their own clicks). Installed BEFORE the panel
  -- manager registers, so nothing it hooks is discarded by these SetScripts.
  frame:SetMovable(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
  frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    EJ.ej.SavePosition(self)
  end)
  if EJ.panelmgr then EJ.panelmgr.Register(frame) end   -- retail UIPanel slot (left); see Core/PanelManager
  frame:Hide()

  buildChrome(frame)
  buildInstanceSelect(frame)

  -- Encounter view (hidden until an instance is picked). retail: anchored to the inset; pinned
  -- above the inset's border pieces like the grid page.
  local enc = CreateFrame("Frame", "EJ_EncounterJournalEncounter", frame)
  enc:SetPoint("TOPLEFT",     frame.inset, "TOPLEFT",      0, 0)
  enc:SetPoint("BOTTOMRIGHT", frame.inset, "BOTTOMRIGHT", -3, 0)
  enc:SetFrameLevel(frame.inset:GetFrameLevel() + 2)
  enc:Hide()
  frame.encounter = enc
  EJ.ej.frame = frame
  if EJ.ej.BuildEncounterPage then EJ.ej.BuildEncounterPage(frame) end
  if EJ.ej.BuildNavBar then EJ.ej.BuildNavBar(frame) end
  -- buildInstanceSelect's selectCat() already ran RefreshNavBar once, but the navbar didn't exist
  -- yet (built just above), so that pass no-op'd. Refresh now so the Home crumb is laid out on the
  -- very first open.
  if EJ.ej.RefreshNavBar then EJ.ej.RefreshNavBar() end

  -- Populate-on-open. The instance grid is first rendered inside build() while the frame is still
  -- HIDDEN, and a ScrollFrame won't lay its content out until shown — re-apply the active filter
  -- on open, both immediately and one frame later (the first open's OnShow runs in the same tick
  -- as :Show(), before the ScrollFrame's geometry exists).
  frame:HookScript("OnShow", function(self)
    local function refresh()
      local page = self.instanceSelect
      if page and page:IsShown() and page.applyInstanceFilter then page.applyInstanceFilter() end
    end
    refresh()
    if EJ.After then EJ.After(0, refresh) end
  end)

  pinScale(frame)
  EJ.ej.RestorePosition(frame)

  -- ESC closes it (ToggleGameMenu walks UISpecialFrames first).
  EJ.FrameUtil.EscClose("EJ_EncounterJournal")
  return frame
end

function EJ.ej.Toggle()
  local f = build()
  if f:IsShown() then
    f:Hide()
  else
    pinScale(f)
    f:Show()
  end
end

function EJ.ej.Open()  build():Show() end
function EJ.ej.Close() if frame then frame:Hide() end end

-- `/ej scale <n>` — the window size multiplier (0.5 … 2.0), persisted; applied live.
function EJ.ej.SetScale(n)
  local cf = _G.DEFAULT_CHAT_FRAME
  n = tonumber(n)
  if not n then
    if cf then cf:AddMessage("|cff66ccffEncounterJournal|r scale: |cffffd200" .. userScale() .. "|r  (|cffffd200/ej scale 0.5 … 2.0|r)") end
    return
  end
  if n < 0.5 then n = 0.5 elseif n > 2 then n = 2 end
  if EJ.db then EJ.db.ejScale = n end
  if frame then pinScale(frame) end
  if cf then cf:AddMessage("|cff66ccffEncounterJournal|r scale set to |cffffd200" .. n .. "|r") end
end

-- Navigation between the instance-select grid and the encounter view.
function EJ.ej.ShowList()
  local f = build()
  f._currentInstance = nil
  f._currentBoss = nil
  if f.encounter then f.encounter:Hide() end
  if f.instanceSelect then f.instanceSelect:Show() end
  if EJ.ej.RefreshNavBar then EJ.ej.RefreshNavBar() end
end

function EJ.ej.ShowInstance(inst)
  local f = build()
  f._currentInstance = (type(inst) == "table") and inst or nil
  f._currentBoss = nil   -- entering an instance clears the boss breadcrumb level
  if f.instanceSelect then f.instanceSelect:Hide() end
  if f.encounter then f.encounter:Show() end
  if EJ.ej.PopulateEncounter and type(inst) == "table" then
    EJ.ej.PopulateEncounter(inst)   -- fills lore (name/desc) + the real boss list
  end
  if EJ.ej.RefreshNavBar then EJ.ej.RefreshNavBar() end
end

-- Filter the instance grid by name substring (the search box). Re-renders the active
-- category's entries.
function EJ.ej.FilterGrid(text)
  local f = EJ.ej.frame
  local page = f and f.instanceSelect
  if not (page and page.renderGrid and page._activeEntries) then return end
  text = (text or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
  if text == "" then page.renderGrid(page._activeEntries); return end
  local filtered = {}
  for _, e in ipairs(page._activeEntries) do
    if e.name and e.name:lower():find(text, 1, true) then filtered[#filtered + 1] = e end
  end
  page.renderGrid(filtered)
end

-- Adventure-Guide micro button on the main menu bar — the journal's opener (3.3.5a ships no EJ
-- micro button and no TOGGLEENCOUNTERJOURNAL key). The ORIGINAL retail look: the real
-- UI-MicroButton-EJ art slotted into the micro-button row in its retail position (after LFG,
-- before Main Menu), with the whole row tightened to make room — the proven AzerPUGs sequence
-- (its 3.4 MainMenuBar matches 3.3.5a's). Every reposition is guarded on its frame existing.
local stockMicroLayout   -- defined below
local function setupMicroButton()
  if EJ.ej._microButton then return end
  if not _G.MainMenuBar then return end

  -- Sit in the micro-button row EXACTLY like a native button: same PARENT (the real micro buttons
  -- live on MainMenuBarArtFrame — parenting ours to MainMenuBar put it a layer BELOW, so it drew
  -- behind the bar end-cap art), same FRAME LEVEL, and same SIZE (hardcoding 28×58 made it taller
  -- than 3.3.5's row, so it poked up above the other buttons). Mirror a reference micro button.
  local ref = _G.LFDMicroButton or _G.CharacterMicroButton or _G.PVPMicroButton
  local parent = (ref and ref:GetParent()) or _G.MainMenuBarArtFrame or _G.MainMenuBar
  local b = CreateFrame("Button", "EJ_EJMicroButton", parent)
  if ref then
    b:SetSize(ref:GetWidth(), ref:GetHeight())
    b:SetFrameStrata(ref:GetFrameStrata())
    b:SetFrameLevel(ref:GetFrameLevel())
  else
    b:SetSize(28, 58)
  end
  -- The retail EJ micro-button art (UI-MicroButton-EJ-*) is a Cata+ asset absent on stock 3.3.5a,
  -- so we SHIP it ourselves (Art/EncounterJournal/ui-microbutton-ej-up.blp + -down.blp), drawn via
  -- a Texture region + Texture:SetTexture with the full .blp path (the proven shipped-art path).
  -- Highlight uses the native ring (present on 3.3.5).
  local up = b:CreateTexture(nil, "BACKGROUND")
  up:SetAllPoints(b); up:SetTexture(ART_EJ .. "ui-microbutton-ej-up.blp")
  b:SetNormalTexture(up)
  local dn = b:CreateTexture(nil, "BACKGROUND")
  dn:SetAllPoints(b); dn:SetTexture(ART_EJ .. "ui-microbutton-ej-down.blp")
  b:SetPushedTexture(dn)
  b:SetHighlightTexture("Interface\\Buttons\\UI-MicroButton-Hilight")
  b:SetScript("OnClick", function() EJ.ej.Toggle() end)
  if EJ.tooltip and EJ.tooltip.Wire then
    EJ.tooltip.Wire(b, ADVENTURE_JOURNAL or "Adventure Guide")
  end

  EJ.ej._microButton = b
  -- ElvUI owns the micro buttons (its own bar + layout): hand ours over instead (Core/ElvUI.lua).
  if EJ.elvui and EJ.elvui.AttachMicroButton(b, function() stockMicroLayout(b) end) then return end
  stockMicroLayout(b)
end

-- Re-lay the stock micro-button row, inserting ours, exactly as AzerPUGs does. Guarded so a missing
-- or renamed button (bar addons) can't error out the chain.
stockMicroLayout = function(b)
  local function anchor(name, relName, x)
    local fr, rel = _G[name], _G[relName]
    if fr and rel then fr:ClearAllPoints(); fr:SetPoint("BOTTOMLEFT", rel, "BOTTOMRIGHT", x, 0) end
  end
  if _G.CharacterMicroButton and _G.MainMenuBarArtFrame then
    _G.CharacterMicroButton:ClearAllPoints()
    _G.CharacterMicroButton:SetPoint("BOTTOMLEFT", _G.MainMenuBarArtFrame, "BOTTOMLEFT", 547, 2)
  end
  anchor("SpellbookMicroButton",   "CharacterMicroButton",   -4)
  anchor("TalentMicroButton",      "SpellbookMicroButton",   -4)
  anchor("AchievementMicroButton", "TalentMicroButton",      -4)
  anchor("QuestLogMicroButton",    "AchievementMicroButton", -4)
  anchor("SocialsMicroButton",     "QuestLogMicroButton",    -4)
  anchor("PVPMicroButton",         "SocialsMicroButton",     -4)
  -- 3.3.5a's dungeon-finder micro button is LFDMicroButton; 3.4/retail call it LFGMicroButton.
  local lfdName = _G.LFDMicroButton and "LFDMicroButton" or (_G.LFGMicroButton and "LFGMicroButton")
  if lfdName then anchor(lfdName, "PVPMicroButton", -5) end
  b:ClearAllPoints()
  b:SetPoint("BOTTOMLEFT", (lfdName and _G[lfdName]) or _G.PVPMicroButton or _G.SocialsMicroButton, "BOTTOMRIGHT", -4, 0)
  anchor("MainMenuMicroButton",    "EJ_EJMicroButton",       -5)
  anchor("HelpMicroButton",        "MainMenuMicroButton",    -4)
end

-- ── Openers ──────────────────────────────────────────────────────────────────────────────
-- Registered at FILE SCOPE (the instant this file loads), NOT inside the per-login module boot,
-- so they exist even if build() or the module dispatcher errors. If even these do nothing after
-- a /reload, the addon itself isn't loading — check that it is enabled in the AddOns list.
--
-- TAINT: safe + additive. Era/3.3.5 ships no ToggleEncounterJournal (EJ is Wrath+), so this
-- CREATES a global the client lacks rather than overwriting Blizzard's; the ~="function" guard
-- no-ops on a future build that adds it.
if type(_G.ToggleEncounterJournal) ~= "function" then
  _G.ToggleEncounterJournal = function() EJ.ej.Toggle() end
end
_G.SLASH_ENCOUNTERJOURNAL1 = "/ej"
_G.SLASH_ENCOUNTERJOURNAL2 = "/encounterjournal"
_G.SLASH_ENCOUNTERJOURNAL3 = "/adventureguide"
if _G.SlashCmdList then
  _G.SlashCmdList["ENCOUNTERJOURNAL"] = function(msg)
    local cf = _G.DEFAULT_CHAT_FRAME
    local cmd, arg = string.match(msg or "", "^%s*(%S*)%s*(%S*)")
    cmd = cmd and string.lower(cmd) or ""
    -- `/ej model [x|y|z|facing|scale <n> | global <n> | path <file>|clear | display <id>|clear |
    --  reset]` — live-tune the currently shown boss model (persisted per display ID; see
    -- EJ.ej.ModelTune in EncounterPage.lua).
    if cmd == "model" and EJ.ej.ModelTune then
      local sub, val = string.match(msg or "", "^%s*%S+%s+(%S+)%s*(.-)%s*$")
      EJ.ej.ModelTune(sub and string.lower(sub) or nil, tonumber(val), val)
      return
    end
    if cmd == "scale" then EJ.ej.SetScale(arg ~= "" and arg or nil); return end
    if cmd == "resetpos" then
      EJ.ej.ResetPosition()
      if cf then cf:AddMessage("|cff66ccffEncounterJournal|r window position reset.") end
      return
    end
    if cmd == "skin" and EJ.skin then
      if arg == "" then
        if cf then cf:AddMessage("|cff66ccffEncounterJournal|r skin: |cffffd200" .. EJ.skin.Label(EJ.skin.Get())
          .. "|r  (use |cffffd200/ej skin classic|r or |cffffd200/ej skin dragonflight|r)") end
      else
        EJ.skin.Set(string.lower(arg))
      end
      return
    end
    if cmd == "faction" and EJ.ej.SetFactionMode then EJ.ej.SetFactionMode(string.lower(arg)); return end
    if cmd == "help" or cmd == "?" then
      if cf then
        cf:AddMessage("|cff66ccffEncounterJournal|r commands:")
        cf:AddMessage("  |cffffd200/ej|r — toggle the journal")
        cf:AddMessage("  |cffffd200/ej scale <0.5-2.0>|r — window size (drag the window to move it; |cffffd200/ej resetpos|r puts it back)")
        cf:AddMessage("  |cffffd200/ej model x|y|z|facing|scale <n> · global <n> · npc <id> · path <file> · display <id> · mode creature|file|auto|display · reset|r — tune the shown boss model (mouse wheel over the model = zoom, drag = rotate)")
        cf:AddMessage("  |cffffd200/ej skin dragonflight|classic|r — DragonUI look or the MoP Classic look (reloads)")
        cf:AddMessage("  |cffffd200/ej faction auto|all|r — only your faction's bosses/loot (auto) or both")
      end
      return
    end
    local ok, err = pcall(EJ.ej.Toggle)
    if not ok and cf then
      cf:AddMessage("|cffff5555EncounterJournal error:|r " .. tostring(err))
    end
  end
end

-- One-time load confirmation (diagnostic + tells the user how to open it). If you DON'T see this
-- line at login, this file isn't loading (a Lua error earlier in the load order, or the addon is
-- disabled).
if _G.DEFAULT_CHAT_FRAME then
  _G.DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffEncounterJournal|r loaded — open with |cffffd200/ej|r or the book button on the menu bar (|cffffd200/ej help|r).")
end

-- Boot: build the window + add the micro button at login. Each is isolated in its own pcall so a
-- failure in one can't suppress the other (or the file-scope openers above); errors are printed
-- to chat instead of vanishing (EJ.Log isn't shipped here). Re-pin on scale changes.
EJ.modules.Register("EncounterJournal", {
  default = true, label = "Encounter Journal", category = "Windows",
  desc = "The Adventure Guide: bosses, abilities, and loot for classic dungeons and raids. Turning this off removes it; the classic game has none.",
  events = { "PLAYER_LOGIN", "UI_SCALE_CHANGED", "DISPLAY_SIZE_CHANGED" },
  onBoot = function(ev)
    if ev == "PLAYER_LOGIN" then
      local function report(tag, fn)
        local ok, err = pcall(fn)
        if not ok and _G.DEFAULT_CHAT_FRAME then
          _G.DEFAULT_CHAT_FRAME:AddMessage("|cffff5555EncounterJournal " .. tag .. " error:|r " .. tostring(err))
        end
      end
      if EJ.ej.ApplyFaction then report("faction", EJ.ej.ApplyFaction) end   -- before build: prunes the data the window reads
      report("microbutton", setupMicroButton)
      report("build", build)
    elseif frame then
      pinScale(frame)
    end
  end,
})
