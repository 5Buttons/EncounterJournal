-- Addon/EncounterJournal/NavBar.lua — breadcrumb navbar + search box below the nineslice
-- (roadmap item 4). Uses EJ.navbar (Core/NavBar.lua), our 3.3.5a breadcrumb built from plain
-- buttons since the client has no NavBarTemplate. Breadcrumb: [Home] › [Instance ▾] › [Boss],
-- where the instance crumb's ▾ jumps straight to any boss. Search box filters the instance grid
-- by name (v1; deeper EJ_SetSearch over bosses/loot is a later pass).
--
-- retail anchors (EJ.xml:1209-1213, 1196-1206): navBar TOPLEFT(61,-22) 500×34;
-- searchBox TOPRIGHT(-10,-32) 210×20.

EJ.ej = EJ.ej or {}

-- The search box's REAL text: "" when it is empty OR shows ClassicAPI's SEARCH placeholder
-- (SearchBoxTemplate_OnLoad/OnEditFocusLost write the localized "Search" into the box itself).
function EJ.ej.ReadSearchText(sb)
  local t = sb and sb.GetText and sb:GetText()
  if not t or t == "" or t == (SEARCH or "Search") then return "" end
  return t
end

-- Dropdown contents for the instance breadcrumb button: jump to a boss.
local function bossJumpList()
  local f = EJ.ej.frame
  local inst = f and f._currentInstance
  local list = {}
  if inst and inst.encounters then
    for _, enc in ipairs(inst.encounters) do
      list[#list + 1] = {
        text = enc.name,
        id   = enc.id,
        func = function() if EJ.ej.ShowBoss then EJ.ej.ShowBoss(enc) end end,
      }
    end
  end
  return list
end

-- Instance breadcrumb click → back to the instance overview (clears selected boss).
local function instanceOnClick()
  local f = EJ.ej.frame
  if f and f._currentInstance and EJ.ej.ShowInstance then EJ.ej.ShowInstance(f._currentInstance) end
end

function EJ.ej.BuildNavBar(f)
  if f._ejNavBar then return f._ejNavBar end
  local lvl = (f.NineSlice and f.NineSlice:GetFrameLevel() or f:GetFrameLevel()) + 6

  -- retail's EJ home button is the short word "Home" (HOME), not the long title — that's
  -- why it never truncates. The window title bar carries "Adventure Guide". EJ.navbar sizes
  -- each crumb to its label width, so "Home" stays compact.
  local navBar = EJ.navbar.Build(f, {
    name       = "EJ_EncounterJournalNavBar",
    frameLevel = lvl,
    home       = {
      name    = HOME or "Home",
      OnClick = function() if EJ.ej.ShowList then EJ.ej.ShowList() end end,
    },
  })
  -- Stretch the bar across most of the header instead of a fixed 500px: anchor both sides so it
  -- fills to just left of the search box (TOPRIGHT(-10) + 210 wide → its left edge ≈ -220).
  navBar:SetHeight(34)
  navBar:SetPoint("TOPLEFT",  f, "TOPLEFT",   61, -22)
  navBar:SetPoint("TOPRIGHT", f, "TOPRIGHT", -228, -22)

  f._ejNavBar = navBar

  -- Search box. pcall the template in case a future build renames it; the journal works
  -- without search. Deep search lives in EncounterJournal/Search.lua (EJ.ej.SearchUpdate:
  -- instances/bosses/abilities/loot with a results dropdown); plain grid filtering is the
  -- fallback if that file is absent.
  local ok, sb = pcall(CreateFrame, "EditBox", "EJ_EncounterJournalSearchBox", f, "SearchBoxTemplate")
  if ok and sb then
    sb:SetSize(210, 20)
    sb:SetPoint("TOPRIGHT", f, "TOPRIGHT", -10, -32)
    sb:SetFrameLevel(lvl)
    -- !!!ClassicAPI's SearchBoxTemplate_OnLoad / _OnEditFocusLost write the literal SEARCH string
    -- into the box as an old-style placeholder (no retail overlay watermark), and OnTextChanged
    -- fires for that write too — so a click into the box and a click away used to filter the
    -- grid by "search" (zero instances match → an empty page). ReadSearchText treats the
    -- placeholder as "no search".
    sb:HookScript("OnTextChanged", function(self)
      local t = EJ.ej.ReadSearchText(self)
      if EJ.ej.SearchUpdate then EJ.ej.SearchUpdate(self, t)
      elseif EJ.ej.FilterGrid then EJ.ej.FilterGrid(t) end
    end)
    -- deep-search UX: Enter = open the top hit; Escape hides; focus-lost hides DELAYED so a
    -- click on a result row (which steals focus on mouse-down) still lands its OnClick.
    sb:HookScript("OnEnterPressed",  function() if EJ.ej.SearchEnter then EJ.ej.SearchEnter() end end)
    sb:HookScript("OnEscapePressed", function() if EJ.ej.SearchHide then EJ.ej.SearchHide() end end)
    sb:HookScript("OnEditFocusLost", function() if EJ.ej.SearchHide then EJ.ej.SearchHide(true) end end)
    f._ejSearchBox = sb
  end
  return navBar
end

-- Rebuild the breadcrumb for the current instance (or just the home button at the list).
function EJ.ej.RefreshNavBar()
  local f = EJ.ej.frame
  local navBar = f and f._ejNavBar
  if not navBar then return end

  local hierarchy = {}
  local inst = f._currentInstance
  if inst then
    hierarchy[#hierarchy + 1] = {
      name     = inst.name,
      id       = inst.id,
      OnClick  = instanceOnClick,
      listFunc = bossJumpList,   -- the ▾ boss-jump dropdown
    }
  end
  -- extend the breadcrumb to the selected boss: Home › Instance ▾ › Boss
  local boss = f._currentBoss
  if boss then
    hierarchy[#hierarchy + 1] = {
      name    = boss.name,
      id      = boss.id,
      OnClick = function() if EJ.ej.ShowBoss then EJ.ej.ShowBoss(boss) end end,
    }
  end
  EJ.navbar.Refresh(navBar, hierarchy)
end
