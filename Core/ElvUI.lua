-- Addon/Core/ElvUI.lua — ElvUI (3.3.5 backport, 6.x) integration for the journal's micro button.
--
-- ElvUI reparents the ten Blizzard micro buttons onto its own ElvUI_MicroBar and lays them out
-- from a FILE-LOCAL list (Modules/ActionBars/MicroBar.lua MICRO_BUTTONS), so our button can't
-- simply be appended, and the stock re-anchoring in EncounterJournal.lua setupMicroButton would
-- tear ElvUI's row apart. Instead:
--   * AB:HandleMicroButton(b) gives our button ElvUI's backdrop/hover/texcoords and parents it
--     to the bar (also picks up ElvUI_MicrobarEnhancement's symbol text, if installed);
--   * a post-hook on AB:UpdateMicroPositionDimensions re-runs ElvUI's own layout math with our
--     button slotted after the dungeon-finder button, so buttonsPerRow / size / spacing settings
--     and the mover keep working.
-- ElvUI initialises from its own PLAYER_LOGIN handler, which may run after ours, so attaching
-- polls briefly for ElvUI_MicroBar. If it never appears (ElvUI's action bar module disabled),
-- the caller's stock layout runs instead.

EJ = EJ or {}
EJ.elvui = EJ.elvui or {}

local ORDER = {
  "CharacterMicroButton", "SpellbookMicroButton", "TalentMicroButton", "AchievementMicroButton",
  "QuestLogMicroButton", "SocialsMicroButton", "PVPMicroButton", "LFDMicroButton",
  "EJ_EJMicroButton", "MainMenuMicroButton", "HelpMicroButton",
}

local function engine()
  local e = _G.ElvUI
  return type(e) == "table" and e[1] or nil
end

function EJ.elvui.IsLoaded()
  return IsAddOnLoaded and IsAddOnLoaded("ElvUI") and engine() ~= nil
end

local function actionBars()
  local E = engine()
  if not (E and E.GetModule) then return nil end
  local ok, ab = pcall(E.GetModule, E, "ActionBars", true)
  return ok and ab or nil
end

-- ElvUI's UpdateMicroPositionDimensions, with ORDER instead of its local list.
local function relayout(ab)
  local E, bar = engine(), _G.ElvUI_MicroBar
  local db = ab and ab.db and ab.db.microbar
  if not (E and bar and db) or InCombatLockdown() then return end
  local buttons = {}
  for _, name in ipairs(ORDER) do
    if _G[name] then buttons[#buttons + 1] = _G[name] end
  end

  -- slider maxes at 10; treat max as "one row"
  local perRow = db.buttonsPerRow or #buttons
  if perRow >= 10 then perRow = #buttons end
  local offset = E:Scale(E.PixelMode and 1 or 3)
  local spacing = E:Scale(offset + (db.buttonSpacing or 0))
  local numRows, prev = 1, bar
  for i, button in ipairs(buttons) do
    button:Size(db.buttonSize, db.buttonSize * 1.4)
    button:ClearAllPoints()
    if prev == bar then
      button:Point("TOPLEFT", bar, "TOPLEFT", offset, -offset)
    elseif (i - 1) % perRow == 0 then
      button:Point("TOP", buttons[i - perRow], "BOTTOM", 0, -spacing)
      numRows = numRows + 1
    else
      button:Point("LEFT", prev, "RIGHT", spacing, 0)
    end
    prev = button
  end

  local ref = _G.CharacterMicroButton
  local cols = math.min(perRow, #buttons)
  ab.MicroWidth = ((ref:GetWidth() + spacing) * cols) - spacing + offset * 2
  ab.MicroHeight = ((ref:GetHeight() + spacing) * numRows) - spacing + offset * 2
  bar:Size(ab.MicroWidth, ab.MicroHeight)

  -- ElvUI_MicrobarEnhancement: symbol text instead of the icon art.
  local b = _G.EJ_EJMicroButton
  if b and b.text then
    if db.symbolic then
      b:DisableDrawLayer("BACKGROUND"); b:EnableDrawLayer("BORDER")
      local r, g, bl = 1, 1, 1
      if ref.text then r, g, bl = ref.text:GetTextColor() end
      b.text:SetTextColor(r, g, bl)
    else
      b:EnableDrawLayer("BACKGROUND"); b:DisableDrawLayer("BORDER")
    end
  end
end

-- Returns true when ElvUI owns the micro buttons (the caller must then skip its own layout).
-- fallback() runs if ElvUI is loaded but its micro bar never shows up.
function EJ.elvui.AttachMicroButton(b, fallback)
  if not EJ.elvui.IsLoaded() then return false end

  local function try()
    local ab = actionBars()
    if not (ab and ab.HandleMicroButton and ab.UpdateMicroPositionDimensions and _G.ElvUI_MicroBar) then
      return false
    end
    ab:HandleMicroButton(b)
    if b.text then b.text:SetText("EJ") end
    hooksecurefunc(ab, "UpdateMicroPositionDimensions", relayout)
    relayout(ab)
    return true
  end
  if try() then return true end

  local f, waited = CreateFrame("Frame"), 0
  f:SetScript("OnUpdate", function(self, elapsed)
    waited = waited + elapsed
    if try() then
      self:SetScript("OnUpdate", nil)
    elseif waited > 5 then
      self:SetScript("OnUpdate", nil)
      if fallback then fallback() end
    end
  end)
  return true
end
