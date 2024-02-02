if not AnimationPairs then
    AnimationPairs = {}
end

function StartPairedAnimation(caster, target, animProperties)

    local pairData = {
        Caster = caster,
        CasterData = SexActor_Init(caster, "SexVocalCaster"),
        Target = target,
        TargetData = SexActor_Init(target, "SexVocalTarget"),
        AnimProperties = animProperties,
        SwitchPlaces = false
    }

    UpdatePairedAnimationVars(pairData)

    AnimationPairs[#AnimationPairs + 1] = pairData

    local stripDelay = 0
    if pairData.AnimProperties["Strip"] == true and Osi.HasActiveStatus(caster, "BLOCK_STRIPPING") ~= 1 then
        stripDelay = 1600
        Osi.ObjectTimerLaunch(caster, "Strip", 600)
        Osi.ApplyStatus(caster, "DARK_JUSTICIAR_VFX", 1)
        Osi.ObjectTimerLaunch(target, "Strip", 600)
        Osi.ApplyStatus(target, "DARK_JUSTICIAR_VFX", 1)
    end

    if pairData.AnimProperties["Fade"] == true then
        Osi.ObjectTimerLaunch(caster, "PairedSexFade.Start", 200 + stripDelay)
        Osi.ObjectTimerLaunch(caster, "PairedSexFade.End", 1200 + stripDelay)
    end

    Osi.ObjectTimerLaunch(caster, "PairedSexSetup", 400 + stripDelay)

    TryAddSpell(caster, pairData.AnimContainer)
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

        if timer == "PairedSexSetup" then
            SexActor_SubstituteProxy(pairData.CasterData, pairData.Target)
            Osi.ObjectTimerLaunch(pairData.Caster, "PairedSexAnimStart", 400)
            return
        end

        if timer == "PairedSexAnimStart" then
            SexActor_FinalizeSetup(pairData.CasterData)
            SexActor_FinalizeSetup(pairData.TargetData)
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

        if spell == "EndSex" then
            StopPairedAnimation(pairData)
        elseif spell == "SwitchPlacesLesbian" or spell == "SwitchPlacesStraight" then
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

    local casterIsMale = Osi.IsTagged(pairData.Caster, "d27831df-2891-42e4-b615-ae555404918b") -- Has GENITAL_PENIS tag
    local targetIsMale = 1
    if Osi.HasAppliedStatusOfType(pairData.Target, "POLYMORPHED") == 1 then -- If target has POLYMORPHED status (Disguise Self, etc.)...
        if Osi.GetGender(pairData.Target, 1) == "Female" then
            targetIsMale = 0
        end
    elseif Osi.IsTagged(pairData.Target, "25bf5042-5bf6-4360-8df8-ab107ccb0d37") == 0 then -- If target has no PLAYABLE tag (not a PC or a companion)...
        if Osi.IsTagged(pairData.Target, "3806477c-65a7-4100-9f92-be4c12c4fa4f") == 1 then -- If target has FEMALE tag...
            targetIsMale = 0
        end
    else -- Target is PLAYABLE
        targetIsMale = Osi.IsTagged(pairData.Target, "d27831df-2891-42e4-b615-ae555404918b") -- Has GENITAL_PENIS tag
    end

    if casterIsMale == 0 and targetIsMale == 0 then
        pairData.AnimContainer = "LesbianAnimationsContainer"
    end

    if (casterIsMale == targetIsMale and pairData.SwitchPlaces) or (casterIsMale == 0 and targetIsMale == 1) then
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
