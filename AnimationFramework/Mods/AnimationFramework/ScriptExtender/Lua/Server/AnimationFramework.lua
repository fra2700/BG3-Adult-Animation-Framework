
-- Runs every time a save is loaded --
function OnSessionLoaded()
                                                 ---- Setup Functions ----
------------------------------------------------------------------------------------------------------------------------------------------

    Ext.Osiris.RegisterListener("LevelGameplayStarted", 2, "after", function(_, _)
        local party = Osi.DB_PartyMembers:Get(nil)
        for i = #party, 1, -1 do
            local character = party[i][1]
            if Osi.HasSpell(character, "StartSexContainer") == 0 then
                Osi.AddSpell(character, "StartSexContainer", 0, 0)
            end
        end
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
                _D(_C():GetAllComponents(target))
                break
            end
        end
    end)
    
    Ext.Osiris.RegisterListener("UsingSpellOnTarget", 6, "after", function(caster, _, spell, _, _, _)
        if spell == "BlockStripping" then
            Osi.RemoveStatus(caster, "BLOCK_STRIPPING")  
            Osi.ApplyStatus(caster, "BLOCK_STRIPPING", -1)  
        end
    end)

    Ext.Osiris.RegisterListener("UsingSpellOnTarget", 6, "after", function(caster, _, spell, _, _, _)
        if spell == "RemoveStrippingBlock" then
            Osi.RemoveStatus(caster, "BLOCK_STRIPPING")  
        end
    end)

------------------------------------------------------------------------------------------------------------------------------
-- SUBSCRIBE FUNCTION --
------------------------------------------------------------------------------------------------------------------------------

end

Ext.Events.SessionLoaded:Subscribe(OnSessionLoaded)

function SexSpellUsed(caster, target, animProperties)
    -- If it matches, Assign the corresponding property to a global variable (needs cleaning)
    if animProperties then
        --prevent target moving if party member
        Osi.DetachFromPartyGroup(caster)
        Osi.SetDetached(caster, 1)

        if animProperties["Type"] == "Solo" then
            StartSoloAnimation(caster, animProperties)
        elseif animProperties["Type"] == "Paired" then
            StartPairedAnimation(caster, target, animProperties)
        end
    end
end


function SubstituteProxy(actor, target)
    
    Osi.SetDetached(actor, 1)
    Actor = actor
    TargetActor = target
    ActorX, ActorY, ActorZ = Osi.GetPosition(actor)
    if target ~= nil then
        TargetX, TargetY, TargetZ = Osi.GetPosition(target)
    end
    if target then
        Osi.SetDetached(target, 1)
        local proxylocation = Osi.CreateAtObject("06f96d65-0ee5-4ed5-a30a-92a3bfe3f708", target, 0, 0, "", 1)
        Osi.TeleportToPosition(actor, ActorX+1.3, ActorY, ActorZ+1.3, "", 0,0,0,0,1)
        Prox = Osi.CreateAtObject(Osi.GetTemplate(actor), proxylocation, 0, 0, "", 1)
        Osi.Transform(Prox, actor, "296bcfb3-9dab-4a93-8ab1-f1c53c6674c9")
        Osi.SetDetached(Prox, 1)
    else
        local proxylocation = Osi.CreateAtObject("06f96d65-0ee5-4ed5-a30a-92a3bfe3f708", actor, 0, 0, "", 1)
        Osi.TeleportToPosition(actor, ActorX+1.3, ActorY, ActorZ+1.3, "", 0,0,0,0,1)
        Prox = Osi.CreateAtObject(Osi.GetTemplate(actor), proxylocation, 0, 0, "", 1)
        Osi.Transform(Prox, actor, "296bcfb3-9dab-4a93-8ab1-f1c53c6674c9")
        Osi.ObjectTimerLaunch(actor, "ProxySetupTimer", 0.01)
        Osi.SetDetached(Prox, 1)
    end
    Osi.ObjectTimerLaunch(actor, "ProxySetupTimer", 0.01)
    Osi.AddBoosts(Prox, "ActionResourceBlock(Movement)", "", "")

    --Osi.Transform(prox, actor, "8194cfb6-4199-46d2-9027-613c302352aa")

    Ext.Osiris.RegisterListener("ObjectTimerFinished", 2, "after", function(actor, timer)
        if timer == "ProxySetupTimer" then
            if TargetActor ~= nil then
                Osi.TeleportToPosition(actor, TargetX, TargetY, TargetZ, "", 0,0,0,0,1)
                TargetActor = nil
            else
                Osi.TeleportToPosition(actor, ActorX, ActorY, ActorZ, "", 0,0,0,0,1)
            end
            --Osi.SetDetached(Prox, 0)
            Osi.SetDetached(actor, 0)
        end
    end)
    return Prox
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
