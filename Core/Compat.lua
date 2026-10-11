-- Core/Compat.lua — the journal's own shims for the handful of post-3.3.5a APIs it uses.
--
-- The addon runs on a stock 3.3.5a client. !!!ClassicAPI is an OPTIONAL dependency: when it is
-- loaded, a shim hands off to its implementation (C_Timer, C_Item, C_AddOns, GetPhysicalScreenSize,
-- SearchBoxTemplate); when it is absent, the fallback here does the job with native 3.3.5a calls.
-- Nothing in this file creates or modifies a global the client or another addon could see —
-- everything lives on the EJ table — so it can't clash with ClassicAPI or other addons.
--
-- Loaded FIRST in the TOC (before Core.lua), so it creates the EJ table.

EJ = EJ or {}

-- True when Tsoukie's !!!ClassicAPI is loaded (it sorts first and is an OptionalDep, so by the
-- time this file runs it has fully loaded if it is installed and enabled).
EJ.HasClassicAPI = (IsAddOnLoaded and IsAddOnLoaded("!!!ClassicAPI")) and true or false

-- ---------------------------------------------------------------------------------------------
-- Timers — EJ.After(delay, fn) ≈ C_Timer.After. Fallback: one hidden OnUpdate frame that runs
-- due callbacks; idle (no OnUpdate) while nothing is queued.
-- ---------------------------------------------------------------------------------------------
if C_Timer and C_Timer.After then
  EJ.After = C_Timer.After
else
  local queue, driver = {}, nil
  local function onUpdate(self)
    local now, i = GetTime(), 1
    while i <= #queue do
      local t = queue[i]
      if t.at <= now then
        table.remove(queue, i)
        local ok, err = pcall(t.fn)
        if not ok and geterrorhandler then geterrorhandler()(err) end
      else
        i = i + 1
      end
    end
    if #queue == 0 then self:SetScript("OnUpdate", nil) end
  end
  function EJ.After(delay, fn)
    if type(fn) ~= "function" then return end
    driver = driver or CreateFrame("Frame")
    queue[#queue + 1] = { at = GetTime() + math.max(0, tonumber(delay) or 0), fn = fn }
    driver:SetScript("OnUpdate", onUpdate)
  end
end

-- ---------------------------------------------------------------------------------------------
-- Widget helpers for methods 3.3.5a lacks (Region:SetShown, Button:SetEnabled arrived in 4.x+).
-- Plain functions instead of metatable patches, so no other addon's widgets are touched.
-- ---------------------------------------------------------------------------------------------
function EJ.SetShown(obj, shown)
  if not obj then return end
  if shown then obj:Show() else obj:Hide() end
end

function EJ.SetEnabled(btn, enabled)
  if not btn then return end
  if enabled then btn:Enable() else btn:Disable() end
end

-- ---------------------------------------------------------------------------------------------
-- Physical screen size. 3.3.5a has no GetPhysicalScreenSize; the "gxResolution" CVar holds the
-- active mode as "1920x1080". Returns width, height (0, 0 if unknown).
-- ---------------------------------------------------------------------------------------------
function EJ.PhysicalScreenSize()
  if GetPhysicalScreenSize then
    local w, h = GetPhysicalScreenSize()
    if h and h > 0 then return w, h end
  end
  local res = GetCVar and GetCVar("gxResolution")
  local w, h = res and res:match("^(%d+)x(%d+)")
  if not w then
    -- GetScreenResolutions()[GetCurrentResolution()] is the same string on 3.3.5a
    local idx = GetCurrentResolution and GetCurrentResolution()
    local list = idx and GetScreenResolutions and { GetScreenResolutions() }
    res = list and list[idx]
    w, h = res and res:match("^(%d+)x(%d+)")
  end
  return tonumber(w) or 0, tonumber(h) or 0
end

-- ---------------------------------------------------------------------------------------------
-- Add-on queries (C_AddOns on newer clients / ClassicAPI, the plain globals on 3.3.5a).
-- ---------------------------------------------------------------------------------------------
function EJ.IsAddOnLoaded(name)
  local fn = (C_AddOns and C_AddOns.IsAddOnLoaded) or _G.IsAddOnLoaded
  if not fn then return false end
  local ok, loaded = pcall(fn, name)
  return (ok and loaded) and true or false
end

-- True if the addon is INSTALLED (present + enabled), loaded or not. IsAddOnLoaded is wrong for
-- LoadOnDemand addons, which aren't loaded at PLAYER_LOGIN. GetAddOnInfo's 6th return ("reason")
-- is "MISSING" only when the addon isn't there at all.
function EJ.IsAddOnInstalled(name)
  local fn = (C_AddOns and C_AddOns.GetAddOnInfo) or _G.GetAddOnInfo
  if not fn then return EJ.IsAddOnLoaded(name) end
  local ok, _, _, _, _, reason = pcall(fn, name)
  return ok and reason ~= "MISSING"
end

-- ---------------------------------------------------------------------------------------------
-- Items. EJ.RequestItem asks the server for an item the client hasn't cached: ClassicAPI's
-- C_Item.RequestLoadItemDataByID when present (pcall: it throws on ids this server doesn't know),
-- plus the native 3.3.5a way — a hidden tooltip SetHyperlink, which is what AtlasLoot does.
-- EJ.SetTooltipItem fills a tooltip for a CACHED item (SetItemByID is 4.x+; SetHyperlink with a
-- cached item sends nothing to the server).
-- ---------------------------------------------------------------------------------------------
local scanTip
function EJ.RequestItem(itemID)
  if not itemID then return end
  if C_Item and C_Item.RequestLoadItemDataByID then pcall(C_Item.RequestLoadItemDataByID, itemID) end
  scanTip = scanTip or CreateFrame("GameTooltip", "EJ_ItemScanTip", nil, "GameTooltipTemplate")
  scanTip:SetOwner(UIParent, "ANCHOR_NONE")
  pcall(scanTip.SetHyperlink, scanTip, "item:" .. itemID .. ":0:0:0:0:0:0:0")
end

function EJ.SetTooltipItem(tooltip, itemID)
  local _, link = GetItemInfo(itemID)
  if not link then return false end
  return pcall(tooltip.SetHyperlink, tooltip, link) and true or false
end
