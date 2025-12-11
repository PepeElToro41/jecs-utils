local jecs = require(script.Parent.Parent.jecs)

type World = jecs.World
type Query<T...> = jecs.Query<T...>

local common = {}

function common.observe_archetypes(
	world: jecs.World,
	query: jecs.Query<...any>,
	added: (archetype: jecs.Archetype) -> (),
	deleted: (archetype: jecs.Archetype) -> ()
)
	local first = query.ids[1]

	local observable = world.observable
	local on_create_action = observable[jecs.ArchetypeCreate :: any]
	if not on_create_action then
		on_create_action = {} :: any
		observable[jecs.ArchetypeCreate :: any] = on_create_action
	end

	local query_cache_on_create = on_create_action[first]
	if not query_cache_on_create then
		query_cache_on_create = {}
		on_create_action[first] = query_cache_on_create
	end

	local on_delete_action = observable[jecs.ArchetypeDelete :: any]
	if not on_delete_action then
		on_delete_action = {} :: any
		observable[jecs.ArchetypeDelete :: any] = on_delete_action
	end
	local query_cache_on_delete = on_delete_action[first]
	if not query_cache_on_delete then
		query_cache_on_delete = {}
		on_delete_action[first] = query_cache_on_delete
	end

	local function on_create_callback(archetype: jecs.Archetype)
		added(archetype)
	end

	local function on_delete_callback(archetype: jecs.Archetype)
		deleted(archetype)
	end

	local observer_for_create = { query = query :: any, callback = on_create_callback }
	local observer_for_delete = { query = query :: any, callback = on_delete_callback }

	table.insert(query_cache_on_create, observer_for_create)
	table.insert(query_cache_on_delete, observer_for_delete)

	local function disconnect()
		table.remove(query_cache_on_create, table.find(query_cache_on_create, observer_for_create))
		table.remove(query_cache_on_delete, table.find(query_cache_on_create, observer_for_delete))
	end

	return disconnect
end

return common
