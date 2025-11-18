local jecs = require(script.Parent.jecs)

local query_first = require(script["query-first"])
local query_count = require(script["query-count"])
local query_entities = require(script["query-entities"])
local query_changed = require(script["query-changed"])
local query_random = require(script["query-random"])

local collect = require(script.collect)
local interval = require(script.interval)
local ref = require(script.ref)
local observers = require(script.observers)
local is_a = require(script["is-a"])

local utils = {
	query_first = query_first,
	query_count = query_count,
	query_entities = query_entities,
	query_changed = query_changed,
	query_random = query_random,

	collect = collect,
	interval = interval,
	ref = ref,
	is_a = is_a.is_a,
	IsA = is_a.is_a,

	observer = observers.observer,
	monitor = observers.monitor,

	__world = nil :: jecs.World?,
}
utils.default = utils

function utils.world(world: jecs.World)
	utils.__world = world

	ref.world(world)
	is_a.world(world)
end

return utils
