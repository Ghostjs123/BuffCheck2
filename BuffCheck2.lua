bc2_default_print_format = "|c00f7f26c%s|r"

buffcheck2_config = {}
buffcheck2_saved_consumes = {} -- should contain the actual name of the item, not the buff texture
bc2_current_consumes = {}

bc2_button_count = 25
bc2_bag_contents = {}

bc2_showed_already = false

food_buff_textures = {"Interface\\Icons\\INV_Boots_Plate_03", "Interface\\Icons\\Spell_Misc_Food",
    "Interface\\Icons\\INV_Gauntlets_19", "Interface\\Icons\\Spell_Nature_ManaRegenTotem"}

--======================================================================================================================

SlashCmdList["SLASH_BUFFCHECK2"] = function() end

SLASH_BUFFCHECK1, SLASH_BUFFCHECK2, SLASH_BUFFCHECK3 = "/bc2", "/buffcheck2", "/bw2" -- added bw2 bc i keep misstyping it
function SlashCmdList.BUFFCHECK(args) -- for some reason if I do .BUFFCHECK2 it doesnt work, doesnt like numbers?

    if(args == "") then
        -- print default usage
        bc2_send_message("Commands:")
        bc2_send_message("add {ItemLink} - adds the item")
        bc2_send_message("remove {ItemLink} - removes the item")
        bc2_send_message("lock - locks the frame")
        bc2_send_message("unlock - unlocks the frame")
        bc2_send_message("show - shows the frame")
        bc2_send_message("hide - hides the frame")
        bc2_send_message("scale - scales the frame, default is 100")
        bc2_send_message("clear - clears the saved list of consumes")
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
    elseif(string.find(args, "unlock") ~= nil) then
        bc2_unlock_frame()
    elseif(string.find(args, "lock") ~= nil) then
        bc2_lock_frame()
    elseif(string.find(args, "show") ~= nil) then
        bc2_show_frame()
    elseif(string.find(args, "hide") ~= nil) then
        bc2_hide_frame()
    elseif(string.find(args, "clear") ~= nil) then
        bc2_clear_saved_consumes()
    elseif(string.find(args, "scale") ~= nil) then
        local scale = string.sub(args, string.match(args, "%d+"))
        bc2_scale_interface(tonumber(scale))
    elseif(string.find(args, "test") ~= nil) then
        bc2_test()
    else
        bc2_send_message("Unknown arguments, to show usage type /bc2")
    end
end

--======================================================================================================================

function BuffCheck2_OnLoad()
    this:RegisterEvent("VARIABLES_LOADED")
    this:RegisterEvent("PLAYER_AURAS_CHANGED")
    this:RegisterEvent("UNIT_INVENTORY_CHANGED")
    this:RegisterEvent("PARTY_MEMBERS_CHANGED")
    this:RegisterEvent("BAG_UPDATE")
end

--======================================================================================================================

function BuffCheck2_OnEvent(event)
    if(event == "VARIABLES_LOADED") then
        bc2_init()
    elseif(event == "PLAYER_AURAS_CHANGED" or event == "UNIT_INVENTORY_CHANGED") then
        bc2_update_frame()
    elseif(event == "PARTY_MEMBERS_CHANGED") then
        bc2_check_group_update()
    elseif(event == "BAG_UPDATE") then
        bc2_update_bag_contents()
        bc2_update_item_counts()
        bc2_set_item_cooldowns()
    end
end

--======================================================================================================================

-- called on "VARIABLES_LOADED"

function bc2_init()

    if buffcheck2_config["locked"] == true then
        bc2_lock_frame()
    else
        bc2_unlock_frame()
    end

    if buffcheck2_config["showing"] == true then
        bc2_show_frame(false)
    else
        bc2_hide_frame()
    end

    if buffcheck2_config["scale"] then
        BuffCheck2Frame:SetScale(buffcheck2_config["scale"] / 100)
        BuffCheck2Frame:ClearAllPoints()
        BuffCheck2Frame:SetPoint("CENTER", "UIParent")
    end

    -- sneak in all of the consumes in BuffCheck2_Data.lua into bc2_bag_contents
    for key, _ in bc2_item_buffs do
        bc2_bag_contents[key] = 0
    end
    for key, _ in bc2_food_buffs do
        bc2_bag_contents[key] = 0
    end
    for key, _ in bc2_weapon_buffs do
        bc2_bag_contents[key] = 0
    end

    bc2_update_bag_contents()

    bc2_update_frame()

    bc2_update_item_counts()

    -- make a cooldown frame for each button
    local button
    for i = 1, bc2_button_count do
        button = getglobal("BuffCheck2Button"..i)
        local myCooldown = CreateFrame("Model", nil, button, "CooldownFrameTemplate")

        button.cooldown = function(start, duration)
            CooldownFrame_SetTimer(myCooldown, start, duration, 1)
        end
    end

    this:UnregisterEvent("VARIABLES_LOADED")
    bc2_send_message("BuffCheck2 - Init successful")
end

--======================================================================================================================

-- called on "PLAYER_AURAS_CHANGED"

function bc2_update_frame()
    -- rebuild the current missing consumes
    bc2_clear_current_consumes()
    local count = 1
    for _, consume in buffcheck2_saved_consumes do
        if bc2_player_has_buff(consume) == false then
            bc2_current_consumes[count] = consume
            count = count + 1
        end
    end
    count = 1
    for _, consume in bc2_current_consumes do
        bc2_add_item_to_interface(consume, count)
        count = count + 1
    end
    -- hide the rest of the buttons
    for i = count, bc2_button_count do
        local button = getglobal("BuffCheck2Button"..i)
        if button:IsVisible() then
            button:Hide()
        end
    end
    -- if no missing consumes display the placeholder
    if table.getn(bc2_current_consumes) == 0 then
        bc2_add_item_to_interface("Interface\\Icons\\Spell_Nature_WispSplode")
        BuffCheck2Frame:SetWidth(54)
    else
        BuffCheck2Frame:SetWidth(54 + (count - 2) * 36)
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
    if bufftexture == nil then
        bufftexture = bc2_food_buffs[item_name]
    end
    if bufftexture == nil then
        bufftexture = bc2_weapon_buffs[item_name]
    end
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

--======================================================================================================================

function bc2_remove_item_from_saved_list(item_name)
    local contains = false
    for _, consume in buffcheck2_saved_consumes do
        if consume == item_name then
            contains = true
            break
        end
    end

    local bufftexture = bc2_item_buffs[item_name]
    if bufftexture == nil then
        bufftexture = bc2_food_buffs[item_name]
    end
    if bufftexture == nil then
        bufftexture = bc2_weapon_buffs[item_name]
    end
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
    BuffCheck2Frame:EnableMouse(false)
    local backdrop = BuffCheck2Frame:GetBackdrop()
    backdrop["insets"] = { top = 0, bottom = 0, right = 0, left = 0 }
    backdrop["tile"] = true
    backdrop["tileSize"] = 1
    backdrop["edgeSize"] = 1
    BuffCheck2Frame:SetBackdrop(backdrop)
    bc2_send_message("BuffCheck2 - Interface locked")
end

function bc2_unlock_frame()
    buffcheck2_config["locked"] = false
    BuffCheck2Frame:EnableMouse(true)
    local backdrop = BuffCheck2Frame:GetBackdrop()
    backdrop["insets"] = { top = 12, bottom = 11, right = 12, left = 11 }
    backdrop["tile"] = true
    backdrop["tileSize"] = 32
    backdrop["edgeSize"] = 32
    BuffCheck2Frame:SetBackdrop(backdrop)
    bc2_send_message("BuffCheck2 - Interface unlocked")
end

--======================================================================================================================

function bc2_show_frame(should_update)
    buffcheck2_config["showing"] = true
    BuffCheck2Frame:Show()
    bc2_send_message("BuffCheck2 - Interface showing")
    if should_update then
        bc2_update_frame()
    end
end

function bc2_hide_frame()
    buffcheck2_config["showing"] = false
    BuffCheck2Frame:Hide()
    bc2_send_message("BuffCheck2 - Interface hidden")
end

--======================================================================================================================

function bc2_clear_saved_consumes()
    for k in pairs(buffcheck2_saved_consumes) do
        buffcheck2_saved_consumes[k] = nil
    end
    bc2_update_frame()
end

function bc2_clear_current_consumes()
    for k in pairs(bc2_current_consumes) do
        bc2_current_consumes[k] = nil
    end
end

--======================================================================================================================

function bc2_check_group_update()
    if(UnitInRaid("player") == 1 and bc2_showed_already == false) then
        bc2_show_frame()
        bc2_showed_already = true
    end
end

--======================================================================================================================

function bc2_player_has_buff(buffname)
    local bufftexture = bc2_item_buffs[buffname]
    if bufftexture then
        if bufftexture.buff_name ~= nil then
            return bc2_is_buff_present(bufftexture.buff_path[1], bufftexture.buff_name)
        else
            return bc2_is_buff_present(bufftexture.buff_path[1])
        end
    else
        bufftexture = bc2_food_buffs[buffname]
        if bufftexture then
            for _, food_buff_texture in food_buff_textures do
                -- hopefully there isn't any buffs that share a texture w/ food buffs
                -- because im not checking the name of the buff here
                if bc2_is_buff_present(food_buff_texture) then
                    return true
                end
            end
        else
            bufftexture = bc2_weapon_buffs[buffname]
            if bufftexture then
                local hasMainHandEnchant, _, _, hasOffHandEnchant, _, _, _, _, _ = GetWeaponEnchantInfo()
                local mainHandLink = GetInventoryItemLink("player", GetInventorySlotInfo("MainHandSlot"))
                local offHandLink = GetInventoryItemLink("player", GetInventorySlotInfo("SecondaryHandSlot"))
                local id1 = bc2_item_link_to_item_id(mainHandLink)
                local id2 = bc2_item_link_to_item_id(offHandLink)
                if id1 ~= nil then
                    local _, _, _, _, _, sType, _, _ = GetItemInfo(id1)
                    if(string.sub(sType, 0, 1) == "O") then
                        if hasMainHandEnchant == nil then
                            return false
                        end
                    elseif(string.sub(sType, 0, 1) == "T") then -- two handed
                        if(hasMainHandEnchant == nil) then
                            return false
                        end
                    end
                end
                if id2 ~= nil then
                    local _, _, _, _, _, sType, _, _ = GetItemInfo(id2)
                    if(string.sub(sType, 0, 1) == "O") then
                        if hasOffHandEnchant == nil then
                            return false
                        end
                    end
                end
                return true
            end
        end
    end
    return false
end

--======================================================================================================================

function bc2_is_buff_present(texture, spell_name)
    local x
    local bufftexture

    for x = 1, 32 do
        bufftexture = UnitBuff("player", x)

        if bufftexture == nil then
            break
        elseif texture == bufftexture then
            if spell_name ~= nil and spell_name ~= "" then
                BuffCheck2Tooltip:SetPlayerBuff(x - 1)
                local name = BuffCheck2TooltipTextLeft1:GetText()
                if name == spell_name then
                    return true
                end
            else
                return true
            end
        end
    end
    return false
end

--======================================================================================================================

function bc2_texture_to_name(texture)
    for spell_name, spell_info in bc2_item_buffs do
        if(bc2_has_value(spell_info.buff_path, texture)) then
            return spell_name
        end
    end

    for spell_name, spell_info in bc2_food_buffs do
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

    for spell_name, spell_info in bc2_food_buffs do
        if(spell_name == name) then
            return spell_info.buff_path
        end
    end

    return ""
end

--======================================================================================================================

function bc2_item_link_to_item_id(itemLink)
    -- item link format ex: |Hitem:6948:0:0:0:0:0:0:0|h[Hearthstone]|h
    -- matches anything inside the first 2 :'s ex: |Hitem:6948:0:0:0:0: -> 6948
    if itemLink ~= nil then
        return string.match(itemLink, ":(%d+)")
    else
        return nil
    end
end

function bc2_item_link_to_item_name(itemLink)
    -- item link format ex: |Hitem:6948:0:0:0:0:0:0:0|h[Hearthstone]|h
    -- matches anything inside square brackets ex: asdasd[abc]asdasd -> abc
    if itemLink ~= nil then
        return string.match(itemLink, "%[(.+)%]")
    else
        return nil
    end
end

function bc2_get_item_name_from_args(args)
    -- ideal args format "add [Elixir of the Mongoose]
    -- matches anything inside square brackets ex: asdasd[abc]asdasd -> abc
    -- copy paste of bc2_item_link_to_item_name, keeping it seperate in case the pattern needs changed later
    if args ~= nil then
        return string.match(args, "%[(.+)%]")
    else
        return nil
    end
end

--======================================================================================================================

-- quick function to print a msg to the chat log

function bc2_send_message(message)
    DEFAULT_CHAT_FRAME:AddMessage(string.format(bc2_default_print_format, tostring(message)))
end

--======================================================================================================================

function bc2_tprint(tbl, indent)
    if not indent then indent = 0 end
    for k, v in pairs(tbl) do
        local formatting = string.rep("  ", indent) .. k .. ": "
        if type(v) == "table" then
            bc2_send_message(formatting)
            bc2_tprint(v, indent+1)
        elseif type(v) == 'boolean' then
            bc2_send_message(formatting .. tostring(v))
        else
            bc2_send_message(formatting .. v)
        end
    end
end

--======================================================================================================================

function bc2_GetTextureByID(id)
    local _, _, _, _, _, _, _, _, texture = GetItemInfo(id)
    if texture == nil then
        bc2_send_message("Could not find texture for " .. tostring(id))
    end
    return texture
end

--======================================================================================================================

function bc2_update_bag_contents()
    -- clear bc2_bag_contents
    for k in pairs(bc2_bag_contents) do
        bc2_bag_contents[k] = 0
    end
    -- rebuild bc2_bag_contents
    -- note: bags start at index 0 (Backpack)
    for i = 0, 4 do
        local numberOfSlots = GetContainerNumSlots(i)
        for j = 1, numberOfSlots do
            local itemLink = GetContainerItemLink(i, j)
            if(itemLink ~= nil) then
                local _, itemCount, _, _, _ = GetContainerItemInfo(i, j)
                local itemname = bc2_item_link_to_item_name(itemLink)
                if bc2_bag_contents[itemname] ~= nil then
                    bc2_bag_contents[itemname] = bc2_bag_contents[itemname] + itemCount
                else
                    bc2_bag_contents[itemname] = itemCount
                end
            end
        end
    end
end

--======================================================================================================================

function bc2_test()
    bc2_send_message("buffcheck2_saved_consumes")
    bc2_tprint(buffcheck2_saved_consumes)
    bc2_send_message("bc2_current_consumes")
    bc2_tprint(bc2_current_consumes)
end

--======================================================================================================================
--======================================================================================================================
--======================================================================================================================

-- GUI specific functions


function bc2_add_item_to_interface(consume, index)
    local button, icon, count
    if consume ~= "Interface\\Icons\\Spell_Nature_WispSplode" then
        button = getglobal("BuffCheck2Button"..index)
        icon = getglobal("BuffCheck2Button"..index.."Icon")
        count = getglobal("BuffCheck2Button"..index.."Count")
        local texture
        if bc2_item_buffs[consume] then
            texture = bc2_GetTextureByID(bc2_item_buffs[consume].id)
        elseif bc2_food_buffs[consume] then
            texture = bc2_GetTextureByID(bc2_food_buffs[consume].id)
        elseif bc2_weapon_buffs[consume] then
            texture = bc2_GetTextureByID(bc2_weapon_buffs[consume].id)
        end
        if texture then
            icon:SetTexture(texture)
            local consume_count = bc2_bag_contents[bc2_current_consumes[index]]
            count:SetText(consume_count) -- still needed for when new items are added
            if string.len(consume_count) == 2 then
                count:SetPoint("LEFT", button, "RIGHT", -16, -10)
            else
                count:SetPoint("LEFT", button, "RIGHT", -10, -10)
            end
            button:Show()
        else
            bc2_send_message("Error in bc2_add_item_to_interface with consume: " .. consume)
        end

        return
    else
        button = getglobal("BuffCheck2Button1")
        icon = getglobal("BuffCheck2Button1Icon")
        count = getglobal("BuffCheck2Button1Count")
        icon:SetTexture(consume)
        count:SetText("")
        button:Show()
    end
end

function bc2_update_item_counts()
    local button, icon, count
    for i = 1, table.getn(bc2_current_consumes) do
        button = getglobal("BuffCheck2Button"..i)
        icon = getglobal("BuffCheck2Button"..i.."Icon")
        local texture = icon:GetTexture()
        if texture ~= "Interface\\Icons\\Spell_Nature_WispSplode" then
            count = getglobal("BuffCheck2Button"..i.."Count")
            local consume_count = bc2_bag_contents[bc2_current_consumes[i]]
            count:SetText(consume_count)
            if string.len(consume_count) == 2 then
                count:SetPoint("LEFT", button, "RIGHT", -16, -10)
            else
                count:SetPoint("LEFT", button, "RIGHT", -10, -10)
            end
        end
    end
end

function bc2_set_item_cooldowns()
    for i = 0, 4 do
        local numberOfSlots = GetContainerNumSlots(i)
        for j = 1, numberOfSlots do
            local itemLink = GetContainerItemLink(i, j)
            if(itemLink ~= nil) then
                local itemname = bc2_item_link_to_item_name(itemLink)
                for k = 1, table.getn(bc2_current_consumes) do
                    if bc2_current_consumes[k] == itemname then
                        local _, duration, _ = GetContainerItemCooldown(i, j)
                        local button = getglobal("BuffCheck2Button"..k)
                        button.cooldown(GetTime(), duration)
                    end
                end
            end
        end
    end
end

function bc2_button_onclick(id)
    local consume = bc2_current_consumes[id]
    -- note: bags start at index 0 (Backpack)
    for i = 0, 4 do
        local numberOfSlots = GetContainerNumSlots(i)
        for j = 1, numberOfSlots do
            local itemLink = GetContainerItemLink(i, j)
            if(itemLink ~= nil) then
                local itemname = bc2_item_link_to_item_name(itemLink)
                if itemname == consume then
                    UseContainerItem(i, j, 1)
                    bc2_send_message("Using " .. itemLink)
                    table.remove(bc2_current_consumes, id)
                    return
                end
            end
        end
    end
end

function bc2_show_tooltip(id)
    local consume = bc2_item_buffs[bc2_current_consumes[id]]

    if consume == nil then
        consume = bc2_food_buffs[bc2_current_consumes[id]]
    end

    if consume then
        local _, link = GetItemInfo(consume.id)
        GameTooltip:SetOwner(getglobal("BuffCheck2Button"..id), "ANCHOR_BOTTOMRIGHT")
        GameTooltip:SetHyperlink(link)
        GameTooltip:Show()
    end
end

function bc2_scale_interface(scale)
    local map_result = scale / 100
    BuffCheck2Frame:SetScale(map_result)
    BuffCheck2Frame:ClearAllPoints()
    BuffCheck2Frame:SetPoint("CENTER", "UIParent")
    buffcheck2_config["scale"] = scale
    bc2_send_message("scaled to " .. scale)
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
