--[[ function AddAnimsetToWaterfall(payload)
    local data = Ext.Json.Parse(payload)
    local actorEntity = Ext.Entity.Get(data.Actor)

    actorEntity.AnimationWaterfall.Waterfall[#actorEntity.AnimationWaterfall.Waterfall+1] = data.AnimationWaterfall
end ]]

if Ext.IsClient() then
    Ext.RegisterNetListener("AddAnimatonToWaterfall", function(_, payload) 
        local data = Ext.Json.Parse(payload)
        local actorEntity = Ext.Entity.Get(data.Actor)

        actorEntity.AnimationWaterfall.Waterfall[#actorEntity.AnimationWaterfall.Waterfall+1] = data.AnimationWaterfall 
    end)
end

--[[ if Ext.IsServer() then
    Ext.Osiris.RegisterListener("UsingSpellOnTarget", 6, "after", function(caster, target, spell, _, _, _)
        -- Checks to see if the name of the spell used matches any of the Spells in the AnimationPacks
        for _, table in ipairs(StartSexSpells) do
            if table.AnimName == spell then
                Ext.Net.BroadcastMessage("AddAnimatonWaterfall", Ext.Json.Stringify({
                Caster = caster,
                Target = target,
                AnimationWaterfall = {
                    Resource = "8335d892-7440-42f7-b084-b31a768c623d",
                    Slot = 0,
                    Type = "Visual"
                    }
                }))
                break
            end
        end
    end)
end ]]



