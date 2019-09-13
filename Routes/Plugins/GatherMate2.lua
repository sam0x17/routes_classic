local Routes = LibStub("AceAddon-3.0"):GetAddon("Routes", 1)
if not Routes then return end

local SourceName = "GatherMate2"
local L = LibStub("AceLocale-3.0"):GetLocale("Routes")
local LN = LibStub("AceLocale-3.0"):GetLocale("GatherMate2Nodes", true)

------------------------------------------
-- setup
Routes.plugins[SourceName] = {}
local source = Routes.plugins[SourceName]

do
	local loaded = true
	local function IsActive() -- Can we gather data?
		return GatherMate2 and loaded
	end
	source.IsActive = IsActive

	-- stop loading if the addon is not enabled, or
	-- stop loading if there is a reason why it can't be loaded ("MISSING" or "DISABLED")
	local enabled = GetAddOnEnableState(UnitName("player"), SourceName)
	local name, title, notes, loadable, reason, security = GetAddOnInfo(SourceName)
	if not enabled or (reason ~= nil and reason ~= "DEMAND_LOADED") then
		loaded = false
		return
	end
end

------------------------------------------
-- functions

local amount_of = {}
local function Summarize(data, zone)
	LN = LibStub("AceLocale-3.0"):GetLocale("GatherMate2Nodes", true) -- Workaround LoD of GatherMate2 if AddonLoader is used.
	for db_type, db_data in pairs(GatherMate2.gmdbs) do
		-- reuse table
		wipe(amount_of)
		-- only look for data for this currentzone
		local zoneID = Routes.LZName[zone]
		if db_data[zoneID] then
			-- count the unique values (structure is: location => itemID)
			for _,node in pairs(db_data[zoneID]) do
				amount_of[node] = (amount_of[node] or 0) + 1
			end
			-- XXX Localize these strings
			-- store combinations with all information we have
			for node,count in pairs(amount_of) do
				local translatednode = GatherMate2:GetNameForNode(db_type, node)
				if translatednode then
					data[ ("%s;%s;%s;%s"):format(SourceName, db_type, node, count) ] = ("%s - %s (%d)"):format(L[SourceName..db_type], translatednode, count)
				end
			end
		end
	end
	return data
end
source.Summarize = Summarize

-- returns the english name, translated name for the node so we can store it was being requested
-- also returns the type of db for use with auto show/hide route
local translate_db_type = {
	["Herb Gathering"] = "Herbalism",
	["Mining"] = "Mining",
	["Fishing"] = "Fishing",
	["Extract Gas"] = "ExtractGas",
	["Treasure"] = "Treasure",
	["Archaeology"] = "Archaeology",
	["Logging"] = "Logging",
}
local function AppendNodes(node_list, zone, db_type, node_type)
	if type(GatherMate2.gmdbs[db_type]) == "table" then
		node_type = tonumber(node_type)

		-- Find all of the notes
		local zoneID = Routes.LZName[zone]
		for loc, t in pairs(GatherMate2.gmdbs[db_type][zoneID]) do
			-- And are of a selected type - store
			if t == node_type then
				-- Convert GM2 location to our format
				local x, y, l = GatherMate2:DecodeLoc(loc) -- ignore level for now
				local newLoc = Routes:getID(x, y)
				tinsert( node_list, newLoc )
			end
		end

		-- return the node_type for auto-adding
		local translatednode = GatherMate2:GetNameForNode(db_type, node_type)
		for k, v in pairs(LN) do
			if v == translatednode then -- get the english name
				return k, v, translate_db_type[db_type]
			end
		end
	end
end
source.AppendNodes = AppendNodes

local function InsertNode(event, zone, nodeType, coord, node_name)
	-- Convert coords
	local x, y, l = GatherMate2:DecodeLoc(coord) -- ignore level for now
	local newCoord = Routes:getID(x, y)
	-- Convert zone
	local zoneLocalized = GatherMate2:MapLocalize(zone)
	Routes:InsertNode(zoneLocalized, newCoord, node_name)
end

local function DeleteNode(event, zone, nodeType, coord, node_name)
	-- Convert coords
	local x, y, l = GatherMate2:DecodeLoc(coord) -- ignore level for now
	local newCoord = Routes:getID(x, y)
	-- Convert zone
	local zoneLocalized = GatherMate2:MapLocalize(zone)
	Routes:DeleteNode(zoneLocalized, newCoord, node_name)
end

local function AddCallbacks()
	Routes:RegisterMessage("GatherMate2NodeAdded", InsertNode)
	Routes:RegisterMessage("GatherMate2NodeDeleted", DeleteNode)
end
source.AddCallbacks = AddCallbacks

local function RemoveCallbacks()
	Routes:UnregisterMessage("GatherMate2NodeAdded")
	Routes:UnregisterMessage("GatherMate2NodeDeleted")
end
source.RemoveCallbacks = RemoveCallbacks

-- vim: ts=4 noexpandtab
