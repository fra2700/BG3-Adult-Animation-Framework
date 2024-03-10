Ext.Require("Shared/AnimationPack.lua")
Ext.Require("Server/AnimationFramework.lua")
Ext.Require("Server/SexActor.lua")
Ext.Require("Server/PairedAnimation.lua")
Ext.Require("Server/SoloAnimation.lua")

Ext.Vars.RegisterUserVariable("ActorData", {
    Server = true,
    Client = true, 
    SyncToClient = true
})

Ext.Vars.RegisterUserVariable("PairData", {
    Server = true,
    Client = true, 
    SyncToClient = true
})