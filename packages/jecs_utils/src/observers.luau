--!strict
local jecs = require(script.Parent.Parent.jecs)

type World = jecs.World
type Query<T...> = jecs.Query<T...>

type Id<T = any> = jecs.Id<T>

export type Iter<T...> = (Observer<T...>) -> () -> (jecs.Entity, T...)

export type Observer<T...> = {
	disconnect: () -> (),
}

export type Monitor<T...> = {
	disconnect: () -> (),
	added: ((jecs.Entity) -> ()) -> (),
	removed: ((jecs.Entity) -> ()) -> (),
}

type QueryInner = jecs.Query<...any> & jecs.QueryInner

local function get_matching_archetypes(world: jecs.World, query: jecs.Query<...any>)
	local archetypes = {}
	local first = query.ids[1]

	for _, archetype in query:archetypes() do
		archetypes[archetype.id] = true
	end

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
		archetypes[archetype.id] = true
	end

	local function on_delete_callback(archetype: jecs.Archetype)
		archetypes[archetype.id] = nil
	end

	local observer_for_create = { query = query :: any, callback = on_create_callback }
	local observer_for_delete = { query = query :: any, callback = on_delete_callback }

	table.insert(query_cache_on_create, observer_for_create)
	table.insert(query_cache_on_delete, observer_for_delete)

	local function disconnect()
		table.remove(query_cache_on_create, table.find(query_cache_on_create, observer_for_create))
		table.remove(query_cache_on_delete, table.find(query_cache_on_create, observer_for_delete))
		table.clear(archetypes)
	end

	return archetypes, disconnect
end

local function observers_new<T...>(query: Query<T...>, callback: (jecs.Entity) -> ()): Observer<T...>
	local world = (query :: Query<T...> & { world: World }).world
	callback = callback

	local terms = query.ids

	local archetypes, disconnect_archetypes = get_matching_archetypes(world, query)
	local entity_index = world.entity_index :: any

	local function emplaced<a>(entity: jecs.Entity, id: jecs.Id<a>, value: a)
		local r = entity_index.sparse_array[jecs.ECS_ID(entity)]

		local archetype = r.archetype

		if archetypes[archetype.id] then
			callback(entity)
		end
	end

	local cleanup = {}

	for _, term in terms do
		if jecs.IS_PAIR(term) then
			local rel = jecs.ECS_PAIR_FIRST(term)
			local tgt = jecs.ECS_PAIR_SECOND(term)
			local wc = tgt == jecs.w

			local onadded = world:added(rel, function(entity, id)
				if not wc and id ~= term then
					return
				end
				local r = jecs.record(world, entity)
				if archetypes[r.archetype.id] then
					callback(entity)
				end
			end)
			table.insert(cleanup, onadded)
		else
			local onadded = world:added(term, emplaced)
			local onchanged = world:changed(term, emplaced)
			table.insert(cleanup, onadded)
			table.insert(cleanup, onchanged)
		end
	end

	local without: { jecs.Id<any> } = (query :: QueryInner).filter_without
	if without then
		for _, term in without do
			if jecs.IS_PAIR(term) then
				local rel = jecs.ECS_PAIR_FIRST(term)
				local tgt = jecs.ECS_PAIR_SECOND(term)
				local wc = tgt == jecs.w
				local onremoved = world:removed(rel, function(entity, id)
					if not wc and id ~= term then
						return
					end
					local r = jecs.record(world, entity)
					local archetype = r.archetype
					if archetype then
						local dst = jecs.archetype_traverse_remove(world, id, archetype)
						if archetypes[dst.id] then
							callback(entity)
						end
					end
				end)

				table.insert(cleanup, onremoved)
			else
				local onremoved = world:removed(term, function(entity, id)
					local r = jecs.record(world, entity)
					local archetype = r.archetype
					if archetype then
						local dst = jecs.archetype_traverse_remove(world, id, archetype)
						if archetypes[dst.id] then
							callback(entity)
						end
					end
				end)

				table.insert(cleanup, onremoved)
			end
		end
	end

	local function disconnect()
		disconnect_archetypes()

		for _, disconnect in cleanup do
			disconnect()
		end
	end

	local observer = {
		disconnect = disconnect,
	}

	return observer
end

local function monitors_new<T...>(query: Query<T...>): Monitor<T...>
	local world = (query :: Query<T...> & { world: World }).world
	local archetypes, disconnect_archetypes = get_matching_archetypes(world, query)
	local entity_index = world.entity_index :: any

	local terms = query.ids

	local callback_added: ((jecs.Entity) -> ())?
	local callback_removed: ((jecs.Entity) -> ())?

	local function emplaced<a>(entity: jecs.Entity, id: jecs.Id<a>, value: a)
		if callback_added == nil then
			return
		end

		local r = jecs.entity_index_try_get_fast(entity_index, entity :: any) :: jecs.Record

		local archetype = r.archetype

		if archetypes[archetype.id] then
			callback_added(entity)
		end
	end

	local function removed(entity: jecs.Entity, component: jecs.Id)
		if callback_removed == nil then
			return
		end
		local r = jecs.record(world, entity)
		if not archetypes[r.archetype.id] then
			return
		end
		callback_removed(entity)
	end

	local cleanup = {}

	for _, term in terms do
		if jecs.IS_PAIR(term) then
			local rel = jecs.ECS_PAIR_FIRST(term)
			local tgt = jecs.ECS_PAIR_SECOND(term)
			local wc = tgt == jecs.w

			local onadded = world:added(rel, function(entity, id)
				if callback_added == nil then
					return
				end

				if not wc and id ~= term then
					return
				end

				local r = jecs.entity_index_try_get_fast(entity_index, entity :: any) :: jecs.Record

				local archetype = r.archetype

				if archetypes[archetype.id] then
					callback_added(entity)
				end
			end)
			local onremoved = world:removed(rel, function(entity, id)
				if callback_removed == nil then
					return
				end
				if not wc and id ~= term then
					return
				end
				local r = jecs.record(world, entity)
				if not archetypes[r.archetype.id] then
					return
				end
				callback_removed(entity)
			end)
			table.insert(cleanup, onadded)
			table.insert(cleanup, onremoved)
		else
			local onadded = world:added(term, emplaced)
			local onremoved = world:removed(term, removed)
			table.insert(cleanup, onadded)
			table.insert(cleanup, onremoved)
		end
	end

	local without: { jecs.Id<any> } = (query :: QueryInner).filter_without
	if without then
		for _, term in without do
			if jecs.IS_PAIR(term) then
				local rel = jecs.ECS_PAIR_FIRST(term)
				local tgt = jecs.ECS_PAIR_SECOND(term)
				local wc = tgt == jecs.w
				local onadded = world:added(rel, function(entity, id)
					if callback_removed == nil then
						return
					end
					if not wc and id ~= term then
						return
					end
					local r = jecs.record(world, entity)
					local archetype = r.archetype
					if archetype then
						local dst = jecs.archetype_traverse_remove(world, id, archetype)
						if archetypes[dst.id] then
							callback_removed(entity)
						end
					end
				end)
				local onremoved = world:removed(rel, function(entity, id)
					if callback_added == nil then
						return
					end
					if not wc and id ~= term then
						return
					end
					local r = jecs.record(world, entity)
					local archetype = r.archetype
					if archetype then
						local dst = jecs.archetype_traverse_remove(world, id, archetype)
						if archetypes[dst.id] then
							callback_added(entity)
						end
					end
				end)
				table.insert(cleanup, onadded)
				table.insert(cleanup, onremoved)
			else
				local onadded = world:added(term, function(entity, id)
					if callback_removed == nil then
						return
					end
					local r = jecs.record(world, entity)
					local archetype = r.archetype
					if archetype then
						local dst = jecs.archetype_traverse_remove(world, id, archetype)
						if archetypes[dst.id] then
							callback_removed(entity)
						end
					end
				end)
				local onremoved = world:removed(term, function(entity, id)
					if callback_added == nil then
						return
					end
					local r = jecs.record(world, entity)
					local archetype = r.archetype
					if archetype then
						local dst = jecs.archetype_traverse_remove(world, id, archetype)
						if archetypes[dst.id] then
							callback_added(entity)
						end
					end
				end)
				table.insert(cleanup, onadded)
				table.insert(cleanup, onremoved)
			end
		end
	end

	local function disconnect()
		disconnect_archetypes()
		for _, disconnect in cleanup do
			disconnect()
		end
	end

	local function monitor_added(callback)
		callback_added = callback
	end

	local function monitor_removed(callback)
		callback_removed = callback
	end

	local monitor = {
		disconnect = disconnect,
		added = monitor_added,
		removed = monitor_removed,
	} :: Monitor<T...>

	return monitor
end

return {
	monitor = monitors_new,
	observer = observers_new,
}
