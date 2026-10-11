# Encounter Journal for WotLK 3.3.5a (Beta)

A standalone Adventure Guide for **Wrath of the Lich King 3.3.5a**: bosses, abilities and loot for
every Classic, Burning Crusade and Wrath dungeon and raid.

## Install

Copy this folder into `Interface/AddOns/`. It must be named **`EncounterJournal`**.

No other addon is required. [!!!ClassicAPI](https://gitlab.com/Tsoukie/classicapi) is optional and
used when present.

## Usage

Open the journal with the book button on the micro menu, `/ej`, or the key binding
"Toggle Adventure Guide".

| Command | Effect |
|---|---|
| `/ej` | toggle the journal |
| `/ej help` | list the commands |
| `/ej scale <0.5-2.0>` | window size |
| `/ej resetpos` | reset the window position |
| `/ej skin classic\|dragonflight` | MoP Classic or DragonUI look (reloads the UI) |
| `/ej faction auto\|all` | only your faction's bosses and loot (default), or both |

## Features

- **Encounter page:** boss list, lore, abilities, loot. One difficulty selector per instance
  (Normal/Heroic, 10/25), "Show Map" and "Find Group" (Dungeon Finder) buttons.
- **Loot:** filters for class (class-coloured), slot and difficulty. Items load AtlasLoot-style:
  right-click a row, or "Load all items", so the addon never floods the server with item queries.
  Shift-click links, Ctrl-click opens the dressing room.
- **Hard modes:** bonus loot under its own sub-header. Ulduar hard modes (Yogg-Saron: 1 Keeper /
  0 Keepers incl. Mimiron's Head), Sartharion +1/+2/+3 drakes.
- **Faction:** split encounters (Trial of the Crusader, Trial of the Champion, Gunship Battle,
  Nexus, Karazhan Chess) and faction loot show only your faction's version.
- **ElvUI:** the journal button joins ElvUI's micro bar. Leatrix Maps positioning is respected.
- **Search:** instances, bosses, abilities and loot.

## To-do

- **Model viewer:** the Model tab is disabled for now. Many boss models, humanoids above all,
  don't load reliably on 3.3.5a.
- **Black Temple:** unfinished. Many ability sections are placeholders without name or text.
- **Upper Blackrock Spire:** bosses and loot are in; ability sections, boss lore and portraits are
  still missing (no Blizzard journal data exists for the Classic raid).

## Development

- The addon folder holds only what the client loads (`Core/`, `EncounterJournal/`, `Art/`, TOC,
  bindings). Tools and reference material live outside it in
  `c:\Games\Chromiefresh\EncounterJournal-dev\`.
- Data: `vanilla_data.lua`, `tbc_data.lua`, `wotlk_data.lua` (BC/Wrath from the retail Encounter
  Journal DB2, loot from AtlasLoot_ChromieCraft). Overlays: `abilities_seed.lua`, `LootData.lua`,
  `Faction.lua`.
- Generated blocks (between `-- BEGIN` / `-- END` markers) are rewritten by the dev folder's
  `tools/gen_faction.py` and `tools/gen_loot_groups.py`; the DB2 tiers by `tools/extract_ej.py`.
- Post-3.3.5a APIs go through the shims in `Core/Compat.lua` (`EJ.After`, `EJ.SetShown`, ...).
  The dev folder's `tools/stock335_harness/` runs the addon against a stock 3.3.5a API stub.
- No `luac` on the dev machine: compile-check with Python's `lupa` (`lua51.LuaRuntime`,
  `loadstring`).
