buffcheck2_config = {}
buffcheck2_saved_consumes = {} -- should contain the actual name of the item, not the buff texture

bc2_button_count = 4
bc2_current_buffs_on_player = {}

food_buff_textures = {"Interface\\Icons\\INV_Boots_Plate_03", "Interface\\Icons\\Spell_Misc_Food",
    "Interface\\Icons\\Spell_Misc_Food", "Interface\\Icons\\INV_Gauntlets_19",
    "Interface\\Icons\\Spell_Nature_ManaRegenTotem"}

--======================================================================================================================

function bc2_OnLoad()
    this:RegisterEvent("VARIABLES_LOADED")
    this:RegisterEvent("PLAYER_AURAS_CHANGED")
    this:RegisterEvent("UNIT_INVENTORY_CHANGED")
end

--======================================================================================================================

function ScubaLoot_OnEvent(event)
    if(event == "VARIABLES_LOADED") then
        bc2_init()
    elseif(event == "PLAYER_AURAS_CHANGED" or event == "UNIT_INVENTORY_CHANGED") then
        bc2_update_frame()
    end
end

--======================================================================================================================

-- called on "VARIABLES_LOADED"

function bc2_init()
    if buffcheck2_config["showing"] then
        if buffcheck2_config["showing"] == true then
            BuffCheck2Frame:Show()
        else
            BuffCheck2Frame:Hide()
        end
    else
        -- set default
        buffcheck2_config["showing"] = true
    end

    if buffcheck2_config["locked"] then
        if buffcheck2_config["locked"] == true then
            BuffCheck2Frame:SetMovable(true)
        else
            BuffCheck2Frame:SetMovable(false)
        end
    else
        -- set default
        buffcheck2_config["locked"] = false
    end

    if(table.getn(buffcheck2_saved_consumes) == 0) then
        if(buffcheck2_config["showing"] == true and buffcheck2_config["locked"] == false) then
            -- todo figure out if that is the correct path
            table.insert(buffcheck2_saved_consumes, "Interface\\Icons\\Spell_Nature_WispSplode")
        end
    end

    bc2_update_frame()
end

--======================================================================================================================

-- called on "PLAYER_AURAS_CHANGED"

function bc2_update_frame()
    update_current_buffs_on_player()
    for _, consume in buffcheck2_saved_consumes do
        local temp_result = bc2_player_has_buff(consume)
        if temp_result == false then
            bc2_add_item_to_interface(consume)
        end
    end
end

--======================================================================================================================

function bc2_add_item_to_interface(consume)
    local button, icon
    local placed = false
    for i = 1, bc2_button_count do
        button = getglobal("BuffCheck2Button"..i)
        if placed == false then
            if(button:IsVisible() == nil) then
                icon = getglobal("BuffCheck2Button"..i.."Icon")
                local texture = bc2_name_to_texture(consume)
                if texture ~= nil then
                    icon:SetTexture()
                    button:Show()
                else
                    bc2_send_message("Error - could not find " .. consume .. " in BuffCheck2_Data.lua")
                end
                placed = true
            end
        else
            -- hide the rest of the buttons
            button:Hide()
        end
    end
end

--======================================================================================================================

SlashCmdList["SLASH_BUFFCHECK2"] = function() end

SLASH_BUFFCHECK1, SLASH_BUFFCHECK2 = "/bc2", "/buffcheck2"
function SlashCmdList.BUFFCHECK(args)

    if(args == "") then
        -- print default usage
        bc2_send_message("Commands:")
        bc2_send_message("add {ItemLink} - adds the item")
        bc2_send_message("remove {ItemLink} - removes the item")
        bc2_send_message("lock - locks the frame")
        bc2_send_message("unlock - unlocks the frame")
        bc2_send_message("show - shows the frame")
        bc2_send_message("hide - hides the frame")
    elseif(string.find(args, "add") ~= nil) then
        local item_name = bc2_get_item_name_from_args(args)
        if(item_name == nil) then
            bc2_send_message("Missing an item link")
        else
            bc2_add_item_to_saved_list(item_name)
        end
    elseif(string.find(args, "remove") ~= nil) then
        local item_name = bc2_get_item_name_from_args(args)
        if(item_name == nil) then
            bc2_send_message("Missing an item link")
        else
            bc2_remove_item_from_saved_list(item_name)
        end
    elseif(string.find(args, "lock") ~= nil) then
        bc2_lock_frame()
    elseif(string.find(args, "unlock") ~= nil) then
        bc2_unlock_frame()
    elseif(string.find(args, "show") ~= nil) then
        bc2_show_frame()
    elseif(string.find(args, "hide") ~= nil) then
        bc2_hide_frame()
    elseif(string.find(args, "test") ~= nil) then
        bc2_test()
    else
        bc2_send_message("Unknown arguments, to show usage type /bc2")
    end
end

--======================================================================================================================

function bc2_add_item_to_saved_list(item_name)
    local contains = false
    for _, consume in buffcheck2_saved_consumes do
        if consume == item_name then
            contains = true
            break
        end
    end

    local bufftexture = bc2_item_buffs[item_name]
    if bufftexture then
        if contains then
            bc2_send_message(tostring(item_name) .. " is already added")
        else
            table.insert(buffcheck2_saved_consumes, item_name)
            bc2_send_message("added: " .. tostring(item_name))
            bc2_update_frame()
        end
    else
        bc2_send_message("Could not find " .. item_name .. " in BuffCheck2_Data.lua")
    end
end

function bc2_remove_item_from_saved_list(item_name)
    local contains = false
    for _, consume in buffcheck2_saved_consumes do
        if consume == item_name then
            contains = true
            break
        end
    end

    local bufftexture = bc2_item_buffs[item_name]
    if bufftexture then
        if contains == false then
            bc2_send_message(tostring(item_name) .. " is not added")
        else
            table.remove(buffcheck2_saved_consumes, bc2_get_index_in_table(buffcheck2_saved_consumes, item_name))
            bc2_send_message("removed: " .. tostring(item_name))
            bc2_update_frame()
        end
    else
       bc2_send_message("Could not find " .. item_name .. " in BuffCheck2_Data.lua")
    end
end

--======================================================================================================================

function bc2_lock_frame()
    buffcheck2_config["locked"] = true
    BuffCheck2Frame:SetMovable(false)
    bc2_send_message(tostring(BuffCheck2Frame:IsMovable()))
    bc2_send_message("Interface locked")
end

function bc2_unlock_frame()
    buffcheck2_config["locked"] = false
    BuffCheck2Frame:SetMovable(true)
    bc2_send_message(tostring(BuffCheck2Frame:IsMovable()))
    bc2_send_message("Interface unlocked")
end

--======================================================================================================================

function bc2_show_frame()
    buffcheck2_config["showing"] = true
    BuffCheck2Frame:Show()
    bc2_send_message("Interface showing")
end

function bc2_hide_frame()
    buffcheck2_config["showing"] = false
    BuffCheck2Frame:Hide()
    bc2_send_message("Interface hidden")
end

--======================================================================================================================

function bc2_player_has_buff(buffname)
    local bufftexture = bc2_item_buffs[buffname]
    if bufftexture then
        return bc2_has_value(bc2_current_buffs_on_player, bufftexture)
    else
        bufftexture = bc2_sharpening_stones[buffname]
        if bufftexture then
            local hasMainHandEnchant, _, _, hasOffHandEnchant, _, _, _, _, _ = GetWeaponEnchantInfo()
            local mainHandLink = GetInventoryItemLink("player", GetInventorySlotInfo("MainHandSlot"))
            local _, _, _, _, _, sType, _, _ = GetItemInfo(item_link_to_item_id(mainHandLink))
            if(string.sub(sType, 0, 1) == "O") then -- one handed
                if(hasMainHandEnchant ~= nil and hasOffHandEnchant ~= nil) then
                    return true
                end
            elseif(string.sub(sType, 0, 1) == "T") then -- two handed
                if(hasMainHandEnchant ~= nil) then
                    return true
                end
            end
        end
    end
    return false
end

--======================================================================================================================

function update_current_buffs_on_player()
    local buffs = {}

        for x = 1, 32 do
            local bufftexture = UnitBuff("player", x)

            if bufftexture == nil then
                break
            else
                -- needed to differentiate btwn buffs w/ the same texture like gspp and demon armor
                local buffname = bc2_texture_to_name(bufftexture)
                if buffname ~= "" then
                    table.insert(buffs, bufftexture)
                end
            end
        end

    bc2_current_buffs_on_player = buffs
end

--======================================================================================================================

function bc2_texture_to_name(texture)
    for spell_name, spell_info in bc2_item_buffs do
        if(bc2_has_value(spell_info.buff_path, texture)) then
            return spell_name
        end
    end

    return ""
end

function bc2_name_to_texture(name)
    for spell_name, spell_info in bc2_item_buffs do
        if(spell_name == name) then
            return spell_info.buff_path
        end
    end

    return ""
end

--======================================================================================================================

function bc2_is_item_link(itemLink)
    -- theres better ways to do this but this works too
    bc2_send_message("bc2_is_item_link: " .. tostring(itemLink))
    if bc2_item_link_to_item_name(itemLink) ~= nil and bc2_item_link_to_item_id(itemLink) ~= nil then
        return true
    else
        return false
    end
end

function bc2_item_link_to_item_name(itemLink)
    -- item link format ex: |Hitem:6948:0:0:0:0:0:0:0|h[Hearthstone]|h
    -- matches anything inside square brackets ex: asdasd[abc]asdasd -> abc
    return string.match(itemLink, "%[(.+)%]")
end

function bc2_item_link_to_item_id(itemLink)
    -- item link format ex: |Hitem:6948:0:0:0:0:0:0:0|h[Hearthstone]|h
    -- matches anything inside the first 2 :'s ex: |Hitem:6948:0:0:0:0: -> 6948
    return string.match(itemLink, ":(%d+)")
end

function bc2_get_item_name_from_args(args)
    -- ideal args format "add [Elixir of the Mongoose]
    -- matches anything inside square brackets ex: asdasd[abc]asdasd -> abc
    -- copy paste of bc2_item_link_to_item_name, keeping it seperate in case the pattern needs changed later
    return string.match(args, "%[(.+)%]")
end

--======================================================================================================================

-- quick function to print a msg to the chat log

function bc2_send_message(message)
    DEFAULT_CHAT_FRAME:AddMessage(message)
end

--======================================================================================================================

function bc2_tprint(tbl, indent)
    if not indent then indent = 0 end
    for k, v in pairs(tbl) do
        local formatting = string.rep("  ", indent) .. k .. ": "
        if type(v) == "table" then
            bc2_send_message(formatting)
            tprint(v, indent+1)
        elseif type(v) == 'boolean' then
            bc2_send_message(formatting .. tostring(v))
        else
            bc2_send_message(formatting .. v)
        end
    end
end

--======================================================================================================================

function bc2_test()
    bc2_tprint(buffcheck2_saved_consumes)
end

--======================================================================================================================
--======================================================================================================================
--======================================================================================================================

-- GUI specific functions

function bc2_button_onclick(id)
    local consume = buffcheck2_saved_consumes[id]
    -- note: bags start at index 0 (Backpack)
    for i = 0, 4 do
        local numberOfSlots = GetContainerNumSlots(i)
        for j = 1, numberOfSlots do
            local itemLink = GetContainerItemLink(i, j)
            if(itemLink ~= nil) then
                local itemname = bc3_item_link_to_item_name(itemLink)
                if itemname == consume then
                    -- todo test this
                    --UseContainerItem(i, j)
                    bc2_send_message("Using " .. consume)
                    return
                end
            end
        end
    end
end

--======================================================================================================================
--======================================================================================================================
--======================================================================================================================

-- Aditional functions

function split(s, delimiter)
    local result = {}
    for match in string.gmatch(s..delimiter, "(.-)"..delimiter) do
        table.insert(result, match)
    end
    return result
end

-- credit Sol
string.match = string.match or function(str, pattern)
    local tbl_res = { string.find(str, pattern) }

    if tbl_res[3] then
        return select(3, unpack(tbl_res))
    else
        return tbl_res[1], tbl_res[2]
    end
end

-- credit Sol
select = select or function(idx, ...)
    local len = table.getn(arg)

    if type(idx) == 'string' and idx == '#' then
        return len
    else
        local tbl = {}

        for i = idx, len do
            table.insert(tbl, arg[i])
        end

        return unpack(tbl)
    end
end

-- credit Sol
string.split = string.split or function(delim, s, limit)
    local split_string = {}
    local rest = {}

    local i = 1
    for str in string.gfind(s, '([^' .. delim .. ']+)' .. delim .. '?') do
        if limit and i >= limit then
            table.insert(rest, str)
        else
            table.insert(split_string, str)
        end

        i = i + 1
    end

    if limit then
        table.insert(split_string, string.join(delim, unpack(rest)))
    end

    return unpack(split_string)
end

-- credit Sol
string.gmatch = string.gmatch or function(str, pattern)
    local init = 0

    return function()
        local tbl = { string.find(str, pattern, init) }

        local start_pos = tbl[1]
        local end_pos = tbl[2]

        if start_pos then
            init = end_pos + 1

            if tbl[3] then
                return unpack({select(3, unpack(tbl))})
            else
                return string.sub(str, start_pos, end_pos)
            end
        end
    end
end

-- credit Sol
string.trim = string.trim or function(str)
    return string.gsub(str, '^%s*(.-)%s*$', '%1')
end

function bc2_has_value(tab, val)
    for _, value in tab do
        if value == val then
            return true
        end
    end
    return false
end

function bc2_get_index_in_table(tab, val)
    for index, value in tab do
        if value == val then
            return index
        end
    end
    return nil
end

--======================================================================================================================
