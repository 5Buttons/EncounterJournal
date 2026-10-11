-- Addon/Core/FrameUtil.lua — shared frame utilities. The canonical pixel-perfect pin.
--
-- ONE PinPixelPerfect for the whole addon. Pins a frame to the 768/physicalHeight pixel
-- scale (same crispness as every other UI frame, and the DragonflightUI-bug-proof way to
-- size — we pin EFFECTIVE scale, never a raw SetScale guess). `userScale` is the per-frame
-- Edit Mode multiplier (default 1.0). Because we divide by the parent's effective scale,
-- the frame lands at an effective scale of (768/physH)*userScale regardless of where it's
-- parented.
--
-- Everything binds through this: EJ.panelchrome.PinPixelPerfect is a thin alias, and per-frame
-- modules call it directly instead of hand-rolling their own copy. Loaded right after
-- Core/Modules.lua (needs only the WoW API) so it exists before PanelChrome and every frame module.

local EJ = EJ
EJ.FrameUtil = EJ.FrameUtil or {}

-- THE shared "do it when combat ends" deferral. Runs fn immediately when not in
-- lockdown; otherwise queues it for the next PLAYER_REGEN_ENABLED (one shared watcher
-- frame for the whole addon — modules don't hand-roll their own). Jobs run in queue
-- order. NOTE: this is for PROTECTED-call deferral (InCombatLockdown); combat
-- *visibility* logic must use UnitAffectingCombat instead (see PATTERNS.md).
local regenJobs, regenWatcher
function EJ.FrameUtil.AfterCombat(fn)
  if not (InCombatLockdown and InCombatLockdown()) then
    fn()
    return
  end
  regenJobs = regenJobs or {}
  regenJobs[#regenJobs + 1] = fn
  if not regenWatcher then
    regenWatcher = CreateFrame("Frame")
    regenWatcher:RegisterEvent("PLAYER_REGEN_ENABLED")
    regenWatcher:SetScript("OnEvent", function()
      local jobs = regenJobs
      regenJobs = nil
      if jobs then
        for _, job in ipairs(jobs) do job() end
      end
    end)
  end
end

-- SetScale on a PROTECTED frame (one that parents secure children — EJ_TalentFrame,
-- EJ_ProfessionsFrame) raises in combat, e.g. when an OnShow re-pin runs while the secure
-- key toggle opens the window mid-combat. Defer those pins to PLAYER_REGEN_ENABLED; the
-- frame keeps its current (already-pinned-at-build) scale until then. Pins coalesce by
-- frame (only the last requested userScale applies).
local deferredPins
local function flushDeferredPins()
  local pins = deferredPins
  deferredPins = nil
  if not pins then return end
  for frame, userScale in pairs(pins) do
    EJ.FrameUtil.PinPixelPerfect(frame, userScale)
  end
end

-- The canonical pixel base: (768/physicalHeight) × the automatic integer multiplier —
-- or NIL when the user ticked Blizzard's UI Scale (useUiScale CVar; owner rule: their
-- scale rules then). Modules that must SetScale by hand (nameplates' sanctioned
-- exception, menus, tooltip) read THIS instead of computing 768/physH themselves, so
-- the 4K multiplier + the opt-out apply addon-wide from one seam.
function EJ.FrameUtil.PixelBaseScale()
  if GetCVarBool and GetCVarBool("useUiScale") then return nil end
  local _, ph = EJ.PhysicalScreenSize()
  if not ph or ph <= 0 then return nil end
  return (768 / ph) * math.max(1, math.floor(ph / 1080 + 0.5))
end

-- Registry of every pinned frame → its last userScale, so a UI-scale / resolution change
-- re-pins ALL of them live (TRACKER #28). Previously only ~28 modules listened for
-- UI_SCALE_CHANGED and the rest "settled on /reload" — so toggling Blizzard's UI Scale left
-- the unlistening frames at a stale scale (minimap huge, frames drifting, mixed sizes). One
-- central watcher closes that: a frame is registered the first time it's pinned and re-pinned
-- on every scale change. Modules that ALSO listen (and re-layout) keep their handlers; this
-- only adds coverage for the ones that didn't.
local pinnedFrames = setmetatable({}, { __mode = "k" })   -- weak keys: don't keep dead frames alive

function EJ.FrameUtil.PinPixelPerfect(frame, userScale)
  if not frame then return end
  pinnedFrames[frame] = userScale or 1.0
  if InCombatLockdown and InCombatLockdown() and frame.IsProtected and frame:IsProtected() then
    local schedule = deferredPins == nil
    deferredPins = deferredPins or {}
    deferredPins[frame] = userScale or 1.0
    if schedule then EJ.FrameUtil.AfterCombat(flushDeferredPins) end
    return
  end
  -- Owner rule 2026-06-12: when the user OPTS INTO Blizzard's UI Scale (the "UI Scale"
  -- checkbox in System→Graphics → useUiScale CVar), honor their chosen scale instead of
  -- pinning. The pin forces 768/physicalHeight — on a 4K monitor that's ~0.36, which
  -- made every EJ frame tiny relative to the Blizzard frames the user had scaled up
  -- (4K tester report). With useUiScale on, frames inherit UIParent's user-chosen scale
  -- and userScale stays the per-frame multiplier. Toggling the checkbox fires
  -- UI_SCALE_CHANGED (modules that listen re-pin live; the rest settle on /reload).
  if GetCVarBool and GetCVarBool("useUiScale") then
    frame:SetScale(userScale or 1.0)
    return
  end
  local _, ph = EJ.PhysicalScreenSize()
  if not ph or ph <= 0 then return end
  -- Automatic INTEGER pixel multiplier (owner 2026-06-12): crispness needs each art
  -- pixel to map to a WHOLE number of screen pixels, not 1:1 specifically. m=1 at
  -- 1080p/1440p (today's look), m=2 at 4K (perfect 2×2 blocks — same apparent size as
  -- 1080p, zero smear; was 1:1 = half-size, the 4K tester report), m=4 at 8K. 1440p has
  -- no clean integer (1.875×) so it stays 1×.
  local m = math.max(1, math.floor(ph / 1080 + 0.5))
  local target = (768 / ph) * m * (userScale or 1.0)
  local parent = frame:GetParent() or UIParent
  local parentScale = parent:GetEffectiveScale()
  if parentScale and parentScale > 0 then
    frame:SetScale(target / parentScale)
  end
end

-- Central re-pin: when the user changes UI scale / resolution (incl. toggling the useUiScale
-- opt-out), re-pin every registered frame so none is left at a stale scale (TRACKER #28).
local function repinAllFrames()
  for frame, us in pairs(pinnedFrames) do
    if frame.GetObjectType then EJ.FrameUtil.PinPixelPerfect(frame, us) end
  end
end

-- Re-pin DEFERRED one frame, coalesced. Two reasons, both probe-confirmed (2026-06-13):
-- (1) at scale-event time the relevant CVar can still read its PRE-commit value (the probe saw
--     GetCVarBool("useUiScale")==0 fire DURING the enable Apply), so a synchronous re-pin reads
--     stale state; next frame it has committed. (2) a burst of events collapses to one re-pin.
local repinPending
local function scheduleRepin()
  if repinPending then return end
  repinPending = true
  local function run() repinPending = nil; repinAllFrames() end
  if EJ.After then EJ.After(0, run) else run() end
end

-- WHY a second seam beyond the scale events (probe-confirmed 2026-06-13): UI_SCALE_CHANGED /
-- DISPLAY_SIZE_CHANGED fire only when UIParent's *scale* actually changes. But our pin DECISION
-- flips on the `useUiScale` CVar (pixel-pin 768/physH vs inherit UIParent), and toggling that
-- checkbox leaves UIParent's scale UNCHANGED whenever `uiScale` already equals the no-scale value
-- (the tester's uiScale=0.9). So un-ticking "UI Scale" to return to OUR scaling fired NO scale
-- event at all — every EJ frame stayed at Blizzard's scale until /reload. CVAR_UPDATE catches that
-- flip. We compare CVar VALUES against a cache (not the event's arg1: that token is an inconsistent
-- uppercase alias for some cvars, e.g. era's ArenaUI "SHOW_ARENA_ENEMY_FRAMES_TEXT").
local lastUseUi   = GetCVarBool and GetCVarBool("useUiScale")
local lastUiScale = GetCVar and GetCVar("uiScale")

local pinScaleWatcher = CreateFrame("Frame")
pinScaleWatcher:RegisterEvent("UI_SCALE_CHANGED")
pinScaleWatcher:RegisterEvent("DISPLAY_SIZE_CHANGED")
pinScaleWatcher:RegisterEvent("CVAR_UPDATE")
pinScaleWatcher:SetScript("OnEvent", function(_, event)
  if event == "CVAR_UPDATE" then
    -- Defer the value read+compare: the CVar may not have committed yet at event time, and
    -- this filters out the (frequent) CVAR_UPDATEs for cvars we don't care about.
    local function check()
      local u = GetCVarBool and GetCVarBool("useUiScale")
      local s = GetCVar and GetCVar("uiScale")
      if u ~= lastUseUi or s ~= lastUiScale then
        lastUseUi, lastUiScale = u, s
        repinAllFrames()
      end
    end
    if EJ.After then EJ.After(0, check) else check() end
    return
  end
  -- UI_SCALE_CHANGED / DISPLAY_SIZE_CHANGED: keep the cache fresh and re-pin (deferred).
  lastUseUi   = GetCVarBool and GetCVarBool("useUiScale")
  lastUiScale = GetCVar and GetCVar("uiScale")
  scheduleRepin()
end)

-- F6 was REVERTED. The pixel-pin is SURGICAL — it sizes ONLY EJ's own frames and deliberately leaves
-- Blizzard's UIParent (and everything that inherits it: context menus, the unit right-click popup, the
-- crafting filter dropdown, …) at the user's OWN scale. Switching to the global uiScale dragged all
-- those Blizzard menus up to EJ's scale ("much too large"), which the pin had been avoiding — the two
-- mechanisms do different things, so the pin can't be replaced by a global scale. The pin stays.
-- Undo the one-time native-scale migration for anyone who already got it: turn useUiScale back OFF so
-- the pin's pixel-math runs and Blizzard's UI returns to its own scale. The CVar flip fires CVAR_UPDATE
-- → the watcher above re-pins every EJ frame. Runs once (db.uiScalePushed → nil), out of combat.
local function undoScaleMigration()
  if not (SetCVar and EJ.db and EJ.db.uiScalePushed) then return end
  EJ.db.uiScalePushed = nil
  pcall(SetCVar, "useUiScale", "0")
end

local scaleMigrateFrame = CreateFrame("Frame")
scaleMigrateFrame:RegisterEvent("PLAYER_LOGIN")
scaleMigrateFrame:SetScript("OnEvent", function() undoScaleMigration() end)

-- Money text — the gold/silver/copper coin-icon string for a copper amount (Blizzard's
-- GetCoinTextureString), with a caller-chosen string for nil/zero. Centralizes the `coin()`
-- helper the AuctionHouse panels each copied verbatim. (Frames that show a live wallet use
-- Blizzard's native MoneyFrame/SmallMoneyFrameTemplate — this is just for inline price text.)
-- Font constants + setter. One home for the client font paths modules were inlining
-- ("Fonts\\FRIZQT__.TTF" was scattered across ~8 files). Set() encodes the
-- SetFont-failure fallback (SetFont returns false on a bad path → fall back to a
-- known font object) that the EncounterJournal sites each hand-rolled.
EJ.font = EJ.font or {}
EJ.font.FRIZ     = "Fonts\\FRIZQT__.TTF"
EJ.font.MORPHEUS = "Fonts\\MORPHEUS.ttf"
function EJ.font.Set(fs, path, size, flags, fallbackObject)
  if not fs:SetFont(path, size, flags or "") and fallbackObject then
    fs:SetFontObject(fallbackObject)
  end
end

-- ESC-close registration: add the frame (by global name) to UISpecialFrames, once.
-- ONLY for ordinary windows — a PROTECTED window (one parenting secure children, e.g.
-- EJ_TalentFrame / EJ_ProfessionsFrame) swallows the insecure ESC close in combat and
-- needs the secure close-handler pattern instead (see PATTERNS.md).
function EJ.FrameUtil.EscClose(frame)
  local name = type(frame) == "string" and frame
    or (frame and frame.GetName and frame:GetName())
  if not name then return end
  for _, n in ipairs(UISpecialFrames) do
    if n == name then return end
  end
  tinsert(UISpecialFrames, name)
end

-- Keep a frame on screen after its SIZE changes. SetClampedToScreen clamps on SetPoint /
-- StartMoving but NOT on a bare SetSize, so a frame that grows past an edge (e.g. the bag bar
-- or micro menu switching to a vertical orientation — TRACKER #26) stays off-screen until the
-- next reposition. Re-asserting the current anchor marks it dirty and re-runs the clamp.
function EJ.FrameUtil.KeepOnScreen(frame)
  if not (frame and frame.SetClampedToScreen) then return end
  frame:SetClampedToScreen(true)
  local p1, rel, p2, x, y = frame:GetPoint(1)
  if p1 then frame:SetPoint(p1, rel, p2, x or 0, y or 0) end
end

-- Disable-path fallback for XML-BUILT frames. Most EJ frames only exist when their module
-- boots, so "disabled = absence of boot" hides them for free — but the unit-frame families
-- (Player/Target/Pet) build NE_*Frame from XML at file load, and Target/ToT/Pet register a
-- secure unit watch in their XML OnLoad. Without this, a disabled (or rival-yielding)
-- module's frame still pops. Call once at file scope per family: at PLAYER_LOGIN, if the
-- module did NOT boot, unhook the unit watch and hide each named frame (combat-deferred —
-- these are protected secure unit buttons, and a /reload can land mid-combat). Mirrors the
-- QuestTracker nativeFallback pattern: an always-on watcher that acts only when the module
-- is OFF.
function EJ.FrameUtil.HideWhenModuleOff(moduleName, ...)
  local names = { ... }
  local w = CreateFrame("Frame")
  w:RegisterEvent("PLAYER_LOGIN")
  w:SetScript("OnEvent", function()
    if not EJ.modules or EJ.modules.IsBooted(moduleName) then return end
    EJ.FrameUtil.AfterCombat(function()
      for _, n in ipairs(names) do
        local f = _G[n]
        if f then
          if UnregisterUnitWatch then pcall(UnregisterUnitWatch, f) end
          f:Hide()
        end
      end
    end)
  end)
end

-- Panel open/close sounds. Native UIPanels play their own kit from OnShow/OnHide; our
-- custom NE_ windows miss them entirely (owner report 2026-06-12). Wire via an invisible
-- CHILD frame, never HookScript: the protected windows' (EJ_TalentFrame/EJ_Professions
-- Frame) own script slots are secure-wrapped, and HookScript there broke the secure open
-- (same lesson as Core/PanelManager watch frames). A child's OnShow/OnHide fires with the
-- parent's effective visibility on every open path and never touches its script chain.
-- Each kit may be retail-only sound DATA the Era client lacks (SOUNDKIT constant existing
-- ≠ the kit plays — the FDID≠art lesson's audio twin): PlaySound returns no willPlay
-- then, so fall back to the vanilla-native kit. pcall: unknown kit IDs hard-error.
function EJ.FrameUtil.WirePanelSounds(frame, openKit, closeKit, fallbackOpen, fallbackClose)
  if not frame or frame._ejSoundWatcher then return end
  local function play(kit, fallback)
    if not kit then return end
    local ok, willPlay = pcall(PlaySound, kit)
    if not (ok and willPlay) and fallback then pcall(PlaySound, fallback) end
  end
  local w = CreateFrame("Frame", nil, frame)
  w:SetScript("OnShow", function() play(openKit,  fallbackOpen)  end)
  w:SetScript("OnHide", function() play(closeKit, fallbackClose) end)
  frame._ejSoundWatcher = w
end

EJ.money = EJ.money or {}
function EJ.money.Text(copper, empty)
  if copper and copper > 0 then
    return (GetCoinTextureString and GetCoinTextureString(copper)) or tostring(copper)
  end
  return empty or "—"
end

-- Tab helpers. EJ.tabs.ResizeTabMinimum sizes a CharacterFrameTabButtonTemplate tab to
-- max(70, textWidth + 24) — a 70px floor (the vanilla TabResize minimum, era
-- SharedUIPanelTemplates.lua:432) so short labels stay compact, growing wider for long ones with
-- ~12px breathing each side. We avoid PanelTemplates_TabResize because it calls tabText:SetWidth(0)
-- which empirically clears some Era tabs' text. The journal's Dungeons/Raids bottom tabs use this.
-- (Extracted from the former CharacterPanel/TabButtons.lua, the rest of which was a New Era
-- character-window restyle unrelated to the journal and was removed.)
EJ.tabs = EJ.tabs or {}
function EJ.tabs.ResizeTabMinimum(tab)
  if not tab then return end
  local text = _G[tab:GetName() .. "Text"]
  local textW = 0
  if text then
    text:SetWidth(0)  -- ensure auto-size before measuring
    textW = text:GetWidth() or 0
  end
  tab:SetWidth(math.max(70, math.floor(textW + 24)))
end

-- Shared 5-tier difficulty ladder (creature/quest level vs the player). Returns the difficulty KEY
-- ("impossible"/"verydifficult"/"difficult"/"standard"/"trivial") — the threshold logic the target
-- frame's level colour AND the quest-log title colour both carried verbatim. Callers map the key to
-- their OWN colour table (TargetFrame forces retail literals per Law 1; the quest log prefers the
-- live QuestDifficultyColors global) — only the thresholds are shared, not the colour policy.
function EJ.difficultyTier(level)
  local diff = (level or 0) - (UnitLevel("player") or 0)
  if diff >= 5 then return "impossible"
  elseif diff >= 3 then return "verydifficult"
  elseif diff >= -2 then return "difficult"
  elseif GetQuestGreenRange and (-diff) <= (GetQuestGreenRange("player") or 0) then return "standard"
  else return "trivial" end
end

EJ.color = EJ.color or {}
-- "ffrrggbb" hex (floor rounding) for a {r,g,b} colour table (0-1). No "|c" prefix — for manual
-- "|c"..hex.."…".."|r" concatenation. White fallback so the result is never malformed.
function EJ.color.ToHex(color)
  color = color or { r = 1, g = 1, b = 1 }
  return string.format("ff%02x%02x%02x",
    math.floor((color.r or 1) * 255), math.floor((color.g or 1) * 255), math.floor((color.b or 1) * 255))
end
-- Wrap `text` in a class colour code: |cffRRGGBB<text>|r, from RAID_CLASS_COLORS[classFile] (white
-- fallback). The character + inspect level lines built this identically.
function EJ.color.WrapClass(classFile, text)
  local c = (classFile and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFile]) or { r = 1, g = 1, b = 1 }
  return "|c" .. EJ.color.ToHex(c) .. (text or "") .. "|r"
end
-- Class colour as raw r,g,b (0-1). Honours CUSTOM_CLASS_COLORS (the addon-overridable
-- table) when present, falling back to Blizzard's RAID_CLASS_COLORS, then white. Matches
-- the lookup hand-rolled in Guild/Roster, CharacterPanel inspect lines, etc.
function EJ.color.ClassRGB(classFile)
  local pool = CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS
  local c = classFile and pool and pool[classFile]
  if not c then return 1, 1, 1 end
  return c.r, c.g, c.b
end
-- Debuff-type (dispel) colour as raw r,g,b (0-1) from the global DebuffTypeColor table,
-- with the "none" entry as the fallback (matches PartyFrame/Behavior's aura-border tint).
function EJ.color.DispelRGB(dtype)
  local pool = _G.DebuffTypeColor
  local c = pool and (pool[dtype or "none"] or pool.none)
  if not c then return 1, 1, 1 end
  return c.r, c.g, c.b
end

-- Region walking — the "iterate a frame's child regions, act on matching ones" idiom
-- hand-rolled ~35x across the reskin modules (hide a decorative texture by draw layer,
-- find an anonymous FontString by text). One {GetRegions()} capture per call (the
-- CharacterPanel idiom), so callers stop re-rolling the loop.
--
-- ForEachRegion(frame, kind, layer, fn): call fn(region) for each child region whose
-- object type == `kind` (nil = any) and draw layer == `layer` (nil = any). Returns the
-- count visited.
function EJ.FrameUtil.ForEachRegion(frame, kind, layer, fn)
  if not (frame and frame.GetRegions and fn) then return 0 end
  local regions = { frame:GetRegions() }
  local visited = 0
  for i = 1, #regions do
    local r = regions[i]
    if r and (not kind or (r.GetObjectType and r:GetObjectType() == kind))
         and (not layer or (r.GetDrawLayer and (r:GetDrawLayer()) == layer)) then
      fn(r)
      visited = visited + 1
    end
  end
  return visited
end

-- FindRegion(frame, kind, predicate): return the first child region matching `kind`
-- (nil = any) for which predicate(region) is truthy, else nil. For the "find the
-- anonymous texture/FontString by content" lookups.
function EJ.FrameUtil.FindRegion(frame, kind, predicate)
  if not (frame and frame.GetRegions and predicate) then return nil end
  local regions = { frame:GetRegions() }
  for i = 1, #regions do
    local r = regions[i]
    if r and (not kind or (r.GetObjectType and r:GetObjectType() == kind)) and predicate(r) then
      return r
    end
  end
  return nil
end

-- Copyable dump dialog — a movable DIALOG-strata frame holding a selectable multiline
-- EditBox (Ctrl+A / Ctrl+C), generalizing the Debug log window and the per-module dump
-- boxes reinvented across ~6 modules. Era-verified backdrop path (CreateFrame +
-- native SetBackdrop, as Debug.lua uses). Returns the frame; drive it with
-- :ShowText(text) (sets text, shows, selects all) or :SetText(text).
-- STAGED (REFACTOR-PLAN.md Phase 2): not yet adopted; smoke-test before routing the
-- existing copy boxes through it.
function EJ.FrameUtil.CopyBox(opts)
  opts = opts or {}
  local w, h = opts.w or 760, opts.h or 500
  local f = CreateFrame("Frame", opts.name, UIParent)   -- 3.3.5a frames have SetBackdrop natively
  f:SetSize(w, h)
  f:SetPoint("CENTER")
  f:SetFrameStrata("DIALOG")
  f:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    edgeSize = 16, insets = { left = 4, right = 4, top = 4, bottom = 4 },
  })
  f:EnableMouse(true)
  f:SetMovable(true)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", f.StartMoving)
  f:SetScript("OnDragStop", f.StopMovingOrSizing)
  f:Hide()

  local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  title:SetPoint("TOP", 0, -10)
  title:SetText(opts.title or "Copy — Ctrl+A then Ctrl+C")

  local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", -4, -4)

  local scroll = CreateFrame("ScrollFrame", "EJ_FrameUtilCopyScroll", f, "UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT", 12, -34)
  scroll:SetPoint("BOTTOMRIGHT", -30, 38)

  local edit = CreateFrame("EditBox", nil, scroll)
  edit:SetMultiLine(true)
  edit:SetAutoFocus(false)
  edit:SetFontObject(ChatFontNormal)
  edit:SetWidth(w - 50)
  edit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  scroll:SetScrollChild(edit)

  local selectAll = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  selectAll:SetSize(90, 20)
  selectAll:SetPoint("BOTTOMLEFT", 12, 10)
  selectAll:SetText("Select All")
  selectAll:SetScript("OnClick", function() edit:SetFocus(); edit:HighlightText() end)

  f.edit = edit
  function f:SetText(t) edit:SetText(t or "") end
  function f:ShowText(t) edit:SetText(t or ""); self:Show(); edit:SetFocus(); edit:HighlightText() end
  return f
end

-- EJ.IsAddOnLoaded / EJ.IsAddOnInstalled live in Core/Compat.lua.
