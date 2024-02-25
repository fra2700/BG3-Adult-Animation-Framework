-- Hotloading
local function on_reset_completed()
    Ext.Stats.LoadStatsFile("Public/AnimationFramework/Stats/Generated/Data/AnimationFramework.txt",1)
    _P('Reloading stats!')
end

Ext.Events.ResetCompleted:Subscribe(on_reset_completed)

Ext.Require("Shared/AnimationPack.lua")
Ext.Require("Server/AnimationFramework.lua")
Ext.Require("Server/SexActor.lua")
Ext.Require("Server/PairedAnimation.lua")
Ext.Require("Server/SoloAnimation.lua")
-- Add Other Animation Packs Here --
