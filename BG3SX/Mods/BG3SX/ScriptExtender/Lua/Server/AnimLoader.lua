local function registerAnimationSets(animSets)
    local modVars = Ext.Vars.GetModVariables("e641c689-4da2-42d0-a286-aeb962618556")
    if not modVars.LoadedAnimationSets then
        modVars.LoadedAnimationSets = animSets
    else
        for _, animSet in ipairs(animSets) do
            table.insert(modVars.LoadedAnimationSets, animSet)
        end
    end
    Ext.Vars.GetModVariables("e641c689-4da2-42d0-a286-aeb962618556")
    _D(modVars.LoadedAnimationSets)
end

function OnSessionLoaded() 
    _P("LoadingAnimations")    
    Ext.Osiris.RegisterListener("LevelGameplayStarted", 2, "after", function(_, _) registerAnimationSets(AnimSets) end) end
Ext.Events.SessionLoaded:Subscribe(OnSessionLoaded)



