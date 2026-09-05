-- Addon/EncounterJournal/ModelPaths.lua — creature display id -> model file, read straight out of
-- THIS client's CreatureDisplayInfo.dbc + CreatureModelData.dbc (scratchpad dbcmodels.py over the
-- Data\*.MPQ archives in load order; display table from patch-y.mpq, model table from patch-y.mpq).
-- GENERATED — regenerate rather than edit. Covers every display id the journal data references.
--
-- Used by EncounterPage.lua as the AUTOMATIC fallback when Model:SetDisplayInfo(id) leaves the
-- pane empty (the Kel'Thuzad case): the raw .m2 goes through Model:SetModel(path) instead.
-- `scale` is CreatureDisplayInfo.CreatureModelScale (SetDisplayInfo applies it, SetModel does not,
-- so the fallback multiplies it in). `humanoid` marks displays that dress a shared character
-- model via CreatureDisplayInfoExtra (armor/skin) — SetModel(path) would show a bare base body,
-- so those are NOT auto-substituted; they can still be forced with /ej model path.

local EJ = _G.EJ
EJ.ej = EJ.ej or {}

EJ.ej.MODEL_PATH_DB = {
  [11611] = { path = "Creature\\Troglodyte\\Troglodyte.m2", scale = 1 },  -- Oggleflint
  [7970] = { path = "Creature\\FelGuard\\FelGuard.m2", scale = 1.5 },  -- Taragaman the Hungerer
  [11429] = { path = "Character\\Orc\\Male\\OrcMale.m2", scale = 1, humanoid = true },  -- Jergosh the Invoker
  [2007] = { path = "Creature\\Satyr\\Satyr.m2", scale = 1 },  -- Bazzalan
  [4313] = { path = "Character\\NightElf\\Female\\NightElfFemale.m2", scale = 1, humanoid = true },  -- Lady Anacondra
  [4214] = { path = "Character\\NightElf\\Male\\NightElfMale.m2", scale = 1.2, humanoid = true },  -- Lord Pythas
  [4213] = { path = "Character\\NightElf\\Male\\NightElfMale.m2", scale = 1.2, humanoid = true },  -- Lord Cobrahn
  [5126] = { path = "Creature\\SeaTurtle\\SeaTurtle.m2", scale = 1 },  -- Kresh
  [4203] = { path = "Creature\\ThunderLizard\\ThunderLizard.m2", scale = 1 },  -- Skum
  [4215] = { path = "Character\\NightElf\\Male\\NightElfMale.m2", scale = 1.2, humanoid = true },  -- Lord Serpentis
  [4256] = { path = "Creature\\BogBeast\\BogBeast.m2", scale = 4.5 },  -- Verdan the Everliving
  [4088] = { path = "Creature\\Murloc\\Murloc.m2", scale = 4 },  -- Mutanus the Devourer
  [14403] = { path = "Creature\\Ogre\\Ogre.m2", scale = 1.15 },  -- Rhahk'Zor
  [7125] = { path = "Character\\Goblin\\Male\\GoblinMale.m2", scale = 1, humanoid = true },  -- Sneed
  [7124] = { path = "Character\\Goblin\\Male\\GoblinMale.m2", scale = 1.5, humanoid = true },  -- Gilnid
  [2026] = { path = "Character\\Tauren\\Male\\TaurenMale.m2", scale = 1.2, humanoid = true },  -- Mr. Smite
  [7113] = { path = "Character\\Goblin\\Male\\GoblinMale.m2", scale = 1.5, humanoid = true },  -- Captain Greenskin
  [2029] = { path = "Character\\Human\\Male\\HumanMale.m2", scale = 1.2, humanoid = true },  -- Edwin VanCleef
  [1305] = { path = "Creature\\Murloc\\Murloc.m2", scale = 1.3 },  -- Cookie
  [524] = { path = "Creature\\Worgen\\Worgen.m2", scale = 1.15 },  -- Rethilgore
  [3222] = { path = "Character\\Human\\Male\\HumanMale.m2", scale = 1.2, humanoid = true },  -- Baron Silverlaine
  [3223] = { path = "Character\\Human\\Male\\HumanMale.m2", scale = 1, humanoid = true },  -- Commander Springvale
  [522] = { path = "Creature\\Worgen\\Worgen.m2", scale = 1.3 },  -- Odo the Blindwatcher
  [2352] = { path = "Creature\\DireWolf\\DireWolf.m2", scale = 2 },  -- Fenrus the Devourer
  [11179] = { path = "Creature\\Worgen\\Worgen.m2", scale = 1.5 },  -- Wolf Master Nandos
  [2353] = { path = "Character\\Human\\Male\\HumanMale.m2", scale = 1.2, humanoid = true },  -- Archmage Arugal
  [5027] = { path = "Creature\\SeaTurtle\\SeaTurtle.m2", scale = 1.5 },  -- Ghamoo-ra
  [4979] = { path = "Creature\\NagaFemale\\Siren.m2", scale = 1.3 },  -- Lady Sarevess
  [1773] = { path = "Creature\\Murloc\\Murloc.m2", scale = 2 },  -- Gelihast
  [4939] = { path = "Character\\Orc\\Male\\OrcMale.m2", scale = 1.2, humanoid = true },  -- Twilight Lord Kelris
  [1816] = { path = "Creature\\threshadon\\Threshadon.m2", scale = 1.3 },  -- Old Serra'kis
  [2837] = { path = "Creature\\Hydra\\Hydra.m2", scale = 2 },  -- Aku'mai
  [6533] = { path = "Creature\\Troglodyte\\Troglodyte.m2", scale = 1.5 },  -- Grubbis
  [5497] = { path = "Creature\\WATERELEMENTAL\\WaterElemental.m2", scale = 1.3 },  -- Viscous Fallout
  [6915] = { path = "Creature\\GnomeSpidertank\\GnomeSpiderTank.m2", scale = 1.2 },  -- Electrocutioner 6000
  [6774] = { path = "Creature\\GNOMESPIDERTANK\\GnomeBot.m2", scale = 1.1 },  -- Crowd Pummeler 9-60
  [6980] = { path = "Creature\\GnomeSpidertank\\GnomePounder.m2", scale = 1 },  -- Mekgineer Thermaplugg
  [517] = { path = "Creature\\OrcMaleWarriorLight\\OrcMaleWarriorLight.m2", scale = 1.2 },  -- Targorr the Dread
  [825] = { path = "Character\\Dwarf\\Male\\DwarfMale.m2", scale = 1, humanoid = true },  -- Kam Deepfury
  [3250] = { path = "Creature\\Ogre\\OgreMage.m2", scale = 1 },  -- Hamhock
  [1621] = { path = "Character\\Human\\Male\\HumanMale.m2", scale = 1, humanoid = true },  -- Bazil Thredd
  [2149] = { path = "Character\\Human\\Male\\HumanMale.m2", scale = 1, humanoid = true },  -- Dextren Ward
  [2142] = { path = "Character\\Dwarf\\Male\\DwarfMale.m2", scale = 1, humanoid = true },  -- Bruegal Ironknuckle
  [6110] = { path = "Creature\\Quillboar\\QuillBoarCaster.m2", scale = 1.2 },  -- Roogug
  [6097] = { path = "Creature\\Quillboar\\QuillBoar.m2", scale = 1.5 },  -- Aggem Thorncurse
  [4644] = { path = "Creature\\Quillboar\\QuillBoarWarrior.m2", scale = 1.5 },  -- Death Speaker Jargba
  [4652] = { path = "Creature\\Quillboar\\QuillBoarWarrior.m2", scale = 1.6 },  -- Overlord Ramtusk
  [2450] = { path = "Creature\\Boar\\Boar.m2", scale = 3 },  -- Agathelos the Raging
  [4642] = { path = "Creature\\Quillboar\\QuillBoarCaster.m2", scale = 1.4 },  -- Charlga Razorflank
  [2044] = { path = "Character\\Human\\Male\\HumanMale.m2", scale = 1, humanoid = true },  -- Interrogator Vishas
  [11396] = { path = "Creature\\SkeletonMage\\SkeletonMage.m2", scale = 1.3 },  -- Bloodmage Thalnos
  [2040] = { path = "Character\\Human\\Male\\HumanMale.m2", scale = 1, humanoid = true },  -- Houndmaster Loksey
  [5266] = { path = "Character\\Human\\Male\\HumanMale.m2", scale = 1.25, humanoid = true },  -- Arcanist Doan
  [2041] = { path = "Character\\Human\\Male\\HumanMale.m2", scale = 1.3, humanoid = true },  -- Herod
  [2042] = { path = "Character\\Human\\Male\\HumanMale.m2", scale = 1.2, humanoid = true },  -- Scarlet Commander Mograine
  [2043] = { path = "Character\\Human\\Female\\HumanFemale.m2", scale = 1.25, humanoid = true },  -- High Inquisitor Whitemane
  [2605] = { path = "Character\\Scourge\\Male\\ScourgeMale.m2", scale = 1, humanoid = true },  -- High Inquisitor Fairbanks
  [5945] = { path = "Creature\\Troglodyte\\Troglodyte.m2", scale = 1.5 },  -- Revelosh
  [5710] = { path = "Character\\Dwarf\\Male\\DwarfMale.m2", scale = 1, humanoid = true },  -- The Lost Dwarves
  [6089] = { path = "Creature\\TitanFemale\\TitanFemale.m2", scale = 1.2 },  -- Ironaya
  [10798] = { path = "Creature\\GolemStone\\GolemStone.m2", scale = 1.3 },  -- Ancient Stone Keeper
  [6059] = { path = "Character\\Dwarf\\Male\\DwarfMale.m2", scale = 1, humanoid = true },  -- Galgann Firehammer
  [11165] = { path = "Creature\\Troglodyte\\Troglodyte.m2", scale = 2 },  -- Grimlok
  [5988] = { path = "Creature\\StoneKeeper\\StoneKeeper.m2", scale = 1.5 },  -- Archaedas
  [7845] = { path = "Creature\\CryptFiend\\CryptFiend.m2", scale = 2.5 },  -- Tuten'kash
  [8055] = { path = "Creature\\SkeletonNaked\\SkeletonNaked.m2", scale = 2 },  -- Mordresh Fire Eye
  [7864] = { path = "Creature\\FleshGolem\\FleshGolem.m2", scale = 1.45 },  -- Glutton
  [6124] = { path = "Creature\\Quillboar\\QuillBoar.m2", scale = 1.5 },  -- Plaguemaw the Rotting
  [11382] = { path = "Creature\\Quillboar\\QuillBoar.m2", scale = 2 },  -- Ragglesnout
  [7971] = { path = "Creature\\Lich\\Lich.m2", scale = 1.25 },  -- Amnennar the Coldbringer
  [11172] = { path = "Creature\\WATERELEMENTAL\\WaterElemental.m2", scale = 2 },  -- Noxxion
  [12389] = { path = "Creature\\Lasher\\Lasher.m2", scale = 2.5 },  -- Razorlash
  [12334] = { path = "Creature\\Satyr\\Satyr.m2", scale = 2 },  -- Lord Vyletongue
  [12350] = { path = "Creature\\KeeperOfTheGrove\\KeeperOfTheGrove.m2", scale = 1.3 },  -- Celebras the Cursed
  [12293] = { path = "Creature\\MountainGiant\\MountainGiant.m2", scale = 1.6 },  -- Landslide
  [13589] = { path = "Creature\\Crocodile\\Crocodile.m2", scale = 3 },  -- Rotgrip
  [12292] = { path = "Creature\\Tharazun\\Tharazun.m2", scale = 2 },  -- Princess Theradras
  [6696] = { path = "Character\\Troll\\Male\\TrollMale.m2", scale = 1, humanoid = true },  -- Theka the Martyr
  [6685] = { path = "Character\\Troll\\Female\\TrollFemale.m2", scale = 1, humanoid = true },  -- Hydromancer Velratha
  [7353] = { path = "Character\\Troll\\Male\\TrollMale.m2", scale = 1, humanoid = true },  -- Antu'sul
  [6434] = { path = "Character\\Troll\\Male\\TrollMale.m2", scale = 1, humanoid = true },  -- Witch Doctor Zum'rah
  [7271] = { path = "Creature\\Hydra\\Hydra.m2", scale = 3 },  -- Gahz'rilla
  [6690] = { path = "Character\\Troll\\Male\\TrollMale.m2", scale = 1.1, humanoid = true },  -- Nekrum & Sezz'ziz
  [6439] = { path = "Character\\Troll\\Male\\TrollMale.m2", scale = 1.2, humanoid = true },  -- Chief Ukorz Sandscalp
  [7534] = { path = "Creature\\Gargoyle\\Gargoyle.m2", scale = 1 },  -- Kirtonos the Herald
  [11073] = { path = "Character\\Human\\Female\\HumanFemale.m2", scale = 1.25, humanoid = true },  -- Jandice Barov
  [12073] = { path = "Creature\\BoneGolem\\BoneGolem.m2", scale = 2 },  -- Rattlegore
  [10248] = { path = "Character\\Scourge\\Male\\ScourgeMale.m2", scale = 1.3, humanoid = true },  -- Marduk Blackpool
  [2606] = { path = "Creature\\SkeletonMage\\SkeletonMage.m2", scale = 1.5 },  -- Vectus
  [7919] = { path = "Creature\\Lich\\Lich.m2", scale = 1.5 },  -- Ras Frostwhisper
  [11069] = { path = "Creature\\HighElf\\HighElfFemale_Mage.m2", scale = 1 },  -- Instructor Malicia
  [10901] = { path = "Character\\Human\\Male\\HumanMale.m2", scale = 1, humanoid = true },  -- Doctor Theolen Krastinov
  [11492] = { path = "Creature\\Zombie\\Zombie.m2", scale = 1.75 },  -- Lorekeeper Polkelt
  [10433] = { path = "Creature\\Wight\\Wight.m2", scale = 1 },  -- The Ravenian
  [11072] = { path = "Character\\Human\\Male\\HumanMale.m2", scale = 1.75, humanoid = true },  -- Lord Alexei Barov
  [11835] = { path = "Character\\Human\\Female\\HumanFemale.m2", scale = 1.25, humanoid = true },  -- Lady Illucia Barov
  [11070] = { path = "Character\\Human\\Male\\HumanMale.m2", scale = 1.5, humanoid = true },  -- Darkmaster Gandling
  [8761] = { path = "Character\\Human\\Female\\HumanFemale.m2", scale = 1.2, humanoid = true },  -- High Interrogator Gerstahn
  [5781] = { path = "Creature\\ElementalEarth\\ElementalEarth.m2", scale = 1.15 },  -- Lord Roccor
  [9212] = { path = "Character\\Dwarf\\Male\\DwarfMale.m2", scale = 1, humanoid = true },  -- Houndmaster Grebmar
  [9329] = { path = "Character\\Dwarf\\Male\\DwarfMale.m2", scale = 1, humanoid = true },  -- Ring of Law
  [8762] = { path = "Character\\Tauren\\Male\\TaurenMale.m2", scale = 1, humanoid = true },  -- Pyromancer Loregrain
  [1204] = { path = "Creature\\FireElemental\\FireElemental.m2", scale = 1.5 },  -- Lord Incendius
  [9089] = { path = "Character\\Dwarf\\Male\\DwarfMale.m2", scale = 1.2, humanoid = true },  -- Warder Stilgiss
  [8704] = { path = "Character\\Dwarf\\Male\\DwarfMale.m2", scale = 1, humanoid = true },  -- Fineous Darkvire
  [12162] = { path = "Creature\\MountainGiant\\MountainGiant.m2", scale = 1.75 },  -- Bael'Gar
  [8756] = { path = "Character\\Dwarf\\Male\\DwarfMale.m2", scale = 1.25, humanoid = true },  -- General Angerforge
  [8759] = { path = "Character\\Dwarf\\Male\\DwarfMale.m2", scale = 1.1, humanoid = true },  -- Golem Lord Argelmach
  [8658] = { path = "Character\\Dwarf\\Male\\DwarfMale.m2", scale = 1, humanoid = true },  -- Hurley Blackbreath
  [8177] = { path = "Creature\\GolemStone\\GolemCannonStone.m2", scale = 1.5 },  -- Phalanx
  [8652] = { path = "Character\\Gnome\\Male\\GnomeMale.m2", scale = 1, humanoid = true },  -- Plugger Spazzring
  [8329] = { path = "Creature\\Salamander\\SalamanderMale.m2", scale = 1 },  -- Ambassador Flamelash
  [8687] = { path = "Character\\Dwarf\\Male\\DwarfMale.m2", scale = 2, humanoid = true },  -- The Seven
  [8807] = { path = "Character\\Dwarf\\Male\\DwarfMale.m2", scale = 1.2, humanoid = true },  -- Emperor Dagran Thaurissan
  [8053] = { path = "Creature\\SkeletalSerpent\\SkeletalSerpent.m2", scale = 2.5 },  -- Avatar of Hakkar
  [6708] = { path = "Character\\Troll\\Male\\TrollMale.m2", scale = 1, humanoid = true },  -- Jammal'an the Prophet
  [7553] = { path = "Creature\\Drake\\Drake.m2", scale = 1.5 },  -- Wardens of the Dream
  [7806] = { path = "Creature\\Dragon\\NorthrendDragon.m2", scale = 0.8 },  -- Shade of Eranikus
  [11565] = { path = "Creature\\Ogre\\OgreWarlord.m2", scale = 2.65 },  -- Highlord Omokk
  [9732] = { path = "Character\\Troll\\Female\\TrollFemale.m2", scale = 1.2, humanoid = true },  -- Shadow Hunter Vosh'gajin
  [9733] = { path = "Character\\Troll\\Male\\TrollMale.m2", scale = 1.2, humanoid = true },  -- War Master Voone
  [9929] = { path = "Creature\\MineSpider\\MineSpider.m2", scale = 1.75 },  -- Mother Smolderweb
  [11583] = { path = "Creature\\Ogre\\OgreWarlord.m2", scale = 2.8 },  -- Urok Doomhowl
  [9738] = { path = "Character\\Orc\\Male\\OrcMale.m2", scale = 1.2, humanoid = true },  -- Quartermaster Zigris
  [9567] = { path = "Creature\\DireWolf\\DireWolf.m2", scale = 2 },  -- Halycon
  [9564] = { path = "Creature\\DireWolf\\DireWolf.m2", scale = 3 },  -- Gizrul the Slavener
  [8711] = { path = "Creature\\DragonSpawn\\DragonSpawnArmored.m2", scale = 2 },  -- Overlord Wyrmthalak
  [14383] = { path = "Creature\\AncientOfWar\\AncientofWar.m2", scale = 2 },  -- Tendris Warpwood
  [11270] = { path = "Character\\NightElf\\Female\\NightElfFemale.m2", scale = 1.2, humanoid = true },  -- Illyanna Ravenoak
  [14384] = { path = "Character\\NightElf\\Male\\NightElfMale.m2", scale = 1.2, humanoid = true },  -- Magister Kalendris
  [14173] = { path = "Creature\\voidterror\\VoidTerror.m2", scale = 3 },  -- Immol'thar
  [11256] = { path = "Character\\NightElf\\Male\\NightElfMale.m2", scale = 1, humanoid = true },  -- Prince Tortheldrin
  [14378] = { path = "Creature\\HighElf\\HighElfFemale_Mage.m2", scale = 1.2 },  -- Lethtendris
  [5489] = { path = "Creature\\WATERELEMENTAL\\WaterElemental.m2", scale = 1.75 },  -- Hydrospawn
  [11335] = { path = "Creature\\Satyr\\Satyr.m2", scale = 2 },  -- Zevrim Thornhoof
  [14416] = { path = "Creature\\Satyr\\Satyr.m2", scale = 2.5 },  -- Alzzin the Wildshaper
  [10482] = { path = "Character\\Human\\Male\\HumanMale.m2", scale = 1, humanoid = true },  -- Hearthsinger Forresten
  [10771] = { path = "Creature\\Ghost\\Ghost.m2", scale = 1 },  -- The Unforgiven
  [10669] = { path = "Character\\Human\\Male\\HumanMale.m2", scale = 1.2, humanoid = true },  -- Postmaster Malown
  [571] = { path = "Creature\\Ghoul\\Ghoul.m2", scale = 1.5 },  -- Timmy the Cruel
  [10458] = { path = "Character\\Human\\Male\\HumanMale.m2", scale = 1, humanoid = true },  -- Commander Malor
  [10674] = { path = "Character\\Human\\Male\\HumanMale.m2", scale = 1, humanoid = true },  -- Willey Hopebreaker
  [10544] = { path = "Character\\Human\\Male\\HumanMale.m2", scale = 1, humanoid = true },  -- Instructor Galford
  [10691] = { path = "Creature\\Dreadlord\\DreadLord.m2", scale = 2.5 },  -- Balnazzar
  [11561] = { path = "Creature\\Ogre\\OgreWarlord.m2", scale = 2.35 },  -- Guard Mol'dar
  [11545] = { path = "Creature\\Ogre\\Ogre.m2", scale = 2.05 },  -- Stomper Kreeg
  [11564] = { path = "Creature\\Ogre\\OgreWarlord.m2", scale = 2.5 },  -- Captain Kromcrush
  [11537] = { path = "Creature\\Ogre\\OgreMage.m2", scale = 2.35 },  -- Cho'Rush the Observer
  [10698] = { path = "Creature\\Banshee\\Banshee.m2", scale = 1.5 },  -- Baroness Anastari
  [9793] = { path = "Creature\\CryptFiend\\CryptFiend.m2", scale = 1.25 },  -- Nerub'enkan
  [10546] = { path = "Character\\Human\\Male\\HumanMale.m2", scale = 1, humanoid = true },  -- Maleki the Pallid
  [12818] = { path = "Creature\\FleshGolem\\FleshGolem.m2", scale = 2 },  -- Ramstein the Gorger
  [10217] = { path = "Character\\Human\\Male\\HumanMale.m2", scale = 1, humanoid = true },  -- Lord Aurius Rivendare
  [15217] = { path = "Character\\Troll\\Male\\TrollMale.m2", scale = 1.4, humanoid = true },  -- High Priest Venoxis
  [15219] = { path = "Character\\Troll\\Female\\TrollFemale.m2", scale = 1.4, humanoid = true },  -- High Priestess Jeklik
  [15220] = { path = "Character\\Troll\\Female\\TrollFemale.m2", scale = 1.4, humanoid = true },  -- High Priestess Mar'li
  [11288] = { path = "Character\\Troll\\Male\\TrollMale.m2", scale = 1.4, humanoid = true },  -- Bloodlord Mandokir
  [15288] = { path = "Creature\\Hydra\\Hydra.m2", scale = 3 },  -- Gahz'ranka
  [15216] = { path = "Character\\Troll\\Male\\TrollMale.m2", scale = 1.4, humanoid = true },  -- High Priest Thekal
  [15218] = { path = "Character\\Troll\\Female\\TrollFemale.m2", scale = 1.4, humanoid = true },  -- High Priestess Arlokk
  [11311] = { path = "Character\\Troll\\Male\\TrollMale.m2", scale = 1.4, humanoid = true },  -- Jin'do the Hexxer
  [15295] = { path = "Creature\\Hakkar\\Hakkar.m2", scale = 7 },  -- Hakkar
  [8390] = { path = "Creature\\TrollDire\\TrollDire.m2", scale = 1.5 },  -- Gri'lek
  [15267] = { path = "Character\\Troll\\Male\\TrollMale.m2", scale = 2, humanoid = true },  -- Hazza'rah
  [15268] = { path = "Character\\Troll\\Male\\TrollMale.m2", scale = 2, humanoid = true },  -- Renataki
  [15269] = { path = "Character\\Troll\\Male\\TrollMale.m2", scale = 2, humanoid = true },  -- Wushoolay
  [13031] = { path = "Creature\\Salamander\\SalamanderMale.m2", scale = 3 },  -- Lucifron
  [10193] = { path = "Creature\\FelBeast\\FelBeast.m2", scale = 3 },  -- Magmadar
  [13030] = { path = "Creature\\Salamander\\SalamanderMale.m2", scale = 3 },  -- Gehennas
  [12110] = { path = "Creature\\ElementalEarth\\ElementalEarth.m2", scale = 3 },  -- Garr
  [13032] = { path = "Creature\\Salamander\\SalamanderMale.m2", scale = 3 },  -- Shazzrah
  [12129] = { path = "Creature\\FireElemental\\FireElemental.m2", scale = 4 },  -- Baron Geddon
  [11986] = { path = "Creature\\MountainGiant\\MountainGiant.m2", scale = 3 },  -- Golemagg the Incinerator
  [12029] = { path = "Creature\\Salamander\\SalamanderMale.m2", scale = 4 },  -- Majordomo Executus
  [11121] = { path = "Creature\\Ragnaros\\Ragnaros.m2", scale = 1 },  -- Ragnaros
  [10115] = { path = "Creature\\DragonSpawn\\DragonSpawnOverlord.m2", scale = 2 },  -- Razorgore the Untamed
  [13992] = { path = "Creature\\Dragon\\NorthrendDragon.m2", scale = 1.5 },  -- Vaelastrasz the Corrupt
  [14308] = { path = "Creature\\DragonFootSoldier\\DragonFootSoldier.m2", scale = 2 },  -- Broodlord Lashlayer
  [6377] = { path = "Creature\\Drake\\Drake.m2", scale = 1.3 },  -- Firemaw
  [14367] = { path = "Creature\\Drakeadon\\Drakeadon.m2", scale = 3 },  -- Chromaggus
  [11380] = { path = "Creature\\Dragon\\DragonNefarian.m2", scale = 2 },  -- Nefarian
  [15742] = { path = "Creature\\SandReaver\\SandReaver.m2", scale = 1.5 },  -- Kurinnaxx
  [15376] = { path = "Creature\\QuirajGladiator\\QuirajGladiator.m2", scale = 4 },  -- General Rajaxx
  [15392] = { path = "Creature\\ObsidianDestroyer\\ObsidianDestroyer.m2", scale = 5 },  -- Moam
  [15654] = { path = "Creature\\SilithidTankBoss\\SilithidTankBoss.m2", scale = 1.5 },  -- Buru the Gorger
  [15431] = { path = "Creature\\SilithidWaspBoss\\SilithidWaspBoss.m2", scale = 2 },  -- Ayamiss the Hunter
  [15432] = { path = "Creature\\Horisath\\Horisath.m2", scale = 2.5 },  -- Ossirian the Unscarred
  [15345] = { path = "Creature\\QuirajProphet\\QuirajProphet.m2", scale = 4 },  -- The Prophet Skeram
  [15656] = { path = "Creature\\SilithidTankBoss\\SilithidTankBoss.m2", scale = 1.25 },  -- Silithid Royalty
  [15583] = { path = "Creature\\QuirajBattleguard\\BattleGuard.m2", scale = 2.75 },  -- Battleguard Sartura
  [15743] = { path = "Creature\\SandReaver\\SandReaver.m2", scale = 2 },  -- Fankriss the Unyielding
  [15686] = { path = "Creature\\SlimeGiant\\GiantSlime.m2", scale = 1.5 },  -- Viscidus
  [15739] = { path = "Creature\\SilithidWaspBoss\\SilithidWaspBoss.m2", scale = 2 },  -- Princess Huhuran
  [15778] = { path = "Creature\\TwinEmperor\\TwinEmperor.m2", scale = 3 },  -- The Twin Emperors
  [15509] = { path = "Creature\\SANDWORM\\SandWorm.m2", scale = 7.5 },  -- Ouro
  [15787] = { path = "Creature\\HalfBodyofKathune\\HalfBodyofKathune.m2", scale = 1 },  -- C'Thun
  [18916] = { path = "Creature\\Beholder\\Beholder.m2", scale = 2 },  -- Shirrak the Dead Watcher
  [17715] = { path = "Character\\Draenei\\Male\\DraeneiMale.m2", scale = 2, humanoid = true },  -- Exarch Maladaar
  [18236] = { path = "Creature\\FelOrcBoss\\FelOrcWarriorBoss.m2", scale = 2 },  -- Watchkeeper Gargolmar
  [18237] = { path = "Creature\\DoomGuardOutland\\DoomGuardOutland.m2", scale = 2.5 },  -- Omor the Unscarred
  [18944] = { path = "Creature\\FelOrcNetherdrake\\FelOrcNetherDrakeMounted.m2", scale = 2 },  -- Vazruden the Herald
  [22642] = { path = "Creature\\FelElfWarriorMale\\FelElfWarriorMale.m2", scale = 1.5 },  -- Selin Fireheart
  [22731] = { path = "Creature\\ArcaneVoidwraith\\ArcaneVoidWraith.m2", scale = 5 },  -- Vexallus
  [22596] = { path = "Creature\\Shivan\\Shivan.m2", scale = 0.9 },  -- Priestess Delrissa
  [22906] = { path = "Creature\\Kaelthas_broken\\KaelThasBroken.m2", scale = 2 },  -- Kael'thas Sunstrider
  [19332] = { path = "Creature\\MountainGiantCrystal\\MountainGiantCrystal_Boss.m2", scale = 2.5 },  -- Tavarok
  [19780] = { path = "Creature\\Etherial\\Etherial.m2", scale = 2.25 },  -- Nexus-Prince Shaffar
  [17386] = { path = "Character\\Human\\Male\\HumanMale.m2", scale = 1.3, humanoid = true },  -- Lieutenant Drake
  [17387] = { path = "Character\\Human\\Male\\HumanMale.m2", scale = 1.4, humanoid = true },  -- Captain Skarloc
  [19135] = { path = "Creature\\DrakeDarkshade\\DrakeDarkshade.m2", scale = 1.3 },  -- Epoch Hunter
  [20599] = { path = "Creature\\Arakkoa\\Arakkoa_Sage.m2", scale = 1.9 },  -- Darkweaver Syth
  [21492] = { path = "Creature\\RavenGod\\RavenGod.m2", scale = 2 },  -- Anzu
  [18636] = { path = "Creature\\Arakkoa\\Arakkoa_Sage.m2", scale = 2 },  -- Talon King Ikiss
  [18821] = { path = "Creature\\DoomGuardOutland\\DoomGuardOutland.m2", scale = 2.3 },  -- Ambassador Hellmaw
  [18058] = { path = "Creature\\OgreMageLord\\OgreMageLord.m2", scale = 3.5 },  -- Blackheart the Inciter
  [18535] = { path = "Character\\Orc\\Male\\OrcMale.m2", scale = 1.4, humanoid = true },  -- Grandmaster Vorpil
  [18839] = { path = "Creature\\Murmur\\Murmur.m2", scale = 1 },  -- Murmur
  [19882] = { path = "Creature\\Voidwraith\\VoidWraith.m2", scale = 3.5 },  -- Zereketh the Unbound
  [19888] = { path = "Creature\\Shivan\\Shivan.m2", scale = 2.5 },  -- Dalliah the Doomsayer
  [19977] = { path = "Creature\\Wrathguard\\Wrathguard.m2", scale = 3.5 },  -- Wrath-Scryer Soccothrates
  [19943] = { path = "Creature\\QuirajProphet\\QuirajProphet.m2", scale = 3 },  -- Harbinger Skyriss
  [20513] = { path = "Creature\\DragonFootSoldierDarkshade\\DragonFootSoldierDarkshade.m2", scale = 2 },  -- Chrono Lord Deja
  [19066] = { path = "Creature\\DrakeDarkshade\\DrakeDarkshade.m2", scale = 1.75 },  -- Temporus
  [20510] = { path = "Creature\\DragonDarkshade\\DragonDarkShade.m2", scale = 1 },  -- Aeonus
  [18369] = { path = "Creature\\Moarg\\Moarg1.m2", scale = 2 },  -- The Maker
  [19372] = { path = "Creature\\Beholder\\Beholder.m2", scale = 2 },  -- Broggok
  [17153] = { path = "Character\\FelOrc\\Male\\FelOrcMale.m2", scale = 1.2, humanoid = true },  -- Keli'dan the Breaker
  [18929] = { path = "Character\\BloodElf\\Female\\BloodElfFemale.m2", scale = 2, humanoid = true },  -- Commander Sarannis
  [19045] = { path = "Character\\BloodElf\\Male\\BloodElfMale.m2", scale = 1.3, humanoid = true },  -- High Botanist Freywinn
  [13109] = { path = "Creature\\Lasher\\Lasher.m2", scale = 2 },  -- Laj
  [19438] = { path = "Creature\\Ancientofarcane\\AncientofArcane.m2", scale = 2 },  -- Warp Splinter
  [19162] = { path = "Creature\\ARCANETITAN\\ArcaneTitan.m2", scale = 3 },  -- Mechano-Lord Capacitus
  [19166] = { path = "Character\\BloodElf\\Female\\BloodElfFemale.m2", scale = 2, humanoid = true },  -- Nethermancer Sepethrea
  [20033] = { path = "Character\\BloodElf\\Male\\BloodElfMale.m2", scale = 2, humanoid = true },  -- Pathaleon the Calculator
  [16628] = { path = "Character\\Orc\\Male\\OrcMale.m2", scale = 1.4, humanoid = true },  -- Grand Warlock Nethekurse
  [17725] = { path = "Character\\FelOrc\\Male\\FelOrcMale.m2", scale = 1.3, humanoid = true },  -- Blood Guard Porung
  [18031] = { path = "Creature\\OgreMageLord\\OgreMageLord.m2", scale = 3.5 },  -- Warbringer O'mrogg
  [19799] = { path = "Creature\\Kargath\\Kargath.m2", scale = 2 },  -- Warchief Kargath Bladefist
  [17728] = { path = "CHARACTER\\Broken\\Male\\BrokenMale.m2", scale = 2, humanoid = true },  -- Mennu the Betrayer
  [17729] = { path = "Creature\\LobstrokOutland\\LobstrokOutland.m2", scale = 5 },  -- Rokmar the Crackler
  [18224] = { path = "Creature\\FungalGiant\\FungalGiant.m2", scale = 3.5 },  -- Quagmirran
  [11268] = { path = "Creature\\NagaFemale\\Siren.m2", scale = 2 },  -- Hydromancer Thespia
  [18638] = { path = "Creature\\GnomeSpidertank\\GnomePounder.m2", scale = 2 },  -- Mekgineer Steamrigger
  [20235] = { path = "CHARACTER\\Naga_\\Male\\Naga_Male.m2", scale = 2.5, humanoid = true },  -- Warlord Kalithresh
  [17228] = { path = "Creature\\FungalGiant\\FungalGiant.m2", scale = 3.5 },  -- Hungarfen
  [17528] = { path = "Creature\\HydraOutland\\HydraOutland.m2", scale = 3 },  -- Ghaz'an
  [18570] = { path = "CHARACTER\\Broken\\Male\\BrokenMale.m2", scale = 1.5, humanoid = true },  -- Swamplord Musel'ek
  [18194] = { path = "Creature\\Tripod\\Tripod.m2", scale = 3 },  -- The Black Stalker
  [16054] = { path = "Creature\\DarkHound\\DarkHound.m2", scale = 1.6 },  -- Rokad the Ravager
  [16053] = { path = "Creature\\FelBat\\FelBat.m2", scale = 1.2 },  -- Shadikith the Glider
  [15938] = { path = "Creature\\MineSpider\\MineSpider.m2", scale = 1.3 },  -- Hyakiss the Lurker
  [16416] = { path = "Creature\\MOUNTEDDEATHKNIGHT\\UnMountedDeathKnight.m2", scale = 1.5 },  -- Attumen the Huntsman
  [19640] = { path = "Creature\\felhorse\\FelHorseEpic.m2", scale = 1.6 },  -- Midnight
  [16540] = { path = "Character\\Scourge\\Male\\ScourgeMale.m2", scale = 1.8, humanoid = true },  -- Moroes
  [16198] = { path = "Creature\\TitanFemale\\TitanFemale.m2", scale = 1.6 },  -- Maiden of Virtue
  [17053] = { path = "Creature\\Worgen\\Worgen.m2", scale = 3 },  -- The Big Bad Wolf
  [17067] = { path = "Character\\Human\\Male\\HumanMale.m2", scale = 1.75, humanoid = true },  -- Romulo
  [17068] = { path = "Character\\Human\\Female\\HumanFemale.m2", scale = 1.75, humanoid = true },  -- Julianne
  [17550] = { path = "Character\\Troll\\Female\\TrollFemale.m2", scale = 1.75, humanoid = true },  -- The Crone
  [16958] = { path = "Creature\\ArcaneGolem\\ArcaneGolem.m2", scale = 4.7 },  -- The Curator
  [16621] = { path = "Character\\Human\\Male\\HumanMale.m2", scale = 1.8, humanoid = true },  -- Shade of Aran
  [11343] = { path = "Creature\\Satyr\\Satyr.m2", scale = 2.25 },  -- Terestian Illhoof
  [15363] = { path = "Creature\\Dragon\\Taerar.m2", scale = 1.8 },  -- Netherspite
  [18720] = { path = "Creature\\medivh\\Medivh.m2", scale = 1.3 },  -- Echo of Medivh
  [19274] = { path = "Creature\\EREDAR\\Eredar.m2", scale = 4 },  -- Prince Malchezaar
  [18649] = { path = "Creature\\OgreKing\\OgreKing.m2", scale = 3.5 },  -- High King Maulgar
  [12472] = { path = "Creature\\Ogre\\OgreMage.m2", scale = 2.2 },  -- Kiggler the Crazed
  [11585] = { path = "Creature\\Ogre\\OgreMage.m2", scale = 2.35 },  -- Blindeye the Seer
  [20195] = { path = "Creature\\OgreMageLord\\OgreMageLord.m2", scale = 2.2 },  -- Olm the Summoner
  [20194] = { path = "Creature\\OgreMage02\\OgreMage02.m2", scale = 2 },  -- Krosh Firehand
  [18698] = { path = "Creature\\Gronn\\Gronn.m2", scale = 4 },  -- Gruul the Dragonkiller
  [18527] = { path = "Creature\\PitLord\\Magtheridon.m2", scale = 4 },  -- Magtheridon
  [9865] = { path = "Character\\Orc\\Female\\OrcFemale.m2", scale = 1.2, humanoid = true },  -- Hellfire Channeler
  [20162] = { path = "Creature\\WATERELEMENTAL\\WaterElemental.m2", scale = 5 },  -- Hydross the Unstable
  [20216] = { path = "Creature\\Krakken\\Krakken.m2", scale = 2 },  -- The Lurker Below
  [20514] = { path = "Character\\BloodElf\\Male\\BloodElfMale.m2", scale = 2.25, humanoid = true },  -- Leotheras the Blind
  [20568] = { path = "Creature\\demonhunter\\DemonHunter.m2", scale = 3 },  -- Shadow of Leotheras
  [20662] = { path = "CHARACTER\\Naga_\\Male\\Naga_Male.m2", scale = 3.5, humanoid = true },  -- Fathom-Lord Karathress
  [20671] = { path = "CHARACTER\\Naga_\\Male\\Naga_Male.m2", scale = 2.25, humanoid = true },  -- Fathom-Guard Sharkkis
  [20670] = { path = "CHARACTER\\Broken\\Male\\BrokenMale.m2", scale = 2, humanoid = true },  -- Fathom-Guard Tidalvess
  [20672] = { path = "CHARACTER\\Naga_\\Female\\Naga_Female.m2", scale = 2, humanoid = true },  -- Fathom-Guard Caribdis
  [20739] = { path = "Creature\\SeaGiant\\SeaGiant.m2", scale = 3 },  -- Morogrim Tidewalker
  [20748] = { path = "Creature\\LadyVashj\\LadyVashj.m2", scale = 3.5 },  -- Lady Vashj
  [18945] = { path = "Creature\\PHOENIX\\Phoenix.m2", scale = 5 },  -- Al'ar
  [18951] = { path = "Creature\\FelReaver\\FelReaver.m2", scale = 1.5 },  -- Void Reaver
  [18239] = { path = "Character\\BloodElf\\Female\\BloodElfFemale.m2", scale = 4, humanoid = true },  -- High Astromancer Solarian
  [20023] = { path = "Creature\\Kaelthas\\Kaelthas.m2", scale = 3 },  -- Kael'thas Sunstrider
  [20236] = { path = "Character\\BloodElf\\Male\\BloodElfMale.m2", scale = 3, humanoid = true },  -- Thaladred the Darkener
  [20178] = { path = "Character\\BloodElf\\Male\\BloodElfMale.m2", scale = 3, humanoid = true },  -- Lord Sanguinar
  [20237] = { path = "Character\\BloodElf\\Female\\BloodElfFemale.m2", scale = 3, humanoid = true },  -- Grand Astromancer Capernian
  [20177] = { path = "Character\\BloodElf\\Male\\BloodElfMale.m2", scale = 3, humanoid = true },  -- Master Engineer Telonicus
  [17444] = { path = "Creature\\Lich\\Lich.m2", scale = 3.5 },  -- Rage Winterchill
  [21069] = { path = "Creature\\Dreadlord\\DreadLord.m2", scale = 5 },  -- Anetheron
  [17886] = { path = "Creature\\Lord Kezzak\\LordKezzak.m2", scale = 2.25 },  -- Kaz'rogal
  [18526] = { path = "Creature\\PITLORD\\Pitlord.m2", scale = 4 },  -- Azgalor
  [20939] = { path = "Creature\\EREDAR\\Archimonde.m2", scale = 12 },  -- Archimonde
  [21174] = { path = "Creature\\NagaLordMale\\NagaLordMale.m2", scale = 7 },  -- High Warlord Naj'entus
  [21145] = { path = "Creature\\AbyssalIllidan\\Abyssal_Illidan.m2", scale = 16 },  -- Supremus
  [21357] = { path = "Creature\\Akama\\Akama.m2", scale = 5 },  -- Shade of Akama
  [21262] = { path = "Creature\\TeronGorefiend\\TeronGorefiend.m2", scale = 2.5 },  -- Teron Gorefiend
  [21443] = { path = "Creature\\FelOrcDire\\FelOrcDire.m2", scale = 2.75 },  -- Gurtogg Bloodboil
  [21483] = { path = "Creature\\WellofSouls\\WellofSoulsGrief.m2", scale = 1 },  -- Essence of Suffering
  [21485] = { path = "Creature\\WellofSouls\\WellofSoulsSeduction.m2", scale = 1 },  -- Essence of Desire
  [21484] = { path = "Creature\\WellofSouls\\WellofSoulsPain.m2", scale = 1 },  -- Essence of Anger
  [21252] = { path = "Creature\\HaremMatron\\HaremMatron.m2", scale = 2.5 },  -- Mother Shahraz
  [21416] = { path = "Character\\BloodElf\\Male\\BloodElfMale.m2", scale = 2.2, humanoid = true },  -- Gathios the Shatterer
  [21417] = { path = "Character\\BloodElf\\Male\\BloodElfMale.m2", scale = 2.1, humanoid = true },  -- High Nethermancer Zerevor
  [21419] = { path = "Character\\BloodElf\\Female\\BloodElfFemale.m2", scale = 2.1, humanoid = true },  -- Lady Malande
  [21418] = { path = "Character\\BloodElf\\Male\\BloodElfMale.m2", scale = 2.25, humanoid = true },  -- Veras Darkshadow
  [21135] = { path = "Creature\\Illidan\\Illidan.m2", scale = 1.5 },  -- Illidan Stormrage
  [23345] = { path = "Creature\\DragonKalecgos\\DragonKalecgos.m2", scale = 1.75 },  -- Kalecgos
  [26628] = { path = "Creature\\Dreadlord\\DreadLord.m2", scale = 3 },  -- Sathrovarr the Corruptor
  [22711] = { path = "Creature\\Brutallus\\Brutallus.m2", scale = 6 },  -- Brutallus
  [22838] = { path = "Creature\\FrostWurmFellfire\\FrostWurmFellfire.m2", scale = 1.6 },  -- Felmyst
  [23334] = { path = "Creature\\EredarFemale\\EredarFemale.m2", scale = 2.5 },  -- Grand Warlock Alythess
  [23177] = { path = "Creature\\EredarFemale\\EredarFemale.m2", scale = 2.5 },  -- Lady Sacrolash
  [23404] = { path = "Creature\\Muru\\Muru.m2", scale = 2 },  -- M'uru
  [23428] = { path = "Creature\\VoidGod\\VoidGod.m2", scale = 6 },  -- Entropius
  [23200] = { path = "Creature\\Kiljaeden\\Kiljaeden.m2", scale = 6 },  -- Kil'jaeden
  [27407] = { path = "Creature\\NerubianPriest\\NerubianPriest.m2", scale = 4 },  -- Elder Nadox
  [27406] = { path = "Creature\\VampyrBloodPrince\\VampyrBloodPrince.m2", scale = 2 },  -- Prince Taldaram
  [26777] = { path = "Character\\Orc\\Female\\OrcFemale.m2", scale = 1.65, humanoid = true },  -- Jedoga Shadowseeker
  [28133] = { path = "Creature\\FungalMonster\\FungalMonster.m2", scale = 3.5 },  -- Amanitar
  [27408] = { path = "Creature\\FacelessOne\\FacelessOne.m2", scale = 4 },  -- Herald Volazj
  [27394] = { path = "Creature\\NerubianPriest\\NerubianPriest.m2", scale = 4 },  -- Krik'thir the Gatewatcher
  [26776] = { path = "Creature\\BoneSpider\\BoneSpider.m2", scale = 6 },  -- Hadronox
  [27856] = { path = "Creature\\CryptLord\\CryptLord.m2", scale = 1 },  -- Anub'arak
  [26352] = { path = "Creature\\TrollDire\\TrollDire.m2", scale = 2 },  -- Trollgore
  [26292] = { path = "Creature\\Lich\\Lich.m2", scale = 3 },  -- Novos the Summoner
  [5240] = { path = "Creature\\TRex\\trex.m2", scale = 2.5 },  -- King Dred
  [27072] = { path = "Creature\\SkeletalSerpent\\SkeletalSerpent.m2", scale = 2.5 },  -- The Prophet Tharon'ja
  [27422] = { path = "Creature\\slith\\Slith.m2", scale = 2 },  -- Slad'ran
  [26589] = { path = "Creature\\ZuldrakGolem\\ZuldrakGolem.m2", scale = 3 },  -- Drakkari Colossus
  [27059] = { path = "Character\\IceTroll\\Male\\IceTrollMale.m2", scale = 1.5, humanoid = true },  -- Moorabi
  [26644] = { path = "Creature\\Oracle\\Oracle.m2", scale = 3 },  -- Eck the Ferocious
  [27061] = { path = "Character\\IceTroll\\Male\\IceTrollMale.m2", scale = 1.5, humanoid = true },  -- Gal'darah
  [27301] = { path = "Creature\\IronVrykulMale\\IronVrykulMale.m2", scale = 1.75 },  -- General Bjarngrim
  [27071] = { path = "Creature\\NorthrendFireGiant\\NorthrendFireGiant.m2", scale = 1.25 },  -- Volkhan
  [27484] = { path = "Creature\\RevenantAir\\RevenantAir.m2", scale = 2.5 },  -- Ionar
  [27485] = { path = "Creature\\TitanMale\\TitanMale.m2", scale = 2.1 },  -- Loken
  [30972] = { path = "Character\\Human\\Male\\HumanMale.m2", scale = 2.5, humanoid = true },  -- Falric
  [30973] = { path = "Character\\Human\\Male\\HumanMale.m2", scale = 2.5, humanoid = true },  -- Marwyn
  [30721] = { path = "Creature\\ArthasLichKing\\ArthasLichKing_Unarmed.m2", scale = 2.75 },  -- The Lich King
  [20909] = { path = "Creature\\MountainGiantCrystal\\MountainGiantCrystal.m2", scale = 2.25 },  -- Krystallus
  [26657] = { path = "Creature\\TitanFemale\\TitanFemale.m2", scale = 2 },  -- Maiden of Grief
  [26353] = { path = "Character\\Dwarf\\Male\\DwarfMale.m2", scale = 1.1, humanoid = true },  -- Brann Bronzebeard
  [27483] = { path = "Creature\\IronVrykulMale\\IronVrykulMale.m2", scale = 1.6 },  -- Sjonnir The Ironshaper
  [31154] = { path = "Creature\\RidingUndeadDrake\\ArmoredRidingUndeadDrake.m2", scale = 1 },  -- Rimefang
  [26579] = { path = "Creature\\FleshGolem\\FleshGolem.m2", scale = 2.5 },  -- Meathook
  [26581] = { path = "Creature\\Necromancer\\Necromancer.m2", scale = 2 },  -- Salramm the Fleshcrafter
  [26580] = { path = "Creature\\DragonFootSoldierDarkshade\\DragonFootSoldierDarkshade.m2", scale = 2 },  -- Chrono-Lord Epoch
  [26582] = { path = "Creature\\MalGanis\\MalGanis.m2", scale = 3 },  -- Mal'Ganis
  [30226] = { path = "Character\\Human\\Male\\HumanMale.m2", scale = 1.5, humanoid = true },  -- Bronjahm
  [30148] = { path = "Creature\\WellofSouls\\WellofSoulsPain.m2", scale = 0.8 },  -- Devourer of Souls
  [24366] = { path = "Character\\Dwarf\\Male\\DwarfMale.m2", scale = 1.25, humanoid = true },  -- Commander Stoutbeard
  [24352] = { path = "Character\\Orc\\Male\\OrcMale.m2", scale = 1.25, humanoid = true },  -- Commander Kolurg
  [24066] = { path = "Character\\BloodElf\\Female\\BloodElfFemale.m2", scale = 1.35, humanoid = true },  -- Grand Magus Telestra
  [26259] = { path = "Creature\\ArcaneVoidwraith\\ArcaneVoidWraith.m2", scale = 5 },  -- Anomalus
  [26298] = { path = "Creature\\MountainGiantCrystal\\MountainGiantCrystal.m2", scale = 1.75 },  -- Ormorok the Tree-Shaper
  [24307] = { path = "Creature\\DragonRedCrystal\\RedCrystalDragon.m2", scale = 0.75 },  -- Keristrasza
  [27032] = { path = "Creature\\DragonSpawn\\DragonSpawnOverlordNexus.m2", scale = 2 },  -- Drakos the Interrogator
  [27033] = { path = "Creature\\NetherDrakonidBoss\\NetherDrakonidBoss.m2", scale = 2.5 },  -- Varos Cloudstrider
  [25010] = { path = "Character\\Human\\Male\\HumanMale.m2", scale = 1.5, humanoid = true },  -- Mage-Lord Urom
  [27034] = { path = "Creature\\Dragon\\NorthrendDragon.m2", scale = 2 },  -- Ley-Guardian Eregos
  [27488] = { path = "Creature\\Arakkoa\\Arakkoa_Sage.m2", scale = 1.8 },  -- Erekem
  [20590] = { path = "Creature\\Beholder\\Beholder.m2", scale = 2 },  -- Moragg
  [27487] = { path = "Creature\\RevenantWater\\RevenantWater.m2", scale = 2 },  -- Ichoron
  [27486] = { path = "Creature\\EtherialRobe\\EtherialRobe.m2", scale = 1.5 },  -- Xevozz
  [27855] = { path = "Creature\\Voidlord\\VoidLord.m2", scale = 2.5 },  -- Zuramat the Obliterator
  [27508] = { path = "Character\\BloodElf\\Female\\BloodElfFemale.m2", scale = 1.4, humanoid = true },  -- Cyanigosa
  [28587] = { path = "Character\\Orc\\Male\\OrcMale.m2", scale = 1.2, humanoid = true },  -- Mokra the Skullcrusher
  [28637] = { path = "Character\\BloodElf\\Female\\BloodElfFemale.m2", scale = 1.1, humanoid = true },  -- Eressea Dawnsinger
  [28597] = { path = "Character\\Tauren\\Male\\TaurenMale.m2", scale = 1.1, humanoid = true },  -- Runok Wildmane
  [28588] = { path = "Character\\Troll\\Male\\TrollMale.m2", scale = 1.1, humanoid = true },  -- Zul'tore
  [28589] = { path = "Character\\Scourge\\Male\\ScourgeMale.m2", scale = 1.1, humanoid = true },  -- Deathstalker Visceri
  [28560] = { path = "Character\\Human\\Male\\HumanMale.m2", scale = 1.1, humanoid = true },  -- Marshal Jacob Alerius
  [28586] = { path = "Character\\Gnome\\Male\\GnomeMale.m2", scale = 1.1, humanoid = true },  -- Ambrose Boltspark
  [28735] = { path = "Character\\NightElf\\Female\\NightElfFemale.m2", scale = 1.1, humanoid = true },  -- Jaelyne Evensong
  [28564] = { path = "Character\\Dwarf\\Female\\DwarfFemale.m2", scale = 1.1, humanoid = true },  -- Lana Stouthammer
  [28736] = { path = "Character\\Draenei\\Male\\DraeneiMale.m2", scale = 1.2, humanoid = true },  -- Colosos
  [29616] = { path = "Character\\Human\\Male\\HumanMale.m2", scale = 1.75, humanoid = true },  -- Eadric the Pure
  [29490] = { path = "Character\\Human\\Female\\HumanFemale.m2", scale = 1.75, humanoid = true },  -- Argent Confessor Paletress
  [29837] = { path = "Character\\Scourge\\Male\\ScourgeMale.m2", scale = 2, humanoid = true },  -- The Black Knight
  [25338] = { path = "Creature\\VampyrBloodPrince\\VampyrBloodPrince.m2", scale = 1.5 },  -- Prince Keleseth
  [24605] = { path = "Character\\Vrykul\\Male\\VrykulMale.m2", scale = 1.25, humanoid = true },  -- Skarvald the Constructor
  [26349] = { path = "Creature\\Necromancer\\Necromancer.m2", scale = 2 },  -- Dalronn the Controller
  [21953] = { path = "Character\\Vrykul\\Male\\VrykulMale.m2", scale = 1.25, humanoid = true },  -- Ingvar the Plunderer
  [26096] = { path = "Creature\\ValkierDark\\ValkierDark.m2", scale = 1 },  -- Svala Sorrowgrave
  [27419] = { path = "Creature\\Magnataur\\magnataur.m2", scale = 3 },  -- Gortok Palehoof
  [26284] = { path = "Creature\\WoolyRhino\\WoolyRhino.m2", scale = 2 },  -- Ferocious Rhino
  [26327] = { path = "Creature\\NorthrendWorgen\\NorthrendWorgen.m2", scale = 5 },  -- Frenzied Worgen
  [24564] = { path = "Creature\\JormungarLarva\\JormungarLarva.m2", scale = 4 },  -- Massive Jormungar
  [23999] = { path = "Creature\\DireFurbolg\\DireFurbolg.m2", scale = 5 },  -- Ravenous Furbolg
  [27418] = { path = "Creature\\FrostVrykulMale\\FrostVrykulMale.m2", scale = 1.5 },  -- Skadi the Ruthless
  [28019] = { path = "Creature\\KingYmiron\\KingYmiron.m2", scale = 1.65 },  -- King Ymiron
  [26967] = { path = "Creature\\NorthrendStoneGiant\\NorthrendStoneGiant.m2", scale = 1.5 },  -- Archavon the Stone Watcher
  [27108] = { path = "Creature\\NORTHRENDIRONGIANT\\NorthrendIronGiant.m2", scale = 1.5 },  -- Emalon the Storm Watcher
  [29524] = { path = "Creature\\NorthrendFireGiant\\NorthrendFireGiant.m2", scale = 1.25 },  -- Koralon the Flame Watcher
  [31089] = { path = "Creature\\NorthrendIceGiant\\NorthrendIceGiant.m2", scale = 1.5 },  -- Toravon the Ice Watcher
  [15931] = { path = "Creature\\CryptLord\\CryptLord.m2", scale = 1 },  -- Anub'Rekhan
  [15940] = { path = "Character\\Human\\Female\\HumanFemale.m2", scale = 1.7, humanoid = true },  -- Grand Widow Faerlina
  [15928] = { path = "Creature\\GiantSpider\\GiantSpider.m2", scale = 8.7 },  -- Maexxna
  [16590] = { path = "Character\\Human\\Male\\HumanMale.m2", scale = 2, humanoid = true },  -- Noth the Plaguebringer
  [16309] = { path = "Creature\\Necromancer\\Necromancer.m2", scale = 3 },  -- Heigan the Unclean
  [16110] = { path = "Creature\\FungalMonster\\FungalMonster.m2", scale = 4 },  -- Loatheb
  [16582] = { path = "Character\\Human\\Male\\HumanMale.m2", scale = 2, humanoid = true },  -- Instructor Razuvious
  [16539] = { path = "Character\\Human\\Male\\HumanMale.m2", scale = 1.75, humanoid = true },  -- Death Knight Understudy
  [16279] = { path = "Creature\\Necromancer\\Necromancer.m2", scale = 3 },  -- Gothik the Harvester
  [10729] = { path = "Creature\\MountedDeathKnight\\MountedDeathKnight.m2", scale = 1.5 },  -- Baron Rivendare
  [16155] = { path = "Creature\\MOUNTEDDEATHKNIGHT\\MountedDeathKnight_Korthazz.m2", scale = 1.5 },  -- Thane Korth'azz
  [16153] = { path = "Creature\\MOUNTEDDEATHKNIGHT\\MountedDeathKnight_Blaumeux.m2", scale = 1.5 },  -- Lady Blaumeux
  [16154] = { path = "Creature\\MOUNTEDDEATHKNIGHT\\MountedDeathKnight_Zeliek.m2", scale = 1.5 },  -- Sir Zeliek
  [16174] = { path = "Creature\\FleshGolem\\FleshGolem.m2", scale = 4 },  -- Patchwerk
  [16035] = { path = "Creature\\FleshGiant\\FleshGiant.m2", scale = 1.5 },  -- Grobbulus
  [16064] = { path = "Creature\\UndeadBeast\\UndeadBeast.m2", scale = 3 },  -- Gluth
  [16137] = { path = "Creature\\FleshTitan\\FleshTitan.m2", scale = 2 },  -- Thaddius
  [15945] = { path = "Creature\\KelThuzad\\KelThuzad.m2", scale = 4 },  -- Kel'Thuzad
  [27035] = { path = "Creature\\Dragon\\NorthrendDragon.m2", scale = 1.8 },  -- Sartharion
  [27082] = { path = "Creature\\Drake\\Drake.m2", scale = 1.5 },  -- Tenebron
  [27421] = { path = "Creature\\Drake\\Drake.m2", scale = 1.5 },  -- Shadron
  [27039] = { path = "Creature\\Drake\\Drake.m2", scale = 1.5 },  -- Vesperon
  [26752] = { path = "Creature\\Malygos\\Malygos.m2", scale = 2 },  -- Malygos
  [29614] = { path = "Creature\\Magnataur\\magnataur.m2", scale = 3.5 },  -- Gormok the Impaler
  [29815] = { path = "Creature\\Jormungar\\Jormungar.m2", scale = 5 },  -- Acidmaw and Dreadscale
  [21601] = { path = "Creature\\Yeti\\Yeti.m2", scale = 4 },  -- Icehowl
  [29615] = { path = "Creature\\EREDAR\\Eredar.m2", scale = 5 },  -- Lord Jaraxxus
  [29814] = { path = "Character\\Gnome\\Male\\GnomeMale.m2", scale = 1.25, humanoid = true },  -- Wilfred Fizzlebang
  [29770] = { path = "Character\\NightElf\\Female\\NightElfFemale.m2", scale = 3.1, humanoid = true },  -- Alyssia Moonstalker
  [29767] = { path = "Character\\Dwarf\\Male\\DwarfMale.m2", scale = 1.5, humanoid = true },  -- Anthar Forgemender
  [29774] = { path = "Character\\Human\\Male\\HumanMale.m2", scale = 3.7, humanoid = true },  -- Baelnor Lightbearer
  [29776] = { path = "Character\\Human\\Female\\HumanFemale.m2", scale = 4.1, humanoid = true },  -- Irieth Shadowstep
  [29780] = { path = "Creature\\Ent\\Ent.m2", scale = 1 },  -- Melador Valestrider
  [29772] = { path = "Character\\Gnome\\Male\\GnomeMale.m2", scale = 1.5, humanoid = true },  -- Noozle Whizzlestick
  [29777] = { path = "Creature\\EredarFemale\\EredarFemale.m2", scale = 2 },  -- Serissa Grimdabbler
  [29779] = { path = "Character\\Draenei\\Male\\DraeneiMale.m2", scale = 3, humanoid = true },  -- Shocuul
  [29765] = { path = "Character\\Human\\Male\\HumanMale.m2", scale = 3.7, humanoid = true },  -- Tyrius Duskblade
  [29781] = { path = "Creature\\DruidOwlbear\\DruidOwlBearTauren.m2", scale = 1.2 },  -- Birana Stormhoof
  [29784] = { path = "Character\\Tauren\\Male\\TaurenMale.m2", scale = 2.5, humanoid = true },  -- Broln Stouthorn
  [29783] = { path = "Character\\Scourge\\Male\\ScourgeMale.m2", scale = 1.5, humanoid = true },  -- Caiphus the Stern
  [29787] = { path = "Character\\Scourge\\Female\\ScourgeFemale.m2", scale = 1.5, humanoid = true },  -- Ginselle Blightslinger
  [29782] = { path = "Character\\Orc\\Male\\OrcMale.m2", scale = 3.2, humanoid = true },  -- Gorgrim Shadowcleave
  [29792] = { path = "Character\\Orc\\Male\\OrcMale.m2", scale = 2, humanoid = true },  -- Harkzog
  [29790] = { path = "Character\\Troll\\Female\\TrollFemale.m2", scale = 3, humanoid = true },  -- Maz'dinah
  [29793] = { path = "Character\\Tauren\\Male\\TaurenMale.m2", scale = 2.5, humanoid = true },  -- Narrhok Steelbreaker
  [29786] = { path = "Character\\Troll\\Female\\TrollFemale.m2", scale = 3, humanoid = true },  -- Ruj'kah
  [29791] = { path = "Character\\Scourge\\Female\\ScourgeFemale.m2", scale = 1.5, humanoid = true },  -- Vivienne Blackwhisper
  [29240] = { path = "Creature\\Valkier\\Valkier.m2", scale = 1.5 },  -- Fjola Lightbane
  [29267] = { path = "Creature\\ValkierDark\\ValkierDark.m2", scale = 1.5 },  -- Eydis Darkbane
  [29268] = { path = "Creature\\CryptLord\\CryptLord_Frost.m2", scale = 1.5 },  -- Anub'arak
  [31119] = { path = "Creature\\BoneGuard\\BoneGuard.m2", scale = 4.5 },  -- Lord Marrowgar
  [30893] = { path = "Creature\\MinisterofDeath\\MinisterofDeath.m2", scale = 3 },  -- Lady Deathwhisper
  [30416] = { path = "Character\\Orc\\Male\\OrcMale.m2", scale = 2.5, humanoid = true },  -- High Overlord Saurfang
  [30508] = { path = "Character\\Dwarf\\Male\\DwarfMale.m2", scale = 3, humanoid = true },  -- Muradin Bronzebeard
  [30790] = { path = "Character\\Orc\\Male\\OrcMale.m2", scale = 1.15, humanoid = true },  -- Deathbringer Saurfang
  [31006] = { path = "Creature\\IcecrownFleshBeast\\IcecrownFleshBeast.m2", scale = 1 },  -- Festergut
  [31005] = { path = "Creature\\IcecrownFleshBeast\\IcecrownFleshBeast.m2", scale = 1 },  -- Rotface
  [30881] = { path = "Creature\\MadScientist\\MadScientistNoBackpack.m2", scale = 3.9 },  -- Professor Putricide
  [30858] = { path = "Creature\\VampyrBloodPrince\\VampyrBloodPrince.m2", scale = 1.75 },  -- Prince Valanar
  [30857] = { path = "Creature\\VampyrBloodPrince\\VampyrBloodPrince.m2", scale = 1.75 },  -- Prince Keleseth
  [30856] = { path = "Creature\\VampyrBloodPrince\\VampyrBloodPrince.m2", scale = 1.75 },  -- Prince Taldaram
  [31165] = { path = "Creature\\BloodQueen\\BloodQueen.m2", scale = 4 },  -- Blood-Queen Lana'thel
  [30318] = { path = "Creature\\Dragon\\NorthrendDragon.m2", scale = 2 },  -- Valithria Dreamwalker
  [30362] = { path = "Creature\\FrostWurmNorthrend\\FrostWurmNorthrend.m2", scale = 2.5 },  -- Sindragosa
  [28875] = { path = "CREATURE\\FlameLeviathan\\FlameLeviathan.m2", scale = 3 },  -- Flame Leviathan
  [29185] = { path = "Creature\\NorthrendFireGiant\\NorthrendFireGiant.m2", scale = 2 },  -- Ignis the Furnace Master
  [28787] = { path = "CREATURE\\ProtoDragon\\ProtoDragon_Razorscale.m2", scale = 2 },  -- Razorscale
  [28611] = { path = "CREATURE\\ClockworkGiant\\ClockworkGiant.m2", scale = 1.5 },  -- XT-002 Deconstructor
  [28344] = { path = "Creature\\NORTHRENDIRONGIANT\\NorthrendIronGiant.m2", scale = 1.5 },  -- Steelbreaker
  [28381] = { path = "Creature\\IronVrykulMale\\IronVrykulMale.m2", scale = 2 },  -- Runemaster Molgeim
  [28324] = { path = "CREATURE\\IronDwarf\\IronDwarf.m2", scale = 2 },  -- Stormcaller Brundir
  [28638] = { path = "CREATURE\\KOLOGARN\\Kologarn.m2", scale = 0.85 },  -- Kologarn
  [28651] = { path = "Creature\\TitanFemale\\TitanFemale.m2", scale = 2.5 },  -- Auriaya
  [28743] = { path = "CREATURE\\Hodir\\Hodir.m2", scale = 2.5 },  -- Hodir
  [28977] = { path = "CREATURE\\Thorum\\Thorum.m2", scale = 2.5 },  -- Thorim
  [28488] = { path = "Creature\\VrykulFemale\\FrostVrykulFemaleCaster.m2", scale = 2 },  -- Sif
  [28777] = { path = "CREATURE\\Freia\\Freia.m2", scale = 2.5 },  -- Freya
  [29174] = { path = "Creature\\ANCIENTPROTECTOR\\AncientProtector.m2", scale = 3 },  -- Elder Brightleaf
  [29175] = { path = "Creature\\AncientOfLore\\AncientofLore.m2", scale = 2 },  -- Elder Ironbranch
  [29176] = { path = "Creature\\ANCIENTPROTECTOR\\AncientProtector.m2", scale = 3 },  -- Elder Stonebark
  [28578] = { path = "Creature\\ClockworkGnome\\ClockworkGnome_D.m2", scale = 3 },  -- Mimiron
  [28548] = { path = "CREATURE\\FacelessGeneral\\FacelessGeneral.m2", scale = 1.2 },  -- General Vezax
  [28817] = { path = "CREATURE\\YoggSaron\\YoggSaron.m2", scale = 1 },  -- Yogg-Saron
  [28641] = { path = "CREATURE\\AlglontheObserver\\AlgalontheObserver.m2", scale = 3 },  -- Algalon the Observer
  [8570] = { path = "Creature\\Dragon\\DragonOnyxia.m2", scale = 1.8 },  -- Onyxia
  [31952] = { path = "Creature\\TwighlightDragon\\TwighlightDragon.m2", scale = 1.8 },  -- Halion
}
