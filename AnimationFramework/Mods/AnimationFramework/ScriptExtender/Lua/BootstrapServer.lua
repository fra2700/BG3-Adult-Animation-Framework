Ext.Require("Server/AnimationFramework.lua")
Ext.Require("Server/SexActor.lua")
Ext.Require("Server/PairedAnimation.lua")
Ext.Require("Server/SoloAnimation.lua")
Ext.Require("Server/ActorScale.lua")

Ext.Vars.RegisterModVariable("df8b9877-5662-4411-9d08-9ee2ec4d8d9e", "BG3SX_AnimationData", {})


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

