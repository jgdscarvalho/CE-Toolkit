------------------------------------------------------------------------------------------------------------------------
-- Cheat Engine toolkit for Dynasty Warriors 6 (PlayStation 2).
------------------------------------------------------------------------------------------------------------------------
-- Author                  | Zé Gabriel
-- Repository              | https://github.com/jgdscarvalho
-- License                 | MIT
-- SPDX-License-Identifier | MIT
-- Game                    | Samurai Warriors 2
-- Platform                | PlayStation 2
-- Version                 | SLUS-21462
-- Description             | All officers and bodyguards tables.
------------------------------------------------------------------------------------------------------------------------

--- A table of colors used as palette of record colors.
local colors = {
    SOFT_RED      = 225 + (128 * 256) + (128 * 65536), -- R: 225 | G: 128 | B: 128
    EMERALD_GREEN =   0 + (255 * 256) + (128 * 65536), -- R:   0 | G: 255 | B: 128
    PINK          = 255 + (128 * 256) + (255 * 65536), -- R: 255 | G: 128 | B: 255
    ORANGE        = 255 + (128 * 256) + (  0 * 65536), -- R: 255 | G: 128 | B:   0
    LIGHT_GREEN   = 128 + (255 * 256) + (128 * 65536), -- R: 128 | G: 255 | B: 128
    BLUE          = 128 + (128 * 256) + (255 * 65536), -- R: 128 | G: 128 | B: 255
    YELLOW        = 255 + (255 * 256) + (  0 * 65536), -- R: 255 | G: 255 | B:   0
    CYAN          = 128 + (255 * 256) + (255 * 65536), -- R: 128 | G: 255 | B: 255
}

------------------------------------------------------------------------------------------------------------------------

--- Scans the memory to locate Yukimura's statistics (at level 1) base address.
--- 
-- • @return number: The memory address corresponding to Yukimura's table.
local function search_yukimura_address()
   print("Searching for Yukimura Sanada's address...")

   -- This scan attempts to locate Yukimura's base statistics as an array of bytes.
   local scan = AOBScan("73 00 00 00 5C 00 00 00 58 00 00 00 5B 00 00 00 \z
                         5C 00 00 00 6E 00 00 00 72 00 00 00 5D 00 00 00")

   -- The offset that points to the experience value used as base address to find all other addresses.
   local offset = 32

   if not scan or scan.Count == 0 then
      error("No address has been found! Are you running the script with an empty save?")
   end

   local module_address = getAddress("pcsx2-qt.exe")
   local found = 0

   -- Iterate through the scan results to find the first address after the module's base address.
   -- This ensures the correct address is returned, since multiple static instances of Yukimura's data may be found.
   for i = 0, scan.Count - 1 do
      local address = tonumber(scan[i], 16) + offset

      print(string.format("Checking address: %X...", address))

      -- The true Yukimura'a address is usually the second one.
      if i == 1 then
         print(string.format("Yukimura's address found, address %X!", address))

         scan.destroy()

         return address
      end
   end

   scan.destroy()

   error("The master address was not found! Are you running the script with an empty save?")
end

------------------------------------------------------------------------------------------------------------------------

--- Creates the "Attributes" sub-group for an officer/bodyguard.
--- 
-- • @parameter base_address: The base address of the officer/bodyguard.
-- • @parameter parent_header: The parent header to which the "Attributes" table will be attached.
local function create_attribute_records(base_address, parent_header)
   local statistics_header = AddressList.createMemoryRecord()

   statistics_header.Description = "Attributes"
   statistics_header.IsGroupHeader = true
   statistics_header.Parent = parent_header
   statistics_header.DisplayAsChild = true

   local attributes_struct = { --- Size: 36 bytes (4 * 9).
       "Experience",
       "Luck",
       "Dexterity",
       "Speed",
       "Ride",
       "Defense",
       "Attack",
       "Musou",
       "Life",
   }

   -- Create each statistic entry (offsets go backwards from base), in reverse order.
   for i = #attributes_struct, 1, - 1 do
      local offset = -(i - 1) * 4
      local address = string.format("%X", base_address + offset)
      local description = attributes_struct[i]
      local entry = AddressList.createMemoryRecord()

      local color

      if description == "Life" then
         color = colors.EMERALD_GREEN
      elseif description == "Musou" then
         color = colors.PINK
      elseif description == "Attack" then
         color = colors.ORANGE
      elseif description == "Defense" then
         color = colors.LIGHT_GREEN
      else
         color = colors.BLUE
      end

      entry.Parent = statistics_header
      entry.Description = description
      entry.Address = address
      entry.VarType = vtDword
      entry.Color = color
      entry.DisplayAsChild = true
   end

   local level_entry = AddressList.createMemoryRecord()

   level_entry.Parent = statistics_header
   level_entry.Description = "Lv"
   level_entry.Address = string.format("%X", base_address + 4)
   level_entry.VarType = vtDword
   level_entry.Color = colors.BLUE
end

------------------------------------------------------------------------------------------------------------------------

--- Creates the "Skills" sub-group for an officer.
---
-- • @parameter officer_address: The memory address of the officer.
-- • @parameter parent_header: The parent header to which the "Skills" header will be attached.
local function create_skill_records(officer_address, parent_header)
   local skills_header = AddressList.createMemoryRecord()

   skills_header.Description = "Skills"
   skills_header.IsGroupHeader = true
   skills_header.Parent = parent_header
   skills_header.DisplayAsChild = true

   local skills_struct = { -- Size: 40 bytes (1 * 40).

      -- Ability: Increase character attributes.
      --
      -- Size: 10 bytes.
      "Vitality",
      "Focus",
      "Potence",
      "Fortitude",
      "Cavalier",
      "Impulse",
      "Grace",
      "Karma",
      "Sensei",
      "Master",

      -- Growth: Increase character growth.
      --
      -- Size: 10 bytes.
      "Vitality",
      "Focus",
      "Potence",
      "Fortitude",
      "Cavalier",
      "Impulse",
      "Grace",
      "Karma",
      "Sensei",
      "Acclaim",

      -- Battle: Increase character battle attributes.
      --
      -- Size: 10 bytes.
      "Reach",
      "Sickle",
      "Rage",
      "Chaos",
      "Resilience",
      "Element",
      "Ele-Charge",
      "Musou Power",
      "True Power",
      "Awakening",

      -- Special: Miscellaneous effects.
      --
      -- Size: 10 bytes.
      "Glutonny",
      "Cutthroat",
      "Equestrian",
      "Opportunity",
      "Ration",
      "Prodigy",
      "Discern",
      "Greed",
      "Fitness",
      "Plunder",
   }

   local base_skill_address = officer_address + 161 -- The first skill starts 161 bytes after the base address.

   -- Create memory records for each skill with appropriate label and color.
   for i = 1, #skills_struct do
      local address = string.format("%X", base_skill_address + (i - 1)) -- Directly use the base address for skills.

      -- Create a entry of the skills as array, useful to copy and paste the same skills between officers.
      if i == 1 then
         local skill_array_entry = AddressList.createMemoryRecord()

         skill_array_entry.Parent = skills_header
         skill_array_entry.Description = "Skills as Array[40]"
         skill_array_entry.Address = address
         skill_array_entry.VarType = vtByteArray
         skill_array_entry.DisplayAsChild = true
         skill_array_entry.ShowAsHex = true
      end

      local entry = AddressList.createMemoryRecord()

      entry.Parent = skills_header
      entry.Description = skills_struct[i]
      entry.Address = address
      entry.VarType = vtByte

      -- Set the description color based on skill category, to match in-game colors.
      if i <= 10 then
         entry.Color = colors.CYAN
      elseif i <= 20 then
         entry.Color = colors.YELLOW
      elseif i <= 30 then
         entry.Color = colors.SOFT_RED
      else
         entry.Color = colors.LIGHT_GREEN
      end
   end
end

------------------------------------------------------------------------------------------------------------------------

--- Creates the "Weapons" sub-group for an officer.
--- 
-- • @parameter base_address: The base memory address of the officer. The first weapon starts 8 bytes after this address.
-- • @parameter parent_header: The parent group to which the "Weapons" group will be attached.
local function create_weapon_records(base_address, parent_header)
   local weapons_header = AddressList.createMemoryRecord()

   weapons_header.Description = "Weapons"
   weapons_header.IsGroupHeader = true
   weapons_header.Parent = parent_header
   weapons_header.DisplayAsChild = true

   local weapon_struct = { -- Size: 19 bytes.

      -- Weapon identifier.
      --
      ----------------------------------------------------------------------------------------------------------------------------------------------
      -- Yukimura Sanada            | 000: Cross Spear          | 001: Lunar Spear          | 002: Crimson Fang         | 003: Dragon's Tail
      -- Keiji Maeda                | 004: Double Pike          | 005: Snake Tongue         | 006: Ogre Horn            | 007: Divine Mandible
      -- Nobunaga Oda               | 008: King's Sword         | 009: King's Rage          | 010: Demon's Slayer       | 011: Demon Regalla
      -- Mistuhide Akechi           | 012: Katana               | 013: Masterpiece          | 014: Hallowed Edge        | 015: Gilded Talon
      -- Kenshin Uesugi             | 016: Spiked Blade         | 017: Seven Spirits        | 018: Barbed Fang          | 019: Frozen Flame
      -- Oichi                      | 020: Cup & Ball           | 021: Cup & Stone          | 022: Cup & Iron           | 023: Cup & Gold
      -- Okuni                      | 024: Umbrella             | 025: Dance Parasol        | 026: Scomed Moon          | 027: Raging Sun
      -- Magoichi Saika             | 028: Musket               | 029: Silver Trigger       | 030: Thunder Thrower      | 031: Marksman's Pride
      -- Shingen Takeda             | 032: War Fan              | 033: Takeda Fan           | 034: Pressed Element      | 035: Heaven's Sign
      -- Masamune Date              | 036: Blade & Pistol       | 037: Edge & Powder        | 038: Metal & Fire         | 039: Manhunters
      -- Nō                         | 040: Hand Claw            | 041: Spider Sting         | 042: Scorpion Tail        | 043: Delicious Venom
      -- Hanzō Hattori              | 044: Scythe               | 045: Flash Cutter         | 046: Shadow Fang          | 047: Chained Dragon
      -- Ranmaru Mori               | 048: Long Sword           | 049: Brave Metal          | 050: Storm Blade          | 051: Iron Vengeance
      -- Hideyoshi Toyotomi         | 052: Triple Staff         | 053: Painful Triad        | 054: Monster Bones        | 055: Simian Sansetsu
      -- Tadakatsu Honda            | 056: Great Spear          | 057: Tiger Slayer         | 058: War Trident          | 059: Tonbo-giri
      -- Ina                        | 060: Long Bow             | 061: Bladed Bow           | 062: Wind Rider           | 063: Colled Viper
      -- Ieyasu Tokugawa            | 064: Cannon Spear         | 065: Fuse Pike            | 066: Boom Blade           | 067: Quake Maker
      -- Mitsunari Ishida           | 068: Folding Fan          | 069: Fuji's Grace         | 070: Open Valor           | 071: Golden Frill
      -- Nagamasa Azai              | 072: Lance                | 073: Knight's Staff       | 074: Impaler              | 075: King's Honor
      -- Sakon Shima                | 076: Broadsword           | 077: Machete              | 078: Body Cleaver         | 079: Wrecking Blade
      -- Yoshihiro Shimazu          | 080: War Hammer           | 081: Giant's Mallet       | 082: Bone Grinder         | 083: Beast Crusher
      -- Ginchiyo Tachibana         | 084: Serrate Blade        | 085: Lighting Sword       | 086: Thunder's Roar       | 087: Heaven's Bite
      -- Kanetsugu Naoe             | 088: Sword & Charms       | 089: Metal & Magic        | 090: Sacred Arms          | 091: Evil's Bane
      -- Nene                       | 092: Flying Swords        | 093: Kunoichi Blades      | 094: Tempered Windg       | 095: Devil Feathers
      -- Kotarō Fūma                | 096: Gauntlet             | 097: Chaos Guards         | 098: Demon Claws          | 099: Thorns of Peril
      -- Musashi Miyamoto           | 100: Twin Blades          | 101: Rage & Desire        | 102: Skill & Finesse      | 103: Mastery & Vision
      ----------------------------------------------------------------------------------------------------------------------------------------------
      --
      -- Size: 1 byte.
      "Identifier",

      -- Weapon element identifier, following.
      --
      --    0 | Empty
      --    1 | Fire
      --    2 | Ice
      --    3 | Thunder
      --    4 | Wind
      --    5 | Death
      --
      -- Size: 1 byte.
      "Element",

      -- An array of 8 bytes, each 1 byte containing the type of attribute boost for that slot, following:
      --
      --    00: Life;
      --    01: Musou;
      --    02: Attack:
      --    03: Defense;
      --    04: Ride;
      --    05: Speed;
      --    06: Dexterity;
      --    07: Luck;
      --    08: Musou Charge;
      --    09: Range;
      --    0A: Empty;
      --    Any other value placed become 0A, empty slot.
      --
      -- Size: 8 bytes (1 * 8).
      "Slot 1: Type",
      "Slot 2: Type",
      "Slot 3: Type",
      "Slot 4: Type",
      "Slot 5: Type",
      "Slot 6: Type",
      "Slot 7: Type",
      "Slot 8: Type",

      -- An array of 8 bytes, each 1 byte containing the power of attribute boost for that slot.
      --
      -- A non-cheated range in-game is between 0 and 20.
      --
      -- Size: 8 bytes (1 * 8).
      "Slot 1: Power",
      "Slot 2: Power",
      "Slot 3: Power",
      "Slot 4: Power",
      "Slot 5: Power",
      "Slot 6: Power",
      "Slot 7: Power",
      "Slot 8: Power",

      -- How many slots are available on that weapon.
      --
      -- Size: 1 byte.
      "Nº Slots",
   }

   local first_weapon_address = base_address + 8 -- 8 bytes offset.
   local weapon_block_size = 19

   for i = 0, 7 do
      local weapon_header = AddressList.createMemoryRecord()

      weapon_header.Description = "Weapon " .. (i + 1)
      weapon_header.IsGroupHeader = true
      weapon_header.Parent = weapons_header
      weapon_header.DisplayAsChild = true

      for j = 0, weapon_block_size - 1 do -- 19 bytes per weapon block.
         local address = string.format("%X", first_weapon_address + (i * weapon_block_size) + j)

         -- Create a entry of the elements and slots as array.
         -- Useful to copy and paste the same boosts between weapons.
         if j == 1 then
            local weapon_array_entry = AddressList.createMemoryRecord()

            weapon_array_entry.Parent = weapon_header
            weapon_array_entry.Description = "Boosts as Array[18]"
            weapon_array_entry.Address = address
            weapon_array_entry.VarType = vtByteArray
            weapon_array_entry.DisplayAsChild = true
            weapon_array_entry.ShowAsHex = true
         end

         local entry = AddressList.createMemoryRecord()

         entry.Parent = weapon_header
         entry.Description = weapon_struct[j + 1]
         entry.Address = address
         entry.VarType = vtByte
         entry.DisplayAsChild = true
      end
   end
end

------------------------------------------------------------------------------------------------------------------------

--- Creates the "Officers" group on root.
--- 
-- • @parameter yukimura_address: The memory address of Yukimura Sanada (base address of all officers).
local function create_officer_records(yukimura_address)
   local officers_header = AddressList.createMemoryRecord()

   officers_header.Description = "Officers"
   officers_header.IsGroupHeader = true

   local officers_struct = {
      "Yukimura Sanada",
      "Keiji Maeda",
      "Nobunaga Oda",
      "Mitsuhide Akechi",
      "Kenshin Uesugi",
      "Oichi",
      "Okuni",
      "Magoichi Saika",
      "Shingen Takeda",
      "Masamune Date",
      "Nō",
      "Hanzō Hattori",
      "Ranmaru Mori",
      "Hideyoshi Toyotomi",
      "Tadakatsu Honda",
      "Ina",
      "Ieyasu Tokugawa",
      "Mitsunari Ishida",
      "Nagamasa Azai",
      "Sakon Shima",
      "Yoshihiro Shimazu",
      "Ginchiyo Tachibana",
      "Kanetsugu Naoe",
      "Nene",
      "Kotarō Fūma",
      "Musashi Miyamoto",
   }

   -- Iterate through each officer and create their own sub-header.
   for i = 1, #officers_struct do
      local base_address = yukimura_address + ((i - 1) * 236)
      local name = officers_struct[i] or ("Officer " .. i)

      local officer_header = AddressList.createMemoryRecord()

      officer_header.Description = name
      officer_header.IsGroupHeader = true
      officer_header.Parent = officers_header

      create_skill_records(base_address, officer_header)
      create_attribute_records(base_address, officer_header)
      create_weapon_records(base_address, officer_header)
   end
end

------------------------------------------------------------------------------------------------------------------------

--- Creates the "Guards" group on root.
--- 
-- • @parameter master_address: Memory address of Yukimura's table.
local function create_bodyguard_records(master_address)
   local guards_header = AddressList.createMemoryRecord()

   guards_header.Description = "Guards"
   guards_header.IsGroupHeader = true

   local guards_struct = {
      "Takanobu Ryūzōji",
      "Kosuke Anayama",
      "Shikanosuke Yamanaka",
      "Masatoshi Hoshima",
      "Moriyasu Tozawa",
      "Sekishūsai Yagyū",
      "Nobutsuna Kamiizumi",
      "Koma",
      "Nana",
      "Inu Ōura",
      "Matsu Maeda",
      "Kai",
      "Nagato Fujibayashi",
      "Isuke Ninokuruwa",
      "Tamba Momochi",
      "Sasuke Sarutobi",
      "Koji Kashin",
      "Maria Konishi",
      "Tiger Gamō",
      "Usui",
      "Tsune Katō",
      "Chiyojo Mochizuki",
      "Sukenao Inadome",
      "Hisatoki Tanegashima",
      "Zenjūbō Sugitani",
      "Dōjun Igasaki",
      "Jūzō Kakei",
      "Koshōshō",
      "Tatsuko Kyōgoku",
      "Myōrinni Yoshioka",
      "Chiyo Yamanouchi",
      "Tsuru",
      "Sansa Honinbō",
      "Shōki Kaisen",
      "Sūden Ishin",
      "Sōhō Takuan",
      "Tenkai Nankōbō",
      "Itoko Ikeda",
      "Sayuri",
      "Ise",
      "Aya",
      "Otsū Ono",
      "Mataichirō Namasue",
      "Yoemon Aochi",
      "Isa Miyoshi",
      "Kumawaka",
      "Seikai Miyoshi",
      "Rokurō Mochizuki",
      "Ginpachirō Ono",
      "Danzō Katō",
      "Saizō Kirigatuke",
      "Hisahide Matsunaga",
      "Kojirō Sasaki",
      "Katsuie Shibata",
   }

   -- Iterate through each guard and create their own statistics address.
   for i = 1, #guards_struct do
      local base_address = master_address + ((i - 1) * 44)
      local guard_header = AddressList.createMemoryRecord()

      guard_header.Description = guards_struct[i] or ("Guard " .. i)
      guard_header.IsGroupHeader = true
      guard_header.Parent = guards_header

      create_attribute_records(base_address, guard_header)

      local unknown_entry = AddressList.createMemoryRecord()

      unknown_entry.Parent = guard_header
      unknown_entry.Description = "???" -- Padding?
      unknown_entry.Address = string.format("%X", base_address + 8)
      unknown_entry.VarType = vtDword
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
    local master_address = search_yukimura_address()

    create_officer_records(master_address)
    create_bodyguard_records(master_address + 0x17F8)
    collapse_all_headers()
end

------------------------------------------------------------------------------------------------------------------------

run()
