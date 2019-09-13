local Routes = LibStub("AceAddon-3.0"):GetAddon("Routes", 1)
if not Routes then return end

local SourceName = "Gatherer"
local L = LibStub("AceLocale-3.0"):GetLocale("Routes")

------------------------------------------
-- setup
Routes.plugins[SourceName] = {}
local source = Routes.plugins[SourceName]

do
	local loaded = true
	local function IsActive() -- Can we gather data?
		return Gatherer and loaded
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

local function Summarize(data, zone)
	local amount_of = {}
	local db_type_of = {}
	local zoneID = Routes.LZName[zone]

	-- This loop works only because of a bug in Gatherer.
	-- Gatherer may be fixed in the future and break this loop.
	for _, node, db_type in Gatherer.Storage.ZoneGatherNames(zoneID) do
		amount_of[node] = (amount_of[node] or 0) + 1
		db_type_of[node] = db_type
	end
	for node, count in pairs(amount_of) do
		local db_type = db_type_of[node]
		local translatednode = Gatherer.Util.GetNodeName(node)
		data[ ("%s;%s;%s;%s"):format(SourceName, db_type, node, count) ] = ("%s - %s (%d)"):format(L[SourceName..db_type], translatednode, count)
	end

	return data
end
source.Summarize = Summarize

-- returns the english name, translated name for the node so we can store it was being requested
-- also returns the type of db for use with auto show/hide route
local translate_db_type = {
	["HERB"] = "Herbalism",
	["MINE"] = "Mining",
	["OPEN"] = "Treasure",
	["ARCH"] = "Archaeology",
}
local function AppendNodes(node_list, zone, db_type, node_type)
	local zoneID = Routes.LZName[zone]
	node_type = tonumber(node_type)

	-- posX, posY, timesGathered, indoors, harvested, inspected, source = GetGatherInfo(C, Z, node_type, db_type, index)
	for index, posX, posY, inspected, indoors in Gatherer.Storage.ZoneGatherNodes(zoneID, db_type) do
		if Gatherer.Storage.GetGatherInfo(zoneID, node_type, db_type, index) then
			tinsert( node_list, floor(posX * 10000 + 0.5) * 10000 + floor(posY * 10000 + 0.5) )
		end
	end


	-- return the node_type for auto-adding
	local translatednode = Gatherer.Util.GetNodeName(node_type)
	return translatednode, translatednode, translate_db_type[db_type]
end
source.AppendNodes = AppendNodes

-- continent/zone - GetMapZones() stuff
-- nodeType - HERB/MINE/OPEN
-- x, y - the coordinate [0,1]
-- node_name - the node being removed, can be an ID, as long as I can convert this to a localized or english string of the node such as "Copper Vein"
local function InsertNode(continent, zone, nodeType, x, y, node_name)
	--Routes:InsertNode(zone, coord, node_name)
end

local function DeleteNode(continent, zone, nodeType, x, y, node_name)
	--Routes:DeleteNode(zone, coord, node_name)
end

local function AddCallbacks()
	--Functions to add Gatherer callbacks
end
source.AddCallbacks = AddCallbacks

local function RemoveCallbacks()
	--Functions to remove Gatherer callbacks
end
source.RemoveCallbacks = RemoveCallbacks

-- vim: ts=4 noexpandtab
