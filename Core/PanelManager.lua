-- Core/PanelManager.lua — EJ.panelmgr: retail-style UIPanel positioning for OUR frames.
--
-- Reimplements retail's UIParentPanelManager left/center/right slot system (areas + pushable
-- sorting + side-by-side tiling + auto-minimize) WITHOUT registering our frames with Era's
-- UIPanelWindows. We avoid that on purpose: writing UIPanelWindows taints it, and ShowUIPanel is
-- combat-gated for our PROTECTED frames (Professions/Talents parent secure buttons) — they open in
-- combat via secure toggles, which native registration would regress. So we position via plain
-- SetPoint and re-assert after Era's own manager runs (UpdateUIPanelPositions hook below).
--
-- SCOPE: this manages the COMPLETE set of panel-class windows New Era produces — every UIPanel-area
-- window (our custom NE_ frames AND the natives we reskin in place), so ONE coordinator reserves a
-- slot for each and they tile around each other (the "dynamic position" contract). HUD / Edit-Mode
-- frames (unit frames, action bars, buff frame, minimap, cooldown viewers, boss mods, PRD, trackers)
-- are NOT panels and are never registered here. A frame's default position = its retail UIPanel slot.
--
-- MOVABILITY = retail parity: retail's UIPanels are NOT user-movable (the manager owns their
-- position); the ONE genuinely drag-movable retail standalone is StopwatchFrame, which we leave as
-- Era's native frame untouched. So NO EJ panel is user-draggable — the old "managed-with-breakout"
-- drag handles were removed (owner rule: movable in retail ⟺ movable for us).
--
-- Base offsets are VERIFIED from retail 12.0.5 / Era 1.15.8 (byte-identical, UIParent.xml:5-15;
-- LEFT/TOP also confirmed via `/neprobe charpos`):
--   LEFT_OFFSET = 16, TOP_OFFSET = -116, CENTER_OFFSET = 16+leftWidth (no inter-panel gap).
--
-- area (retail UIPanelWindows semantics):
--   "left"         — leftmost slot; tiles right of earlier (lower-pushable) frames.
--   "center"       — centered on screen when shown; EXCLUSIVE (closes other panels).
--   "centerOrLeft" — center when it's the ONLY panel open, else behaves as left (retail PlayerSpells).
--   "doublewide"   — spans left+center; treated as a wide left frame, others tile to its right.
-- pushable: sort key. Lower = further left. Ties broken by show-recency (oldest = leftmost).
--           pushable 0 frames mutually replace (retail: you can't gossip and vendor at once).
--
-- Combat: SetPoint/Hide/Raise are combat-locked only on PROTECTED frames. Reflow runs freely in
-- combat when no protected (watch) frame is shown (so plain natives like CharacterFrame re-assert
-- their tile position against Era's combat re-slot); if a watch frame is shown the whole pass is
-- deferred to PLAYER_REGEN_ENABLED (frames keep their last out-of-combat position meanwhile).

local EJ = EJ
EJ.panelmgr = EJ.panelmgr or {}
local M = EJ.panelmgr

-- All four VERIFIED from UIParent.xml:5-15 (era==retail; LEFT/TOP also confirmed via /neprobe charpos).
local LEFT_OFFSET   = 16
local TOP_OFFSET    = -116
local SPACING       = 32      -- PANEl_SPACING_X — the gap between adjacent tiled panels
local DEFAULT_WIDTH = 384     -- DEFAULT_FRAME_WIDTH — width fallback when GetWidth is unavailable
-- Retail UIParent.xml:13 — reserved strip at the right screen edge; the tiled row may not
-- cross UIParent width minus this (GetMaxUIPanelsWidth, UIParentPanelManager.lua:929-940).
local RIGHT_OFFSET_BUFFER = 80
-- Retail CHECK_FIT_DEFAULT_EXTRA_WIDTH/HEIGHT (UIParentPanelManager.lua:78-79 doc).
local CHECK_FIT_EXTRA = 20

M._reg = M._reg or {}         -- [frame] = meta { area, pushable, width, xoffset, yoffset, _shown, _seq }
M._seq = M._seq or 0

-- Per-frame area/pushable, keyed by frame global name. Values are retail's UIPanelWindows
-- attributes (or RegisterUIPanel calls). A module calls M.Register(frame) (or the frame is caught
-- by name in M.ScanRegister) and the meta is looked up here, so all the tuning lives in one place.
--
-- DUAL-WRITE: the NATIVE frames below ALSO live in Era's UIPanelWindows, so Era's secure manager
-- positions them too. Our re-assert hook (hooksecurefunc UpdateUIPanelPositions → ScheduleReflow,
-- bottom of file) runs after Era and re-tiles everything consistently. We do NOT write Era's
-- UIPanelWindows (that taints the secure system) and we never SetUserPlaced / HideUIPanel.
--
-- PROTECTED frames (`watch = true`: EJ_TalentFrame / EJ_ProfessionsFrame — they parent secure
-- buttons) are managed, but their OnShow/OnHide slots are OWNED by SecureHandlerWrapScript
-- ESC-binding snippets, so Register() parents an invisible plain child whose OnShow/OnHide fires
-- with the parent's effective visibility on every open path without touching the parent's scripts.
M.DEFAULTS = {
  -- ============================ NATIVE frames (reskinned in place; Era global names) ============
  -- CharacterFrame ← retail left/3 (Mainline UIPanelWindows.lua:9). RE-MANAGED (2026-06-20): it must
  -- tile with the other left panels so DressUp/Inspect/etc. don't render on top of it. Non-protected,
  -- so Reflow re-asserts its retail slot even in combat (combat-partial reflow), countering Era's
  -- own UIPanelWindows re-slot to (0,-83) that previously made the panel jump. CharacterPanel.lua
  -- only applies DIMENSIONS now (applyRetailPosition is a no-op stub); position is ours.
  CharacterFrame       = { area = "left",         pushable = 3, whileDead = 1 },
  -- InspectFrame ← retail left/0 (Blizzard_InspectUI.lua:6). Managing it reserves the 32px SPACING
  -- so EJ_TalentFrame (centerOrLeft) no longer butts up against it with no padding. LoD (caught by
  -- the ADDON_LOADED scan). Era declares pushable 2; retail is 0 — we use retail.
  InspectFrame         = { area = "left",         pushable = 0 },
  FriendsFrame         = { area = "left",         pushable = 0, whileDead = 1 },  -- "Social"
  -- NPC-interaction + misc natives ← retail UIPanelWindows.lua:16-29 (all left/0). The pushable-0
  -- mutual-replace among them is retail-literal (you can't gossip and vendor at once; plain :Hide()
  -- ends the NPC session via each frame's own OnHide, as retail's replace does).
  GossipFrame          = { area = "left",         pushable = 0 },
  QuestFrame           = { area = "left",         pushable = 0 },
  MerchantFrame        = { area = "left",         pushable = 0 },
  MailFrame            = { area = "left",         pushable = 0 },
  TradeFrame           = { area = "left",         pushable = 0 },  -- retail 0 (Era declares 1)
  TaxiFrame            = { area = "left",         pushable = 0 },
  ItemTextFrame        = { area = "left",         pushable = 0 },
  PetitionFrame        = { area = "left",         pushable = 0 },
  GuildRegistrarFrame  = { area = "left",         pushable = 0 },
  TabardFrame          = { area = "left",         pushable = 0 },
  DressUpFrame         = { area = "left",         pushable = 2 },
  -- MacroFrame / ChannelFrame ← retail left/1 whileDead (Blizzard_MacroUI.lua:2 / Channels:1). LoD/
  -- always-loaded reskins; live GetWidth (≈338) rules.
  MacroFrame           = { area = "left",         pushable = 1, whileDead = 1 },
  ChannelFrame         = { area = "left",         pushable = 1, whileDead = 1 },
  -- HelpFrame ← retail center/0 whileDead (Mainline UIPanelWindows.lua:5). A center frame is
  -- EXCLUSIVE — opening it closes the other panels (retail behaviour).
  HelpFrame            = { area = "center",       pushable = 0, whileDead = 1 },
  -- BankFrame: retail lists width 425 for the LEGACY bank; ours is the modern 738-wide rebuild, so
  -- live GetWidth must rule — no width override. Retail left/6 (Mainline UIPanelWindows.lua:22).
  BankFrame            = { area = "left",         pushable = 6, whileDead = 1 },
  -- World map + quest log ← retail WorldMapFrame (Blizzard_WorldMap.lua:126 RegisterUIPanel:
  -- left/0, allowOtherPanels). watch: it parents a SECURE close button → protected tree.
  -- skip(): only the MINIMIZED (windowed) map is managed; the maximized map owns the screen
  -- (WorldMap.lua applyDisplayGeometry centres it) and must not hold a tile slot.
  WorldMapFrame        = { area = "left",         pushable = 0, watch = true,
                           skip = function() return _G.WorldMapFrame and _G.WorldMapFrame._ejMaximized end },

  -- ============================ CUSTOM NE_ frames (self-register at build; meta lives here) ======
  EJ_EncounterJournal  = { area = "left",         pushable = 0, width = 830 },
  EJ_AuctionHouseFrame = { area = "doublewide",   pushable = 0, xoffset = 20 },
  -- Achievements ← retail AchievementFrame (Mainline Blizzard_AchievementUI.lua:2 doublewide/0
  -- xoffset 80 whileDead).
  EJ_AchievementFrame  = { area = "doublewide",   pushable = 0, xoffset = 80, whileDead = 1 },
  -- Guild ← retail CommunitiesFrame (Mainline UIPanelWindows.lua:36 left/1 whileDead). Keeps its
  -- user min/max button (retail has it); live GetWidth (322 minimized / 814 maximized) rules.
  EJ_GuildFrame        = { area = "left",         pushable = 1, whileDead = 1 },
  EJ_PVEFrame          = { area = "left",         pushable = 1, whileDead = 1 },  -- "LFG"
  -- Pet stable ← retail StableFrame (Blizzard_StableUI.lua:206 left/1). Built lazily on
  -- PET_STABLE_SHOW; PetStable.lua calls Register. (Era's native PetStableFrame is left/0.)
  EJ_PetStableFrame    = { area = "left",         pushable = 1, whileDead = 1 },
  -- Calendar ← retail CalendarFrame (Mainline Blizzard_Calendar.lua:31 doublewide/0 whileDead,
  -- yoffset 20). Built lazily on first open; Calendar.lua calls Register.
  EJ_Calendar          = { area = "doublewide",   pushable = 0, whileDead = 1, yoffset = 20 },
  -- Talents & Spellbook ← retail PlayerSpellsFrame (Blizzard_PlayerSpellsRegistration.lua:2-18:
  -- centerOrLeft/3, allowOtherPanels, checkFit +200w/+140h, autoMinimizeWithOtherPanels). Retail's
  -- yoffset=75 is tuned for retail's taller frame; ours preserves EJ_TalentFrame's parity Y (-16 =
  -- TOP_OFFSET + 100) in both the centered and tiled states (retail's same-yPos-both-branches law).
  -- autoMinimize (the Spellbook's setMinimizedFunc) is wired at runtime via M.SetAutoMinimize so the
  -- full-width (1618) spellbook collapses to its compact (809) width when another panel tiles beside
  -- it, instead of overflowing the row (retail PlayerSpellsFrame.ShouldAutoMinimize).
  EJ_TalentFrame            = { area = "centerOrLeft", pushable = 3, yoffset = 100, watch = true, whileDead = 1,
                                checkFit = true, checkFitExtraWidth = 200, checkFitExtraHeight = 140 },
  -- Professions book ← retail ProfessionsBookFrame (Mainline UIPanelWindows.lua:10 left/1,
  -- width=575). The DECLARED slot width (575) is what retail uses to offset the NEXT tiled frame
  -- — NOT the live frame width (550). Verified via /neprobe panels.
  EJ_ProfessionsFrame       = { area = "left",         pushable = 1, watch = true, whileDead = 1, width = 575 },
  -- Crafting window ← retail ProfessionsFrame (Blizzard_ProfessionsRegistration.lua:2-10:
  -- left/1, xoffset 35, checkFit, allowOtherPanels). It PARENTS a secure craft-forward button
  -- (EJ_ProfessionsCraftForward, Crafting.lua:846) → the frame is implicitly PROTECTED, so its
  -- checkFit SetScale / any Hide is combat-locked. NOT `watch` (its OnShow isn't secure-wrapped, so
  -- it keeps synchronous positioning — no one-frame fallback flash); instead `secureChild` makes the
  -- combat defer explicit rather than relying on IsProtected() timing. Keeps its user min/max button
  -- (404 minimized / 942 maximized); live GetWidth rules.
  EJ_ProfessionsCraftingFrame = { area = "left",       pushable = 1, xoffset = 35, checkFit = true, secureChild = true },
}

-- Only a pure "center" frame is EXCLUSIVE (HelpFrame). "centerOrLeft" is retail-literal
-- (UIParentPanelManager.lua:52 + 635-637): centered when it's the ONLY open panel, otherwise it
-- joins the left tiling like any pushable frame — PlayerSpells coexists (allowOtherPanels = 1).
local function isExclusive(area) return area == "center" end
local function isCenterish(area) return area == "center" or area == "centerOrLeft" end

local function inCombat() return InCombatLockdown and InCombatLockdown() end

-- Registration. Call once per managed frame (typically right after it's created).
--   meta = { area = "left"|"center"|"centerOrLeft"|"doublewide", pushable = n,
--            width = <override>, xoffset = <px>, yoffset = <px> }
function M.Register(frame, meta)
  if not frame or M._reg[frame] then return end
  if not meta then
    local name = frame.GetName and frame:GetName()
    meta = name and M.DEFAULTS[name]
  end
  if not meta then return end   -- unknown frame; nothing to position
  M._reg[frame] = meta
  -- NOTE: deliberately NO SetUserPlaced — it TAINTS the frame (and errors on non-movable ones
  -- like DressUpFrame). Not needed: Era positions a panel then calls frame:Show() (UIParentPanel
  -- Manager.lua SetUIPanel ~456→461), so our OnShow hook fires AFTER Era and overrides its anchor.
  -- Non-watch frames reflow SYNCHRONOUSLY in the hook + schedule the deferred corrector. watch
  -- frames stay DEFERRED-only: their shows run inside secure snippets, where a synchronous reflow
  -- is exactly what broke the open.
  local sync = not meta.watch
  local function onShow()
    local mt = M._reg[frame]; if not mt then return end
    M._seq = M._seq + 1; mt._seq = M._seq; mt._shown = true
    if sync then M.Reflow() end
    M.ScheduleReflow()
  end
  local function onHide()
    local mt = M._reg[frame]; if not mt then return end
    mt._shown = false
    if sync then M.Reflow() end
    M.ScheduleReflow()
  end
  if meta.watch then
    -- PROTECTED frame whose OnShow/OnHide slots are secure-wrapped (ESC binding snippets) —
    -- HookScript there broke the secure open. A plain invisible CHILD frame's OnShow/OnHide
    -- fires with the parent's effective visibility on every open path, and SetScript on our
    -- own child never touches the parent's script chain.
    local w = CreateFrame("Frame", nil, frame)
    w:SetScript("OnShow", onShow)
    w:SetScript("OnHide", onHide)
    meta._watcher = w
  else
    frame:HookScript("OnShow", onShow)
    frame:HookScript("OnHide", onHide)
  end
  if frame:IsShown() then
    M._seq = M._seq + 1; M._reg[frame]._seq = M._seq; M._reg[frame]._shown = true
    M.ScheduleReflow()
  end
end

-- Auto-minimize behaviour for a managed frame (retail autoMinimizeWithOtherPanels). The Spellbook
-- calls this once the shared EJ_TalentFrame exists. Merges into the frame's meta; registers it first
-- if needed. opts = { withOtherPanels = bool, condition = bool|func, setMinimized = func(frame,bool) }.
function M.SetAutoMinimize(frame, opts)
  if not frame or not opts then return end
  if not M._reg[frame] then M.Register(frame) end
  local m = M._reg[frame]; if not m then return end
  m.autoMinimizeWithOtherPanels = opts.withOtherPanels
  m.autoMinimizeOnCondition     = opts.condition
  m.setMinimizedFunc            = opts.setMinimized
  M.ScheduleReflow()
end

-- Reflow on the NEXT frame, coalesced. CRITICAL: our protected frames (Professions/Talents) are
-- shown by SECURE snippets (the micro-button wraps); running the reflow synchronously inside their
-- OnShow does SetPoint/Hide on protected frames mid-secure-show and breaks the open. Deferring lets
-- the secure show finish first, then we position/close cleanly.
function M.ScheduleReflow()
  if M._scheduled then return end
  M._scheduled = true
  if C_Timer and C_Timer.After then
    C_Timer.After(0, function() M._scheduled = nil; M.Reflow() end)
  else
    M._scheduled = nil; M.Reflow()
  end
end

-- Width a frame consumes in UIPARENT space. meta.width overrides are UIParent-space (like
-- retail's UIPanelWindows width attributes); a live GetWidth() is in the frame's own units,
-- so pixel-pinned frames (scale ≠ 1) must be multiplied out (retail GetUIPanelWidth equiv).
local function widthOf(frame, meta)
  if meta.width then return meta.width end
  local w = (frame.GetWidth and frame:GetWidth()) or DEFAULT_WIDTH
  return w * ((frame.GetScale and frame:GetScale()) or 1)
end

-- In combat a PROTECTED frame cannot be position-mutated (SetPoint/Hide/SetScale forbidden). Such a
-- frame is "locked": the reflow leaves it exactly where it is and re-runs a full pass at
-- PLAYER_REGEN_ENABLED. NON-protected frames are NOT locked — their SetPoint is legal in combat, so
-- they still tile NOW (vendor/character/NPC windows coordinate during combat instead of stacking).
-- Out of combat nothing is locked. Three protection signals: `meta.watch` (windows whose OnShow/
-- OnHide are secure-wrapped), `meta.secureChild` (frames that parent a secure button but position
-- synchronously — explicit so combat-safety doesn't hinge on secure-child construction order), and
-- frame:IsProtected() as the runtime catch-all (true when the frame OR ANY DESCENDANT is protected).
local function frameLocked(frame, meta)
  if not inCombat() then return false end
  return meta.watch or meta.secureChild or (frame.IsProtected and frame:IsProtected())
end

-- Shown managed frames, each tagged `locked` (protected-in-combat). Locked frames STAY in the
-- tiling math (they reserve their slot, so non-protected frames tile AROUND them instead of on top),
-- but every position mutation (SetPoint/Hide/Raise/SetScale) is skipped for them — see the guards in
-- closePanel/raise/applyCheckFit/evalAutoMinimize and the tile loop. A full pass at
-- PLAYER_REGEN_ENABLED positions them once lockdown lifts.
-- A window the player dragged somewhere themselves leaves the panel row for good: it is never
-- re-tiled and the other windows tile as if it weren't open (the DragonUI_NewEra panel-manager
-- rule). The journal calls this from its OnDragStop after persisting the point; ClearUserPlaced
-- (the `/ej resetpos` path) hands the window back to the tiler.
function M.MarkUserPlaced(frame)
  local m = frame and M._reg[frame]
  if m then m.userPlaced = true end
end
function M.ClearUserPlaced(frame)
  local m = frame and M._reg[frame]
  if m then m.userPlaced = nil; M.ScheduleReflow() end
end

local function gatherShown()
  local shown = {}
  for frame, meta in pairs(M._reg) do
    if frame:IsShown() and not (meta.skip and meta.skip()) and not meta.userPlaced then
      shown[#shown + 1] = { frame = frame, meta = meta, locked = frameLocked(frame, meta) }
    end
  end
  return shown
end

-- Retail checkFit (UIPanelUpdateScaleForFit → FrameUtil.UpdateScaleForFitSpecific,
-- FrameUtil.lua:169-179): scale the frame down so (size + extra buffer) fits UIParent;
-- never scale UP past its intended scale. Retail's version is absolute (SetScale(1) then
-- ratio) because its panels live at scale 1; ours compose with the pixel-pin — the frame's
-- pinned scale is the "1" baseline. The baseline self-heals: if an outside owner (the pin,
-- a login apply) wrote a scale we didn't, adopt it as the new base.
local function applyCheckFit(e)
  if e.locked then return end   -- SetScale on a protected frame is combat-locked
  local f, meta = e.frame, e.meta
  if not meta.checkFit then return end
  local cur = (f.GetScale and f:GetScale()) or 1
  if meta._fitApplied == nil or math.abs(cur - meta._fitApplied) > 0.001 then
    meta._fitBase = cur
  end
  local base = meta._fitBase or 1
  local availW = _G.UIParent:GetWidth()  / base
  local availH = _G.UIParent:GetHeight() / base
  local ratio = math.min(
    availW / (f:GetWidth()  + (meta.checkFitExtraWidth  or CHECK_FIT_EXTRA)),
    availH / (f:GetHeight() + (meta.checkFitExtraHeight or CHECK_FIT_EXTRA)),
    1)
  local new = base * ratio
  if math.abs(new - cur) > 0.001 then f:SetScale(new) end
  meta._fitApplied = new
end

-- Auto-minimize (retail EvaluateAutoMinimize, UIParentPanelManager.lua:732-764): a frame flagged
-- autoMinimizeWithOtherPanels shrinks when it shares the screen and restores when alone, via its
-- setMinimizedFunc. Ours drives the Spellbook tab (retail PlayerSpellsFrame autoMinimize) so a
-- full-width (1618) spellbook auto-collapses to its compact (809) width when another panel tiles
-- beside it instead of overflowing the row. Runs BEFORE width measurement so the shrunk frame
-- consumes less of the row.
local function evalAutoMinimize(e, otherOpen)
  if e.locked then return end   -- can't change a protected frame's width in combat
  local m = e.meta
  if not m.setMinimizedFunc then return end
  if not (m.autoMinimizeWithOtherPanels or m.autoMinimizeOnCondition ~= nil) then return end
  local should = false
  if m.autoMinimizeWithOtherPanels and otherOpen then should = true end
  if not should and m.autoMinimizeOnCondition ~= nil then
    if type(m.autoMinimizeOnCondition) == "function" then
      should = m.autoMinimizeOnCondition(e.frame) and true or false
    else
      should = m.autoMinimizeOnCondition and true or false
    end
  end
  m.setMinimizedFunc(e.frame, should)
end

-- Close a managed frame for an exclusivity/replace decision. Plain :Hide() only — NOT HideUIPanel
-- (that dispatches into the secure UIPanel system and taints). For our native frames the slight
-- slot-tracking desync with Era is harmless since our reflow owns positioning. OnHide fires a
-- (guarded) reflow either way.
local function closePanel(e)
  if e.locked then return end   -- Hide on a protected frame is combat-locked
  if e.frame:IsShown() then e.frame:Hide() end
end

-- Layering. Retail re-stacks EVERY managed panel on each UpdateUIPanelPositions via frame:Raise()
-- (UIParentPanelManager.lua:606/625/672/710), so the just-positioned row sits cleanly above stale
-- frames at the same strata. Raise() only reorders within a strata and is not a protected method.
local function raise(e)
  if e.locked then return end   -- Raise() reorders within strata; skip protected frames in combat
  if e.frame.Raise then e.frame:Raise() end
end

-- Reflow: decide which managed frames may coexist (close the rest), then tile the survivors.
-- Mirrors retail's ShowUIPanel intent: an exclusive (center) frame can't share the screen, and
-- non-exclusive frames tile left→right by pushable. The NEWEST-shown frame is the one that "wins"
-- a conflict (you just opened it), matching retail's open-replaces-incompatible behaviour.
function M.Reflow()
  if M._reflowing then return end                     -- re-entrancy: our own Hide() fires OnHide → Reflow
  M._reflowing = true

  -- Combat: tile the NON-protected frames now (their SetPoint/Hide is legal) AROUND any shown
  -- PROTECTED frame, which stays put (can't move it) but still reserves its slot in the math (see
  -- gatherShown's `locked` tag + the per-frame guards). A full pass at PLAYER_REGEN_ENABLED then
  -- positions the protected frames once lockdown lifts. This replaced the old all-or-nothing combat
  -- bail that made every panel stack whenever a single protected frame (e.g. Talents) was open.
  -- NOTE: a protected frame OPENED in combat can't be positioned at all until regen — it sits at its
  -- build anchor and may overlap; that's an irreducible WoW restriction (no taint-free workaround).
  M._deferred = nil
  if inCombat() then
    for frame, meta in pairs(M._reg) do
      if frame:IsShown() and not (meta.skip and meta.skip()) and frameLocked(frame, meta) then
        M._deferred = true; break
      end
    end
  end

  local shown = gatherShown()
  if #shown == 0 then M._reflowing = false; return end

  -- The dominant frame = most recently shown.
  local dominant = shown[1]
  for _, e in ipairs(shown) do
    if (e.meta._seq or 0) > (dominant.meta._seq or 0) then dominant = e end
  end

  if isExclusive(dominant.meta.area) then
    -- Pure "center" (HelpFrame): it owns the screen. Close every other managed panel, centre it.
    for _, e in ipairs(shown) do if e ~= dominant then closePanel(e) end end
    applyCheckFit(dominant)
    if not dominant.locked then
      dominant.frame:ClearAllPoints()
      -- Anchor offsets are in the FRAME's scaled units; retail divides the UIParent-space Y by
      -- the frame's scale (UIParentPanelManager.lua:655 — centerXOffset deliberately NOT divided).
      dominant.frame:SetPoint("TOP", _G.UIParent, "TOP",
        dominant.meta.centerXOffset or 0,
        (((dominant.meta.yoffset or 0) + TOP_OFFSET) / (dominant.frame:GetScale() or 1)))
      raise(dominant)
    end
    M._reflowing = false
    return
  end

  -- Dominant is non-exclusive: close any exclusive panels (they can't coexist), then tile the rest.
  for _, e in ipairs(shown) do
    if e ~= dominant and isExclusive(e.meta.area) then closePanel(e) end
  end

  -- Re-gather survivors (some may have just been hidden).
  local tile = {}
  for _, e in ipairs(gatherShown()) do
    if not isExclusive(e.meta.area) then tile[#tile + 1] = e end
  end

  -- Replace rule (retail): two pushable-0 frames can't coexist — keep only the newest, close the
  -- older ones. pushable>0 frames all tile. (e.g. opening Mail over Merchant closes Merchant.)
  local newestZero
  for _, e in ipairs(tile) do
    if (e.meta.pushable or 0) == 0
       and (not newestZero or (e.meta._seq or 0) > (newestZero.meta._seq or 0)) then
      newestZero = e
    end
  end
  if newestZero then
    local closedAny = false
    for _, e in ipairs(tile) do
      if (e.meta.pushable or 0) == 0 and e ~= newestZero then closePanel(e); closedAny = true end
    end
    if closedAny then
      tile = {}
      for _, e in ipairs(gatherShown()) do
        if not isExclusive(e.meta.area) then tile[#tile + 1] = e end
      end
    end
  end

  -- Auto-minimize flagged frames BEFORE measuring widths (retail evaluates EvaluateAutoMinimize per
  -- panel in UpdateUIPanelPositions). otherOpen = there's more than just this frame in the row.
  local otherOpen = #tile > 1
  for _, e in ipairs(tile) do evalAutoMinimize(e, otherOpen) end

  -- checkFit (retail UIParentPanelManager.lua:582-584): scale flagged frames to fit the
  -- screen BEFORE measuring the row — a shrunken frame consumes less tile width.
  for _, e in ipairs(tile) do applyCheckFit(e) end

  -- Row fit (retail GetMaxUIPanelsWidth + CanShowUIPanels, :331-339/:929/:968-990): a
  -- side-by-side arrangement may not cross UIParent's right edge minus the buffer; retail
  -- REPLACES (closes) panels rather than letting one hang off-screen. Our reflow equivalent:
  -- the newest-shown frame always survives; close the oldest others until the row fits.
  if #tile > 1 then
    local maxW = _G.UIParent:GetWidth() - RIGHT_OFFSET_BUFFER
    local function rowRightEdge()
      local x = LEFT_OFFSET
      for _, e in ipairs(tile) do
        x = x + (e.meta.xoffset or 0) + widthOf(e.frame, e.meta) + SPACING
      end
      return x - SPACING   -- right edge of the last frame (no trailing gap)
    end
    local newest = tile[1]
    for _, e in ipairs(tile) do
      if (e.meta._seq or 0) > (newest.meta._seq or 0) then newest = e end
    end
    while #tile > 1 and rowRightEdge() > maxW do
      local victim
      for _, e in ipairs(tile) do
        -- Skip locked frames as victims: closePanel can't actually Hide them in combat, so
        -- evicting one would leave it shown yet un-reserved. Close the oldest NON-locked instead.
        if e ~= newest and not e.locked and (not victim or (e.meta._seq or 0) < (victim.meta._seq or 0)) then
          victim = e
        end
      end
      if not victim then break end
      closePanel(victim)   -- no-op if victim is locked, but we still drop it from the row below
      for i, e in ipairs(tile) do
        if e == victim then table.remove(tile, i); break end
      end
    end
  end

  -- centerOrLeft, retail-literal (UIParentPanelManager.lua:635-637): when it's the ONLY open
  -- panel it positions as a native CENTER frame ("TOP" of UIParent; xoffset ignored,
  -- centerXOffset honored — :652-655); with anything else open it tiles as a left-area frame.
  if #tile == 1 and isCenterish(tile[1].meta.area) then
    local e = tile[1]
    if not e.locked then   -- protected centerOrLeft (Talents) in combat: leave it at its build anchor
      e.frame:ClearAllPoints()
      -- Y divided by frame scale (retail :655); centerXOffset deliberately not divided.
      e.frame:SetPoint("TOP", _G.UIParent, "TOP",
        e.meta.centerXOffset or 0,
        (((e.meta.yoffset or 0) + TOP_OFFSET) / (e.frame:GetScale() or 1)))
      raise(e)
    end
    M._reflowing = false
    return
  end

  -- Tile left→right by pushable.
  table.sort(tile, function(a, b)
    local pa, pb = a.meta.pushable or 0, b.meta.pushable or 0
    if pa ~= pb then return pa < pb end
    return (a.meta._seq or 0) < (b.meta._seq or 0)   -- ties: oldest = leftmost
  end)

  local x = LEFT_OFFSET
  for _, e in ipairs(tile) do
    local xo = e.meta.xoffset or 0
    -- Position non-locked frames; a locked (protected-in-combat) frame keeps its current position
    -- but STILL advances x below, so the others tile around its reserved slot instead of over it.
    if not e.locked then
      -- x walks in UIPARENT space; anchor offsets are in the frame's scaled units, so divide
      -- by the frame's scale exactly like retail (UIParentPanelManager.lua:603). No-op for
      -- scale-1 natives; corrects drift on our pixel-pinned (scale ≠ 1) windows.
      local s = (e.frame.GetScale and e.frame:GetScale()) or 1
      e.frame:ClearAllPoints()
      e.frame:SetPoint("TOPLEFT", _G.UIParent, "TOPLEFT",
        (x + xo) / s, ((e.meta.yoffset or 0) + TOP_OFFSET) / s)
      raise(e)
    end
    -- Advance includes xoffset (retail GetUIPanelWidth: next base = base + (declared|GetWidth)*scale
    -- + xOff). NO doublewide floor — retail reserves the frame's real width (UIParentPanelManager.lua
    -- :898-915), so the next panel tiles against the doublewide's actual edge, not a phantom 2×default.
    x = x + xo + widthOf(e.frame, e.meta) + SPACING
  end

  M._reflowing = false
end

-- Auto-register any DEFAULTS frame that already exists. Frames built at login are caught here;
-- lazily-built frames (e.g. AuctionHouse) also call M.Register themselves on creation; LoD natives
-- (Inspect, Macro) are caught by the ADDON_LOADED scan below. (Register guards double-adds.)
function M.ScanRegister()
  for name in pairs(M.DEFAULTS) do
    local f = _G[name]
    if f and not M._reg[f] then M.Register(f) end
  end
end

local boot = CreateFrame("Frame")
boot:RegisterEvent("PLAYER_LOGIN")
boot:RegisterEvent("PLAYER_ENTERING_WORLD")
boot:RegisterEvent("PLAYER_REGEN_ENABLED")
boot:RegisterEvent("ADDON_LOADED")   -- catch LoD natives (Blizzard_InspectUI, Blizzard_MacroUI, …)
boot:SetScript("OnEvent", function(_, ev)
  if ev == "PLAYER_REGEN_ENABLED" then
    if M._deferred then M.Reflow() end
  else
    M.ScanRegister()
    if C_Timer and C_Timer.After and ev ~= "ADDON_LOADED" then
      C_Timer.After(2, M.ScanRegister)
      C_Timer.After(5, M.ScanRegister)
    end
  end
end)

-- Re-assert our layout after Era's native panel manager runs. Era's FramePositionDelegate re-pins
-- its tracked UIPanels (the natives above) on EVERY UpdateUIPanelPositions — and that fires on
-- triggers we don't drive (a panel's content finishing load, a tab swap, UI-scale changes). When
-- that happens Era yanks a native back to its own slot and it overlaps our row. A coalesced
-- ScheduleReflow after Era re-tiles ours on top. Safe: Reflow only SetPoints (never writes a
-- UIParent attribute or calls HideUIPanel), so it can't re-trigger Era → no loop.
if hooksecurefunc and type(_G.UpdateUIPanelPositions) == "function" then
  hooksecurefunc("UpdateUIPanelPositions", function() M.ScheduleReflow() end)
end
