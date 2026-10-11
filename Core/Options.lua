-- Addon/Core/Options.lua — UI skin selection (classic vs dragonflight).
--
--
--   "dragonflight" — the DragonUI_NewEra look: retail metal nineslice, round portrait,
--                    RedButton close, Dragonflight metal tabs, minimal scrollbars. The default.
--   "classic"      — the original Classic look: Wotlk FrameGeneral UI-Frame border + portrait
--                    ring (rebuilt in EncounterJournal.lua), the native red-square close
--                    button, the classic red bottom tabs and gold-arrow scrollbars.
-- The breadcrumb navbar and the journal's own UI-EJ-* art are the same in both.
--

EJ = EJ or {}
EJ.skin = EJ.skin or {}

EJ.skin.CLASSIC      = "classic"
EJ.skin.DRAGONFLIGHT = "dragonflight"

-- Known skins, in toggle order. label = user-facing name (options dropdown / chat).
EJ.skin.LIST = {
  { key = EJ.skin.DRAGONFLIGHT, label = "Dragonflight" },
  { key = EJ.skin.CLASSIC,      label = "Classic" },
}

local function isValid(key)
  for _, s in ipairs(EJ.skin.LIST) do if s.key == key then return true end end
  return false
end

-- Active skin key. Reads the SavedVariable (EJ.db is set in Core.lua after applyMigrations);
-- coalesces to dragonflight before the DB exists or if a stored value is unknown.
function EJ.skin.Get()
  local k = EJ.db and EJ.db.skin
  if k and isValid(k) then return k end
  return EJ.skin.DRAGONFLIGHT
end

function EJ.skin.Is(key) return EJ.skin.Get() == key end

-- Human-readable label for a key (falls back to the key itself).
function EJ.skin.Label(key)
  for _, s in ipairs(EJ.skin.LIST) do if s.key == key then return s.label end end
  return key
end

-- StaticPopup offering the reload that actually applies a newly-chosen skin.
StaticPopupDialogs = StaticPopupDialogs or {}
StaticPopupDialogs["EJ_SKIN_RELOAD"] = {
  text = "Encounter Journal: switch to the %s skin? This reloads your UI.",
  button1 = OKAY or "Okay",
  button2 = CANCEL or "Cancel",
  OnAccept = function() ReloadUI() end,
  timeout = 0, whileDead = 1, hideOnEscape = 1, preferredIndex = 3,
}

-- Persist a skin choice. Returns true if it changed. When `prompt` is not false and the value
-- changed, shows the reload popup (the only way the live frame picks up the new skin).
function EJ.skin.Set(key, prompt)
  if not isValid(key) then
    if DEFAULT_CHAT_FRAME then
      DEFAULT_CHAT_FRAME:AddMessage("|cffffd200EncounterJournal|r: unknown skin '" .. tostring(key) .. "'.")
    end
    return false
  end
  EJ.db = EJ.db or {}
  if EJ.db.skin == key then return false end
  EJ.db.skin = key
  if EJ.skin._onChange then EJ.skin._onChange(key) end
  if prompt ~= false then
    StaticPopup_Show("EJ_SKIN_RELOAD", EJ.skin.Label(key))
  end
  return true
end

-- Cycle to the next skin in LIST (used by a bare toggle). Honours the reload prompt.
function EJ.skin.Toggle()
  local cur, nextKey = EJ.skin.Get()
  for i, s in ipairs(EJ.skin.LIST) do
    if s.key == cur then nextKey = EJ.skin.LIST[(i % #EJ.skin.LIST) + 1].key break end
  end
  EJ.skin.Set(nextKey or EJ.skin.DRAGONFLIGHT)
end

-- ============================================================================================
-- Interface Options panel
-- ============================================================================================
-- Addon/Core/Options.lua — a minimal Interface Options panel (Interface → AddOns → Encounter
-- Journal) exposing the UI skin toggle. 3.3.5a ships InterfaceOptionsFrame + the
-- InterfaceOptions_AddCategory API; we register a single panel and drop a skin dropdown on it.
-- The actual skin swap is handled by EJ.skin.Set (persists + offers a reload). Loads after
-- Core/Dropdown.lua (needs EJ.dropdown.New) and the skin section above (EJ.skin).

EJ = EJ or {}

local function build()
  if EJ._optionsPanel then return EJ._optionsPanel end
  if not (CreateFrame and EJ.skin) then return end

  local panel = CreateFrame("Frame", "EJ_OptionsPanel", UIParent)
  panel.name = "Encounter Journal"

  local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", 16, -16)
  title:SetText("Encounter Journal")

  local sub = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
  sub:SetPoint("RIGHT", panel, "RIGHT", -32, 0)
  sub:SetJustifyH("LEFT"); sub:SetJustifyV("TOP")
  sub:SetText("Choose how the journal window looks. Switching skins reloads your UI.")

  -- Skin label + dropdown.
  local skinLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  skinLabel:SetPoint("TOPLEFT", sub, "BOTTOMLEFT", 0, -24)
  skinLabel:SetText("UI Skin")

  if EJ.dropdown and EJ.dropdown.New then
    local dd = EJ.dropdown.New(panel, "EJ_OptionsSkinDropdown", { width = 180 })
    dd:SetPoint("TOPLEFT", skinLabel, "BOTTOMLEFT", -16, -4)
    if dd.SetDefaultText then dd:SetDefaultText(EJ.skin.Label(EJ.skin.Get())) end
    dd:SetupMenu(function(_, root)
      for _, s in ipairs(EJ.skin.LIST) do
        local key = s.key
        root:CreateRadio(s.label,
          function() return EJ.skin.Is(key) end,
          function() EJ.skin.Set(key) end)
      end
    end)
    panel:SetScript("OnShow", function() if dd.GenerateMenu then dd:GenerateMenu() end end)
    panel._skinDropdown = dd
  end

  if InterfaceOptions_AddCategory then
    InterfaceOptions_AddCategory(panel)
  end
  EJ._optionsPanel = panel
  return panel
end

-- Build at load (InterfaceOptionsFrame exists by then on 3.3.5a). Guarded so a missing API
-- can't abort the addon.
pcall(build)

-- Expose an opener (handy for a future "Settings" button / slash alias).
function EJ.OpenOptions()
  local p = EJ._optionsPanel or build()
  if p and InterfaceOptionsFrame_OpenToCategory then
    InterfaceOptionsFrame_OpenToCategory(p)
    InterfaceOptionsFrame_OpenToCategory(p)   -- 3.3.5 quirk: call twice to land on the right panel
  end
end
