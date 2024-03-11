if not AnimationSolos then
    AnimationSolos = {}
end

function StartSoloAnimation(actor, animProperties) 
    local soloData = {
        Actor = actor,
        ActorData = SexActor_Init(actor, true, "SexVocal", animProperties),
        AnimProperties = animProperties,
        AnimContainer = "",
        OriginalStartLocationx = "",
        OriginalStartLocationy = "",
        OriginalStartLocationz = "",
        AnimationProp = "",
    }

    local actorScaled = SexActor_PurgeBodyScaleStatuses(soloData.ActorData)

    UpdateSoloAnimationVars(soloData)

    AnimationSolos[actor] = soloData

    GetOriginalSoloStartLocation(soloData)

    local setupDelay = 400
    if actorScaled and setupDelay < BODY_SCALE_DELAY then
        setupDelay = BODY_SCALE_DELAY -- Give some time for the actor's body to go back to its normal scale
    end

    if animProperties["Fade"] == true then
        Osi.ObjectTimerLaunch(actor, "SoloSexFade.Start", setupDelay - 200)
        Osi.ObjectTimerLaunch(actor, "SoloSexFade.End", setupDelay + 800)
    end

    Osi.ObjectTimerLaunch(actor, "SoloSexSetup", setupDelay)

    TryAddSoloSexSpells(soloData)
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
    local height = soloData.ActorData.HeightClass
    _P(ActorHasPenis(soloData.Actor))
    local filteredAnim = ""
    local gender = ""

    if ActorHasPenis(soloData.Actor) then
        soloData.AnimContainer = "MaleMasturbationContainer"
        gender = "_Male"
        soloData.ActorData.Animation = soloData.AnimProperties['FallbackTopAnimationID']
    else
        soloData.AnimContainer = "FemaleMasturbationContainer"
        gender = "_Female"
        
        soloData.ActorData.Animation = soloData.AnimProperties['FallbackBottomAnimationID']
    end

    filteredAnim = height..gender

    if soloData.AnimProperties[filteredAnim] then
        soloData.ActorData.Animation = soloData.AnimProperties[filteredAnim]
    end
    soloData.ActorData.SoundTable = PLAYER_SEX_SOUNDS

    --Update the Persistent Variable on the actor so that other mods can use this
    --local actorEnt = Ext.Entity.Get(soloData.Actor)
    --actorEnt.Vars.soloData = soloData
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

function TryAddSoloSexSpells(soloData)
    TryAddSpell(soloData.Actor, "CameraHeight")
    TryAddSpell(soloData.Actor, "zzzStopMasturbating")
    TryAddSpell(soloData.Actor, soloData.AnimContainer)
    TryAddSpell(soloData.Actor, "ChangeLocationSolo")
end

function MoveSoloSceneToLocation(actor, x,y,z)
    local soloData = FindSoloData(actor)
    Osi.SetDetached(soloData.ActorData.Proxy, 1)
    Osi.SetDetached(soloData.Actor, 1)

    if CheckDistanceToNewLocationSolo(soloData, x,y,z) < 4 then
        Osi.TeleportToPosition(soloData.ActorData.Proxy, x, y, z)
        Osi.TeleportToPosition(soloData.Actor, x, y, z)
        if soloData.AnimationProp ~= nil then
            Osi.TeleportToPosition(soloData.AnimationProp, x, y, z)
        end
    end
    Osi.SetDetached(soloData.Actor, 0)
end

--Sets the original start location, to prevent the ChangeLocation spell from being abused
function GetOriginalSoloStartLocation(soloData)
    local x,y,z = Osi.GetPosition(soloData.Actor)
    soloData.OriginalStartLocationx = x
    soloData.OriginalStartLocationy = y
    soloData.OriginalStartLocationz = z
end

--Distance Check
function CheckDistanceToNewLocationSolo(soloData, x,y,z)
    local dx = x - soloData.OriginalStartLocationx
    local dy = y - soloData.OriginalStartLocationy
    local dz = z - soloData.OriginalStartLocationz

    local dxSquared = dx * dx
    local dySquared = dy * dy
    local dzSquared = dz * dz

    local distanceSquared = dxSquared + dySquared + dzSquared
    local distance = math.sqrt(distanceSquared)

    return distance
end

--Returns the soloData of an actor
function FindSoloData(actor)
    for _, i in pairs(AnimationSolos) do
        if AnimationSolos[actor] ~= nil then
            return AnimationSolos[actor]
        end
    end    
    return nil
end