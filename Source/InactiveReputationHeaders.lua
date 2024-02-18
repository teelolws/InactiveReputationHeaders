local addonName, addon = ...

-- Replaces the functions in FrameXML\ReputationFrame.lua with a variant that allows reputation headers to be marked inactive

addon.reputationsToOverride = {[67] = true, [469] = true, [891] = true, [892] = true, [1037] = true, [1052] = true, [1272] = true, [1302] = true, [2445] = true, [2507] = true, [2510] = true,
    [1162] = true, [1834] = true, [980] = true, [1444] = true, -- these 4 are "Cataclysm", "Legion" etc, they only appear if all their subfactions are marked inactive, and... not sure why they're showing as a reputation at all. Probably a bug. Have been showing since Dragonflight launch.
}

EventUtil.ContinueOnAddOnLoaded(addonName, function()
    if not IRH_DB then
        IRH_DB = {}
    end
end)
