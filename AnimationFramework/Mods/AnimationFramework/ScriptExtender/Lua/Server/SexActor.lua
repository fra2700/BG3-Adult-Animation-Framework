
local FLAG_COMPANION_IN_CAMP = "161b7223-039d-4ebe-986f-1dcd9a66733f"

local function RemoveSexPositionSpells(actor)
    TryRemoveSpell(actor, "StraightAnimationsContainer")
    TryRemoveSpell(actor, "LesbianAnimationsContainer")
    TryRemoveSpell(actor, "FemaleMasturbationContainer")
    TryRemoveSpell(actor, "MaleMasturbationContainer")
end

local function BlockActorMovement(actor)
    Osi.AddBoosts(actor, "ActionResourceBlock(Movement)", "", "")
end

local ORGASM_SOUNDS = {
    "Player_Races_Voice_Combat_Recover",
    "Player_Races_Voice_Combat_Recover_Chance",
    "Player_Races_Voice_Combat_Recover_Cinematics",
    "Player_Races_Voice_Gen_Recover",
    "Player_Races_Voice_Gen_Recover_Cinematics"
}


function SexActor_Init(actor, vocalTimerName, animProperties)
    local actorData = {
        Actor = actor,
        Proxy = nil,
        Animation = "",
        SoundTable = {},
        VocalTimerName = vocalTimerName,
        Strip = (animProperties["Strip"] == true and Osi.HasActiveStatus(actor, "BLOCK_STRIPPING") == 0)
    }

    Osi.SetDetached(actor, 1)
    Osi.DetachFromPartyGroup(actor)

    TryRemoveSpell(actor, "StartSexContainer")
    RemoveSexPositionSpells(actor) -- Just in case

    -- Clear FLAG_COMPANION_IN_CAMP to prevent companions from teleporting to their tent while all this is happening
    if Osi.GetFlag(FLAG_COMPANION_IN_CAMP, actor) == 1 then
        Osi.ClearFlag(FLAG_COMPANION_IN_CAMP, actor)
        actorData.IsCompanionInCamp = true
    end

    return actorData
end

function SexActor_Terminate(actorData)
    if actorData.Proxy then
        -- Delete proxy
        Osi.StopAnimation(actorData.Proxy, 1)
        Osi.TeleportToPosition(actorData.Proxy, 0, 0, 0)
        Osi.SetOnStage(actorData.Proxy, 0) -- Disable AI, remove the model
        Osi.RequestDeleteTemporary(actorData.Proxy)
        actorData.Proxy = nil

        Osi.TeleportToPosition(actorData.Actor, actorData.StartX, actorData.StartY, actorData.StartZ)
        Osi.SetVisible(actorData.Actor, 1)
    else
        Osi.StopAnimation(actorData.Actor, 1)
    end

    -- Orgasm
    Osi.PlaySound(actorData.Actor, ORGASM_SOUNDS[math.random(1, #ORGASM_SOUNDS)])

    Osi.RemoveBoosts(actorData.Actor, "ActionResourceBlock(Movement)", 0, "", "")
    SexActor_StopVocalTimer(actorData)

    if SexActor_IsStripped(actorData) then
        SexActor_Redress(actorData)
    end

    RemoveSexPositionSpells(actorData.Actor)
    if Osi.IsPartyMember(actorData.Actor, 0) == 1 then
        AddMainSexSpells(actorData.Actor)
    end

    if actorData.IsCompanionInCamp then
        Osi.SetFlag(FLAG_COMPANION_IN_CAMP, actorData.Actor)
    end

    Osi.SetDetached(actorData.Actor, 0)
end

function SexActor_CreateProxyMarker(target)
    local proxyData = {}
    proxyData.MarkerX, proxyData.MarkerY, proxyData.MarkerZ = Osi.GetPosition(target)
    proxyData.Marker = Osi.CreateAtObject("06f96d65-0ee5-4ed5-a30a-92a3bfe3f708", target, 1, 0, "", 1)
    return proxyData
end

function SexActor_TerminateProxyMarker(proxyData)
    if proxyData then
        Osi.RequestDelete(proxyData.Marker)
    end
end

function SexActor_SubstituteProxy(actorData, proxyData)
    actorData.StartX, actorData.StartY, actorData.StartZ = Osi.GetPosition(actorData.Actor)

    -- Temporary teleport the original away a bit to give room for the proxy
    Osi.TeleportToPosition(actorData.Actor, actorData.StartX + 1.3, actorData.StartY, actorData.StartZ + 1.3, "", 0, 0, 0, 0, 1)

    local actorEntity = Ext.Entity.Get(actorData.Actor)

    actorData.Proxy = Osi.CreateAtObject(Osi.GetTemplate(actorData.Actor), proxyData.Marker, 1, 0, "", 1)

    -- Copy the actor's looks to the proxy (does not copy transforms)
    local lookTemplate = actorData.Actor
    -- If current GameObjectVisual template does not match the original actor's template, apply GameObjectVisual template to the proxy.
    -- This copies the horns of Wyll or the look of any Disguise Self spell applied to the actor. 
    local visTemplate = TryGetEntityValue(actorEntity, "GameObjectVisual", "RootTemplateId")
    local origTemplate = TryGetEntityValue(actorEntity, "OriginalTemplate", "OriginalTemplate")
    if visTemplate and origTemplate and visTemplate ~= origTemplate then
        lookTemplate = visTemplate
    end
    Osi.Transform(actorData.Proxy, lookTemplate, "296bcfb3-9dab-4a93-8ab1-f1c53c6674c9")

    Osi.SetDetached(actorData.Proxy, 1)
    BlockActorMovement(actorData.Proxy)

    local proxyEntity = Ext.Entity.Get(actorData.Proxy)

    -- Copy Voice component to the proxy because Osi.CreateAtObject does not do this and we want the proxy to play vocals
    TryCopyEntityComponent(actorEntity, proxyEntity, "Voice")

    -- Copy MaterialParameterOverride component if present.
    -- This fixes the white Shadowheart going back to her original black hair as a proxy.
    TryCopyEntityComponent(actorEntity, proxyEntity, "MaterialParameterOverride")

    -- Copy actor's equipment to the proxy (it will be equipped later in SexActor_FinalizeSetup)
    if not SexActor_IsStripped(actorData) then
        SexActor_CopyEquipmentToProxy(actorData)
    end
end

function SexActor_FinalizeSetup(actorData, proxyData)
    if actorData.Proxy then
        local actorEntity = Ext.Entity.Get(actorData.Actor)
        local proxyEntity = Ext.Entity.Get(actorData.Proxy)

        -- Support for the looks brought by Resculpt spell from "Appearance Edit Enhanced" mod.
        if TryCopyEntityComponent(actorEntity, proxyEntity, "AppearanceOverride") then
            if proxyEntity.GameObjectVisual.Type ~= 2 then
                proxyEntity.GameObjectVisual.Type = 2
                proxyEntity:Replicate("GameObjectVisual")
            end
        end

        if actorData.CopiedEquipment then
            SexActor_DressProxy(actorData)
        end

        Osi.TeleportToPosition(actorData.Actor, proxyData.MarkerX, proxyData.MarkerY, proxyData.MarkerZ, "", 0, 0, 0, 0, 1)
        Osi.SetVisible(actorData.Actor, 0)
    end
    BlockActorMovement(actorData.Actor)
end

function SexActor_StartAnimation(actorData, animProperties)
    SexActor_StopVocalTimer(actorData)

    local animActor = actorData.Proxy or actorData.Actor
    if animProperties["Loop"] == true then
        Osi.PlayLoopingAnimation(animActor, "", actorData.Animation, "", "", "", "", "")
    else
        Osi.PlayAnimation(animActor, actorData.Animation)
    end

    if animProperties["Sound"] == true and #actorData.SoundTable >= 1 then
        SexActor_StartVocalTimer(actorData, 600)
    end
end

function SexActor_StartVocalTimer(actorData, time)
    Osi.ObjectTimerLaunch(actorData.Actor, actorData.VocalTimerName, time)
end

function SexActor_StopVocalTimer(actorData)
    Osi.ObjectTimerCancel(actorData.Actor, actorData.VocalTimerName)
end

function SexActor_PlayVocal(actorData, minRepeatTime, maxRepeatTime)
    if #actorData.SoundTable >= 1 then
        local soundActor = actorData.Proxy or actorData.Actor
        Osi.PlaySound(soundActor, actorData.SoundTable[math.random(1, #actorData.SoundTable)])
        SexActor_StartVocalTimer(actorData, math.random(minRepeatTime, maxRepeatTime))
    end
end


-------------------------------------------------------------------------------
          -- STRIPPING --
-------------------------------------------------------------------------------

local STRIP_SLOTS = { "Boots", "Breast", "Cloak", "Gloves", "Helmet", "Underwear", "VanityBody", "VanityBoots", "MeleeMainHand", "MeleeOffHand", "RangedMainHand", "RangedOffHand" }

function SexActor_IsStripped(actorData)
    if actorData.GearSet then
        return true
    end
    return false
end

function SexActor_Strip(actorData)
    actorData.OldArmourSet = Osi.GetArmourSet(actorData.Actor)
    Osi.SetArmourSet(actorData.Actor, 1)
    
    local currentEquipment = {}
    for _, slotName in ipairs(STRIP_SLOTS) do
        local gearPiece = Osi.GetEquippedItem(actorData.Actor, slotName)
        if gearPiece then
            Osi.LockUnequip(gearPiece, 0)
            Osi.Unequip(actorData.Actor, gearPiece)
            currentEquipment[#currentEquipment+1] = gearPiece
        end
    end
    actorData.GearSet = currentEquipment
end

function SexActor_Redress(actorData)
    Osi.SetArmourSet(actorData.Actor, actorData.OldArmourSet)

    for _, item in ipairs(actorData.GearSet) do
        Osi.Equip(actorData.Actor, item)
    end
    actorData.GearSet = nil
end

function SexActor_CopyEquipmentToProxy(actorData)
    local currentArmourSet = Osi.GetArmourSet(actorData.Actor)

    local copySlots = {}
    if currentArmourSet == 0 then -- "Normal" armour set
        copySlots = { "Boots", "Breast", "Cloak", "Gloves", "Amulet", "MeleeMainHand", "MeleeOffHand", "RangedMainHand", "RangedOffHand", "MusicalInstrument" }

        -- If the actor has "Hide Helmet" option off in the inventory...
        if TryGetEntityValue(actorData.Actor, "ServerCharacter", "PlayerData", "HelmetOption") ~= 0 then
            copySlots[#copySlots + 1] = "Helmet"
        end
    elseif currentArmourSet == 1 then -- "Vanity" armour set
        copySlots = { "Underwear", "VanityBody", "VanityBoots" }
    end

    local copiedEquipment = {}
    for _, slotName in ipairs(copySlots) do
        local gearPiece = Osi.GetEquippedItem(actorData.Actor, slotName)
        if gearPiece then
            local gearTemplate = Osi.GetTemplate(gearPiece)
            Osi.TemplateAddTo(gearTemplate, actorData.Proxy, 1, 0)
            copiedEquipment[#copiedEquipment + 1] = { Template = gearTemplate, SourceItem = gearPiece } 
        end
    end

    if #copiedEquipment > 0 then
        actorData.CopiedEquipment = copiedEquipment
        actorData.CopiedArmourSet = currentArmourSet
    end
end

function SexActor_DressProxy(actorData)
    Osi.SetArmourSet(actorData.Proxy, actorData.CopiedArmourSet)

    for _, itemData in ipairs(actorData.CopiedEquipment) do
        local item = Osi.GetItemByTemplateInInventory(itemData.Template, actorData.Proxy)
        if item then
            -- Copy the dye applied to the source item
            TryCopyEntityComponent(itemData.SourceItem, item, "ItemDye")

            Osi.Equip(actorData.Proxy, item)
        else
            _P("SexActor_DressProxy: couldn't find an item of template " .. itemTemplate .. " in the proxy")
        end
    end

    actorData.CopiedArmourSet = nil
    actorData.CopiedEquipment = nil
end
