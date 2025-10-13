local jecs = require(script.Parent.Parent.jecs)
local observers = require(script.Parent.observers)

--- Creates an iterator with all the entities where their entity components have changed.
--- @param query: the query to get entities from
--- @return iterator: an iterator with all the entities, can also manually iterate with .iter()
function query_changed(query: jecs.Query<any>)
	local iter_queue = {} :: { jecs.Entity }
	local iter_indexes = {} :: { [jecs.Entity]: number }

	local observer = observers.observer(query, function(entity: jecs.Entity)
		local index = iter_indexes[entity]
		if index then
			return
		end

		table.insert(iter_queue, entity)
		iter_indexes[entity] = #iter_queue
	end)

	local monitor = observers.monitor(query)
	monitor.removed(function(entity)
		local index = iter_indexes[entity]
		if index == nil then
			return
		end

		local last = table.remove(iter_queue)
		if last and last ~= entity then
			iter_queue[index] = last
			iter_indexes[last] = index
		end
		iter_indexes[entity] = nil
	end)

	local function iter()
		local row = #iter_queue
		return function(): jecs.Entity
			if row == 0 then
				table.clear(iter_queue)
				table.clear(iter_indexes)
				return nil :: any
			end
			local entity = iter_queue[row]
			row -= 1
			return entity
		end
	end
	local function disconnect()
		observer.disconnect()
		monitor.disconnect()
	end

	return setmetatable({
		iter = iter,
		disconnect = disconnect,
	}, {
		__iter = iter,
	})
end

return query_changed
