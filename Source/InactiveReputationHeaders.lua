-- Replaces the functions in FrameXML\ReputationFrame.lua with a variant that allows reputation headers to be marked inactive

if not IRH_DB or (type(IRH_DB) ~= "table") then
    IRH_DB = {}
end

local reputationsToOverride = {[67] = true, [469] = true, [1037] = true, [1052] = true, [1272] = true, [1302] = true, [2445] = true,}

-- simple map: original index => new index
local reputations = {}

local originalGetFactionInfo = GetFactionInfo
local originalGetNumFactions = GetNumFactions

local lastCompile = GetTime()

local function compileNewTable()
    if (lastCompile + 0.1) > GetTime() then return end
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
    local function recursion(k)
        for i = k, numFactions do
            if IRH_DB[select(14, originalGetFactionInfo(reputations[i]))] then
                local name = originalGetFactionInfo(reputations[i])
                table.insert(removed, reputations[i])
                for j = i, numFactions do
                    reputations[j] = reputations[j+1]
                end
                reputations[numFactions] = nil
                numFactions = numFactions - 1
                recursion(i)
                return
            end
        end
    end
    recursion(1)
    
    -- remove headers that have no reputations in them anymore
    function recursion(k)
        for i = k, numFactions do
            local name, _, _, _, _, _, _, _, isHeader, isCollapsed, _, _, isChild = originalGetFactionInfo(reputations[i])
            if (not (name == FACTION_INACTIVE)) and isHeader and (not isCollapsed) and (not isChild) then
                local containsOther = false
                local _, _, _, _, _, _, _, _, isHeader2, _, _, _, isChild2 = originalGetFactionInfo(reputations[i+1])
                if isHeader2 and (not isChild2) then
                    -- skip this header, too
                    for j = i, numFactions do
                        reputations[j] = reputations[j+1]
                    end
                    reputations[numFactions] = nil
                    numFactions = numFactions - 1
                    recursion(i)
                    return
                end
            end
        end
    end
    recursion(1)
            
    -- find the faction index of the "Inactive" header
    local inactiveCategoryFactionIndex = 0
    for i = 1, originalGetNumFactions() do
        local name = originalGetFactionInfo(i)
        if name == FACTION_INACTIVE then
            inactiveCategoryFactionIndex = i
            if select(10, originalGetFactionInfo(i)) then return end -- if Inactive is collapsed, no need to inject removed factions
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

--local printOnce
-- Replace Global GetFactionInfo with a variant that factors in any changes to factionIndex we make
function GetFactionInfo(index)
    compileNewTable()
    ReputationFrame_Update()
    if index > GetNumFactions() then index = 1 end
    index = reputations[index]
    if not index then
        index = 1
        --if not printOnce then
        --    printOnce = true
        --    print("InactiveReputationHeaders: Something went wrong. Please report this to the author!")
        --end
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
            C_Timer.After(0.1, ReputationFrame_Update)
        else
		    PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF);
            IRH_DB[factionID] = nil
        end
        ReputationFrame_Update()
    end
end)

local originalExpandFactionHeader = ExpandFactionHeader
function ExpandFactionHeader(index)
    originalExpandFactionHeader(reputations[index])
    compileNewTable()
    C_Timer.After(0.1, ReputationFrame_Update)
end

local originalCollapseFactionHeader = CollapseFactionHeader
function CollapseFactionHeader(index)
    originalCollapseFactionHeader(reputations[index])
    compileNewTable()
    C_Timer.After(0.1, ReputationFrame_Update)
end

local originalFactionToggleAtWar = FactionToggleAtWar
function FactionToggleAtWar(index)
    originalFactionToggleAtWar(reputations[index])
end

local originalSetFactionActive = SetFactionActive
function SetFactionActive(index)
    originalSetFactionActive(reputations[index])
    compileNewTable()
    C_Timer.After(0.1, ReputationFrame_Update)
end

local originalSetFactionInactive = SetFactionInactive
function SetFactionInactive(index)
    originalSetFactionInactive(reputations[index])
    compileNewTable()
    C_Timer.After(0.1, ReputationFrame_Update)
end

local originalSetWatchedFactionIndex = SetWatchedFactionIndex
function SetWatchedFactionIndex(index)
    originalSetWatchedFactionIndex(reputations[index] or 0)
end

CharacterFrameTab2:HookScript("OnClick", function()
    C_Timer.After(0.1, ReputationFrame_Update)
end)