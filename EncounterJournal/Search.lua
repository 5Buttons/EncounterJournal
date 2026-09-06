-- Addon/EncounterJournal/Search.lua — DEEP search over the seeded journal data (ROADMAP R1).
-- Retail's EJ searches bosses/abilities/loot through the live EJ_SetSearch API; 3.3.5a has no
-- journal API at all, but ALL our data is local (EJ.ej.DATA), so we flatten it once into an
-- index and substring-match per keystroke. Results pop in a tooltip-style dropdown under the
-- navbar search box — "[Type]  Name  — context" — and a click navigates there (instance page,
-- boss abilities tab, or boss loot tab). Wired from EncounterJournal/NavBar.lua:
-- OnTextChanged → EJ.ej.SearchUpdate · Enter → SearchEnter · Escape/focus-lost → SearchHide.

EJ.ej = EJ.ej or {}

local MIN_CHARS = 2     -- don't search on a single letter (too noisy)
local MAX_SHOWN = 12    -- rows in the dropdown; the footer carries the full count
local ROW_H     = 22

-- type → colored tag; TYPE_ORDER groups results (instances first, loot last, like retail)
local TYPE_TAG = {
  instance = "|cff66ccffInstance|r",
  boss     = "|cffffd200Boss|r",
  ability  = "|cffff9955Ability|r",
  loot     = "|cff88cc88Loot|r",
}
local TYPE_ORDER = { instance = 1, boss = 2, ability = 3, loot = 4 }

-- Flat search index over EJ.ej.DATA, built lazily on the FIRST search — all *_data.lua files
-- (and the WotLK replace-on-collision pass) have long run by then, and the dataset is static.
local index
local function buildIndex()
  index = {}
  local D = EJ.ej.DATA
  for _, inst in ipairs((D and D.instances) or {}) do
    index[#index + 1] = { type = "instance", key = (inst.name or ""):lower(),
                          label = inst.name, inst = inst }
    for _, enc in ipairs(inst.encounters or {}) do
      index[#index + 1] = { type = "boss", key = (enc.name or ""):lower(),
                            label = enc.name, ctx = inst.name, inst = inst, enc = enc }
      for _, s in ipairs(enc.sections or {}) do
        if s.title and s.title ~= "" then
          index[#index + 1] = { type = "ability", key = s.title:lower(),
                                label = s.title, ctx = enc.name, inst = inst, enc = enc }
        end
      end
      for _, l in ipairs(enc.loot or {}) do
        -- baked names (TBC/WotLK rows) or item_info.lua names (every tier) are searchable;
        -- uncached items have no live name on 3.3.5
        local nm = (type(l) == "table") and l.name
        if (not nm or nm == "") and type(l) == "table" and EJ.ej.ITEM_INFO and EJ.ej.ITEM_INFO[l.id] then
          nm = EJ.ej.ITEM_INFO[l.id][1]
        end
        if nm and nm ~= "" then
          index[#index + 1] = { type = "loot", key = nm:lower(), label = nm,
                                ctx = enc.name, inst = inst, enc = enc, loot = true }
        end
      end
    end
  end
end

local function search(needle)
  if not index then buildIndex() end
  local out = {}
  for _, e in ipairs(index) do
    local pos = e.key:find(needle, 1, true)
    if pos then
      -- rank: type group first, prefix matches before mid-string ones
      e._rank = (TYPE_ORDER[e.type] or 9) * 10 + (pos == 1 and 0 or 5)
      out[#out + 1] = e
    end
  end
  table.sort(out, function(a, b)
    if a._rank ~= b._rank then return a._rank < b._rank end
    return (a.label or "") < (b.label or "")
  end)
  return out
end

-- ── results dropdown ────────────────────────────────────────────────────────────────────────
local results
local function acquireResults(sb)
  if results then return results end
  results = CreateFrame("Frame", "EJ_EJSearchResults", sb)   -- parented to the box: hides with the window
  results:SetFrameStrata("DIALOG")
  results:SetWidth(340)
  results:SetPoint("TOPRIGHT", sb, "BOTTOMRIGHT", 0, -3)
  results:SetBackdrop({
    bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
  })
  results:SetBackdropColor(0.05, 0.05, 0.05, 0.95)
  results:EnableMouse(true)   -- swallow clicks so they don't fall through onto the page
  results.rows = {}
  results.footer = results:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  results.footer:SetPoint("BOTTOMLEFT", results, "BOTTOMLEFT", 10, 8)
  results:Hide()
  return results
end

local function acquireRow(i)
  local r = results.rows[i]
  if r then return r end
  r = CreateFrame("Button", nil, results)
  r:SetHeight(ROW_H)
  r:SetPoint("TOPLEFT",  results, "TOPLEFT",   8, -8 - (i - 1) * ROW_H)
  r:SetPoint("TOPRIGHT", results, "TOPRIGHT", -8, -8 - (i - 1) * ROW_H)
  local hl = r:CreateTexture(nil, "HIGHLIGHT")
  hl:SetAllPoints(r)
  hl:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")   -- present on 3.3.5
  hl:SetBlendMode("ADD")
  r.text = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  r.text:SetPoint("LEFT", r, "LEFT", 2, 0); r.text:SetPoint("RIGHT", r, "RIGHT", -2, 0)
  r.text:SetJustifyH("LEFT")
  r:SetScript("OnClick", function(self)
    if self.entry then EJ.ej.SearchNavigate(self.entry) end
  end)
  results.rows[i] = r
  return r
end

-- Click (or Enter) on a result: open what it points at. Loot hits land on the boss's Loot tab,
-- ability hits on the abilities tab; the instance page comes first so the breadcrumb is right.
function EJ.ej.SearchNavigate(e)
  if not (e and e.inst) then return end
  if results then results:Hide() end
  local f = EJ.ej.frame
  local sb = f and f._ejSearchBox
  if sb then sb:SetText(""); sb:ClearFocus() end
  if EJ.ej.ShowInstance then EJ.ej.ShowInstance(e.inst) end
  if e.enc and EJ.ej.ShowBoss then
    EJ.ej.ShowBoss(e.enc)
    if EJ.ej.SelectTab then EJ.ej.SelectTab(e.loot and 2 or 1) end
  end
end

function EJ.ej.SearchEnter()   -- Enter in the search box = open the top result
  local first = results and results._first
  if first and results:IsShown() then EJ.ej.SearchNavigate(first) end
end

-- Hide the dropdown. `delayed` = focus-lost path: postpone so a click ON a result row (which
-- steals focus on mouse-down, before its OnClick fires on mouse-up) still lands.
function EJ.ej.SearchHide(delayed)
  if not results then return end
  if delayed and C_Timer and C_Timer.After then
    C_Timer.After(0.2, function()
      if results and not results:IsMouseOver() then results:Hide() end
    end)
  else
    results:Hide()
  end
end

-- OnTextChanged entry point (NavBar.lua). Keeps the live instance-grid name filter AND runs
-- the deep search once the text is long enough.
function EJ.ej.SearchUpdate(sb, text)
  text = (text or ""):gsub("^%s+", ""):gsub("%s+$", "")
  if EJ.ej.FilterGrid then EJ.ej.FilterGrid(text) end
  local res = acquireResults(sb)
  if #text < MIN_CHARS then res:Hide(); return end

  local found = search(text:lower())
  local shown = math.min(#found, MAX_SHOWN)
  for i = 1, shown do
    local e, r = found[i], acquireRow(i)
    r.entry = e
    r.text:SetText(TYPE_TAG[e.type] .. "  " .. (e.label or "")
      .. (e.ctx and ("  |cff888888— " .. e.ctx .. "|r") or ""))
    r:Show()
  end
  for i = shown + 1, #results.rows do results.rows[i]:Hide() end
  results._first = found[1]

  if #found == 0 then
    results.footer:SetText(NO_SEARCH_RESULTS or "No results")
  elseif #found > shown then
    results.footer:SetText(("Showing %d of %d results"):format(shown, #found))
  else
    results.footer:SetText(("%d result%s"):format(#found, #found == 1 and "" or "s"))
  end
  res:SetHeight(8 + shown * ROW_H + 22)
  res:Show()
end
