local jecs = require(script.Parent.jecs)
local jecs_utils = require(script.Parent["jecs-utils"])

local use_entity_get = require(script.use_entity_get)
local use_entity_has = require(script.use_entity_has)
local use_query_first = require(script.use_query_first)
local use_query = require(script.use_query)
local use_target = require(script.use_target)

local jecs_vide = {
	useEntityGet = use_entity_get.use_entity_get,
	useEntityHas = use_entity_has.use_entity_has,
	useQueryFirst = use_query_first.use_query_first,
	useQuery = use_query.use_query,
	useTarget = use_target.use_target,

	use_entity_get = use_entity_get.use_entity_get,
	use_entity_has = use_entity_has.use_entity_has,
	use_query_first = use_query_first.use_query_first,
	use_query = use_query.use_query,
	use_target = use_target.use_target,

	__world = nil :: jecs.World?,
}
jecs_vide.default = jecs_vide

function jecs_vide.world(world: jecs.World)
	if jecs_utils.__world ~= world then
		jecs_utils.world(world)
	end

	use_entity_get.world = world
	use_entity_has.world = world
	use_query_first.world = world
	use_query.world = world
	use_target.world = world
end

return jecs_vide
