
-- Runs every time a save is loaded --
function OnSessionLoaded()
                                                 ---- Setup Functions ----
------------------------------------------------------------------------------------------------------------------------------------------

    Ext.Osiris.RegisterListener("LevelGameplayStarted", 2, "after", function(_, _)
        local party = Osi.DB_PartyMembers:Get(nil)
        for i = #party, 1, -1 do
            AddMainSexSpells(party[i][1])
        end
    end)

    Ext.Osiris.RegisterListener("CharacterJoinedParty", 1, "after", function(actor)
        AddMainSexSpells(actor)
    end)

 ------------------------------------------------------------------------------------------------------------------------------------------
                                                ---- Animation Functions ----
 ------------------------------------------------------------------------------------------------------------------------------------------

    -- Typical Spell Use --
    Ext.Osiris.RegisterListener("UsingSpellOnTarget", 6, "after", function(caster, target, spell, _, _, _)
        -- Checks to see if the name of the spell used matches any of the Spells in the AnimationPacks
        for _, table in ipairs(StartSexSpells) do
            if table.AnimName == spell then
                SexSpellUsed(caster, target, table)
                break
            end
        end
    end)
    
    Ext.Osiris.RegisterListener("UsingSpellOnTarget", 6, "after", function(_, target, spell, _, _, _)
        if spell == "BlockStripping" then
            Osi.RemoveStatus(target, "BLOCK_STRIPPING")  
            Osi.ApplyStatus(target, "BLOCK_STRIPPING", -1)  
        elseif spell == "RemoveStrippingBlock" then
            Osi.RemoveStatus(target, "BLOCK_STRIPPING")  
        end
    end)

------------------------------------------------------------------------------------------------------------------------------
-- SUBSCRIBE FUNCTION --
------------------------------------------------------------------------------------------------------------------------------

end

Ext.Events.SessionLoaded:Subscribe(OnSessionLoaded)

function SexSpellUsed(caster, target, animProperties)
    if animProperties then
        if animProperties["Type"] == "Solo" then
            StartSoloAnimation(caster, animProperties)
        elseif animProperties["Type"] == "Paired" then
            StartPairedAnimation(caster, target, animProperties)
        end
    end
end

function TryAddSpell(actor, spellName)
    if Osi.HasSpell(actor, spellName) == 0 then
        Osi.AddSpell(actor, spellName)
        return true
    end
    return false
end

function TryRemoveSpell(actor, spellName)
    if Osi.HasSpell(actor, spellName) == 1 then
        Osi.RemoveSpell(actor, spellName)
        return true
    end
    return false
end

-- Returns true if actor is playable (a PC or a companion)
function ActorIsPlayable(actor)
    return Osi.IsTagged(actor, "PLAYABLE_25bf5042-5bf6-4360-8df8-ab107ccb0d37") == 1
end

function ActorHasPenis(actor)
    -- If actor is polymorphed (e.g., Disguise Self spell)
    if Osi.HasAppliedStatusOfType(actor, "POLYMORPHED") == 1 then
        -- As of hot fix #17, "Femme Githyanki" disguise has a dick.
        local actorEntity = Ext.Entity.Get(actor)
        if actorEntity.GameObjectVisual and actorEntity.GameObjectVisual.RootTemplateId and actorEntity.GameObjectVisual.RootTemplateId == "7bb034aa-d355-4973-9b61-4d83cf29d510" then
            return true
        end

        return Osi.GetGender(actor, 1) ~= "Female"
    end

    -- Actors seem to have GENITAL_PENIS/GENITAL_VULVA only if they are player chars or companions who can actually join the party.
    -- NPCs never get the tags. "Future" companions don't have them too.
    -- E.g., Halsin in Act 1 has no GENITAL_PENIS, he gets it only when his story allows him to join the active party in Act 2.
    if ActorIsPlayable(actor) then
        if Osi.IsTagged(actor, "GENITAL_PENIS_d27831df-2891-42e4-b615-ae555404918b") == 1 then
            return true
        end

        if Osi.IsTagged(actor, "GENITAL_VULVA_a0738fdf-ca0c-446f-a11d-6211ecac3291") == 1 then
            return false
        end
    end

    -- Fallback for NPCs, "future" companions, etc.
    return Osi.IsTagged(actor, "FEMALE_3806477c-65a7-4100-9f92-be4c12c4fa4f") ~= 1
end

function AddMainSexSpells(actor)
    -- Add "Start Sex" and "Sex Options" spells only if actor is PLAYABLE or HUMANOID or FIEND
    if (ActorIsPlayable(actor)
        or Osi.IsTagged(actor, "HUMANOID_7fbed0d4-cabc-4a9d-804e-12ca6088a0a8") == 1 
        or Osi.IsTagged(actor, "FIEND_44be2f5b-f27e-4665-86f1-49c5bfac54ab") == 1)
    then
        TryAddSpell(actor, "StartSexContainer")
        TryAddSpell(actor, "SexOptions")
    end
end

function CopySimpleEntityComponent(srcEntity, dstEntity, componentName)
    local srcComponent = srcEntity[componentName]
    if not srcComponent then
        _P("CopySimpleEntityComponent: srcEntity has no '" .. componentName .. "' component.")
        return
    end

    local dstComponent = dstEntity[componentName]
    if not dstComponent then
        dstEntity:CreateComponent(componentName)
        dstComponent = dstEntity[componentName]
    end

    for k, v in pairs(srcComponent) do        
        dstComponent[k] = v
    end

    if componentName ~= "ServerIconList" and componentName ~= "ServerDisplayNameList" and componentName ~= "ServerItem" then
        dstEntity:Replicate(componentName)
    end
end
