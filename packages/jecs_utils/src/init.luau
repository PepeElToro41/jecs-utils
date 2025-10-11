local jecs = require(script.Parent.jecs)

local query_first = require(script.query_first)
local query_count = require(script.query_count)
local query_entities = require(script.query_entities)
local collect = require(script.collect)
local interval = require(script.interval)
local ref = require(script.ref)
local observers = require(script.observers)

local utils = {
	query_first = query_first,
	query_count = query_count,
	query_entities = query_entities,
	collect = collect,
	interval = interval,
	ref = ref,
	observers = observers,
}

function utils.world(world: jecs.World)
	ref.world(world)
end

ref()

return utils
