
-- Runs every time a save is loaded --
function OnSessionLoaded()
                                                 ---- Setup Functions ----
------------------------------------------------------------------------------------------------------------------------------------------

    Ext.Osiris.RegisterListener("LevelGameplayStarted", 2, "after", function(_, _)
        local party = Osi.DB_PartyMembers:Get(nil)
        for i = #party, 1, -1 do
            AddMainSexSpell(party[i][1])
            AddSexOptions(party[i][1])
        end
    end)

    Ext.Osiris.RegisterListener("CharacterJoinedParty", 1, "after", function(actor)
        AddMainSexSpell(actor)
        AddSexOptions(party[i][1])
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
        end
    end)

    Ext.Osiris.RegisterListener("UsingSpellOnTarget", 6, "after", function(_, target, spell, _, _, _)
        if spell == "RemoveStrippingBlock" then
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

function AddMainSexSpell(actor)
    -- Add "Start Sex" spell only if actor is PLAYABLE or HUMANOID or FIEND
    if (ActorIsPlayable(actor)
        or Osi.IsTagged(actor, "HUMANOID_7fbed0d4-cabc-4a9d-804e-12ca6088a0a8") == 1 
        or Osi.IsTagged(actor, "FIEND_44be2f5b-f27e-4665-86f1-49c5bfac54ab") == 1)
    then
        TryAddSpell(actor, "StartSexContainer")
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

function AddSexOptions(actor)
    -- Add "Start Sex" spell only if actor is PLAYABLE or HUMANOID or FIEND
    if (ActorIsPlayable(actor)
        or Osi.IsTagged(actor, "HUMANOID_7fbed0d4-cabc-4a9d-804e-12ca6088a0a8") == 1 
        or Osi.IsTagged(actor, "FIEND_44be2f5b-f27e-4665-86f1-49c5bfac54ab") == 1)
    then
        TryAddSpell(actor, "SexOptions")
    end
end