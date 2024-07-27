-- This file is adapted from the 11.0.0 version of ReputationFrame.lua

local addonName, addon = ...

function ReputationFrame:Update()
	local factionList = {}
    local inactiveList = {}
    local inactiveCategoryFactionIndex
    local inactiveCollapsed = false
    
	for index = C_Reputation.GetNumFactions(), 1, -1 do
		local factionData = C_Reputation.GetFactionDataByIndex(index);
		if factionData then
			factionData.factionIndex = index;
			if IRH_DB[factionData.factionID] then
                -- remove headers flagged overwrite inactive
                tinsert(inactiveList, 1, factionData)
            else
                -- find the location of the Inactive header, if it exists
                if factionData.name == FACTION_INACTIVE then
                    if factionData.isCollatpsed then
                        inactiveCollapsed = true
                    end
                    inactiveCategoryFactionIndex = index
                    tinsert(factionList, 1, factionData)
                else
                    -- remove any headers that have no content left
                    local compareData = factionList[1]
                    local skip = false
                    if compareData and factionData.isHeader and (not factionData.isCollapsed) and (not factionData.isChild) and compareData.isHeader and (not compareData.isChild) then
                        -- header is now empty, omit
                    else
                        tinsert(factionList, 1, factionData)
                    end
                end
            end
		end
	end
    
    -- inject removed factions into "inactive" list if expanded
    if inactiveCategoryFactionIndex and not inactiveCollapsed then
        for removedIndex, removedData in ipairs(inactiveList) do
            local found = false
            for index = 1, #factionList do
                local data = factionList[index]
                if data.factionIndex > inactiveCategoryFactionIndex then
                    local preName = data.name
                    if data.factionIndex == (inactiveCategoryFactionIndex+1) then
                        preName = "A"
                    end
                    if data.factionID == 1168 then
                        -- the guild reputation, it is sorted as "Guild" but shows the guilds name
                        preName = GUILD
                    end
                    
                    local postName
                    if index == #factionList then
                        postName = "Z"
                    else
                        postName = factionList[index+1].name
                        if factionList[index+1].factionID == 1168 then
                            postName = GUILD
                        end
                    end
                    
                    if (removedData.name > preName) and (removedData.name < postName) then
                        found = true
                        table.insert(factionList, index, removedData)
                        break
                    end
                end
            end
        end
    end

	self.ScrollBox:SetDataProvider(CreateDataProvider(factionList), ScrollBoxConstants.RetainScrollPosition);

    self.ReputationDetailFrame:Refresh();
end

function ReputationFrame.ReputationDetailFrame:Refresh()
	local selectedFactionIndex = C_Reputation.GetSelectedFaction();
	local factionData = C_Reputation.GetFactionDataByIndex(selectedFactionIndex);
	if not factionData or factionData.factionID <= 0 then
		self:Hide();
		return;
	end

	self.Title:SetText(factionData.name);
	self.Description:SetText(factionData.description);

	self.AtWarCheckbox:SetEnabled(factionData.canToggleAtWar and not factionData.isHeader);
	self.AtWarCheckbox:SetChecked(factionData.atWarWith);
	local atWarTextColor = factionData.canToggleAtWar and not factionData.isHeader and RED_FONT_COLOR or GRAY_FONT_COLOR;
	self.AtWarCheckbox.Label:SetTextColor(atWarTextColor:GetRGB());

	local canSetInactive = factionData.canSetInactive or addon.reputationsToOverride[factionData.factionID]
    self.MakeInactiveCheckbox:SetEnabled(canSetInactive);		
	self.MakeInactiveCheckbox:SetChecked(IRH_DB[factionData.factionID] or not C_Reputation.IsFactionActive(selectedFactionIndex));
	local inactiveTextColor = canSetInactive and NORMAL_FONT_COLOR or GRAY_FONT_COLOR;
	self.MakeInactiveCheckbox.Label:SetTextColor(inactiveTextColor:GetRGB());

	self.WatchFactionCheckbox:SetChecked(factionData.isWatched);
	
	local isMajorFaction = C_Reputation.IsMajorFaction(factionData.factionID);
	self:SetHeight(isMajorFaction and 228 or 203);
	self.ViewRenownButton:Refresh();

	self:Show();
end

ReputationFrame.ReputationDetailFrame:AddStaticEventMethod(EventRegistry, "ReputationFrame.NewFactionSelected", ReputationFrame.ReputationDetailFrame.Refresh)

function ReputationDetailFrameMixin:ClearSelectedFaction()
	C_Reputation.SetSelectedFaction(0);
	EventRegistry:TriggerEvent("ReputationFrame.NewFactionSelected");
end

ReputationFrame.ReputationDetailFrame.MakeInactiveCheckbox:SetScript("OnClick", function(self)
	local shouldBeActive = not self:GetChecked();
    local selectedFactionIndex = C_Reputation.GetSelectedFaction()
    local factionData = C_Reputation.GetFactionDataByIndex(selectedFactionIndex)
    if addon.reputationsToOverride[factionData.factionID] then
        IRH_DB[factionData.factionID] = not shouldBeActive
        ReputationFrame:Update()
    else
	   C_Reputation.SetFactionActive(C_Reputation.GetSelectedFaction(), shouldBeActive);
    end

	local clickSound = self:GetChecked() and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF;
	PlaySound(clickSound);
end)
