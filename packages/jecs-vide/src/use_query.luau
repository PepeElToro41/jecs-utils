local vide = require(script.Parent.Parent.vide)
local jecs = require(script.Parent.Parent.jecs)
local observers = require(script.Parent.observers)
local query_first = require(script.Parent.query_first)

local source = vide.source
local read = vide.read
local cleanup = vide.cleanup
local effect = vide.effect

local exports = {
	world = (nil :: any) :: jecs.World,
}

type Derivable<T> = (() -> T) | T

function useQuery<T...>(query: Derivable<jecs.Query<...any>?>?): () -> { jecs.Entity }
	local entities = {} :: { jecs.Entity }
	local entity_map = {} :: { [jecs.Entity]: number }

	local state = source(entities)

	effect(function()
		local query = read(query)

		table.clear(entities)
		table.clear(entity_map)
		if not query then
			state(entities)
			return
		end
		for entity in query:iter() do
			table.insert(entities, entity)
			entity_map[entity] = #entities
		end
		state(entities)

		local monitor = observers.monitor(query)
		monitor.added(function(entity)
			if entity_map[entity] then
				return
			end
			table.insert(entities, entity)
			entity_map[entity] = #entities
			state(entities)
		end)

		monitor.removed(function(entity)
			local index = entity_map[entity]
			if not index then
				return
			end
			entity_map[entity] = nil
			local latest = table.remove(entities)
			if not latest then
				state(entities)
				return
			end
			if latest == entity then
				state(entities)
				return
			end
			entities[index] = latest
			entity_map[latest] = index
			state(entities)
		end)

		cleanup(monitor.disconnect)
	end)

	return state
end

exports.useQuery = useQuery

return exports
