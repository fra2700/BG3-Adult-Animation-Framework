if not AnimationSolos then
    AnimationSolos = {}
end

function StartSoloAnimation(actor, animProperties) 

    local soloData = {
        Actor = actor,
        ActorData = SexActor_Init(actor, "SexVocal"),
        AnimProperties = animProperties,
        AnimContainer = ""
    }



    UpdateSoloAnimationVars(soloData)

    AnimationSolos[actor] = soloData

    if animProperties["Fade"] == true then
        Osi.ObjectTimerLaunch(actor, "SoloSexFade.Start", 200)
        Osi.ObjectTimerLaunch(actor, "SoloSexFade.End", 1200)
    end

    Osi.ObjectTimerLaunch(actor, "SoloSexSetup", 400)

    TryAddSpell(actor, soloData.AnimContainer)
end

function SoloAnimationListeners()

    Ext.Osiris.RegisterListener("ObjectTimerFinished", 2, "after", function(actor, timer)

        ------------------------------------
                  -- FADE TIMERS --
        ------------------------------------

        if timer == "SoloSexFade.Start" then
            Osi.ScreenFadeTo(actor, 0.1, 0.1, "AnimFade")
            return
        end

        if timer == "SoloSexFade.End" then
            Osi.ClearScreenFade(actor, 0.1, "AnimFade", 0)
            return
        end

        ------------------------------------
               -- ANIMATION TIMERS --
        ------------------------------------

        local soloData = AnimationSolos[actor]
        if not soloData then
            return
        end

        if timer == "SoloSexSetup" then
            if soloData.AnimProperties["Strip"] == true and Osi.HasActiveStatus(actor, "BLOCK_STRIPPING") ~= 1 then
                SexActor_Strip(soloData.ActorData)
            end
            soloData.ProxyData = SexActor_CreateProxyMarker(soloData.Actor)
            SexActor_SubstituteProxy(soloData.ActorData, soloData.ProxyData)
            Osi.ObjectTimerLaunch(actor, "SoloAnimStart", 200)
            return
        end

        if timer == "SoloAnimStart" then
            SexActor_FinalizeSetup(soloData.ActorData, soloData.ProxyData)
            PlaySoloAnimation(soloData)
            Osi.SetDetached(soloData.Actor, 0)
            return
        end
        
        if timer == "SoloAnimTimeout" then
            StopSoloAnimation(soloData)
            return
        end

        if timer == "FinishMasturbating" then
            SexActor_Terminate(soloData.ActorData)
            SexActor_TerminateProxyMarker(soloData.ProxyData)

            AnimationSolos[actor] = nil
            return
        end

        ------------------------------------
               -- SOUND TIMERS --
        ------------------------------------

        if timer == "SexVocal" then
            SexActor_PlayVocal(soloData.ActorData, 1500, 2500)
            return
        end
    end)

    ------------------------------------
            -- SPELL LISTENERS --
    ------------------------------------

    Ext.Osiris.RegisterListener("UsingSpell", 5, "after", function(caster, spell, _, _, _)
        local soloData = AnimationSolos[caster]
        if not soloData then
            return
        end

        if spell == "zzzStopMasturbating" then
            StopSoloAnimation(soloData)
            print("Stop")
        else
            for _, newAnim in ipairs(SexAnimations) do
                if newAnim.AnimName == spell then
                    soloData.AnimProperties = newAnim
                    UpdateSoloAnimationVars(soloData)   
                    PlaySoloAnimation(soloData)
                    break
                end
            end
        end
    end)
end

Ext.Events.SessionLoaded:Subscribe(SoloAnimationListeners)

function PlaySoloAnimation(soloData)
    SexActor_StartAnimation(soloData.ActorData, soloData.AnimProperties)

    -- Timeout timer
    local animTimeout = soloData.AnimProperties["AnimLength"] * 1000
    if animTimeout > 0 then
        Osi.ObjectTimerLaunch(soloData.Actor, "SoloAnimTimeout", animTimeout)
    else
        Osi.ObjectTimerCancel(soloData.Actor, "SoloAnimTimeout")
    end
end

function StopSoloAnimation(soloData)
    Osi.ObjectTimerCancel(soloData.Actor, "SoloAnimTimeout")
    Osi.ObjectTimerCancel(soloData.Actor, "SoloSexFade.Start")
    Osi.ObjectTimerCancel(soloData.Actor, "SoloSexFade.End")

    Osi.ScreenFadeTo(soloData.Actor, 0.1, 0.1, "AnimFade")

    Osi.ObjectTimerLaunch(soloData.Actor, "FinishMasturbating", 200)
    Osi.ObjectTimerLaunch(soloData.Actor, "SoloSexFade.End", 2500)
    SexActor_StopVocalTimer(soloData.ActorData)
end

local PLAYER_SEX_SOUNDS = {
    "BreathLongExhaleOpen_PlayerCharacter_Cine",
    "BreathLongInhaleOpen_PlayerCharacter_Cine",
    "BreathShortInhaleOpen_PlayerCharacter_Cine",
    "LoveMoanClosed_PlayerCharacter_Cine",
    "LoveMoanOpen_PlayerCharacter_Cine"
}

local function ActorHasPenis(actor)
    -- If actor is polymorphed (e.g., Disguise Self spell)
    if Osi.HasAppliedStatusOfType(actor, "POLYMORPHED") == 1 then
        -- As of hot fix #17, "Femme Githyanki" disguise has a dick.
        local actorEntity = Ext.Entity.Get(actor)
        if actorEntity.GameObjectVisual and actorEntity.GameObjectVisual.RootTemplateId and actorEntity.GameObjectVisual.RootTemplateId == "7bb034aa-d355-4973-9b61-4d83cf29d510" then
            return true
        end

        return Osi.GetGender(actor, 1) ~= "Female"
    end

    -- If actor is not playable
    if not ActorIsPlayable(actor) then
        return Osi.IsTagged(actor, "FEMALE_3806477c-65a7-4100-9f92-be4c12c4fa4f") ~= 1
    end

    -- Playable actor (PC or companion)
    return Osi.IsTagged(actor, "GENITAL_PENIS_d27831df-2891-42e4-b615-ae555404918b") == 1
end

function UpdateSoloAnimationVars(soloData)
    soloData.AnimContainer = "MaleMasturbationContainer"
    soloData.ActorData.Animation  = soloData.AnimProperties["TopAnimationID"]
    soloData.ActorData.SoundTable = PLAYER_SEX_SOUNDS

    local casterHasPenis = ActorHasPenis(soloData.Actor)

    if casterHasPenis == false then
        soloData.AnimContainer = "FemaleMasturbationContainer"
        soloData.ActorData.Animation  = soloData.AnimProperties["BottomAnimationID"]
    end
end