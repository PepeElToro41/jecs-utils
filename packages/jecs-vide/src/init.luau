local jecs = require(script.Parent.jecs)

local useEntityGet = require(script.use_entity_get)
local useEntityHas = require(script.use_entity_has)
local useQueryFirst = require(script.use_query_first)
local useQuery = require(script.use_query)
local useTarget = require(script.use_target)

local jecs_vide = {
	useEntityGet = useEntityGet.useEntityGet,
	useComponent = useEntityHas.useEntityHas,
}

function jecs_vide.world(world: jecs.World)
	useEntityGet.world = world
	useEntityHas.world = world
	useQueryFirst.world = world
	useQuery.world = world
	useTarget.world = world
end

return jecs_vide
