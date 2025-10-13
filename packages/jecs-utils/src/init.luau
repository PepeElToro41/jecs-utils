local jecs = require(script.Parent.jecs)

local query_first = require(script["query-first"])
local query_count = require(script["query-count"])
local query_entities = require(script["query-entities"])
local query_changed = require(script["query-changed"])

local collect = require(script.collect)
local interval = require(script.interval)
local ref = require(script.ref)
local observers = require(script.observers)

local utils = {
	query_first = query_first,
	query_count = query_count,
	query_entities = query_entities,
	query_changed = query_changed,

	collect = collect,
	interval = interval,
	ref = ref,

	observer = observers.observer,
	monitor = observers.monitor,

	__world = nil :: jecs.World?,
}

function utils.world(world: jecs.World)
	utils.__world = world

	ref.world(world)
end

return utils
