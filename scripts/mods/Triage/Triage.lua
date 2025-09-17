--[[
Title: Triage
Author: Wobin
Date: 23/08/2025
Repository: https://github.com/Wobin/Triage
Version: 1.0
--]]
local mod = get_mod("Triage")

local CLASS = CLASS
local Managers = Managers
local ScriptUnit = ScriptUnit
local PlayerManager = Managers.player
local HasExtension = ScriptUnit.has_extension

local health_syringe = "content/items/pocketable/syringe_corruption_pocketable"

mod.targets = {}
mod.outlined = {}
local targets = mod.targets

mod.on_game_state_changed = function()
    mod.targets = {}
    mod:clean_outline()
    mod.outlined = {}
    mod.wielding = nil
end

mod.clean_outline = function()
    local outline_system = Managers.state and Managers.state.extension and Managers.state.extension:system("outline_system")
    if not outline_system then return end
    for player, _ in pairs(mod.outlined) do                           
        outline_system:remove_outline(player, "triage")
    end
end

mod:hook_require("scripts/settings/outline/outline_settings", function(settings)    
     settings.PlayerUnitOutlineExtension.triage = {
        priority = 1,
        color = {0,0,1},
        material_layers = {
            "player_outline_knocked_down",
            "player_outline_knocked_down_reversed_depth"
        },
        visibility_check = function(unit) return targets[unit] end
    }
end)

local throttle = 0
mod.update = function(dt)
    if not mod.wielding then return end
    if dt + throttle < 1 then 
        throttle = throttle + dt
        return             
    end
    throttle = 0
    mod:check_health()
end
   
mod.check_health = function()  
    local players = PlayerManager:players()
    for _, player in pairs(players) do
        if player then
            local health_sys = HasExtension(player.player_unit, "health_system")
            local corrupted = health_sys:permanent_damage_taken_percent() 
            local max_wounds = health_sys:max_wounds()           
            if corrupted > 0 and  corrupted >= (1 - 1 / max_wounds) then                                  
                targets[player.player_unit] = true                
            else
                targets[player.player_unit] = nil
            end                    
        end    
    end
end

mod:hook_safe(CLASS.ActionHandler, "start_action", function(self, _, _, action_name)            
        
        local outline_system = Managers.state and Managers.state.extension:system("outline_system")
        local players = PlayerManager:players()    
        if (action_name == "action_wield" or action_name == "action_aim") and self._inventory_component[self._inventory_component.wielded_slot] == health_syringe then
            mod.wielding = true
	        for _, player in pairs(players) do           
			    outline_system:add_outline(player.player_unit, "triage")
                mod.outlined[player.player_unit] = true
            end
        else
            mod:clean_outline()
            mod.outlined = {}
            mod.wielding = false
        end
end)

