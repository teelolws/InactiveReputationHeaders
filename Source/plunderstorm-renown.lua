-- Make the Plunderstorm faction's Renown button usable

hooksecurefunc(ReputationFrame.ReputationDetailFrame.ViewRenownButton, "Refresh", function(self)
    local factionID = C_Reputation.GetFactionDataByIndex(C_Reputation.GetSelectedFaction()).factionID
    if factionID == 2593 then
        self:Enable()
    end
end)
