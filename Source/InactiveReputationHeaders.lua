-- Replaces the functions in FrameXML\ReputationFrame.lua with a variant that allows reputation headers to be marked inactive

if not IRH_DB or (type(IRH_DB) ~= "table") then
    IRH_DB = {}
end

local reputationsToOverride = {[67] = true, [469] = true, [1037] = true, [1052] = true, [1272] = true, [1302] = true, [2445] = true, [2510] = true,
    [1162] = true, [1834] = true, [980] = true, [1444] = true, -- these 4 are "Cataclysm", "Legion" etc, they only appear if all their subfactions are marked inactive, and... not sure why they're showing as a reputation at all. Probably a bug. Have been showing since Dragonflight launch.
}

-- simple map: original index => new index
local reputations = {}

local originalGetFactionInfo = GetFactionInfo
local originalGetNumFactions = GetNumFactions

local lastCompile = 0

local function compileNewTable()
    if (lastCompile + 2) > GetTime() then return end
    lastCompile = GetTime()
    
    local numFactions = originalGetNumFactions()
    GetNumFactions = function()
        return numFactions
    end
    
    -- setup defaults
    wipe(reputations)
    for i = 1, numFactions do
        reputations[i] = i
    end
    
    -- remove reputations flagged overwrite inactive
    local removed = {}
    for i = numFactions, 1, -1 do
        if IRH_DB[select(14, originalGetFactionInfo(reputations[i]))] then
            local name = originalGetFactionInfo(reputations[i])
            table.insert(removed, reputations[i])
            for j = i, numFactions do
                reputations[j] = reputations[j+1]
            end
            reputations[numFactions] = nil
            numFactions = numFactions - 1
        end
    end
    
    -- remove headers that have no reputations in them anymore
    for i = numFactions, 1, -1 do
        local name, _, _, _, _, _, _, _, isHeader, isCollapsed, _, _, isChild = originalGetFactionInfo(reputations[i])
        if (not (name == FACTION_INACTIVE)) and isHeader and (not isCollapsed) and (not isChild) then
            local containsOther = false
            local _, _, _, _, _, _, _, _, isHeader2, _, _, _, isChild2 = originalGetFactionInfo(reputations[i+1])
            if isHeader2 and (not isChild2) then
                for j = i, numFactions do
                    reputations[j] = reputations[j+1]
                end
                reputations[numFactions] = nil
                numFactions = numFactions - 1
            end
        end
    end
            
    -- find the faction index of the "Inactive" header
    local inactiveCategoryFactionIndex = 0
    for i = 1, originalGetNumFactions() do
        local name = originalGetFactionInfo(i)
        if name == FACTION_INACTIVE then
            if select(10, originalGetFactionInfo(i)) then return end -- if Inactive is collapsed, no need to inject removed factions
            inactiveCategoryFactionIndex = i
            break
        end
    end
    
    -- inject removed factions into "inactive" list if expanded
    for _, removedOriginalIndex in ipairs(removed) do
        for i = (reputations[inactiveCategoryFactionIndex]+1), numFactions do -- might need to increase that to +2?
            local injectName = originalGetFactionInfo(removedOriginalIndex)
            local preName, _, _, _, _, _, _, _, _, _, _, _, _, factionID = originalGetFactionInfo(reputations[i-1])
            if factionID == 1168 then preName = GUILD end -- the guild reputation, it is sorted as "Guild" but shows the guilds name
            local postName, _, _, _, _, _, _, _, _, _, _, _, _, factionID = originalGetFactionInfo(reputations[i])
            if factionID == 1168 then postName = GUILD end
    
            if (injectName > preName) and (injectName < postName) then
                for j = (numFactions+1), (i+1), -1 do
                    reputations[j] = reputations[j-1]
                end
                reputations[i] = removedOriginalIndex
                break
            end
        end
    end
end

-- Replace Global GetFactionInfo with a variant that factors in any changes to factionIndex we make
local lastReputationFrameUpdate = 0
function GetFactionInfo(index)
    compileNewTable()
    
    if (lastReputationFrameUpdate + 2) < GetTime() then
        ReputationFrame_Update()
        lastReputationFrameUpdate = GetTime()
    end
    
    if index > GetNumFactions() then index = 1 end
    index = reputations[index]
    if not index then
        index = 1
    end
    local name, description, standingID, barMin, barMax, barValue, atWarWith, canToggleAtWar, isHeader, isCollapsed, hasRep, isWatched, isChild, factionID, hasBonusRepGain, canSetInactive = originalGetFactionInfo(index)
    if reputationsToOverride[factionID] then
        canSetInactive = true
    end
    return name, description, standingID, barMin, barMax, barValue, atWarWith, canToggleAtWar, isHeader, isCollapsed, hasRep, isWatched, isChild, factionID, hasBonusRepGain, canSetInactive
end

local originalIsFactionInactive = IsFactionInactive
IsFactionInactive = function(factionIndex)
    compileNewTable()
    if not reputations[factionIndex] then return nil end
    if IRH_DB[select(14, originalGetFactionInfo(reputations[factionIndex]))] then
        return true
    else
        return originalIsFactionInactive(reputations[factionIndex])
    end
end

ReputationDetailInactiveCheckBox:HookScript("OnClick", function(self)
    local factionIndex = GetSelectedFaction()
    if factionIndex == 0 then return end
    local factionID = select(14, GetFactionInfo(factionIndex))
	if reputationsToOverride[factionID] then 
        if not self:GetChecked() then
            PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
            IRH_DB[factionID] = true
        else
            PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF);
            IRH_DB[factionID] = nil
        end
        lastReputationFrameUpdate = 0
        lastCompile = 0
        ReputationFrame_Update()
    end
end)

local originalExpandFactionHeader = ExpandFactionHeader
function ExpandFactionHeader(index)
    originalExpandFactionHeader(reputations[index])
    ReputationFrame_Update()
end

local originalCollapseFactionHeader = CollapseFactionHeader
function CollapseFactionHeader(index)
    originalCollapseFactionHeader(reputations[index])
    ReputationFrame_Update()
end

local originalFactionToggleAtWar = FactionToggleAtWar
function FactionToggleAtWar(index)
    originalFactionToggleAtWar(reputations[index])
end

local originalSetFactionActive = SetFactionActive
function SetFactionActive(index)
    originalSetFactionActive(reputations[index])
    ReputationFrame_Update()
end

local originalSetFactionInactive = SetFactionInactive
function SetFactionInactive(index)
    originalSetFactionInactive(reputations[index])
    ReputationFrame_Update()
end

local originalSetWatchedFactionIndex = SetWatchedFactionIndex
function SetWatchedFactionIndex(index)
    originalSetWatchedFactionIndex(reputations[index] or 0)
end

CharacterFrameTab2:HookScript("OnClick", function()
    C_Timer.After(0.1, ReputationFrame_Update)
end)
