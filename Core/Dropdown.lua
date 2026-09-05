-- Addon/Core/Dropdown.lua — the classic UIDropDownMenu, wrapped in the tiny modern-style
-- surface our call sites use. Replaces the old Core/DropdownSkin.lua.
--
-- WHY: the New Era source built RETAIL dropdowns — CreateFrame("DropdownButton", …,
-- "WowStyle1DropdownTemplate") + :SetupMenu/:GenerateMenu/root:CreateRadio. Neither the
-- frame type nor those methods exist on 3.3.5a, and DropdownSkin.lua only re-painted the
-- retail DropdownButton's atlas art (meaningless for a classic dropdown). 3.3.5a ships the
-- classic UIDropDownMenu in FrameXML, and !!!ClassicAPI bundles a parallel C_UIDropDownMenu_*
-- copy with the same classic look. We build the menu the classic way (Initialize + CreateInfo
-- + AddButton) but keep the call sites' radio-generator shape, so EncounterJournal.lua /
-- EncounterPage.lua / WorldMap/DungeonMap.lua each only swapped one CreateFrame line.
--
-- USAGE
--   local dd = EJ.dropdown.New(parent, "GlobalName"|nil, { width = 160 })
--   dd:SetPoint(...)                 -- it's a real Frame; native methods pass through
--   dd:SetDefaultText(ALL)           -- optional collapsed label when nothing is checked
--   dd:SetupMenu(function(dropdown, root)
--     root:CreateRadio(label, function() return isSelected end, function() ...select... end)
--   end)
--   dd:GenerateMenu()                -- refresh the collapsed label (e.g. after a category swap)

EJ = EJ or {}
EJ.dropdown = EJ.dropdown or {}

-- Pick ONE family and stay consistent — a C_-template frame driven by native Initialize (or
-- vice-versa) mismatches, since each Initialize sets attributes its own template's scripts
-- read. !!!ClassicAPI (a hard dependency) ships the C_ family; native is the fallback if it's
-- somehow absent (the addon wouldn't load without ClassicAPI anyway).
local hasC       = C_UIDropDownMenu_Initialize ~= nil
local TEMPLATE   = hasC and "C_UIDropDownMenuTemplate" or "UIDropDownMenuTemplate"
local Init       = hasC and C_UIDropDownMenu_Initialize or UIDropDownMenu_Initialize
local CreateInfo = hasC and C_UIDropDownMenu_CreateInfo or UIDropDownMenu_CreateInfo
local AddButton  = hasC and C_UIDropDownMenu_AddButton  or UIDropDownMenu_AddButton
local SetText    = hasC and C_UIDropDownMenu_SetText    or UIDropDownMenu_SetText
local SetWidth   = hasC and C_UIDropDownMenu_SetWidth   or UIDropDownMenu_SetWidth
local CloseAll   = hasC and C_CloseDropDownMenus        or CloseDropDownMenus

-- Resolve the collapsed (button) label by replaying the generator in scan-only mode: the radio
-- whose isChecked() returns true wins, else the explicit default text. Cheap — the generators
-- here are pure reads of addon state, so running them an extra time has no side effects.
local function resolveText(dd)
  local checked
  local root = {}
  function root.CreateRadio(_, label, isChecked)
    if isChecked and isChecked() then checked = label end
  end
  if dd._gen then dd._gen(dd, root) end
  return checked or dd._defaultText or ""
end

local methods = {}

-- generator(dropdown, root): call root:CreateRadio(label, isCheckedFn, onClickFn) per option.
function methods:SetupMenu(generator)
  self._gen = generator
  Init(self, function(_, level)
    level = level or 1
    local root = {}
    function root.CreateRadio(_, label, isChecked, onClick)
      local info = CreateInfo()
      info.text    = label
      info.checked = isChecked and isChecked() or false
      info.func    = function()
        if onClick then onClick() end
        SetText(self, resolveText(self))   -- refresh collapsed label after the selection
        if CloseAll then CloseAll() end
      end
      AddButton(info, level)
    end
    generator(self, root)
  end)
  SetText(self, resolveText(self))
end

-- Refresh the collapsed label from the currently-checked radio (no menu rebuild). Mirrors the
-- retail DropdownButton:GenerateMenu() the call sites invoke after a category/state change.
function methods:GenerateMenu()
  SetText(self, resolveText(self))
end

-- Set the fallback collapsed label (shown when no radio is checked); also the direct
-- "show this text now" call some sites make right after a selection.
function methods:SetDefaultText(text)
  self._defaultText = text
  SetText(self, resolveText(self))
end

-- Pop a TRANSIENT context menu (a list of { text=, func=, disabled= }) anchored to `anchor`
-- (a frame, or "cursor"). Used by the navbar breadcrumb's boss-jump arrow. Built on EasyMenu —
-- native 3.3.5a preferred (battle-tested; ClassicAPI's C_EasyMenu mixes C_/native init), with
-- C_EasyMenu as the fallback. A single reusable menu frame is created lazily on first use.
local EZ          = EasyMenu or C_EasyMenu
local EZ_TEMPLATE = EasyMenu and "UIDropDownMenuTemplate" or "C_UIDropDownMenuTemplate"
local easyFrame
function EJ.dropdown.OpenMenu(anchor, entries, opts)
  if not (EZ and entries and #entries > 0) then return end
  easyFrame = easyFrame or CreateFrame("Frame", "EJ_DropdownContextMenu", UIParent, EZ_TEMPLATE)
  local list = {}
  for _, e in ipairs(entries) do
    list[#list + 1] = { text = e.text, notCheckable = true, func = e.func, disabled = e.disabled }
  end
  opts = opts or {}
  EZ(list, easyFrame, anchor or "cursor", opts.x or 0, opts.y or 0, "MENU")
end

-- parent, name (optional global name), opts { width }.
--
-- A GLOBAL NAME IS MANDATORY even though callers may pass nil: the classic dropdown's helpers
-- (SetText/SetWidth/…) resolve the template's pieces by string —  _G[frame:GetName().."Text"],
-- ..."Middle", ..."Button" — and the "$parent*" template children only get global names when
-- the frame itself is named. An unnamed frame → GetName() is nil → "concatenate nil" the moment
-- we set the width or text. So auto-assign a unique name when one isn't supplied.
local autoIndex = 0
function EJ.dropdown.New(parent, name, opts)
  opts = opts or {}
  if not name then
    autoIndex = autoIndex + 1
    name = "EJ_Dropdown" .. autoIndex
  end
  local dd = CreateFrame("Frame", name, parent, TEMPLATE)
  for k, v in pairs(methods) do dd[k] = v end
  if opts.width and SetWidth then SetWidth(dd, opts.width) end
  return dd
end
