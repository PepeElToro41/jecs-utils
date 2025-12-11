--!strict
local jecs = require(script.Parent.Parent.jecs)
local common = require(script.Parent.common)

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

	for _, archetype in query:archetypes() do
		archetypes[archetype.id] = true
	end

	local function on_create_callback(archetype: jecs.Archetype)
		archetypes[archetype.id] = true
	end

	local function on_delete_callback(archetype: jecs.Archetype)
		archetypes[archetype.id] = nil
	end

	local disconnect = common.observe_archetypes(world, query, on_create_callback, on_delete_callback)
	return archetypes, disconnect
end

local function observers_new<T...>(query: Query<T...>, callback: (jecs.Entity) -> ()): Observer<T...>
	local world = (query :: Query<T...> & { world: World }).world
	callback = callback

	local terms = query.ids
	local with: { jecs.Entity } = (query :: QueryInner).filter_with

	local archetypes, disconnect_archetypes = get_matching_archetypes(world, query)

	local function emplaced<a>(entity: jecs.Entity)
		local r = jecs.record(world, entity)
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
			local wc = tgt == jecs.Wildcard

			local onchanged = world:changed(rel, function(entity, id)
				if wc then
					emplaced(entity)
				elseif id == term then
					emplaced(entity)
				end
			end)
			table.insert(cleanup, onchanged)
		else
			local onchanged = world:changed(term, emplaced)
			table.insert(cleanup, onchanged)
		end
	end

	if with then
		for _, term in with do
			if jecs.IS_PAIR(term) then
				local rel = jecs.ECS_PAIR_FIRST(term)
				local tgt = jecs.ECS_PAIR_SECOND(term)
				local wc = tgt == jecs.Wildcard

				local onadded = world:added(rel, function(entity, id)
					if wc then
						emplaced(entity)
					elseif id == term then
						emplaced(entity)
					end
				end)
				table.insert(cleanup, onadded)
			else
				local onadded = world:added(term, emplaced)
				table.insert(cleanup, onadded)
			end
		end
	end

	local without: { jecs.Id<any> } = (query :: QueryInner).filter_without
	if without then
		for _, term in without do
			if jecs.IS_PAIR(term) then
				local rel = jecs.ECS_PAIR_FIRST(term)

				local onremoved = world:removed(rel, function(entity, id)
					local r = jecs.record(world, entity)
					local archetype = r.archetype
					local dst = jecs.archetype_traverse_remove(world, id, archetype)

					if archetypes[dst.id] and not archetypes[archetype.id] then
						callback(entity)
					end
				end)
				table.insert(cleanup, onremoved)
			else
				local onremoved = world:removed(term, function(entity, id)
					local r = jecs.record(world, entity)
					local archetype = r.archetype
					local dst = jecs.archetype_traverse_remove(world, id, archetype)
					if archetypes[dst.id] then
						callback(entity)
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
	local terms: { jecs.Entity } = (query :: QueryInner).filter_with or query.ids

	local callback_added: ((jecs.Entity) -> ())?
	local callback_removed: ((jecs.Entity) -> ())?

	local function archetype_changed<a>(entity: jecs.Entity, src: jecs.Archetype, dst: jecs.Archetype)
		if archetypes[dst.id] then
			if not archetypes[src.id] then
				if callback_added then
					callback_added(entity)
				end
			end
		else
			if archetypes[src.id] then
				if callback_removed then
					callback_removed(entity)
				end
			end
		end
	end

	local cleanup = {}

	for _, term in terms do
		if jecs.IS_PAIR(term) then
			local rel = jecs.ECS_PAIR_FIRST(term)

			local onadded = world:added(rel, function(entity, id, _, src)
				if callback_added == nil then
					return
				end
				local r = jecs.record(world, entity :: any)
				local dst = r and r.archetype

				if dst then
					archetype_changed(entity, src, dst)
				end
			end)
			local onremoved = world:removed(rel, function(entity, id)
				if callback_removed == nil then
					return
				end
				local r = jecs.record(world, entity)
				local src = r and r.archetype
				local dst = src and jecs.archetype_traverse_remove(world, id, src)
				if src then
					archetype_changed(entity, src, dst)
				else
					callback_removed(entity)
				end
			end)
			table.insert(cleanup, onadded)
			table.insert(cleanup, onremoved)
		else
			local onadded = world:added(term, function(entity, id, _, src)
				if callback_added == nil then
					return
				end
				local r = jecs.record(world, entity)
				local dst = r and r.archetype

				if dst then
					archetype_changed(entity, src, dst)
				end
			end)
			local onremoved = world:removed(term, function(entity)
				if callback_removed == nil then
					return
				end
				local r = jecs.record(world, entity)
				local archetype = r and r.archetype

				if not archetype or archetypes[archetype.id] then
					callback_removed(entity)
				end
			end)
			table.insert(cleanup, onadded)
			table.insert(cleanup, onremoved)
		end
	end

	local without: { jecs.Id<any> } = (query :: QueryInner).filter_without
	if without then
		for _, term in without do
			if jecs.IS_PAIR(term) then
				local rel = jecs.ECS_PAIR_FIRST(term)

				local onadded = world:added(rel, function(entity, id, _, src)
					if callback_removed == nil then
						return
					end
					local r = jecs.record(world, entity)
					local dst = r.archetype

					if dst then
						archetype_changed(entity, src, dst)
					end
				end)
				local onremoved = world:removed(rel, function(entity, id)
					if callback_added == nil then
						return
					end
					local r = jecs.record(world, entity)
					local src = r.archetype
					local dst = src and jecs.archetype_traverse_remove(world, id, src)
					if dst then
						archetype_changed(entity, src, dst)
					end
				end)
				table.insert(cleanup, onadded)
				table.insert(cleanup, onremoved)
			else
				local onadded = world:added(term, function(entity, id, _, src)
					if callback_removed == nil then
						return
					end

					if archetypes[src.id] then
						callback_removed(entity)
					end
				end)
				local onremoved = world:removed(term, function(entity, id)
					if callback_added == nil then
						return
					end
					local r = jecs.record(world, entity)
					local src = r.archetype
					local dst = src and jecs.archetype_traverse_remove(world, id, src)
					if dst then
						archetype_changed(entity, src, dst)
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
