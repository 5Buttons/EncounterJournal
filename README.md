# Encounter Journal — 3.3.5a standalone port

A standalone Adventure Guide (Encounter Journal) for **Wrath of the Lich King 3.3.5a**,
originally  ported from the New Era addon's Encounter Journal module. 

3.3.5 shipped no Encounter Journal of its own (it's a Cataclysm feature), so this brings the boss / ability / loot /
model browser to the WotLK client, populated with **vanilla-accurate** classic dungeon/raid
data **plus** a **WotLK** dataset adapted from the AzerPUGs Wrath Dungeon Journal.

## ✅ Status: opens and renders in-client (AzerothCore 3.3.5a)

The Lua copied here was written for **Classic Era (Interface 11508)** and calls APIs that do
**not** exist on 3.3.5a (Interface 30300). It was ported on top of **!!!ClassicAPI** (see below)
and now **runs on a live 3.3.5a client**: the window opens (micro button / `/ej` / keybind), the
metal `PortraitFrameTemplate` chrome draws from **real retail art**, the dungeon/raid grid and
the two-page encounter view (boss list, lore, ability sections, model) render, and the journal
carries both the original **vanilla** dataset and an adapted **WotLK** dataset.

Framework pieces done: the compat/shim layer; the **window chrome** (real metal nineslice +
body background + portrait ring + TopTileStreaks); the **dropdowns** (the three retail
`DropdownButton`/`WowStyle1DropdownTemplate` selectors are now classic `UIDropDownMenu`s via
`Core/Dropdown.lua`); the **navbar + deep search** (breadcrumb rebuilt from plain buttons since
3.3.5a has no `NavBarTemplate`; the search box searches instances/bosses/abilities/loot with a
results dropdown — `EncounterJournal/Search.lua`); the **model tab** (native 3.3.5 `PlayerModel`
instead of `ModelScene`, with a multi-creature switcher for council bosses and live framing
tuning via `/ej model`); the **openers** (micro button + slash + keybind); and **all three
datasets** — vanilla (cmangos-accurate) plus TBC + WotLK regenerated from **retail DB2** via
`tools/extract_ej.py`, with baked loot (name/quality/drop% + per-item difficulty masks) and
loot slot/difficulty/class filters. See `ROADMAP.md` for the review, fix plan and what's next.

### In-client bugs fixed (3.3.5a gotchas worth remembering)
- **`UIPanelScrollFrameTemplate` needs a NAME** — Blizzard's `ScrollFrame_OnLoad` /
  `OnScrollRangeChanged` do `_G[self:GetName().."ScrollBar"]`, so an unnamed templated
  ScrollFrame errors ("concatenate a nil value"). Name every one.
- **`parent:CreateMaskTexture()` returns nil** on ClassicAPI (mask textures are a no-op on
  3.3.5) — guard the result or `mask:SetTexture` aborts the whole window build (`Core/Portrait.lua`).
- **A raw retail FileDataID with no local file renders solid RED** on this client (not
  transparent) — every unshipped FDID (window bg `374155`, WotLK splash art, …) must be pointed
  at a shipped path or it's a red rectangle.
- **The dungeon-finder micro button is `LFDMicroButton`** on 3.3.5a, not `LFGMicroButton`
  (that's 3.4/retail). The real micro buttons live on `MainMenuBarArtFrame`, not `MainMenuBar`.
- **`AZP.WrathJournal.SavedData` (AzerPUGs) had a latent bug** — `InstanceLink.D` used
  `InstanceID[N]` (nil) instead of `InstanceID.D[N]`, so `string.format("%d", nil)` crashed the
  data file at load. Fixed in our copy.
- Module `onBoot` is `pcall`-wrapped and `EJ.Log` isn't shipped, so a `build()` error was
  silently swallowed — the journal's openers now register at **file scope** (independent of
  `build()`), and `build()` errors print to chat.

Addon identity: the install folder + TOC is **`EncounterJournal`**; SavedVariables is
**`EncounterJournalDB`**; the in-code namespace is the global table **`EJ`** (renamed from the
New Era source's `NE` — see *Namespace* below). The AzerPUGs WotLK source tables are confined to
a **file-local `AZP`** inside `wotlk_data.lua` and never touch the global namespace.

**Namespace:** everything lives under the single global **`EJ`** table (`EJ.ej`, `EJ.dropdown`,
`EJ.navbar`, `EJ.portrait`, `EJ.tex`, `EJ.nineslice`, …). The original New Era `NE` namespace,
the `NE_`-prefixed frame/global names (now `EJ_`), and the `NEWERA` keybind header (now
`ENCOUNTERJOURNAL`) were all renamed out; no `NE`/`AZP` remnant remains in shipped code.

## Built on !!!ClassicAPI (the key decision)

This port takes a **hard dependency on [!!!ClassicAPI](https://gitlab.com/Tsoukie/classicapi)**
(Tsoukie; note: **GitLab**, the old GitHub URL is dead), a 3.3.5a library that emulates large
parts of the modern/Classic API. It's declared `## Dependencies: !!!ClassicAPI` in the TOC, so
the game won't load the journal without it. A pinned snapshot (**1.22**, 2026-06-30) is
**vendored at the repo root** and included in the release zip by `tools/package.ps1`.

Leaning on ClassicAPI instead of hand-shimming everything **erased most of the original blocker
list**. What ClassicAPI provides for us:

| Need | Provided by ClassicAPI |
|------|------------------------|
| `C_Timer.After` / `NewTimer` / `NewTicker` | ✅ animation-group based (no per-frame OnUpdate) |
| `GetPhysicalScreenSize` | ✅ `PixelUtil` |
| `texture:SetAtlas` + `C_Texture` atlas DB (`RegisterAtlas`, `GetAtlasExists`) | ✅ |
| NineSlice (`NineSliceUtil.ApplyLayoutByName`, `PortraitFrameTemplate`) | ✅ + ships metal frame art, uses the correct 3.3.5 **mirror** technique |
| `SearchBoxTemplate`, `UIDropDownMenu` templates, `Backdrop`, `UIPanelTemplates` | ✅ |
| `C_Item.RequestLoadItemDataByID`, `C_Map.GetPlayerMapPosition`, `C_AddOns` | ✅ |
| `SOUNDKIT` | ⚠️ base table only — **missing** the `IG_CHARACTER_INFO_OPEN/CLOSE` keys we use |

What ClassicAPI does **not** give us (these were the genuine work, now all resolved): the
**modern dropdown** API (`DropdownButton`/`SetupMenu` — it only ships the old `UIDropDownMenu`),
**`ModelScene`**, **`NavBarTemplate`**, the round **PortraitMetal portrait-ring** corner, and the
real `UI-Frame-Metal-*` atlas family (its PortraitFrame layout references it but only registers
the diamond-studded look-alike `UI-Frame-DiamondMetal-*`).

Our own gap-fillers on top of ClassicAPI live in `Core/Compat.lua`:
- the two `SOUNDKIT.IG_CHARACTER_INFO_*` keys + `C_Map.GetMapChildrenInfo` /
  `C_EncounterJournal.IsEncounterComplete` stubs;
- **the real PortraitFrame metal chrome** — we ship the actual retail metal sheets under
  `Art/Frame/` and register every `UI-Frame-Metal-*` piece (corners, the four tiling edges, the
  round `UI-Frame-PortraitMetal-CornerTopLeft` ring) with texcoords transcribed from
  `UiTextureAtlasMember.12.1.0.68301.csv` (kept in the repo root). This replaced the old
  `Core/Atlas335.lua` DiamondMetal aliasing.

### Frame / chrome art (how the metal border is built)
The window inherits `PortraitFrameTemplate` (so does the retail Encounter Journal and the AzerPUGs
Wrath fork). ClassicAPI's nineslice draws that layout from named atlas pieces; `Core/Compat.lua`'s
`regAt(name, sheetFile, w, h, L, R, T, B, sheetW, sheetH, tileH, tileV)` registers each piece from
a shipped sheet (`w,h` = 1x render size; `L,R,T,B` = pixel coords ÷ sheet size; `tileH/tileV` per
the `_`/`!` atlas-name prefix). Sheets in `Art/Frame/`:

| retail UiTextureAtlasID | file | holds |
|---|---|---|
| 1390 | `uiframemetal2x.blp` (512×512) | 4 corners + the **portrait ring** |
| 1395 | `uiframemetalhorizontal2x.blp` (64×256) | top + bottom edges (`_`, horiz-tile) |
| 1394 | `uiframemetalvertical2x.blp` (512×32) | left + right edges (`!`, vert-tile, art stored **upright**) |
| 950 | `uiframehorizontal.blp` (256×128) | the `_UI-Frame-TopTileStreaks` band |

Body background = ClassicAPI's bundled `UI-Background-Rock` tile (a raw retail bg FDID rendered
red). To **view/measure a BLP** while working: `python` parses the BLP2 header → raw BGRA
(uncompressed `enc=3` only) → `magick -size WxH -depth 8 bgra:in.bgra out.png` (ImageMagick is
installed; pass it Windows paths).

## What's in here

| Path | What it is | Port status |
|------|-----------|-------------|
| `Art/EncounterJournal/` | 365 BLP textures (chrome sheet, slices, instance splashes, lore backdrops, boss portraits, model backdrops). **BLPs work as-is on 3.3.5.** | ✅ ready |
| `EncounterJournal/vanilla_data.lua` | **ALL Classic data in one file** — instances, bosses, loot+drop%, models, ability sections (was `Data.lua` + `AbilitiesEra.lua` + `PortraitOverrides.lua`). | ✅ ready |
| `EncounterJournal/tbc_data.lua` | **ALL TBC data in one file** — auto-generated from retail DB2 (tier 70) by `tools/extract_ej.py`: 24 instances, 100 bosses (96 with baked loot incl. difficulty masks). | ✅ ready |
| `EncounterJournal/wotlk_data.lua` | **ALL WotLK data in one file** — auto-generated from retail DB2 (tier 72): 25 instances, 122 bosses (110 with baked loot). Supersedes the old AzerPUGs adapter (kept as `.azerpugs.bak`). | ✅ ready |
| `EncounterJournal/Search.lua` | **Deep search** — flattens `EJ.ej.DATA` into an index; the navbar search box matches instances/bosses/abilities/loot and shows a click-to-navigate results dropdown. | ✅ done |
| `EncounterJournal/Slices.lua` | Virtual texcoord slices for the chrome sheet (`EJ.ej.ApplySlice`). Texcoord-based, no atlas. | ✅ mostly ready |
| `EncounterJournal/EncounterJournal.lua` | Window shell + real metal chrome, instance grid, Dungeons/Raids tabs, the three openers (micro button / slash / global). | ✅ ported |
| `EncounterJournal/EncounterPage.lua` | Encounter view: lore/info panels, boss list, abilities/loot/model (native `PlayerModel`). | ✅ ported |
| `EncounterJournal/NavBar.lua` | Breadcrumb (plain buttons) + `SearchBoxTemplate` search box. | ✅ ported |
| `EncounterJournal/{ModelCam,PortraitCam}.lua` | Model camera tuning data + portrait cam. Live per-boss overrides via `/ej model` (persisted in the SavedVariables). | ⚠️ partial |
| `Art/Common/651080-whiteiconframe.blp` | The retail `WhiteIconFrame` rarity border (the 4.x client path draws nothing on 3.3.5) — used by loot rows + `Core/ItemButton.lua`. | ✅ ready |
| `Art/Frame/` | **NEW.** Real retail PortraitFrame metal sheets (corners/edges/streaks) — see "Frame / chrome art". | ✅ ready |
| `Art/EncounterJournal/ui-microbutton-ej-{up,down}.blp`, `UI-EJ-{WrathoftheLichKing,Classic,BurningCrusade}.blp` | **NEW.** Extracted retail micro-button art + tier backgrounds. | ✅ ready |
| `Bindings.xml` | **NEW.** Registers the `TOGGLEENCOUNTERJOURNAL` keybind (labels live in `Core/Core.lua`). | ✅ done |
| `Core/Compat.lua` | Gap-filler shims (SOUNDKIT keys, C_Map/C_EncounterJournal stubs) **+ the real PortraitFrame metal-atlas registration** (was `Core/Atlas335.lua`). | ✅ done |
| `Core/Dropdown.lua` | **NEW.** Classic `UIDropDownMenu` wrapper (`EJ.dropdown.New` / `.OpenMenu`) exposing the `:SetupMenu`/`:GenerateMenu`/`root:CreateRadio` surface. Replaced `Core/DropdownSkin.lua`. | ✅ done |
| `Core/NavBar.lua` | Breadcrumb helper rebuilt from plain pooled buttons (no `NavBarTemplate`); boss-jump via `EJ.dropdown.OpenMenu`. | ✅ done |
| `Core/Texture.lua`, `Core/NineSlice.lua` | Atlas + nineslice helpers, bridged to ClassicAPI. `NineSlice.lua` also holds the retail layout data (was `Core/NineSliceLayouts.lua`). | ✅ done |
| `Core/Portrait.lua` | Masked portrait cutout (mask is a no-op on 3.3.5 → square icon, kept within the ring opening). | ✅ done |
| `Core/*.lua` (rest) | The `EJ.*` framework helpers (fonts, scrollbar, tooltip, panel chrome, item button, module registry). The journal's bottom Dungeons/Raids tabs are sized by `EJ.tabs.ResizeTabMinimum` (in `Core/FrameUtil.lua`). | ✅ mostly |
| `Core/WorldMap.lua` | The "Show Map" button action (`EJ.worldmap.ShowInstanceMap` — opens the world map to the instance's uiMap). Replaced the non-functional `WorldMap/{Dungeons,DungeonMap}.lua` dungeon-overlay system (whose data/support layer — DungeonMaps tiles, Questie, HereBeDragons, MapCanvas — was never shipped). Empty on stock 3.3.5a; a client patch that ships dungeon-map art makes it work. | ✅ button works (art = patch) |

## 3.3.5 API gap list (status)

Each modern/Era-only API the copied code uses, and how it's resolved. **Most former blockers are
now handled by ClassicAPI + our two gap-filler files** (see "Built on !!!ClassicAPI" above).

**✅ Resolved**
- **Modern dropdowns** — the New Era source built retail `CreateFrame("DropdownButton", …, "WowStyle1DropdownTemplate")` selectors with `:SetupMenu`/`root:CreateRadio` (neither the frame type nor those methods exist on 3.3.5a). `Core/Dropdown.lua`'s `EJ.dropdown.New` wraps the **classic `UIDropDownMenu`** (ClassicAPI's `C_UIDropDownMenu_*`, native fallback) and re-exposes the same `:SetupMenu`/`:GenerateMenu`/`:SetDefaultText`/`root:CreateRadio` surface, so the instance filter (`EncounterJournal.lua`), loot-slot filter (`EncounterPage.lua`), and floor selector (`WorldMap/DungeonMap.lua`) each swapped a single `CreateFrame` line. (The old `Core/DropdownSkin.lua`, which only repainted the retail button's atlas art, was deleted.) The navbar boss-jump is a separate `listFunc` on the breadcrumb — it lands with the NavBar rework.
- **`C_Timer.After`** — ClassicAPI (animation-group based). *(used by the dropdown refresh, loot debounce, model-load poll, FrameUtil/PanelManager/ScrollbarReskin)*
- **`GetPhysicalScreenSize`** — ClassicAPI `PixelUtil` (FrameUtil's `PinPixelPerfect` calls it unguarded).
- **`SOUNDKIT.*`** — ClassicAPI base table; we add the missing `IG_CHARACTER_INFO_OPEN/CLOSE` in `Core/Compat.lua`. `PlaySound` takes the string names natively on 3.3.5, so `WirePanelSounds` needed no change.
- **Atlas system / window chrome** — bridged, not replaced. `EJ.tex.SetAtlas` falls through to ClassicAPI's native `texture:SetAtlas` (gated on `C_Texture.GetAtlasExists`); `EJ.nineslice.ApplyLayout` delegates to `NineSliceUtil.ApplyLayoutByName`. `Core/Compat.lua` registers the real `UI-Frame-Metal-*` family (corners + 4 edges + the `UI-Frame-PortraitMetal-CornerTopLeft` ring) from the shipped `Art/Frame/` sheets (see "Frame / chrome art"), so the border draws as the genuine retail PortraitFrame metal. Body bg = ClassicAPI's `UI-Background-Rock`. The interior chrome stays on `Slices.lua` texcoord slices.
- **TBC + WotLK content** — `tbc_data.lua` + `wotlk_data.lua` are **auto-generated from the retail Encounter-Journal DB2 tables** (build 12.1.0.68301, staged in `tools/db2/`) by `tools/extract_ej.py`: instances, bosses, ability section trees, lore, boss map positions (`JournalEncounterXMapLoc`) and **inline baked loot** (item list + per-item difficulty from DB2, name/quality/drop% joined from AtlasLoot by itemID). WotLK loads last and replace-on-collision (`id`-dedup) supersedes colliding Classic instances (e.g. Naxxramas 754). Vanilla stays cmangos-built — DB2 tier 68 "Classic" is the *Cataclysm* dungeon revamp, wrong for 3.3.5.
- **`C_Item.RequestLoadItemDataByID`** — ClassicAPI (no-op level; `GetItemInfo` resolves cached items synchronously on 3.3.5).
- **`NavBarTemplate` / `NavBar_Initialize`** — Cata+ (absent on 3.3.5a; ClassicAPI doesn't ship them). `Core/NavBar.lua` was reimplemented as a plain breadcrumb of pooled buttons + `›` separators, prepending a Home crumb and laying each crumb out left-to-right at its label width. A crumb with a `listFunc` gets a ▾ sub-button that pops a transient context menu (`EJ.dropdown.OpenMenu`, built on `EasyMenu`) — this is the boss-jump. The inset border (`ui-frame-inner*`) is kept and degrades gracefully if those atlases don't resolve.
- **`SearchBoxTemplate`** — ClassicAPI ships it (inherits `InputBoxTemplate`, with `SearchBoxTemplate_OnLoad`), so the navbar search box uses the template directly; the EJ code just hooks `OnTextChanged` → `EJ.ej.FilterGrid`.
- **`ModelScene`** (`EncounterPage.lua`) — 3.3.5a has no `ModelScene` frame type, no `SetFromModelSceneID`/`GetActorByTag`/`SetModelByCreatureDisplayID`, and none of the `MakeCurrentCameraCustom`/`SetCameraPosition`/`SetCameraTarget` camera API. Reworked onto the **native 3.3.5 `PlayerModel`**: the model area is now a plain container Frame holding a `PlayerModel`; `SetDisplayInfo(displayID)` loads the creature and `SetPosition(x,y,z)` + `SetFacing` + `SetModelScale` frame it (3.3.5's camera is fixed at the origin looking down +X, so the *model* is moved — larger x = further/smaller, negative z lowers it to centre, y pans). The size-fitted `ModelCam.lua` per-boss `cdist`/`ctz` map to x / −z; `MODEL_TWEAKS` (live `/ne ejmodel`) overrides outliers with explicit `x/y/z/facing/mscale`. Drag-to-rotate is self-contained (horizontal cursor delta → `SetFacing`; 3.3.5 has no generic `Model_OnUpdate` to borrow). *Axis signs/scale may need in-client tuning — the framing math is the right mechanism but unverified against the live client.*

**⚠️ Still to do (real rewrites — ClassicAPI doesn't cover these)**
- *(none of the big framework blockers remain — see roadmap for the remaining loot-streaming + polish work.)*

**Minor / guarded already** (unchanged)
- `GameTooltip_SetTitle`, `GameTooltip_AddColoredLine` — may be absent; code falls back to `:SetText` / `:AddLine`.
- `GameFontNormalMed3` / `GameFontNormalLarge2` — absent (code already falls back).
- `bit`, `InCombatLockdown`, `HandleModifiedItemClick`, `PlayerModel`, `InsetFrameTemplate`, `UIPanelCloseButton`, `CharacterFrameTabButtonTemplate` — all present on 3.3.5. ✅
- **`EJ.modules` / `EJ.panelmgr`** — kept as-is. The module registry is just `CreateFrame` + events and **works unchanged on 3.3.5**, so the boot block at the bottom of `EncounterJournal.lua` did NOT need replacing (contrary to the original plan). `EJ.panelmgr` calls are nil-guarded.

## Known cosmetic gaps (non-fatal, polish later)
- Portrait **circular mask**: 3.3.5 has no texture masking (`CreateMaskTexture` is a no-op) and the
  metal ring is open toward the frame interior, so a square icon always poked out. Solved by
  shipping a **pre-masked circular icon** — the 521753 book/skull DXT1-decoded with a circular
  alpha baked in, exported as `Art/EncounterJournal/ui-ej-portraiticon-round.tga` (the round
  illusion now comes from the icon's own transparent corners, not from masking).
- Some **boss/instance art** is placeholder — ~111 art-less bosses (mostly WotLK raids) fall
  back to the neutral plate, some instances use placeholder splash art (any unshipped retail
  FDID would render red, so `Assets.lua`'s deferred fallback pass maps them to shipped
  neutrals). Extract the real art to upgrade, purely additive.
- Boss **model** sometimes shows a red `?` or sits mis-framed — tune it live per boss with
  **`/ej model x|y|z|facing|scale <n>`** (persisted per display ID in the SavedVariables;
  `reset` clears, `global <n>` scales everything).
- DB2 ability text carries retail `$spell`-tokens; `cleanBody()` strips them at render but the
  numeric values are lost. The proper fix is resolving them at extraction time (`ROADMAP.md` R6).

## Roadmap

The build-up history (shims → chrome → dropdowns → navbar → model tab → openers → DB2 data →
loot filters) is done and archived in git history. **Current plan: see `ROADMAP.md`** — the
2026-07 review with the fix list and the retail-parity feature roadmap. Recently landed from it:
- **Deep search** (R1) — `EncounterJournal/Search.lua`, results dropdown under the search box.
- **Tier-aware instance-select background** (R3) — swaps Classic/BC/Wrath art with the filter.
- **Multi-creature model switcher** (R4) — portrait buttons on council bosses (31 in the data).
- **`/ej model` live framing tuner** (F3) + **loot rarity borders** (F1, shipped WhiteIconFrame)
  + **vendored !!!ClassicAPI 1.22** (F2) + **`tools/package.ps1` release packaging** (F5).

Next per `ROADMAP.md`: an in-client verification pass (F4), the unified encounter-level
difficulty selector (R2), boss-kill/lockout awareness (R5), token resolution in the extractor
(R6), and the LFD "Find Group" button (R7).

### 2026-09-05 — visual parity with the DragonUI_NewEra journal + its 3.3.5a fixes
The `DragonUI_NewEra-main/` reference (a DragonUI module, so not runnable here — this install uses
ElvUI) was mined for its look and for the 3.3.5a traps it documents. Landed:
- **Chrome:** retail `UI-Background-Rock` body (374155, untinted), black inset well, **Dragonflight
  metal Dungeons/Raids tabs** (`Core/Tabs.lua`), **RedButton close** (path + texcoord — a texture
  OBJECT handed to `SetNormalTexture` left the button blank on this client), the **MinimalScrollBar**
  art actually lit up (its atlases + the inset trim + the tab/close sheets are registered in the
  new `Core/AtlasData.lua` → the `EJ_ATLAS` table `EJ.tex.SetAtlas` consults first; sheets under
  `Art/Common/`). Grid + encounter pages are pinned above the inset's own border pieces.
- **Art completed from the reference:** +116 boss plates, +7 backdrops, +7 lore splashes, and the
  23 square 128×128 WotLK instance icons (also aliased onto the seven DB2 `ButtonFileDataID`s no
  extract of ours carried, e.g. Ahn'kahet / Halls of * / Nexus / ICC) with a square-aware crop
  (`EJ.ej.SetButtonTexCoord`). Boss plates without art: 193 → ~86.
- **Expansion-tier selector** (Classic / Burning Crusade / Wrath; persisted; defaults to the
  character's level) replaces the continent/"All" filter, so the page art always matches the
  listed tier — "All" used to paint Classic art behind Wrath dungeons.
- **Window:** draggable, position persisted (`/ej resetpos` returns it to the panel row);
  `/ej scale <0.5-2.0>` size knob; `/ej help`.
- **Fixes from the reference's notes:** search-box placeholder (`ClassicAPI`'s `SearchBoxTemplate`
  writes the literal "Search" into the box → the grid was filtered by it after a focus change);
  model area is shown BEFORE the load (the engine drops loads into hidden frames) plus a reload
  retry and a "not available yet" notice; spell icons via `GetSpellInfo`; WotLK tier tokens /
  quest items relabelled instead of "Junk"; loot slot dropdown lists only present categories,
  gets a clear-X, and resets on a difficulty switch; selected boss row stays lit. (NewEra's
  drop-chance loot headers were tried and reverted: our DB2 loot has no rate for most WotLK drops,
  so everything read "Common"/"Bonus" — the list stays flat like retail's.)
- **Model overrides:** `EJ.ej.MODEL_PATH[displayID]` loads a raw `.m2` via `Model:SetModel` (test
  seed: Kel'Thuzad 15945 → `Creature\Lich\Lich.m2`); live via `/ej model path <file>|none|clear`
  and `/ej model display <id>|clear` (persisted per display ID).
- Static check: `python scratchpad/luacheck.py` (lupa) compiles every shipped file; no luac here.
- **Loot loading (AtlasLoot-style, reference `AtlasLoot_ChromieCraft-master/`):** 3.3.5a only
  knows an item once the server has answered a query for it, and nothing here queries behind the
  player's back (item-query bursts disconnect people). An unloaded row shows its baked name, a "?"
  icon in a RED border and "Right-click to load"; the tooltip carries AtlasLoot's warning.
  **Right-click** queries that item (hidden-tooltip `SetHyperlink("item:<id>")`, AtlasLoot's
  mechanism) and the row fills in as the answer lands; **"Load all items"** under the list queries
  the whole page one item per 0.15 s. Left-click keeps shift = chat link / ctrl = dress-up.
- **WotLK raid abilities:** the DB2 extract has NO sections for 43 Wrath raid bosses (Naxxramas,
  Vault of Archavon, Obsidian Sanctum, Eye of Eternity, Trial of the Crusader, Onyxia, Icecrown
  Citadel, Ruby Sanctum, Algalon). `EncounterJournal/wotlk_abilities.lua` (generated by the
  scratchpad `abilport.py` from DragonUI_NewEra's hand-seeded `AbilitiesWotLK.lua`, re-keyed by
  instance + boss name onto our JournalEncounter ids) overlays 187 abilities: onto those
  section-less encounters, AND (its `FORCE` set) over the 13 DB2-sectioned Ulduar bosses, whose
  retail entries read wrong in-client — Ulduar is entirely NewEra-seeded now. Caveat inherited from
  the source: bodies are paraphrased prose (most
  from a Wowhead tooltip export, some hand-written) and `spell` is 0 where no id was verified —
  a future DB2 regen with real sections wins automatically.
- **Burning Crusade raid abilities:** retail never authored sections for the 8 TBC raids, so all
  36 raid bosses (Karazhan … Sunwell) were section-less. `EncounterJournal/tbc_abilities.lua`
  (scratchpad `tbcport.py` from NewEra's `AbilitiesTBC.lua`, whose keys are the same DB2 encounter
  ids as ours) overlays 181 abilities — sourced there from cmangos TBCDB spell lists + ScriptDev2
  boss scripts, cross-checked on the TBC Wowhead; `spell` is the real TBC id or 0, never guessed.
- **Loot difficulty masks the DB2 extract lacks** (`EncounterJournal/loot_diff.lua`, scratchpad
  `lootdiff.py` from NewEra's AtlasLoot-tagged rows, applied at load only over the DB2 placeholder
  value so a regen with real masks wins): Ulduar was `diff=0` everywhere (no selector, one merged
  list) → 10/25 masks from `size` tags (437 items); the 16 TBC dungeons were `diff=6` everywhere
  (= Normal AND Heroic, so the selector showed the same list twice) → Normal-only / Heroic-only rows
  from AtlasLoot's `n`/`h` tags (467 items); the 16 WotLK dungeons had the same `6`-everywhere
  placeholder and get the same treatment (NewEra's placeholder instance ids matched by name);
  untagged rows stay on both.
- **Loot rows without a cached item** (`EncounterJournal/item_info.lua`, scratchpad `iteminfo.py`):
  the Classic tier bakes no item names, so on a fresh item cache every Classic loot row failed the
  "no name, not cached" test and the lists came up EMPTY. The table maps all 5969 loot item ids to
  { name, quality, icon } — names/quality from AtlasLoot_ChromieCraft (24 ids unnamed), icons for
  every id from this client's `Item.dbc` + `ItemDisplayInfo.dbc` (extracted from the locale MPQ
  with `mpyq`). Unloaded rows now show the real icon in the red border; the search index covers
  Classic loot names too.
- **Boss model fallback in bulk** (`EncounterJournal/ModelPaths.lua`, scratchpad `dbcmodels.py`):
  display id → model file for 485 of the 494 boss displays, read from this client's
  `CreatureDisplayInfo.dbc` + `CreatureModelData.dbc` (patch-y.mpq wins). A raw `.m2` via
  `SetModel` comes up UNTEXTURED, though: the skin lives in the display's TextureVariation, which
  only the display/creature loaders apply. Load mode (`/ej model mode`, persisted):
  **`creature`** (default) = `Model:SetCreature(npcID)`, the standard 3.3.5 path — the client
  queries the creature from the server (like an item) and renders the display with its textures
  and scale; retried at 0.15/0.5/1 s while the server answers, verdict at 2 s, then the model file
  (visible, untextured) or `SetDisplayInfo`. Npc ids: Classic encounter ids ARE cmangos npc ids;
  TBC/WotLK come from `EncounterJournal/npc_ids.lua`, harvested from the installed DBM boss mods
  (158 of 222 bosses — DBM-Party-BC covers only part of the Outland dungeons, and event/faction
  encounters have no mod; those fall through to display/file). `file` loads the `.m2` up front
  (untextured); `auto` tries `SetDisplayInfo` then the file; `display` never falls back.
  160 displays are humanoid (a shared character body
  dressed by CreatureDisplayInfoExtra) and are not auto-substituted — `SetModel` would show a bare
  body; 9 ids are retail-only displays the 3.3.5 tables don't have (Pit of Saron bosses, Sapphiron).
  Explicit `/ej model path` overrides still win (Kel'Thuzad keeps `Creature\Lich\Lich.m2`; the DBC
  says his own model is `Creature\KelThuzad\KelThuzad.m2` at display scale 4).
- **Ability icons:** the DB2 extract writes retail FileDataIDs into every section's `icon=`, and
  3.3.5a renders a numeric FDID as a RED square. `tools/convert_icons.py --write` (map:
  `icon_ids.lua`, WeakAuras' ArtTexturePaths) rewrote 1330 of 1354 icons to
  `Interface\icons\<name>` paths; the 24 left are Cata+ icons the client has no file for, and the
  renderer now treats any numeric icon as "none" (→ the spell's own icon, else no glyph) instead of
  handing it to SetTexture. **Re-run the converter after every `extract_ej.py` regen.**

## Opening the journal

3.3.5a ships no Encounter Journal binding or button, so the openers register at **file scope** in
`EncounterJournal.lua` (so they survive a `build()` error), all calling `EJ.ej.Toggle()`:
- a **micro button** on the main menu bar — inserted before the Main Menu button (mirrors a real
  micro button's parent/level/size so it sits in the row), using the shipped retail
  `Art/EncounterJournal/ui-microbutton-ej-{up,down}.blp`;
- a **slash command** — `/ej`, `/encounterjournal`, or `/adventureguide`;
- a **key binding** — "Toggle Adventure Guide" under the *Encounter Journal* category in the Key
  Bindings UI (registered via `Bindings.xml`; `ToggleEncounterJournal()` is created at login).

## Repo layout (since 2026-09-05)

The addon folder (`Interface/AddOns/EncounterJournal/`, the git working tree) now holds ONLY what
ships plus `tools/`: `EncounterJournal.toc`, `Bindings.xml`, `Core/`, `EncounterJournal/`, `Art/`,
the vendored `!!!ClassicAPI/`, and `tools/` (extractor, icon converter + its `icon_ids.lua` map,
packaging script, the pinned `db2/` CSVs the extractor reads). Everything dev-only moved to
**`c:\Games\Chromiefresh\EncounterJournal-dev\`** (outside `Interface/`, so the client never scans
it): `NewEra/` (the original addon), `DragonUI_NewEra-main/` (the visual/3.3.5a reference),
`EncounterJournal-main/` (Ascension), `References/` (wiki, AzerPUGs, AtlasLoot_ChromieCraft, the
atlas CSV), `daten/` (the newer 12.1.0 DB2 export), `libs/`, `dist/` (build output) and `bak/`
(the pre-regen data backups). The scratchpad port scripts and `tools/extract_ej.py --loottables`
resolve those paths relative to the repo root (`../../../EncounterJournal-dev/...`).

## Install

Requires **[!!!ClassicAPI](https://gitlab.com/Tsoukie/classicapi)** — a 3.3.5a compatibility
library that emulates the modern API (`C_Timer`, `SetAtlas`, NineSlice, `SearchBoxTemplate`,
`GetPhysicalScreenSize`, etc.). A pinned copy (1.22) is **vendored at the repo root** and
declared as a hard `## Dependencies` in the TOC, so the game won't load the journal without it.

Easiest: run **`tools\package.ps1`** — it stages only the shippable files (no dev folders, no
`.bak` backups) plus `!!!ClassicAPI/` into `dist\EncounterJournal-<version>.zip`; extract that
zip into `World of Warcraft/Interface/AddOns/`. Manual install: copy `!!!ClassicAPI/` and this
addon (as a folder named **`EncounterJournal`** — all art paths resolve under
`Interface\AddOns\EncounterJournal\`) into `Interface/AddOns/`.
