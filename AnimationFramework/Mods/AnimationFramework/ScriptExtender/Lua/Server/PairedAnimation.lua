if not AnimationPairs then
    AnimationPairs = {}
end

function StartPairedAnimation(caster, target, animProperties)

    local pairData = {
        Caster = caster,
        CasterData = SexActor_Init(caster, "SexVocalCaster", animProperties),
        Target = target,
        TargetData = SexActor_Init(target, "SexVocalTarget", animProperties),
        AnimProperties = animProperties,
        SwitchPlaces = false
    }

    UpdatePairedAnimationVars(pairData)

    AnimationPairs[#AnimationPairs + 1] = pairData

    --check if caster has 'block stripping' status & strip caster if not
    local stripDelay = 0
    if pairData.CasterData.Strip or pairData.TargetData.Strip then
        stripDelay = 1600
        if pairData.CasterData.Strip then
            Osi.ApplyStatus(caster, "DARK_JUSTICIAR_VFX", 1)
        end
        if pairData.TargetData.Strip then
            Osi.ApplyStatus(target, "DARK_JUSTICIAR_VFX", 1)
        end
        Osi.ObjectTimerLaunch(caster, "PairedSexStrip", 600)
    end
    
    if pairData.AnimProperties["Fade"] == true then
        Osi.ObjectTimerLaunch(caster, "PairedSexFade.Start", 200 + stripDelay)
        Osi.ObjectTimerLaunch(caster, "PairedSexFade.End", 1200 + stripDelay)
    end

    Osi.ObjectTimerLaunch(caster, "PairedSexSetup", 400 + stripDelay)

    TryAddSpell(caster, pairData.AnimContainer)
end

local function TryStripPairedActor(actorData)
    if actorData.Strip then
        Osi.ApplyStatus(actorData.Actor, "PASSIVE_WILDMAGIC_MAGICRETRIBUTION_DEFENDER", 1)
        SexActor_Strip(actorData)
    end
end

function PairedAnimationListeners()

    Ext.Osiris.RegisterListener("ObjectTimerFinished", 2, "after", function(actor, timer)

        ------------------------------------
                  -- FADE TIMERS --
        ------------------------------------

        if timer == "PairedSexFade.Start" then
            Osi.ScreenFadeTo(actor, 0.1, 0.1, "AnimFade")
            return
        end

        if timer == "PairedSexFade.End" then
            Osi.ClearScreenFade(actor, 0.1, "AnimFade", 0)
            return
        end
        
        ------------------------------------
               -- ANIMATION TIMERS --
        ------------------------------------

        local pairIndex = FindPairIndexByActor(actor)
        if pairIndex < 1 then
            return
        end
        local pairData = AnimationPairs[pairIndex]

        --Stripping fixed to work per-actor
        if timer == "PairedSexStrip" then
            TryStripPairedActor(pairData.CasterData)
            TryStripPairedActor(pairData.TargetData)
            return
        end


        if timer == "PairedSexSetup" then
            pairData.ProxyData = SexActor_CreateProxyMarker(pairData.Target)
            SexActor_SubstituteProxy(pairData.CasterData, pairData.ProxyData)
            -- Always create a proxy for targets if they are PCs or companions or some temporary party members. 
            -- It fixes the moan sounds for companions and prevents animation reset on these characters' selection in the party.
            if ActorIsPlayable(pairData.Target) or Osi.IsPartyMember(pairData.Target, 1) == 1 then
                -- A workaround for the following bug in BG3 SE "BG3Ext v14 built on Feb 16 2024 23:26:35":
                -- if 2 proxies are created w/o a delay, copying Voice component to the 2nd proxy results in crashes or Lua errors in the console.
                -- SexActor_SubstituteProxy(pairData.TargetData, pairData.ProxyData)
                Osi.ObjectTimerLaunch(pairData.Caster, "PairedSexCreateTargetProxy", 100)
            end
            Osi.ObjectTimerLaunch(pairData.Caster, "PairedSexAnimStart", 400)
            return
        end

        if timer == "PairedSexCreateTargetProxy" then
            SexActor_SubstituteProxy(pairData.TargetData, pairData.ProxyData)
            return
        end

        if timer == "PairedSexAnimStart" then
            SexActor_FinalizeSetup(pairData.CasterData, pairData.ProxyData)
            SexActor_FinalizeSetup(pairData.TargetData, pairData.ProxyData)
            PlayPairedAnimation(pairData)
            Osi.SetDetached(pairData.Caster, 0)
            return
        end
        
        if timer == "PairedAnimTimeout" then
            StopPairedAnimation(pairData)
            return
        end

        if timer == "FinishSex" then
            SexActor_Terminate(pairData.CasterData)
            SexActor_Terminate(pairData.TargetData)
            SexActor_TerminateProxyMarker(pairData.ProxyData)

            table.remove(AnimationPairs, pairIndex)
            return
        end

        ------------------------------------
               -- SOUND TIMERS --
        ------------------------------------

        if timer == "SexVocalCaster" then
            SexActor_PlayVocal(pairData.CasterData, 1500, 2500)
            return
        end

        if timer == "SexVocalTarget" then
            SexActor_PlayVocal(pairData.TargetData, 1500, 2500)
            return
        end
        
    end)

    Ext.Osiris.RegisterListener("UsingSpell", 5, "after", function(caster, spell, _, _, _)
        local pairIndex = FindPairIndexByActor(caster)
        if pairIndex < 1 then
            return
        end
        local pairData = AnimationPairs[pairIndex]

        if spell == "zzzEndSex" then
            StopPairedAnimation(pairData)
        elseif spell == "zzSwitchPlacesLesbian" or spell == "zzSwitchPlacesStraight" then
            pairData.SwitchPlaces = not pairData.SwitchPlaces
            UpdatePairedAnimationVars(pairData)
            PlayPairedAnimation(pairData)
        else
            for _, newAnim in ipairs(SexAnimations) do
                if newAnim.AnimName == spell then
                    pairData.AnimProperties = newAnim
                    UpdatePairedAnimationVars(pairData)
                    PlayPairedAnimation(pairData)
                    break
                end
            end
        end
    end)
    
end

Ext.Events.SessionLoaded:Subscribe(PairedAnimationListeners)

function PlayPairedAnimation(pairData)
    SexActor_StartAnimation(pairData.CasterData, pairData.AnimProperties)
    SexActor_StartAnimation(pairData.TargetData, pairData.AnimProperties)

    -- Timeout timer
    local animTimeout = pairData.AnimProperties["AnimLength"] * 1000
    if animTimeout > 0 then
        Osi.ObjectTimerLaunch(pairData.Caster, "PairedAnimTimeout", animTimeout)
    else
        Osi.ObjectTimerCancel(pairData.Caster, "PairedAnimTimeout")
    end
end

function StopPairedAnimation(pairData)
    Osi.ObjectTimerCancel(pairData.Caster, "PairedAnimTimeout")
    Osi.ObjectTimerCancel(pairData.Caster, "PairedSexFade.Start")
    Osi.ObjectTimerCancel(pairData.Caster, "PairedSexFade.End")
    Osi.ObjectTimerCancel(pairData.Target, "PairedSexFade.Start")
    Osi.ObjectTimerCancel(pairData.Target, "PairedSexFade.End")

    Osi.ScreenFadeTo(pairData.Caster, 0.1, 0.1, "AnimFade")
    --Osi.ScreenFadeTo(pairData.Target, 0.1, 0.1, "AnimFade")

    Osi.ObjectTimerLaunch(pairData.Caster, "FinishSex", 200)
    Osi.ObjectTimerLaunch(pairData.Caster, "PairedSexFade.End", 2500)
    --Osi.ObjectTimerLaunch(pairData.Target, "PairedSexFade.End", 2500)
    SexActor_StopVocalTimer(pairData.CasterData)
    SexActor_StopVocalTimer(pairData.TargetData)
end

function UpdatePairedAnimationVars(pairData)
    pairData.AnimContainer = "StraightAnimationsContainer"

    local casterAnimName  = "TopAnimationID"
    local casterSoundName = "SoundTop"
    local targetAnimName  = "BottomAnimationID"
    local targetSoundName = "SoundBottom"

    local casterHasPenis = ActorHasPenis(pairData.Caster)
    local targetHasPenis = ActorHasPenis(pairData.Target)

    if casterHasPenis == false and targetHasPenis == false then
        pairData.AnimContainer = "LesbianAnimationsContainer"
    end

    if (casterHasPenis == targetHasPenis and pairData.SwitchPlaces) or (casterHasPenis == false and targetHasPenis) then
        casterAnimName, targetAnimName = targetAnimName, casterAnimName
        casterSoundName, targetSoundName = targetSoundName, casterSoundName
    end
    
    pairData.CasterData.Animation  = pairData.AnimProperties[casterAnimName]
    pairData.CasterData.SoundTable = pairData.AnimProperties[casterSoundName]
    pairData.TargetData.Animation  = pairData.AnimProperties[targetAnimName]
    pairData.TargetData.SoundTable = pairData.AnimProperties[targetSoundName]
end

function FindPairIndexByActor(actor)
    for i = 1, #AnimationPairs do
        if AnimationPairs[i].Caster == actor or AnimationPairs[i].Target == actor then
            return i
        end
    end    
    return 0
end
