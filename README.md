# Encounter Journal for WotLK 3.3.5a (Beta)

Adventure Guide for **Wrath of the Lich King 3.3.5a**: bosses, abilities and loot for every Classic, Burning Crusade and Wrath dungeon and raid.


## Install

Copy this folder into `Interface/AddOns/`. It must be named **`EncounterJournal`**.

No other addon is required. [!!!ClassicAPI](https://gitlab.com/Tsoukie/classicapi) is optional and its shims are used when present.



## Features

### **Encounter page:** boss list, lore, abilities, loot.
  
<img width="901" height="576" alt="image" src="https://github.com/user-attachments/assets/1e6051d5-2869-43bd-828c-4219eb4605cb" />

### **Loot:** filters for class, slot and difficulty. Items load the same way as Atlasloot. This is due to 3.3.5 client limitations. Right-click an item, or "Load all items". 
  
<img width="1159" height="640" alt="image" src="https://github.com/user-attachments/assets/55b7760d-b6af-4679-9523-4523b002233d" />
  
### **Hard modes:** bonus loot under their own sub-header. Ulduar hard modes (Yogg-Saron: 1 Keeper /0 Keepers incl. Mimiron's Head), Sartharion +1/+2/+3 drakes.

<img width="881" height="592" alt="image" src="https://github.com/user-attachments/assets/7d8cf026-ce91-4026-858b-d8a96fbe0d19" />

## Usage

Open the journal with the book button on the micro menu, `/ej`, or the key binding
"Toggle Adventure Guide".

| Command | Effect |
|---|---|
| `/ej` | toggle the journal |
| `/ej help` | list the commands |
| `/ej scale <0.5-2.0>` | window size |
| `/ej resetpos` | reset the window position |
| `/ej skin classic\|dragonflight` | Wotlk or DragonUI look (reloads the UI) |
| `/ej faction auto\|all` | only your faction's bosses and loot (default), or both |

## To-do

- **Model viewer:** the Model tab is disabled for now. Havent found a way to reliable load models. 

- **Black Temple:** unfinished. Many ability sections are placeholders without name or text.
  
- **Upper Blackrock Spire:** bosses and loot are in; ability sections, boss lore and portraits are
   missing

