if not AnimationSolos then
    AnimationSolos = {}
end

function StartSoloAnimation(actor, animProperties) 
    local soloData = {
        Actor = actor,
        ActorData = SexActor_Init(actor, true, "SexVocal", animProperties),
        AnimProperties = animProperties,
        AnimContainer = ""
    }

    local actorScaled = SexActor_PurgeBodyScaleStatuses(soloData.ActorData)

    UpdateSoloAnimationVars(soloData)

    AnimationSolos[actor] = soloData

    local setupDelay = 400
    if actorScaled and setupDelay < BODY_SCALE_DELAY then
        setupDelay = BODY_SCALE_DELAY -- Give some time for the actor's body to go back to its normal scale
    end

    if animProperties["Fade"] == true then
        Osi.ObjectTimerLaunch(actor, "SoloSexFade.Start", setupDelay - 200)
        Osi.ObjectTimerLaunch(actor, "SoloSexFade.End", setupDelay + 800)
    end

    Osi.ObjectTimerLaunch(actor, "SoloSexSetup", setupDelay)

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
            if soloData.ActorData.Strip then
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
            RemoveAnimationProp(soloData)
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
    RemoveAnimationProp(soloData)
    SexActor_StartAnimation(soloData.ActorData, soloData.AnimProperties)
    CreateAnimationProp(soloData)

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

function UpdateSoloAnimationVars(soloData)
    if ActorHasPenis(soloData.Actor) then
        soloData.AnimContainer = "MaleMasturbationContainer"
        soloData.ActorData.Animation = soloData.AnimProperties["TopAnimationID"]
    else
        soloData.AnimContainer = "FemaleMasturbationContainer"
        soloData.ActorData.Animation = soloData.AnimProperties["BottomAnimationID"]
    end
    soloData.ActorData.SoundTable = PLAYER_SEX_SOUNDS
end

function CreateAnimationProp(soloData)
    local prop = soloData.AnimProperties["AnimObject"]
    if prop then
        soloData.AnimationProp = Osi.CreateAtObject(prop, soloData.ActorData.Proxy, 1, 0, "", 1)
    end
end

function RemoveAnimationProp(soloData)
    if soloData.AnimationProp then
        Osi.RequestDelete(soloData.AnimationProp)
        soloData.AnimationProp = nil
    end
end