-- Addon/Core/Skin.lua — UI skin selection (classic vs dragonflight).
--
-- The journal's data layer (EJ.ej.DATA) is skin-independent; only the frame chrome/widget
-- art differs. This module is the single source of truth for "which skin is active":
-- skin-aware widgets (the NavBar today; chrome/fonts later) read EJ.skin.Is(...) at BUILD time.
--
--   "classic"      — the original Encounter Journal look (UI-EJ-* sprite art + the authentic
--                    CS_HelpTextures breadcrumb navbar). The default.
--   "dragonflight" — a differentiated variant (currently the plain-text breadcrumb; modern
--                    atlas art filled in later). A stub the toggle can already select.
--
-- APPLY MODEL: the window is built once and cached (EncounterJournal.lua build()), so a live
-- re-skin of an existing frame is out of scope. EJ.skin.Set() persists the choice and offers a
-- ReloadUI() — the standard addon "reload to apply a skin" flow.

EJ = EJ or {}
EJ.skin = EJ.skin or {}

EJ.skin.CLASSIC      = "classic"
EJ.skin.DRAGONFLIGHT = "dragonflight"

-- Known skins, in toggle order. label = user-facing name (options dropdown / chat).
EJ.skin.LIST = {
  { key = EJ.skin.CLASSIC,      label = "Classic" },
  { key = EJ.skin.DRAGONFLIGHT, label = "Dragonflight" },
}

local function isValid(key)
  for _, s in ipairs(EJ.skin.LIST) do if s.key == key then return true end end
  return false
end

-- Active skin key. Reads the SavedVariable (EJ.db is set in Core.lua after applyMigrations);
-- coalesces to classic before the DB exists or if a stored value is unknown.
function EJ.skin.Get()
  local k = EJ.db and EJ.db.skin
  if k and isValid(k) then return k end
  return EJ.skin.CLASSIC
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
  EJ.skin.Set(nextKey or EJ.skin.CLASSIC)
end
