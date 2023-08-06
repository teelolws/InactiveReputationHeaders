if WOW_PROJECT_ID ~= WOW_PROJECT_WRATH_CLASSIC then return end

local addonName, addon = ...

local reputationsToOverride = addon.reputationsToOverride

local originalIsFactionInactive = IsFactionInactive
local IsFactionInactive = function(factionIndex)
    if IRH_DB[select(14, GetFactionInfo(factionIndex))] then
        return true
    else
        return originalIsFactionInactive(factionIndex)
    end
end

function ReputationFrame_Update()
	local numFactions = GetNumFactions();
    local factionIndex, factionRow, factionTitle, factionStanding, factionBar, factionButton, factionLeftLine, factionBottomLine, factionBackground, color, tooltipStanding;
	local name, description, standingID, barMin, barMax, barValue, atWarWith, canToggleAtWar, isHeader, isCollapsed, hasRep, isWatched, isChild, factionID
	local atWarIndicator, rightBarTexture;

    local previousBigTexture = ReputationFrameTopTreeTexture;	--In case we have a line going off the panel to the top
	previousBigTexture:Hide();
	local previousBigTexture2 = ReputationFrameTopTreeTexture2;
	previousBigTexture2:Hide();

	local gender = UnitSex("player");
	
	local i;
	
	local offScreenFudgeFactor = 5;
	local previousBigTextureRows = 0;
	local previousBigTextureRows2 = 0;

    local factionIndexOffset = 0
    local inactiveCategoryFactionIndex = 1
    local toBeInjected = {}
    for factionIndex = 1, GetNumFactions() do
        local name = GetFactionInfo(factionIndex)
        if name == FACTION_INACTIVE then
            inactiveCategoryFactionIndex = factionIndex
        end
        for factionID, enabled in pairs(IRH_DB) do
            if enabled then
                if (select(14, GetFactionInfo(factionIndex)) == factionID) then
                    toBeInjected[factionID] = factionIndex
                    numFactions = numFactions + 1
                end
            end
        end
    end
    
    -- Update scroll frame
	if ( not FauxScrollFrame_Update(ReputationListScrollFrame, numFactions, NUM_FACTIONS_DISPLAYED, REPUTATIONFRAME_FACTIONHEIGHT ) ) then
		ReputationListScrollFrameScrollBar:SetValue(0);
	end
	local factionOffset = FauxScrollFrame_GetOffset(ReputationListScrollFrame);
    
	for i=1, NUM_FACTIONS_DISPLAYED, 1 do
		factionIndex = factionOffset + i + factionIndexOffset;
		factionRow = _G["ReputationBar"..i];
		factionBar = _G["ReputationBar"..i.."ReputationBar"];
		factionTitle = _G["ReputationBar"..i.."FactionName"];
		factionButton = _G["ReputationBar"..i.."ExpandOrCollapseButton"];
		factionLeftLine = _G["ReputationBar"..i.."LeftLine"];
		factionBottomLine = _G["ReputationBar"..i.."BottomLine"];
		factionStanding = _G["ReputationBar"..i.."ReputationBarFactionStanding"];
		factionBackground = _G["ReputationBar"..i.."Background"];
        if ( factionIndex <= numFactions ) then
			name, description, standingID, barMin, barMax, barValue, atWarWith, canToggleAtWar, isHeader, isCollapsed, hasRep, isWatched, isChild, factionID = GetFactionInfo(factionIndex);
			
            local function getNext()
                if IRH_DB[factionID] then
                    -- skip this reputation
                    factionIndexOffset = factionIndexOffset + 1
                    factionIndex = factionOffset + i + factionIndexOffset;
                    name, description, standingID, barMin, barMax, barValue, atWarWith, canToggleAtWar, isHeader, isCollapsed, hasRep, isWatched, isChild, factionID = GetFactionInfo(factionIndex);
                    getNext()
                end
            end
            getNext()
            
            if (inactiveCategoryFactionIndex > 1) and (factionIndex > inactiveCategoryFactionIndex) then
                -- begin re-injecting factions into the Inactive list
                for injectFactionID in pairs(toBeInjected) do
                    factionIndexOffset = factionIndexOffset - 1
                    factionIndex = toBeInjected[injectFactionID]
                    toBeInjected[injectFactionID] = nil
                    name, description, standingID, barMin, barMax, barValue, atWarWith, canToggleAtWar, isHeader, isCollapsed, hasRep, isWatched, isChild, factionID, hasBonusRepGain = GetFactionInfoByID(injectFactionID)
                    break
                end 
            end
            
            factionTitle:SetText(name);
			if ( isCollapsed ) then
				factionButton:SetNormalTexture("Interface\\Buttons\\UI-PlusButton-Up");
			else
				factionButton:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-Up"); 
			end
			factionRow.index = factionIndex;
			factionRow.isCollapsed = isCollapsed;
			local factionStandingtext = GetText("FACTION_STANDING_LABEL"..standingID, gender);
			factionStanding:SetText(factionStandingtext);

			--Normalize Values
			barMax = barMax - barMin;
			barValue = barValue - barMin;
			barMin = 0;
			
			factionRow.standingText = factionStandingtext;
			factionRow.tooltip = HIGHLIGHT_FONT_COLOR_CODE.." "..barValue.." / "..barMax..FONT_COLOR_CODE_CLOSE;
			factionBar:SetMinMaxValues(0, barMax);
			factionBar:SetValue(barValue);
			local color = FACTION_BAR_COLORS[standingID];
			factionBar:SetStatusBarColor(color.r, color.g, color.b);
			
			if ( isHeader and not isChild ) then
				factionLeftLine:SetTexCoord(0, 0.25, 0, 2);
				factionBottomLine:Hide();
				factionLeftLine:Hide();
				if ( previousBigTextureRows == 0 ) then
					previousBigTexture:Hide();
				end
				previousBigTexture = factionBottomLine;
				previousBigTextureRows = 0;
			elseif ( isHeader and isChild ) then
				ReputationBar_DrawHorizontalLine(factionLeftLine, 11, factionButton);
				if ( previousBigTexture2 and previousBigTextureRows2 == 0 ) then
					previousBigTexture2:Hide();
				end
				factionBottomLine:Hide();
				previousBigTexture2 = factionBottomLine;
				previousBigTextureRows2 = 0;
				previousBigTextureRows = previousBigTextureRows+1;
				ReputationBar_DrawVerticalLine(previousBigTexture, previousBigTextureRows);
				
			elseif ( isChild ) then
				ReputationBar_DrawHorizontalLine(factionLeftLine, 11, factionBackground);
				factionBottomLine:Hide();
				previousBigTextureRows = previousBigTextureRows+1;
				previousBigTextureRows2 = previousBigTextureRows2+1;
				ReputationBar_DrawVerticalLine(previousBigTexture2, previousBigTextureRows2);
			else
				-- is immediately under a main category
				ReputationBar_DrawHorizontalLine(factionLeftLine, 13, factionBackground);
				factionBottomLine:Hide();
				previousBigTextureRows = previousBigTextureRows+1;
				ReputationBar_DrawVerticalLine(previousBigTexture, previousBigTextureRows);
			end
			
			ReputationFrame_SetRowType(factionRow, ((isChild and 1 or 0) + (isHeader and 2 or 0)), hasRep);
			
			factionRow:Show();

			-- Update details if this is the selected faction
			if ( atWarWith ) then
				_G["ReputationBar"..i.."ReputationBarAtWarHighlight1"]:Show();
				_G["ReputationBar"..i.."ReputationBarAtWarHighlight2"]:Show();
			else
				_G["ReputationBar"..i.."ReputationBarAtWarHighlight1"]:Hide();
				_G["ReputationBar"..i.."ReputationBarAtWarHighlight2"]:Hide();
			end
			if ( factionIndex == GetSelectedFaction() ) then
				if ( ReputationDetailFrame:IsShown() ) then
					ReputationDetailFactionName:SetText(name);
					ReputationDetailFactionDescription:SetText(description);
					if ( atWarWith ) then
						ReputationDetailAtWarCheckBox:SetChecked(1);
					else
						ReputationDetailAtWarCheckBox:SetChecked(nil);
					end
					if ( canToggleAtWar and (not isHeader)) then
						ReputationDetailAtWarCheckBox:Enable();
						ReputationDetailAtWarCheckBoxText:SetTextColor(RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b);
					else
						ReputationDetailAtWarCheckBox:Disable();
						ReputationDetailAtWarCheckBoxText:SetTextColor(GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b);
					end
					ReputationDetailInactiveCheckBox:Enable();
					ReputationDetailInactiveCheckBoxText:SetTextColor(ReputationDetailInactiveCheckBoxText:GetFontObject():GetTextColor());
					if ( IsFactionInactive(factionIndex) ) then
						ReputationDetailInactiveCheckBox:SetChecked(1);
					else
						ReputationDetailInactiveCheckBox:SetChecked(nil);
					end
					if ( isWatched ) then
						ReputationDetailMainScreenCheckBox:SetChecked(1);
					else
						ReputationDetailMainScreenCheckBox:SetChecked(nil);
					end
					_G["ReputationBar"..i.."ReputationBarHighlight1"]:Show();
					_G["ReputationBar"..i.."ReputationBarHighlight2"]:Show();
				end
			else
				_G["ReputationBar"..i.."ReputationBarHighlight1"]:Hide();
				_G["ReputationBar"..i.."ReputationBarHighlight2"]:Hide();
			end
		else
			factionRow:Hide();
		end
	end
	if ( GetSelectedFaction() == 0 ) then
		ReputationDetailFrame:Hide();
	end
	
	for i = (NUM_FACTIONS_DISPLAYED + factionOffset + 1), numFactions, 1 do
		local name, description, standingID, barMin, barMax, barValue, atWarWith, canToggleAtWar, isHeader, isCollapsed, hasRep, isWatched, isChild  = GetFactionInfo(i);
		if not name then break; end
		
		if ( isHeader and not isChild ) then
			break;
		elseif ( (isHeader and isChild) or not(isHeader or isChild) ) then
			ReputationBar_DrawVerticalLine(previousBigTexture, previousBigTextureRows+1);
			break;
		elseif ( isChild ) then
			ReputationBar_DrawVerticalLine(previousBigTexture2, previousBigTextureRows2+1);
			break;
		end
	end
end

ReputationDetailInactiveCheckBox:SetScript("OnClick", function(self)
    local factionID = select(14, GetFactionInfo(GetSelectedFaction()))
	if reputationsToOverride[factionID] then 
        if self:GetChecked() then
		    PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
            IRH_DB[factionID] = true
            ReputationFrame_Update()
        else
		    PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF);
            IRH_DB[factionID] = false
            ReputationFrame_Update()
        end
    else
        if ( self:GetChecked() ) then
		    PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
		    SetFactionInactive(GetSelectedFaction());
	    else
		    PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF);
		    SetFactionActive(GetSelectedFaction());
	    end
    end
end)
