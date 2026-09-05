-- Addon/EncounterJournal/wotlk_abilities.lua — ability sections for the WotLK RAID bosses the
-- retail DB2 extract (wotlk_data.lua) carries no sections for: Naxxramas, Vault of Archavon,
-- Obsidian Sanctum, Eye of Eternity, Trial of the Crusader, Onyxia's Lair, Icecrown Citadel,
-- Ruby Sanctum and Algalon. Taken from DragonUI_NewEra's hand-seeded AbilitiesWotLK.lua
-- (2026-09-05) and re-keyed from its placeholder encounter ids onto OUR JournalEncounter ids by
-- instance + boss name (tools: scratchpad abilport.py). GENERATED — regenerate rather than edit.
--
-- Provenance (per the source's header): ~82 encounters were seeded from a Wowhead WotLK tooltip
-- export (body text PARAPHRASED, `spell` = the real spellID from the Wowhead link); the rest are
-- hand-written from general encounter knowledge with spell=0. Flags use the journal's bit scheme:
-- Tank 1, Heal 4, Deadly 16, Important 32, Interrupt 64, Magic 128, Curse 256, Poison 512,
-- Disease 1024, Enrage 2048, Bleed 8192. No icon FDIDs — the renderer resolves the spell's icon.
--
-- Overlay: merged into EJ.ej.DATA at load into encounters that still have no sections (a future
-- DB2 regen that brings real sections wins automatically) PLUS the FORCE set below, where the
-- NewEra seed deliberately replaces the DB2 sections. Loads after wotlk_data.lua.

local EJ = _G.EJ
EJ.ej = EJ.ej or {}

-- Encounters whose existing DB2 sections are REPLACED (the retail Ulduar entries read wrong in-client).
local FORCE = { [1637]=true, [1638]=true, [1639]=true, [1640]=true, [1641]=true, [1642]=true, [1643]=true, [1644]=true, [1645]=true, [1646]=true, [1647]=true, [1648]=true, [1649]=true }

local ABIL = {
  -- Vault of Archavon
  [1597] = { -- Archavon the Stone Watcher
    { title = "Crush", flags = 1, spell = 0,
      body = "A heavy melee strike against his current target that also lightly damages nearby allies — the tank should expect a steady stream of large hits." },
    { title = "Rock Shards", flags = 16, spell = 58689,
      body = "Shards of stone erupt beneath random players, dealing Physical damage to anyone caught in the blast." },
    { title = "Stomp", flags = 16, spell = 60880,
      body = "Stomps the ground, knocking back and damaging everyone in the room — a simple positioning check more than a true mechanic." },
  },
  [1598] = { -- Emalon the Storm Watcher
    { title = "Lightning Nova", flags = 16, spell = 59835,
      body = "Releases a burst of Nature damage across the entire room, hitting everyone regardless of position." },
    { title = "Overcharge", flags = 32, spell = 0,
      body = "Empowers his three Tempest Minions, sharply increasing the damage of their lightning attacks — killing a minion quickly removes a third of the incoming damage." },
  },
  [1599] = { -- Koralon the Flame Watcher
    { title = "Flame Breath", flags = 16, spell = 0,
      body = "Breathes a cone of fire in front of him, dealing heavy Fire damage to anyone caught in front of Koralon." },
    { title = "Meteor Fists", flags = 16, spell = 66725,
      body = "Slams the ground with his fists, sending fire spreading outward from the impact — melee should be ready to step out and back in." },
    { title = "Burning Aura", flags = 16, spell = 0,
      body = "The ground beneath and around Koralon continuously burns, punishing players who stay in melee range instead of managing their positioning." },
  },
  [1600] = { -- Toravon the Ice Watcher
    { title = "Frozen Orb", flags = 16, spell = 72092,
      body = "Launches a slow-moving orb of ice that damages and chills anyone it passes through — sidestep its path rather than tanking the hit." },
    { title = "Encase in Ice", flags = 16, spell = 0,
      body = "Traps a player in a block of ice, immobilizing them until it's broken or expires." },
    { title = "Fury of the Ice Watcher", flags = 2048, spell = 0,
      body = "Toravon periodically empowers himself with the room's frost pillars, hitting harder for a duration — a burn window the raid should be prepared to heal through." },
  },
  -- Naxxramas
  [1601] = { -- Anub'Rekhan
    { title = "Impale", flags = 16, spell = 28783,
      body = "Spikes erupt from the earth in a line, dealing heavy Physical damage and launching anyone hit into the air with a stun." },
    { title = "Locust Swarm", flags = 16, spell = 28785,
      body = "Releases a swarm of locusts that slows Anub'Rekhan and silences and damages everyone nearby — casters lose the ability to act while it's up." },
    { title = "Summon Crypt Guards", flags = 32, spell = 0,
      body = "Calls in a Crypt Guard that attacks players and stacks a bleed effect; keeping it off the raid's ranged and healers matters more than burning it down instantly." },
  },
  [1602] = { -- Grand Widow Faerlina
    { title = "Poison Bolt Volley", flags = 512, spell = 28796,
      body = "Showers every nearby enemy with poison bolts, dealing instant Nature damage followed by a lingering damage-over-time tick." },
    { title = "Rain of Fire", flags = 16, spell = 28794,
      body = "Calls down fire on a targeted area, punishing anyone who stays inside the zone for its duration." },
    { title = "Frenzy", flags = 2048, spell = 28798,
      body = "Doubles her physical damage and speeds her attacks — Faerlina's adds must be mind-controlled to silence her before this triggers, or the tank needs strong cooldowns to survive it." },
    { title = "Widow's Embrace", flags = 32, spell = 28790,
      body = "Sacrificing a captive Worshipper silences Faerlina's Nature spells and prevents her Frenzy for a time — a defensive tool the encounter is built around using." },
  },
  [1603] = { -- Maexxna
    { title = "Web Wrap", flags = 16, spell = 28622,
      body = "Wraps a random player in a sticky cocoon and hauls them to the wall, dealing Nature damage every second until the web is destroyed." },
    { title = "Web Spray", flags = 16, spell = 28841,
      body = "Sprays webbing across the whole room, stunning and damaging everyone caught in the open." },
    { title = "Necrotic Poison", flags = 512, spell = 28776,
      body = "A deadly poison that reduces all healing received by the target by a huge margin for half a minute — the tank needs external cooldowns or a swap to survive it." },
  },
  [1604] = { -- Noth the Plaguebringer
    { title = "Curse of the Plaguebringer", flags = 256, spell = 29213,
      body = "Curses nearby players; if it isn't dispelled within ten seconds, it erupts for heavy Shadow damage to the cursed player and everyone near them." },
    { title = "Blink", flags = 32, spell = 29210,
      body = "Teleports Noth to a new target, clearing all stuns and roots on him and wiping his threat table completely — tanks need to reacquire him fast." },
    { title = "Cripple", flags = 16, spell = 29212,
      body = "Reduces the target's movement speed, attack speed, and strength significantly for the duration." },
    { title = "Summon Skeletons", flags = 32, spell = 0,
      body = "Raises Plagued Warriors and Skeletons from the balcony floor plates to assault the raid; these need to be cleared alongside Noth himself." },
  },
  [1605] = { -- Heigan the Unclean
    { title = "Eruption", flags = 16, spell = 29371,
      body = "Erupts specific floor quadrants with toxic sludge in a rolling pattern — the well-known 'Heigan dance' where the raid must dodge each wave in sequence." },
    { title = "Spell Disruption", flags = 128, spell = 29310,
      body = "An aura that triples the cast time of every nearby enemy's spells, punishing casters who try to stand and nuke through the dance phase." },
    { title = "Decrepit Fever", flags = 1024, spell = 29998,
      body = "Afflicts nearby players with a heavy fever that deals Nature damage and drains Stamina — a reason to keep some distance during the tank-and-spank phase." },
  },
  [1606] = { -- Loatheb
    { title = "Necrotic Aura", flags = 4, spell = 29184,
      body = "A deathly pulse that blocks all healing received by the raid for the encounter's duration — direct heals must be timed for the brief windows between casts, or absorbed with cooldowns." },
    { title = "Deathbloom", flags = 16, spell = 29865,
      body = "Deals Shadow damage over several seconds, then blooms for a large final hit when it expires — spread out before it detonates." },
    { title = "Inevitable Doom", flags = 256, spell = 29204,
      body = "A terminal curse on a random player that deals heavy Shadow damage after ten seconds; there's no way to remove it, only heal or cooldown through the hit." },
    { title = "Summon Spores", flags = 32, spell = 29234,
      body = "Plague Spores drift toward the raid and, when killed, burst into a cloud that boosts critical strike chance and drops threat for anyone standing in it — useful for DPS to pop deliberately." },
  },
  [1607] = { -- Instructor Razuvious
    { title = "Unbalancing Strike", flags = 1, spell = 26613,
      body = "A heavy strike against his target that also cuts their defense skill, making follow-up hits land harder." },
    { title = "Disrupting Shout", flags = 64, spell = 29107,
      body = "A wide interrupt-and-silence shout that locks out spellcasting for anyone caught nearby." },
    { title = "Jagged Knife", flags = 8192, spell = 55550,
      body = "Throws a knife that deals Physical damage and opens a bleeding wound that ticks for several seconds." },
  },
  [1608] = { -- Gothik the Harvester
    { title = "Harvest Soul", flags = 512, spell = 28679,
      body = "Drains souls from nearby players, dealing Shadow damage and growing stronger with each soul taken — don't let Gothik linger uncontested on the living side." },
    { title = "Unholy Aura", flags = 128, spell = 28350,
      body = "Pulses unholy energy that damages everyone in the room every couple of seconds, on top of the waves of undead spilling in from both sides of the gate." },
  },
  [1609] = { -- The Four Horsemen
    { title = "Unholy Shadow", flags = 128, spell = 28863,
      body = "Strikes a target with dark magic for a large initial hit followed by a lingering Shadow damage-over-time." },
    { title = "Holy Wrath", flags = 128, spell = 28883,
      body = "Strikes a target with Holy energy that then jumps on to nearby allies, spreading damage across whoever is stacked together." },
    { title = "Void Zone", flags = 16, spell = 28865,
      body = "Drops a damaging void zone on the ground beneath a target; move it off the raid immediately." },
    { title = "Meteor", flags = 16, spell = 28884,
      body = "Calls down a meteor that splits heavy Fire damage among everyone within its blast radius — spread out to soften the hit." },
  },
  [1610] = { -- Patchwerk
    { title = "Hateful Strike", flags = 1, spell = 28308,
      body = "Slams the melee-range player with the highest current health for extreme Physical damage, then resets its target list — tanks trade this hit back and forth." },
    { title = "Frenzy", flags = 2048, spell = 28131,
      body = "Doubles Patchwerk's physical damage and speeds up his attacks for half a minute; healers should be ready for the tank swap and burn window." },
    { title = "Berserk", flags = 2048, spell = 26662,
      body = "If the enrage timer expires, Patchwerk's damage and speed spike catastrophically — this is effectively an unsurvivable wipe condition, not a mechanic to heal through." },
  },
  [1611] = { -- Grobbulus
    { title = "Poison Cloud", flags = 512, spell = 28240,
      body = "Leaves a thick, spreading cloud of toxic gas behind him that damages anyone standing inside — keep moving the fight away from old clouds." },
    { title = "Mutating Injection", flags = 512, spell = 28169,
      body = "Injects a player with a toxin that explodes after several seconds (or on dispel), leaving a fresh poison cloud on the ground — run the injected player away from the raid before it pops." },
    { title = "Slime Spray", flags = 16, spell = 28157,
      body = "Sprays a cone of toxic slime in front of him and spawns a Fallout Slime; ranged players should avoid standing directly ahead of Grobbulus." },
  },
  [1612] = { -- Gluth
    { title = "Mortal Wound", flags = 8192, spell = 29337,
      body = "Stacks a physical wound on the tank that reduces healing received further with each application — tank swaps or heavy cooldowns manage the stacking." },
    { title = "Decimate", flags = 16, spell = 28374,
      body = "Crushes every nearby player and zombie down to a sliver of their maximum health — a burst healers should top the raid off before, not after." },
    { title = "Enrage", flags = 2048, spell = 28371,
      body = "Increases Gluth's physical damage and attack speed for a couple of minutes — expect a harder tanking phase during it." },
  },
  [1613] = { -- Thaddius
    { title = "Polarity Shift", flags = 16, spell = 28089,
      body = "Charges every raid member with a Positive or Negative polarity; standing near someone of the opposite charge deals severe damage to both, so the raid must regroup by matching charge each time it flips." },
    { title = "Chain Lightning", flags = 128, spell = 28090,
      body = "Strikes a target with lightning that arcs on to several nearby players for Nature damage." },
  },
  [1614] = { -- Sapphiron
    { title = "Frost Aura", flags = 16, spell = 28531,
      body = "A constant frost pulse that damages everyone in the room every couple of seconds regardless of position." },
    { title = "Icebolt", flags = 16, spell = 28522,
      body = "Freezes a random player and everyone standing near them in a solid block of ice, dealing Frost damage — spread out to avoid chaining the freeze to others." },
    { title = "Frost Breath", flags = 16, spell = 28524,
      body = "A frontal cone of frost that deals massive damage and freezes anyone caught in front of Sapphiron; only face him away from the raid." },
    { title = "Life Drain", flags = 512, spell = 28542,
      body = "Drains life from a couple of random targets, damaging them and healing Sapphiron in return." },
  },
  [1615] = { -- Kel'Thuzad
    { title = "Frost Blast", flags = 16, spell = 27808,
      body = "Locks a player in a block of ice for heavy Frost damage that then chains on to nearby allies — spread the raid to limit how far the bounce reaches." },
    { title = "Shadow Fissure", flags = 16, spell = 27810,
      body = "Marks a spot on the ground that erupts after a few seconds for massive Shadow damage; move off the marked tile before it goes off." },
    { title = "Detonate Mana", flags = 128, spell = 27819,
      body = "Destabilizes a caster's mana pool so it explodes after several seconds, dealing Arcane damage to everyone nearby based on how much mana they had banked." },
    { title = "Chains of Kel'Thuzad", flags = 32, spell = 28410,
      body = "Enslaves several random players, sharply boosting their damage and turning them against their own raid — crowd control or careful damage is needed to handle the charmed players without killing them." },
  },
  -- The Obsidian Sanctum
  [1616] = { -- Sartharion
    { title = "Flame Tsunami", flags = 16, spell = 57491,
      body = "A wall of fire sweeps across the entire platform, dealing massive Fire damage to anyone it reaches — the raid must move to the safe half of the room in time." },
    { title = "Cleave", flags = 1, spell = 56909,
      body = "Strikes his current target and the nearest allies for boosted melee damage in a frontal cone." },
    { title = "Tail Lash", flags = 16, spell = 56910,
      body = "Swings his tail at anyone standing behind him, dealing Physical damage and stunning them — melee must stay to his sides." },
    { title = "Drake Allies", flags = 32, spell = 0,
      body = "Leaving one or more of Tenebron, Shadron, or Vesperon alive for the fight adds their own auras and breath attacks on top of Sartharion's, sharply raising the difficulty in exchange for better loot." },
  },
  -- The Eye of Eternity
  [1617] = { -- Malygos
    { title = "Arcane Storm", flags = 16, spell = 56172,
      body = "Fires a flurry of arcane missiles at random targets, dealing heavy Arcane damage to each one hit." },
    { title = "Vortex", flags = 16, spell = 56105,
      body = "Pulls the entire raid into the air and spins them, dealing Arcane damage every second for the duration — there's little to do but ride it out." },
    { title = "Power Spark", flags = 32, spell = 56152,
      body = "A glowing orb of energy drifts toward Malygos; if it reaches him his damage output increases substantially, so it should be intercepted and destroyed first." },
    { title = "Surge of Power", flags = 16, spell = 56505,
      body = "Sweeps a beam of concentrated arcane energy across the platform during the drake-combat phase — stay out of the beam's path while flying." },
  },
  -- Trial of the Crusader
  [1618] = { -- The Northrend Beasts
    { title = "Impale (Gormok)", flags = 8192, spell = 66331,
      body = "Gormok the Impaler drives his spear into the target for heavy Physical damage and a stacking bleed that lasts half a minute." },
    { title = "Massive Crash (Icehowl)", flags = 16, spell = 66683,
      body = "Icehowl leaps into the arena's center and crashes down, knocking back and stunning everyone nearby." },
    { title = "Trample (Icehowl)", flags = 16, spell = 66734,
      body = "Icehowl charges across the floor toward a marked player — anyone directly in his path takes a devastating hit, so clear the lane." },
  },
  [1619] = { -- Lord Jaraxxus
    { title = "Fel Fireball", flags = 16, spell = 66228,
      body = "Hurls a corrupted fireball at the tank for a heavy instant hit followed by a lingering Fire damage-over-time." },
    { title = "Incinerate Flesh", flags = 4, spell = 66237,
      body = "Marks a player with a debuff that absorbs incoming healing; if they aren't healed past the absorb amount in time, it explodes for massive raid-wide Fire damage." },
    { title = "Legion Flame", flags = 16, spell = 66197,
      body = "Blasts a player with hellfire and leaves a trail of flame patches spreading from their location — move away from the raid while marked." },
  },
  [1620] = { -- Champions of the Alliance
    { title = "Rival Team Tactics", flags = 32, spell = 0,
      body = "A team of enemy-faction heroes fights with full class kits and no fixed threat table, dynamically targeting low-health or crowd-controlled players — focus fire, peel, and burst cooldowns matter more than tanking here." },
  },
  [1621] = { -- Champions of the Horde
    { title = "Rival Team Tactics", flags = 32, spell = 0,
      body = "A team of enemy-faction heroes fights with full class kits and no fixed threat table, dynamically targeting low-health or crowd-controlled players — focus fire, peel, and burst cooldowns matter more than tanking here." },
  },
  [1622] = { -- Twin Val'kyr
    { title = "Twin Spikes", flags = 1, spell = 66075,
      body = "A coordinated strike from both sisters that raises the target's damage taken from the opposite magic school for a time." },
    { title = "Shield of Darkness", flags = 4, spell = 65874,
      body = "One twin shields herself with a massive damage absorb and channels a continuous heal — she must be attacked through the shield or the fight stalls." },
    { title = "Light Vortex (Fjola)", flags = 128, spell = 66058,
      body = "Fjola Lightbane channels a whirlwind of holy energy that damages everyone not carrying the matching Light Essence." },
    { title = "Dark Vortex (Eydis)", flags = 128, spell = 66046,
      body = "Eydis Darkbane channels a whirlwind of shadow energy that damages everyone not carrying the matching Dark Essence — swapping essences between casts is the core of the fight." },
  },
  [1623] = { -- Anub'arak
    { title = "Penetrating Cold", flags = 16, spell = 66013,
      body = "Pierces several random raid members with bone-deep cold, dealing repeating Frost damage over the debuff's duration." },
    { title = "Freezing Slash", flags = 16, spell = 66012,
      body = "Encases the tank in ice with a heavy strike, stunning them briefly and cutting their armor." },
    { title = "Leeching Swarm", flags = 512, spell = 66118,
      body = "Releases scarabs that drain a percentage of every raid member's current health each second, healing Anub'arak with every tick — this is a hard enrage-style burn phase, not something to stall through." },
    { title = "Impale", flags = 16, spell = 56090,
      body = "Drives spikes up through the ground beneath a player, dealing lethal Physical damage — standing on a frozen Permafrost patch blocks the spike from erupting." },
  },
  -- Icecrown Citadel
  [1624] = { -- Lord Marrowgar
    { title = "Bone Slice", flags = 1, spell = 69055,
      body = "Strikes the tank and up to two nearby players for heavy Physical damage in a frontal cone." },
    { title = "Coldflame", flags = 16, spell = 69146,
      body = "Fires a line of blue fire toward a random player that leaves a damaging trail on the ground — walk it away from the raid rather than through it." },
    { title = "Bone Spike Graveyard", flags = 16, spell = 69057,
      body = "Impales random players on bone spikes, stunning them and dealing damage over time until the spike is destroyed — free the impaled players quickly." },
    { title = "Bone Storm", flags = 16, spell = 69076,
      body = "Spins in a hurricane of bone fragments for half a minute, chasing and damaging anyone in range — keep moving and away from melee during it." },
  },
  [1625] = { -- Lady Deathwhisper
    { title = "Mana Barrier", flags = 128, spell = 70842,
      body = "In phase one she's shielded by a mana-based barrier instead of health and immune to physical damage — casters carry this phase while melee help clear adds." },
    { title = "Death and Decay", flags = 16, spell = 71001,
      body = "Corrupts a targeted area of ground, dealing Shadow damage every second to anyone standing inside — move out immediately." },
    { title = "Shadow Bolt Volley", flags = 128, spell = 71002,
      body = "Hurls dark bolts at several targets at once for Shadow damage." },
    { title = "Dominate Mind", flags = 32, spell = 71289,
      body = "Mind-controls several random players to fight for the Cult of the Damned — crowd control or careful damage keeps them from doing too much harm before it wears off." },
  },
  [1626] = { -- Icecrown Gunship Battle
    { title = "Below Zero", flags = 16, spell = 69705,
      body = "Freezes the deck's machinery and slows nearby players' attack and casting speed — a reason to spread out on the ship's deck." },
    { title = "Burning Pitch", flags = 16, spell = 69709,
      body = "Hurls burning pitch onto the enemy ship's deck, leaving patches that burn anyone who lingers near them." },
    { title = "Boarding Phase", flags = 32, spell = 0,
      body = "Once the ships close, enemy officers and mages teleport aboard and must be killed quickly — leaving them alive lets them wreak havoc on the deck crew." },
  },
  [1627] = { -- Icecrown Gunship Battle
    { title = "Below Zero", flags = 16, spell = 69705,
      body = "Freezes the deck's machinery and slows nearby players' attack and casting speed — a reason to spread out on the ship's deck." },
    { title = "Burning Pitch", flags = 16, spell = 69709,
      body = "Hurls burning pitch onto the enemy ship's deck, leaving patches that burn anyone who lingers near them." },
    { title = "Boarding Phase", flags = 32, spell = 0,
      body = "Once the ships close, enemy officers and mages teleport aboard and must be killed quickly — leaving them alive lets them wreak havoc on the deck crew." },
  },
  [1628] = { -- Deathbringer Saurfang
    { title = "Boiling Blood", flags = 16, spell = 72241,
      body = "Deals Shadow damage over time to a random player and heals Saurfang for the full amount dealt — a reason to keep his health pressured rather than let this tick freely." },
    { title = "Mark of the Fallen Champion", flags = 256, spell = 72293,
      body = "Curses a player so that whenever Saurfang's Blood Beasts deal damage or he gains Blood Power, the marked player takes a percentage of their max health as true damage — the mark should be dispelled or managed carefully." },
    { title = "Blood Beasts", flags = 32, spell = 72173,
      body = "At high Blood Power, Saurfang summons Blood Beasts that must be tanked and killed quickly before their bleeding attacks stack out of control." },
  },
  [1629] = { -- Festergut
    { title = "Gaseous Blight", flags = 1024, spell = 72193,
      body = "Fills the room with a noxious blight that deals Shadow damage every few seconds, stacking up as the fight progresses." },
    { title = "Gas Spore", flags = 32, spell = 69279,
      body = "Inoculates a random player with a volatile spore that explodes after several seconds, damaging nearby allies but granting the target resistance to future Blight stacks — that player should move away from the raid before it pops." },
    { title = "Vile Gas", flags = 16, spell = 71218,
      body = "Sprays a foul gas on a random player, forcing them to vomit and move away from the group for several seconds." },
    { title = "Pungent Blight", flags = 16, spell = 71219,
      body = "Consumes all of Festergut's built-up Blight stacks to unleash a massive room-wide burst of Nature damage — this typically defines the enrage timer for the fight." },
  },
  [1630] = { -- Rotface
    { title = "Slime Spray", flags = 16, spell = 69508,
      body = "Sprays a cone of toxic slime in front of him and spawns a Fallout Slime — face him away from the raid." },
    { title = "Mutated Infection", flags = 1024, spell = 69674,
      body = "Injects a toxic ooze into a player that ticks Shadow damage and, when it expires, spawns a small ooze that must be kited into the larger oozes to merge and pop them." },
    { title = "Unstable Ooze Explosion", flags = 16, spell = 69839,
      body = "A large merged ooze explodes violently for heavy Nature damage to anyone within range and spawns more small oozes — pop these away from the raid." },
  },
  [1631] = { -- Professor Putricide
    { title = "Slime Puddle", flags = 16, spell = 70341,
      body = "Drops a pool of slime beneath a target that slows movement and deals Nature damage over time — step out of the puddle." },
    { title = "Choking Gas Bomb", flags = 64, spell = 71255,
      body = "Hurls gas bombs around the room; stepping near one releases a cloud that silences and causes attacks to miss for anyone caught inside." },
    { title = "Malleable Goo", flags = 16, spell = 72295,
      body = "Hurls a glob of slime at a location, damaging anyone nearby and slowing their attack and casting speed heavily." },
    { title = "Phase Transformations", flags = 32, spell = 0,
      body = "Putricide periodically drinks experimental mutagens that reshape the fight's mechanics for a time (Gas, Ooze, or a blend of both) — the raid needs to adapt to whichever phase is active." },
  },
  [1632] = { -- Blood Prince Council
    { title = "Kinetic Bomb", flags = 16, spell = 72053,
      body = "Summons a slow floating orb toward a random player; if it reaches the ground it explodes for damage scaled to how high it was when it landed — intercept and pop it early." },
    { title = "Glittering Sparks", flags = 64, spell = 71396,
      body = "The active Prince emits dazzling sparks that deal Fire damage and interrupt spellcasting for anyone standing too close." },
    { title = "Shadow Resonance", flags = 128, spell = 71822,
      body = "Empowers the currently active Prince, boosting their damage output — the raid rotates which Prince is targeted as this stacks up, to keep from over-committing to one." },
  },
  [1633] = { -- Blood-Queen Lana'thel
    { title = "Shroud of Sorrow", flags = 128, spell = 70986,
      body = "A constant aura of despair that deals Shadow damage to the whole raid every few seconds for the entire fight — sustained raid healing is required throughout." },
    { title = "Essence of the Blood-Queen", flags = 512, spell = 70879,
      body = "Infects a player with vampiric essence, doubling their damage and letting them heal from it — but they must bite another player before the buff expires or take a severe penalty; managing the bite chain carefully avoids an uncontrolled vampire outbreak." },
    { title = "Swarming Shadows", flags = 16, spell = 71264,
      body = "The targeted player leaves trails of dark shadow fire behind them as they move — walk this trail away from the raid." },
  },
  [1634] = { -- Valithria Dreamwalker
    { title = "Dream Portals", flags = 4, spell = 71305,
      body = "Green portals to the Nightmare occasionally open; stepping through and collecting Emerald Vigor sharply boosts a healer's output for the rest of the encounter — this is a healing-check fight built around keeping Valithria's health climbing." },
    { title = "Suppressor Aura", flags = 4, spell = 71743,
      body = "Nightmare invaders reduce all healing Valithria receives while alive — killing the adds (especially the Suppressers) as they spawn is as important as the direct healing." },
  },
  [1635] = { -- Sindragosa
    { title = "Frost Aura", flags = 16, spell = 70084,
      body = "A constant frost pulse that damages everyone in the room regardless of position." },
    { title = "Permeating Chill", flags = 128, spell = 70109,
      body = "Every spell a player casts stacks a chilling debuff that deals Frost damage when it expires — casters should be mindful of how many stacks they're carrying." },
    { title = "Unchained Magic", flags = 128, spell = 70134,
      body = "Builds instability the more a player casts spells, eventually triggering a backlash explosion — another reason for casters to pace their output." },
    { title = "Blistering Cold", flags = 16, spell = 70123,
      body = "Channels an absolute-zero shockwave that deals massive Frost damage to anyone within range; breaking line of sight behind an Ice Tomb is the only way to survive it." },
    { title = "Icy Grip / Frost Beacon", flags = 16, spell = 70117,
      body = "Pulls the raid to the platform's center and marks random players with frost beacons that encase them in Ice Tombs shortly after — these Tombs double as the only shelter from Blistering Cold." },
  },
  [1636] = { -- The Lich King
    { title = "Infest", flags = 1024, spell = 70541,
      body = "Infests a target with ghoulish parasites that deal Shadow damage over time, worsening if the target's health drops too low — healing above the threshold matters." },
    { title = "Necrotic Plague", flags = 1024, spell = 70337,
      body = "A terminal plague that deals Shadow damage every few seconds and jumps to the nearest player when it expires or is dispelled, growing the Lich King's power each time it spreads — passing it around deliberately is part of managing the fight." },
    { title = "Remorseless Winter", flags = 16, spell = 68981,
      body = "Channels an icy vortex around the platform's edge that instantly kills anyone who steps outside the safe inner circle." },
    { title = "Defile", flags = 16, spell = 72762,
      body = "Grows a corrupted pool beneath a player's feet that expands and deals more damage the longer it persists — move it to an unused corner of the platform immediately." },
    { title = "Soul Reaper", flags = 1, spell = 69409,
      body = "A heavy strike on the tank that leaves a shadow debuff dealing massive damage after five seconds unless mitigated with a defensive cooldown — tank swaps are typically timed around this." },
    { title = "Raging Spirits", flags = 32, spell = 69200,
      body = "Summons spectral warriors that chase random players and must be controlled or killed before their attacks add up on top of everything else happening on the platform." },
  },
  -- Ulduar
  [1637] = { -- Flame Leviathan
    { title = "Flame Vents", flags = 16, spell = 62396,
      body = "Channels jets of fire from its side turrets, dealing heavy Fire damage per second to everyone within a wide radius." },
    { title = "Battering Ram", flags = 16, spell = 62376,
      body = "Charges forward and slams into a vehicle for greatly increased damage, knocking it back — evasive driving matters more than tanking the hit." },
    { title = "Systems Overload", flags = 32, spell = 62475,
      body = "Forces a temporary shutdown that increases damage taken by the Leviathan by half while disabling its attacks — the burn window vehicle turrets should focus." },
  },
  [1638] = { -- Ignis the Furnace Master
    { title = "Flame Jets", flags = 16, spell = 62680,
      body = "Erupts the ground in flame, interrupting spellcasting and dealing Fire damage over time to everyone nearby." },
    { title = "Slag Pot", flags = 16, spell = 62717,
      body = "Grabs a random player and dunks them in the molten furnace pot, dealing heavy Fire damage every second until they're freed." },
    { title = "Scorch", flags = 16, spell = 62686,
      body = "Blasts a trail of fire along the ground in front of him that deals damage over time to anyone standing in it." },
  },
  [1639] = { -- Razorscale
    { title = "Devouring Flame", flags = 16, spell = 62796,
      body = "Spits a fireball that leaves a spreading sea of blue fire on the ground, dealing heavy Fire damage per second to anyone standing in it." },
    { title = "Flame Buffet", flags = 16, spell = 64016,
      body = "Stacks Fire damage taken on the current target with each application — the tank should be swapped before the stacks climb too high." },
    { title = "Harpoon Phase", flags = 32, spell = 0,
      body = "Before she can be fought on the ground, Razorscale must be harpooned out of the sky repeatedly while her adds are managed — skipping this phase isn't an option." },
  },
  [1640] = { -- XT-002 Deconstructor
    { title = "Tympanic Tantrum", flags = 16, spell = 62776,
      body = "Channels a room-wide sound wave that deals a percentage of everyone's maximum health as Physical damage every second and dazes them for the duration." },
    { title = "Searing Light", flags = 128, spell = 63018,
      body = "Burns a random player with holy energy, dealing heavy Holy damage and causing them to burn nearby allies — spread away from the group when marked." },
    { title = "Gravity Bomb", flags = 16, spell = 63024,
      body = "Traps a player in a gravitational field that explodes after several seconds, pulling in and damaging anyone nearby — move away from the raid before it detonates." },
  },
  [1641] = { -- The Assembly of Iron
    { title = "Fusion Punch", flags = 1, spell = 61903,
      body = "A heavy melee strike on the tank followed by a lingering Nature damage tick — cooldowns help smooth out the burst." },
    { title = "Rune of Power", flags = 32, spell = 61974,
      body = "Drops a rune zone on the ground that boosts the damage of anyone standing inside it, boss or player — the raid can use this deliberately during burn phases." },
    { title = "Static Overload", flags = 128, spell = 61909,
      body = "Charges a random player with electricity that pulses outward, damaging nearby allies — spread out when marked." },
  },
  [1642] = { -- Kologarn
    { title = "Stone Grip", flags = 16, spell = 62166,
      body = "Squeezes a player in his massive stone fist, dealing damage every second until the arm takes enough damage to force a release — focus the grabbing arm down quickly." },
    { title = "Focused Eyebeams", flags = 16, spell = 63346,
      body = "Tracks a target with twin laser beams from his eyes, dealing heavy Fire damage per second to anyone caught in the beam's path." },
    { title = "Overhead Smash", flags = 1, spell = 62019,
      body = "A heavy overhead slam on the tank that also reduces their armor with each stack, making later hits progressively worse." },
  },
  [1643] = { -- Auriaya
    { title = "Sonic Screech", flags = 16, spell = 64688,
      body = "A piercing frontal blast that splits heavy Physical damage among everyone it hits — avoid standing in front of her." },
    { title = "Terrifying Screech", flags = 16, spell = 64386,
      body = "A horrific roar that sends every nearby player fleeing in terror for several seconds." },
    { title = "Feral Defender", flags = 32, spell = 64447,
      body = "Summons a Feral Defender that channels a beam linking it to Auriaya, healing her while active — the beam must be broken or the defender killed to stop the drain." },
  },
  [1644] = { -- Hodir
    { title = "Biting Cold", flags = 16, spell = 62038,
      body = "A stacking frost debuff that builds the longer a player stands still — keep moving to avoid the damage climbing out of control." },
    { title = "Flash Freeze", flags = 16, spell = 61968,
      body = "Encases every exposed player and NPC in blocks of ice; sheltering in one of the room's warming snowdrifts blocks the effect entirely." },
    { title = "Frozen Blows", flags = 16, spell = 62478,
      body = "Infuses Hodir's weapon with frost, trading some physical damage for a large Frost damage component on every swing." },
  },
  [1645] = { -- Thorim
    { title = "Chain Lightning", flags = 128, spell = 64363,
      body = "Strikes a target with lightning that arcs on to several nearby allies for Nature damage." },
    { title = "Lightning Charge", flags = 16, spell = 62466,
      body = "Draws a beam of electricity from the arena's pillars, damaging anyone in the beam's path and empowering Thorim's attack power." },
    { title = "Unbalancing Strike", flags = 1, spell = 62130,
      body = "A heavy strike on the tank that also cuts their defense skill for several seconds, making follow-up attacks hit harder." },
  },
  [1646] = { -- Freya
    { title = "Sunbeam", flags = 16, spell = 62623,
      body = "Drops a pillar of light on a random target, dealing Nature damage and silencing anyone caught within it — step out of the beam quickly." },
    { title = "Bright Waves", flags = 4, spell = 62626,
      body = "Sends a wave of nature magic across the room that heals Freya's allied Elders or damages the raid depending on the fight's setup." },
    { title = "Touch of Eonar", flags = 4, spell = 62528,
      body = "Channels a large heal on Freya from a Lifebinder's Gift totem — interrupting or killing the source quickly denies the healing." },
    { title = "Attuned Elders", flags = 32, spell = 0,
      body = "Choosing to fight Freya's three Elder Nature Guardians alongside her (Ironbranch, Brightleaf, Stonebark) adds their own auras — more Elders means a longer, harder, but more rewarding fight." },
  },
  [1647] = { -- Mimiron
    { title = "Proximity Mines", flags = 16, spell = 63297,
      body = "Scatters mines across the floor that detonate for Fire damage when stepped on or walked near — watch your footing during his mobile phases." },
    { title = "Plasma Blast", flags = 16, spell = 62997,
      body = "Channels a beam of plasma at the tank, dealing heavy Fire damage per second for several seconds." },
    { title = "Laser Barrage", flags = 16, spell = 63274,
      body = "A rapid spinning laser sweep that deals heavy damage per second to anyone caught directly in its frontal path." },
    { title = "Shock Blast", flags = 16, spell = 63631,
      body = "After a visible cast, deals massive Nature damage to everyone within range — this phase punishes staying too close to the boss's platform." },
  },
  [1648] = { -- General Vezax
    { title = "Aura of Despair", flags = 128, spell = 62692,
      body = "Shuts off all passive and spell-based mana regeneration in the room while boosting his own physical attack speed — mana management becomes the core of the fight." },
    { title = "Shadow Crash", flags = 16, spell = 62660,
      body = "Fires a missile of dark energy at a location, leaving behind a pool that reduces spell costs and speeds up casting — standing in it deliberately can help mana-starved casters." },
    { title = "Searing Flames", flags = 64, spell = 62661,
      body = "A channeled blast of Fire damage that also strips armor from everyone nearby unless interrupted." },
    { title = "Mark of the Faceless", flags = 512, spell = 63276,
      body = "Siphons health from a random player and heals Vezax from nearby Saronite Vapors — killing the vapors before he can drain them limits the healing." },
  },
  [1649] = { -- Yogg-Saron
    { title = "Brain Link", flags = 128, spell = 63802,
      body = "Links two players with a psychic beam; if they drift more than 20 yards apart they both take heavy Shadow damage and lose Sanity — stay paired up close together." },
    { title = "Malady of the Mind", flags = 256, spell = 63830,
      body = "A psychic curse that deals Shadow damage and briefly stuns the target in horror before jumping to another nearby ally." },
    { title = "Psychosis", flags = 128, spell = 65301,
      body = "Blasts a target's mind with Shadow damage and drains a chunk of their Sanity — low Sanity eventually causes hallucinations and loss of control." },
    { title = "Lunatic Gaze", flags = 16, spell = 64163,
      body = "A dark visual wave from Yogg-Saron himself — looking directly at him during the cast deals Shadow damage and rapidly drains Sanity, so face away." },
  },
  [1650] = { -- Algalon the Observer
    { title = "Quantum Strike", flags = 1, spell = 64412,
      body = "A precise strike on the tank that partially bypasses armor for high Physical damage." },
    { title = "Cosmic Smash", flags = 16, spell = 62311,
      body = "Calls down a cosmic sphere at a location, dealing heavy Fire damage to anyone near the impact and tapering off with distance — step away from the marked spot." },
    { title = "Big Bang", flags = 16, spell = 64584,
      body = "An arena-wide cosmic explosion that deals catastrophic Physical damage to everyone — the raid must take shelter inside a Shadow Crevice to survive it." },
  },
  -- Onyxia's Lair
  [1651] = { -- Onyxia
    { title = "Deep Breath", flags = 16, spell = 0,
      body = "Flies to one end of the lair and exhales a scorching line of fire the length of the room, dealing devastating Fire damage to anyone caught in its path." },
    { title = "Flame Breath", flags = 16, spell = 0,
      body = "A frontal cone of fire while grounded — stay out of Onyxia's front arc, especially melee." },
    { title = "Wing Buffet", flags = 16, spell = 0,
      body = "Knocks back everyone standing behind her with a sweep of her wings; melee positioning matters throughout the ground phases." },
    { title = "Bellowing Roar", flags = 16, spell = 0,
      body = "Fears everyone in the room briefly — trinkets and fear breaks help keep the raid from scattering into other mechanics." },
    { title = "Whelp Phases", flags = 32, spell = 0,
      body = "Onyxia periodically takes to the air and rains fireballs down while spawning waves of whelps from the room's eggs; the whelps must be tanked and cleared until she lands again." },
  },
  -- The Ruby Sanctum
  [1652] = { -- Halion
    { title = "Flame Tsunami", flags = 16, spell = 74711,
      body = "A wall of dark fire sweeps across the platform in the physical realm, dealing heavy Fire damage to anyone caught in its path." },
    { title = "Meteor Strike", flags = 16, spell = 74648,
      body = "Marks a location that erupts into a massive meteor after several seconds, splitting heavy Fire damage among nearby players and spawning fire elementals." },
    { title = "Fiery Combustion", flags = 16, spell = 74562,
      body = "A stacking Fire damage-over-time on a target and everyone within 10 yards that leaves a burning pool on the ground when it ends or is dispelled." },
    { title = "Soul Consumption", flags = 512, spell = 74792,
      body = "The Twilight Realm counterpart to Fiery Combustion — a stacking Shadow damage-over-time that leaves a lingering void pool behind when it expires." },
    { title = "Twilight Cutter", flags = 16, spell = 74769,
      body = "Four rotating shadow orbs sweep razor-sharp beams of twilight energy across the Twilight Realm platform — touching one is lethal, so track their rotation and stay clear." },
  },
}

EJ.ej.ABIL_WOTLK = ABIL

local function applyAbilities()
  local data = EJ.ej.DATA
  if not data then return end
  for _, inst in ipairs(data.instances or {}) do
    for _, enc in ipairs(inst.encounters or {}) do
      local list = ABIL[enc.id]
      if list and (FORCE[enc.id] or not enc.sections or #enc.sections == 0) then
        local secs, n = {}, #list
        for i, a in ipairs(list) do
          secs[i] = {
            id = enc.id * 1000 + i, title = a.title, parent = 0, child = 0,
            sib = (i < n) and (enc.id * 1000 + i + 1) or 0, order = i,
            spell = a.spell or 0, icon = 0, flags = a.flags or 0, cdisp = 0, body = a.body,
          }
        end
        enc.sections = secs
        enc.rootSection = secs[1] and secs[1].id or 0
      end
    end
  end
end
applyAbilities()
