-- Make the Plunderstorm faction's Renown button usable

hooksecurefunc(ReputationDetailViewRenownButton, "Refresh", function(self)
	local factionID = select(14, GetFactionInfo(GetSelectedFaction()))
    if factionID == 2593 then
        self:Enable()
    end
end)
