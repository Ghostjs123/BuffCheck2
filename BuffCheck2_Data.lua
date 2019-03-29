-- notes: ALL bc2_item_buffs must have an id, buff_path, and duration

-- duration of 0 means the addon will not give an expiration warning in chat

-- buff_path referes to the texture resulting from the use of the item

-- if the texture conflicts with that of another item then you can add the optional
-- buff_name field to double check if item's buff is actually present

bc2_item_buffs = {
    -- agi buffs
    ["Elixir of the Mongoose"] = {
        buff_path = { "Interface\\Icons\\INV_Potion_32" },
        id = 13452,
        duration = 3600
    },
    ["Elixir of Greater Agility"] = {
        buff_path = { "Interface\\Icons\\INV_Potion_93" },
        id = 9187,
        duration = 3600
    },
    ["Ground Scorpok Assay"] = {
        buff_path = { "Interface\\Icons\\Spell_Nature_ForceOfNature" },
        id = 8412,
        duration = 3600
    },

    -- strength buffs
    ["Juju Power"] = {
        buff_path = { "Interface\\Icons\\INV_Misc_MonsterScales_11" },
        id = 12451,
        duration = 1800
    },
    ["Elixir of Giants"] = {
        buff_path = { "Interface\\Icons\\INV_Potion_61" },
        id = 9206,
        duration = 3600
    },
    ["R.O.I.D.S."] = {
        buff_path = { "Interface\\Icons\\Spell_Nature_Strength" },
        buff_name = "Rage of Ages",
        id = 8410,
        duration = 3600
    },

    -- attack power buffs
    ["Juju Might"] = {
        buff_path = { "Interface\\Icons\\INV_Misc_MonsterScales_07" },
        id = 12460,
        duration = 600
    },
    ["Winterfall Firewater"] = {
        buff_path = { "Interface\\Icons\\INV_Potion_92" },
        id = 12820,
        duration = 1200
    },
    ["Bogling Root"] = {
        buff_path = { "Interface\\Icons\\Spell_Nature_Strength" },
        buff_name = "Fury of the Bogling",
        id = 5206,
        duration = 600
    },

    -- armor buffs
    ["Elixir of Superior Defense"] = {
        buff_path = { "Interface\\Icons\\INV_Potion_86" },
        id = 13445,
        duration = 3600
    },
    ["Elixir of Greater Defense"] = {
        buff_path = { "Interface\\Icons\\INV_Potion_86" },
        id = 8951,
        duration = 3600
    },
    ["Crystal Ward"] = {
        buff_path = { "Interface\\Icons\\INV_Misc_Gem_Ruby_02" },
        id = 11564,
        duration = 1800
    },
    ["Scroll of Protection IV"] = {
        buff_path = { "Interface\\Icons\\Ability_Warrior_DefensiveStance" },
        id = 10305,
        duration = 1800
    },
    ["Greater Stoneshield Potion"] = {
        buff_path = { "Interface\\Icons\\INV_Potion_69" },
        id = 13455,
        duration = 0
    },

    -- health buffs
    ["Elixir of Fortitude"] = {
        buff_path = { "Interface\\Icons\\INV_Potion_44" },
        id = 3825,
        duration = 3600
    },
    ["Spirit of Zanza"] = {
        buff_path = { "Interface\\Icons\\INV_Potion_30" },
        id = 20079,
        duration = 7200
    },
    ["Lung Juice Cocktail"] = {
        buff_path = { "Interface\\Icons\\INV_Drink_12" },
        id = 8411,
        duration = 3600
    },
    ["Gordok Green Grog"] = {
        buff_path = { "Interface\\Icons\\INV_Drink_03" },
        id = 18269,
        duration = 900
    },
    ["Rumsey Rum Black Label"] = {
        buff_path = { "Interface\\Icons\\INV_Drink_04" },
        id = 21151,
        duration = 900
    },

    -- misc tank consumes
    ["Gift of Arthas"] = {
        buff_path = { "Interface\\Icons\\Spell_Shadow_FingerOfDeath" },
        id = 9088,
        duration = 1800
    },

    -- spirit buffs
    ["Kreeg's Stout Beatdown"] = {
        buff_path = { "Interface\\Icons\\INV_Drink_05" },
        id = 18284,
        duration = 900
    },

    -- health regen buffs
    ["Major Troll's Blood Potion"] = {
        buff_path = { "Interface\\Icons\\INV_Potion_79" },
        id = 20004,
        duration = 3600
    },

    -- mana regen buffs
    ["Mageblood Potion"] = {
        buff_path = { "Interface\\Icons\\INV_Drink_45" },
        id = 20007,
        duration = 3600
    },

    -- spell power buffs
    ["Greater Arcane Elixir"] = {
        buff_path = { "Interface\\Icons\\INV_Potion_25" },
        id = 13454,
        duration = 3600
    },
    ["Elixir of Greater Firepower"] = {
        buff_path = { "Interface\\Icons\\INV_Potion_60" },
        id = 21546,
        duration = 3600
    },
    ["Elixir of Shadow Power"] = {
        buff_path = { "Interface\\Icons\\INV_Potion_46" },
        id = 9264,
        duration = 3600
    },

    -- flasks
    ["Flask of the Titans"] = {
        buff_path = { "Interface\\Icons\\INV_Potion_62" },
        id = 13510,
        duration = 7200
    },
    ["Flask of Supreme Power"] = {
        buff_path = { "Interface\\Icons\\INV_Potion_41" },
        id = 13512,
        duration = 7200
    },
    ["Flask of Distilled Wisdom"] = {
        buff_path = { "Interface\\Icons\\INV_Potion_97" },
        id = 13511,
        duration = 7200
    },

    -- valentine's buffs
    ["Dark Desire"] = {
        buff_path = { "Interface\\Icons\\INV_ValentinesChocolate04" },
        id = 22237,
        duration = 3600
    },
    ["Very Berry Cream"] = {
        buff_path = { "Interface\\Icons\\INV_ValentinesChocolate02" },
        id = 22238,
        duration = 3600
    },
    ["Buttermilk Delight"] = {
        buff_path = { "Interface\\Icons\\INV_ValentinesChocolate01" },
        id = 22236,
        duration = 3600
    },
    ["Sweet Surprise"] = {
        buff_path = { "Interface\\Icons\\INV_ValentinesChocolate03" },
        id = 22239,
        duration = 3600
    },

    -- zone specific items
        -- jujus
    ["Juju Chill"] = {
        buff_path = { "Interface\\Icons\\INV_Misc_MonsterScales_09" },
        buff_name = "Juju Chill",
        id = 12457,
        duration = 600
    },
    ["Juju Ember"] = {
        buff_path = { "Interface\\Icons\\INV_Misc_MonsterScales_15" },
        id = 12455,
        duration = 600
    },
        -- greater prot pots
    ["Greater Shadow Protection Potion"] = {
        buff_path = { "Interface\\Icons\\INV_Potion_23" },
        id = 13459,
        duration = 0
    },
    ["Greater Fire Protection Potion"] = {
        buff_path = { "Interface\\Icons\\INV_Potion_24" },
        id = 13457,
        duration = 0
    },
    ["Greater Nature Protection Potion"] = {
        buff_path = { "Interface\\Icons\\INV_Potion_22" },
        id = 13458,
        duration = 0
    },
    ["Greater Arcane Protection Potion"] = {
        buff_path = { "Interface\\Icons\\INV_Potion_83" },
        id = 13461,
        duration = 0
    },
    ["Greater Frost Protection Potion"] = {
        buff_path = { "Interface\\Icons\\INV_Potion_20" },
        id = 13456,
        duration = 0
    },
        -- other
    ["Elixir of Poison Resistance"] = {
        buff_path = { "Interface\\Icons\\INV_Potion_12" },
        id = 3386,
        duration = 0
    },
    ["Swiftness Potion"] = {
        buff_path = { "Interface\\Icons\\INV_Potion_95" },
        id = 2459,
        duration = 0
    },
    ["Juju Escape"] = {
        buff_path = { "Interface\\Icons\\INV_Misc_MonsterScales_17" },
        id = 12459,
        duration = 0
    },

    -- additional consumes (always bad)
    ["Elixir of the Sages"] = {
        buff_path = { "Interface\\Icons\\INV_Potion_29" },
        id = 13447,
        duration = 3600
    },
    ["Elixir of Brute Force"] = {
        buff_path = { "Interface\\Icons\\INV_Potion_40" },
        id = 13453,
        duration = 3600
    }
}

-- notes: ALL bc2_food_buffs must have an id and a duration

-- duration of 0 means the addon will not give an expiration warning in chat

-- buff_path is not needed bc all resulting textures are in food_buff_textures in BuffCheck2.lua

bc2_food_buffs = {
    -- food buffs todo add more
    ["Tender Wolf Steak"] = {
        id = 18045,
        duration = 900
    },
    ["Cooked Glossy Mightfish"] = {
        id = 13927,
        duration = 600
    },
    ["Dirge's Kickin' Chimaerok Chops"] = {
        id = 21023,
        duration = 900
    },
    ["Smoked Desert Dumplings"] = {
        id = 20452,
        duration = 900
    },
    ["Grilled Squid"] = {
        id = 13928,
        duration = 600
    },
    ["Nightfin Soup"] = {
        id = 13931,
        duration = 600
    },
    ["Blessed Sunfruit"] = {
        id = 13810,
        duration = 600
    },
    ["Blessed Sunfruit Juice"] = {
        id = 13813,
        duration = 600
    }
}

-- notes: ALL bc2_weapon_buffs must have an id and duration

-- duration of 0 means the addon will not give an expiration warning in chat

bc2_weapon_buffs = {
    ["Dense Sharpening Stone"] = {
        id = 12404,
        duration = 1800
    },
    ["Elemental Sharpening Stone"] = {
        id = 18262,
        duration = 1800
    },
    ["Dense Weightstone"] = {
        id = 12643,
        duration = 1800
    },
    ["Consecrated Sharpening Stone"] = {
        id = 23122,
        duration = 1800
    },
    ["Blessed Wizard Oil"] = {
        id = 23123,
        duration = 1800
    },
    ["Brilliant Wizard Oil"] = {
        id = 20749,
        duration = 1800
    },
    ["Brilliant Mana Oil"] = {
        id = 20748,
        duration = 1800
    },
    ["Crippling Posion II"] = {
        id = 3776,
        duration = 0
    },
    ["Deadly Posion V"] = {
        id = 20844,
        duration = 0
    },
    ["Deadly Posion IV"] = {
        id = 8985,
        duration = 0
    },
    ["Instant Posion VI"] = {
        id = 8928,
        duration = 0
    },
    ["Frost Oil"] = {
        id = 3829,
        duration = 1800
    },
    ["Rough Sharpening Stone"] = { -- using it for testing
        id = 2862,
        duration = 1800
    }
}