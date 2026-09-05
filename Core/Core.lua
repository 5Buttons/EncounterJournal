-- Addon/Core/Core.lua — root namespace, SavedVariables schema, capability flags.
-- Loaded before everything else. Sets up the EJ table so Debug.lua and later modules
-- can attach to it without re-checking.

local addonName, ns = ...
EJ = EJ or {}
EJ.ns = ns
EJ.version = "0.85"

-- Stable per-character key ("<name>-<realm>") for per-character data kept inside the
-- account-wide NewEraDB — the established convention (equipmentSets, talents, achievements,
-- knownFlights, recipeTracker, and now the Edit Mode active-layout selection). Only meaningful
-- after PLAYER_LOGIN (UnitName needs the player object). Modules historically rolled their own
-- local copy of this; this is the shared one for new call sites to adopt.
function EJ.CharKey()
  return (UnitName("player") or "?") .. "-" .. (GetRealmName() or "")
end

-- Fresh-install seed guard (F5). True when a CVar still equals its ENGINE default — i.e. the user has
-- NOT changed it in Blizzard's own options. Boot-time "seed the retail default" writes gate on this so
-- they never clobber a value the user already set (GetCVarDefault is present on Era via
-- C_CVar.GetCVarDefault). If the API/default is unavailable we treat it as fresh (seed proceeds), since
-- the parity default is the intended fallback.
function EJ.CVarAtDefault(cvar)
  if not (GetCVar and GetCVarDefault) then return true end
  local def = GetCVarDefault(cvar)
  if def == nil then return true end
  return tostring(GetCVar(cvar)) == tostring(def)
end

-- SavedVariables schema + migration framework (Hard Rule #7).
-- Bump CURRENT_SCHEMA and add EJ.migrations[N] = function(db) ... end when the saved
-- layout changes. Edit Mode layouts are the crown jewels — never wipe.
local CURRENT_SCHEMA = 15
EJ.migrations = EJ.migrations or {}

EJ.migrations[1] = function(db)
  db.layouts = db.layouts or {}     -- Edit Mode per-frame layouts (per-profile later)
  db.frames  = db.frames  or {}     -- per-frame settings (show text, class color, etc.)
end

EJ.migrations[2] = function(db)
  -- Per-bar "enabled" state — Approach A's global gate (matches retail's
  -- Settings.GetValue("PROXY_SHOW_ACTIONBAR_N") concept but kept in our SV so
  -- we don't have to touch Era's secure binding state). Default = true for
  -- all bars (retail Modern preset has every bar enabled out of the box).
  -- Surfaced via /ne options → ActionBars; not in EditMode.
  db.actionbars         = db.actionbars         or {}
  db.actionbars.enabled = db.actionbars.enabled or {}
end

EJ.migrations[3] = function(db)
  -- Equipment Manager sets. Sets are inherently PER-CHARACTER (different gear
  -- per toon), so they're keyed by "<name>-<realm>" inside the account-wide DB
  -- rather than spinning up a second SavedVariables file. Only used by the
  -- custom (non-native) backend; when C_EquipmentSet is functional the sets
  -- live server-side and this table stays empty. See CharacterPanel/EquipmentSets.lua.
  db.equipmentSets = db.equipmentSets or {}
end

EJ.migrations[4] = function(db)
  -- Talent panel per-character preferences (e.g. a future locked-background
  -- override, last-viewed tab). Keyed by "<name>-<realm>" — talent choices are
  -- inherently per-toon. Currently the panel derives everything live (dominant
  -- spec, etc.), so this starts empty; it's the persistence seam for any opt-in
  -- talent UI settings we add. See Addon/Talents/.
  db.talents = db.talents or {}
end

EJ.migrations[5] = function(db)
  -- Auction House favorites. Era has no C_AuctionHouse favorites API, so this SV table IS the
  -- authoritative store (addon-driven permanently — no server hydrate seam; Classic+ won't ship it).
  -- Account-wide (retail AH favorites are account-wide), keyed by itemId -> true. Toggled by the
  -- star column in the browse list; the Favorites search button queries each starred item.
  db.ahFavorites = db.ahFavorites or {}
end

EJ.migrations[6] = function(db)
  -- Recent Allies (custom reimplementation). Retail's C_RecentAllies is server-dead on Era
  -- (IsSystemSupported() == false — see project_recent_allies_cut), so we capture our OWN roster
  -- from party/raid GROUP_ROSTER_UPDATE into SV — addon-authoritative, no server hydrate seam.
  -- PER-CHARACTER ("who I grouped with on this toon"), keyed "<name>-<realm>" inside the
  -- account-wide DB (same shape as equipmentSets/talents). See Social/RecentAllies.lua.
  db.recentAllies = db.recentAllies or {}
end

EJ.migrations[7] = function(db)
  -- Per-module boot enable flags (the reload-gated module manager — Core/Modules.lua).
  -- The dispatcher reads db.modules.enabled[name] at ADDON_LOADED to decide whether to
  -- invoke each module's onBoot this session. Absent/nil => the module's registered
  -- default (almost always enabled). This is the BOOT axis.
  db.modules = db.modules or {}
  db.modules.enabled = db.modules.enabled or {}

  -- Reconcile the two pre-existing enable systems WITHOUT wiping anything:
  -- (1) NamePlates ships a live per-plate render gate (db.nameplates.Enabled, capital E
  --     — NamePlates/NamePlates.lua). If the user already turned plates OFF, mirror that
  --     into the module flag so the two agree. The legacy flag stays authoritative for
  --     the live render gate; this is just the boot-axis seed.
  if db.nameplates and db.nameplates.Enabled == false then
    db.modules.enabled.NamePlates = false
  end
  -- (2) db.actionbars.enabled is PER-BAR (Bar2..Bar5) — a finer granularity than the
  --     per-module boot flag, and a LIVE visibility toggle (MultiBars/MultiBars.lua).
  --     We deliberately leave it alone; the ActionBar1/MultiBars *modules* stay default-on
  --     at the boot axis, and per-bar visibility remains its own live system.
  -- db.layouts (Edit Mode crown jewels — Hard Rule #8) is never touched here.
end

EJ.migrations[8] = function(db)
  -- Companion-addon dependency notices (Core/Dependencies.lua). Holds only the one-time
  -- "Don't show again" flag for the missing-dependency popup. Additive; never touches
  -- layouts or module enable flags (the addon gate is transient, not persisted).
  db.deps = db.deps or {}
end

EJ.migrations[9] = function(db)
  -- Tracked profession recipes (the recipe objective-tracker section — QuestTracker/
  -- RecipeTracker.lua). PER-CHARACTER ("recipes I'm tracking on this toon"), keyed
  -- "<name>-<realm>" inside the account-wide DB — same shape as recentAllies / equipmentSets.
  -- Each char's value is a map { [recipeSpellID] = snapshot }. Snapshots (recipe name +
  -- reagents{itemID,need}) are PERSISTED because Era's legacy reagent API only reads while
  -- the profession window is open; have-counts are recomputed live via GetItemCount.
  db.recipeTracker = db.recipeTracker or {}
end

EJ.migrations[10] = function(db)
  -- One-time help nudges (Core/HelpPlate.lua + Core/HelpTip.lua). Retail gates its
  -- first-open tutorial pulses behind the closedInfoFrames CVar bitfield; the
  -- LE_FRAME_TUTORIAL_* slots are retail-defined, so on Era the same one-shot flags
  -- live here instead. Account-wide (retail's bitfield is too), keyed by panel
  -- ("worldmap", "editmode", ...) -> true once the nudge has been shown.
  db.helpSeen = db.helpSeen or {}
end

EJ.migrations[11] = function(db)
  -- Achievement engine store (Achievements/Engine.lua). PER-CHARACTER, keyed
  -- "<name>-<realm>" inside the account DB (recipeTracker convention). Holds earned
  -- awards (treat like layouts — never wipe), tracker counters/sets, the kill log,
  -- quest buckets, battleground accumulators and the tracked-achievement list.
  db.achievements = db.achievements or {}
end

EJ.migrations[12] = function(db)
  -- Discovered flight points (the travel router — Quests/TravelGraph.lua). The router used
  -- to assume EVERY flight master was known (it suggested flights the player hadn't learned —
  -- e.g. "fly to Theramore" with no Dustwallow flight path); this is now the authoritative
  -- learned-flight store. PER-CHARACTER (flight discovery is per-toon), keyed "<name>-<realm>"
  -- inside the account DB (recipeTracker convention). Populated when the player opens a flight
  -- master (TAXIMAP_OPENED — the one place Era exposes the true discovered network); each char's
  -- value is a map { [normalizedNodeName] = { name, map, x, y } }. Never wiped.
  db.knownFlights = db.knownFlights or {}
end

EJ.migrations[13] = function(db)
  -- Nameplate Style enum realigned to retail's 0-based Enum.NamePlateStyle (Modern=0..Legacy=5);
  -- was 1-based (Modern=1..Legacy=6). Shift any SAVED selection down one so a stored "Modern" (1)
  -- stays Modern (0), etc. Guarded to the old 1..6 range so it runs exactly once, no-ops on a fresh
  -- install (no stored style), and can never double-apply or go negative.
  local s = db.nameplates and db.nameplates.style
  if type(s) == "number" and s >= 1 and s <= 6 then
    db.nameplates.style = s - 1
  end
end

EJ.migrations[14] = function(db)
  -- Bag bar UI state (BagsBar/BagsBar.lua). Currently just the expand/collapse toggle, which
  -- was previously runtime-only and reset to expanded on every /reload. Retail persists this in
  -- the account-wide CVar `expandBagBar` (Shared/MainMenuBarBagManager.lua:8,28); the CVar's
  -- writability isn't confirmed on the Era client, so we mirror its account-wide scope in our own
  -- SV instead. `expanded` defaults to true (retail's initial state) — left nil here so the
  -- BagsBar read coalesces a fresh install to expanded.
  db.bagsbar = db.bagsbar or {}
end

EJ.migrations[15] = function(db)
  -- UI skin selection (Core/Skin.lua). The journal's chrome is rendered in the "classic"
  -- (original Encounter Journal) look by default; "dragonflight" is a differentiated variant
  -- (currently the plain breadcrumb navbar, art filled in later). Stored as a string so the
  -- skin module can read EJ.db.skin at build time. Default classic = retail-EJ-faithful look.
  db.skin = db.skin or "classic"
end

local function applyMigrations(db)
  db.schema = db.schema or 0
  while db.schema < CURRENT_SCHEMA do
    local step = EJ.migrations[db.schema + 1]
    if not step then break end
    step(db)
    db.schema = db.schema + 1
  end
end

-- Capability flags (Hard Rule #8). One place that probes Era's API surface at load and
-- exposes booleans the rest of the addon reads. Also the Classic Plus hydrate seam: a
-- flag that flips from false to true on a future client lights up dependent frames
-- without scattering `if C_Foo then` across the codebase.
-- Key binding labels for Addon\Bindings.xml (retail binding names — see the XML for
-- why). The settings UI reads BINDING_NAME_<name>; era ships neither string, so
-- define-if-absent (creating globals Era lacks, never overwriting — the
-- MicroButtonAndBagsBar precedent).
BINDING_NAME_TOGGLEACHIEVEMENT = BINDING_NAME_TOGGLEACHIEVEMENT or "Toggle Achievements"
BINDING_NAME_TOGGLEENCOUNTERJOURNAL = BINDING_NAME_TOGGLEENCOUNTERJOURNAL or "Toggle Adventure Guide"
-- Edit Mode has NO retail binding name to borrow (retail exposes Edit Mode only via the
-- ESC-menu button + /editmode, never a keybind), so this one is addon-namespaced.
BINDING_NAME_ENCOUNTERJOURNAL_EDITMODE = BINDING_NAME_ENCOUNTERJOURNAL_EDITMODE or (HUD_EDIT_MODE_MENU or "Edit Mode")
-- Keybinding category header. The Key Bindings UI resolves a binding's category via _G[cat]
-- (era Keybindings.lua GetBindingCategoryName) — Bindings.xml uses category="BINDING_HEADER_ENCOUNTERJOURNAL"
-- so our binds group under "Encounter Journal" instead of the generic "AddOns" bucket.
BINDING_HEADER_ENCOUNTERJOURNAL = BINDING_HEADER_ENCOUNTERJOURNAL or "Encounter Journal"

EJ.cap = EJ.cap or {}

local function probeCapabilities()
  -- Native equipment-set engine. The C_EquipmentSet *namespace* always exists
  -- on Era (Blizzard ships the generated docs for every flavor), so a bare
  -- `C_EquipmentSet ~= nil` check is a trap — it's true even when the functions
  -- are non-functional stubs. The authoritative test is CanUseEquipmentSets(),
  -- which the client gates by game type. Wrapped in pcall so a hard stub that
  -- errors degrades to "no native support" rather than blocking login.
  -- This is the hydrate seam: if a future (Classic+) server turns the system
  -- on, this flips to true and EquipmentSets.lua routes through the native API
  -- with zero other changes.
  local nativeOK = false
  if C_EquipmentSet and C_EquipmentSet.CanUseEquipmentSets and C_EquipmentSet.GetEquipmentSetIDs then
    local ok, canUse = pcall(C_EquipmentSet.CanUseEquipmentSets)
    nativeOK = ok and canUse == true
  end
  EJ.cap.equipmentSets = nativeOK

  -- Talent system flavour. Era ships the classic grid talent API (GetNumTalentTabs
  -- + C_SpecializationInfo.GetTalentInfo); retail's node-graph API (C_ClassTalents)
  -- is absent. Our panel drives off the classic flag. The modern flag is the
  -- Classic+ hydrate seam: if a future client adds C_ClassTalents, a node-graph
  -- adapter can light up behind the same renderer (see Talents/TRACKER.md).
  EJ.cap.talentsClassic = (GetNumTalentTabs ~= nil)
    and (C_SpecializationInfo ~= nil and C_SpecializationInfo.GetTalentInfo ~= nil)
  EJ.cap.talentsModern = (C_ClassTalents ~= nil)
end

-- Early-development notice (owner directive 2026-06-12). Shown at login until the user
-- acknowledges it once (account-wide; ESC/no-click re-shows next login). The ack flag is
-- versioned so a future message change can re-prompt by bumping NOTICE_VERSION.
local NOTICE_VERSION = 1

-- ONE combined startup popup (USER_TRACKER U13): the early-dev notice AND the missing-companion
-- (BigWigs/Questie) warning share a single window instead of two stacked popups. Show it when
-- EITHER part applies; the OK button acks only the part(s) actually shown (dev notice is versioned
-- + account-wide; deps dismissal persists once-ever via EJ.deps). ESC (no OK) re-shows next login.
local function showStartupNotice()
  local devUnacked = (EJ.db.earlyDevNoticeAck or 0) < NOTICE_VERSION
  local depsBody = EJ.deps and EJ.deps.GetMissingDepsBody and EJ.deps.GetMissingDepsBody()
  if not devUnacked and not depsBody then return end
  if not StaticPopup_Show then return end

  local parts = {}
  if devUnacked then
    parts[#parts + 1] = "|cffffd100New Era|r is in early development.\n\n"
      .. "Please report bugs on the CurseForge page.\n\n"
      .. "|cffff4040Hardcore characters: use at your own risk until v1.0.|r"
  end
  if depsBody then parts[#parts + 1] = depsBody end

  -- Defined fresh each call so OnAccept closes over THIS login's devUnacked/depsBody (acks only
  -- what was shown). preferredIndex 3 = avoid the popup-1/2 taint slots.
  StaticPopupDialogs["EJ_STARTUP_NOTICE"] = {
    text = "%s",
    button1 = OKAY,
    OnAccept = function()
      if devUnacked then EJ.db.earlyDevNoticeAck = NOTICE_VERSION end
      if depsBody and EJ.deps and EJ.deps.MarkDepsDismissed then EJ.deps.MarkDepsDismissed() end
    end,
    timeout = 0, whileDead = 1, hideOnEscape = 1, preferredIndex = 3,
  }
  StaticPopup_Show("EJ_STARTUP_NOTICE", table.concat(parts, "\n\n|cff808080——————————————|r\n\n"))
end

-- Boot.
local boot = CreateFrame("Frame")
boot:RegisterEvent("ADDON_LOADED")
boot:RegisterEvent("PLAYER_LOGIN")
boot:SetScript("OnEvent", function(_, event, name)
  if event == "ADDON_LOADED" and name == addonName then
    -- True first-ever load = the SavedVariables has no schema yet (fresh install / wiped SV).
    -- Modules read EJ.freshInstall to apply retail one-time defaults (e.g. NamePlates forces
    -- retail's nameplate CVars once) WITHOUT re-forcing them on later loads. Capture BEFORE
    -- applyMigrations, which stamps db.schema. Transient (lives on EJ, never saved).
    EJ.freshInstall = not (EncounterJournalDB and EncounterJournalDB.schema)
    EncounterJournalDB = EncounterJournalDB or {}
    applyMigrations(EncounterJournalDB)
    EJ.db = EncounterJournalDB
  elseif event == "PLAYER_LOGIN" then
    probeCapabilities()
    -- Delay past the login flurry so the notice isn't lost under the loading screen.
    if C_Timer and C_Timer.After then
      C_Timer.After(3, showStartupNotice)
    else
      showStartupNotice()
    end
  end
end)
