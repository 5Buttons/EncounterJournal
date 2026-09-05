# Encounter Journal 3.3.5a — Review, Fix Plan & Feature Roadmap (2026-07-16)

Reviewed against the retail Adventure Guide feature set, the WoW 3.3.5a programming wiki
(`References/wow-335a-addon-wiki-main/`), and the two reference addons (AzerPUGs Wrath
Classic journal; Ascension `EncounterJournal-main`, structure-inspiration only per project
rules — no boss data from it).

> **Status update (2026-07-17):** F1 ✅ (WhiteIconFrame shipped to `Art/Common/`, both call
> sites fixed) · F2 ✅ (!!!ClassicAPI **1.22** vendored at repo root — the project moved to
> **GitLab** <https://gitlab.com/Tsoukie/classicapi>, the GitHub URL is dead) · F3 ✅
> (`/ej model x|y|z|facing|scale|global|reset`) · F5 ✅ (`tools/package.ps1` →
> `dist/EncounterJournal-<ver>.zip`) · F6 ✅ (git repo, initial commit) · F7 ✅ (README
> refreshed) · F8 ✅ (dead watcher removed; `$`-token resolution folded into R6) ·
> R1 ✅ (`EncounterJournal/Search.lua` deep search + results dropdown) · R3 ✅ (tier-aware
> grid background) · R4 ✅ (multi-creature model switcher; 31 council bosses in the data).
> All shipped Lua syntax-checked. **Open: F4 (in-client verification — now the top priority),
> R5–R10.**
>
> **Second batch (same day):** R2 ✅ — ONE encounter-page difficulty selector: buckets are now
> per-INSTANCE (`EJ.ej.InstanceDiffBuckets`, cached union of loot diff masks), `refreshView`
> owns availability/default/anchor/visibility (Loot tab + boss Abilities pages), the selection
> filters loot rows AND hides Heroic-flagged sections (flag 8, incl. children) on Normal
> buckets. R7 ✅ — "Find Group" button on the lore page (`Core/LFD.lua`): runtime name-match
> against `GetLFGDungeonInfo` (no baked ID table), opens the 3.3.5 Dungeon Finder in Specific
> mode with the dungeon's normal+heroic rows ticked; dungeons only, fully guarded.
> R5 needs design first: per-boss kill stats require a boss→statistic-achievement-ID mapping
> (runtime statistics-category scan or a baked table) — not started. R6 blocked on a 3.3.5
> spell-value data source (`daten/` has no spell tables).
>
> **2026-09-05 (DragonUI_NewEra parity pass):** chrome brought to the NewEra look (rock body,
> black inset, DF metal tabs, RedButton close, MinimalScrollBar art, `Core/AtlasData.lua`), art
> sets completed from that reference (+116 boss plates, +7 backdrops, +7 lore, 23 square WotLK
> icons), expansion-TIER selector in place of the continent/"All" filter, draggable + persisted
> window, `/ej scale`. Bugs fixed from the reference's 3.3.5a notes: search placeholder filtering
> the grid, model loaded into a hidden frame, `GetSpellTexture(id)`, "Junk" tier tokens, loot
> slot dropdown offering empty categories. Added: clear-X, boss-row highlight lock,
> `EJ.ej.MODEL_PATH` raw `.m2` overrides (`/ej model path`, Kel'Thuzad test). NewEra's
> drop-chance loot headers were tried and reverted (no rates in our WotLK loot → all "Common").
> F5 (second half) ✅: all dev-only material (NewEra/, DragonUI_NewEra-main/, EncounterJournal-main/,
> References/, daten/, libs/, dist/, *.bak) moved out of the addon folder to
> `c:\Games\Chromiefresh\EncounterJournal-dev\`; the root AtlasLoot duplicate was deleted (identical
> to the References copy); `icon_ids.lua` lives in `tools/`. Addon folder: 784 MB → 133 MB.
> Data overlays (all generated, all "only where the DB2 value is the placeholder"): `tbc_abilities.lua`
> (36 BC raid bosses), `loot_diff.lua` (Ulduar 10/25 + TBC dungeon N/H masks), `item_info.lua`
> (name/quality/icon for all 5969 loot ids — fixes the empty Classic loot on a fresh item cache),
> `ModelPaths.lua` (485 display→.m2 from the client DBCs, automatic SetModel fallback). The MPQ/DBC
> extraction runs with python `mpyq` straight off `c:\Games\Chromiefresh\Data\*.MPQ`.
> Same day: `wotlk_abilities.lua` overlays NewEra's hand-seeded abilities onto the 43 WotLK raid
> bosses the DB2 extract left section-less (144 abilities; paraphrased text, spell ids where
> verified) — the Abilities tab is no longer empty on any Wrath raid boss.
> **F4 (in-client verification) is now the top priority again** — none of this has run in the
> client yet; every piece degrades to the previous art if a sheet/atlas fails to resolve.
> R8 shrinks to ~86 art-less bosses. Still open: R5, R6, R9, R10.

## Current state (verified in this review)

Working and in good shape:
- Opens in-client: micro button (real `UI-MicroButton-EJ` art), `/ej` slash, keybind.
- Real retail metal `PortraitFrameTemplate` chrome from shipped `Art/Frame/` sheets.
- Instance grid (splash art, Dungeons/Raids tabs, continent/expansion filter, name search).
- Two-page encounter view: lore, boss list, ability section tree (expand/collapse, flag
  badges + tooltips), loot tab (slot + difficulty + approximate class filter, baked
  name/quality, click-to-load caching), model tab (native `PlayerModel`, drag-rotate).
- Breadcrumb navbar with boss-jump dropdown; classic + dragonflight skin scaffold.
- Data: 76 instances — vanilla (27, cmangos-accurate), TBC (24) + WotLK (25) regenerated
  from retail DB2 via `tools/extract_ej.py`, loot with difficulty bitmask, boss map coords.

---

## Part 1 — Fix plan (bugs & hygiene, in priority order)

### F1. Loot rarity border is broken twofold
`EncounterPage.lua` `lootRow()` sets `iconBorder` to `Interface\Common\WhiteIconFrame` — a
**4.x+ client path that doesn't exist on 3.3.5** (silently fails). `Core/ItemButton.lua:41`
already points at the correct shipped path `Art\Common\651080-whiteiconframe.blp` — but
**that file is not in the repo** (`Art/Common/` doesn't exist).
**Fix:** extract WhiteIconFrame once (same workflow as the micro-button art), ship it under
`Art/Common/`, and point both call sites at the addon path.

### F2. `!!!ClassicAPI` is not bundled but README says it is
The addon hard-depends on it (`## Dependencies`), README says "(bundled here)" — there is no
`!!!ClassicAPI/` anywhere in the repo. A fresh install following the README fails.
**Fix:** either vendor a known-good ClassicAPI snapshot next to the addon (preferred — the
port is tuned against its exact shim behaviors) or correct the README with a pinned
download link/version.

### F3. Model-tuning command referenced but never shipped
`EncounterPage.lua` loads persisted overrides from `EncounterJournalDB._ejTweaks` and its
comments direct you to `/ne ejmodel` — but the slash handler only implements `/ej skin`.
The known mis-framed / red-`?` models **cannot be tuned in-client** right now.
**Fix:** add `/ej model x|y|z|facing|scale <n>` + `global <n>` + `save` acting on
`EJ.ej._cur` (the hook is already in place), writing through to `_ejTweaks`.

### F4. In-client verification pass is overdue
Unverified since being built: the classic-skin navbar (art/texcoords/overlap), the skin
toggle + options panel, `/ej skin`, model framing across WotLK bosses, and the loot class
filter's warm pass. One session with a checklist; log fixes back into README/memory.

### F5. Packaging: ~520 MB of dev material sits inside the addon folder
`NewEra/` (488 MB — the entire original addon), `References/` (11 MB),
`EncounterJournal-main/` (8.3 MB, belongs under `References/`), `libs/` (3.1 MB, unused
Ascension leftovers), `daten/` (4.8 MB DB2 CSVs), `tools/`, `icon_ids.lua` (765 KB),
`UiTextureAtlasMember...csv`, four `*.bak` data files, plus redundant *named* art
duplicates alongside the `<fdid>.blp` copies in `Art/EncounterJournal/`.
**Fix:** add `tools/package.ps1` that copies only the ship list (TOC, `Bindings.xml`,
`Core/`, `EncounterJournal/` minus `*.bak`, `Art/`, README) into a release zip named
`EncounterJournal/`. Optionally move `EncounterJournal-main/`, `NewEra/`, `libs/`, `daten/`
under `References/`.

### F6. Not a git repository
One bad edit to a 576 KB generated data file is unrecoverable. **Fix:** `git init`, commit,
`.gitignore` for `References/`, `NewEra/`, `daten/`, `__pycache__/`.

### F7. Stale docs
README/TOC still describe the AzerPUGs-adapter WotLK data and old roadmap steps 9/10; the
DB2 regeneration (TBC+WotLK), the loot difficulty/class filters, and the deletion of
`BossPinsEra.lua` are not reflected. **Fix:** refresh README status/roadmap sections.

### F8. Minor code cleanups
- `GET_ITEM_INFO_RECEIVED` watcher (`EncounterPage.lua:739`) is dead on 3.3.5 (event is
  MoP+) — delete or annotate.
- ~967 data lines carry retail `$`-tokens; `cleanBody()` strips them at render but the
  numeric values are lost ("deals $NNNNNs1 damage" → "deals damage"). Proper fix belongs in
  `tools/extract_ej.py`: resolve `$<spell>s<idx>`/`$<spell>d` against a 3.3.5 Spell.dbc
  dump at extraction time (see R6).

---

## Part 2 — Feature roadmap (retail-parity, ordered by value ÷ effort)

### R1. Deep search (the biggest missing retail feature)
Retail searches bosses, abilities and loot with a results dropdown; ours only filters
instance names in the grid. All data is local in `EJ.ej.DATA`, so this is pure Lua:
on ≥3 chars, scan instances/encounters/sections/loot names → results list (type-tagged,
capped ~20) in a dropdown under the search box → click navigates (ShowInstance/ShowBoss +
tab select). No API gaps.

### R2. Encounter-level difficulty selector
Retail's difficulty switch changes both abilities and loot. We already have: loot `diff`
bitmask + dropdown, and section flag bit 8 = Heroic. Unify into ONE selector on the
encounter page that (a) drives the existing loot buckets and (b) hides Heroic-flagged
sections on Normal / shows them highlighted on Heroic.

### R3. Tier-aware instance-select background
`UI-EJ-{Classic,BurningCrusade,WrathoftheLichKing}.blp` are already shipped; the grid bg is
hardcoded to Classic. Swap it from the active expansion/continent filter selection.

### R4. Multi-creature model switcher
Council-style bosses carry `creatures[2..n]` in the data, but the model tab always shows
`creatures[1]`. Retail shows small portrait toggle buttons — add up to 4 buttons in the
model area calling `NormalizeModel(ma, creatures[i].display)`.

### R5. Boss-kill / lockout awareness (3.3.5-native twist)
Retail shows defeated bosses. 3.3.5 has `GetSavedInstanceInfo()` (instance lockouts) and
boss-kill counts via achievement statistics (`GetStatistic`). Show a lockout line on the
instance lore page and a "defeated" check on raid bosses where a statistic exists.

### R6. Token resolution at extraction time
Extend `extract_ej.py` to resolve `$NNNNNsX` damage/duration tokens against a 3.3.5
spell-data dump (AzerothCore DB or Spell.dbc CSV) so ability text carries real numbers
like retail. Data-only change; regenerate tbc/wotlk files.

### R7. LFD integration (3.3.5-native, not retail)
On WotLK dungeon pages, a "Find Group" button that opens the 3.3.5 Dungeon Finder to that
dungeon (map journal instance → LFG dungeon ID). Small, high-delight.

### R8. Remaining art extraction (cosmetic backlog)
111 art-less bosses (mostly WotLK raids) fall back to the neutral plate; some instances use
placeholder splash art. Same extraction workflow as before; purely additive via
`Assets.lua` registration.

### R9. Boss map pins (blocked on client patch)
Encounter x/y/uiMapID are already baked from `JournalEncounterXMapLoc`, but stock 3.3.5
ships no dungeon-map art, so "Show Map" opens an empty map. When the planned client patch
adds map art, render pins from the baked coords — addon-side prep is a small data provider
in `Core/WorldMap.lua`.

### R10. Skin decision
The Dragonflight skin is a stub (DF flat-atlas art doesn't exist on 3.3.5). Decide: finish
it (large art-extraction effort) or de-scope to classic-only and remove the toggle +
`Core/Skin.lua` reload prompt. Recommendation: de-scope until everything else ships.

### Explicitly out of scope (documented decisions)
- **Overview tab** — retail Overview sections are Cata+ data; none exist for these tiers.
- **Suggested-content home page, item-set browser** — retail-era systems with no 3.3.5 data.
- **`|Hjournal:` chat links** — the 3.3.5 client can't render the hyperlink type; loot item
  shift-click linking already works once an item is cached.
- **Minimap button** — user decision: never.

### Suggested order
F1–F3 (quick wins) → F4 verification session → R1 → R2 → R3+R4 → F5–F7 packaging/docs →
R5–R8 as content polish → R9/R10 when their blockers resolve.
