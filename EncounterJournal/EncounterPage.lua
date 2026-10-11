-- Addon/EncounterJournal/EncounterPage.lua — the encounter view, data-driven from
-- EJ.ej.DATA (port-a-frame Step 4: behavior). Left lore/instance panel + right full-width
-- info panel (book bg + 4 info tabs + boss list + per-boss content). Real boss/ability/
-- loot/model data for the 11 verified-vanilla seeded instances; revamped dungeons are
-- deferred shells handled in EncounterJournal.lua's grid.
--
-- Layout transcribed from retail Cata Blizzard_EncounterJournal.xml:1307-1610 (12.0.5.67451).
-- Interaction model (simplified for v1): boss list on the left page (always, when an
-- instance is open); right page shows the instance lore landing until a boss is picked,
-- then the selected boss's content per the active tab (Overview=desc, Abilities=sections,
-- Loot=items, Model=creature).

EJ.ej = EJ.ej or {}

local selInst, selBoss   -- module state: current instance + boss tables

local function sliceTex(parent, slice, layer, setSize)
  local t = parent:CreateTexture(nil, layer or "ARTWORK")
  EJ.ej.ApplySlice(t, slice, setSize)
  return t
end

-- Model tab switch. OFF for now: many boss models render broken on 3.3.5a (humanoids above all —
-- see the model-loading notes), so the tab is greyed out and unclickable. The model code below
-- stays intact; flip this to true to bring the tab back.
EJ.ej.MODEL_TAB_ENABLED = false

local function makeTab(parent, id, iconSel, iconUnsel, tip)
  local t = CreateFrame("Button", nil, parent)
  t:SetSize(63, 57)
  local n = sliceTex(t, "UI-EJ-Tab-UnSelected"); n:SetAllPoints(t); t:SetNormalTexture(n)
  local h = sliceTex(t, "UI-EJ-Tab-Highlight");  h:SetAllPoints(t); h:SetBlendMode("ADD"); t:SetHighlightTexture(h)
  t.selBG = sliceTex(t, "UI-EJ-Tab-Selected", "ARTWORK"); t.selBG:SetAllPoints(t); t.selBG:Hide()
  t.unselIcon = sliceTex(t, iconUnsel, "OVERLAY", true); t.unselIcon:SetPoint("RIGHT", t, "RIGHT", -6, 0)
  t.selIcon   = sliceTex(t, iconSel,   "OVERLAY", true); t.selIcon:SetPoint("CENTER", t.unselIcon, "CENTER", 0, 0); t.selIcon:Hide()
  t.tabID = id
  t:SetScript("OnClick", function() EJ.ej.SelectTab(id) end)
  if tip then
    EJ.tooltip.Wire(t, tip)
  end
  return t
end

-- Left lore/instance panel (the instance landing on the right page)
local function buildLorePanel(enc)
  local p = CreateFrame("Frame", "EJ_EncounterJournalInstanceFrame", enc)
  p:SetSize(390, 425)
  p:SetPoint("BOTTOMRIGHT", enc, "BOTTOMRIGHT", -1, 2)
  enc.instance = p

  -- Loading-screen artwork at the TOP (per-instance LoreFileDataID set in PopulateEncounter).
  -- retail /neprobe ej: loreBG 390x330 TOP(3,-9).
  local loreBG = p:CreateTexture(nil, "BACKGROUND")
  loreBG:SetTexture(EJ.tex.localFiles[527422] or 527422)   -- UI-EJ-LOREBG-Default placeholder
  loreBG:SetSize(390, 330)
  loreBG:SetPoint("TOP", p, "TOP", 3, -9)
  loreBG:SetTexCoord(0, 0.7617187, 0, 0.65625)   -- retail crop (same for default + per-instance)
  p.loreBG = loreBG

  -- Name plate + dungeon name near the TOP of the artwork. retail /neprobe ej: titleBG
  -- UI-EJ-DungeonNameBg 256x64 TOP(loreBG,0,-38); title Morpheus 24 at frame TOP(0,-48).
  local titleBG = sliceTex(p, "UI-EJ-DungeonNameBg", "ARTWORK", true)   -- 256x64 native
  titleBG:SetPoint("TOP", loreBG, "TOP", 0, -38)
  p.titleBG = titleBG

  local title = p:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetWidth(256); title:SetJustifyH("CENTER")
  title:SetPoint("CENTER", titleBG, "CENTER", 0, 1)   -- vertically centred IN the name-plate overlay
  EJ.font.Set(title, EJ.font.MORPHEUS, 24, "", GameFontNormalHuge or GameFontNormalLarge)
  title:SetShadowColor(0, 0, 0, 1); title:SetShadowOffset(1, -1)
  p.title = title

  -- Show-Map button at the BOTTOM (retail BOTTOMLEFT(33,126), 48x32; UI-EJ-ShowMapBG plate +
  -- quest-map glyph). OnClick → OpenWorldMap wired in the maps slice.
  local map = CreateFrame("Button", nil, p)
  map:SetSize(48, 32)
  map:SetPoint("BOTTOMLEFT", p, "BOTTOMLEFT", 33, 126)
  local mapBG = sliceTex(map, "UI-EJ-ShowMapBG", "BACKGROUND", true)
  mapBG:SetPoint("LEFT", map, "LEFT", -3, 5)
  local mapTex = map:CreateTexture(nil, "ARTWORK")
  mapTex:SetTexture("Interface\\QuestFrame\\UI-QuestMap_Button")
  mapTex:SetSize(48, 32); mapTex:SetPoint("RIGHT", map, "RIGHT", 0, 0)
  mapTex:SetTexCoord(0.125, 0.875, 0.0, 0.5)
  local mapText = map:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  mapText:SetPoint("LEFT", map, "RIGHT", 2, 0)
  mapText:SetText(ENCOUNTER_JOURNAL_SHOW_MAP or "Show Map")
  map:SetScript("OnClick", function() if EJ.ej.ShowMap then EJ.ej.ShowMap() end end)
  EJ.tooltip.Wire(map, ENCOUNTER_JOURNAL_SHOW_MAP or "Show Map")
  p.mapButton = map

  -- "Find Group" (3.3.5-native — retail has no queue button for old dungeons):
  -- opens the Dungeon Finder in Specific mode with this dungeon ticked (Core/LFD.lua). The
  -- static LFD eye + label, right of the Show-Map row; PopulateEncounter shows it only for
  -- queueable dungeons (never raids).
  local lfd = CreateFrame("Button", nil, p)
  lfd:SetSize(28, 28)
  lfd:SetPoint("LEFT", mapText, "RIGHT", 18, 2)
  local eye = lfd:CreateTexture(nil, "ARTWORK")
  eye:SetAllPoints(lfd)
  eye:SetTexture("Interface\\LFGFrame\\LFG-Eye")   -- 8x4 sheet of 64px frames; frame 1 = static eye
  eye:SetTexCoord(0, 0.125, 0, 0.25)
  lfd.text = lfd:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  lfd.text:SetPoint("LEFT", lfd, "RIGHT", 2, -2)
  lfd.text:SetText("Find Group")
  lfd:SetScript("OnClick", function()
    if EJ.lfd and EJ.lfd.FindGroup then EJ.lfd.FindGroup(selInst) end
  end)
  EJ.tooltip.Wire(lfd, "Find Group")
  lfd:Hide(); lfd.text:Hide()
  p.lfdButton = lfd

  -- Lore text — retail LoreScrollingFont 315x95 BOTTOMLEFT(35,5); arrows-only scrollbar.
  local loreScroll = CreateFrame("ScrollFrame", "EJ_EJLoreScroll", p, "UIPanelScrollFrameTemplate")
  loreScroll:SetSize(315, 95)
  loreScroll:SetPoint("BOTTOMLEFT", p, "BOTTOMLEFT", 35, 5)
  local loreChild = CreateFrame("Frame", nil, loreScroll)
  loreChild:SetSize(315, 1)
  loreScroll:SetScrollChild(loreChild)
  local lore = loreChild:CreateFontString(nil, "ARTWORK", "GameFontBlack")
  lore:SetWidth(315)
  lore:SetJustifyH("LEFT"); lore:SetJustifyV("TOP")
  lore:SetPoint("TOPLEFT", loreChild, "TOPLEFT", 0, 0)
  if EJ.scrollbar and EJ.scrollbar.Reskin then EJ.scrollbar.Reskin(loreScroll, { hideIfUnscrollable = true }) end
  -- arrows-only: hide the thumb + track so only the two arrows show (retail lore look)
  local sbb = loreScroll.ScrollBar
  if sbb then
    local th = sbb.GetThumbTexture and sbb:GetThumbTexture(); if th then th:SetAlpha(0) end
    for _, k in ipairs({ "_ejThumbCapTop", "_ejThumbCapBot", "_ejTrackBegin", "_ejTrackEnd", "_ejTrackMiddle" }) do
      if sbb[k] then sbb[k]:SetAlpha(0) end
    end
  end
  p.lore = lore
  p.loreChild = loreChild
end

-- Right info panel: book bg, header, 4 tabs, boss list (scroll), content area
local function buildInfoPanel(enc)
  local p = CreateFrame("Frame", "EJ_EncounterJournalInfoFrame", enc)
  p:SetSize(785, 425)
  p:SetPoint("BOTTOMRIGHT", enc, "BOTTOMRIGHT", -1, 2)
  enc.info = p

  local bg = p:CreateTexture(nil, "BACKGROUND")
  bg:SetTexture(EJ.tex.localFiles[521750] or 521750)   -- UI-EJ-JournalBG
  bg:SetSize(785, 425)
  bg:SetPoint("BOTTOMRIGHT", p, "BOTTOMRIGHT", 0, 0)
  bg:SetTexCoord(0, 0.766601562, 0, 0.830078125)

  -- Two page-header strips span the full two-page width (probe: leftShadow + rightShadow,
  -- each 386x39 file 522972, TOPLEFT/TOPRIGHT(0,-11)). We only had the left half before.
  local lh = sliceTex(p, "UI-EJ-LeftPageHeader", "BACKGROUND", true)
  lh:SetDrawLayer("BACKGROUND", 3)
  lh:SetPoint("TOPLEFT", p, "TOPLEFT", 0, -11)
  local rh = sliceTex(p, "UI-EJ-RightPageHeader", "BACKGROUND", true)
  rh:SetDrawLayer("BACKGROUND", 3)
  rh:SetPoint("TOPRIGHT", p, "TOPRIGHT", 0, -11)
  p.rightHeader = rh

  -- Header titles: dungeon name (left page) + boss name (right page). Probe shows both
  -- (instanceTitle + encounterTitle) live in the info header. Set in PopulateEncounter/ShowBoss.
  p.instanceTitle = p:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  p.instanceTitle:SetPoint("TOPLEFT", p, "TOPLEFT", 70, -16)
  p.instanceTitle:SetWidth(310); p.instanceTitle:SetJustifyH("LEFT"); p.instanceTitle:SetTextColor(1, 0.82, 0)
  EJ.font.Set(p.instanceTitle, EJ.font.MORPHEUS, 16, "", GameFontNormal)
  -- Boss name — retail/MoP spec (Blizzard_EncounterJournal.xml encounterTitle): GameFontNormalLarge,
  -- justifyH LEFT, BOTTOMLEFT at the page's TOPRIGHT(-350,-36), beige (0.902,0.788,0.671), 220 wide
  -- with AutoScalingFontStringMixin (minLineHeight 9) shrinking long names. 3.3.5 has no such mixin,
  -- so p.SetEncounterTitle steps the font size down instead. Width 190 (not 220): the title spans
  -- x 435-625 of the 785 page, clear of the difficulty dropdown's visible button (~633+).
  local ENC_TITLE_W, ENC_TITLE_MIN = 190, 9
  p.encounterTitle = p:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  p.encounterTitle:SetPoint("BOTTOMLEFT", p, "TOPRIGHT", -350, -36)
  p.encounterTitle:SetWidth(ENC_TITLE_W); p.encounterTitle:SetJustifyH("LEFT")
  p.encounterTitle:SetTextColor(0.902, 0.788, 0.671)
  if p.encounterTitle.SetWordWrap then p.encounterTitle:SetWordWrap(false) end
  local encFont, encSize, encFlags = p.encounterTitle:GetFont()
  function p.SetEncounterTitle(text)
    local fs = p.encounterTitle
    if not encFont then fs:SetText(text or ""); return end
    local size = encSize
    fs:SetFont(encFont, size, encFlags); fs:SetText(text or "")
    while size > ENC_TITLE_MIN and fs:GetStringWidth() > ENC_TITLE_W do
      size = size - 1
      fs:SetFont(encFont, size, encFlags)
    end
  end

  -- Loot slot-filter dropdown (right page header; shown only on the Loot tab — retail's
  -- ItemSlotFilterType selector). Fully pcall-wrapped: it's non-critical chrome, and an error
  -- here must NOT abort buildInfoPanel (which would skip the lore-panel build → blank landing).
  pcall(function()
    if not (EJ.dropdown and EJ.dropdown.New) then return end
    local lootFilter = EJ.dropdown.New(p, nil, { width = 75 })
    lootFilter:SetPoint("TOPRIGHT", p, "TOPRIGHT", -14, -12)   -- re-anchored in p.LayoutFilters
    lootFilter:SetDefaultText(ALL or "All")
    lootFilter:SetupMenu(function(dropdown, root)
      -- Only offer the slot categories the current loot actually has (retail skips empty ones),
      -- narrowed to the selected difficulty — the menu is rebuilt on every open, so it tracks the
      -- other filters without being told. A slot that only drops on the OTHER difficulty would
      -- otherwise render an empty page that reads as "this boss drops nothing".
      local present = EJ.ej.PresentLootCategories and EJ.ej.PresentLootCategories(p.lootSource, p) or nil
      for _, f in ipairs(EJ.ej.LOOT_FILTERS) do
        local key, label = f[1], f[2]
        if key == "ALL" or not present or present[key] then
          root:CreateRadio(label,
            function() return (p.lootSlot or "ALL") == key end,
            function()
              p.lootSlot = key
              if dropdown.SetDefaultText then dropdown:SetDefaultText(label) end
              if EJ.ej.SelectTab then EJ.ej.SelectTab(p.selectedTab or 2) end
            end)
        end
      end
    end)
    lootFilter:Hide()
    p.lootFilter = lootFilter

    -- Quick-clear "X" — only up while a real slot filter is active. Sits LEFT of the slot box
    -- (the difficulty selector is its right-hand neighbour, MoP order); UIDropDownMenuTemplate's
    -- frame edge lies ~16px outside the visible box, hence the inward offset. p.LayoutFilters
    -- pushes the class dropdown further left while it is shown.
    local clear = CreateFrame("Button", nil, lootFilter)
    clear:SetSize(16, 16)
    clear:SetPoint("RIGHT", lootFilter, "LEFT", 16, 2)
    local ctex = clear:CreateTexture(nil, "OVERLAY")
    ctex:SetAllPoints(clear)
    if not (EJ.tex and EJ.tex.SetAtlas and EJ.tex.SetAtlas(ctex, "common-search-clearbutton", false)) then
      ctex:SetTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
    end
    ctex:SetAlpha(0.8)
    clear:SetScript("OnEnter", function(self)
      ctex:SetAlpha(1)
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      GameTooltip:SetText(_G.CLEAR_ALL or _G.RESET or "Clear Filter")
      GameTooltip:Show()
    end)
    clear:SetScript("OnLeave", function() ctex:SetAlpha(0.8); GameTooltip:Hide() end)
    clear:SetScript("OnClick", function()
      if PlaySound then pcall(PlaySound, "igMainMenuOptionCheckBoxOn") end
      p.ResetLootFilter()
      if EJ.ej.SelectTab then EJ.ej.SelectTab(p.selectedTab or 2) end
    end)
    clear:Hide()
    p.lootFilterClear = clear
  end)

  -- Drop back to "All". Shared by the clear button and by the difficulty selector, which resets
  -- it because a Normal table is not the Heroic one: a slot filter carried across the switch can
  -- silently empty the loot page.
  function p.ResetLootFilter()
    p.lootSlot = "ALL"
    local dd = p.lootFilter
    if dd and dd.SetDefaultText then
      local fl = EJ.ej.LOOT_FILTERS
      dd:SetDefaultText((fl and fl[1] and fl[1][2]) or ALL or "All")
    end
    if p.lootFilterClear then p.lootFilterClear:Hide() end
  end

  -- ENCOUNTER-PAGE difficulty dropdown. One selector for the whole page: filters
  -- the loot rows by bucket AND hides/shows Heroic-flagged ability sections. refreshView owns
  -- the bucket list (per-instance union, EJ.ej.InstanceDiffBuckets), the default selection,
  -- the anchor and the visibility (Loot tab + boss Abilities pages, only when ≥2 buckets).
  pcall(function()
    if not (EJ.dropdown and EJ.dropdown.New) then return end
    local diffFilter = EJ.dropdown.New(p, nil, { width = 105 })
    diffFilter:SetPoint("TOPRIGHT", p, "TOPRIGHT", -14, -12)
    diffFilter:SetupMenu(function(dropdown, root)
      for _, b in ipairs(p.lootDiffsAvail or {}) do
        local label = EJ.ej.DIFF_LABEL[b] or tostring(b)
        root:CreateRadio(label,
          function() return p.lootDiff == b end,
          function()
            p.lootDiff = b
            if dropdown.SetDefaultText then dropdown:SetDefaultText(label) end
            -- switching difficulty swaps the whole drop table → a slot filter from the old one
            -- is stale by definition and would leave the page looking empty rather than filtered
            if p.ResetLootFilter then p.ResetLootFilter() end
            if EJ.ej.SelectTab then EJ.ej.SelectTab(p.selectedTab or 2) end
          end)
      end
    end)
    diffFilter:Hide()
    p.difficultyFilter = diffFilter
  end)

  -- Class dropdown label in the chosen class's colour (MoP Classic does this); "All Classes" in
  -- the normal dropdown white. CUSTOM_CLASS_COLORS (!ClassColors etc.) wins over RAID_CLASS_COLORS.
  function p.ColorClassFilter()
    local dd = p.classFilter
    local fs = dd and dd.GetName and dd:GetName() and _G[dd:GetName() .. "Text"]
    if not fs then return end
    local tag = p.lootClass or "ALL"
    local c = (_G.CUSTOM_CLASS_COLORS and _G.CUSTOM_CLASS_COLORS[tag]) or (_G.RAID_CLASS_COLORS and _G.RAID_CLASS_COLORS[tag])
    if c then fs:SetTextColor(c.r, c.g, c.b) else fs:SetTextColor(1, 1, 1) end
  end

  -- Header filter row, MoP Classic order, right to left: Difficulty · Slot · Class. Each one
  -- anchors to its visible right-hand neighbour, so hiding the difficulty selector (single-
  -- difficulty instances) slides the others right without a gap. UIDropDownMenuTemplate frames
  -- carry ~16px of transparent padding per side, so neighbours overlap by FILTER_GAP to leave a
  -- small visible gap. Called by refreshView after it has decided what is shown.
  local FILTER_GAP = 22
  function p.LayoutFilters()
    local right, x = nil, 0
    local function place(dd, extra)
      if not (dd and dd:IsShown()) then return end
      dd:ClearAllPoints()
      if right then dd:SetPoint("TOPRIGHT", right, "TOPLEFT", FILTER_GAP - (extra or 0), 0)
      else dd:SetPoint("TOPRIGHT", p, "TOPRIGHT", -14, -12) end
      right = dd
    end
    place(p.difficultyFilter)
    place(p.lootFilter)
    place(p.classFilter, (p.lootFilterClear and p.lootFilterClear:IsShown()) and 16 or 0)
  end

  -- Loot CLASS dropdown (leftmost of the loot filters). Approximate class-usability filter;
  -- default = the player's class. Position is finalised in renderLoot (left of the difficulty
  -- filter when it's shown, else left of the slot filter) so there's no gap.
  pcall(function()
    if not (EJ.dropdown and EJ.dropdown.New) then return end
    local classFilter = EJ.dropdown.New(p, nil, { width = 90 })
    classFilter:SetPoint("TOPRIGHT", p, "TOPRIGHT", -14, -12)   -- re-anchored in p.LayoutFilters
    local _, playerClass = UnitClass("player")
    p.lootClass = p.lootClass or playerClass or "ALL"
    classFilter:SetupMenu(function(dropdown, root)
      for _, c in ipairs(EJ.ej.ClassFilters()) do
        local tag, label = c[1], c[2]
        root:CreateRadio(label,
          function() return (p.lootClass or "ALL") == tag end,
          function()
            p.lootClass = tag
            if dropdown.SetDefaultText then dropdown:SetDefaultText(label) end
            p.ColorClassFilter()
            if EJ.ej.SelectTab then EJ.ej.SelectTab(p.selectedTab or 2) end
          end)
      end
    end)
    for _, c in ipairs(EJ.ej.ClassFilters()) do
      if c[1] == p.lootClass and classFilter.SetDefaultText then classFilter:SetDefaultText(c[2]) end
    end
    classFilter:Hide()
    p.classFilter = classFilter
    p.ColorClassFilter()
  end)

  -- model/instance button (top-left) → back to the instance overview (retail parity)
  local ib = CreateFrame("Button", nil, p)
  ib:SetSize(64, 61)
  ib:SetPoint("TOPLEFT", p, "TOPLEFT", 0, -3)
  -- dungeon-specific portrait under the UI-EJ-BossModelButton ring (set per-instance)
  ib.icon = ib:CreateTexture(nil, "BACKGROUND")
  ib.icon:SetSize(40, 40)
  ib.icon:SetPoint("CENTER", ib, "CENTER", 0, 1)
  local ibN = sliceTex(ib, "UI-EJ-BossModelButton"); ibN:SetAllPoints(ib); ib:SetNormalTexture(ibN)
  local ibH = sliceTex(ib, "UI-EJ-BossModelButton"); ibH:SetAllPoints(ib); ibH:SetBlendMode("ADD"); ib:SetHighlightTexture(ibH)
  -- retail's EncounterJournalInstanceButton_OnClick = NavBar_Reset + DisplayInstance: step back
  -- ONE level (boss → instance overview), not all the way to the dungeon grid. ShowInstance
  -- clears selBoss + re-displays the overview, and RefreshNavBar→navbar.Refresh does the
  -- NavBar_Reset. (The navbar Home button is the path back to the grid, mirroring retail.)
  ib:SetScript("OnClick", function() if selInst and EJ.ej.ShowInstance then EJ.ej.ShowInstance(selInst) end end)
  EJ.tooltip.Wire(ib, BACK or "Back")
  -- Store on the info panel so PopulateEncounter can fill the per-dungeon portrait inside the
  -- ring (retail's $parentInstanceButton.icon, BACKGROUND/6). Without this the read at
  -- PopulateEncounter (enc.info.instanceButton) was nil → the ring rendered with an empty
  -- centre. The ring (UI-EJ-BossModelButton) + the portrait BLPs were already shipped; only
  -- this assignment was missing.
  p.instanceButton = ib

  -- Info tabs. Vanilla instances ship NO overview sections (EJ_HTYPE_OVERVIEW), so we follow
  -- retail's collapsed layout (Blizzard_EncounterJournal.lua:1271-1282): there is no separate
  -- "Overview" page — tab 1 keeps the Boss icon (the XML never swaps it), its tooltip becomes
  -- ABILITIES, and it shows the boss's lore description followed by the ability sections. The
  -- dedicated abilities tab (3) is HIDDEN and Model re-anchors directly below Loot (EJ.lua:1280).
  local overview = makeTab(p, 1, "UI-EJ-Tab-BossIcon-Selected",  "UI-EJ-Tab-BossIcon-UnSelected",  ABILITIES or "Abilities")
  overview:SetPoint("TOPLEFT", p, "TOPRIGHT", -4, -35)
  local loot = makeTab(p, 2, "UI-EJ-Tab-LootIcon-Selected",      "UI-EJ-Tab-LootIcon-UnSelected",  LOOT_NOUN or "Loot")
  loot:SetPoint("TOP", overview, "BOTTOM", 0, 2)
  -- tab 3 created for index stability but never shown/enabled (collapsed into tab 1, per retail).
  local boss = makeTab(p, 3, "UI-EJ-Tab-AbilitiesIcon-Selected", "UI-EJ-Tab-AbilitiesIcon-UnSelected", ABILITIES or "Abilities")
  boss:Hide()
  local model = makeTab(p, 4, "UI-EJ-Tab-ModelIcon-Selected",    "UI-EJ-Tab-ModelIcon-UnSelected",
    EJ.ej.MODEL_TAB_ENABLED and (MODEL or "Model") or ((MODEL or "Model") .. " (disabled for now)"))
  model:SetPoint("TOP", loot, "BOTTOM", 0, 2)
  p.tabs = { overview, loot, boss, model }

  -- Boss list (left page) — real scroll viewport + modern reskinned scrollbar (EJ.scrollbar).
  local bossScroll = CreateFrame("ScrollFrame", "EJ_EJBossScroll", p, "UIPanelScrollFrameTemplate")
  bossScroll:SetSize(330, 382)
  bossScroll:SetPoint("BOTTOMLEFT", p, "BOTTOMLEFT", 25, 1)
  local bossChild = CreateFrame("Frame", nil, bossScroll)
  bossChild:SetSize(330, 1)
  bossScroll:SetScrollChild(bossChild)
  if EJ.scrollbar and EJ.scrollbar.Reskin then EJ.scrollbar.Reskin(bossScroll, { hideIfUnscrollable = true }) end
  p.bossList = { scroll = bossChild, buttons = {} }

  -- Content area (right page): a text body, a loot row holder, and a creature model.
  local c = CreateFrame("Frame", nil, p)
  c:SetPoint("TOPLEFT", p, "TOPLEFT", 400, -44)
  c:SetPoint("BOTTOMRIGHT", p, "BOTTOMRIGHT", -16, 16)
  -- DO NOT call c:SetClipsChildren() here. 3.3.5a has no native SetClipsChildren; ClassicAPI's
  -- shim emulates clipping by reparenting/re-anchoring the frame into an internal clip container,
  -- which WIPES this frame's TOPLEFT+BOTTOMRIGHT anchors → it collapses to a single (0,0) point,
  -- zero size, nil rect → ALL right-page content (abilities, loot) renders invisibly. The section
  -- and loot content already live inside ScrollFrames that clip to their own viewports, so clipping
  -- here is redundant anyway. (Diagnosed via /ejdiag: content frame had numPts=1, size 0x0.)
  c.text = c:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  c.text:SetPoint("TOPLEFT"); c.text:SetWidth(360)
  c.text:SetJustifyH("LEFT"); c.text:SetJustifyV("TOP")
  c.text:Hide()
  -- Loot list — scrollable viewport + reskinned bar (drops can exceed one page, esp. the
  -- aggregated instance-wide list). c.lootFrame is the scroll CHILD (rows parent to it).
  c.lootScroll = CreateFrame("ScrollFrame", "EJ_EJLootScroll", c, "UIPanelScrollFrameTemplate")
  c.lootScroll:SetPoint("TOPLEFT", c, "TOPLEFT", 0, 0)
  c.lootScroll:SetPoint("BOTTOMRIGHT", c, "BOTTOMRIGHT", -22, 22)   -- 22px strip below for the load-all button
  c.lootFrame = CreateFrame("Frame", nil, c.lootScroll)
  c.lootFrame:SetSize(321, 1)
  c.lootScroll:SetScrollChild(c.lootFrame)
  if EJ.scrollbar and EJ.scrollbar.Reskin then EJ.scrollbar.Reskin(c.lootScroll, { hideIfUnscrollable = true }) end
  c.lootFrame.rows = {}
  c.lootScroll:Hide()
  -- "Load all items" — AtlasLoot's "Query Server" button for the whole page (throttled, see
  -- EJ.ej.QueryLootPage). Sits in the strip under the list; renderLoot shows it only while the
  -- page still has unloaded rows.
  pcall(function()
    local btn = CreateFrame("Button", "EJ_EJLootLoadAll", c, "UIPanelButtonTemplate")
    btn:SetSize(120, 20)
    btn:SetPoint("BOTTOMRIGHT", c, "BOTTOMRIGHT", -22, 0)
    btn:SetText("Load all items")
    btn:SetScript("OnClick", function() if EJ.ej.QueryLootPage then EJ.ej.QueryLootPage() end end)
    EJ.tooltip.Wire(btn, function(_, tip)
      tip:SetText("Load all items", 1, 1, 1)
      tip:AddLine("Queries the server for every unloaded item on this page, one at a time.", nil, nil, nil, true)
      tip:AddLine("Querying many items at once can disconnect you.", 1, 0.35, 0.35, true)
    end)
    btn:Hide()
    c.lootLoadAll = btn
  end)
  -- Abilities list (right page) — scrollable icon+title+body cards, the retail
  -- AbilitiesInfo look (EJ.xml "AbilitiesInfoTemplate"). Replaces the old flat text blob.
  c.sectionScroll = CreateFrame("ScrollFrame", "EJ_EJSectionScroll", c, "UIPanelScrollFrameTemplate")
  c.sectionScroll:SetPoint("TOPLEFT", c, "TOPLEFT", 0, 0)
  c.sectionScroll:SetPoint("BOTTOMRIGHT", c, "BOTTOMRIGHT", -22, 0)
  local sc = CreateFrame("Frame", nil, c.sectionScroll)
  sc:SetSize(340, 1)
  c.sectionScroll:SetScrollChild(sc)
  if EJ.scrollbar and EJ.scrollbar.Reskin then EJ.scrollbar.Reskin(c.sectionScroll, { hideIfUnscrollable = true }) end
  c.sectionChild = sc
  c.sectionWidgets = {}
  c.sectionScroll:Hide()
  p.content = c

  -- Model area — retail's $parentModelFrame is a MODELSCENE, but 3.3.5a has NO ModelScene frame
  -- type (and no SetFromModelSceneID/GetActorByTag actor API). We render with the native 3.3.5
  -- PlayerModel instead: SetDisplayInfo loads the creature, SetPosition/SetFacing/SetModelScale
  -- frame + rotate it (the classic WotLK model-viewer mechanism — same as the inspect/pet
  -- frames). `ma` is just a plain container Frame holding the bg, the PlayerModel, the paper
  -- frame, and the name. 390x423 BOTTOMRIGHT(info,-3,1). Layer order: dungeonBG BACKGROUND/1 →
  -- [3D PlayerModel] → paperFrame OVERLAY/0 → nameShadow OVERLAY/1 → name.
  local ma = CreateFrame("Frame", nil, p)
  ma:SetSize(390, 423)
  ma:SetPoint("BOTTOMRIGHT", p, "BOTTOMRIGHT", -3, 1)
  ma:Hide()
  ma.bg = ma:CreateTexture(nil, "BACKGROUND", nil, 1)
  ma.bg:SetTexture(EJ.tex.localFiles[521743] or 521743)   -- UI-EJ-BACKGROUND-Default (per-instance set in refreshView)
  -- Probe: dungeonBG is shown 394x425 from a 512x512 file via a HORIZONTALLY-FLIPPED crop
  -- (L=0.7695,R=0 → mirrored; B=0.8301). 0.7695*512≈394, 0.8301*512≈425 = exact content region.
  ma.bg:SetTexCoord(0.76953125, 0, 0, 0.83007813)
  ma.bg:SetSize(394, 425); ma.bg:SetPoint("BOTTOMLEFT", ma, "BOTTOMLEFT", 0, -2)
  -- PlayerModel fallback (hidden unless the ModelScene can't produce an actor on Era).
  ma.model = CreateFrame("PlayerModel", nil, ma)
  ma.model:SetAllPoints(ma); ma.model:Hide()
  -- paper frame OVERLAYS the model (transparent centre frames it) — retail OVERLAY/0.
  ma.shadow = ma:CreateTexture(nil, "OVERLAY", nil, 0)
  ma.shadow:SetTexture(EJ.tex.localFiles[527690] or 527690)   -- UI-EJ-BossModelPaperFrame
  -- Its OWN flipped crop (retail EJ.xml:1990), distinct from the bg's — without it the full
  -- 512² stretches to 393x424 and reads as the wrong size.
  ma.shadow:SetTexCoord(0.767578125, 0, 0, 0.828125)
  ma.shadow:SetSize(393, 424); ma.shadow:SetPoint("BOTTOMRIGHT", ma, "BOTTOMRIGHT", 3, 0)
  -- name on a child frame above EVERYTHING (scene 3D, fallback PlayerModel, paper frame).
  local nf = CreateFrame("Frame", nil, ma)
  nf:SetAllPoints(ma); nf:SetFrameLevel(ma.model:GetFrameLevel() + 2)
  ma.nameShadow = nf:CreateTexture(nil, "ARTWORK")
  EJ.ej.ApplySlice(ma.nameShadow, "UI-EJ-BossNameShadow", true)  -- 395x63
  ma.nameShadow:SetPoint("BOTTOM", nf, "BOTTOM", 0, -2)
  ma.name = nf:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  ma.name:SetSize(380, 10); ma.name:SetJustifyH("CENTER")
  ma.name:SetPoint("BOTTOM", nf, "BOTTOM", 0, 6)
  EJ.font.Set(ma.name, EJ.font.MORPHEUS, 18, "", GameFontNormalLarge)
  ma.name:SetShadowColor(0, 0, 0, 1); ma.name:SetShadowOffset(1, -1)

  -- "Nothing loaded" notice. On this client a creature whose display data hasn't been seen this
  -- session can come back empty from SetDisplayInfo (no server push of unseen display info) —
  -- say so instead of leaving the pane blank. Shown by the load verdict in _PlayerModelFallback.
  ma.unavailable = nf:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  ma.unavailable:SetPoint("CENTER", ma, "CENTER", 0, 10)
  ma.unavailable:SetWidth(300)
  ma.unavailable:SetJustifyH("CENTER")
  ma.unavailable:SetText("Model not available yet — it loads once the creature has been seen this session.")
  ma.unavailable:Hide()

  -- Drag-to-rotate. 3.3.5a has no generic Model_OnUpdate/Model_OnMouseDown FrameXML helpers to
  -- piggyback (those are Era/retail Classic/ModelFrames.lua), so we drive it ourselves: while a
  -- drag is active, accumulate the horizontal cursor delta into model.facing and feed SetFacing
  -- (the native 3.3.5 rotate). A lone overlay frame doesn't reliably catch the mouse over the 3D
  -- model, so we start/stop the drag from every frame in the stack.
  local rot = CreateFrame("Frame", nil, ma)
  rot:SetAllPoints(ma)
  rot:SetFrameLevel(ma.model:GetFrameLevel() + 1)
  ma.rotator = rot

  ma.model.facing = ma.model.facing or 0
  ma.model:SetScript("OnUpdate", function()
    if not ma._dragging then return end
    local mx = GetCursorPosition()
    mx = mx / (ma:GetEffectiveScale() or 1)        -- pixels → UI units (delta only; sign matters)
    if ma._dragX then
      ma.model.facing = (ma.model.facing or 0) + (mx - ma._dragX) * 0.025
      if ma.model.SetFacing then ma.model:SetFacing(ma.model.facing) end
    end
    ma._dragX = mx
  end)
  local function startDrag(_, btn)
    if btn and btn ~= "LeftButton" then return end
    ma._dragging, ma._dragX, ma._userRotated = true, nil, true
  end
  local function stopDrag() ma._dragging = false end
  -- Mouse wheel over the model = zoom (SetModelScale), persisted per display ID exactly like
  -- `/ej model scale <n>` — the quick way to size a boss that came in too big or too small.
  local function wheel(_, delta)
    if EJ.ej.ModelZoom then EJ.ej.ModelZoom(delta) end
  end
  for _, fr in ipairs({ ma, ma.model, nf, rot }) do
    fr:EnableMouse(true)
    fr:SetScript("OnMouseDown", startDrag)
    fr:SetScript("OnMouseUp",   stopDrag)
    fr:EnableMouseWheel(true)
    fr:SetScript("OnMouseWheel", wheel)
  end

  -- Multi-creature switcher: council-style bosses carry creatures[2..n]; retail
  -- shows one portrait button per creature that swaps the displayed model. Our portrait = the
  -- LEFT half of the shipped creature plate (creature.file — the bust sits there), stacked down
  -- the model area's left edge. Only shown when a boss has 2+ displayable creatures. The
  -- buttons sit ABOVE the drag-rotate stack (nf = model+2) so clicks reach them, not the drag.
  ma.creatureBtns = {}
  local function creatureBtn(i)
    local cb = ma.creatureBtns[i]
    if cb then return cb end
    cb = CreateFrame("Button", nil, ma)
    cb:SetSize(42, 42)
    cb:SetFrameLevel(ma.model:GetFrameLevel() + 4)
    if i == 1 then cb:SetPoint("TOPLEFT", ma, "TOPLEFT", 8, -10)
    else cb:SetPoint("TOPLEFT", ma.creatureBtns[i - 1], "BOTTOMLEFT", 0, -6) end
    cb.bg = cb:CreateTexture(nil, "BACKGROUND")
    cb.bg:SetAllPoints(cb); cb.bg:SetTexture(0, 0, 0, 0.6)
    cb.tex = cb:CreateTexture(nil, "ARTWORK")
    cb.tex:SetAllPoints(cb)
    cb.sel = cb:CreateTexture(nil, "OVERLAY")            -- gold ring on the active creature
    cb.sel:SetAllPoints(cb)
    cb.sel:SetTexture("Interface\\Buttons\\CheckButtonHilight")
    cb.sel:SetBlendMode("ADD")
    cb:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    cb:SetScript("OnEnter", function(self)
      if self.creatureName then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(self.creatureName, 1, 1, 1)
        GameTooltip:Show()
      end
    end)
    cb:SetScript("OnLeave", function() GameTooltip:Hide() end)
    cb:SetScript("OnClick", function(self)
      if self.display then
        ma._activeCreature = self.idx
        -- only the PRIMARY creature has a known npc id; the others load by display id
        ma._npcID = (self.idx == 1 and EJ.ej.EncounterNPC) and EJ.ej.EncounterNPC(selInst, selBoss) or nil
        EJ.ej.NormalizeModel(ma, self.display)
        ma.SetCreatures()                                -- refresh the selection rings
      end
    end)
    ma.creatureBtns[i] = cb
    return cb
  end

  -- (Re)fill the switcher for `boss`; calling with nil only refreshes the selection ring
  -- (after a click). refreshView calls this on every Model-tab entry, which intentionally
  -- resets the active creature to the primary one.
  function ma.SetCreatures(forEnc)
    if forEnc then ma._creatures = forEnc.creatures or {}; ma._activeCreature = 1 end
    local list, n = ma._creatures or {}, 0
    for i, cr in ipairs(list) do
      if cr.display and cr.display > 0 then
        n = n + 1
        local cb = creatureBtn(n)
        cb.idx, cb.display, cb.creatureName = i, cr.display, cr.name
        local plate = (cr.file and cr.file > 0) and cr.file or 521744   -- generic plate fallback
        cb.tex:SetTexture(EJ.tex.localFiles[plate] or plate)
        cb.tex:SetTexCoord(0, 0.5, 0, 1)
        EJ.SetShown(cb.sel, i == (ma._activeCreature or 1))
        cb:Show()
      end
    end
    for i = n + 1, #ma.creatureBtns do ma.creatureBtns[i]:Hide() end
    if n < 2 then                     -- a single-model boss needs no switcher
      for i = 1, n do ma.creatureBtns[i]:Hide() end
    end
  end

  p.modelArea = ma
end

-- Boss list population (pooled buttons)
local function acquireBossButton(list, i)
  local b = list.buttons[i]
  if b then return b end
  b = CreateFrame("Button", nil, list.scroll)
  b:SetSize(325, 55)
  local up = sliceTex(b, "UI-EJ-BossButton-Up");        up:SetAllPoints(b); b:SetNormalTexture(up)
  local hi = sliceTex(b, "UI-EJ-BossButton-Highlight"); hi:SetAllPoints(b); hi:SetBlendMode("ADD"); b:SetHighlightTexture(hi)
  local dn = sliceTex(b, "UI-EJ-BossButton-Down");      dn:SetAllPoints(b); b:SetPushedTexture(dn)
  -- creature portrait + name live on a CHILD FRAME above the button's HIGHLIGHT layer.
  -- retail uses a sub-frame (EJ.xml:577-597) so the portrait isn't covered by the hover
  -- highlight (a direct OVERLAY region on the button IS covered) — fixes the z-hierarchy.
  local cf = CreateFrame("Frame", nil, b)
  cf:SetFrameLevel(b:GetFrameLevel() + 2)
  cf:SetAllPoints(b)
  b.creature = cf:CreateTexture(nil, "ARTWORK")
  b.creature:SetSize(128, 64)                            -- per EJ.xml:585
  b.creature:SetPoint("TOPLEFT", b, "TOPLEFT", -4, 13)   -- overhangs the button top by 13
  b.name = cf:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  b.name:SetPoint("LEFT", b, "LEFT", 105, -3); b.name:SetWidth(205); b.name:SetJustifyH("LEFT")
  b.name:SetTextColor(0.827, 0.659, 0.463)
  list.buttons[i] = b
  return b
end

-- Keep the selected boss's row lit (retail locks the selected EncounterButton's highlight).
local function applyBossHighlight()
  local f = EJ.ej.frame
  local bl = f and f.encounter and f.encounter.info and f.encounter.info.bossList
  if not (bl and bl.buttons) then return end
  for _, b in ipairs(bl.buttons) do
    if b.LockHighlight then
      if b.enc and b.enc == selBoss then b:LockHighlight() else b:UnlockHighlight() end
    end
  end
end

local function fillBossList(inst)
  local list = EJ.ej.frame.encounter.info.bossList
  local encs = inst.encounters or {}
  for i, enc in ipairs(encs) do
    local b = acquireBossButton(list, i)
    b:ClearAllPoints()
    -- 15px top pad so the first boss's portrait (overhangs +13 above its button) isn't
    -- clipped by the scroll viewport.
    if i == 1 then b:SetPoint("TOPLEFT", list.scroll, "TOPLEFT", 0, -15)
    else b:SetPoint("TOPLEFT", list.buttons[i-1], "BOTTOMLEFT", 0, -2) end
    b.name:SetText(enc.name or "?")
    b.enc = enc
    local cr = enc.creatures and enc.creatures[1]
    if cr and cr.file and cr.file > 0 then
      -- 3.3.5a's SetTexture returns nil for a missing file and KEEPS the old image — on a pooled
      -- button that is the previous instance's boss. Fall back to the generic plate instead.
      if not b.creature:SetTexture(EJ.tex.localFiles[cr.file] or cr.file) then
        b.creature:SetTexture(EJ.tex.localFiles[521744])
      end
      b.creature:SetTexCoord(0, 1, 0, 1)
      b.creature:Show()
    else
      b.creature:Hide()
    end
    b:SetScript("OnClick", function()
      if PlaySound then pcall(PlaySound, "igMainMenuOptionCheckBoxOn") end
      EJ.ej.ShowBoss(enc)
    end)
    b:Show()
  end
  for i = #encs + 1, #list.buttons do list.buttons[i]:Hide() end
  applyBossHighlight()   -- restore the selected-row highlight after a (re)build
  list.scroll:SetHeight(math.max(1, #encs * 57 + 15))  -- +15 top pad; drives the scroll range
end

-- Loot rendering. 3.3.5a/ClassicAPI has NO GET_ITEM_INFO_RECEIVED (MoP+), so an uncached item
-- never streams a refresh — baked name/quality show immediately, but the real icon/link stay
-- blank until the client caches the item. We DON'T background-poll; instead loadLootItem() is
-- called on a row CLICK (AtlasLoot-style): it requests the item and does a few short repaints
-- bounded by THAT item resolving. warmLoot() is a BOUNDED batch warm used only when a class filter
-- is active (the filter needs item types). Forward-declared so earlier functions can call them.
local loadLootItem, warmLoot
-- Loot row = retail EncounterItemTemplate (EJ.xml:1078-1129): 321x45, icon 42x42 TOPLEFT(2,-2),
-- name top, slot bottom-left, armor/weapon type bottom-right, UI-EJ-LootFrame row bg, quality
-- WhiteIconFrame border. Icon/row hover → item tooltip.
local function lootRow(lf, i)
  local r = lf.rows[i]
  if r then return r end
  r = CreateFrame("Button", nil, lf)
  r:SetSize(321, 45)
  r.bg = r:CreateTexture(nil, "BORDER"); EJ.ej.ApplySlice(r.bg, "UI-EJ-LootFrame")
  r.bg:SetSize(321, 45); r.bg:SetPoint("LEFT", r, "LEFT", 0, 0)
  r.icon = r:CreateTexture(nil, "ARTWORK"); r.icon:SetSize(42, 42); r.icon:SetPoint("TOPLEFT", r, "TOPLEFT", 2, -2)
  -- rarity border: MUST be the shipped BLP — the client path Interface\Common\WhiteIconFrame
  -- is 4.x+ and renders nothing on 3.3.5 (see Core/ItemButton.lua WHITE_FRAME).
  r.iconBorder = r:CreateTexture(nil, "OVERLAY")
  r.iconBorder:SetTexture((EJ.itembtn and EJ.itembtn.WHITE_FRAME) or "Interface\\Common\\WhiteIconFrame")
  r.iconBorder:SetAllPoints(r.icon); r.iconBorder:Hide()
  r.name = r:CreateFontString(nil, "OVERLAY", "GameFontNormal")  -- retail GameFontNormalMed3; Med3 may be absent on Era
  r.name:SetWidth(250); r.name:SetJustifyH("LEFT")
  r.name:SetPoint("TOPLEFT", r.icon, "TOPRIGHT", 7, -7)
  r.slot = r:CreateFontString(nil, "OVERLAY", "GameFontBlack"); r.slot:SetJustifyH("LEFT")
  r.slot:SetPoint("BOTTOMLEFT", r.icon, "BOTTOMRIGHT", 7, 5); r.slot:SetTextColor(0.25, 0.148, 0.02)
  r.armorType = r:CreateFontString(nil, "OVERLAY", "GameFontBlack"); r.armorType:SetJustifyH("RIGHT")
  r.armorType:SetPoint("RIGHT", r, "RIGHT", -10, -6); r.armorType:SetTextColor(0.25, 0.148, 0.02)
  -- drop-chance (top-right) — NOT retail-parity; an EJ addition, sourced from AtlasLoot droprate.
  r.dropPct = r:CreateFontString(nil, "OVERLAY", "GameFontBlack"); r.dropPct:SetJustifyH("RIGHT")
  r.dropPct:SetPoint("TOPRIGHT", r, "TOPRIGHT", -10, -7); r.dropPct:SetTextColor(0.25, 0.148, 0.02)
  -- retail EncounterItemTemplate registers Left+Right so a modified click (shift=CHATLINK,
  -- ctrl=DRESSUP) reaches HandleModifiedItemClick; Era ships that helper (ItemButtonTemplate.lua).
  -- AtlasLoot-style loading: an item the client hasn't cached yet is NOT queried on hover or on a
  -- plain click — you RIGHT-CLICK it. The row says so (dimmed name, "?" icon, red hint in the type
  -- column) and the tooltip explains it. Left-click keeps retail's modified clicks (shift = chat
  -- link, ctrl = dress-up), which only work once the link is cached.
  r:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  r:SetScript("OnClick", function(self, button)
    if self.link and HandleModifiedItemClick(self.link) then
      PlaySound("igMainMenuOption"); return
    end
    if button == "RightButton" and self.itemID and not GetItemInfo(self.itemID) and loadLootItem then
      PlaySound("igMainMenuOptionCheckBoxOn")
      loadLootItem(self.itemID)
    end
  end)
  r:SetScript("OnEnter", function(self)
    if not self.itemID then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    if GetItemInfo(self.itemID) then
      if EJ.SetTooltipItem(GameTooltip, self.itemID) then GameTooltip:Show() end
    else
      -- SetItemByID/SetHyperlink on an uncached id would query the server behind the player's
      -- back; show a plain notice instead so the load stays an explicit right-click.
      -- AtlasLoot's exact wording (its LootButtons.lua OnEnter for an "unsafe" item).
      GameTooltip:SetText(self.bakedName or ("Item " .. self.itemID), 1, 1, 1)
      GameTooltip:AddLine(" ")
      GameTooltip:AddLine("Item not loaded yet.", 1, 0.35, 0.35)
      GameTooltip:AddLine("You can right-click to attempt to query the server.  You may be disconnected.", 1, 1, 1, true)
      GameTooltip:Show()
    end
  end)
  r:SetScript("OnLeave", function() GameTooltip:Hide() end)
  lf.rows[i] = r
  return r
end

local MAX_LOOT = 100   -- scrollable now; the instance-wide aggregate can be large

-- Loot slot filter (retail Enum.ItemSlotFilterType): {key, label}; key "ALL" = no filter.
EJ.ej.LOOT_FILTERS = {
  { "ALL",            ALL or "All" },
  { "INVTYPE_HEAD",   _G.INVTYPE_HEAD or "Head" },
  { "INVTYPE_NECK",   _G.INVTYPE_NECK or "Neck" },
  { "INVTYPE_SHOULDER", _G.INVTYPE_SHOULDER or "Shoulder" },
  { "INVTYPE_CLOAK",  _G.INVTYPE_CLOAK or "Back" },
  { "INVTYPE_CHEST",  _G.INVTYPE_CHEST or "Chest" },
  { "INVTYPE_WRIST",  _G.INVTYPE_WRIST or "Wrist" },
  { "INVTYPE_HAND",   _G.INVTYPE_HAND or "Hands" },
  { "INVTYPE_WAIST",  _G.INVTYPE_WAIST or "Waist" },
  { "INVTYPE_LEGS",   _G.INVTYPE_LEGS or "Legs" },
  { "INVTYPE_FEET",   _G.INVTYPE_FEET or "Feet" },
  { "MAINHAND",       _G.INVTYPE_WEAPONMAINHAND or "Main Hand" },
  { "OFFHAND",        _G.INVTYPE_WEAPONOFFHAND or "Off Hand" },
  { "INVTYPE_FINGER", _G.INVTYPE_FINGER or "Finger" },
  { "INVTYPE_TRINKET", _G.INVTYPE_TRINKET or "Trinket" },
  { "OTHER",          _G.OTHER or "Other" },
}

-- WotLK set/tier tokens. GetItemInfo reports these as Miscellaneous/"Junk" (they carry no equip
-- slot), so the type column read "Junk" for every tier piece in the game. There is no runtime flag
-- that separates a tier token from an actual grey vendor item on 3.3.5a, so this is an explicit
-- set (derived by DragonUI_NewEra from AtlasLoot's `Token` tag, minus the three pure currencies):
--   40610-40639  T7  "of the Lost <archetype>"      (Naxxramas / Sartharion / Malygos)
--   45632-45661  T8  "of the Wayward <archetype>"   (Ulduar)
--   47242        T9  Trophy of the Crusade          (Trial of the Crusader)
--   52025-52030  T10 "<archetype>'s Mark of Sanctification" (Icecrown, normal + heroic)
local TIER_TOKEN = {
  [40610]=1, [40611]=1, [40612]=1, [40613]=1, [40614]=1, [40615]=1, [40616]=1, [40617]=1,
  [40618]=1, [40619]=1, [40620]=1, [40621]=1, [40622]=1, [40623]=1, [40624]=1, [40625]=1,
  [40626]=1, [40627]=1, [40628]=1, [40629]=1, [40630]=1, [40631]=1, [40632]=1, [40633]=1,
  [40634]=1, [40635]=1, [40636]=1, [40637]=1, [40638]=1, [40639]=1, [45632]=1, [45633]=1,
  [45634]=1, [45635]=1, [45636]=1, [45637]=1, [45638]=1, [45639]=1, [45640]=1, [45641]=1,
  [45642]=1, [45643]=1, [45644]=1, [45645]=1, [45646]=1, [45647]=1, [45648]=1, [45649]=1,
  [45650]=1, [45651]=1, [45652]=1, [45653]=1, [45654]=1, [45655]=1, [45656]=1, [45657]=1,
  [45658]=1, [45659]=1, [45660]=1, [45661]=1, [47242]=1, [52025]=1, [52026]=1, [52027]=1,
  [52028]=1, [52029]=1, [52030]=1,
}
-- Quest items that GetItemInfo files under Miscellaneous/"Junk" rather than the Quest class
-- (Shadowfrost Shard, Fragment of Val'anyr, the Ulduar keeper Sigils, Head of Onyxia, …). Same
-- source; a no-op for items that already report "Quest".
local QUEST_ITEM = {
  [4631]=1, [5334]=1, [7670]=1, [7741]=1, [9234]=1, [9471]=1, [10660]=1, [10661]=1, [11325]=1,
  [12335]=1, [12336]=1, [12337]=1, [12534]=1, [12845]=1, [13523]=1, [17203]=1, [17204]=1,
  [18780]=1, [18782]=1, [18784]=1, [19017]=1, [19716]=1, [19717]=1, [19718]=1, [19719]=1,
  [19720]=1, [19721]=1, [19722]=1, [19723]=1, [19724]=1, [19939]=1, [19940]=1, [19941]=1,
  [19942]=1, [20383]=1, [21232]=1, [21237]=1, [22637]=1, [22734]=1, [23723]=1, [23735]=1,
  [23881]=1, [23886]=1, [23933]=1, [24248]=1, [25461]=1, [25462]=1, [27632]=1, [27633]=1,
  [28490]=1, [28769]=1, [29906]=1, [30808]=1, [30827]=1, [30828]=1, [30829]=1, [31085]=1,
  [31086]=1, [31721]=1, [31722]=1, [31744]=1, [31750]=1, [32459]=1, [33330]=1, [33814]=1,
  [33815]=1, [33821]=1, [33826]=1, [33827]=1, [33834]=1, [33835]=1, [33836]=1, [33840]=1,
  [33847]=1, [33858]=1, [33859]=1, [33860]=1, [33861]=1, [34157]=1, [43151]=1, [43411]=1,
  [44569]=1, [44577]=1, [44650]=1, [45038]=1, [45784]=1, [45786]=1, [45787]=1, [45788]=1,
  [45814]=1, [45815]=1, [45816]=1, [45817]=1, [49644]=1, [50226]=1, [50231]=1, [50274]=1,
  [51026]=1,
}

-- Type column text for a resolved item: the item subtype, with the two 3.3.5 mis-classes fixed.
local function lootTypeText(id, itemType, itemSubType)
  local t = itemSubType or itemType or ""
  if t == "Money(OBSOLETE)" or t == "Money" then t = _G.CURRENCY or "Currency" end
  if TIER_TOKEN[id] then t = "Tier" end
  if QUEST_ITEM[id] then t = "Quest" end
  return t
end

-- NOTE: NewEra groups loot under drop-chance headers (Extremely Rare / Very Rare / Uncommon /
-- Common / Bonus). That was tried here on 2026-09-05 and reverted the same day: our DB2 loot
-- carries no rate for most WotLK drops (pct=0) or one ≥15%, so every epic read "Common" and the
-- tier tokens / emblems (not equippable) read "Bonus". The list stays FLAT, like retail's.
-- Loot difficulty buckets (extract_ej.py `diff` bitmask: bit b set = item drops on bucket b).
-- 1 Normal / 2 Heroic (5-man); 3-6 raid sizes. diff==0/nil = no difficulty data → shows always.
EJ.ej.DIFF_LABEL = {
  [1] = _G.PLAYER_DIFFICULTY1 or "Normal",
  [2] = _G.PLAYER_DIFFICULTY2 or "Heroic",
  -- short raid labels (MoP Classic's "(10) Heroic" style) so the header filter row fits one page
  [3] = "10 " .. (_G.PLAYER_DIFFICULTY1 or "Normal"),
  [4] = "25 " .. (_G.PLAYER_DIFFICULTY1 or "Normal"),
  [5] = "10 " .. (_G.PLAYER_DIFFICULTY2 or "Heroic"),
  [6] = "25 " .. (_G.PLAYER_DIFFICULTY2 or "Heroic"),
}
local HEROIC_BUCKET = { [2] = true, [5] = true, [6] = true }   -- 5-man Heroic / 10H / 25H

-- Difficulty buckets for a whole INSTANCE (union of its encounters' loot `diff` masks), cached
-- on the instance table. The difficulty selector is per-instance like retail's —
-- stable across bosses, so a loot-less boss still offers the instance's difficulties, and the
-- selection can't get reset by walking the boss list. Vanilla instances (all diff==0) return
-- {} → no selector.
function EJ.ej.InstanceDiffBuckets(inst)
  if not inst then return {} end
  if inst._diffs then return inst._diffs end
  local avail, seen = {}, {}
  for _, e in ipairs(inst.encounters or {}) do
    for _, entry in ipairs(e.loot or {}) do
      local d = (type(entry) == "table" and entry.diff) or 0
      if d > 0 then
        for b = 1, 6 do
          if not seen[b] and bit.band(d, bit.lshift(1, b)) ~= 0 then
            seen[b] = true; avail[#avail + 1] = b
          end
        end
      end
    end
  end
  table.sort(avail)
  inst._diffs = avail
  return avail
end

-- ── Class loot filter ──────────────────────────────────────────────────────────────────────
-- Retail filters loot by class/spec via the live EJ API (per-item class/spec data we don't have
-- on 3.3.5). We approximate a CLASS filter from the item itself: armor MATERIAL the class wears at
-- max level + weapon/relic proficiency. itemType/itemSubType come from GetItemInfo (enUS strings on
-- this server). An uncached item (itemType nil) can't be classified yet → shown (stays clickable).
local CLASS_ORDER = { "WARRIOR","PALADIN","HUNTER","ROGUE","PRIEST",
                      "DEATHKNIGHT","SHAMAN","MAGE","WARLOCK","DRUID" }
local CLASS_ARMOR = { WARRIOR="Plate", PALADIN="Plate", DEATHKNIGHT="Plate",
                      HUNTER="Mail", SHAMAN="Mail", ROGUE="Leather", DRUID="Leather",
                      MAGE="Cloth", PRIEST="Cloth", WARLOCK="Cloth" }
local ARMOR_MAT      = { Cloth=true, Leather=true, Mail=true, Plate=true }
local UNIVERSAL_SLOT = { INVTYPE_NECK=true, INVTYPE_FINGER=true, INVTYPE_TRINKET=true, INVTYPE_CLOAK=true }
local SHIELD_CLASS   = { WARRIOR=true, PALADIN=true, SHAMAN=true }
local HOLDABLE_CLASS = { PRIEST=true, MAGE=true, WARLOCK=true, DRUID=true, SHAMAN=true, PALADIN=true }
local WAND_CLASS     = { PRIEST=true, MAGE=true, WARLOCK=true }
local CLASS_RELIC    = { PALADIN="Librams", DRUID="Idols", SHAMAN="Totems", DEATHKNIGHT="Sigils" }
local function wset(...) local t = {} for _, v in ipairs({...}) do t[v] = true end return t end
local CLASS_WEAPONS = {
  WARRIOR     = wset("Daggers","Fist Weapons","One-Handed Axes","One-Handed Maces","One-Handed Swords","Polearms","Staves","Two-Handed Axes","Two-Handed Maces","Two-Handed Swords","Bows","Crossbows","Guns","Thrown"),
  PALADIN     = wset("One-Handed Axes","One-Handed Maces","One-Handed Swords","Polearms","Two-Handed Axes","Two-Handed Maces","Two-Handed Swords"),
  HUNTER      = wset("Daggers","Fist Weapons","One-Handed Axes","One-Handed Swords","Polearms","Staves","Two-Handed Axes","Two-Handed Swords","Bows","Crossbows","Guns"),
  ROGUE       = wset("Daggers","Fist Weapons","One-Handed Axes","One-Handed Maces","One-Handed Swords","Bows","Crossbows","Guns","Thrown"),
  PRIEST      = wset("Daggers","One-Handed Maces","Staves"),
  DEATHKNIGHT = wset("One-Handed Axes","One-Handed Maces","One-Handed Swords","Polearms","Two-Handed Axes","Two-Handed Maces","Two-Handed Swords"),
  SHAMAN      = wset("Daggers","Fist Weapons","One-Handed Axes","One-Handed Maces","Staves","Two-Handed Axes","Two-Handed Maces"),
  MAGE        = wset("Daggers","One-Handed Swords","Staves"),
  WARLOCK     = wset("Daggers","One-Handed Swords","Staves"),
  DRUID       = wset("Daggers","Fist Weapons","One-Handed Maces","Polearms","Staves","Two-Handed Maces"),
}

-- "All Classes" + the 10 classes (localized names). Built lazily so LOCALIZED_CLASS_NAMES_* are up.
function EJ.ej.ClassFilters()
  if EJ.ej._classFilters then return EJ.ej._classFilters end
  local names = _G.LOCALIZED_CLASS_NAMES_MALE or {}
  local out = { { "ALL", _G.ALL_CLASSES or "All Classes" } }
  for _, tag in ipairs(CLASS_ORDER) do out[#out + 1] = { tag, names[tag] or tag } end
  EJ.ej._classFilters = out
  return out
end

-- Can `classTag` (or "ALL") use this item? equipLoc + itemType/itemSubType from GetItemInfo.
function EJ.ej.ClassCanUse(classTag, equipLoc, itemType, itemSubType)
  if not classTag or classTag == "ALL" then return true end
  if not (itemType and itemType ~= "") then return true end          -- uncached → can't classify yet
  if UNIVERSAL_SLOT[equipLoc] then return true end                   -- neck/ring/trinket/cloak
  if equipLoc == "INVTYPE_RELIC" then return CLASS_RELIC[classTag] == itemSubType end
  if equipLoc == "INVTYPE_SHIELD" then return SHIELD_CLASS[classTag] == true end
  if equipLoc == "INVTYPE_HOLDABLE" then return HOLDABLE_CLASS[classTag] == true end
  if itemType == "Weapon" then
    if itemSubType == "Wands" then return WAND_CLASS[classTag] == true end
    local w = CLASS_WEAPONS[classTag]
    return (w and w[itemSubType]) and true or false
  end
  if itemType == "Armor" then
    if ARMOR_MAT[itemSubType] then return CLASS_ARMOR[classTag] == itemSubType end
    return true                                                       -- misc armor (shirts/tabards)
  end
  return true                                                         -- gems/recipes/emblems/etc.
end
local LOOT_DIRECT = { INVTYPE_HEAD=1, INVTYPE_NECK=1, INVTYPE_SHOULDER=1, INVTYPE_CLOAK=1,
  INVTYPE_CHEST=1, INVTYPE_WRIST=1, INVTYPE_HAND=1, INVTYPE_WAIST=1, INVTYPE_LEGS=1, INVTYPE_FEET=1,
  INVTYPE_FINGER=1, INVTYPE_TRINKET=1 }
local function lootCategory(equipLoc)
  if equipLoc == "INVTYPE_ROBE" then return "INVTYPE_CHEST" end
  if LOOT_DIRECT[equipLoc] then return equipLoc end
  if equipLoc == "INVTYPE_WEAPONMAINHAND" or equipLoc == "INVTYPE_2HWEAPON" or equipLoc == "INVTYPE_WEAPON"
     or equipLoc == "INVTYPE_RANGED" or equipLoc == "INVTYPE_RANGEDRIGHT" or equipLoc == "INVTYPE_THROWN" then
    return "MAINHAND"
  end
  if equipLoc == "INVTYPE_WEAPONOFFHAND" or equipLoc == "INVTYPE_SHIELD" or equipLoc == "INVTYPE_HOLDABLE" then
    return "OFFHAND"
  end
  return "OTHER"
end

-- Does a loot row pass the encounter-page difficulty selection? `d` is the extract_ej.py bitmask
-- (bit b set = drops on bucket b); 0/nil = no difficulty data → always shown.
local function passesDifficulty(info, d)
  local sel = info and info.lootDiff
  if sel and d and d ~= 0 and bit.band(d, bit.lshift(1, sel)) == 0 then return false end
  return true
end

-- The slot categories actually PRESENT in a loot list (narrowed to the selected difficulty when
-- `info` is given), so the slot dropdown never offers a category that would render an empty page.
-- Resolvable items classify by their equip slot; rows with only a baked name (not cached yet)
-- render under OTHER, so they count as OTHER here too.
function EJ.ej.PresentLootCategories(items, info)
  local present = {}
  for i = 1, #(items or {}) do
    local entry = items[i]
    local isTab = type(entry) == "table"
    local id = isTab and entry.id or entry
    local d  = isTab and entry.diff or 0
    if id and passesDifficulty(info, d) then
      local name, _, _, _, _, _, _, _, equipLoc = GetItemInfo(id)
      local ii = EJ.ej.ITEM_INFO and EJ.ej.ITEM_INFO[id]
      if name then present[lootCategory(equipLoc or "")] = true
      elseif (isTab and entry.name and entry.name ~= "") or (ii and ii[1]) then present.OTHER = true end
    end
  end
  return present
end

-- Loot sub-header (LootData.lua: Ulduar "Hard Mode", Yogg-Saron's keeper tiers): a title in
-- the parchment ink colour over a thin rule, the width of a loot row.
local LOOT_HEADER_H = 30
local function lootHeader(lf, i)
  lf.headers = lf.headers or {}
  local h = lf.headers[i]
  if h then return h end
  h = CreateFrame("Frame", nil, lf)
  h:SetSize(321, LOOT_HEADER_H)
  h.text = h:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  h.text:SetPoint("BOTTOMLEFT", h, "BOTTOMLEFT", 4, 7)
  h.text:SetJustifyH("LEFT")
  h.text:SetTextColor(0.25, 0.148, 0.02)
  if EJ.font and EJ.font.Set then EJ.font.Set(h.text, EJ.font.MORPHEUS, 15, "", GameFontNormalLarge) end
  h.rule = h:CreateTexture(nil, "ARTWORK")
  h.rule:SetTexture(0.25, 0.148, 0.02, 0.45)
  h.rule:SetHeight(1)
  h.rule:SetPoint("BOTTOMLEFT", h, "BOTTOMLEFT", 2, 3)
  h.rule:SetPoint("BOTTOMRIGHT", h, "BOTTOMRIGHT", -2, 3)
  lf.headers[i] = h
  return h
end

local function renderLoot(boss, preserveScroll)
  local info = EJ.ej.frame.encounter.info
  local lf = info.content.lootFrame
  local items = boss and boss.loot or {}
  -- The on-demand repaints pass only { loot = lootSource }; keep the boss id (loot groups) when
  -- they repaint the same list.
  local bossID = boss and boss.id
  if not bossID and items == info.lootSource then bossID = info.lootBossID end
  info.lootBossID = bossID
  -- Remember the list currently shown so the on-demand repaints (loadLootItem / warmLoot) re-render
  -- THIS view as items resolve — both the boss page and the instance-landing aggregate.
  info.lootSource = items
  -- Difficulty selection is ENCOUNTER-PAGE-WIDE: refreshView owns the bucket list
  -- (per-instance via EJ.ej.InstanceDiffBuckets), the selection default and the dropdown
  -- visibility, BEFORE dispatching here. This renderer only applies the per-row filter.
  -- Class filter: shown on the Loot tab (position: info.LayoutFilters). Per-row usability check
  -- happens in the loop below.
  local cls = info.lootClass or "ALL"
  if info.classFilter then
    EJ.SetShown(info.classFilter, info.selectedTab == 2)
    if info.LayoutFilters then info.LayoutFilters() end
  end

  local filter = info.lootSlot or "ALL"

  -- Resolve + filter, in data order (a flat list, like retail's). Baked name/quality
  -- (AtlasLoot-style) show immediately; the real icon/link only appear once the client caches the
  -- item. We DON'T background-poll — GetItemInfo already pings the server passively, and a click
  -- on the row (loadLootItem) force-caches + repaints on demand.
  -- Grouped loot (LootData.lua, per boss): ungrouped rows first, then each group under its own
  -- sub-header, which only appears when at least one of its rows survives the filters. The
  -- instance-landing aggregate (no boss id) stays flat.
  local groupOf = bossID and EJ.ej.LOOT_GROUP and EJ.ej.LOOT_GROUP[bossID]
  local passes = { { key = false } }
  if groupOf then
    for _, g in ipairs(EJ.ej.LOOT_GROUPS or {}) do passes[#passes + 1] = g end
  end
  local vis, prev, anyUncached, uncached = 0, nil, false, 0
  local nHead, height, pendingHeader = 0, 0, nil
  for _, pass in ipairs(passes) do
  pendingHeader = pass.key and pass.label or nil
  for i = 1, #items do
    if vis >= MAX_LOOT then break end
    -- loot schema is { {id=ITEMID, pct=DROP%, diff=MASK, name=, q=}, ... }; tolerate a bare id too.
    local entry = items[i]
    local isTab = type(entry) == "table"
    local entryID = isTab and entry.id or entry
    if ((groupOf and groupOf[entryID]) or false) == pass.key then
    local id  = isTab and entry.id  or entry
    local pct = isTab and entry.pct or 0
    local d   = isTab and entry.diff or 0
    local name, link, quality, _, _, itemType, itemSubType, _, equipLoc, icon = GetItemInfo(id)
    local cached = name ~= nil
    if not itemType then anyUncached = true end   -- can't class-classify until the item caches
    -- Not cached: the row's baked name/quality (TBC/WotLK data), else item_info.lua (AtlasLoot
    -- names + this client's DBC icons — the Classic tier bakes nothing, so without this every
    -- uncached Classic row vanished on a fresh item cache).
    local ii = EJ.ej.ITEM_INFO and EJ.ej.ITEM_INFO[id]
    if not name and isTab and entry.name and entry.name ~= "" then name = entry.name; quality = quality or entry.q end
    if not name and ii and ii[1] then name = ii[1]; quality = quality or ii[2] end
    if not passesDifficulty(info, d) then
      -- hidden by the difficulty filter (item doesn't drop on the selected difficulty)
    elseif not EJ.ej.ClassCanUse(cls, equipLoc, itemType, itemSubType) then
      -- hidden by the class filter (uncached items pass — they can't be classified yet)
    elseif not (name and name ~= "") then
      -- no baked name and not cached yet (rare, ~7 items) → no row until the client resolves it
    elseif filter == "ALL" or lootCategory(equipLoc or "") == filter then
      if pendingHeader then
        nHead = nHead + 1
        local h = lootHeader(lf, nHead)
        h:ClearAllPoints()
        if not prev then h:SetPoint("TOPLEFT", lf, "TOPLEFT", 0, 0)
        else h:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", 0, -2) end
        h.text:SetText(pendingHeader)
        h:Show()
        prev, pendingHeader = h, nil
        height = height + LOOT_HEADER_H + 2
      end
      vis = vis + 1
      local r = lootRow(lf, vis)
      r:ClearAllPoints()
      if not prev then r:SetPoint("TOPLEFT", lf, "TOPLEFT", 0, 0)
      else r:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", 0, -2) end
      prev = r
      height = height + 47
      r.itemID = id
      r.link = link   -- HandleModifiedItemClick needs the link, not the id, to chat-link/dress-up
      r.bakedName = name
      r.name:SetText(name)
      local col = EJ.itembtn.TextColor(quality or 1)
      if col then
        r.name:SetTextColor(col.r, col.g, col.b)
        r.iconBorder:SetVertexColor(col.r, col.g, col.b); r.iconBorder:Show()
      else
        r.name:SetTextColor(1, 1, 1); r.iconBorder:Hide()
      end
      if cached then
        r.icon:SetTexture(icon or "Interface\\Icons\\INV_Misc_QuestionMark")
        r.slot:SetText((equipLoc and equipLoc ~= "" and _G[equipLoc]) or "")
        r.armorType:SetText(lootTypeText(id, itemType, itemSubType))
      else
        -- NOT loaded yet ("unsafe" in AtlasLoot terms): the item's own icon when the DBC table knows
        -- it (else "?") inside a RED border — the same cue AtlasLoot draws — plus the hint where the
        -- type column would be.
        local ic = ii and ii[3]
        r.icon:SetTexture(ic and ("Interface\\Icons\\" .. ic) or "Interface\\Icons\\INV_Misc_QuestionMark")
        r.iconBorder:SetVertexColor(1, 0.1, 0.1); r.iconBorder:Show()
        r.slot:SetText("")
        r.armorType:SetText("|cffff5555Right-click to load|r")
        uncached = uncached + 1
      end
      -- drop% (EJ addition): show only when a rate was recorded (pct>0)
      r.dropPct:SetText(pct and pct > 0 and string.format("%.1f%%", pct) or "")
      r:Show()
    end
    end   -- group match
  end
  end     -- passes
  for i = vis + 1, #lf.rows do lf.rows[i]:Hide() end
  for i = nHead + 1, #(lf.headers or {}) do lf.headers[i]:Hide() end
  lf:SetHeight(math.max(1, height))   -- rows 45 + 2 gap, headers 30 + 2; drives the loot scroll range
  -- "Load all items" (AtlasLoot's Query Server button) only while something on the page is unloaded.
  local btn = info.content.lootLoadAll
  if btn and not btn._ejBusy then EJ.SetShown(btn, uncached > 0) end
  -- Reset scroll only when switching into a fresh view; a streaming re-render keeps the
  -- user's place (otherwise every item that arrives would snap the list back to the top).
  if not preserveScroll and lf:GetParent().SetVerticalScroll then lf:GetParent():SetVerticalScroll(0) end
  -- The class filter needs each item's type (GetItemInfo), so when a specific class is selected we
  -- warm the list ONCE (bounded — see warmLoot), letting uncached rows classify. "All Classes"
  -- needs no item data → stays pure click-to-load.
  if cls ~= "ALL" and anyUncached and warmLoot then warmLoot() end
end

-- On-demand item loader (AtlasLoot-style, triggered by a row CLICK — no background polling). 3.3.5
-- has no GET_ITEM_INFO_RECEIVED, and the item arrives from the server a moment after the request,
-- so we do a few SHORT delayed repaints bounded by THIS item resolving (or ~2s), then stop.
-- Issue the server item query for one id (EJ.RequestItem, Core/Compat.lua: a hidden-tooltip
-- SetHyperlink — AtlasLoot's mechanism — plus ClassicAPI's RequestLoadItemDataByID when loaded).
-- The answer lands in the item cache a moment later; there is no event for it on this client, so
-- callers repaint on a timer.
local queryItem = EJ.RequestItem

-- Right-click on a row: query THIS item, then repaint the open loot view a few times (bounded by
-- the item resolving, or ~2s) so the row fills in as soon as the server answers.
loadLootItem = function(itemID)
  if not itemID then return end
  queryItem(itemID)
  local n = 0
  local function repaint()
    n = n + 1
    local inf = EJ.ej.frame and EJ.ej.frame.encounter and EJ.ej.frame.encounter.info
    if inf and inf.selectedTab == 2 and inf.lootSource then renderLoot({ loot = inf.lootSource }, true) end
    if n < 6 and not GetItemInfo(itemID) then EJ.After(0.3, repaint) end
  end
  EJ.After(0.2, repaint)
end

-- "Load all items": query every unloaded item of the open loot page, one every 0.15s (AtlasLoot's
-- Query Server button does the same with a 30ms busy-wait; rapid-fire item queries are what gets
-- people disconnected, hence the spacing), repainting every 10 items and at the end. A new page or
-- a second click supersedes a running batch.
local queryTicket = 0
function EJ.ej.QueryLootPage()
  local info = EJ.ej.frame and EJ.ej.frame.encounter and EJ.ej.frame.encounter.info
  local items = info and info.lootSource
  if not items then return end
  local ids, seen = {}, {}
  for i = 1, #items do
    local e = items[i]
    local id = (type(e) == "table") and e.id or e
    if id and not seen[id] and not GetItemInfo(id) then seen[id] = true; ids[#ids + 1] = id end
    if #ids >= MAX_LOOT then break end
  end
  local btn = info.content and info.content.lootLoadAll
  if #ids == 0 then
    if btn then btn:Hide() end
    return
  end
  queryTicket = queryTicket + 1
  local ticket, i = queryTicket, 0
  local function repaint()
    if info.selectedTab == 2 and info.lootSource == items then renderLoot({ loot = items }, true) end
  end
  local function step()
    if ticket ~= queryTicket then return end
    i = i + 1
    local id = ids[i]
    if not id then
      if btn then btn._ejBusy = nil; btn:SetText("Load all items"); btn:Enable() end
      repaint()
      return
    end
    queryItem(id)
    if btn then btn:SetText(("Loading %d/%d"):format(i, #ids)) end
    if i % 10 == 0 then repaint() end
    EJ.After(0.15, step)
  end
  if btn then btn._ejBusy = true; btn:Disable() end
  step()
end

-- BOUNDED batch warm for the CLASS filter (which needs each item's type). GetItemInfo in renderLoot
-- already pings the server; this re-renders the open list a FEW times (~1.2s total) so the freshly
-- cached items classify, then STOPS. Not the continuous poller — it self-limits to `ticks` runs.
local warming
warmLoot = function()
  if warming then return end
  warming = true
  local ticks = 3
  local function tick()
    ticks = ticks - 1
    local inf = EJ.ej.frame and EJ.ej.frame.encounter and EJ.ej.frame.encounter.info
    if inf and inf.selectedTab == 2 and inf.lootSource then renderLoot({ loot = inf.lootSource }, true) end
    if ticks > 0 then EJ.After(0.4, tick) else warming = false end
  end
  EJ.After(0.3, tick)
end

-- NOTE: no GET_ITEM_INFO_RECEIVED watcher — that event is MoP+ and NEVER fires on 3.3.5a
-- (a dead handler shipped here until 2026-07). Uncached items refresh through the baked
-- name/quality fallback + click-to-load (loadLootItem) + the bounded warmLoot() batch above.

-- Display a creature in the model area on the native 3.3.5 PlayerModel (no ModelScene on
-- 3.3.5a). We frame the creature by hand: SetDisplayInfo loads it, then SetPosition(x,y,z) +
-- SetFacing + SetModelScale place it. The 3.3.5 camera is fixed at the origin looking down +X
-- and the MODEL is moved: larger x = further away (fits bigger creatures); a negative z lowers
-- the model so its eye-height point centres in the frame; y pans horizontally. Per-boss framing
-- comes from Models.lua's size-fitted MODEL_CAM (cdist≈distance → x, ctz≈eye height → -z);
-- MODEL_TWEAKS overrides outliers (live via /ej model) and may give explicit x/y/z/facing/mscale.
EJ.ej.MODEL_TWEAKS = EJ.ej.MODEL_TWEAKS or {}
-- Per-display-ID raw MODEL PATH overrides: the boss loads through Model:SetModel(path) instead of
-- SetDisplayInfo(displayID). For bosses whose display info the client won't resolve (the red "?"
-- / blank pane) a direct .m2 path sidesteps the creature-display lookup entirely. Keyed by the
-- boss's data display ID; a persisted `/ej model path <file>` tweak wins over this table, and
-- `/ej model path none` disables a default for that boss.
--   15945 Kel'Thuzad (Naxxramas) → creature\lich\lich.m2   (test case, 2026-09-05)
EJ.ej.MODEL_PATH = EJ.ej.MODEL_PATH or {
  [15945] = "Creature\\Lich\\Lich.m2",
}
-- Baked per-boss framing defaults (same keys as the live tweaks: mscale / x / y / z / facing).
-- A persisted `/ej model …` or wheel-zoom tweak for the same display ID replaces the whole entry.
--   15945 Kel'Thuzad (raw lich.m2): tuned in-client 2026-09-05 — x=-2 (pulled toward the camera),
--   scale 0.8; the model's own cam entry (cdist 2.4 / ctz 0.57) supplies the height.
EJ.ej.MODEL_TWEAKS[15945] = EJ.ej.MODEL_TWEAKS[15945] or { x = -2, mscale = 0.8 }
EJ.ej.DEFAULT_MODEL_SCALE = EJ.ej.DEFAULT_MODEL_SCALE or 1   -- global zoom (tune /ej model global N; <1 = smaller)

-- How a boss model is loaded (persisted in EncounterJournalDB.ejModelMode; `/ej model mode <m>`):
--   "file"    (default) every display the client's own DBC tables map to a creature model file
--             (Models.lua, non-humanoid) loads that .m2 via Model:SetModel — the ONLY path that
--             has been seen to work on this client (the Kel'Thuzad test). Humanoid displays (a shared
--             character body dressed via CreatureDisplayInfoExtra) still go through SetDisplayInfo,
--             since SetModel would show a bare base body.
--   "auto"    SetDisplayInfo first; if the pane is still empty after 0.5s, fall back to the file.
--   "display" SetDisplayInfo only (no file fallback) — for comparing what the client does natively.
--   "creature" (default) Model:SetCreature(npcID) — the standard 3.3.5 way: the client queries the
--             creature from the server (like an item) and then renders the display WITH its skin
--             textures and scale. Needs the npc id (Classic: the encounter id itself; TBC/WotLK:
--             Models.lua from the DBM mods). Empty after the retries → the model file (untextured,
--             but visible), else SetDisplayInfo.
EJ.ej.MODEL_MODES = { creature = true, file = true, auto = true, display = true }
function EJ.ej.ModelMode()
  local m = EJ.db and EJ.db.ejModelMode
  return (m and EJ.ej.MODEL_MODES[m]) and m or "creature"
end

-- The npc (creature) id behind an encounter's primary creature, or nil. Classic encounter ids ARE
-- cmangos npc ids (the extractor keyed them so); TBC/WotLK ids are JournalEncounter ids, resolved
-- through EJ.ej.NPC_ID (Models.lua).
function EJ.ej.EncounterNPC(inst, enc)
  if not enc then return nil end
  local t = EJ.ej.NPC_ID and EJ.ej.NPC_ID[enc.id]
  if t and t[1] then return t[1] end
  if inst and not inst._tbc and not inst._wotlk and enc.id and enc.id > 0 then return enc.id end
  return nil
end
EJ.ej.DEFAULT_CAM_DIST    = EJ.ej.DEFAULT_CAM_DIST    or 4   -- default model depth (x) when no per-boss cam
EJ.ej.DEFAULT_CAM_TARGET  = EJ.ej.DEFAULT_CAM_TARGET  or 0.7 -- default eye height; the model drops by this (z = -target)

-- Render `displayID` into ma.model, framed for 3.3.5. (Keeps the historical name; it is now the
-- one and only model path, not a fallback.)
function EJ.ej._PlayerModelFallback(ma, displayID)
  local model = ma and ma.model
  if not model then return end
  if not (displayID and displayID > 0) then
    pcall(model.ClearModel, model); model:Hide()
    return
  end
  -- The tweak table is STORED (not a throwaway {}), so the wheel zoom / live tuner can mutate the
  -- same table this closure's frame() reads and re-frame without reloading the model.
  local t = EJ.ej.MODEL_TWEAKS[displayID]
  if not t then t = {}; EJ.ej.MODEL_TWEAKS[displayID] = t end
  local cam = (EJ.ej.MODEL_CAM and EJ.ej.MODEL_CAM[displayID]) or {}   -- per-boss camera (Models.lua)
  model.facing = t.facing or 0   -- resting rotation; the drag handler updates it from here

  local function frame()
    pcall(function()
      -- ma._dbScale = the display's CreatureModelScale when the model came in as a raw file
      -- (SetDisplayInfo applies that scale itself; SetModel does not).
      model:SetModelScale((t.mscale or EJ.ej.DEFAULT_MODEL_SCALE or 1) * (ma._dbScale or 1))
      -- Don't re-place once the user has drag-rotated (avoids a mid-drag snap); just re-assert facing.
      if ma._userRotated then model:SetFacing(model.facing or 0); return end
      -- cdist (model distance) → x depth; ctz (eye height) → -z so that point centres. Explicit
      -- x/y/z in MODEL_TWEAKS win for hand-tuned outliers.
      local x = t.x or t.cdist or cam.cdist or EJ.ej.DEFAULT_CAM_DIST or 4
      local y = t.y or 0
      local z = t.z or -(t.ctz or cam.ctz or EJ.ej.DEFAULT_CAM_TARGET or 0.7)
      model:SetPosition(x, y, z)
      model:SetFacing(model.facing or 0)
    end)
  end

  -- What to load. Precedence:
  --   1. an explicit raw path (tweak `model` from `/ej model path`, else EJ.ej.MODEL_PATH) → SetModel
  --   2. mode "file": the client's own model file for this display (Models.lua, non-humanoid)
  --      → SetModel, times the display's CreatureModelScale
  --   3. SetDisplayInfo(loadID) (loadID may be redirected by `/ej model display <id>`); in mode
  --      "auto" an empty pane after 0.5s falls back to 2.
  local loadID = t.display or displayID
  local mode   = EJ.ej.ModelMode()
  local db     = EJ.ej.MODEL_PATH_DB and EJ.ej.MODEL_PATH_DB[loadID]
  local dbOK   = db and db.path and not db.humanoid
  local path = t.model
  if path == nil then path = EJ.ej.MODEL_PATH and EJ.ej.MODEL_PATH[displayID] end
  if path == "" then path = nil end
  -- npc id for the creature path: a persisted `/ej model npc <id>` tweak, else what refreshView /
  -- the creature switcher resolved for this boss (nil = unknown → display/file instead)
  local npc = (not path) and mode == "creature" and (t.npc or ma._npcID) or nil
  ma._dbScale = 1
  ma._loadSource = path and "path" or (npc and "creature") or "display"
  if not path and not npc and mode == "file" and dbOK then
    path = db.path; ma._dbScale = db.scale or 1; ma._loadSource = "file"
  end
  local function load()
    pcall(model.ClearModel, model)
    if path then pcall(model.SetModel, model, path)
    elseif npc then pcall(model.SetCreature, model, npc)
    else pcall(model.SetDisplayInfo, model, loadID) end
  end
  local function loadedOK()
    local m = model.GetModel and model:GetModel()
    return type(m) == "string" and m ~= ""
  end

  -- Show FIRST: the 3.3.5a engine silently skips a model load while the frame (or any ancestor)
  -- is hidden, so loading into a hidden PlayerModel left the pane blank / a red "?" until
  -- something re-issued the load. refreshView shows the whole model area before calling here.
  model:Show()
  if ma.unavailable then ma.unavailable:Hide() end
  ma._activeDisplayID = displayID   -- token: stale timer callbacks from a previous boss bail out
  load()
  frame()
  ma._frameModel = frame   -- exposed so a live re-tune can re-apply framing
  -- 3.3.5 has no reliable OnModelLoaded event; re-assert shortly after in case the model
  -- streamed in late (ClassicAPI provides C_Timer). The first load of a session can also race
  -- the client's own data lookup and come back empty — re-issue it once, then give a verdict.
  if EJ.After then
    EJ.After(0.05, frame)
    EJ.After(0.15, function()
      if ma._activeDisplayID ~= displayID or ma._userRotated or not model:IsShown() then return end
      load(); frame()
    end)
    -- The creature query is answered by the SERVER (the first one of a session can take seconds),
    -- so SetCreature is re-issued at 0.5/1/2/3.5/5s while the pane is still empty, with a "loading"
    -- notice up meanwhile, and only judged at 6.5s — falling back to the untextured file earlier
    -- than that turned a slow answer into a permanently white boss.
    if ma._loadSource == "creature" and ma.unavailable then
      ma.unavailable:SetText("Loading model from the server…")
      ma.unavailable:Show()
    end
    local function creatureRetry()
      if ma._activeDisplayID ~= displayID or not model:IsShown() then return end
      if ma._loadSource ~= "creature" then return end
      if loadedOK() then
        if ma.unavailable then ma.unavailable:Hide() end
        frame()
      else
        load(); frame()
      end
    end
    for _, delay in ipairs({ 0.5, 1.0, 2.0, 3.5, 5.0 }) do EJ.After(delay, creatureRetry) end
    local function fallbackToFile()
      path = db.path; ma._dbScale = db.scale or 1; ma._loadSource = "file"
      load(); frame()
      EJ.After(0.3, function()
        if ma._activeDisplayID ~= displayID then return end
        frame()
        if ma.unavailable then EJ.SetShown(ma.unavailable, not loadedOK()) end
      end)
    end
    local function verdict()
      if ma._activeDisplayID ~= displayID then return end
      frame()
      local ok = loadedOK()
      if ma.unavailable then
        ma.unavailable:SetText("Model not available yet — it loads once the creature has been seen this session.")
      end
      -- mode "auto": SetDisplayInfo left the pane empty → the display's model file, like an
      -- explicit `/ej model path` would (humanoid displays excluded: SetModel shows a bare body).
      -- (also in "creature" mode, for bosses whose npc id is unknown and so loaded by display)
      if not ok and ma._loadSource == "display" and (mode == "auto" or mode == "creature") and dbOK then
        return fallbackToFile()
      end
      -- mode "creature": the server never answered (or the id is wrong) → the model file if the
      -- client has one, else SetDisplayInfo.
      if not ok and ma._loadSource == "creature" then
        if dbOK then return fallbackToFile() end
        npc = nil; ma._loadSource = "display"; load(); frame()
        EJ.After(0.3, function()
          if ma._activeDisplayID ~= displayID then return end
          frame()
          if ma.unavailable then EJ.SetShown(ma.unavailable, not loadedOK()) end
        end)
        return
      end
      if ma.unavailable then EJ.SetShown(ma.unavailable, not ok) end
    end
    -- display/file/path loads are local → verdict at 0.5s; a creature query waits for the server.
    EJ.After(ma._loadSource == "creature" and 6.5 or 0.5, verdict)
  end
end

function EJ.ej.NormalizeModel(ma, displayID)
  if not ma then return end
  local model = ma.model
  EJ.ej._cur = { ma = ma, display = displayID }   -- for the /ej model live-tuning command
  if model then model.facing = 0 end              -- each model starts unrotated
  ma._userRotated = false                          -- re-allow framing for the new model
  -- Load persisted live-tuned overrides (from /ej model) once per session, so tuned models
  -- stay correct across reloads until we bake them into the static table.
  if not EJ.ej._tweaksLoaded and EncounterJournalDB then
    EJ.ej.MODEL_TWEAKS = EJ.ej.MODEL_TWEAKS or {}
    for d, t in pairs(EncounterJournalDB._ejTweaks or {}) do EJ.ej.MODEL_TWEAKS[d] = t end
    if EncounterJournalDB._ejGlobalMScale then EJ.ej.DEFAULT_MODEL_SCALE = EncounterJournalDB._ejGlobalMScale end
    EJ.ej._tweaksLoaded = true
  end
  EJ.ej._PlayerModelFallback(ma, displayID)
end

-- Wheel zoom on the model area: ±10% model scale per notch, clamped 0.1…5, persisted per display
-- ID (the same `mscale` `/ej model scale <n>` writes) and applied live through the model's own
-- re-frame closure — no reload, no chat spam.
function EJ.ej.ModelZoom(delta)
  local cur = EJ.ej._cur
  local d = cur and cur.display
  if not d then return end
  local t = EJ.ej.MODEL_TWEAKS[d]
  if not t then t = {}; EJ.ej.MODEL_TWEAKS[d] = t end
  local s = t.mscale or EJ.ej.DEFAULT_MODEL_SCALE or 1
  s = s * (((delta or 0) > 0) and 1.1 or 0.9)
  if s < 0.1 then s = 0.1 elseif s > 5 then s = 5 end
  t.mscale = math.floor(s * 100 + 0.5) / 100
  local db = EJ.db or EncounterJournalDB
  if db then
    db._ejTweaks = db._ejTweaks or {}
    db._ejTweaks[d] = t
  end
  if cur.ma and cur.ma._frameModel then cur.ma._frameModel() end
end

-- Live framing tuner behind `/ej model …` (slash handler in EncounterJournal.lua). Writes the
-- tweak for the CURRENTLY SHOWN display ID into MODEL_TWEAKS, persists it in the SavedVariables
-- (`_ejTweaks`, merged back by NormalizeModel after a reload) and re-frames the visible model
-- immediately. field: x|y|z|facing|scale <n> · global <n> (default zoom) · path <file>|none|clear
-- (load a raw .m2 instead of the display ID) · display <id>|clear (load another display ID) ·
-- reset · nil = status. `raw` is the untouched argument text (paths aren't numbers).
function EJ.ej.ModelTune(field, value, raw)
  local cf = _G.DEFAULT_CHAT_FRAME
  local function say(msg) if cf then cf:AddMessage("|cff66ccffEJ model|r " .. msg) end end
  local cur = EJ.ej._cur
  local d = cur and cur.display
  local db = EJ.db or EncounterJournalDB
  local function persist(t)
    if not db then return end
    db._ejTweaks = db._ejTweaks or {}
    db._ejTweaks[d] = t
  end

  if field == "mode" then
    local m = (raw or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
    if EJ.ej.MODEL_MODES[m] then
      if db then db.ejModelMode = m end
      say("load mode = " .. m .. " (creature = SetCreature(npc) with textures, file = client model file, auto = display then file, display = display only)")
    else
      say("load mode = " .. EJ.ej.ModelMode() .. "  (/ej model mode creature|file|auto|display)")
      return
    end
  elseif field == "path" and d then
    local t = EJ.ej.MODEL_TWEAKS[d] or {}
    EJ.ej.MODEL_TWEAKS[d] = t
    local arg = (raw or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if arg == "" or arg:lower() == "clear" then
      t.model = nil
      say(("display %d: path override cleared%s"):format(d,
        (EJ.ej.MODEL_PATH and EJ.ej.MODEL_PATH[d]) and (" (default " .. EJ.ej.MODEL_PATH[d] .. " applies)") or ""))
    elseif arg:lower() == "none" then
      t.model = ""
      say(("display %d: loads via display ID again (default path disabled)"):format(d))
    else
      t.model = arg:gsub("/", "\\")
      say(("display %d: model path = %s"):format(d, t.model))
    end
    persist(t)
  elseif field == "npc" and d then
    local t = EJ.ej.MODEL_TWEAKS[d] or {}
    EJ.ej.MODEL_TWEAKS[d] = t
    if value and value > 0 then
      t.npc = value
      say(("display %d: loads creature (npc) %d via SetCreature"):format(d, value))
    else
      t.npc = nil
      say(("display %d: npc override cleared"):format(d))
    end
    persist(t)
  elseif field == "display" and d then
    local t = EJ.ej.MODEL_TWEAKS[d] or {}
    EJ.ej.MODEL_TWEAKS[d] = t
    if value and value > 0 then
      t.display = value
      say(("display %d: loads display ID %d instead"):format(d, value))
    else
      t.display = nil
      say(("display %d: display override cleared"):format(d))
    end
    persist(t)
  elseif field == "global" then
    if value then
      EJ.ej.DEFAULT_MODEL_SCALE = value
      if db then db._ejGlobalMScale = value end
      say("global scale = " .. value)
    else
      say("global scale = " .. tostring(EJ.ej.DEFAULT_MODEL_SCALE))
      return
    end
  elseif not d then
    say("no model shown — open a boss's Model tab first")
    return
  elseif field == "reset" then
    EJ.ej.MODEL_TWEAKS[d] = nil
    if db and db._ejTweaks then db._ejTweaks[d] = nil end
    say("cleared tweaks for display " .. d)
  elseif (field == "x" or field == "y" or field == "z" or field == "facing" or field == "scale")
      and value then
    local key = (field == "scale") and "mscale" or field
    local t = EJ.ej.MODEL_TWEAKS[d] or {}
    EJ.ej.MODEL_TWEAKS[d] = t
    t[key] = value
    if db then
      db._ejTweaks = db._ejTweaks or {}
      db._ejTweaks[d] = t
    end
    say(("display %d: %s = %s"):format(d, key, tostring(value)))
  else
    local t = EJ.ej.MODEL_TWEAKS[d] or {}
    local cam = (EJ.ej.MODEL_CAM and EJ.ej.MODEL_CAM[d]) or {}
    local path = t.model
    if path == nil then path = EJ.ej.MODEL_PATH and EJ.ej.MODEL_PATH[d] end
    say(("display %d — x=%s y=%s z=%s facing=%s scale=%s (cam cdist=%s ctz=%s)"):format(
      d, tostring(t.x), tostring(t.y), tostring(t.z), tostring(t.facing), tostring(t.mscale),
      tostring(cam.cdist), tostring(cam.ctz)))
    local dbe = EJ.ej.MODEL_PATH_DB and EJ.ej.MODEL_PATH_DB[t.display or d]
    say(("loads: %s  (mode %s, last load via %s, npc id %s)"):format(
      (path and path ~= "") and ("model path " .. path) or ("display ID " .. tostring(t.display or d)),
      EJ.ej.ModelMode(), tostring(cur.ma and cur.ma._loadSource), tostring(cur.ma and cur.ma._npcID)))
    say(("client DBC model: %s%s"):format(dbe and dbe.path or "none",
      dbe and (dbe.humanoid and " (humanoid — display only)" or (" ×" .. tostring(dbe.scale or 1))) or ""))
    say("usage: /ej model x|y|z|facing|scale <n> · global <n> · npc <id>|clear · path <file>|none|clear · display <id>|clear · mode creature|file|auto|display · reset")
    return
  end

  if cur and cur.ma and d then          -- re-frame live with the new values
    cur.ma._userRotated = false
    EJ.ej._PlayerModelFallback(cur.ma, d)
  end
end

-- Abilities tab: retail's collapsible PaperHeader sections (Cata EJ.xml "EncounterInfo
-- Template"): each ability = a 3-slice paper-header bar [ [-]/[+] · icon · title ] that
-- toggles, revealing the description in dark-brown text on the parchment below. Header art:
-- UnSelectUp slices = collapsed, SelectDown = expanded, Highlight (auto on the HIGHLIGHT
-- draw layer of the button = hover). Default state = expanded (descriptions visible).
-- Strip unresolved spell-script tokens ($8040d duration, $s1 effect values, $bull; bullets)
-- that vanilla can't substitute without live spell data — they'd render as raw "$8040d".
local function cleanBody(s)
  s = (s or ""):gsub("%$%d+%a%d*", ""):gsub("%$%a%d*", ""):gsub("%$bull;?", "•")
  return (s:gsub("%s+([%.,])", "%1"):gsub("  +", " "):gsub("^%s+", ""))
end

local SEC_W = 334

-- 3-slice paper-header band (left + tiled-but-stretched mid + right) on `parent` at `layer`.
local function paperBand(parent, state, layer)
  local b = {}
  b.l = parent:CreateTexture(nil, layer); EJ.ej.ApplySlice(b.l, "UI-EJ-PaperHeader-" .. state .. "-Left", true)
  b.l:ClearAllPoints(); b.l:SetPoint("LEFT", parent, "LEFT", -1, -1)
  b.r = parent:CreateTexture(nil, layer); EJ.ej.ApplySlice(b.r, "UI-EJ-PaperHeader-" .. state .. "-Right", true)
  b.r:ClearAllPoints(); b.r:SetPoint("RIGHT", parent, "RIGHT", 3, -1)
  b.m = parent:CreateTexture(nil, layer); EJ.ej.ApplySlice(b.m, "_PaperHeader-" .. state .. "-Mid", false)
  b.m:SetHeight(29); b.m:SetPoint("LEFT", b.l, "RIGHT", -32, 0); b.m:SetPoint("RIGHT", b.r, "LEFT", 32, 0)
  return b
end
local function bandShown(b, on) EJ.SetShown(b.l, on); EJ.SetShown(b.m, on); EJ.SetShown(b.r, on) end

local function acquireSection(c, i)
  local w = c.sectionWidgets[i]
  if w then return w end
  w = CreateFrame("Frame", nil, c.sectionChild)
  w:SetWidth(SEC_W)
  local hb = CreateFrame("Button", nil, w)
  hb:SetPoint("TOPLEFT", w, "TOPLEFT", 0, 0); hb:SetPoint("TOPRIGHT", w, "TOPRIGHT", 0, 0)
  hb:SetHeight(28)   -- taller band so the (now larger) role/type flag badges sit flush
  w.header  = hb
  w.cBand   = paperBand(hb, "UnSelectUp", "BACKGROUND")   -- collapsed
  w.eBand   = paperBand(hb, "SelectDown", "BACKGROUND")   -- expanded
  paperBand(hb, "Highlight", "HIGHLIGHT")                 -- HIGHLIGHT layer = auto hover glow
  w.expandedIcon = hb:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  w.expandedIcon:SetPoint("LEFT", hb, "LEFT", 5, 0)   -- retail EJ.xml expandedIcon LEFT(5,0)
  w.abilityIcon = hb:CreateTexture(nil, "OVERLAY")
  w.abilityIcon:SetSize(18, 18); w.abilityIcon:SetPoint("LEFT", w.expandedIcon, "RIGHT", 5, 0)
  w.abilityIcon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
  -- section icon-flag badges on the right (Interruptible/Magic/Enrage/…), right-to-left.
  -- retail's SetupIconFlags (EJ.lua:1117) uses per-flag named atlases (icons_16x16_*) and
  -- gives each icon a hover tooltip (tooltipTitle/Text). Each badge is a mouse-enabled Frame
  -- (a texture can't take OnEnter) carrying a .tex child + the tooltip strings.
  w.flagIcons = {}
  for fi = 1, 6 do
    local ic = CreateFrame("Frame", nil, hb)
    ic:SetSize(28, 28)   -- ~2x the old 16px: role/type badges were too small to read
    ic.tex = ic:CreateTexture(nil, "OVERLAY"); ic.tex:SetAllPoints(ic)
    if fi == 1 then ic:SetPoint("RIGHT", hb, "RIGHT", -4, 0)
    else ic:SetPoint("RIGHT", w.flagIcons[fi - 1], "LEFT", -3, 0) end
    ic:EnableMouse(true)
    ic:SetScript("OnEnter", function(self)
      if not self.tooltipTitle then return end
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      GameTooltip:SetText(self.tooltipTitle, 1, 1, 1)
      if self.tooltipText and self.tooltipText ~= "" then
        GameTooltip:AddLine(self.tooltipText, nil, nil, nil, true)
      end
      GameTooltip:Show()
    end)
    ic:SetScript("OnLeave", GameTooltip_Hide)
    ic:Hide()
    w.flagIcons[fi] = ic
  end
  w.title = hb:CreateFontString(nil, "OVERLAY", "GameFontNormal"); w.title:SetJustifyH("LEFT")
  w.desc = w:CreateFontString(nil, "ARTWORK", "GameFontBlack")
  w.desc:SetJustifyH("LEFT"); w.desc:SetJustifyV("TOP"); w.desc:SetTextColor(0.25, 0.1484375, 0.02)
  w.desc:SetWidth(SEC_W - 26); w.desc:SetPoint("TOPLEFT", hb, "BOTTOMLEFT", 13, -9)
  -- parchment inset box behind the description + its bottom border (retail EJ.xml:1012-1024)
  w.descBG = w:CreateTexture(nil, "BACKGROUND")
  EJ.ej.ApplySlice(w.descBG, "UI-PaperOverlay-AbilityTextBG", false)
  w.descBG:SetPoint("TOPLEFT", w.desc, "TOPLEFT", -9, 12)
  w.descBG:SetPoint("BOTTOMRIGHT", w.desc, "BOTTOMRIGHT", 9, -11)
  w.descBottom = w:CreateTexture(nil, "BACKGROUND")
  EJ.ej.ApplySlice(w.descBottom, "UI-PaperOverlay-AbilityTextBottomBorder", false)
  w.descBottom:SetHeight(9)
  w.descBottom:SetPoint("LEFT", w.descBG, "BOTTOMLEFT", 0, 0)
  w.descBottom:SetPoint("RIGHT", w.descBG, "BOTTOMRIGHT", 0, 0)
  hb:SetScript("OnClick", function()
    if w.sectionID and c._secExp then c._secExp[w.sectionID] = not c._secExp[w.sectionID] end
    if c._reflow then c._reflow() end
  end)
  c.sectionWidgets[i] = w
  return w
end

local HEADER_INDENT = 15    -- retail Blizzard_EncounterJournal.lua:3
local SECTION_GAP   = 6

-- IconFlags bitmask → list of set bit indices (icon index = bit position; retail
-- GetIconFlagIndices). flagTexCoord maps an index into the UI-EJ-Icons 8x2 32px grid.
local function flagBits(flags)
  local out = {}
  flags = flags or 0
  for i = 0, 13 do
    if bit.band(flags, bit.lshift(1, i)) ~= 0 then out[#out + 1] = i end
  end
  return out
end
local function flagTexCoord(i)
  local l = (i % 8) / 8
  local t = math.floor(i / 8) / 2
  return l, l + 0.125, t, t + 0.5
end

-- Bit-index → modern flag atlas (retail EncounterJournal_SetFlagIcon, EJ.lua:2358-2404). Index =
-- the flag's bit position (Tank=0 … Bleed=13, from JournalEncounterIconFlags = 1,2,4,…,8192).
-- Atlas names use Era's actual spellings in Generated/AtlasData.lua (file 7494373) — note
-- "inturrupt" (not interrupt) and "blood" (not bleed).
local FLAG_ATLAS = {
  [0]="icons_16x16_tank",   [1]="icons_16x16_damage",  [2]="icons_16x16_heal",
  [3]="icons_16x16_heroic", [4]="icons_16x16_deadly",  [5]="icons_16x16_important",
  [6]="icons_16x16_inturrupt", [7]="icons_16x16_magic", [8]="icons_16x16_curse",
  [9]="icons_16x16_poison", [10]="icons_16x16_disease", [11]="icons_16x16_enrage",
  [12]="icons_16x16_mythic", [13]="icons_16x16_blood",
}
-- Fallback tooltip titles when the ENCOUNTER_JOURNAL_SECTION_FLAG<i> globals are absent (Era).
local FLAG_NAME = {
  [0]="Role: Tank", [1]="Role: Damage", [2]="Role: Healer", [3]="Heroic Difficulty",
  [4]="Deadly", [5]="Important", [6]="Interruptible", [7]="Magic Effect", [8]="Curse Effect",
  [9]="Poison Effect", [10]="Disease Effect", [11]="Enrage Effect", [12]="Mythic Difficulty",
  [13]="Bleed Effect",
}
EJ.ej.FLAG_NAME = FLAG_NAME

-- Apply the flag icon for bit-index `i` to texture `tex`: modern named atlas when available,
-- else retail's legacy UI-EJ-Icons 8x2 grid (EJ.lua:2392-2403) — exactly what we shipped before.
-- NOTE: retail follows native SetAtlas with SetTexCoord(0,1,0,1) (engine-relative to the atlas
-- element). Our EJ.tex.SetAtlas IS the texcoord set (it writes the sheet sub-rect directly), so
-- a trailing SetTexCoord(0,1,0,1) would reset to the FULL sheet — do not add it here.
function EJ.ej.SetFlagIcon(tex, i)
  local atlas = FLAG_ATLAS[i]
  if not (atlas and EJ.tex and EJ.tex.SetAtlas and EJ.tex.SetAtlas(tex, atlas, false)) then
    tex:SetTexture(EJ.tex.localFiles[521749] or 521749)
    tex:SetTexCoord(flagTexCoord(i))
  end
end

-- Lay out one section row at `depth` (indented 15px/level, narrower per retail hWidth-=INDENT).
-- `exp` = expanded → show "-", description box + bottom border (its CHILD rows are emitted
-- separately by the tree walk). Collapsed → "+", header bar only. Returns the row's height.
local function layoutSection(w, s, depth, exp)
  local rowW = SEC_W - depth * HEADER_INDENT
  w:SetWidth(rowW)
  -- top-level titles use the bigger GameFontNormalMed3; nested use GameFontNormal (retail
  -- ToggleHeaders:1882-1886). Fall back to GameFontNormal if Med3 is absent on Era.
  w.title:SetFontObject((depth == 0 and _G.GameFontNormalMed3) or _G.GameFontNormal)
  w.title:ClearAllPoints()
  -- left glyph: creature portrait (IconCreatureDisplayInfoID) > ability icon (FDID) >
  -- spell-resolved icon (GetSpellTexture; for hand-seeded Era sections that carry a real
  -- spellID instead of a baked FDID — the client resolves the authentic vanilla icon) > none
  -- s.icon is a TEXTURE PATH string after tools/convert_icons.py (icon_ids.lua maps the retail
  -- FileDataIDs the DB2 extract carries onto the 3.3.5 Interface\Icons\ paths). 3.3.5a cannot load
  -- a texture by numeric FDID — SetTexture(136041) renders the red "missing" square — so a number
  -- that slipped past the conversion (the ~24 Cata+ icons absent from the map, or an un-converted
  -- regen) is treated as NO icon here, never handed to SetTexture. Fallback order: path (only if
  -- the client actually has the file — GetTexture reads back nil on a failed SetTexture) → the
  -- spell's own icon → none.
  local iconPath = type(s.icon) == "string" and s.icon ~= "" and s.icon or nil
  -- 3.3.5a's GetSpellTexture(id) can't resolve an arbitrary spellID (it wants a spellbook
  -- slot/name); GetSpellInfo(id) can, and its 3rd return is the icon — the same route ClassicAPI's
  -- own C_Spell.GetSpellTexture takes.
  local spellIcon = s.spell and s.spell > 0 and GetSpellInfo and select(3, GetSpellInfo(s.spell)) or nil
  local shown = false
  if s.cdisp and s.cdisp > 0 and SetPortraitTextureFromCreatureDisplayID then
    SetPortraitTextureFromCreatureDisplayID(w.abilityIcon, s.cdisp)
    shown = true
  else
    if iconPath then
      w.abilityIcon:SetTexture(iconPath)
      shown = w.abilityIcon:GetTexture() ~= nil
    end
    if not shown and spellIcon then
      w.abilityIcon:SetTexture(spellIcon)
      shown = w.abilityIcon:GetTexture() ~= nil
    end
    if shown then w.abilityIcon:SetTexCoord(0.07, 0.93, 0.07, 0.93) end
  end
  if shown then
    w.abilityIcon:Show(); w.title:SetPoint("LEFT", w.abilityIcon, "RIGHT", 5, 0)
  else
    w.abilityIcon:SetTexture(nil)
    w.abilityIcon:Hide(); w.title:SetPoint("LEFT", w.expandedIcon, "RIGHT", 5, 0)
  end
  -- right-side flag badges (right-to-left); title's RIGHT anchor stops at the leftmost one.
  -- Each badge gets the modern named atlas + a hover tooltip (retail SetupIconFlags:1117-1135).
  local bits, last = flagBits(s.flags), 0
  for fi = 1, #w.flagIcons do
    local idx = bits[fi]   -- 0-based bit index
    local ic = w.flagIcons[fi]
    if idx then
      EJ.ej.SetFlagIcon(ic.tex, idx)
      ic.tooltipTitle = _G["ENCOUNTER_JOURNAL_SECTION_FLAG" .. idx] or FLAG_NAME[idx]
      ic.tooltipText  = _G["ENCOUNTER_JOURNAL_SECTION_FLAG_DESCRIPTION" .. idx]
      ic:Show(); last = fi
    else
      ic:Hide()
    end
  end
  if last > 0 then w.title:SetPoint("RIGHT", w.flagIcons[last], "LEFT", -5, 0)
  else w.title:SetPoint("RIGHT", w.header, "RIGHT", -8, 0) end
  w.title:SetText(s.title or "")
  w.desc:SetWidth(rowW - 26); w.desc:SetText(cleanBody(s.body))
  local hasBody = (w.desc:GetText() or "") ~= ""
  w.expandedIcon:SetText(exp and "-" or "+")
  bandShown(w.cBand, not exp); bandShown(w.eBand, exp)
  local showDesc = exp and hasBody
  EJ.SetShown(w.desc, showDesc); EJ.SetShown(w.descBG, showDesc); EJ.SetShown(w.descBottom, showDesc)
  local h = 28   -- matches hb:SetHeight (taller header band for the larger flag badges)
  if showDesc then h = h + 9 + (w.desc:GetStringHeight() or 0) + 11 + 9 end  -- gap + text + box pad + border
  w:SetHeight(h)
  return h
end

-- Sections form a tree walked EXACTLY as retail does (ToggleHeaders): start at the boss's
-- rootSection and follow the sibling linked-list (`sib`); an expanded header descends into its
-- `child` chain (indented). Headers expanded by default here (per user); collapse hides the
-- description + its children. `visited` guards against malformed cyclic pointers.
local function renderSections(boss)
  local c = EJ.ej.frame.encounter.info.content
  local byId = {}
  for _, s in ipairs(boss.sections or {}) do byId[s.id] = s end
  c._secExp = c._secExp or {}
  -- Lead lore paragraph: retail shows the boss description at the TOP of detailsScroll, above
  -- the ability sections (Blizzard_EncounterJournal.lua:1354-1356). We render it as the first
  -- element of the section scroll child so lore + abilities scroll together as one page.
  if not c.leadDesc then
    c.leadDesc = c.sectionChild:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    c.leadDesc:SetJustifyH("LEFT"); c.leadDesc:SetJustifyV("TOP"); c.leadDesc:SetWidth(SEC_W)
  end
  c.leadDesc:SetText(cleanBody(boss.desc))
  c._reflow = function()
    local hasLore = (c.leadDesc:GetText() or "") ~= ""
    EJ.SetShown(c.leadDesc, hasLore)
    local y = -6
    if hasLore then
      c.leadDesc:ClearAllPoints()
      c.leadDesc:SetPoint("TOPLEFT", c.sectionChild, "TOPLEFT", 6, y)
      y = y - (c.leadDesc:GetStringHeight() or 0) - 14   -- gap before the first ability band
    end
    -- R2: a NORMAL difficulty bucket hides Heroic-flagged sections (flag value 8) including
    -- their children, retail-style; a Heroic bucket (2/5/6) — or an instance with no
    -- difficulty data at all (sel nil) — shows everything. Read live so the dropdown's
    -- SelectTab-refresh re-walks with the new selection.
    local sel = EJ.ej.frame.encounter.info.lootDiff
    local hideHeroic = sel and not HEROIC_BUCKET[sel]
    local idx, visited = 0, {}
    local function walk(startID, depth)
      local id = startID
      while id and id ~= 0 and byId[id] and not visited[id] do
        visited[id] = true
        local s = byId[id]
        if hideHeroic and bit.band(s.flags or 0, 8) ~= 0 then
          id = s.sib   -- skip the section AND its child chain on Normal
        else
          idx = idx + 1
          local w = acquireSection(c, idx)
          w.sectionID = s.id
          if c._secExp[s.id] == nil then c._secExp[s.id] = true end   -- expanded by default
          local exp = c._secExp[s.id] and true or false
          local h = layoutSection(w, s, depth, exp)
          w:ClearAllPoints(); w:SetPoint("TOPLEFT", c.sectionChild, "TOPLEFT", 6 + depth * HEADER_INDENT, y)
          w:Show()
          y = y - h - SECTION_GAP
          if exp then walk(s.child, depth + 1) end
          id = s.sib
        end
      end
    end
    local root = boss.rootSection
    if not root or root == 0 then root = boss.sections and boss.sections[1] and boss.sections[1].id end
    walk(root, 0)
    for i = idx + 1, #c.sectionWidgets do c.sectionWidgets[i]:Hide() end
    c.sectionChild:SetHeight(math.max(1, -y + 6))
  end
  c._reflow()
  c.sectionScroll:SetVerticalScroll(0)
end

-- The single renderer: decides lore-landing vs per-boss content from (selBoss, tab)
local function refreshView()
  local f = EJ.ej.frame
  if not (f and f.encounter and f.encounter.info) then return end
  local enc, info = f.encounter, f.encounter.info

  -- Tab availability. Tab 3 (the separate abilities page) is collapsed into tab 1 and never
  -- shown — retail's overview-less layout (EJ.lua:1271-1282). Tab 1 is the lore+abilities page,
  -- live for every boss (raids included, since they have abilities). Model(4) is BOSS-ONLY; on
  -- the instance landing only 1 (instance lore) + 2 (aggregated loot) are live.
  local enabled
  if not selBoss then
    enabled = { [1] = true, [2] = true, [3] = false, [4] = false }
  else
    enabled = { [1] = true, [2] = true, [3] = false, [4] = EJ.ej.MODEL_TAB_ENABLED and true or false }
  end

  local tab = info.selectedTab or 1
  if not enabled[tab] then               -- current tab ghosted → jump to first available
    for _, id in ipairs({ 1, 2, 4 }) do if enabled[id] then tab = id; break end end
    info.selectedTab = tab
  end

  for _, t in ipairs(info.tabs) do
    local en = enabled[t.tabID] and true or false
    local on = (t.tabID == tab) and en
    EJ.SetShown(t.selBG, on); EJ.SetShown(t.selIcon, on); EJ.SetShown(t.unselIcon, not on)
    EJ.SetEnabled(t, en)
    t.unselIcon:SetDesaturated(not en); t.unselIcon:SetAlpha(en and 1 or 0.35)
    if t.selIcon.SetDesaturated then t.selIcon:SetDesaturated(not en) end
  end

  local c = info.content
  c.text:Hide(); c.lootScroll:Hide(); c.sectionScroll:Hide()
  if c.lootLoadAll then c.lootLoadAll:Hide() end   -- renderLoot re-shows it when needed
  if info.modelArea then info.modelArea:Hide() end
  -- Boss title in the header is hidden on Model (the model fills the page) AND Loot (that
  -- header hosts the loot filters, not the boss name) — matching retail.
  local hideBossTitle = (tab == 4 or tab == 2)
  if info.encounterTitle then
    info.SetEncounterTitle(selBoss and selBoss.name or "")
    EJ.SetShown(info.encounterTitle, selBoss and not hideBossTitle and true or false)
  end
  if info.rightHeader then EJ.SetShown(info.rightHeader, tab ~= 4) end
  if info.lootFilter then EJ.SetShown(info.lootFilter, tab == 2) end   -- slot filter only on Loot
  if info.lootFilterClear then   -- clear badge only when there is something to clear
    EJ.SetShown(info.lootFilterClear, tab == 2 and (info.lootSlot or "ALL") ~= "ALL")
  end
  -- ONE difficulty selector for the whole encounter page. Buckets come from the
  -- INSTANCE (cached union of its loot diff masks); the selection drives BOTH the loot bucket
  -- filter (renderLoot) and the Heroic ability sections (renderSections). Shown on Loot always
  -- and on a BOSS's Abilities page; hidden on the lore landing, the Model tab, and whenever the
  -- instance has no real choice (vanilla + single-difficulty instances → empty/1-bucket list).
  do
    local avail = EJ.ej.InstanceDiffBuckets(selInst)
    info.lootDiffsAvail = avail
    local ok = false
    for _, b in ipairs(avail) do if b == info.lootDiff then ok = true; break end end
    if not ok then info.lootDiff = avail[1] end   -- default = lowest; nil when no data
    local df = info.difficultyFilter
    if df then
      local show = #avail >= 2 and (tab == 2 or (tab == 1 and selBoss ~= nil))
      EJ.SetShown(df, show and true or false)   -- always the rightmost filter (info.LayoutFilters)
      if info.lootDiff and df.SetDefaultText then
        df:SetDefaultText(EJ.ej.DIFF_LABEL[info.lootDiff] or "")
      end
    end
  end
  if info.classFilter and tab ~= 2 then info.classFilter:Hide() end   -- class filter only on Loot
  if info.LayoutFilters then info.LayoutFilters() end

  if not selBoss then
    if tab == 2 then            -- instance landing Loot = aggregated instance-wide drops
      enc.instance:Hide()       -- don't leave the lore artwork showing beneath the loot
      local agg, seen = {}, {}
      for _, e in ipairs((selInst and selInst.encounters) or {}) do
        for _, entry in ipairs(e.loot or {}) do
          -- entries are { id, pct } tables; dedup on the item id, keep the table (carries pct)
          local eid = (type(entry) == "table") and entry.id or entry
          if eid and not seen[eid] then seen[eid] = true; agg[#agg + 1] = entry end
        end
      end
      renderLoot({ loot = agg }); c.lootScroll:Show()
    else
      enc.instance:Show()       -- lore landing on the right page
    end
    return
  end
  enc.instance:Hide()

  if tab == 2 then            -- Loot
    renderLoot(selBoss); c.lootScroll:Show()
  elseif tab == 4 then        -- Model
    local ma = info.modelArea
    if ma then
      -- per-instance model backdrop (JournalInstance.BGFileDataID); default if unshipped
      local bgFD = selInst and selInst.bgFDID
      ma.bg:SetTexture(EJ.tex.localFiles[bgFD] or EJ.tex.localFiles[521743] or 521743)
      ma.name:SetText(selBoss.name or "")
      -- Show the area BEFORE loading the model: the 3.3.5a engine drops a SetDisplayInfo issued
      -- while the frame chain is hidden, so the model never appeared if loaded first.
      ma:Show()
      local cr = selBoss.creatures and selBoss.creatures[1]
      ma._npcID = EJ.ej.EncounterNPC and EJ.ej.EncounterNPC(selInst, selBoss) or nil
      EJ.ej.NormalizeModel(ma, cr and cr.display)
      if ma.SetCreatures then ma.SetCreatures(selBoss) end   -- multi-creature switcher (R4)
    else
      c.text:SetText("(no model)"); c.text:Show()
    end
  else                        -- tab 1 = lore description + ability sections (retail detailsScroll)
    if (selBoss.sections and #selBoss.sections > 0) or (selBoss.desc and selBoss.desc ~= "") then
      renderSections(selBoss); c.sectionScroll:Show()   -- renderSections prepends the lore paragraph
    else
      c.text:SetText("(No abilities recorded for this encounter.)"); c.text:Show()
    end
  end
end

-- Public API
function EJ.ej.SelectTab(id)
  local f = EJ.ej.frame
  if not (f and f.encounter and f.encounter.info) then return end
  f.encounter.info.selectedTab = id
  refreshView()
end

function EJ.ej.ShowBoss(enc)
  selBoss = enc
  if EJ.ej.frame then EJ.ej.frame._currentBoss = enc end
  applyBossHighlight()   -- keep the clicked boss row highlighted
  refreshView()
  if EJ.ej.RefreshNavBar then EJ.ej.RefreshNavBar() end   -- breadcrumb extends to the boss
end

-- "Show Map" → open the world map to the instance's dungeon map (the first boss's UiMapID). The
-- actual work lives in Core/WorldMap.lua (EJ.worldmap.ShowInstanceMap): combat-guarded, opens the
-- map and SetMapID's to that uiMap. Stock 3.3.5a uiMaps have no dungeon art so it shows an empty
-- map, but a CLIENT PATCH shipping that art makes the button light up with no addon change.
function EJ.ej.ShowMap(inst)
  inst = inst or selInst
  if inst and EJ.worldmap and EJ.worldmap.ShowInstanceMap then
    EJ.worldmap.ShowInstanceMap(inst)
  end
end

function EJ.ej.PopulateEncounter(inst)
  selInst, selBoss = inst, nil
  local enc = EJ.ej.frame.encounter
  enc.instance.title:SetText(inst.name or "")
  if enc.info.instanceTitle then enc.info.instanceTitle:SetText(inst.name or "") end
  -- per-instance loading-screen lore background (LoreFileDataID), cropped per EJ.xml:1314-1320
  if inst.loreFDID and inst.loreFDID > 0 and enc.instance.loreBG then
    enc.instance.loreBG:SetTexture(EJ.tex.localFiles[inst.loreFDID] or inst.loreFDID)
    -- retail crop (probe-confirmed: same (0,0.7617,0,0.6562) for default + per-instance art).
    enc.instance.loreBG:SetTexCoord(0, 0.7617187, 0, 0.65625)
  end
  enc.instance.lore:SetText(inst.desc or "")
  if enc.instance.loreChild then
    enc.instance.loreChild:SetHeight(math.max(1, (enc.instance.lore:GetStringHeight() or 0) + 4))
  end
  -- dungeon-specific back-button portrait (the instance's splash under the ring)
  local ib = enc.info and enc.info.instanceButton
  if ib and ib.icon and inst.buttonFDID and inst.buttonFDID > 0 then
    ib.icon:SetTexture(EJ.tex.localFiles[inst.buttonFDID] or inst.buttonFDID)
    -- square 128x128 icons fill the 40x40 ring uncropped; widescreen splashes take retail's crop
    if EJ.ej.SetButtonTexCoord then EJ.ej.SetButtonTexCoord(ib.icon, inst.buttonFDID, true)
    else ib.icon:SetTexCoord(0, 0.68359375, 0, 0.7421875) end
  end
  -- "Find Group" only for dungeons the 3.3.5 LFD system actually lists (Core/LFD.lua)
  local lb = enc.instance and enc.instance.lfdButton
  if lb then
    local on = (EJ.lfd and EJ.lfd.Available and EJ.lfd.Available(inst)) and true or false
    EJ.SetShown(lb, on)
    if lb.text then EJ.SetShown(lb.text, on) end
  end
  fillBossList(inst)
  enc.info.selectedTab = 1
  refreshView()
end

function EJ.ej.BuildEncounterPage(f)
  local enc = f.encounter
  if not enc or enc._ejBuilt then return end
  enc._ejBuilt = true
  -- pcall each: a failure in one panel must not skip the other (a buildInfoPanel error was
  -- skipping the lore-panel build → blank landing artwork).
  local okI = pcall(buildInfoPanel, enc)   -- info first = book backdrop; lore layers on the right
  local okL = pcall(buildLorePanel, enc)
  if not (okI and okL) and EJ.Log then EJ.Log("EJ", "BuildEncounterPage: info=%s lore=%s", tostring(okI), tostring(okL)) end
  -- retail layers instance ABOVE info: $parentInfo has useParentLevel="true" (= enc's level),
  -- $parentInstanceFrame does not (= enc+1). As plain CreateFrame children both default to
  -- enc+1 → equal sibling levels draw non-deterministically (symptom: the lore landing
  -- sometimes renders UNDER the info book bg). Pin both to reproduce retail's split.
  local lvl = enc:GetFrameLevel()
  if enc.info then enc.info:SetFrameLevel(lvl) end
  if enc.instance then enc.instance:SetFrameLevel(lvl + 1) end
end

