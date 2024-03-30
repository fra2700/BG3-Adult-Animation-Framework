Ext.Require("Shared/AnimationPack.lua")
Ext.Require("Shared/AnimationSets.lua")
Ext.Require("Server/AnimLoader.lua")
Ext.Require("Server/BG3SX.lua")
Ext.Require("Server/SexActor.lua")
Ext.Require("Server/PairedAnimation.lua")
Ext.Require("Server/SoloAnimation.lua")
Ext.Require("Server/ActorScale.lua")
Ext.Require("Server/GameData.lua")



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

Ext.Vars.RegisterUserVariable("SoloData", {
    Server = true,
    Client = true, 
    SyncToClient = true
})