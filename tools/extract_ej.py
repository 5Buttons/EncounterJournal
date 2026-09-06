#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
extract_ej.py - Encounter Journal Daten-Extraktor (DB2-CSV -> native *_data.lua)

Rekonstruktion des verlorenen Original-Tools. Liest Blizzards Encounter-Journal-
DB2-Tabellen (als CSV von wago.tools exportiert) und erzeugt die native
EJ.ej.DATA-Struktur, wie sie EncounterJournal/vanilla_data.lua verwendet.

Siehe tools/README_extract.md fuer die Download-Liste und Feld-Zuordnung.

Beispiele:
    python tools/extract_ej.py --tiers
    python tools/extract_ej.py --tier 1 --validate-against EncounterJournal/vanilla_data.lua
    python tools/extract_ej.py --tier 2 --marker _tbc --out EncounterJournal/tbc_data.lua
"""

import argparse
import csv
import os
import re
import sys

csv.field_size_limit(min(sys.maxsize, 2**31 - 1))

# ---------------------------------------------------------------------------
# CSV laden + tolerante Spaltenaufloesung
# ---------------------------------------------------------------------------

def load_csv(path):
    """Liest eine DB2-CSV -> (list[dict], headers)."""
    if not os.path.exists(path):
        raise SystemExit(
            f"CSV fehlt: {path}\n  Lade sie von https://wago.tools/db2 (CSV, enUS) "
            f"nach tools/db2/ -- siehe tools/README_extract.md."
        )
    with open(path, "r", encoding="utf-8", newline="") as f:
        reader = csv.DictReader(f)
        rows = list(reader)
        headers = reader.fieldnames or []
    return rows, headers


def make_picker(headers, table_label):
    """Liefert pick(field, *candidates, required=, default=) das die erste
    passende Spalte findet (exakt, case-insensitiv, dann Substring)."""
    lower = {h.lower(): h for h in headers}

    def resolve(candidates):
        for c in candidates:
            if c in lower:
                return lower[c]
        # Substring-Fallback (z.B. "Name_lang" matcht "name_lang[enus]")
        for c in candidates:
            for hl, orig in lower.items():
                if c in hl:
                    return orig
        return None

    cache = {}

    def pick(row, candidates, required=False, default=""):
        key = tuple(candidates)
        col = cache.get(key, "missing")
        if col == "missing":
            col = resolve([c.lower() for c in candidates])
            cache[key] = col
            if col is None and required:
                raise SystemExit(
                    f"[{table_label}] Pflichtspalte nicht gefunden. Kandidaten: "
                    f"{candidates}\n  Vorhandene Spalten: {headers}"
                )
        if col is None:
            return default
        return row.get(col, default)

    return pick


def to_int(v, default=0):
    try:
        return int(float(str(v).strip()))
    except (ValueError, TypeError):
        return default


# ---------------------------------------------------------------------------
# DB2 -> Modell
# ---------------------------------------------------------------------------

def index_by(rows, pick, id_candidates):
    out = {}
    for r in rows:
        out[to_int(pick(r, id_candidates, required=True))] = r
    return out


def group_by(rows, pick, key_candidates):
    out = {}
    for r in rows:
        out.setdefault(to_int(pick(r, key_candidates)), []).append(r)
    return out


def _norm_name(s):
    return re.sub(r"[^a-z0-9]", "", (s or "").lower())


# Era-relevant Difficulty IDs → our small bucket codes (bit position in the emitted `diff` mask).
# 1 Normal(5), 2 Heroic(5), 3 10N, 4 25N, 5 10H, 6 25H. 14 = modern "Normal" flexible: only used
# as a single-difficulty fallback for TBC raids (no 10/25); ignored when real 3/4/5/6 exist.
# 23 Mythic / 24,33 Timewalking and anything else = retail noise → dropped.
RAID_BUCKETS = (3, 4, 5, 6)
DUNGEON_BUCKETS = (1, 2)
ERA_DIFFS = {1, 2, 3, 4, 5, 6, 14}   # difficulties that existed in Classic/TBC/WotLK

def build_db2_loot(db2dir, item_index):
    """{ encounterID -> [ {id,pct,q,name,diff}, ... ] } from JournalEncounterItem +
    JournalItemXDifficulty, enriched with AtlasLoot name/quality/drop% by itemID."""
    def P(n):
        return os.path.join(db2dir, n)
    if not os.path.exists(P("JournalEncounterItem.csv")):
        return None
    jei_rows, jei_h = load_csv(P("JournalEncounterItem.csv"))
    pJ = make_picker(jei_h, "JournalEncounterItem")
    diff_by_jei = {}
    if os.path.exists(P("JournalItemXDifficulty.csv")):
        ixd_rows, ixd_h = load_csv(P("JournalItemXDifficulty.csv"))
        pX = make_picker(ixd_h, "JournalItemXDifficulty")
        for r in ixd_rows:
            jeiid = to_int(pX(r, ["JournalEncounterItemID"]))
            diff_by_jei.setdefault(jeiid, set()).add(to_int(pX(r, ["DifficultyID"])))

    out = {}
    for r in jei_rows:
        jeiid = to_int(pJ(r, ["ID"], required=True))
        enc = to_int(pJ(r, ["JournalEncounterID", "EncounterID"]))
        item = to_int(pJ(r, ["ItemID"]))
        if not (enc and item):
            continue
        # Retail's journal lists items that don't exist on 3.3.5 (Timewalking/scaled rewards with
        # modern itemIDs, e.g. 127153). Drop them two ways: (a) itemID far above the WotLK ceiling;
        # (b) the item is tagged ONLY with modern difficulties (Timewalking 24/33, Mythic 23) and
        # none of the era-relevant ones — i.e. it only exists in the modern incarnation.
        if item > 80000:
            continue
        ds = diff_by_jei.get(jeiid, set())
        if ds and not (ds & ERA_DIFFS):
            continue
        buckets = {d for d in ds if d in RAID_BUCKETS or d in DUNGEON_BUCKETS}
        if not buckets and 14 in ds:
            buckets = {1}                       # TBC raids: single "Normal"
        mask = 0
        for b in buckets:
            mask |= (1 << b)                    # bit b (b in 1..6); 0 left for "no difficulty"
        meta = item_index.get(item, {})
        lst = out.setdefault(enc, [])
        existing = next((x for x in lst if x["id"] == item), None)
        if existing:
            existing["diff"] |= mask            # same item across difficulty rows → OR the masks
        else:
            lst.append({"id": item, "pct": meta.get("pct", 0), "q": meta.get("q", 0),
                        "name": meta.get("name", ""), "diff": mask})
    return out


# Constrain an encounter's loot difficulty buckets to the INSTANCE kind: dungeons keep only
# 1/2 (Normal/Heroic), raids keep only 3-6 (10/25 N/H). Strips cross-tagged noise (e.g. a 5-man
# item that DB2 also flags 25N). A raid whose items had no real 3-6 (TBC single-difficulty) ends
# up all-zero → "no difficulty" → shown always, no dropdown.
def _mask_loot_for_instance(loot, is_raid):
    keep = (3, 4, 5, 6) if is_raid else (1, 2)
    out = []
    for it in loot:
        m = 0
        for b in keep:
            if it["diff"] & (1 << b):
                m |= (1 << b)
        nit = dict(it)
        nit["diff"] = m
        out.append(nit)
    return out


def build_model(db2dir, tier_id, loot_by_enc=None):
    def P(name):
        return os.path.join(db2dir, name)

    inst_rows, inst_h = load_csv(P("JournalInstance.csv"))
    enc_rows, enc_h = load_csv(P("JournalEncounter.csv"))
    sec_rows, sec_h = load_csv(P("JournalEncounterSection.csv"))
    cre_rows, cre_h = load_csv(P("JournalEncounterCreature.csv"))
    txi_rows, txi_h = load_csv(P("JournalTierXInstance.csv"))

    # optional: boss map positions (JournalEncounterXMapLoc) -> first loc per encounter
    maploc = {}
    mloc_path = P("JournalEncounterXMapLoc.csv")
    if os.path.exists(mloc_path):
        mloc_rows, mloc_h = load_csv(mloc_path)
        pL = make_picker(mloc_h, "JournalEncounterXMapLoc")
        for r in mloc_rows:
            eid = to_int(pL(r, ["JournalEncounterID", "EncounterID"]))
            if eid and eid not in maploc:
                maploc[eid] = (
                    pL(r, ["Map_0"]), pL(r, ["Map_1"]),
                    to_int(pL(r, ["UiMapID"])),
                )

    pI = make_picker(inst_h, "JournalInstance")
    pE = make_picker(enc_h, "JournalEncounter")
    pS = make_picker(sec_h, "JournalEncounterSection")
    pC = make_picker(cre_h, "JournalEncounterCreature")
    pX = make_picker(txi_h, "JournalTierXInstance")

    # optional: Map.csv fuer isRaid
    map_insttype = {}
    map_path = P("Map.csv")
    if os.path.exists(map_path):
        map_rows, map_h = load_csv(map_path)
        pM = make_picker(map_h, "Map")
        for r in map_rows:
            map_insttype[to_int(pM(r, ["ID"], required=True))] = to_int(
                pM(r, ["InstanceType", "MapType"])
            )

    # Tier-Filter: welche JournalInstanceIDs gehoeren zu tier_id?
    wanted = set()
    for r in txi_rows:
        if to_int(pX(r, ["JournalTierID", "TierID"])) == tier_id:
            wanted.add(to_int(pX(r, ["JournalInstanceID", "InstanceID"])))
    if not wanted:
        raise SystemExit(
            f"Keine Instanzen fuer Tier {tier_id} in JournalTierXInstance gefunden. "
            f"Pruefe die Tier-ID mit --tiers."
        )

    enc_by_inst = group_by(enc_rows, pE, ["JournalInstanceID", "InstanceID"])
    sec_by_enc = group_by(sec_rows, pS, ["JournalEncounterID", "EncounterID"])
    cre_by_enc = group_by(cre_rows, pC, ["JournalEncounterID", "EncounterID"])

    instances = []
    for r in inst_rows:
        iid = to_int(pI(r, ["ID"], required=True))
        if iid not in wanted:
            continue
        mapid = to_int(pI(r, ["MapID", "DungeonMapID"]))
        inst = {
            "id": iid,
            "name": pI(r, ["Name_lang", "Name"], required=True),
            "desc": pI(r, ["Description_lang", "Description"]),
            "mapID": mapid,
            "isRaid": map_insttype.get(mapid, 0) == 2,
            "loreFDID": to_int(pI(r, ["LoreFileDataID"])),
            "bgFDID": to_int(pI(r, ["BackgroundFileDataID"])),
            "buttonFDID": to_int(pI(r, ["ButtonFileDataID"])),
            "order": to_int(pI(r, ["OrderIndex"])),
            "encounters": [],
        }

        for er in sorted(
            enc_by_inst.get(iid, []),
            key=lambda x: to_int(pE(x, ["OrderIndex"])),
        ):
            eid = to_int(pE(er, ["ID"], required=True))
            ename = pE(er, ["Name_lang", "Name"], required=True)
            mx, my, muid = maploc.get(eid, ("0", "0", 0))
            enc = {
                "id": eid,
                "name": ename,
                "desc": pE(er, ["Description_lang", "Description"]),
                "order": to_int(pE(er, ["OrderIndex"])),
                "rootSection": to_int(pE(er, ["FirstSectionID", "RootSectionID"])),
                "uiMapID": muid or to_int(pE(er, ["UiMapID", "MapID"])),
                "x": mx, "y": my,
                "loot": _mask_loot_for_instance((loot_by_enc or {}).get(eid, []), inst["isRaid"]),
                "creatures": [],
                "sections": [],
            }
            for cr in sorted(
                cre_by_enc.get(eid, []), key=lambda x: to_int(pC(x, ["OrderIndex"]))
            ):
                enc["creatures"].append({
                    "display": to_int(pC(cr, ["CreatureDisplayInfoID", "CreatureDisplayID"])),
                    "name": pC(cr, ["Name_lang", "Name"]),
                    "file": to_int(pC(cr, ["FileDataID", "FileDataID0"])),
                })
            for srow in sorted(
                sec_by_enc.get(eid, []), key=lambda x: to_int(pS(x, ["OrderIndex"]))
            ):
                enc["sections"].append({
                    "id": to_int(pS(srow, ["ID"], required=True)),
                    "title": pS(srow, ["Title_lang", "Title"]),
                    "body": pS(srow, ["BodyText_lang", "Body_lang", "BodyText"]),
                    "parent": to_int(pS(srow, ["ParentSectionID"])),
                    "child": to_int(pS(srow, ["FirstChildSectionID"])),
                    "sib": to_int(pS(srow, ["NextSiblingSectionID", "SiblingSectionID"])),
                    "order": to_int(pS(srow, ["OrderIndex"])),
                    "spell": to_int(pS(srow, ["SpellID"])),
                    "icon": to_int(pS(srow, ["IconFileDataID"])),
                    "flags": to_int(pS(srow, ["Flags"])),
                    "cdisp": to_int(pS(srow, ["IconCreatureDisplayInfoID", "CreatureDisplayInfoID"])),
                })
            inst["encounters"].append(enc)

        instances.append(inst)

    instances.sort(key=lambda i: (i["order"], i["id"]))
    return instances


# ---------------------------------------------------------------------------
# Lua-Emitter (Format wie vanilla_data.lua)
# ---------------------------------------------------------------------------

def lua_str(s):
    if s is None:
        s = ""
    s = str(s).replace("\\", "\\\\").replace('"', '\\"')
    s = s.replace("\r\n", "\\n").replace("\n", "\\n").replace("\r", "\\n")
    return '"' + s + '"'


def _coord(v):
    try:
        f = round(float(v), 4)
        return int(f) if f == int(f) else f
    except (ValueError, TypeError):
        return 0


def emit_lua(instances, marker, min_level):
    L = []
    w = L.append
    w("-- AUTO-GENERATED by tools/extract_ej.py from retail DB2.")
    w("-- DO NOT EDIT BY HAND -- re-run tools/extract_ej.py.")
    w("")
    w("local EJ = _G.EJ")
    w("EJ.ej = EJ.ej or {}")
    w("EJ.ej.DATA = EJ.ej.DATA or { instances = {} }")
    w("local INST = EJ.ej.DATA.instances")
    w("")
    w("local NEW = {")
    for inst in instances:
        raid = "true" if inst["isRaid"] else "false"
        w(f'  {{ id={inst["id"]}, name={lua_str(inst["name"])}, isRaid={raid}, minLevel={min_level},')
        w(f'    mapID={inst["mapID"]}, loreFDID={inst["loreFDID"]}, bgFDID={inst["bgFDID"]}, buttonFDID={inst["buttonFDID"]},')
        w(f'    desc={lua_str(inst["desc"])},')
        w("    encounters = {")
        for e in inst["encounters"]:
            w(f'      {{ id={e["id"]}, name={lua_str(e["name"])}, order={e["order"]},')
            w(f'        uiMapID={e["uiMapID"]}, x={_coord(e["x"])}, y={_coord(e["y"])}, rootSection={e["rootSection"]},')
            w(f'        desc={lua_str(e["desc"])},')
            cre = ", ".join(
                f'{{display={c["display"]}, file={c["file"]}, name={lua_str(c["name"])}}}'
                for c in e["creatures"]
            )
            w(f"        creatures = {{ {cre} }},")
            if e.get("loot"):
                loot = ", ".join(
                    f'{{id={it["id"]},pct={it["pct"]},q={it["q"]},'
                    f'diff={it.get("diff", 0)},name={lua_str(it["name"])}}}'
                    for it in e["loot"]
                )
                w(f"        loot = {{ {loot} }},")
            if e["sections"]:
                w("        sections = {")
                for s in e["sections"]:
                    w(
                        f'          {{ id={s["id"]}, title={lua_str(s["title"])}, parent={s["parent"]}, '
                        f'child={s["child"]}, sib={s["sib"]}, order={s["order"]}, spell={s["spell"]}, '
                        f'icon={s["icon"]}, flags={s["flags"]}, cdisp={s["cdisp"]},'
                    )
                    w(f'            body={lua_str(s["body"])} }},')
                w("        },")
            w("      },")
        w("    },")
        w("  },")
    w("}")
    w("")
    w("for _, inst in ipairs(NEW) do")
    w(f'  inst{marker_index(marker)} = true')
    w("  -- supersede any earlier-loaded instance sharing this JournalInstanceID")
    w("  -- (Blizzard reuses IDs across expansions, e.g. Naxxramas 754).")
    w("  for i = #INST, 1, -1 do if INST[i].id == inst.id then table.remove(INST, i) end end")
    w("  INST[#INST+1] = inst")
    w("end")
    w("")
    return "\n".join(L) + "\n"


def marker_index(marker):
    m = marker.lstrip("_")
    return f'["_{m}"]' if marker else '["_x"]'


# ---------------------------------------------------------------------------
# Validierung gegen bestehende *_data.lua
# ---------------------------------------------------------------------------

def scan_reference(path):
    """Zieht (id->name) Instanzen/Encounter und (id->title) Sections aus einer
    bestehenden *_data.lua via Regex. Grob, aber genug zum Abgleich."""
    txt = open(path, "r", encoding="utf-8").read()
    names = dict(re.findall(r'id=(\d+),\s*name="((?:[^"\\]|\\.)*)"', txt))
    titles = dict(re.findall(r'id=(\d+),\s*title="((?:[^"\\]|\\.)*)"', txt))
    return names, titles


def validate(instances, ref_path):
    ref_names, ref_titles = scan_reference(ref_path)
    gen_names, gen_titles = {}, {}
    for inst in instances:
        gen_names[str(inst["id"])] = inst["name"]
        for e in inst["encounters"]:
            gen_names[str(e["id"])] = e["name"]
            for s in e["sections"]:
                gen_titles[str(s["id"])] = s["title"]

    def cmp(label, ref, gen):
        ref_k, gen_k = set(ref), set(gen)
        missing = ref_k - gen_k
        extra = gen_k - ref_k
        mism = [k for k in ref_k & gen_k if ref[k] != gen[k]]
        print(f"  {label}: ref={len(ref_k)} gen={len(gen_k)} "
              f"fehlen={len(missing)} extra={len(extra)} name_diff={len(mism)}")
        for k in list(missing)[:8]:
            print(f"    FEHLT  id={k} ref={ref[k]!r}")
        for k in mism[:8]:
            print(f"    DIFF   id={k} ref={ref[k]!r} gen={gen[k]!r}")

    print("Validierung gegen", ref_path)
    cmp("instanz+boss namen", ref_names, gen_names)
    cmp("section titel", ref_titles, gen_titles)


# ---------------------------------------------------------------------------
# Tier-Liste
# ---------------------------------------------------------------------------

def list_tiers(db2dir):
    path = os.path.join(db2dir, "JournalTier.csv")
    rows, h = load_csv(path)
    p = make_picker(h, "JournalTier")
    print("Tier-IDs (JournalTier.csv):")
    for r in rows:
        print(f"  {to_int(p(r, ['ID'], required=True)):>3}  {p(r, ['Name_lang','Name'])}")


# ---------------------------------------------------------------------------

def main():
    ap = argparse.ArgumentParser(description="Encounter Journal DB2 -> native Lua")
    ap.add_argument("--db2", default="tools/db2", help="Ordner mit den DB2-CSVs")
    ap.add_argument("--tier", type=int, help="JournalTierID (siehe --tiers)")
    ap.add_argument("--tiers", action="store_true", help="JournalTier.csv auflisten und beenden")
    ap.add_argument("--marker", default="_tbc", help="Instanz-Marker, z.B. _tbc")
    ap.add_argument("--minlevel", type=int, default=60, help="Blanket minLevel (Sortierung)")
    ap.add_argument("--out", help="Ziel-Lua-Datei (Default: stdout)")
    ap.add_argument("--validate-against", help="Bestehende *_data.lua zum Abgleich")
    ap.add_argument("--loot", help="AtlasLoot-Datendatei des Tiers (originalwow/burningcrusade/wrath...) -> Loot inline einbacken")
    # Reference dumps live OUTSIDE the addon folder since 2026-09-05 (c:\Games\Chromiefresh\
    # EncounterJournal-dev\, see README "Repo layout"); the default resolves relative to the repo root.
    ap.add_argument("--loottables",
                    default="../../../EncounterJournal-dev/References/AtlasLoot_ChromieCraft-master/AtlasLoot/TableRegister/loottables.en.lua",
                    help="AtlasLoot key->boss Registrierung (Default: im EncounterJournal-dev Ordner)")
    args = ap.parse_args()

    if args.tiers:
        list_tiers(args.db2)
        return

    if args.tier is None:
        ap.error("--tier erforderlich (oder --tiers zum Auflisten)")

    loot_by_enc = None
    if args.loot:
        sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
        import atlasloot
        item_index = atlasloot.item_index(args.loot)
        loot_by_enc = build_db2_loot(args.db2, item_index)
        if loot_by_enc is None:
            print("# WARN: JournalEncounterItem.csv fehlt -> kein Loot", file=sys.stderr)
        else:
            print(f"# DB2-Loot: {len(loot_by_enc)} Encounter, "
                  f"AtlasLoot-Namen fuer {len(item_index)} Items", file=sys.stderr)

    instances = build_model(args.db2, args.tier, loot_by_enc)
    if loot_by_enc is not None:
        matched = sum(1 for i in instances for e in i["encounters"] if e.get("loot"))
        total = sum(len(i["encounters"]) for i in instances)
        print(f"# Loot zugeordnet: {matched}/{total} Bosse", file=sys.stderr)
    print(f"# {len(instances)} Instanzen, "
          f"{sum(len(i['encounters']) for i in instances)} Bosse, "
          f"{sum(len(e['sections']) for i in instances for e in i['encounters'])} Sections",
          file=sys.stderr)

    if args.validate_against:
        validate(instances, args.validate_against)
        return

    lua = emit_lua(instances, args.marker, args.minlevel)
    if args.out:
        with open(args.out, "w", encoding="utf-8") as f:
            f.write(lua)
        print(f"# geschrieben: {args.out}", file=sys.stderr)
    else:
        sys.stdout.write(lua)


if __name__ == "__main__":
    main()
