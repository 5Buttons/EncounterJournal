# Encounter Journal for WotLK 3.3.5a

A standalone Adventure Guide (Encounter Journal) for **Wrath of the Lich King 3.3.5a**: bosses,
abilities, loot and 3D models for every Classic, Burning Crusade and Wrath dungeon and raid.
3.3.5 shipped no Encounter Journal of its own (it is a Cataclysm feature); this one is ported
from the New Era addon's journal module and runs on top of the **!!!ClassicAPI** compatibility
library. Tested on an AzerothCore 3.3.5a realm.

Status: runs in the client. Last full in-client verification by the owner was 2026-09-05; the
chrome details, loot overlays, item names/icons, the retail-API shim and the file restructure
that landed after that date are compile- and data-checked offline but not yet seen in the client
(see Roadmap, item 1).

## Install

Requires **[!!!ClassicAPI](https://gitlab.com/Tsoukie/classicapi)** (Tsoukie; GitLab, the old
GitHub URL is dead), a 3.3.5a library that emulates large parts of the modern API (`C_Timer`,
`SetAtlas` + atlas DB, NineSlice, `SearchBoxTemplate`, `UIDropDownMenu` templates,
`GetPhysicalScreenSize`, `C_Item`, `C_Spell`, ...). It is declared as a hard `## Dependencies` in
the TOC, so the game will not load the journal without it. Pinned version: 1.22.

- Easiest: run `tools\package.ps1`. It stages only the shippable files into
  `dist\EncounterJournal-<version>.zip` and bundles `!!!ClassicAPI/` when a copy sits at the
  repo root (`-NoClassicAPI` skips it). Extract the zip into `World of Warcraft/Interface/AddOns/`.
- Manual: copy `!!!ClassicAPI/` and this addon into `Interface/AddOns/`. The addon folder must be
  named **`EncounterJournal`**, every art path resolves under `Interface\AddOns\EncounterJournal\`.

## Using it

**Opening the journal** (3.3.5a has no built-in button or binding for it):
- the book **micro button** on the main menu bar, next to the Main Menu button;
- `/ej`, `/encounterjournal` or `/adventureguide`;
- the key binding "Toggle Adventure Guide" under the *Encounter Journal* category.

**The window** is draggable, remembers its position, and closes with Escape.

| Command | Effect |
|---|---|
| `/ej` | toggle the journal |
| `/ej help` | list the commands in chat |
| `/ej scale <0.5-2.0>` | window size |
| `/ej resetpos` | put the window back to its default spot |
| `/ej model x\|y\|z\|facing\|scale <n>` | frame the currently shown boss model (persisted per display id) |
| `/ej model global <n>` | zoom every model |
| `/ej model npc <id>` | load this boss through `SetCreature(npcID)` |
| `/ej model path <file>\|none\|clear` | load a raw `.m2` instead of the display id |
| `/ej model display <id>\|clear` | override the display id |
| `/ej model mode creature\|file\|auto\|display` | model load strategy, see below |
| `/ej model reset` | drop the tweaks for this boss |
| `/ej skin classic\|dragonflight` | UI skin (the Dragonflight variant is a stub) |

**Instance grid.** An expansion selector (Classic / Burning Crusade / Wrath, persisted, defaults
to the character's level) picks the tier; Dungeons and Raids are the two bottom tabs. The
search box does a deep search over instances, bosses, abilities and loot names and shows a
results dropdown; Enter opens the top hit.

**Encounter page.** Boss list on the left, lore and ability sections, the loot tab and the model
tab on the right. One difficulty selector per page (Normal/Heroic for 5-mans, 10/25 for raids)
filters loot and sections. "Show Map" opens the world map at the instance (needs a client patch
that ships dungeon map art, stock 3.3.5a has none). "Find Group" opens the Dungeon Finder in
Specific-Dungeon mode with exactly this dungeon ticked (dungeons only, raids are not queueable).

**Loot.** 3.3.5a only knows an item after the server has answered a query for it, and the addon
never queries behind the player's back (item-query bursts disconnect people). Every row shows
its baked name and icon at once; an unloaded item has a red border and "Right-click to load".
Right-click queries that one item, "Load all items" under the list queries the page one item per
0.15 s. Shift-click links the item, Ctrl-click opens the dressing room. Filters: slot, class,
difficulty.

**Models.** Load mode `creature` (default) uses `Model:SetCreature(npcID)`, the standard 3.3.5
way: the client fetches the creature from the server and renders it with its skin textures and
scale. It needs the boss's npc id (Classic encounter ids are npc ids; BC/WotLK ids come from
`npc_ids.lua`). Bosses without an npc id fall back to the display id, then to the model file from
`ModelPaths.lua`, which renders untextured. `file` loads the `.m2` up front, `auto` tries the
display first, `display` never falls back. Council bosses get a portrait row to switch creatures.
Framing comes from `ModelCam.lua` plus the persisted `/ej model` tweaks.

## Repo layout

The addon folder is the git working tree and holds only what ships plus `tools/`. All reference
material (the original New Era addon, DragonUI_NewEra, AtlasLoot_ChromieCraft, DB2 exports,
backups) lives outside the game's scan path in `c:\Games\Chromiefresh\EncounterJournal-dev\`.

| Path | What it is |
|---|---|
| `EncounterJournal.toc` | load order with a comment per file |
| `Bindings.xml` | registers the `TOGGLEENCOUNTERJOURNAL` binding (labels in `Core/Core.lua`) |
| `Core/` | the `EJ.*` framework layer the journal calls into (see below) |
| `EncounterJournal/` | the journal itself: UI, data, overlays |
| `Art/` | 720 BLP/TGA files, 54 MB, all referenced by code or data |
| `tools/` | extractor, icon converter, packaging script, the DB2 CSVs they read |

**`EncounterJournal/`**

| File | Purpose |
|---|---|
| `Assets.lua` | registers and preloads every journal BLP, the texcoord slice table for the chrome sheets (`EJ.ej.ApplySlice`), the BossesGen portrait overrides, and the neutral-art fallback for unshipped FDIDs |
| `vanilla_data.lua` | Classic tier: instances, bosses, loot with drop chances, models. Generated |
| `tbc_data.lua`, `wotlk_data.lua` | BC and Wrath tiers from retail DB2, with baked loot. Generated. WotLK loads last and replaces Classic instances that share an id |
| `abilities_seed.lua` | hand-seeded ability sections for encounters the DB2 has none for: all Classic dungeons/raids, the 8 BC raids, the Wrath raids plus Ulduar (FORCE replaces the broken DB2 Ulduar entries) |
| `loot_diff.lua` | difficulty masks the DB2 left undifferentiated (Ulduar 10/25, BC and Wrath dungeon Normal/Heroic) |
| `item_info.lua` | item id to name, quality and icon for every loot item, so rows render before the item is cached |
| `ModelPaths.lua` | display id to model file (client DBCs), the untextured fallback |
| `npc_ids.lua` | encounter id to npc ids for BC/WotLK (from DBM boss mods) |
| `worldmap_ids.lua` | WorldMapArea.dbc id to Map.dbc id for the instance maps; `EJApi.lua` applies 3.3.5's off-by-one (GetCurrentMapAreaID = dbc + 1, SetMapByID = dbc) |
| `EJApi.lua` | the retail journal API (`EJ_*` globals, `C_EncounterJournal`, `EncounterJournal_OpenJournal`) re-created over the data for retail-era addons such as Details!. The window itself never calls it |
| `ModelCam.lua` | per-boss model camera defaults |
| `EncounterJournal.lua` | window shell, chrome, instance grid, tabs, openers, slash commands |
| `EncounterPage.lua` | encounter view: boss list, lore, sections, loot, model |
| `Search.lua` | deep search and the breadcrumb navbar + search box wiring |

**`Core/`** (load order as in the TOC): `Compat.lua` fills the gaps ClassicAPI leaves
(`SOUNDKIT` keys, the real `UI-Frame-Metal-*` atlas pieces from `Art/Frame/`); `Core.lua` holds
the `EJ` namespace, SavedVariables schema and binding labels; `Skin.lua` + `Options.lua` the skin
toggle and its Interface Options panel; `Modules.lua` the module registry that boots the journal
at login; `FrameUtil.lua` pixel-perfect pinning, fonts, panel sounds, Escape-close;
`PanelManager.lua` the default window slot; `TooltipWire.lua`, `Texture.lua` (`EJ.tex.SetAtlas`,
`RegisterLocal`), `AtlasData.lua` (the `EJ_ATLAS` coords for the `Art/Common/` sheets),
`Tabs.lua` (Dragonflight-style bottom tabs), `NineSlice.lua`, `PanelChrome.lua`, `Portrait.lua`,
`Dropdown.lua` (classic `UIDropDownMenu` behind a `SetupMenu`/`CreateRadio` surface),
`ScrollbarReskin.lua` (MinimalScrollBar look), `NavBar.lua` (breadcrumb widget),
`ItemButton.lua`, `WorldMap.lua` (Show Map), `LFD.lua` (Find Group).

**`Art/`**: `Common/` chrome sheets for tabs, close button, scrollbar, inset, rock body;
`Frame/` the four retail PortraitFrame metal sheets; `NavBar/` breadcrumb art;
`EncounterJournal/` the journal sheets plus `Backdrops/` (61), `Lore/` (61), `Buttons/` (27),
`Bosses/` (413) and `BossesGen/` (69 locally rendered portraits for Classic bosses retail never
drew). Files are named by their retail FileDataID; the data files reference those ids.

**`tools/`**: `extract_ej.py` (DB2 CSV to `*_data.lua`, see `tools/README_extract.md`),
`convert_icons.py` (retail icon FDIDs to `Interface\Icons\` paths, map in `icon_ids.lua`),
`atlasloot.py` (AtlasLoot parser the extractor uses for loot), `package.ps1`, `db2/` (the
retail 12.1.0 export the extractor reads).

## Data

| Tier | Instances | Encounters | Sections | Loot | Difficulty masks | Npc ids for models |
|---|---|---|---|---|---|---|
| Classic | 27 | 206 | DB2 for revamped dungeons + `abilities_seed` | AtlasLootClassic with drop % | single | all (encounter id = npc id) |
| BC | 24 | 100 | dungeons DB2, raids `abilities_seed` | DB2 + AtlasLoot | dungeons N/H from `loot_diff` | 4 dungeon mods + all raids, about 50 dungeon bosses missing |
| WotLK | 25 | 122 | dungeons DB2, raids + Ulduar `abilities_seed` | DB2 + AtlasLoot | dungeons N/H, Ulduar 10/25 from `loot_diff`, other raids DB2 | all raids + most dungeons, about 14 event/faction encounters missing |

Sources: Classic rosters and models come from cmangos, loot from AtlasLootClassic; BC and WotLK
come from the retail Encounter Journal DB2 tables (tier 70 and 72) with loot names, quality and
drop chance joined from AtlasLoot_ChromieCraft. Vanilla is deliberately not taken from DB2: the
DB2 "Classic" tier is the Cataclysm dungeon revamp, wrong for 3.3.5.

**Regenerating the DB2 tiers**

```
# run from the addon folder; the reference material sits in the dev folder next to Interface/
AL=../../../EncounterJournal-dev/References/AtlasLoot_ChromieCraft-master
python tools/extract_ej.py --tiers      # lists the JournalTier ids: Classic=68, Burning Crusade=70, Wrath=72
python tools/extract_ej.py --tier 70 --marker _tbc   --minlevel 60 --loot $AL/AtlasLoot_BurningCrusade/burningcrusade.lua         --out EncounterJournal/tbc_data.lua
python tools/extract_ej.py --tier 72 --marker _wotlk --minlevel 70 --loot $AL/AtlasLoot_WrathoftheLichKing/wrathofthelichking.lua --out EncounterJournal/wotlk_data.lua
python tools/convert_icons.py EncounterJournal/tbc_data.lua EncounterJournal/wotlk_data.lua --write
```

The current extractor regenerates only the BC and Wrath tiers; `vanilla_data.lua` is kept as is.
Run the icon converter after every extract: 3.3.5a cannot load a texture by numeric FileDataID
(it renders a red square), so every `icon=` must be a path. The overlays (`abilities_seed`,
`loot_diff`, item info, portrait overrides) only touch encounters or rows that still carry the
DB2 placeholder values, so a regen that brings real data wins automatically.

**Generator scripts that are NOT in the repo.** `abilities_seed.lua` (BC/WotLK parts),
`loot_diff.lua`, `item_info.lua`, `ModelPaths.lua`, `npc_ids.lua`, `worldmap_ids.lua` and
`ModelCam.lua` were produced by one-off scripts (`tbcport.py`, `abilport.py`, `lootdiff.py`,
`iteminfo.py` and `dbcmodels.py` over the client DBCs via `mpyq`, `npcids.py`, `worldmap.py`,
`gen_modelcam.py`) that lived in a session scratchpad and are gone. Treat those files as
hand-maintained until the scripts are recreated under `tools/`.

## How the chrome is built

The window inherits `PortraitFrameTemplate`; ClassicAPI's NineSlice draws that layout from named
atlas pieces. ClassicAPI only registers its diamond-metal look-alike, so `Core/Compat.lua`
registers the genuine `UI-Frame-Metal-*` family from the retail sheets in `Art/Frame/` with
`regAt(name, sheet, w, h, L, R, T, B, sheetW, sheetH, tileH, tileV)` (`w,h` = 1x render size,
`L,R,T,B` pixel coords, tile flags per the `_`/`!` atlas prefix):

| retail atlas id | file | holds |
|---|---|---|
| 1390 | `uiframemetal2x.blp` 512x512 | four corners and the round portrait ring |
| 1395 | `uiframemetalhorizontal2x.blp` 64x256 | top and bottom edges (horizontal tile) |
| 1394 | `uiframemetalvertical2x.blp` 512x32 | left and right edges (vertical tile, art stored upright) |
| 950 | `uiframehorizontal.blp` 256x128 | the `_UI-Frame-TopTileStreaks` band |

Everything modern that ClassicAPI lacks (Dragonflight tabs, RedButton close, MinimalScrollBar,
inset trim, rock body) is registered from `Art/Common/` sheets in `Core/AtlasData.lua`; the
`EJ_ATLAS` table there is what `EJ.tex.SetAtlas` consults first. The journal's own interior
chrome (dungeon and boss buttons, tabs, paper headers, filter bars) is legacy fixed art carved
out of the `UI-EncounterJournalTextures` sheet by texcoord; the slice table in `Assets.lua` is
transcribed from retail's `Blizzard_EncounterJournal.xml`. The circular portrait is a pre-masked
TGA, because texture masks are a no-op on 3.3.5.

To look at a BLP while working: parse the BLP2 header with Python to raw BGRA (uncompressed
`enc=3` only), then `magick -size WxH -depth 8 bgra:in.bgra out.png` (ImageMagick is installed).

## 3.3.5a gotchas

- A `UIPanelScrollFrameTemplate` frame needs a global name: Blizzard's `ScrollFrame_OnLoad` does
  `_G[self:GetName().."ScrollBar"]`.
- `parent:CreateMaskTexture()` returns nil under ClassicAPI. Guard it.
- A raw retail FileDataID with no local file renders solid red, not transparent. Every FDID the
  data references must resolve to a shipped path; `Assets.lua` maps the rest to neutral art at
  `PLAYER_LOGIN`.
- The dungeon-finder micro button is `LFDMicroButton`; the micro buttons live on
  `MainMenuBarArtFrame`, not `MainMenuBar`.
- ClassicAPI's `SearchBoxTemplate` writes the literal "Search" placeholder into the box and fires
  `OnTextChanged` for it; `EJ.ej.ReadSearchText` treats it as empty.
- A `PlayerModel` must be shown before a load lands, the engine drops loads into hidden frames.
  The 3.3.5 camera is fixed at the origin looking down +X, so framing moves the model:
  `SetPosition(x, y, z)` with larger x = further away, negative z = lower.
- `Model:SetModel(path)` renders untextured; only `SetCreature` and `SetDisplayInfo` apply skins.
- `GetSpellTexture(id)` cannot resolve an arbitrary spell id; `GetSpellInfo(id)` can, its third
  return is the icon.
- There is no `GET_ITEM_INFO_RECEIVED`; poll `GetItemInfo` after a query instead.
- Handing a texture object to `SetNormalTexture` leaves the button blank; pass a path and set the
  texcoord.
- `InterfaceOptionsFrame_OpenToCategory` must be called twice to land on the right panel.

## Known gaps

- Spell-stub sections: Blizzard's DB2 carries placeholder sections titled "Section N" with an
  empty body and only a spell id for Black Temple (118 of 193 sections), Pit of Saron (40 of 65)
  and two single bosses. They render with the right icon but no name or text. Ulduar had the same
  and is replaced by the seed. Fix candidates: resolve name and description at load through
  `GetSpellInfo` and ClassicAPI's `GetSpellDescription`, or bake them at extraction time.
- DB2 ability text carries retail `$spell` tokens; `cleanBody()` strips them, the numbers are
  lost.
- About 86 bosses have no portrait plate and use the neutral one; a few instances use placeholder
  splash art.
- About 50 Outland dungeon bosses and 14 Wrath event encounters have no npc id, so their models
  load by display id or untextured file. 160 displays are humanoid and cannot use the file path
  at all; 9 displays exist only in retail.
- Blizzard never wrote descriptions for the nine Wrath raids; they show empty lore.
- Upper Blackrock Spire is missing from the Classic data (Lower is there).
- Some models sit mis-framed until tuned with `/ej model`.
- The Dragonflight skin is a stub: its only effect is a text breadcrumb instead of the sprite one.
- "Show Map" needs a client patch with dungeon map art.

## Roadmap

1. In-client verification of everything after 2026-09-05: chrome details, a dungeon and a raid
   per tier, loot on both difficulties, the model tab in `creature` mode, `/ej scale`, window
   position persistence, the merged files.
2. Spell-stub sections (see Known gaps): resolve at load or bake at extraction.
3. Npc ids for the Outland dungeons and the Wrath event encounters. No local source has them;
   options are a `creature_template` dump (AzerothCore/TrinityCore SQL) or `/ej model npc <id>`
   by hand.
4. Core cleanup: the login popup in `Core/Core.lua` still shows New Era's early-development text
   and must go; the SavedVariables migrations seed New Era tables the journal never uses;
   `Modules.lua`, `PanelManager.lua`, `FrameUtil.lua`, `Texture.lua` and `NineSlice.lua` carry
   large amounts of framework code with no caller here.
5. Decide the `!!!ClassicAPI` vendoring: the copy at the repo root was removed from the working
   tree but the removal is not committed; `package.ps1` warns when it is absent.
6. Recreate the missing generator scripts under `tools/` (see Data).
7. Wrath raid descriptions: hand-written lore in the DB2 tone, or official text supplied by the
   owner.
8. Model load mode: a SavedVariable `ejModelMode = "file"` from the interim default overrides the
   new `creature` default; consider a one-time migration.
9. Retail-API shim consumers: wire and test `EJApi.lua` against the actual Details! port once it
   is installed.
10. Remaining art: the art-less boss plates and instance splashes. Additive.
11. `$spell` token resolution at extraction time (Spell.dbc is readable with `mpyq`).
12. Boss-kill and lockout awareness (`GetSavedInstanceInfo` gives a count per lockout; per-boss
    needs a statistic mapping); boss map pins (blocked on client map art); skin decision.

Out of scope: the retail Overview tab, suggested-content home and item-set browser (no 3.3.5
data), `|Hjournal:` chat links (the client cannot render the type), a minimap button.

## Development notes

- Everything lives under the global `EJ` table (`EJ.ej` is the journal); SavedVariables is
  `EncounterJournalDB`; frame globals are prefixed `EJ_`.
- No `luac` on the dev machine. Compile-check every shipped file with Python's `lupa`:

```python
from lupa import LuaRuntime; import glob, os
lua = LuaRuntime()
chk = lua.eval("function(src, name) local f, err = (load or loadstring)(src, name) return err end")
for f in glob.glob("Core/*.lua") + glob.glob("EncounterJournal/*.lua"):
    err = chk(open(f, "rb").read().decode("utf-8", "replace"), "@" + os.path.basename(f))
    if err: print("FAIL", f, err)
```

- The data files can also be executed under `lupa` with a stub `EJ` table to diff the resulting
  `EJ.ej.DATA` before and after a change; that is how the 2026-09-06 file merge was verified.
