#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
convert_icons.py - ersetzt retail Icon-FileDataIDs (icon=NNNNN) in den
*_data.lua-Dateien durch echte 3.3.5-Texturpfade ("Interface\\Icons\\name"),
anhand der FDID->Pfad-Map in icon_ids.lua (WeakAuras ArtTexturePaths).

Grund: 3.3.5a kann Texturen NICHT per numerischer FileDataID laden
(SetTexture(136041) zeigt nichts) - nur per Pfad. Konvertiert wird ausschliesslich
das `icon=`-Feld der Ability-Sections; icon=0 bleibt 0; FDIDs ohne Map-Eintrag
bleiben unveraendert (und werden gemeldet).

Beispiel:
    icon=136041   ->   icon="Interface\\icons\\spell_nature_healingtouch"

Benutzung:
    PY=/c/Users/timdi/AppData/Local/Programs/Python/Python313/python
    # Vorschau (schreibt nichts, zeigt Statistik):
    $PY tools/convert_icons.py EncounterJournal/vanilla_data.lua
    # In-place ersetzen (legt .bak an):
    $PY tools/convert_icons.py EncounterJournal/vanilla_data.lua --write
    # Mehrere Dateien:
    $PY tools/convert_icons.py EncounterJournal/vanilla_data.lua EncounterJournal/wotlk_data.lua --write
"""

import argparse
import os
import re
import sys

# Felder, deren numerischer Icon-FDID konvertiert wird. (key, regex) — der Regex
# fasst den Praefix bis zum '=' in Gruppe 1 und die FDID-Zahl in Gruppe 2.
ICON_FIELDS = [
    ("icon",        re.compile(r"(\bicon\s*=\s*)(\d+)")),                 # vanilla native:  icon=136041
    ("abilityIcon", re.compile(r"(\[\"abilityIcon\"\]\s*=\s*)(\d+)")),    # wotlk AZP-Quelle: ["abilityIcon"] = 135990
]
MAP_LINE = re.compile(r"\[(\d+)\]\s*=\s*\"([^\"]*)\"")
PREFIX = "Interface\\\\"  # = literal  Interface\\  (Lua-escaped backslash)


def load_icon_map(path):
    """icon_ids.lua -> {fdid:int -> 'icons\\\\name' (bereits Lua-escaped)}."""
    if not os.path.exists(path):
        raise SystemExit(f"icon_ids.lua nicht gefunden: {path}")
    out = {}
    with open(path, "r", encoding="utf-8") as f:
        for line in f:
            m = MAP_LINE.search(line)
            if m:
                out[int(m.group(1))] = m.group(2)
    if not out:
        raise SystemExit(f"Keine [id]=\"path\" Eintraege in {path} gefunden.")
    return out


def convert_text(text, icon_map):
    stats = {"converted": 0, "zero": 0, "missing": 0}
    missing = {}

    def make_repl():
        def repl(m):
            prefix, num = m.group(1), int(m.group(2))
            if num == 0:
                stats["zero"] += 1
                return m.group(0)              # ...=0 bleibt 0
            path = icon_map.get(num)
            if path is None:
                stats["missing"] += 1
                missing[num] = missing.get(num, 0) + 1
                return m.group(0)              # unbekannt -> unveraendert lassen
            stats["converted"] += 1
            return f'{prefix}"{PREFIX}{path}"'
        return repl

    new_text = text
    for _key, pat in ICON_FIELDS:
        new_text = pat.sub(make_repl(), new_text)
    return new_text, stats, missing


def main():
    ap = argparse.ArgumentParser(description="retail Icon-FDIDs -> 3.3.5 Texturpfade")
    ap.add_argument("files", nargs="+", help="zu konvertierende *_data.lua Datei(en)")
    ap.add_argument("--icon-ids",
                    default=os.path.join(os.path.dirname(os.path.abspath(__file__)), "icon_ids.lua"),
                    help="Pfad zu icon_ids.lua (Standard: tools/icon_ids.lua neben diesem Skript)")
    ap.add_argument("--write", action="store_true",
                    help="Datei in-place ersetzen (legt .bak an). Ohne Flag: nur Vorschau.")
    args = ap.parse_args()

    icon_map = load_icon_map(args.icon_ids)
    print(f"icon_ids.lua: {len(icon_map)} FDID->Pfad Eintraege geladen\n")

    for path in args.files:
        if not os.path.exists(path):
            print(f"!! uebersprungen (fehlt): {path}")
            continue
        text = open(path, "r", encoding="utf-8").read()
        new_text, stats, missing = convert_text(text, icon_map)
        print(f"{path}")
        print(f"  konvertiert={stats['converted']}  icon=0 belassen={stats['zero']}  "
              f"unbekannt={stats['missing']}")
        if missing:
            top = sorted(missing.items(), key=lambda kv: -kv[1])[:15]
            print(f"  unbekannte FDIDs (nicht in icon_ids.lua): "
                  + ", ".join(f"{fd}(x{n})" for fd, n in top))
        if args.write and stats["converted"]:
            bak = path + ".bak"
            if not os.path.exists(bak):
                with open(bak, "w", encoding="utf-8") as f:
                    f.write(text)
            with open(path, "w", encoding="utf-8") as f:
                f.write(new_text)
            print(f"  -> geschrieben (Backup: {bak})")
        elif args.write:
            print("  -> nichts zu schreiben")
        else:
            print("  -> Vorschau (nutze --write zum Ersetzen)")
        print()


if __name__ == "__main__":
    main()
