local addonName, addon = ...

addon.reputationsToOverride = {
    [67] = true,
    [469] = true,
    [891] = true,
    [892] = true,
    [1037] = true,
    [1052] = true,
    [1272] = true,
    [1302] = true,
    [2445] = true,
    [2507] = true,
    [2510] = true,
    [2600] = true,
}

EventUtil.ContinueOnAddOnLoaded(addonName, function()
    if not IRH_DB then
        IRH_DB = {}
    end
end)
