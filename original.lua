local SCALE_NETCHANNEL = "FOCUSCORE_SCALE_NETCHANNEL"

---@param target Guid
---@param status string
local function OnShrinkApplied(target, status)
    --Shrink the character when a certain status was applied
    --[[SHRINK CODE]]
    --Broadcast shrink info to all clients
    Ext.Net.BroadcastMessage(SCALE_NETCHANNEL, Ext.Json.Stringify({
        NetID = esvObject.NetID,
        IsCharacter = isCharacter,
    }))
end

---@param target Guid
---@param status string
local function OnShrinkRemoved(target, status)
    --Unshrink the character on the server
    --[[UNSHRINK CODE]]
    --Broadcast unshrink info to all clients
    Ext.Net.BroadcastMessage(SCALE_NETCHANNEL, Ext.Json.Stringify({
        NetID = esvObject.NetID,
        IsCharacter = isCharacter,
    }))
end

--Scale overrides are lost on reload, so reapply them
--We've baked scale overrides into a custom property of the entity itself. This gets baked into the save we can reference it after a reload.
local function ReapplyCustomScales()
    local currentLevel = Ext.Entity.GetCurrentLevel()
    for _, charObj in pairs(currentLevel.EntityManager.CharacterConversionHelpers.RegisteredCharacters[currentLevel.LevelDesc.LevelName]) do
        local currentScale = charObj.UserVars.FOCUSCORE_CurrentScale
        if currentScale ~= nil and charObj.Scale ~= currentScale then
            charObj.Scale = currentScale
        end
    end

    for _, itemObj in pairs(currentLevel.EntityManager.ItemConversionHelpers.RegisteredItems[currentLevel.LevelDesc.LevelName]) do
        local currentScale = itemObj.UserVars.FOCUSCORE_CurrentScale
        if currentScale ~= nil and itemObj.Scale ~= currentScale then
            itemObj.Scale = currentScale
        end
    end
end

--Ext.Entity.Get doesn't support NetIDs because a NetID can be the same for a character and an item. You had to keep track of if the NetID was for a character or an item.
---@param payload NetMessage
local function ApplyClientScale(payload)
    local data = Ext.Json.Parse(payload)
    local eclObject = data.IsCharacter and Ext.Entity.GetCharacter(data.NetID) or Ext.Entity.GetItem(data.NetID)
    if eclObject ~= nil then
        eclObject.Scale = eclObject.UserVars.FOCUSCORE_CurrentScale
    end
end

if Ext.IsServer() then
    Ext.Osiris.RegisterListener("CharacterStatusApplied", 3, "before", OnShrinkApplied)
    Ext.Osiris.RegisterListener("CharacterStatusRemoved", 3, "before", OnShrinkRemoved)
    Ext.Osiris.RegisterListener("ItemStatusChange", 3, "before", OnShrinkApplied)
    Ext.Osiris.RegisterListener("ItemStatusRemoved", 3, "before", OnShrinkRemoved)
    Ext.Osiris.RegisterListener("RegionStarted", 1, "before", ReapplyCustomScales)
end

if Ext.IsClient() then
    Ext.RegisterNetListener(SCALE_NETCHANNEL, function(_, payload) ApplyClientScale(payload) end)
    Ext.Events.GameStateChanged:Subscribe(function(e)
        if e.FromState == "PrepareRunning" and e.ToState == "Running" then
            ReapplyCustomScales()
        end
    end)
end