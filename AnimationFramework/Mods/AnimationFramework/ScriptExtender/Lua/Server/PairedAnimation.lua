if not AnimationPairs then
    AnimationPairs = {}
end

function StartPairedAnimation(caster, target, animProperties)

    local casterX, casterY, casterZ = Osi.GetPosition(caster)
    local pairData = {
        Caster = caster,
        Target = target,
        CasterProxy = "",
        AnimProperties = animProperties,
        StartAnimLength = animProperties["AnimLength"] * 1000,
        CasterStartX = casterX,
        CasterStartY = casterY,
        CasterStartZ = casterZ,
        RestoreTargetSexSpell = false,
        SwitchPlaces = false
    }

    UpdateAnimationVars(pairData)

    AnimationPairs[#AnimationPairs + 1] = pairData

    Osi.SetDetached(target, 1)
    
    local stripDelay = 0
    if pairData.AnimProperties["Strip"] == true and Osi.HasActiveStatus(caster, "BLOCK_STRIPPING") ~= 1 then
        stripDelay = 1600
        Osi.ObjectTimerLaunch(caster, "Strip", 600)
        Osi.ApplyStatus(caster, "DARK_JUSTICIAR_VFX", 1)
        Osi.ObjectTimerLaunch(target, "Strip", 600)
        Osi.ApplyStatus(target, "DARK_JUSTICIAR_VFX", 1)
    end

    if pairData.AnimProperties["Fade"] == true then
        Osi.ObjectTimerLaunch(caster, "BeginningFade.Start", 200 + stripDelay)
        Osi.ObjectTimerLaunch(caster, "BeginningFade.End", 1200 + stripDelay)
        Osi.ObjectTimerLaunch(caster, "FinishFade.Start", pairData.StartAnimLength - 400 + stripDelay)
        Osi.ObjectTimerLaunch(caster, "FinishFade.End", pairData.StartAnimLength + 400 + 650 + stripDelay)
    end

    Osi.ObjectTimerLaunch(caster, "CasterShowProx", 400 + stripDelay)
    Osi.ObjectTimerLaunch(caster, "PairedSetupCaster", 400 + stripDelay)
    Osi.ObjectTimerLaunch(caster, "SexVocalCaster", 600 + stripDelay)

    Osi.ObjectTimerLaunch(target, "PairedSetupTarget", 400 + stripDelay)
    Osi.ObjectTimerLaunch(target, "SexVocalTarget", 600 + stripDelay)

    TryRemoveSpell(caster, "StartSexContainer")
    pairData.RestoreTargetSexSpell = TryRemoveSpell(target, "StartSexContainer")

    TryAddSpell(caster, pairData.AnimContainer)
end

function PairedAnimationListeners()

    Ext.Osiris.RegisterListener("ObjectTimerFinished", 2, "after", function(actor, timer)

        ------------------------------------
                  -- FADE TIMERS --
        ------------------------------------

        if timer == "BeginningFade.Start" then
            Osi.ScreenFadeTo(actor, 0.1, 0.1, "AnimFade")
            return
        end

        if timer == "BeginningFade.End" then
            Osi.ClearScreenFade(actor, 0.1, "AnimFade", 0)
            return
        end

        if timer == "FinishFade.Start" then
            Osi.ScreenFadeTo(actor, 0.1, 0.1, "AnimFade")
            return
        end

        if timer == "FinishFade.End" then
            Osi.ClearScreenFade(actor, 0.1, "AnimFade", 0)
            return
        end
        
        ------------------------------------
               -- ANIMATION START TIMERS --
        ------------------------------------

        local pairIndex = FindPairIndexByActor(actor)
        if pairIndex < 1 then
            return
        end
        local pairData = AnimationPairs[pairIndex]

        if timer == "CasterShowProx" then
            pairData.CasterProxy = SubstituteProxy(pairData.Caster, pairData.Target)
            Osi.ObjectTimerLaunch(actor, "AnimStartCaster", 400)
            -- Osi.ObjectTimerLaunch(actor, "PairedAnimEnd", pairData.StartAnimLength)
            Osi.AddBoosts(actor, "ActionResourceBlock(Movement)", "", "")
            return
        end

        if timer == "AnimStartCaster" then
            -- Start Animation
            if pairData.AnimProperties["Loop"] == true then
                Osi.PlayLoopingAnimation(pairData.CasterProxy, "", pairData.CasterAnim, "", "", "", "", "")
            else
                Osi.PlayAnimation(pairData.CasterProxy, pairData.CasterAnim)
            end
            return
        end
        
        if timer == "PairedSetupCaster" then
            --add relevant spells
            Osi.Transform(actor, "Humans_InvisibleHelper_d5589336-4ca7-4ef7-9f6d-ebfea51001fe", "b40d9ab4-57a7-4632-b8d7-188904b00606")
            return
        end

        if timer == "PairedSetupTarget" then
            Osi.ObjectTimerLaunch(actor, "AnimStartTarget", 400)
            -- Osi.ObjectTimerLaunch(actor, "PairedAnimEnd", pairData.StartAnimLength)
            Osi.AddBoosts(actor, "ActionResourceBlock(Movement)", "", "")
            return
        end

        if timer == "AnimStartTarget" then
            -- Start Animation
            if pairData.AnimProperties["Loop"] == true then
                Osi.PlayLoopingAnimation(actor, "", pairData.TargetAnim, "", "", "", "", "")
            else
                Osi.PlayAnimation(actor, pairData.TargetAnim)
            end
            -- Start Sounds
            return
        end
        
        ------------------------------------
               -- FINISH SEX TIMERS --
        ------------------------------------

        if timer == "FinishSex" then
            -- CASTER
            Osi.SetDetached(pairData.Caster, 0)
            Osi.RemoveTransforms(pairData.Caster)
            Osi.StopAnimation(pairData.CasterProxy, 1)
            Osi.TeleportToPosition(pairData.CasterProxy, 0, 0, 0)
            Osi.SetOnStage(pairData.CasterProxy, 0)

            Osi.RemoveBoosts(pairData.Caster, "ActionResourceBlock(Movement)", 0, "", "")
            Osi.ObjectTimerCancel(pairData.Caster, "SexVocalCaster")

            TryRemoveSpell(pairData.Caster, pairData.AnimContainer)
            TryAddSpell(pairData.Caster, "StartSexContainer")
            Redress(pairData.Caster)
            Osi.TeleportToPosition(pairData.Caster, pairData.CasterStartX, pairData.CasterStartY, pairData.CasterStartZ)

            -- TARGET
            Osi.SetDetached(pairData.Target, 0)
            Osi.StopAnimation(pairData.Target, 1)

            Osi.RemoveBoosts(pairData.Target, "ActionResourceBlock(Movement)", 0, "", "")
            Osi.ObjectTimerCancel(pairData.Target, "SexVocalTarget")

            if pairData.RestoreTargetSexSpell then
                TryAddSpell(pairData.Target, "StartSexContainer")
            end
            Redress(pairData.Target)

            -- DELETE PAIR DATA
            table.remove(AnimationPairs, pairIndex)
            return
        end

        ------------------------------------
               -- SOUND TIMERS --
        ------------------------------------

        if timer == "SexVocalCaster" then
            Osi.PlaySound(actor, SoundRandomizer(pairData.CasterSound))
            Osi.ObjectTimerLaunch(actor, "SexVocalCaster", math.random(1500, 2500), 1)
            return
        end

        if timer == "SexVocalTarget" then
            Osi.PlaySound(actor, SoundRandomizer(pairData.TargetSound))
            Osi.ObjectTimerLaunch(actor, "SexVocalTarget", math.random(1500, 2500), 1)
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
            SwitchPlaces(pairData)
        else
            for _, newAnim in ipairs(pairData.AnimSet) do
                if newAnim.AnimName == spell then
                    ChangePairedAnimation(pairData, newAnim)
                    break
                end
            end
        end
    end)
    
end

Ext.Events.SessionLoaded:Subscribe(PairedAnimationListeners)

function ChangePairedAnimation(pairData, newAnimation) 
    pairData.AnimProperties = newAnimation
    UpdateAnimationVars(pairData)

    Osi.ObjectTimerCancel(pairData.Caster, "SexVocalCaster")
    Osi.ObjectTimerCancel(pairData.Target, "SexVocalTarget")

    local casterAnim = pairData.CasterAnim
    Osi.PlayLoopingAnimation(pairData.CasterProxy, casterAnim, casterAnim, casterAnim, casterAnim, casterAnim, casterAnim, casterAnim)
    local targetAnim = pairData.TargetAnim
    Osi.PlayLoopingAnimation(pairData.Target, targetAnim, targetAnim, targetAnim, targetAnim, targetAnim, targetAnim, targetAnim)

    if pairData.AnimProperties["Sound"] == true then
        Osi.ObjectTimerLaunch(pairData.Caster, "SexVocalCaster", 1000)
        Osi.ObjectTimerLaunch(pairData.Target, "SexVocalTarget", 1000)
    end
end

function StopPairedAnimation(pairData)
    Osi.ObjectTimerCancel(pairData.Caster, "FinishFade.Start")
    Osi.ObjectTimerCancel(pairData.Caster, "FinishFade.End")
    Osi.ObjectTimerCancel(pairData.Target, "FinishFade.Start")
    Osi.ObjectTimerCancel(pairData.Target, "FinishFade.End")

    Osi.ScreenFadeTo(pairData.Caster, 0.1, 0.1, "AnimFade")
    --Osi.ScreenFadeTo(pairData.Target, 0.1, 0.1, "AnimFade")

    Osi.ObjectTimerLaunch(pairData.Caster, "FinishFade.End", 2500)
    --Osi.ObjectTimerLaunch(pairData.Target, "FinishFade.End", 2500)
    Osi.ObjectTimerLaunch(pairData.Caster, "FinishSex", 200)
    Osi.ObjectTimerCancel(pairData.Caster, "SexVocalCaster")
    Osi.ObjectTimerCancel(pairData.Target, "SexVocalTarget")
end

function SwitchPlaces(pairData)
    pairData.SwitchPlaces = not pairData.SwitchPlaces
    UpdateAnimationVars(pairData)

    local casterAnim = pairData.CasterAnim
    Osi.PlayLoopingAnimation(pairData.CasterProxy, casterAnim, casterAnim, casterAnim, casterAnim, casterAnim, casterAnim, casterAnim)
    local targetAnim = pairData.TargetAnim
    Osi.PlayLoopingAnimation(pairData.Target, targetAnim, targetAnim, targetAnim, targetAnim, targetAnim, targetAnim, targetAnim)
end

function UpdateAnimationVars(pairData)
    pairData.AnimSet = SexAnimations
    pairData.AnimContainer = "StraightAnimationsContainer"

    local casterAnimName  = "TopAnimationID"
    local casterSoundName = "SoundTop"
    local targetAnimName  = "BottomAnimationID"
    local targetSoundName = "SoundBottom"

    local casterIsMale = Osi.IsTagged(pairData.Caster, "d27831df-2891-42e4-b615-ae555404918b") -- Has GENITAL_PENIS tag
    local targetIsMale = 1
    if Osi.IsTagged(pairData.Target, "25bf5042-5bf6-4360-8df8-ab107ccb0d37") == 0 then -- If target has no PLAYABLE tag (not a PC or a companion)...
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

    pairData.CasterAnim  = pairData.AnimProperties[casterAnimName]
    pairData.CasterSound = pairData.AnimProperties[casterSoundName]
    pairData.TargetAnim  = pairData.AnimProperties[targetAnimName]
    pairData.TargetSound = pairData.AnimProperties[targetSoundName]
end

function FindPairIndexByActor(actor)
    for i = 1, #AnimationPairs do
        if AnimationPairs[i].Caster == actor or AnimationPairs[i].Target == actor then
            return i
        end
    end    
    return 0
end
