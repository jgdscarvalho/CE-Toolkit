------------------------------------------------------------------------------------------------------------------------
-- Cheat Engine toolkit for Dynasty Warriors 6 (PlayStation 2).
------------------------------------------------------------------------------------------------------------------------
-- Author                  | Zé Gabriel
-- Repository              | https://github.com/jgdscarvalho
-- License                 | MIT
-- SPDX-License-Identifier | MIT
-- Game                    | Dynasty Warriors 6
-- Platform                | PlayStation 2
-- Version                 | SLUS-21774
-- Description             | All character tables.
------------------------------------------------------------------------------------------------------------------------

--- A table of colors used as palette of record colors.
local colors = {
    SOFT_RED      = 225 + (128 * 256) + (128 * 65536), -- R: 225 | G: 128 | B: 128
    EMERALD_GREEN =   0 + (255 * 256) + (128 * 65536), -- R:   0 | G: 255 | B: 128
    PINK          = 255 + (128 * 256) + (255 * 65536), -- R: 255 | G: 128 | B: 255
    ORANGE        = 255 + (128 * 256) + (  0 * 65536), -- R: 255 | G: 128 | B:   0
    LIGHT_GREEN   = 128 + (255 * 256) + (128 * 65536), -- R: 128 | G: 255 | B: 128
    BLUE          = 128 + (128 * 256) + (255 * 65536), -- R: 128 | G: 128 | B: 255
}

------------------------------------------------------------------------------------------------------------------------

--- Scans the memory to locate Xiahou Dun's weapons base address.
---
-- • @return number: The memory address corresponding to Xiahou Dun's table.
local function search_xiahou_dun_address()
   print("Searching for Xiahou Dun's address...")

   -- This scan attempts to locate Xiahou Dun's base statistics as an array of bytes.
   local scan = AOBScan("00 00 00 00 08 00 00 00 00 00 00 00 00 00 00 00 \z
                         00 00 00 00 00 00 00 00 03 00 00 00 00 00 00 00 \z
                         AE 00 00 00 00 00 00 00 03 00 00 00 00 00 00 00 \z
                         AE 00 00 00 00 00 00 00 03 00 00 00 00 00 00 00 \z
                         AE 00 00 00 00 00 00 00 03 00 00 00 00 00 00 00 \z
                         AE 00 00 00 00 00 00 00 03 00 00 00 00 00 00 00 \z
                         AE 00 00 00 00 00 00 00 03 00 00 00 00 00 00 00 \z
                         AE 00 00 00 00 00 00 00 03 00 00 00 00 00 00 00 \z
                         AE 00 00 00 00 00 00 00 03 00 00 00 00 00 00 00 \z
                         00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 \z
                         00 00 00 00 00 00 00 00 00 00 00 00 01 00 00 00")

   if not scan or scan.Count == 0 then
      error("No address has been found! Are you running the script with an empty save?")
   end

   print(string.format("A total of %d similar addresses has been found!", scan.Count))

   -- Iterate through the scan results to find the first address after the module's base address.
   -- This ensures the correct address is returned, since multiple static instances of the same data may be found.
   for i = 1, scan.Count do
      local address = tonumber(scan[i - 1], 16)

      -- Koei replicate character tables a lot all over the memory.
      -- The actual master memory value is located in the ninth block.
      if i == 8 then
         address = tonumber(scan[i - 1], 16)

         print(string.format("Xiahou Dun's master address found, address %X!", address))

         scan.destroy()

         return address
      end
   end

   scan.destroy()

   error("The master address was not found! Are you running the script with an empty save?")
end

------------------------------------------------------------------------------------------------------------------------

--- Creates a character table of memory records for a given character address.
---
-- • @parameter parent_header: Memory record of the "Characters" header.
-- • @parameter character_address: Memory address of the character.
-- • @parameter character_name: Character name to be the cell description.
local function create_character_records(parent_header, character_address, character_name)
   local character_header = AddressList.createMemoryRecord()

   character_header.Parent = parent_header
   character_header.Description = character_name
   character_header.IsGroupHeader = true
   character_header.Color = colors.SOFT_RED

   local offset = -4 -- Adjustment to compensate the first for loop calculation.

   local leading_struct = { -- Size: 16 bytes.

      -- Unknown.
      --
      -- Size: 4 bytes.
      "???",
      -- Unknown, but for some reason only Xiahou Dun has it, with the value of 08 00 00 00.
      --
      -- Size: 4 bytes.
      "???",
      -- A pointer to the character's skills table.
      --
      -- This table stores the character's learned skills as a bitmask,
      -- where each bit represents a specific skill state.
      --
      -- A character can have up to 49 skills in total.
      -- Since the skill layout differs between characters, this script does not document each individual skill entry.
      --
      -- No one will see this table, so there is no need to document it individually.
      --
      -- Size: 4 bytes.
      "Skills",
   }

   for i = 1, #leading_struct do
      offset = offset + 4

      local address = string.format("%X", character_address + offset)
      local description = leading_struct[i]
      local entry = AddressList.createMemoryRecord()

      entry.Parent = character_header
      entry.Description = description
      entry.Address = address
      entry.VarType = vtDword
      entry.DisplayAsChild = true
      entry.Color = colors.BLUE

      -- Skills cell uses 8 bytes instead of 4.
      if i == 3 then
         offset = offset + 4

         entry.VarType = vtQword
      end
   end

   local weapons_header = AddressList.createMemoryRecord()

   weapons_header.Description = "Weapons"
   weapons_header.IsGroupHeader = true
   weapons_header.Parent = character_header
   weapons_header.DisplayAsChild = true
   weapons_header.Color = colors.SOFT_RED

   
   local weapon_struct = { -- Size: 128 bytes.

      -- Weapon identifier.
      --
      -- Unlike previous Dynasty Warriors titles, Dynasty Warriors 6 does not use a weapon rarity system.
      --
      -- Weapons are instead categorized into three distinct weapon classes:
      --
      --    Standard: Attack range increases.
      --    Strength: Attack power increases.
      --    Skill: Attack speed increases.
      --
      -- The weapon class is intrinsically tied to the weapon identifier.
      --
      -- Because of this, each character only has three valid weapon identifiers, corresponding to their Standard,
      -- Strength and Skill weapons.
      --
      ------------------------------------------------------------------------------------------------------------------
      -- Xiahou Dun                 | 000: Rock Crusher         | 001: Wave Breaker         | 002: Thundersmash
      -- Dian Wei                   | 003: Violent Soul Flail   | 004: Lion's Head Flail    | 005: Berserker Flail
      -- Sima Yi                    | 006: Eradication Claws    | 007: Anguish Claws        | 008: Necrosis Claw
      -- Zhang Liao                 | 009: Twin Vipers          | 010: Twin Dragons         | 011: Twin Eagles
      -- Cao Cao                    | 012: Sword of Heaven      | 013: Blue Blade           | 014: Seven Star Sword
      -- Zhou Yu                    | 015: Red Dusk             | 016: Dark Knight          | 017: Scarlet Dawn
      -- Lu Xun                     | 018: Silver Swallow       | 019: Blue Falcon          | 020: Jade Warbier
      -- Sun Shang Xiang            | 021: Madder Rose          | 022: Wisteria Breeze      | 023: Lotus Bow
      -- Gan Ning                   | 024: Crescent Moon        | 025: Dancing Dragon       | 026: Wing Blade
      -- Sun Jian                   | 027: Elder Sword          | 028: Nine Hook Sword      | 029: Golden Phoenix
      -- Zhao Yun                   | 030: Dragon Spike         | 031: Dragon Fang          | 032: Dragon Talon
      -- Guan Yu                    | 033: Blue Dragon          | 034: Black Dragon         | 035: White Dragon
      -- Zhang Fei                  | 036: Serpent Blade        | 037: Python Blade         | 038: Viper Blade
      -- Zhuge Liang                | 039: Brilliance           | 040: Distinction          | 041: Enlightenment
      -- Liu Bei                    | 042: Strength and Virtue  | 043: Heaven and Earth     | 044: Yin and Yang
      -- Diao Chan                  | 045: Moonflower           | 046: Dewflower            | 047: Rainflower
      -- Lu Bu                      | 048: Sky Piercer          | 049: Demon Bane           | 050: Heron Blade Halberd
      -- Xu Zhu                     | 051: Bone Crusher         | 052: Chaos Crusher        | 053: Whirlwind Crusher
      -- Xiahou Yuan                | 054: Heavens Destroyer    | 055: Heavens Smasher      | 056: Heavens Cutter
      -- Xu Huang                   | 057: Destroyer            | 058: Annihilator          | 059: Obliterator
      -- Zhang He                   | 060: Phoenix Talons       | 061: Dragon's Claws       | 062: White Tiger
      -- Cao Ren                    | 063: Phoenix Wing         | 064: Dragon Scale         | 065: Tortoise Bite
      -- Cao Pi                     | 066: Heaven's Blade       | 067: Kingdom's Pride      | 068: Leader of Men
      -- Taichi Ci                  | 069: Wolf Slayer          | 070: Tiger Slayer         | 071: Apollyon
      -- Lu Meng                    | 072: Valor                | 073: Spirit               | 074: Courage
      -- Huan Gai                   | 072: River Slicer         | 074: Mountain Breaker     | 075: Sky Lasher
      -- Zhou Tai                   | 076: Flashstrike          | 077: Dawnstrike           | 078: Duskstrike
      -- Ling Tong                  | 079: Cyclone              | 080: Typhoon              | 081: Hurricane
      -- Sun Ce                     | 082: Tyrant Strike        | 083: Glimmer Strike       | 084: Stoic Strike
      -- Sun Quan                   | 085: Dragon's Might       | 086: Heaven's Might       | 087: Titan's Might
      -- Ma Chao                    | 090: Ruination            | 091: Storm Breaker        | 092: Mountain Mover
      -- Huang Zhong                | 093: Imortal Blade        | 094: Battle Master Blade  | 095: Princeps Blade
      -- Wei Wan                    | 096: The Awakener         | 097: Bone Splitter        | 098: Stormhowl
      -- Guan Ping                  | 099: Blue Dragon Ji       | 100: Black Dragon Ji      | 101: White Dragon Ji
      -- Pang Tong                  | 102: Firestorm Staff      | 103: Blizzard Staff       | 104: Typhoon Staff
      -- Dong Zhuo                  | 105: Wizard Club          | 106: Magus Club           | 107: Augur Club
      -- Yuan Shao                  | 108: Sword of Kings       | 109: Sword of Severity    | 110: North Star Sword
      -- Zhang Jiao                 | 111: Blaze Staff          | 070: Blight Staff         | 071: Judgement Staff
      -- Zheng Ji                   | 114: Allure               | 115: Charm                | 116: Seduction
      -- Xiao Qiao                  | 117: True Grace           | 118: True Beauty          | 119: True Luster
      -- Yue Ying                   | 120: Jade Cresent         | 121: Saphire Crescent     | 122: Opal Crescent
      ------------------------------------------------------------------------------------------------------------------
      --
      -- Size: 4 bytes.
      "Identifier",

      -- Weapon quality, improves the base weapon attack.
      --
      -- Size: 4 bytes.
      "Quality",

      -- Weapon element identifier, following.
      --
      --    0 | Fire
      --    1 | Ice
      --    2 | Thunder
      --    3 | None
      --
      -- Size: 4 bytes.
      "Element",

      -- Weapon attributes.
      --
      -- In Dynasty Warriors 6 a weapon can have up to 5 attributes.
      --
      -- The attribute data is stored in 4 bytes:
      --
      --    Byte 0: Primary attribute bitmask.
      --    Byte 1: Secondary attribute bitmask.
      --    Byte 2: Padding (always 00).
      --    Byte 3: Padding (always 00).
      --
      -- Each bit represents an attribute flag.
      --
      -- Primary attribute bitmask (Byte 0):
      --
      --    Bit 0 | Air Wave
      --    Bit 1 | Mystic Seak
      --    Bit 2 | True Musou
      --    Bit 3 | Leech
      --    Bit 4 | Concentration
      --    Bit 5 | Balance
      --    Bit 6 | Berserk
      --    Bit 7 | Renbu Spirit
      --
      -- Secondary attribute bitmask (Byte 0):
      --
      --    Bit 0 | Arrow Sight
      --    Bit 1 | Flash
      --
      -- The game selects the first 5 enabled attributes in bit order (lowest bit first).
      --
      -- Size: 4 bytes.
      "Attributes",
   }

   local weapon_count = 8

   for i = 1, weapon_count do
      local weapon_header = AddressList.createMemoryRecord()

      weapon_header.Description = "Weapon " .. i
      weapon_header.IsGroupHeader = true
      weapon_header.Parent = weapons_header
      weapon_header.DisplayAsChild = true
      weapon_header.Color = colors.SOFT_RED

      for j = 1, #weapon_struct do
         offset = offset + 4

         local address = string.format("%X", character_address + offset)
         local description = weapon_struct[j]
         local entry = AddressList.createMemoryRecord()

         entry.Parent = weapon_header
         entry.Description = description
         entry.Address = address
         entry.VarType = vtDword
         entry.DisplayAsChild = true
         entry.Color = colors.BLUE
      end
   end

   local trailing_struct = { -- Size: 32 bytes.

      -- Character growth identifier (I still don't know if this affect any other thing in the game).
      --
      -- In Dynasty Warriors 6 the character status (Life, Musou, Attack and Defense) are not stored in integers,
      -- now they are dynamic set based on a formula, and this formula is based on this identifier.
      --
      -- Also the identifier is coincidently is equals to the index of the character in the memory, following:
      --
      -- 41: Yue Ying
      --
      -- Any value outside this table makes the character loses all the growth bonus by leveling.
      --
      -- Size: 4 bytes.
      "Identifier",

      -- Character outfit identifier, in-game a character have only two outfits (0 or 1).
      --
      -- In Dynasty Warriors 6 the character can have two outfits, the default one and another unlocking by level,
      -- following:
      --
      --    0: Default outfit.
      --    1: Secondary outfit.
      --
      -- Any value other than that the game loads the default outfit.
      --
      -- Size: 4 bytes.
      "Outfit",

      -- Character military title identifier.
      --
      -- Size: 4 bytes.
      "Title",

      -- Character level value, starting from 0 (so the actual level is this value +1).
      --
      -- In Dynasty Warriors 6 the character maximum level is 50.
      --
      -- Takes 4 bytes.
      "Level",

      -- Character experience value, no further explanation needed.
      --
      -- Size: 4 bytes.
      "Experience",

      -- Character KOs value, no further explanation needed.
      --
      -- Size: 4 bytes.
      "KOs",

      -- Character equipped weapon index, a character can have up to 8 weapons (index 0 to 7).
      --
      -- In Dynasty Warriors 6 the character can have up to 8 weapons, this value stores the current equipped index.
      --
      -- Size: 4 bytes.
      "Equipped Weapon",

      -- Boolean value that unlocks the character, following:
      --
      --    0: The character is locked.
      --    1: The character is unlocked.
      --
      -- Size: 4 bytes.
      "Is Unlocked",
   }

   for i = 1, #trailing_struct do
      offset = offset + 4

      local address = string.format("%X", character_address + offset)
      local description = trailing_struct[i]
      local entry = AddressList.createMemoryRecord()

      entry.Parent = character_header
      entry.Description = description
      entry.Address = address
      entry.VarType = vtDword
      entry.DisplayAsChild = true
      entry.Color = colors.BLUE
   end
end

------------------------------------------------------------------------------------------------------------------------

--- Creates a table of memory records for all charaters available in the game.
---
-- • @parameter first_address: Memory address of the first character (Xiahou Dun).
local function create_all_characters_records(first_address)
   local address = first_address

   local parent_header = AddressList.createMemoryRecord()

   parent_header.Description = "Characters"
   parent_header.IsGroupHeader = true
   parent_header.Color = colors.SOFT_RED

   local characters_struct = {
      "Xiahou Dun",
      "Dian Wei",
      "Sima Yi",
      "Zhang Liao",
      "Cao Cao",
      "Zhou Yu",
      "Lu Xun",
      "Sun Shang Xiang",
      "Gan Ning",
      "Sun Jian",
      "Zhao Yun",
      "Guan Yu",
      "Zhang Fei",
      "Zhuge Liang",
      "Liu Bei",
      "Diao Chan",
      "Lu Bu",
      "Xu Zhu",
      "Xiahou Yuan",
      "Xu Huang",
      "Zhang He",
      "Cao Ren",
      "Cao Pi",
      "Taishi Ci",
      "Lu Meng",
      "Huang Gai",
      "Zhou Tai",
      "Ling Tong",
      "Sun Ce",
      "Sun Quan",
      "Ma Chao",
      "Huang Zhong",
      "Wei Wan",
      "Guan Ping",
      "Pang Tong",
      "Dong Zhuo",
      "Yuan Shao",
      "Zhang Jiao",
      "Zheng Ji",
      "Xiao Qiao",
      "Yue Ying",
   }

   local struct_size = 176

   for i = 1, #characters_struct do
      local character_address = address + ((i - 1) * struct_size)
      local character_name = characters_struct[i]

      print(string.format("Creating table for %s...", character_name))

      create_character_records(parent_header, character_address, character_name)
   end
end

------------------------------------------------------------------------------------------------------------------------

--- Applies the "hide when deactivated" option recursively to all group headers and memory records in the address list.
--- This ensures a cleaner layout by hiding collapsed children unless expanded.
local function collapse_all_headers()

   --- Recursively apply "moHideChildren" to all child records of a memory record.
   ---
   -- • @parameter memory_record: The memory record to apply the option to.
   local function apply_recursive(memory_record)
      local group_header = 11

      -- Check if the memory record is a group header (Type == 11) or has children.
      if memory_record.Type == group_header or memory_record.Count > 0 then
         memory_record.Options = "moHideChildren"
         memory_record.IsCollapsed = false

         -- Recursively apply to each child record.
         for i = 1, memory_record.Count do
            apply_recursive(memory_record.Child[i - 1])
         end
      end
   end

   local address_list = getAddressList()

   print("Collapsing all headers...")

   -- Apply recursively to all top-level records.
   for i = 0, address_list.Count - 1 do
      apply_recursive(address_list.MemoryRecord[i])
   end

   -- Refresh the UI if the form is available.
   if getMainForm() then
      getMainForm().refresh()
   end
end

------------------------------------------------------------------------------------------------------------------------

--- Main function to run the script.
--- 
--- The script must be executed from the "There is no memory card (PS2) in MEMORY CARD slot" screen,
--- ensuring the game has loaded the default in-memory data layout.
local function run()
   local xiahou_dun_address = search_xiahou_dun_address()

   create_all_characters_records(xiahou_dun_address)
   collapse_all_headers()
end

------------------------------------------------------------------------------------------------------------------------
-- Run
------------------------------------------------------------------------------------------------------------------------
-- To run this script, start the game using an empty save file.
--
-- It is recommended to run the script while the game is at the "There is no memory card (PS2) in MEMORY CARD slot"
-- screen.
--
-- This script generates a table containing all playable characters available in the game.
------------------------------------------------------------------------------------------------------------------------

run()
