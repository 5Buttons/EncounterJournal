-- Addon/Core/Modules.lua — central module registry + reload-gated boot dispatcher.
--
-- Loaded immediately after Core/Core.lua so EJ.modules.Register exists at the parse
-- time of every later file (modules call Register at file scope, the same place they
-- used to write `local boot = CreateFrame("Frame")`).
--
-- THE RELOAD-GATED CONTRACT
-- A module is "enabled" or "disabled" via a SavedVariable flag (EJ.db.modules.enabled).
-- Disabling is reload-gated: SetEnabled only writes SV — it never tears down a live
-- module. On the NEXT /reload, the dispatcher reads the flags at ADDON_LOADED and only
-- wires up the events of ENABLED modules; a disabled module's onBoot is simply never
-- invoked, so it never builds its frame and never suppresses its Era counterpart — the
-- native Blizzard frame is left untouched/visible. "Disabled" == "absence of boot",
-- not teardown. The options page surfaces a "/reload to apply" prompt.
--
-- WHY ADDON_LOADED, not file scope: EJ.db (and its migrations) only exist after
-- ADDON_LOADED(NewEra). We register at file scope (synchronous, before any event
-- fires) but DECIDE what boots at ADDON_LOADED, when the SV flags are readable.

local EJ = EJ
EJ.modules = EJ.modules or {}
local Mods = EJ.modules

Mods.registry = Mods.registry or {}   -- name -> opts
Mods.order    = Mods.order    or {}   -- registration order (deterministic boot order)
Mods.booted   = Mods.booted   or {}   -- name -> true once this session actually wired up

-- Enable state. SAFE before EJ.db exists (falls back to the module's registered default).
function Mods.IsEnabled(name)
  local opts = Mods.registry[name]
  local default = not (opts and opts.default == false)   -- default true unless opts.default==false
  if not (EJ.db and EJ.db.modules and EJ.db.modules.enabled) then return default end
  local v = EJ.db.modules.enabled[name]
  if v == nil then return default end
  return v and true or false
end

-- Write the flag only. Reload-gated: does NOT boot or tear down anything live.
function Mods.SetEnabled(name, on)
  if not (EJ.db) then return end
  EJ.db.modules = EJ.db.modules or {}
  EJ.db.modules.enabled = EJ.db.modules.enabled or {}
  EJ.db.modules.enabled[name] = on and true or false
  -- A change only matters after /reload (a booted module can't be un-booted live; a
  -- non-booted module can't be built live without re-running its whole boot path).
  local booted = Mods.booted[name] and true or false
  Mods.reloadPending = (booted ~= (on and true or false)) or Mods.reloadPending
  if Mods.onReloadPending then pcall(Mods.onReloadPending) end
end

-- Why a module isn't booting this session despite being enabled (a disabled dependency).
-- name -> depName. Consumed by the options page (grey-out).
Mods.blockedBy = Mods.blockedBy or {}

-- Why a module isn't booting despite being enabled: a required EXTERNAL addon (BigWigs,
-- Questie, ...) isn't installed. name -> addon label. Like blockedBy this is a TRANSIENT,
-- session-only block — we deliberately never write the SV enable flag, so installing the
-- addon and reloading boots the module automatically (no manual re-enable). The options
-- page reads this to ghost (disable) the row. See requiresAddOn in Register.
Mods.missingAddOn = Mods.missingAddOn or {}

-- True if the module's external-addon requirement is satisfied (or it declares none). The
-- single source of truth for shouldBoot AND the options ghost AND the dependency popup, so
-- they never disagree. requiresAddOn = { label = "BigWigs", present = function() ... end }.
function Mods.AddOnSatisfied(name)
  local opts = Mods.registry[name]
  local dep = opts and opts.requiresAddOn
  if not dep or type(dep.present) ~= "function" then return true end
  local ok, present = pcall(dep.present)
  return (ok and present) and true or false
end

-- Rival-addon yield ("play ball"). The INVERSE of requiresAddOn: a module that replaces a
-- whole UI surface (bags, nameplates, auction house) stands down when the user runs a
-- dedicated third-party addon for that surface — they installed it deliberately, so it
-- wins by default. Like missingAddOn this is a TRANSIENT, session-only block: we never
-- write the SV enable flag, so uninstalling the rival re-boots our module on the next
-- load automatically, while a real manual disable (SV flag) is always respected. The
-- user can force both to run via the per-module override (the module's options checkbox
-- drives SetConflictOverride while a rival is present — see Options.lua).
-- Detection = C_AddOns.IsAddOnLoaded (era-verified, Deprecated_1_15_0.lua:13) at boot-
-- event time; a conflict-gated module must not boot before PLAYER_LOGIN (earlier, rival
-- addons may not have finished loading). Declare via `conflictsWith = Mods.RIVALS.<KEY>`.
Mods.RIVALS = {
  BAGS       = { "Bagnon", "Bagshui", "ArkInventory", "AdiBags", "Baganator",
                 "Combuctor", "OneBag3", "tdBag2", "Sorted" },
  NAMEPLATES = { "Plater", "TidyPlates_ThreatPlates", "TidyPlates", "NeatPlates",
                 "Kui_Nameplates", "BetterBlizzPlates" },
  AUCTION    = { "Auctionator", "TradeSkillMaster", "aux-addon", "Auc-Advanced",
                 "AuctionLite" },
  ACTIONBARS = { "Bartender4", "Dominos" },
  CHAT       = { "Prat-3.0", "Chattynator" },
  TOOLTIP    = { "TipTac" },
}

Mods.conflictCache = Mods.conflictCache or {}   -- name -> rival folder | false (= none)

-- First loaded rival addon for this module, or nil. Cached after the first evaluation
-- (the loaded-addon set can't change mid-session; none of the rivals are load-on-demand).
-- Ignores the override — callers combine with ConflictOverride.
function Mods.ConflictedBy(name)
  local cached = Mods.conflictCache[name]
  if cached ~= nil then return cached or nil end
  local opts = Mods.registry[name]
  local rivals = opts and opts.conflictsWith
  local found = false
  if rivals then
    for _, addon in ipairs(rivals) do
      if EJ.IsAddOnLoaded(addon) then found = addon; break end
    end
  end
  Mods.conflictCache[name] = found
  return found or nil
end

function Mods.ConflictOverride(name)
  local t = EJ.db and EJ.db.modules and EJ.db.modules.conflictOverride
  return (t and t[name]) and true or false
end

function Mods.SetConflictOverride(name, on)
  if not EJ.db then return end
  EJ.db.modules = EJ.db.modules or {}
  EJ.db.modules.conflictOverride = EJ.db.modules.conflictOverride or {}
  EJ.db.modules.conflictOverride[name] = on and true or nil
  Mods.reloadPending = true
  if Mods.onReloadPending then pcall(Mods.onReloadPending) end
end

-- Will this module actually run this session, ignoring inter-module `requires`? The SV
-- flag PLUS both transient gates (missing companion addon, rival-addon yield). Use this —
-- not IsEnabled — wherever "is the replacement actually live" matters (Suppress owner
-- tags, requires-chains): IsEnabled alone misses the transient blocks, so e.g. Suppress
-- would keep hiding native bars while ActionBar1 stands down for Bartender. Unregistered
-- modules return true (same forward-compat default as IsEnabled).
function Mods.EffectivelyEnabled(name)
  if not Mods.IsEnabled(name) then return false end
  local opts = Mods.registry[name]
  if opts and opts.requiresAddOn and not Mods.AddOnSatisfied(name) then return false end
  if opts and opts.conflictsWith and not Mods.ConflictOverride(name) and Mods.ConflictedBy(name) then
    return false
  end
  return true
end

-- Dispatcher. One shared event frame. Events are subscribed EAGERLY as modules Register
-- (at file-parse time) — see the ORDERING note in Register below. Each event fans out to
-- the modules that asked for it, gated by shouldBoot (enabled + dependencies satisfied),
-- each call wrapped in pcall (Hard Rule #12 — one module's build error must not abort the
-- rest, which could leave a later unit frame blank).
local dispatcher = CreateFrame("Frame")
local wanted = {}          -- event -> { name, ... }

-- Subscribe to the universal lifecycle events at THIS file's load — the earliest possible
-- point (Core/Modules.lua is near the top of the TOC, before every frame module AND every
-- EditModeRegister / sub-component file). This GUARANTEES the dispatcher receives
-- PLAYER_LOGIN / PLAYER_ENTERING_WORLD before any parse-time boot in a later file, so a
-- module's onBoot (which builds the frame) always runs before the sibling boots that
-- consume that frame — independent of which module happens to Register first. Other events
-- (scale changes, ADDON_LOADED, custom) are added per-module in Register().
dispatcher:RegisterEvent("PLAYER_LOGIN")
dispatcher:RegisterEvent("PLAYER_ENTERING_WORLD")

local function shouldBoot(name)
  if not Mods.IsEnabled(name) then return false end
  local opts = Mods.registry[name]
  if opts and opts.requires then
    for _, dep in ipairs(opts.requires) do
      -- EffectivelyEnabled, not IsEnabled: a dep standing down for a rival addon
      -- (conflictsWith) must block its dependents too, even though its SV flag is on.
      if not Mods.EffectivelyEnabled(dep) then
        -- Degrade, don't error (e.g. MultiBars needs ActionBar1's spellfx namespace).
        if Mods.blockedBy[name] ~= dep and EJ.Log then
          EJ.Log("MODULES", name.." skipped: requires "..dep.." (disabled)")
        end
        Mods.blockedBy[name] = dep
        return false
      end
    end
  end
  -- External-addon requirement (e.g. BigWigs). Transient block — never persisted; auto-clears
  -- when the addon is present on a later reload. Recorded SILENTLY: a missing companion addon
  -- is an EXPECTED, user-handled state surfaced by the clean popup (Core/Dependencies.lua), so
  -- we must NOT EJ.Log it — EJ.Log pops the debug window (Debug.lua Flush), which is exactly
  -- the console-style warning we're replacing with the popup.
  if opts and opts.requiresAddOn and not Mods.AddOnSatisfied(name) then
    Mods.missingAddOn[name] = opts.requiresAddOn.label or "(addon)"
    return false
  end
  -- Rival-addon yield (see RIVALS above). Transient like missingAddOn — never persisted —
  -- and silent for the same reason: an installed rival is an EXPECTED, user-chosen state,
  -- announced by the Dependencies.lua login chat line, not the debug window.
  if opts and opts.conflictsWith and not Mods.ConflictOverride(name) and Mods.ConflictedBy(name) then
    return false
  end
  return true
end

dispatcher:SetScript("OnEvent", function(_, event, arg1, ...)
  local list = wanted[event]
  if not list then return end
  for _, name in ipairs(list) do
    local opts = Mods.registry[name]
    if opts and opts.onBoot and shouldBoot(name) then
      Mods.booted[name] = true
      local ok, err = pcall(opts.onBoot, event, arg1, ...)
      if not ok and EJ.Log then EJ.Log("MODULES", "onBoot error in "..name..": "..tostring(err)) end
      -- Family sub-boots (Mods.OnBoot): run right after the family's own onBoot, in
      -- attach order, each pcall-isolated like onBoot itself. `every` entries fire on
      -- every family boot fire (with the event args); one-shot entries fire once.
      local subs = Mods.subBoots[name]
      if subs then
        for _, e in ipairs(subs) do
          if e.every or not e.ran then
            e.ran = true
            local ok2, err2 = pcall(e.fn, event, arg1, ...)
            if not ok2 and EJ.Log then EJ.Log("MODULES", "sub-boot error in "..name..": "..tostring(err2)) end
          end
        end
      end
    end
  end
end)

-- Family sub-boots. A frame family registers ONE module (one enable flag), but spans many
-- files — each used to hand-roll its own PLAYER_LOGIN boot frame and (sometimes) forget
-- the IsBooted self-gate. OnBoot(family, fn, opts) attaches fn to the family's boot
-- instead: fn(event, ...) runs right after the family's onBoot (frame built), in attach
-- (= TOC parse) order, and ONLY when the family actually boots — disable-gating by
-- construction. Default = one-shot (first boot fire). opts.everyFire = true → fn runs on
-- EVERY fire of the family's registered events, receiving (event, arg1, ...) like onBoot —
-- for sub-components that re-assert on ADDON_LOADED etc. If the family already booted this
-- session, fn runs immediately (no event args).
-- FOOTGUN: for a family registering ADDON_LOADED, the FIRST boot fire is
-- ADDON_LOADED("NewEra") — BEFORE PLAYER_LOGIN. A sub-boot that must wait for login needs
-- everyFire + `if event ~= "PLAYER_LOGIN" then return end`, not the one-shot default.
Mods.subBoots = Mods.subBoots or {}   -- family -> { {fn=, every=, ran=}, ... }
function Mods.OnBoot(family, fn, opts)
  local entry = { fn = fn, every = (opts and opts.everyFire) and true or false }
  if Mods.booted[family] then
    entry.ran = true
    local ok, err = pcall(fn)
    if not ok and EJ.Log then EJ.Log("MODULES", "sub-boot error in "..family..": "..tostring(err)) end
    if not entry.every then return end
  end
  local list = Mods.subBoots[family]
  if not list then list = {}; Mods.subBoots[family] = list end
  list[#list + 1] = entry
end

function Mods.Register(name, opts)
  if Mods.registry[name] then
    if EJ.Log then EJ.Log("MODULES", "duplicate module registration: "..tostring(name)) end
    return
  end
  opts = opts or {}
  Mods.registry[name] = opts
  Mods.order[#Mods.order + 1] = name
  -- Subscribe the dispatcher to this module's events EAGERLY (now, at file-parse time).
  -- ORDERING (load-bearing): the dispatcher must be registered for PLAYER_LOGIN no later
  -- than the hand-rolled boots in sibling files (EditModeRegister.lua, sub-components).
  -- The FIRST Register call (Suppress, early in the TOC) subscribes the dispatcher to
  -- PLAYER_LOGIN, so its handler fires BEFORE those later-parsed boots — every module's
  -- onBoot (which builds the frame) runs before any EditModeRegister tries to register
  -- that frame with Edit Mode. (Subscribing at ADDON_LOADED instead fired the dispatcher
  -- AFTER the parse-time EditMode boots → they saw a nil frame, skipped registration, and
  -- the frame rendered unscaled/oversized — the "quest tracker is huge" bug.)
  local evs = opts.events or (opts.event and { opts.event }) or nil
  if evs and opts.onBoot then
    for _, ev in ipairs(evs) do
      wanted[ev] = wanted[ev] or {}
      wanted[ev][#wanted[ev] + 1] = name
      dispatcher:RegisterEvent(ev)
    end
  end
end

-- Metadata accessors for the options page.
function Mods.GetAll() return Mods.order, Mods.registry end
function Mods.Get(name) return Mods.registry[name] end
function Mods.IsBooted(name) return Mods.booted[name] and true or false end
