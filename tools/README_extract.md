# Encounter Journal Daten-Extraktor (DB2 → native `*_data.lua`)

Rekonstruiert das verlorene `tools/extract_ej.py`. Erzeugt aus Blizzards
Encounter-Journal-DB2-Tabellen die native `EJ.ej.DATA`-Form (wie
`EncounterJournal/vanilla_data.lua`) — pro Tier eine Datei.

## 1. DB2-CSVs besorgen (wago.tools)

Gehe auf <https://wago.tools/db2>, wähle oben einen **Retail-Build** (irgendein
moderner Build hat alle Classic/TBC/WotLK-Journal-Daten — z.B. der im Vanilla-Header
genannte `12.0.5.67451`), und exportiere jede Tabelle als **CSV** (Button „Export → CSV",
Locale **enUS**). Lege sie in `tools/db2/`:

| Datei (→ `tools/db2/`)        | Liefert                                                        | Pflicht |
|-------------------------------|---------------------------------------------------------------|---------|
| `JournalInstance.csv`         | Instanz: id, name, desc, mapID, bg/button/lore-FDID           | ✅      |
| `JournalEncounter.csv`        | Bosse: id, name, desc, order, rootSection, uiMapID, instanceID| ✅      |
| `JournalEncounterSection.csv` | Ability-Baum: title, body, parent/child/sib, icon, spell, flags| ✅      |
| `JournalEncounterCreature.csv`| Modelle: CreatureDisplayInfoID + Portrait-FDID pro Boss       | ✅      |
| `JournalTierXInstance.csv`    | ordnet Instanzen ihren Tiers zu (= der Expansion-Filter)      | ✅      |
| `JournalTier.csv`             | Tier-Namen (Classic / Burning Crusade / Wrath …) — nur Lookup | ✅      |
| `Map.csv`                     | `InstanceType` → unterscheidet Raid (2) von Dungeon (1)       | ⬚ empf. |

> Spaltennamen variieren leicht je Build — der Extractor matcht tolerant
> (mehrere Kandidaten + Substring-Fallback) und meldet, wenn eine Pflicht-Spalte fehlt.

## 2. Loot (Drop-%)

Item-LISTE + DIFFICULTY kommen aus **DB2** (`JournalEncounterItem` per JournalEncounterID an den
Boss gejoint = 100% Abdeckung; `JournalItemXDifficulty` = die Schwierigkeiten je Item). Name+
Qualität+Drop-% kommen aus **AtlasLoot per itemID** (`atlasloot.item_index`, via `--loot <tierfile>`:
OriginalWoW/BurningCrusade/Wrath `*.lua`). Items, die AtlasLoot nicht kennt, laden im Client live
über GetItemInfo (Auto-Poller). Eingebacken **inline pro Boss**:
`loot = { {id=,pct=,q=,diff=MASK,name=""}, … }`.

`diff` = kleine Bitmaske, Bit b gesetzt = droppt auf Bucket b: **1 Normal / 2 Heroisch** (5-Mann),
**3 10N / 4 25N / 5 10H / 6 25H** (Raid); **0 = keine Difficulty-Info → immer sichtbar**. DB2-
DifficultyID→Bucket filtert Retail-Rauschen (23 Mythic, 24/33 Timewalking raus; 14→Normal nur als
TBC-Raid-Fallback). `_mask_loot_for_instance` begrenzt dann per isRaid (Dungeons 1/2, Raids 3-6),
damit quer-getaggte Items (z.B. ein Nexus-Item das DB2 auch als 25N führt) nicht durchschlagen.
(Der alte Boss-Namen-Join `atlasloot.build_loot` bleibt im Modul, wird aber nicht mehr genutzt.)

> **WICHTIG — Classic NICHT aus DB2 regenerieren.** Blizzards Tier „Classic" (68) spiegelt die
> **Cataclysm-überarbeiteten** Dungeons (Deadmines: Glubtok/Vanessa VanCleef; SFK: Ashbury/
> Walden/Godfrey …), NICHT die 3.3.5-Roster. `vanilla_data.lua` ist bewusst aus cmangos
> (3.3.5-genau) gebaut und bleibt so. Nur **TBC (70) + WotLK (72)** sind DB2-rein, weil deren
> Dungeons in Cata nicht überarbeitet wurden.

## 3. Benutzung

```bash
PY="/c/Users/timdi/AppData/Local/Programs/Python/Python313/python"
AL="References/AtlasLoot_ChromieCraft-master"

# a) Tier-IDs auflisten:  Classic=68, Burning Crusade=70, Wrath=72
$PY tools/extract_ej.py --tiers

# b) TBC erzeugen (mit Loot + Boss-Map-Positionen):
$PY tools/extract_ej.py --tier 70 --marker _tbc --minlevel 60 \
    --loot $AL/AtlasLoot_BurningCrusade/burningcrusade.lua \
    --out EncounterJournal/tbc_data.lua

# c) WotLK erzeugen (ersetzt die AzerPUGs-Version; Dedup-by-ID verdrängt Classic-Naxx/Onyxia):
$PY tools/extract_ej.py --tier 72 --marker _wotlk --minlevel 70 \
    --loot $AL/AtlasLoot_WrathoftheLichKing/wrathofthelichking.lua \
    --out EncounterJournal/wotlk_data.lua
```

CSVs liegen in `tools/db2/` (von `daten/` gestaged; `Map.csv` separat, da `daten/` keins hat).
`JournalEncounterXMapLoc` füllt Boss-Positionen (x/y/uiMapID); fehlende Art-FDIDs fängt
`EncounterJournal/art_fallback.lua` mit neutralem Platzhalter ab.

## 4. Feld-Zuordnung (DB2-Spalte → native Lua)

```
instance.id        ← JournalInstance.ID
instance.name      ← JournalInstance.Name_lang
instance.desc      ← JournalInstance.Description_lang
instance.mapID     ← JournalInstance.MapID
instance.bgFDID    ← JournalInstance.BackgroundFileDataID
instance.buttonFDID← JournalInstance.ButtonFileDataID
instance.loreFDID  ← JournalInstance.LoreFileDataID
instance.isRaid    ← Map[mapID].InstanceType == 2   (sonst false)

encounter.id       ← JournalEncounter.ID
encounter.name     ← JournalEncounter.Name_lang
encounter.desc     ← JournalEncounter.Description_lang
encounter.order    ← JournalEncounter.OrderIndex
encounter.rootSection ← JournalEncounter.FirstSectionID
encounter.uiMapID  ← JournalEncounter.UiMapID  (0 falls fehlend)
  (Zuordnung Boss→Instanz über JournalEncounter.JournalInstanceID)

section.id    ← JournalEncounterSection.ID
section.title ← .Title_lang        section.body  ← .BodyText_lang
section.parent← .ParentSectionID   section.child ← .FirstChildSectionID
section.sib   ← .NextSiblingSectionID   section.order ← .OrderIndex
section.icon  ← .IconFileDataID    section.spell ← .SpellID
section.flags ← .Flags             section.cdisp ← .IconCreatureDisplayInfoID
  (Zuordnung Section→Boss über JournalEncounterSection.JournalEncounterID)

creature.display ← JournalEncounterCreature.CreatureDisplayInfoID
creature.name    ← JournalEncounterCreature.Name_lang
creature.file    ← JournalEncounterCreature.FileDataID  (0/Platzhalter falls fehlend)
```

Art-FDIDs (bg/button/lore) sind Retail-FileDataIDs — auf 3.3.5a fehlt die Datei →
rendert den Platzhalter (siehe `DataWotlk`-`placehold`-Mechanik / Port-Status).
Boss-Modelle laufen über `display` (CreatureDisplayInfoID) via `PlayerModel:SetDisplayInfo`.
