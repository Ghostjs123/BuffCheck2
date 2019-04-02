bc2_default_print_format = "|c00f7f26c%s|r"

buffcheck2_config = {}
buffcheck2_saved_consumes = {} -- should contain the actual name of the item, not the buff texture
bc2_current_consumes = {}

bc2_button_count = 25

bc2_bag_contents = {}

buffcheck2_current_timers = {}

bc2_showed_already = false

bc2_backdrop_backup = "empty"

bc2_current_selected_weapon_buff = ""
bc2_was_spell_targeting = false

food_buff_textures = {"Interface\\Icons\\INV_Boots_Plate_03", "Interface\\Icons\\Spell_Misc_Food",
    "Interface\\Icons\\INV_Gauntlets_19", "Interface\\Icons\\Spell_Nature_ManaRegenTotem",
    "Interface\\Icons\\Spell_Holy_Devotion", "Interface\\Icons\\Spell_Holy_LayOnHands", "Interface\\Icons\\INV_Misc_Organ_03"}

--======================================================================================================================

SlashCmdList["SLASH_BUFFCHECK2"] = function() end

SLASH_BUFFCHECK1, SLASH_BUFFCHECK2, SLASH_BUFFCHECK3 = "/bc2", "/buffcheck2", "/bw2" -- added bw2 bc i keep misstyping it
function SlashCmdList.BUFFCHECK(args) -- for some reason if I do .BUFFCHECK2 it doesnt work, doesnt like numbers?

    if(args == "") then
        -- print default usage
        bc2_send_message("BuffCheck2 Commands:")
        bc2_send_message("add [ItemLink] - adds the item")
        bc2_send_message("remove [ItemLink] - removes the item")
        bc2_send_message("lock - locks the frame")
        bc2_send_message("unlock - unlocks the frame")
        bc2_send_message("show - shows the frame")
        bc2_send_message("hide - hides the frame")
        bc2_send_message("scale - scales the frame, default is 100")
        bc2_send_message("clear - clears the saved list of consumes")
        bc2_send_message("vertical - makes the frame vertical")
        bc2_send_message("horizontal - makes the frame horizontal")
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
    elseif(string.find(args, "vertical") ~= nil) then
        bc2_change_to_vertical()
    elseif(string.find(args, "horizontal") ~= nil) then
        bc2_change_to_horizontal()
    elseif(string.find(args, "test2") ~= nil) then
        bc2_test2()
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

function BuffCheck2_OnUpdate()
    -- hide the weapon buttons if the player started targeting and then stopped
    if SpellIsTargeting() then
        bc2_was_spell_targeting = true
    elseif bc2_was_spell_targeting and not SpellIsTargeting() then
        bc2_hide_weapon_buttons()
        bc2_was_spell_targeting = false
    end

    -- handle the expiration timers
    -- arg1 is the time since the last BuffCheck2_OnUpdate() call, BuffCheck2_OnUpdate() gets called every frame
    local needs_update = false
    local id = table.getn(buffcheck2_current_timers)
    while(id > 0) do
        local timer = buffcheck2_current_timers[id]
        -- increment elapsed and since_last_update
        timer.elapsed = timer.elapsed + arg1
        timer.since_last_update = timer.since_last_update + arg1

        -- check for soon to expire or expire
        if timer.given_warning1 == false and timer.duration - timer.elapsed < 300 then -- 5 minutes
            bc2_send_message("BuffCheck2: " .. bc2_item_name_to_item_link(timer.consume) .. string.format(bc2_default_print_format, " has 5 minutes remaining"))
            timer.given_warning1 = true
            needs_update = true
        elseif timer.given_warning2 == false and timer.duration - timer.elapsed < 120 then -- 2 minutes
            bc2_send_message("BuffCheck2: " .. bc2_item_name_to_item_link(timer.consume) .. string.format(bc2_default_print_format, " has 2 minutes remaining"))
            timer.given_warning2 = true
            needs_update = true -- might not be needed
        elseif timer.elapsed > timer.duration then
            bc2_send_message("BuffCheck2: " .. bc2_item_name_to_item_link(timer.consume) .. string.format(bc2_default_print_format, " has expired"))
            table.remove(buffcheck2_current_timers, id)
        end
        id = id - 1
    end

    -- update the frame to add any soon to expire timers to the interface
    if needs_update then
        bc2_update_frame()
    end

    -- finally update the remaining time on soon to expire consumes
    -- need to wait until the bc2_update_frame() call before doing this so that the consume is in the interface
    for _, active_timer in buffcheck2_current_timers do
        if active_timer.given_warning1 then
            if active_timer.since_last_update > 1 then -- update every second instead of every frame
                local button, duration
                for i = 1, table.getn(bc2_current_consumes) do
                    button = getglobal("BuffCheck2Button"..i)
                    if button.consume == active_timer.consume then
                        duration = getglobal("BuffCheck2Button"..i.."Duration")
                        local remainder = floor(active_timer.duration - active_timer.elapsed)
                        if remainder < 10 then
                            duration:ClearAllPoints()
                            duration:SetPoint("LEFT", button, "RIGHT", -20, 2)
                        else
                            duration:ClearAllPoints()
                            duration:SetPoint("LEFT", button, "RIGHT", -25, 2)
                        end
                        if remainder > 60 then
                            remainder = floor(remainder / 60 + 0.5)
                            remainder = tostring(remainder) .. "m"
                        end
                        duration:SetText(remainder)
                    end
                end
                active_timer.since_last_update = 0
            end
        end
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

    -- make a cooldown frame for each button
    local button
    for i = 1, bc2_button_count do
        button = getglobal("BuffCheck2Button"..i)
        local myCooldown = CreateFrame("Model", nil, button, "CooldownFrameTemplate")

        button.cooldown = function(start, duration)
            CooldownFrame_SetTimer(myCooldown, start, duration, 1)
        end
    end

    bc2_update_bag_contents()

    bc2_update_frame()

    bc2_update_item_counts()

    -- set the OnUpdate event
    BuffCheck2Frame:SetScript("OnUpdate", BuffCheck2_OnUpdate)

    if buffcheck2_config["orientation"] == "vertical" then
        bc2_change_to_vertical()
    else
        bc2_change_to_horizontal()
    end

    this:UnregisterEvent("VARIABLES_LOADED")
    bc2_send_message("BuffCheck2 - Init successful")
end

--======================================================================================================================

-- called on "PLAYER_AURAS_CHANGED", bc2_init(), bc2_add_item_to_saved_list(),
-- bc2_remove_item_from_saved_list(), bc2_show_frame(), bc2_update_frame(), BuffCheck2_OnUpdate()

function bc2_update_frame()
    -- rebuild the current missing consumes
    bc2_clear_current_consumes()
    local count = 1
    for _, consume in buffcheck2_saved_consumes do
        local has_buff = bc2_player_has_buff(consume)
        -- add any missing consumes
        if has_buff == false then
            bc2_current_consumes[count] = consume
            count = count + 1
        -- add the consume to current_consumes if it will expire soon
        elseif has_buff == true and bc2_consume_has_timer(consume) then
            for _, active_timer in buffcheck2_current_timers do
                if active_timer.given_warning1 and active_timer.consume == consume then
                    bc2_current_consumes[count] = active_timer.consume
                    count = count + 1
                end
            end
        end
    end

    -- if the consume is not present and the timer has been active for more than 30 seconds then remove the timer
    local i = table.getn(buffcheck2_current_timers)
    while i > 0 do
        if bc2_player_has_buff(buffcheck2_current_timers[i].consume) == false and buffcheck2_current_timers[i].since_last_update > 30 then
            table.remove(buffcheck2_current_timers, i)
        end
        i = i - 1
    end

    -- display the current missing consumes
    count = 1
    for _, consume in bc2_current_consumes do
        bc2_add_item_to_interface(consume, count, bc2_consume_has_timer(consume))
        count = count + 1
    end

    -- hide the rest of the buttons
    for i = count, bc2_button_count do
        local button = getglobal("BuffCheck2Button"..i)
        if button:IsVisible() then
            button:Hide()
        end
    end

    -- if no missing consumes display the placeholder and resize the frame
    if table.getn(bc2_current_consumes) == 0 then
        bc2_add_item_to_interface("Interface\\Icons\\Spell_Nature_WispSplode")
        BuffCheck2Frame:SetWidth(54)
        BuffCheck2Frame:SetHeight(54)
    elseif buffcheck2_config["orientation"] == "vertical" then
        BuffCheck2Frame:SetWidth(54)
        BuffCheck2Frame:SetHeight(54 + (table.getn(bc2_current_consumes) - 1) * 36)
    else
        BuffCheck2Frame:SetWidth(54 + (table.getn(bc2_current_consumes) - 1) * 36)
        BuffCheck2Frame:SetHeight(54)
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
        local itemname, link, quality = GetItemInfo(bufftexture.id)
        if itemname == nil then
            BuffCheck2Tooltip:SetHyperlink("item:"..bufftexture.id..":0:0:0") -- this will query the server and add it to the wdb if found
        end
        if contains then
            bc2_send_message("BuffCheck2: " .. item_name .. string.format(bc2_default_print_format, " is already added"))
        else
            table.insert(buffcheck2_saved_consumes, item_name)
            bc2_send_message("BuffCheck2: added: " .. item_name)
            bc2_update_frame()
            bc2_update_item_counts()
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
            bc2_send_message("BuffCheck2: " .. item_name .. string.format(bc2_default_print_format, " is not added"))
        else
            table.remove(buffcheck2_saved_consumes, bc2_get_index_in_table(buffcheck2_saved_consumes, item_name))
            bc2_send_message("BuffCheck2: removed: " .. item_name)
            -- remove any timers that may still exist for the consume
            for id, active_timer in buffcheck2_current_timers do
                if active_timer.consume == item_name then
                    table.remove(buffcheck2_current_timers, id)
                end
            end
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
    bc2_backdrop_backup = backdrop
    BuffCheck2Frame:SetBackdrop({})
    bc2_send_message("BuffCheck2 - Interface locked")
end

function bc2_unlock_frame()
    buffcheck2_config["locked"] = false
    BuffCheck2Frame:EnableMouse(true)
    if bc2_backdrop_backup ~= "empty" then
        BuffCheck2Frame:SetBackdrop(bc2_backdrop_backup)
    else
        local backdrop = BuffCheck2Frame:GetBackdrop()
        backdrop["insets"] = { top = 12, bottom = 11, right = 12, left = 11 }
        backdrop["tile"] = true
        backdrop["tileSize"] = 32
        backdrop["edgeSize"] = 32
        bc2_backdrop_backup = backdrop
        BuffCheck2Frame:SetBackdrop(backdrop)
    end
    bc2_send_message("BuffCheck2 - Interface unlocked")
end

--======================================================================================================================

function bc2_show_frame(should_update)
    buffcheck2_config["showing"] = true
    BuffCheck2Frame:Show()
    bc2_send_message("BuffCheck2 - Interface showing")
    if should_update == true or should_update == nil then
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
    -- also clear all active timers
    bc2_clear_timers()
    bc2_update_frame()
    bc2_send_message("BuffCheck2: cleared saved consumes")
end

function bc2_clear_timers()
    while(table.getn(buffcheck2_current_timers) > 0) do
        table.remove(buffcheck2_current_timers, 1)
    end
end

function bc2_clear_current_consumes()
    for k in pairs(bc2_current_consumes) do
        bc2_current_consumes[k] = nil
    end
end

--======================================================================================================================

function bc2_check_group_update()
    if(UnitInRaid("player") == 1 and bc2_showed_already == false) then
        if BuffCheck2Frame:IsVisible() ~= true then
            bc2_show_frame()
            bc2_showed_already = true
        end
    end
end

--======================================================================================================================

function bc2_player_has_buff(buffname)
    local bufftexture = bc2_item_buffs[buffname]
    if bufftexture then
        if bufftexture.buff_name ~= nil then
            return bc2_is_buff_present(bufftexture.buff_path, bufftexture.buff_name)
        else
            return bc2_is_buff_present(bufftexture.buff_path)
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
                    if sType == nil then
                        return false
                    elseif(string.sub(sType, 0, 1) == "O" or string.sub(sType, 0, 1) == "D") then
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
                    if(string.sub(sType, 0, 1) == "O" or string.sub(sType, 0, 1) == "D") then
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

-- called in bc2_player_has_buff()
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

function bc2_item_name_to_item_link(name)
    for spell_name, spell_info in bc2_item_buffs do
        if spell_name == name  then
            local itemname, link, quality = GetItemInfo(spell_info.id)
            if(quality == nil or quality < 0 or quality > 7) then
                quality = 1
            end
            local r,g,b = GetItemQualityColor(quality)
            if itemname == nil then
                bc2_send_message("BuffCheck2: error - " .. name .. " is not in your wdb")
                bc2_remove_item_from_saved_list(name)
                return name
            else
                return "|cff" ..bc2_rgbToHex({r, g, b}).."|H"..link.."|h["..itemname.."]|h|r"
            end
        end
    end

    for spell_name, spell_info in bc2_food_buffs do
        if spell_name == name  then
            local itemname, link, quality = GetItemInfo(spell_info.id)
            if(quality == nil or quality < 0 or quality > 7) then
                quality = 1
            end
            local r,g,b = GetItemQualityColor(quality)
            if itemname == nil then
                bc2_send_message("BuffCheck2: error - " .. name .. " is not in your wdb")
                bc2_remove_item_from_saved_list(name)
                return name
            else
                return "|cff" ..bc2_rgbToHex({r, g, b}).."|H"..link.."|h["..itemname.."]|h|r"
            end
        end
    end

    for spell_name, spell_info in bc2_weapon_buffs do
        if spell_name == name  then
            local itemname, link, quality = GetItemInfo(spell_info.id)
            if(quality == nil or quality < 0 or quality > 7) then
                quality = 1
            end
            local r,g,b = GetItemQualityColor(quality)
            if itemname == nil then
                bc2_send_message("BuffCheck2: error - " .. name .. " is not in your wdb")
                bc2_remove_item_from_saved_list(name)
                return name
            else
                return "|cff" ..bc2_rgbToHex({r, g, b}).."|H"..link.."|h["..itemname.."]|h|r"
            end
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
    -- ideal args format "add [Elixir of the Mongoose]"
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
        BuffCheck2Tooltip:SetHyperlink("item:"..id..":0:0:0") -- this will query the server and add it to the wdb if found
        return "Interface\\Icons\\Spell_Nature_WispSplode"
    end
    return texture
end

--======================================================================================================================

function bc2_update_bag_contents()
    -- clear bc2_bag_contents
    for k in pairs(bc2_bag_contents) do
        bc2_bag_contents[k] = 0
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
                    if itemname ~= nil then -- got an error here when i logged on a new char, added this check
                        bc2_bag_contents[itemname] = itemCount
                    end
                end
            end
        end
    end
end

--======================================================================================================================

function bc2_set_expiration_timer(consume)
    -- if there is already an active timer then reset it
    if bc2_consume_has_timer(consume) then
        for _, active_timer in buffcheck2_current_timers do
            if active_timer.consume == consume then
                active_timer.elapsed = 0
                active_timer.given_warning1 = false
                active_timer.given_warning2 = false
            end
        end
    else
        -- otherwise make a new timer
        local consume_info
        if bc2_item_buffs[consume] ~= nil then
            consume_info = bc2_item_buffs[consume]
        elseif bc2_food_buffs[consume] ~= nil then
            consume_info = bc2_food_buffs[consume]
        elseif bc2_weapon_buffs[consume] ~= nil then
            consume_info = bc2_weapon_buffs[consume]
        end
        if consume_info then
            local timer = {}
            timer.consume = consume
            timer.duration = consume_info.duration
            timer.elapsed = 0
            timer.since_last_update = 0
            timer.given_warning1 = false
            timer.given_warning2 = false

            if timer.duration ~= 0 then -- don't add consumes w/ duration 0
                table.insert(buffcheck2_current_timers, timer)
            end
        end
    end
end

--======================================================================================================================

function bc2_consume_has_timer(consume)
    for _, active_timer in buffcheck2_current_timers do
        if active_timer.consume == consume then
            return true
        end
    end
    return false
end

--======================================================================================================================

function bc2_test()
    --[[bc2_send_message("buffcheck2_saved_consumes")
    bc2_tprint(buffcheck2_saved_consumes)
    bc2_send_message("bc2_current_consumes")
    bc2_tprint(bc2_current_consumes)]]--

    local consume = "Gordok Green Grog"

    local consume_info
    if bc2_item_buffs[consume] ~= nil then
        consume_info = bc2_item_buffs[consume]
    elseif bc2_food_buffs[consume] ~= nil then
        consume_info = bc2_food_buffs[consume]
    elseif bc2_weapon_buffs[consume] ~= nil then
        consume_info = bc2_weapon_buffs[consume]
    end
    if consume_info then
        local timer = {}
        timer.consume = consume
        --timer.duration = consume_info.duration
        timer.duration = 10
        timer.elapsed = 0
        timer.since_last_update = 10.1
        timer.given_warning1 = false
        timer.given_warning2 = false
        table.insert(buffcheck2_current_timers, timer)
    end
end

function bc2_test2()
    bc2_tprint(buffcheck2_current_timers)
end

--======================================================================================================================
--======================================================================================================================
--======================================================================================================================

-- GUI specific functions


function bc2_add_item_to_interface(consume, index, is_timer)
    local button, icon, count
    if consume ~= "Interface\\Icons\\Spell_Nature_WispSplode" then
        button = getglobal("BuffCheck2Button"..index)
        icon = getglobal("BuffCheck2Button"..index.."Icon")
        count = getglobal("BuffCheck2Button"..index.."Count")
        local texture, dont_lock_highlight
        if bc2_item_buffs[consume] then
            texture = bc2_GetTextureByID(bc2_item_buffs[consume].id)
            dont_lock_highlight = false
        elseif bc2_food_buffs[consume] then
            texture = bc2_GetTextureByID(bc2_food_buffs[consume].id)
            dont_lock_highlight = false
        elseif bc2_weapon_buffs[consume] then
            texture = bc2_GetTextureByID(bc2_weapon_buffs[consume].id)
            dont_lock_highlight = true
        end
        if texture then
            icon:SetTexture(texture)
            button.texture = texture
            local consume_count = bc2_bag_contents[consume]
            count:SetText(consume_count)
            if string.len(consume_count) == 2 then
                count:SetPoint("LEFT", button, "RIGHT", -16, -10)
            else
                count:SetPoint("LEFT", button, "RIGHT", -10, -10)
            end
            if is_timer == true then -- the consume is still active but close to expiration
                local highlight = getglobal("BuffCheck2Button"..index.."Highlight")
                highlight:Show()
                if not dont_lock_highlight then
                    button.lockedHighlight = true
                end
            else
                local highlight = getglobal("BuffCheck2Button"..index.."Highlight")
                local duration = getglobal("BuffCheck2Button"..index.."Duration")
                highlight:Hide()
                duration:SetText("")
                button.lockedHighlight = false
            end
            button:Show()

            button.consume = consume
        end
    else
        button = getglobal("BuffCheck2Button1")
        icon = getglobal("BuffCheck2Button1Icon")
        count = getglobal("BuffCheck2Button1Count")
        icon:SetTexture(consume)
        button.texture = "Interface\\Icons\\Spell_Nature_WispSplode"
        count:SetText("")
        button:Show()
        button.lockedHighlight = false

        button.consume = "PlaceHolder"
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
                    local button = getglobal("BuffCheck2Button"..k)
                    if button.consume == itemname then
                        -- it was putting near expiration consumes on gcd when abilities were used
                        if not bc2_consume_has_timer(itemname) then
                            local starttime, duration, _ = GetContainerItemCooldown(i, j)
                            button.cooldown(starttime, duration)
                        end
                    end
                end
            end
        end
    end

    for i = 1, table.getn(bc2_current_consumes) do
        if bc2_bag_contents[bc2_current_consumes[i]] == 0 then
            getglobal("BuffCheck2Button"..i).cooldown(GetTime(), 0)
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
                    bc2_send_message("BuffCheck2: Using " .. itemLink)
                    if bc2_weapon_buffs[bc2_current_consumes[id]] == nil then -- don't immediatly do this for weapon buffs
                        bc2_set_expiration_timer(bc2_current_consumes[id])
                    else
                        bc2_current_selected_weapon_buff = bc2_current_consumes[id]
                    end
                    return
                end
            end
        end
    end
end

-- id is the current button being hovered over
function bc2_show_weapon_buttons(id)
    local weapon_button_1 = getglobal("BuffCheck2WeaponButton1")
    weapon_button_1:ClearAllPoints()
    weapon_button_1:SetPoint("TOPLEFT", getglobal("BuffCheck2Button"..id), "TOPLEFT", 0, -36)

    local mainHandTexture = GetInventoryItemTexture("player", GetInventorySlotInfo("MainHandSlot"))
    if mainHandTexture then
        local weapon_texture_1 = getglobal("BuffCheck2WeaponButton1Icon")
        weapon_texture_1:SetTexture(mainHandTexture)
        weapon_button_1:Show()
    else
        weapon_button_1:Hide()
    end

    local weapon_button_2 = getglobal("BuffCheck2WeaponButton2")
    local offHandTexture = GetInventoryItemTexture("player", GetInventorySlotInfo("SecondaryHandSlot"))
    if offHandTexture then
        local weapon_texture_2 = getglobal("BuffCheck2WeaponButton2Icon")
        weapon_texture_2:SetTexture(offHandTexture)
        weapon_button_2:Show()
    else
        weapon_button_2:Hide()
    end
end

function bc2_hide_weapon_buttons()
    getglobal("BuffCheck2WeaponButton1"):Hide()
    getglobal("BuffCheck2WeaponButton2"):Hide()
end

-- id is either 1 for mh or 2 for oh
function bc2_weapon_button_onclick(id)
    -- apply the weapon buff
    if SpellIsTargeting() then -- make sure the cursor is ready to apply the buff
        if id == 1 then
            PickupInventoryItem(GetInventorySlotInfo("MainHandSlot"))
        else
            PickupInventoryItem(GetInventorySlotInfo("SecondaryHandSlot"))
        end
        ReplaceEnchant()
        bc2_set_expiration_timer(bc2_current_selected_weapon_buff)
    end
end

function bc2_show_tooltip(id)
    local is_weapon = false
    local consume = bc2_item_buffs[bc2_current_consumes[id]]

    if consume == nil then
        consume = bc2_food_buffs[bc2_current_consumes[id]]
    end

    if consume == nil then
        consume = bc2_weapon_buffs[bc2_current_consumes[id]]
        if consume then
            bc2_show_weapon_buttons(id)
            is_weapon = true
        end
    end

    if consume then
        local _, link = GetItemInfo(consume.id)
        -- the only time this will be nil is if the interface has a consume in it that is not in the players wdb
        if link ~= nil then
            if is_weapon then
                local offHandTexture = GetInventoryItemTexture("player", GetInventorySlotInfo("SecondaryHandSlot"))
                if offHandTexture then
                    GameTooltip:SetOwner(getglobal("BuffCheck2WeaponButton2"), "ANCHOR_BOTTOMRIGHT")
                else
                    GameTooltip:SetOwner(getglobal("BuffCheck2WeaponButton1"), "ANCHOR_BOTTOMRIGHT")
                end
            else
                GameTooltip:SetOwner(getglobal("BuffCheck2Button"..id), "ANCHOR_BOTTOMRIGHT")
            end
            GameTooltip:SetHyperlink(link)
            GameTooltip:Show()
        end
    end
end

function bc2_show_weapon_tooltip(id)
    if id == 1 then
        GameTooltip:SetOwner(getglobal("BuffCheck2WeaponButton"..id), "ANCHOR_BOTTOMRIGHT")
        GameTooltip:SetInventoryItem("player", GetInventorySlotInfo("MainHandSlot"))
        GameTooltip:Show()
    else
        GameTooltip:SetOwner(getglobal("BuffCheck2WeaponButton"..id), "ANCHOR_BOTTOMRIGHT")
        GameTooltip:SetInventoryItem("player", GetInventorySlotInfo("SecondaryHandSlot"))
        GameTooltip:Show()
    end
end

function bc2_update_texture(id)
    local button = getglobal("BuffCheck2Button"..id)
    local icon = getglobal("BuffCheck2Button"..id.."Icon")
    local consume = button.consume
    local consume_info
    if bc2_item_buffs[consume] ~= nil then
        consume_info = bc2_item_buffs[consume]
    elseif bc2_food_buffs[consume] ~= nil then
        consume_info = bc2_food_buffs[consume]
    elseif bc2_weapon_buffs[consume] ~= nil then
        consume_info = bc2_weapon_buffs[consume]
    end
    if consume_info ~= nil then
        local texture = bc2_GetTextureByID(consume_info.id)
        if texture == "Interface\\Icons\\Spell_Nature_WispSplode" then
            bc2_send_message("BuffCheck2: " .. consume .. " cannot be found on this server")
            bc2_remove_item_from_saved_list(consume)
        else
            icon:SetTexture(texture)
            button.texture = texture
        end
    end
end

function bc2_scale_interface(scale)
    local map_result = scale / 100
    BuffCheck2Frame:SetScale(map_result)
    BuffCheck2Frame:ClearAllPoints()
    BuffCheck2Frame:SetPoint("CENTER", "UIParent")
    buffcheck2_config["scale"] = scale
    bc2_send_message("BuffCheck2: scaled to " .. scale)
end

function bc2_change_to_vertical()
    buffcheck2_config["orientation"] = "vertical"
    local button
    for i = 2, bc2_button_count do
        button = getglobal("BuffCheck2Button"..i)
        button:ClearAllPoints()
        button:SetPoint("TOPLEFT", getglobal("BuffCheck2Button"..tostring(i-1)), "TOPLEFT", 0, -36)
    end
    BuffCheck2Frame:SetWidth(54)
    BuffCheck2Frame:SetHeight(54 + (table.getn(bc2_current_consumes) - 1) * 36)
end

function bc2_change_to_horizontal()
    buffcheck2_config["orientation"] = "horizontal"
    local button
    for i = 2, bc2_button_count do
        button = getglobal("BuffCheck2Button"..i)
        button:ClearAllPoints()
        button:SetPoint("TOPLEFT", getglobal("BuffCheck2Button"..tostring(i-1)), "TOPLEFT", 36, 0)
    end
    BuffCheck2Frame:SetWidth(54 + (table.getn(bc2_current_consumes) - 1) * 36)
    BuffCheck2Frame:SetHeight(54)
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

function bc2_rgbToHex(rgb)
    local hexadecimal = ''

    for key, value in pairs(rgb) do
        local hex = ''

        value = value * 255

        while(value > 0)do
            -- a % b == a - math.floor(a/b)*b
            --local index = math.fmod(value, 16) + 1
            local index = value - math.floor(value / 16) * 16 + 1
            value = math.floor(value / 16)
            hex = string.sub('0123456789ABCDEF', index, index) .. hex
        end

        if(string.len(hex) == 0)then
            hex = '00'

        elseif(string.len(hex) == 1)then
            hex = '0' .. hex
        end

        hexadecimal = hexadecimal .. hex
    end

    return hexadecimal
end

function bc2_roundToNthDecimal(num, n)
    local mult = 10^(n or 0)
    return math.floor(num * mult + 0.5) / mult
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
