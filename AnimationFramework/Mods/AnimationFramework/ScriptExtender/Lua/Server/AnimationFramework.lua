
-- Runs every time a save is loaded --
function OnSessionLoaded()
                                                 ---- Setup Functions ----
------------------------------------------------------------------------------------------------------------------------------------------

    Ext.Osiris.RegisterListener("LevelGameplayStarted", 2, "after", function(_, _)
        local party = Osi.DB_PartyMembers:Get(nil)
        for i = #party, 1, -1 do
            TryAddStartSexSpell(party[i][1])
        end
    end)

    Ext.Osiris.RegisterListener("CharacterJoinedParty", 1, "after", function(actor)
        TryAddStartSexSpell(actor)
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

function TryAddStartSexSpell(actor)
    -- Add "Start Sex" spell only if actor is PLAYABLE (PC or proper companion) or HUMANOID or FIEND
    if (Osi.IsTagged(actor, "PLAYABLE_25bf5042-5bf6-4360-8df8-ab107ccb0d37") == 1 
        or Osi.IsTagged(actor, "HUMANOID_7fbed0d4-cabc-4a9d-804e-12ca6088a0a8") == 1 
        or Osi.IsTagged(actor, "FIEND_44be2f5b-f27e-4665-86f1-49c5bfac54ab") == 1)
    then
        TryAddSpell(actor, "StartSexContainer")
    end
end


-------------------------------------------------------------------------------
          -- SEX ACTOR MANAGEMENT --
-------------------------------------------------------------------------------

local FLAG_COMPANION_IN_CAMP = "161b7223-039d-4ebe-986f-1dcd9a66733f"

local function RemoveSexPositionSpells(actor)
    TryRemoveSpell(actor, "StraightAnimationsContainer")
    TryRemoveSpell(actor, "LesbianAnimationsContainer")
    TryRemoveSpell(actor, "MasturbationAnimationsContainer")
end

local function BlockActorMovement(actor)
    Osi.AddBoosts(actor, "ActionResourceBlock(Movement)", "", "")
end

local ORGASM_SOUNDS = {
    "Player_Races_Voice_Combat_Weak",
    "Player_Races_Voice_Combat_Weak_Cinematics",
    "Player_Races_Voice_Combat_Recover",
    "Player_Races_Voice_Combat_Recover_Chance",
    "Player_Races_Voice_Combat_Recover_Cinematics",
    "Player_Races_Voice_Gen_Recover",
    "Player_Races_Voice_Gen_Recover_Cinematics"
}


function SexActor_Init(actor, vocalTimerName)
    local actorData = {
        Actor = actor,
        Proxy = nil,
        Animation = "",
        SoundTable = {},
        VocalTimerName = vocalTimerName,
        IsCompanionInCamp = false
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

    Redress(actorData.Actor)

    RemoveSexPositionSpells(actorData.Actor)
    if Osi.IsPartyMember(actorData.Actor, 0) == 1 then
        TryAddStartSexSpell(actorData.Actor)
    end

    if actorData.IsCompanionInCamp then
        Osi.SetFlag(FLAG_COMPANION_IN_CAMP, actorData.Actor)
    end

    Osi.SetDetached(actorData.Actor, 0)
end

function SexActor_SubstituteProxy(actorData, optionalTarget)
    actorData.StartX, actorData.StartY, actorData.StartZ = Osi.GetPosition(actorData.Actor)

    local proxyDestination
    if optionalTarget ~= nil then
        proxyDestination = optionalTarget
        actorData.AnimPosX, actorData.AnimPosY, actorData.AnimPosZ = Osi.GetPosition(optionalTarget)
    else
        proxyDestination = actorData.Actor
        actorData.AnimPosX, actorData.AnimPosY, actorData.AnimPosZ = actorData.StartX, actorData.StartY, actorData.StartZ
    end

    local proxyMarker = Osi.CreateAtObject("06f96d65-0ee5-4ed5-a30a-92a3bfe3f708", proxyDestination, 1, 0, "", 1)
    -- Temporary teleport the original away a bit to give room for the proxy
    Osi.TeleportToPosition(actorData.Actor, actorData.StartX + 1.3, actorData.StartY, actorData.StartZ + 1.3, "", 0, 0, 0, 0, 1)
    actorData.Proxy = Osi.CreateAtObject(Osi.GetTemplate(actorData.Actor), proxyMarker, 1, 0, "", 1)
    -- Copy the actor's looks to the proxy (does not copy transforms)
    Osi.Transform(actorData.Proxy, actorData.Actor, "296bcfb3-9dab-4a93-8ab1-f1c53c6674c9")
    Osi.SetDetached(actorData.Proxy, 1)
    BlockActorMovement(actorData.Proxy)

    local actorEntity = Ext.Entity.Get(actorData.Actor)
    local proxyEntity = Ext.Entity.Get(actorData.Proxy)

    -- Copy Voice.Voice to the proxy because Osi.CreateAtObject does not do this and we want the proxy to play vocals
    if actorEntity.Voice then
        if not proxyEntity.Voice then
            proxyEntity:CreateComponent("Voice")
        end
        proxyEntity.Voice.Voice = actorEntity.Voice.Voice
    end
end

function SexActor_FinalizeSetup(actorData)
    if actorData.Proxy then
        Osi.TeleportToPosition(actorData.Actor, actorData.AnimPosX, actorData.AnimPosY, actorData.AnimPosZ, "", 0, 0, 0, 0, 1)
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
