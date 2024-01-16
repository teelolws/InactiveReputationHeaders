if WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE then return end

local addonName, addon = ...

local reputationsToOverride = addon.reputationsToOverride

hooksecurefunc("ReputationFrame_Update", function()
    local dataProvider = ReputationFrame.ScrollBox:GetDataProvider()
    
    -- find the faction index of the "Inactive" header
    local inactiveCategoryFactionIndex
    local inactiveCollapsed = false

    dataProvider:ForEach(function(data)
        local index = data.index
        local name = GetFactionInfo(index)
        if name == FACTION_INACTIVE then
            if select(10, GetFactionInfo(index)) then
                inactiveCollapsed = true
            end
            inactiveCategoryFactionIndex = index
        end
    end)
    
    -- remove reputations flagged overwrite inactive
    local removed = {}
    dataProvider:ReverseForEach(function(data)
        local index = data.index
        if index < (inactiveCategoryFactionIndex or GetNumFactions()) then
            if IRH_DB[select(14, GetFactionInfo(index))] then
                removed[index] = data
                dataProvider:Remove(data)
            end
        end
    end)

    -- remove headers that have no reputations in them anymore
    for dpIndex, data in dataProvider:ReverseEnumerate() do
        local index = data.index
        local name, _, _, _, _, _, _, _, isHeader, isCollapsed, _, _, isChild = GetFactionInfo(index)
        
        if isHeader and (not isCollapsed) and (not isChild) then
            if dataProvider.collection[dpIndex+1] then
                local name2, _, _, _, _, _, _, _, isHeader2, _, _, _, isChild2 = GetFactionInfo(dataProvider.collection[dpIndex+1].index)
                if isHeader2 and (not isChild2) then
                    dataProvider:Remove(data)
                end
            end
        end
    end
    
    if not inactiveCategoryFactionIndex then return end
    if inactiveCollapsed then return end
    
    -- inject removed factions into "inactive" list if expanded
    for removedIndex, removedData in pairs(removed) do
        local found
        dataProvider:ForEach(function(data)
            if found then return end
            local index = data.index
            if index > inactiveCategoryFactionIndex then
                local injectName = GetFactionInfo(removedData.index)
                
                local preName, _, _, _, _, _, _, _, _, _, _, _, _, factionID = GetFactionInfo(index-1)
                if index == (inactiveCategoryFactionIndex+1) then
                    preName = "A"
                end
                
                if factionID == 1168 then
                    preName = GUILD -- the guild reputation, it is sorted as "Guild" but shows the guilds name
                end
                
                local postName, _, _, _, _, _, _, _, _, _, _, _, _, factionID
                if index == GetNumFactions() then
                    postName = "Z"
                else
                    postName, _, _, _, _, _, _, _, _, _, _, _, _, factionID = GetFactionInfo(index+1)
                    if factionID == 1168 then postName = GUILD end
                end
        
                if (injectName > preName) and (injectName < postName) then
                    found = true
                    -- data provider doesn't have an "insert at" function so I have to dig in myself...
                    local tableIndex
                    for i = 1, #dataProvider.collection do
                        if dataProvider.collection[i] == data then
                            tableIndex = i
                            break
                        end
                    end
                    table.insert(dataProvider.collection, tableIndex, removedData)
                    dataProvider:TriggerEvent(DataProviderMixin.Event.OnInsert, tableIndex, removedData)
                    dataProvider:TriggerEvent(DataProviderMixin.Event.OnSizeChanged)
                end
            end
        end)
    end
end)

-- Replace Global GetFactionInfo with a variant that factors in any changes to factionIndex we make
local originalGetFactionInfo = GetFactionInfo
function GetFactionInfo(index)
    local name, description, standingID, barMin, barMax, barValue, atWarWith, canToggleAtWar, isHeader, isCollapsed, hasRep, isWatched, isChild, factionID, hasBonusRepGain, canSetInactive = originalGetFactionInfo(index)
    if reputationsToOverride[factionID] then
        canSetInactive = true
    end
    return name, description, standingID, barMin, barMax, barValue, atWarWith, canToggleAtWar, isHeader, isCollapsed, hasRep, isWatched, isChild, factionID, hasBonusRepGain, canSetInactive
end

local originalIsFactionInactive = IsFactionInactive
IsFactionInactive = function(factionIndex)
    if IRH_DB[select(14, GetFactionInfo(factionIndex))] then
        return true
    else
        return originalIsFactionInactive(factionIndex)
    end
end

ReputationDetailInactiveCheckBox:HookScript("OnClick", function(self, button)
    local factionIndex = GetSelectedFaction()
    local factionID = select(14, GetFactionInfo(factionIndex))
	if reputationsToOverride[factionID] then 
        if self:GetChecked() then
            PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
            IRH_DB[factionID] = true
        else
            PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF);
            IRH_DB[factionID] = nil
        end
        ReputationFrame_Update()
    end
end)
