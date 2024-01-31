if not AnimationSolos then
    AnimationSolos = {}
end

function StartSoloAnimation(actor, animProperties) 

    local soloData = {
        Proxy = "",
        AnimProperties = animProperties,
        AnimLength = animProperties["AnimLength"] * 1000
    }

    AnimationSolos[actor] = soloData
    
    if animProperties["Fade"] == true then
        Osi.ObjectTimerLaunch(actor, "SoloBeginningFade.Start", 200)
        Osi.ObjectTimerLaunch(actor, "SoloBeginningFade.End", 1200)
        Osi.ObjectTimerLaunch(actor, "SoloFinishFade.Start", soloData.AnimLength - 400)
        Osi.ObjectTimerLaunch(actor, "SoloFinishFade.End", soloData.AnimLength + 400 + 650)
    end

    Osi.ObjectTimerLaunch(actor, "ShowProx", 400)
    Osi.ObjectTimerLaunch(actor, "CasterSetup", 400)
    Osi.ObjectTimerLaunch(actor, "SexVocal", 600)

    TryRemoveSpell(actor, "StartSexContainer")
    TryAddSpell(actor, "MasturbationAnimationsContainer")
end

function SoloAnimationListeners()

    Ext.Osiris.RegisterListener("ObjectTimerFinished", 2, "after", function(actor, timer)

        ------------------------------------
                  -- FADE TIMERS --
        ------------------------------------

        if timer == "SoloBeginningFade.Start" then
            Osi.ScreenFadeTo(actor, 0.1, 0.1, "AnimFade")
            return
        end

        if timer == "SoloBeginningFade.End" then
            Osi.ClearScreenFade(actor, 0.1, "AnimFade", 0)
            return
        end

        if timer == "SoloFinishFade.Start" then
            Osi.ScreenFadeTo(actor, 0.1, 0.1, "AnimFade")
            return
        end

        if timer == "SoloFinishFade.End" then
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

        --START
        if timer == "ShowProx" then
            soloData.Proxy = SubstituteProxy(actor)
            Osi.ObjectTimerLaunch(actor, "SoloAnimStart", 200)
            Osi.ObjectTimerLaunch(actor, "SoloAnimEnd", soloData.AnimLength)
            Osi.AddBoosts(actor, "ActionResourceBlock(Movement)", "", "")
            return
        end

        if timer == "CasterSetup" then
            Osi.Transform(actor, "Humans_InvisibleHelper_d5589336-4ca7-4ef7-9f6d-ebfea51001fe", "b40d9ab4-57a7-4632-b8d7-188904b00606")
            if soloData.AnimProperties["Strip"] == true and Osi.HasActiveStatus(actor, "BLOCK_STRIPPING")~=1 then
                Strip(actor)
            end
            Osi.SetDetached(actor, 0)
            return
        end

        if timer == "SoloAnimStart" then
            -- Start Animation
            if soloData.AnimProperties["Loop"] == true then
                Osi.PlayLoopingAnimation(soloData.Proxy, "", soloData.AnimProperties["TopAnimationID"], "", "", "", "", "")
            else
                Osi.PlayAnimation(soloData.Proxy, soloData.AnimProperties["TopAnimationID"])
            end
            return
        end
        
        --END
        if timer == "SoloAnimEnd" then
            StopSoloAnimation(actor)
            return
        end

        if timer == "FinishMasturbating" then
            Osi.RemoveTransforms(actor)
            Osi.StopAnimation(soloData.Proxy, 1)
            Osi.TeleportToPosition(soloData.Proxy, 0, 0, 0)
            Osi.RemoveBoosts(actor, "ActionResourceBlock(Movement)", 0, "", "")
            Osi.ObjectTimerCancel(actor, "SexVocal")

            TryRemoveSpell(actor, "MasturbationAnimationsContainer")
            TryAddSpell(actor, "StartSexContainer")
            Redress(actor)

            AnimationSolos[actor] = nil
            return
        end


        ------------------------------------
               -- SOUND TIMERS --
        ------------------------------------

        if timer == "SexVocal" then
            local randomVocal = SoundRandomizer(PlayerSexSounds)
            Osi.PlaySound(actor, randomVocal)
            Osi.ObjectTimerLaunch(actor, "SexVocal", math.random(1500,2000) , 1)
            return
        end
    end)

    ------------------------------------
            -- SPELL LISTENERS --
    ------------------------------------

    Ext.Osiris.RegisterListener("UsingSpell", 5, "after", function(caster, spell, _, _, _)
        if spell == "StopMasturbating" then
            StopSoloAnimation(caster)
        else
            for _, newAnim in ipairs(MasturbationAnimations) do
                if newAnim.AnimName == spell then
                    ChangeSoloAnimation(caster, newAnim)
                    break
                end
            end
        end
    end)
end

Ext.Events.SessionLoaded:Subscribe(SoloAnimationListeners)

function ChangeSoloAnimation(actor, newAnimation) 
    local soloData = AnimationSolos[actor]
    if not soloData then
        return
    end

    soloData.AnimProperties = newAnimation
    Osi.PlayLoopingAnimation(soloData.Proxy, "", soloData.AnimProperties["TopAnimationID"], "", "", "", "", "")
    -- Osi.PlayLoopingAnimation(soloData.Proxy, "", soloData.AnimProperties["TopAnimationID"], "", "", "", "", "")
    -- Osi.PlayLoopingAnimation(soloData.Proxy, "", soloData.AnimProperties["TopAnimationID"], "", "", "", "", "")
end

function StopSoloAnimation(actor)
    Osi.ObjectTimerCancel(actor, "SoloFinishFade.Start")
    Osi.ObjectTimerCancel(actor, "SoloFinishFade.End")
    Osi.ScreenFadeTo(actor, 0.1, 0.1, "AnimFade")
    Osi.ObjectTimerLaunch(actor, "SoloFinishFade.End", 2500)
    Osi.ObjectTimerLaunch(actor, "FinishMasturbating", 200)
end

PlayerSexSounds = {"BreathLongExhaleOpen_PlayerCharacter_Cine","BreathLongInhaleOpen_PlayerCharacter_Cine","BreathShortInhaleOpen_PlayerCharacter_Cine", "LoveMoanClosed_PlayerCharacter_Cine", "LoveMoanOpen_PlayerCharacter_Cine"}

function SoundRandomizer(soundtable)
    local randomIndex = math.random(1, #soundtable)
    -- Return the randomly selected string
    return soundtable[randomIndex]
end
