GearSets = {}
StripTable = {"Boots","Breast","Cloak","Gloves","Helmet","Underwear","VanityBody","VanityBoots", "MeleeMainHand", "MeleeOffHand", "RangedMainHand", "RangedOffHand"}

function StripListeners()

    Ext.Osiris.RegisterListener("ObjectTimerFinished", 2, "after", function(actor, timer)
        if timer == "Strip" then
            Osi.ApplyStatus(actor, "PASSIVE_WILDMAGIC_MAGICRETRIBUTION_DEFENDER", 1)
            Strip(actor)
        end
    end)

    Ext.Osiris.RegisterListener("ObjectTimerFinished", 2, "after", function(actor, timer)
        if timer == "Redress" then
            Osi.ApplyStatus(StripActor1, "PASSIVE_WILDMAGIC_MAGICRETRIBUTION_DEFENDER", 1)
            if table.empty(CurrentEquipmentActor1) == false then
                for _, item in ipairs(CurrentEquipmentActor1) do
                    Osi.Equip(actor, item)
                end
            CurrentEquipmentActor1 = {}

            end
            if StripActor2 then
                Osi.ApplyStatus(StripActor1, "PASSIVE_WILDMAGIC_MAGICRETRIBUTION_DEFENDER", 1)
                if table.empty(CurrentEquipmentActor2) == false then
                    for _, item in ipairs(CurrentEquipmentActor2) do
                        Osi.Equip(StripActor1, item)
                    end
                CurrentEquipmentActor2 = {}
                end
            end
        end
    end)
end


function Strip(actor)
    Osi.SetArmourSet(actor, 1)
    local currentEquipment = {}

    for i, slotName in ipairs(StripTable) do
        local gearPiece = Osi.GetEquippedItem(actor, slotName)
        if gearPiece ~= nil then
            Osi.LockUnequip(gearPiece, 0)
            Osi.Unequip(actor, gearPiece)
            currentEquipment[#currentEquipment+1] = gearPiece
        end
    end
    GearSets[actor] = currentEquipment
end


function Redress(actor)
    Osi.SetArmourSet(actor, 0)
    for key, set in pairs(GearSets) do
        if actor == key then
            for _, item in pairs(set) do
                Osi.Equip(actor, item)
            end
            GearSets[key] = nil  -- Optionally remove the entry from GearSets after undoing
            break  -- Assuming each actor should have only one entry in GearSets
        end
    end
end


Ext.Events.SessionLoaded:Subscribe(StripListeners)