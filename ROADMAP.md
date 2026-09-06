# Encounter Journal 3.3.5a — State & Roadmap (updated 2026-09-05)

This file is the CURRENT plan. The 2026-07 review that seeded it (F1–F8 fixes, R1–R10 features) is
done or superseded; its history lives in git. What follows is what exists now, what is verified,
and what is next — in priority order.

## Where things stand

**Verified in the client (by the owner, 2026-09-05):**
- The journal opens, renders the NewEra-style chrome, the tier selector, grid, encounter pages.
- Boss models: `Model:SetCreature(npcID)` renders textured models (Thaddius, Gluth confirmed —
  load mode `creature`). A raw `.m2` via `SetModel` renders untextured unless the model has
  baked textures. Kel'Thuzad keeps an explicit `lich.m2` override (x=-2, scale 0.8).
- Loot right-click loading works AtlasLoot-style.

**Built today, NOT yet verified in the client:**
- Chrome details (DF metal tabs, RedButton close, MinimalScrollBar art, inset well, rock body).
- Ability icon paths (1330 converted), `item_info.lua` names/icons, loot difficulty masks
  (`loot_diff.lua`), the TBC/WotLK ability overlays, the retail-API shim (`EJApi.lua`, smoke-tested
  offline with lupa against the real data), `EJ_GetInstanceForMap` via `worldmap_ids.lua`.

**Data coverage (76 instances):**
| Tier | Instances | Bosses | Abilities | Loot difficulty | Boss npc ids (textured models) |
|---|---|---|---|---|---|
| Classic | 27 | 196 creatures | DB2 + hand-seeded (vanilla_data) | n/a (single) | all (encounter id = npc id) |
| BC | 24 | 100 | dungeons DB2, raids NewEra seed (`tbc_abilities.lua`) | dungeons N/H from AtlasLoot tags | 4 dungeon mods + all raids via DBM → ~50 dungeon bosses MISSING |
| WotLK | 25 | 122 | dungeons DB2, raids + Ulduar NewEra seed (`wotlk_abilities.lua`) | dungeons N/H, Ulduar 10/25 from AtlasLoot tags; other raids DB2 | all raids + most dungeons via DBM; ~14 event/faction encounters missing |

## Next (priority order)

1. **In-client verification pass of the 2026-09-05 chrome + data work** (the old F4). One session
   with the grid, a Classic/BC/WotLK dungeon and raid each, loot on both difficulties, the model
   tab in `creature` mode, `/ej scale`, drag/position persistence, `/ej help`.
2. **Boss npc ids for the Outland dungeons (~50) + WotLK event encounters (~14).** No local source
   has them (DBM-Party-BC ships 4 mods; NewEra/AtlasLoot/Ascension carry none). Options: an online
   `creature_template` dump (AzerothCore/TrinityCore SQL), or `/ej model npc <id>` by hand per boss.
   Until then those bosses load by display id → file (untextured) fallback.
3. **WotLK raid instance descriptions.** Blizzard never authored them (both DB2 builds empty for
   all 9 Wrath raids; no client text; no local reference has them). Decision pending: hand-written
   lore paragraphs in the DB2 tone, marked as such, or official website text supplied by the owner.
4. **Model load mode default.** A persisted `ejModelMode = "file"` (from the interim default)
   overrides the new `creature` default; consider a one-time migration once `creature` is confirmed
   to be right for every tier.
5. **Retail-API shim consumers.** `EJApi.lua` exists for Details!/DetailsFramework; wire and test
   against the actual Details port once it is installed (which functions it calls, whether it
   expects `EncounterJournal` as a frame global, `EJ_GetInstanceForMap` inputs).
6. **Remaining art (old R8):** ~86 art-less boss plates, a few instance splashes. Additive.
7. **Boss-kill / lockout awareness (old R5):** 3.3.5-native `GetSavedInstanceInfo` gives a
   defeated-bosses COUNT per lockout; per-boss needs a statistic-achievement mapping.
8. **`$spell` token resolution in DB2 ability text (old R6):** needs a 3.3.5 spell-value source
   (Spell.dbc is in the client MPQs and `mpyq` can now read them — feasible).
9. **Boss map pins (old R9)** blocked on client map art; **skin decision (old R10)** — the
   Dragonflight skin stub is still a stub; de-scope unless wanted.

## Explicitly out of scope (unchanged)
- Overview tab, suggested-content home, item-set browser (retail systems without 3.3.5 data).
- `|Hjournal:` chat links (the client can't render the type).
- Minimap button (owner decision).

## How the generated data files are made (all scratchpad scripts, all re-runnable)
| File | Source | Script |
|---|---|---|
| `EncounterJournal/*_data.lua` icon paths | `tools/icon_ids.lua` (WeakAuras ArtTexturePaths) | `tools/convert_icons.py --write` (re-run after every `extract_ej.py` regen) |
| `tbc_abilities.lua`, `wotlk_abilities.lua` | DragonUI_NewEra `AbilitiesTBC/WotLK.lua` (dev folder) | `tbcport.py`, `abilport.py` |
| `loot_diff.lua` | NewEra `DataTBC/DataWotLK.lua` AtlasLoot tags | `lootdiff.py` |
| `item_info.lua` | AtlasLoot_ChromieCraft names + client `Item.dbc`/`ItemDisplayInfo.dbc` (locale MPQ) | `iteminfo.py` (mpyq) |
| `ModelPaths.lua` | client `CreatureDisplayInfo.dbc` + `CreatureModelData.dbc` | `dbcmodels.py` (mpyq) |
| `npc_ids.lua` | installed DBM boss mods | `npcids.py` |
| `worldmap_ids.lua` | client `WorldMapArea.dbc` | `worldmap.py` (mpyq) |
| `Art/` completions | DragonUI_NewEra `Textures/` | `artcopy.py` |

Dev material (reference addons, DB2 exports, backups) lives in `c:\Games\Chromiefresh\EncounterJournal-dev\`.
