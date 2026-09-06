-- Addon/Core/Options.lua — a minimal Interface Options panel (Interface → AddOns → Encounter
-- Journal) exposing the UI skin toggle. 3.3.5a ships InterfaceOptionsFrame + the
-- InterfaceOptions_AddCategory API; we register a single panel and drop a skin dropdown on it.
-- The actual skin swap is handled by EJ.skin.Set (persists + offers a reload). Loads after
-- Core/Dropdown.lua (needs EJ.dropdown.New) and Core/Skin.lua (needs EJ.skin).

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
