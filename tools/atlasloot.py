# -*- coding: utf-8 -*-
"""
atlasloot.py - parse AtlasLoot (ChromieCraft) data into {boss name -> [loot items]}.

AtlasLoot stores loot as `AtlasLoot_Data["TableKey"] = { {slot,itemID,icon,"=qN=Name",...,"X%"}, ... }`
and maps TableKey -> boss name in AtlasLoot/TableRegister/loottables.en.lua
(`AtlasLoot_TableNames["TableKey"] = { BabbleBoss["Boss Name"], "Module" }`).

We join those: returns { normalized_boss_name : [ {id,pct,q,name}, ... ] } so the EJ
extractor can bake loot inline per encounter (3.3.5 has no GET_ITEM_INFO_RECEIVED, so
name+quality must be baked). Multiple tables for one boss (e.g. ...HEROIC variants) are
merged, de-duplicated by itemID, preserving first-seen order.
"""
import re

def _norm(s):
    return re.sub(r"[^a-z0-9]", "", (s or "").lower())

# TableKey -> boss display name, from loottables.en.lua
def parse_tablenames(path):
    txt = open(path, encoding="utf-8").read()
    out = {}
    for m in re.finditer(r'AtlasLoot_TableNames\["([^"]+)"\]\s*=\s*\{\s*(.+?)\s*\}', txt):
        key, val = m.group(1), m.group(2)
        # first arg is BabbleBoss["X"] / AL["X"] / BabbleZone["X"] / "literal"
        mm = re.match(r'(?:BabbleBoss|BabbleZone|AL)\["([^"]+)"\]|"([^"]+)"', val)
        if mm:
            out[key] = mm.group(1) or mm.group(2)
    return out

# TableKey -> [ {id,pct,q,name} ], from a tier data file (originalwow/burningcrusade/wrath...)
def parse_data(path):
    txt = open(path, encoding="utf-8").read()
    out = {}
    for blk in re.finditer(r'AtlasLoot_Data\["([^"]+)"\]\s*=\s*\{(.*?)\n\t*\};', txt, re.S):
        key, body = blk.group(1), blk.group(2)
        items = []
        for row in re.finditer(r'\{(.*?)\}\s*;', body, re.S):
            r = row.group(1)
            mid = re.match(r'\s*\d+\s*,\s*(\d+)\s*,', r)   # {slot, itemID, ...
            if not mid:
                continue
            iid = int(mid.group(1))
            if iid == 0:
                continue                                   # section header
            mq = re.search(r'"=q(\d+)=([^"]*)"', r)        # "=qN=Name"
            if not mq:
                continue
            q, name = int(mq.group(1)), mq.group(2).strip()
            if not name or "#" in name or q == 6:          # token/header refs, gold headers
                continue
            mp = re.findall(r'"(\d+(?:\.\d+)?)%"', r)       # trailing "13.00%"
            pct = round(float(mp[-1]), 1) if mp else 0
            items.append({"id": iid, "pct": pct, "q": q, "name": name})
        if items:
            out[key] = items
    return out

# itemID -> {name, q, pct} flattened across ALL tables in a tier file. Used to enrich the
# canonical DB2 item list (JournalEncounterItem) with AtlasLoot name/quality/drop% by itemID.
# Name+quality are stable per item; for pct (which can differ N vs H) we keep the highest seen.
def item_index(data_path):
    out = {}
    for items in parse_data(data_path).values():
        for it in items:
            cur = out.get(it["id"])
            if not cur:
                out[it["id"]] = {"name": it["name"], "q": it["q"], "pct": it["pct"]}
            elif it["pct"] > cur["pct"]:
                cur["pct"] = it["pct"]
    return out


# Public: build { normalized boss name -> merged loot list } for one tier.
def build_loot(tablenames_path, data_path):
    keys2name = parse_tablenames(tablenames_path)
    data = parse_data(data_path)
    by_boss = {}
    for key, items in data.items():
        name = keys2name.get(key)
        if not name:
            continue
        nk = _norm(name)
        bucket = by_boss.setdefault(nk, {"name": name, "items": [], "seen": set()})
        for it in items:
            if it["id"] in bucket["seen"]:
                continue
            bucket["seen"].add(it["id"])
            bucket["items"].append(it)
    return {nk: b["items"] for nk, b in by_boss.items()}
