-- Addon/EncounterJournal/npc_ids.lua — JournalEncounter id -> creature (NPC) ids for the TBC + WotLK
-- bosses, harvested from the installed DBM boss mods (scratchpad npcids.py: DBM:NewMod +
-- mod:SetCreatureID + the English localization names, matched to our encounters by name within the
-- tier's DBM modules). Classic needs no table: its encounter ids ARE cmangos npc ids.
-- GENERATED — regenerate rather than edit. First id = the primary creature the model tab loads via
-- Model:SetCreature(npcID), the one 3.3.5 API that brings the display's TEXTURES with it.

local EJ = _G.EJ
EJ.ej = EJ.ej or {}

EJ.ej.NPC_ID = {
  -- Magisters' Terrace
  [533] = { 19622 },  -- Kael'thas Sunstrider (DBM-TheEye)
  -- Karazhan
  [1553] = { 16151, 16152 },  -- Attumen the Huntsman (DBM-Karazhan)
  [1554] = { 15687, 19873, 19876, 17007, 19872, 19874, 19875 },  -- Moroes (DBM-Karazhan)
  [1555] = { 16457 },  -- Maiden of Virtue (DBM-Karazhan)
  [1557] = { 15691 },  -- The Curator (DBM-Karazhan)
  [1559] = { 16524 },  -- Shade of Aran (DBM-Karazhan)
  [1560] = { 15688 },  -- Terestian Illhoof (DBM-Karazhan)
  [1561] = { 15689 },  -- Netherspite (DBM-Karazhan)
  [1562] = { 21752, 21684 },  -- Chess Event (DBM-Karazhan)
  [1764] = { 21752, 21684 },  -- Chess Event (DBM-Karazhan)
  [1563] = { 15690 },  -- Prince Malchezaar (DBM-Karazhan)
  -- Gruul's Lair
  [1564] = { 18831, 18832, 18834, 18835, 18836 },  -- High King Maulgar (DBM-Gruul)
  [1565] = { 19044 },  -- Gruul the Dragonkiller (DBM-Gruul)
  -- Magtheridon's Lair
  [1566] = { 17257 },  -- Magtheridon (DBM-Magtheridon)
  -- Serpentshrine Cavern
  [1567] = { 21216 },  -- Hydross the Unstable (DBM-Serpentshrine)
  [1568] = { 21217 },  -- The Lurker Below (DBM-Serpentshrine)
  [1569] = { 21215 },  -- Leotheras the Blind (DBM-Serpentshrine)
  [1570] = { 21214 },  -- Fathom-Lord Karathress (DBM-Serpentshrine)
  [1571] = { 21213 },  -- Morogrim Tidewalker (DBM-Serpentshrine)
  [1572] = { 21212 },  -- Lady Vashj (DBM-Serpentshrine)
  -- The Eye
  [1573] = { 19514 },  -- Al'ar (DBM-TheEye)
  [1574] = { 19516 },  -- Void Reaver (DBM-TheEye)
  [1575] = { 18805 },  -- High Astromancer Solarian (DBM-TheEye)
  [1576] = { 19622 },  -- Kael'thas Sunstrider (DBM-TheEye)
  -- The Battle for Mount Hyjal
  [1577] = { 17767 },  -- Rage Winterchill (DBM-Hyjal)
  [1578] = { 17808 },  -- Anetheron (DBM-Hyjal)
  [1579] = { 17888 },  -- Kaz'rogal (DBM-Hyjal)
  [1580] = { 17842 },  -- Azgalor (DBM-Hyjal)
  [1581] = { 17968 },  -- Archimonde (DBM-Hyjal)
  -- Black Temple
  [1582] = { 22887 },  -- High Warlord Naj'entus (DBM-BlackTemple)
  [1583] = { 22898 },  -- Supremus (DBM-BlackTemple)
  [1584] = { 22841, 23191, 23215, 23216, 23523, 23318, 23524, 23319 },  -- Shade of Akama (DBM-BlackTemple)
  [1585] = { 22871 },  -- Teron Gorefiend (DBM-BlackTemple)
  [1586] = { 22948 },  -- Gurtogg Bloodboil (DBM-BlackTemple)
  [1588] = { 22947 },  -- Mother Shahraz (DBM-BlackTemple)
  [1589] = { 22949, 22950, 22951, 22952 },  -- The Illidari Council (DBM-BlackTemple)
  [1590] = { 22917, 22997 },  -- Illidan Stormrage (DBM-BlackTemple)
  -- Sunwell Plateau
  [1591] = { 24850 },  -- Kalecgos (DBM-Sunwell)
  [1592] = { 24882 },  -- Brutallus (DBM-Sunwell)
  [1593] = { 25038 },  -- Felmyst (DBM-Sunwell)
  [1594] = { 25165, 25166 },  -- The Eredar Twins (DBM-Sunwell)
  [1595] = { 25741, 25840 },  -- M'uru (DBM-Sunwell)
  [1596] = { 25315, 25588 },  -- Kil'jaeden (DBM-Sunwell)
  -- Ahn'kahet: The Old Kingdom
  [580] = { 29309 },  -- Elder Nadox (DBM-Party-WotLK)
  [581] = { 29308 },  -- Prince Taldaram (DBM-Party-WotLK)
  [582] = { 29310 },  -- Jedoga Shadowseeker (DBM-Party-WotLK)
  [583] = { 30258 },  -- Amanitar (DBM-Party-WotLK)
  [584] = { 29311 },  -- Herald Volazj (DBM-Party-WotLK)
  -- Azjol-Nerub
  [585] = { 28684 },  -- Krik'thir the Gatewatcher (DBM-Party-WotLK)
  [586] = { 28921 },  -- Hadronox (DBM-Party-WotLK)
  [587] = { 34564 },  -- Anub'arak (DBM-Coliseum)
  -- Drak'Tharon Keep
  [588] = { 26630 },  -- Trollgore (DBM-Party-WotLK)
  [589] = { 26631 },  -- Novos the Summoner (DBM-Party-WotLK)
  [590] = { 27483 },  -- King Dred (DBM-Party-WotLK)
  [591] = { 26632 },  -- The Prophet Tharon'ja (DBM-Party-WotLK)
  -- Gundrak
  [592] = { 29304 },  -- Slad'ran (DBM-Party-WotLK)
  [593] = { 29307 },  -- Drakkari Colossus (DBM-Party-WotLK)
  [594] = { 29305 },  -- Moorabi (DBM-Party-WotLK)
  [595] = { 29932 },  -- Eck the Ferocious (DBM-Party-WotLK)
  [596] = { 29306 },  -- Gal'darah (DBM-Party-WotLK)
  -- Halls of Lightning
  [597] = { 28586 },  -- General Bjarngrim (DBM-Party-WotLK)
  [598] = { 28587 },  -- Volkhan (DBM-Party-WotLK)
  [599] = { 28546 },  -- Ionar (DBM-Party-WotLK)
  [600] = { 28923 },  -- Loken (DBM-Party-WotLK)
  -- Halls of Reflection
  [601] = { 38112 },  -- Falric (DBM-Party-WotLK)
  [602] = { 38113 },  -- Marwyn (DBM-Party-WotLK)
  -- Halls of Stone
  [604] = { 27977 },  -- Krystallus (DBM-Party-WotLK)
  [605] = { 27975 },  -- Maiden of Grief (DBM-Party-WotLK)
  [607] = { 27978 },  -- Sjonnir the Ironshaper (DBM-Party-WotLK)
  -- Pit of Saron
  [608] = { 36494 },  -- Forgemaster Garfrost (DBM-Party-WotLK)
  [609] = { 36476 },  -- Ick and Krick (DBM-Party-WotLK)
  [610] = { 36658, 36661 },  -- Scourgelord Tyrannus (DBM-Party-WotLK)
  -- The Culling of Stratholme
  [611] = { 26529 },  -- Meathook (DBM-Party-WotLK)
  [612] = { 26530 },  -- Salramm the Fleshcrafter (DBM-Party-WotLK)
  [613] = { 26532 },  -- Chrono-Lord Epoch (DBM-Party-WotLK)
  [614] = { 26533 },  -- Mal'Ganis (DBM-Party-WotLK)
  -- The Forge of Souls
  [615] = { 36497 },  -- Bronjahm (DBM-Party-WotLK)
  [616] = { 36502 },  -- Devourer of Souls (DBM-Party-WotLK)
  -- The Nexus
  [618] = { 26731 },  -- Grand Magus Telestra (DBM-Party-WotLK)
  [619] = { 26763 },  -- Anomalus (DBM-Party-WotLK)
  [620] = { 26794 },  -- Ormorok the Tree-Shaper (DBM-Party-WotLK)
  [621] = { 26723 },  -- Keristrasza (DBM-Party-WotLK)
  -- The Oculus
  [622] = { 27654 },  -- Drakos the Interrogator (DBM-Party-WotLK)
  [623] = { 27447 },  -- Varos Cloudstrider (DBM-Party-WotLK)
  [624] = { 27655 },  -- Mage-Lord Urom (DBM-Party-WotLK)
  [625] = { 27656 },  -- Ley-Guardian Eregos (DBM-Party-WotLK)
  -- The Violet Hold
  [626] = { 29315 },  -- Erekem (DBM-Party-WotLK)
  [627] = { 29316 },  -- Moragg (DBM-Party-WotLK)
  [628] = { 29313 },  -- Ichoron (DBM-Party-WotLK)
  [629] = { 29266 },  -- Xevozz (DBM-Party-WotLK)
  [630] = { 29312 },  -- Lavanthor (DBM-Party-WotLK)
  [631] = { 29314 },  -- Zuramat the Obliterator (DBM-Party-WotLK)
  [632] = { 31134 },  -- Cyanigosa (DBM-Party-WotLK)
  -- Trial of the Champion
  [634] = { 34657, 34701, 34702, 34703, 34705, 35569, 35570, 35571 },  -- Grand Champions (DBM-Party-WotLK)
  [834] = { 34657, 34701, 34702, 34703, 34705, 35569, 35570, 35571 },  -- Grand Champions (DBM-Party-WotLK)
  [635] = { 35119 },  -- Eadric the Pure (DBM-Party-WotLK)
  [636] = { 34928 },  -- Argent Confessor Paletress (DBM-Party-WotLK)
  [637] = { 35451, 10000 },  -- The Black Knight (DBM-Party-WotLK)
  -- Utgarde Keep
  [638] = { 23953 },  -- Prince Keleseth (DBM-Party-WotLK)
  [639] = { 24200, 24201 },  -- Skarvald & Dalronn (DBM-Party-WotLK)
  [640] = { 23980, 23954 },  -- Ingvar the Plunderer (DBM-Party-WotLK)
  -- Utgarde Pinnacle
  [641] = { 29281 },  -- Svala Sorrowgrave (DBM-Party-WotLK)
  [642] = { 26687 },  -- Gortok Palehoof (DBM-Party-WotLK)
  [643] = { 26693 },  -- Skadi the Ruthless (DBM-Party-WotLK)
  [644] = { 26861 },  -- King Ymiron (DBM-Party-WotLK)
  -- Vault of Archavon
  [1597] = { 31125 },  -- Archavon the Stone Watcher (DBM-VoA)
  [1598] = { 33993 },  -- Emalon the Storm Watcher (DBM-VoA)
  [1599] = { 35013 },  -- Koralon the Flame Watcher (DBM-VoA)
  [1600] = { 38433 },  -- Toravon the Ice Watcher (DBM-VoA)
  -- Naxxramas
  [1601] = { 15956 },  -- Anub'Rekhan (DBM-Naxx)
  [1602] = { 15953 },  -- Grand Widow Faerlina (DBM-Naxx)
  [1603] = { 15952 },  -- Maexxna (DBM-Naxx)
  [1604] = { 15954 },  -- Noth the Plaguebringer (DBM-Naxx)
  [1605] = { 15936 },  -- Heigan the Unclean (DBM-Naxx)
  [1606] = { 16011 },  -- Loatheb (DBM-Naxx)
  [1607] = { 16061 },  -- Instructor Razuvious (DBM-Naxx)
  [1608] = { 16060 },  -- Gothik the Harvester (DBM-Naxx)
  [1609] = { 16063, 16064, 16065, 30549 },  -- The Four Horsemen (DBM-Naxx)
  [1610] = { 16028 },  -- Patchwerk (DBM-Naxx)
  [1611] = { 15931 },  -- Grobbulus (DBM-Naxx)
  [1612] = { 15932 },  -- Gluth (DBM-Naxx)
  [1613] = { 15928 },  -- Thaddius (DBM-Naxx)
  [1614] = { 15989 },  -- Sapphiron (DBM-Naxx)
  [1615] = { 15990 },  -- Kel'Thuzad (DBM-Naxx)
  -- The Obsidian Sanctum
  [1616] = { 28860 },  -- Sartharion (DBM-ChamberOfAspects)
  -- The Eye of Eternity
  [1617] = { 28859 },  -- Malygos (DBM-EyeOfEternity)
  -- Trial of the Crusader
  [1618] = { 34796, 35144, 34799, 34797 },  -- The Northrend Beasts (DBM-Coliseum)
  [1619] = { 34780 },  -- Lord Jaraxxus (DBM-Coliseum)
  [1623] = { 34564 },  -- Anub'arak (DBM-Coliseum)
  -- Icecrown Citadel
  [1624] = { 36612 },  -- Lord Marrowgar (DBM-Icecrown)
  [1625] = { 36855 },  -- Lady Deathwhisper (DBM-Icecrown)
  [1626] = { 36939, 37215, 36948, 37540 },  -- Icecrown Gunship Battle (DBM-Icecrown)
  [1627] = { 36939, 37215, 36948, 37540 },  -- Icecrown Gunship Battle (DBM-Icecrown)
  [1628] = { 37813 },  -- Deathbringer Saurfang (DBM-Icecrown)
  [1629] = { 36626 },  -- Festergut (DBM-Icecrown)
  [1630] = { 36627 },  -- Rotface (DBM-Icecrown)
  [1631] = { 36678 },  -- Professor Putricide (DBM-Icecrown)
  [1632] = { 37970, 37972, 37973 },  -- Blood Prince Council (DBM-Icecrown)
  [1633] = { 37955 },  -- Blood-Queen Lana'thel (DBM-Icecrown)
  [1634] = { 36789 },  -- Valithria Dreamwalker (DBM-Icecrown)
  [1635] = { 36853 },  -- Sindragosa (DBM-Icecrown)
  [1636] = { 36597 },  -- The Lich King (DBM-Icecrown)
  -- Ulduar
  [1637] = { 33113 },  -- Flame Leviathan (DBM-Ulduar)
  [1638] = { 33118 },  -- Ignis the Furnace Master (DBM-Ulduar)
  [1639] = { 33186 },  -- Razorscale (DBM-Ulduar)
  [1640] = { 33293 },  -- XT-002 Deconstructor (DBM-Ulduar)
  [1641] = { 32867, 32927, 32857 },  -- The Assembly of Iron (DBM-Ulduar)
  [1642] = { 32930 },  -- Kologarn (DBM-Ulduar)
  [1643] = { 33515 },  -- Auriaya (DBM-Ulduar)
  [1644] = { 32845, 32926 },  -- Hodir (DBM-Ulduar)
  [1645] = { 32865 },  -- Thorim (DBM-Ulduar)
  [1646] = { 32906 },  -- Freya (DBM-Ulduar)
  [1647] = { 33432 },  -- Mimiron (DBM-Ulduar)
  [1648] = { 33271 },  -- General Vezax (DBM-Ulduar)
  [1649] = { 33288 },  -- Yogg-Saron (DBM-Ulduar)
  [1650] = { 32871 },  -- Algalon the Observer (DBM-Ulduar)
  -- Onyxia's Lair
  [1651] = { 10184 },  -- Onyxia (DBM-Onyxia)
  -- The Ruby Sanctum
  [1652] = { 39863 },  -- Halion (DBM-ChamberOfAspects)
}
