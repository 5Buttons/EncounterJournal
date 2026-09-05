-- Addon/Core/TooltipWire.lua — shared hover-tooltip trigger (EJ.tooltip.Wire).
--
-- Collapses the OnEnter→SetOwner→Set…→Show (+ OnLeave→Hide) boilerplate repeated across ~39
-- buttons into one call, so a handed-over developer sees one component, not N hand-rolled
-- copies with subtly different anchors/leave-handlers.
--
-- Core-owned (not the Tooltip *skin* module's job): Wire only attaches scripts, so it must work
-- even when the GameTooltip skin module is disabled. Core loads first and seeds EJ.tooltip; the
-- skin module later extends the SAME table with ApplyScale/SetAutoCompare/etc.
--
--   EJ.tooltip.Wire(button, "Clean Up Bank")                 -- static text, ANCHOR_RIGHT
--   EJ.tooltip.Wire(button, txt, { anchor = "ANCHOR_LEFT" })
--   EJ.tooltip.Wire(button, function(self, tip)              -- dynamic: populate tip yourself,
--     tip:AddLine(...); tip:AddDoubleLine(...)               --   or return a string to SetText
--   end)
--
-- opts:
--   anchor  = "ANCHOR_RIGHT"  -- SetOwner anchor (default)
--   owner   = nil             -- anchor to THIS frame, not the hovered one (e.g. AH sell: both the
--                                wide row and the 54px slot anchor to the slot)
--   hook    = false           -- HookScript instead of SetScript (keep the template's handlers)
--   noLeave = false           -- don't wire OnLeave (caller has a custom one)
--   refresh = false           -- own frame.UpdateTooltip so GameTooltip's poll re-runs the populate
--                                while hovered — for async-cached data (talents SetTalent header→
--                                full). Mirrors Era's PlayerTalentFrameTalent_OnEnter.

EJ = EJ or {}
EJ.tooltip = EJ.tooltip or {}

-- Set the title via retail's GameTooltip_SetTitle (Era ships it) — wraps deterministically, so
-- short labels stay on one line where raw SetText can wrap. Falls back to SetText pre-helper.
local function setTitle(text)
  if GameTooltip_SetTitle then GameTooltip_SetTitle(GameTooltip, text)
  else GameTooltip:SetText(text) end
end

function EJ.tooltip.Wire(frame, body, opts)
  if not frame then return end
  opts = opts or {}
  local anchor = opts.anchor or "ANCHOR_RIGHT"
  local attach = (opts.hook and frame.HookScript) or frame.SetScript

  -- Named so opts.refresh can install it as frame.UpdateTooltip (GameTooltip polls that
  -- ~5x/sec while the owner is hovered, re-running the populate as async data caches in).
  local function onEnter(self)
    if not GameTooltip then return end
    GameTooltip:SetOwner(opts.owner or self, anchor)
    if type(body) == "function" then
      -- function populates the tip itself (or returns a string → title)
      local txt = body(self, GameTooltip)
      if type(txt) == "string" then setTitle(txt) end
    elseif body ~= nil then
      setTitle(body)
    end
    GameTooltip:Show()
    if opts.refresh then self.UpdateTooltip = onEnter end
  end
  attach(frame, "OnEnter", onEnter)

  if not opts.noLeave then
    attach(frame, "OnLeave", function(self)
      if opts.refresh then self.UpdateTooltip = nil end
      if GameTooltip then GameTooltip:Hide() end
    end)
  end
end
