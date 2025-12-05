local jecs = require(script.Parent.Parent.jecs)
local observers = require(script.Parent.observers)

--- Creates iterators tracking entities that entered or left a query's match.
--- @param query: the query to monitor
--- @return { added: an iterator with entities that started matching, removed: an iterator with entities that stopped matching }
local function query_monitored(query: jecs.Query<any>)
	local added_queue = {} :: { jecs.Entity }
	local added_indexes = {} :: { [jecs.Entity]: number }

	local removed_queue = {} :: { jecs.Entity }
	local removed_indexes = {} :: { [jecs.Entity]: number }

	local monitor = observers.monitor(query)

	monitor.added(function(entity: jecs.Entity)
		local index = removed_indexes[entity]
		if index then
			local last = table.remove(removed_queue)
			if last and last ~= entity then
				removed_queue[index] = last
				removed_indexes[last] = index
			end
			removed_indexes[entity] = nil
			return
		end

		index = added_indexes[entity]
		if index then
			return
		end
		table.insert(added_queue, entity)
		added_indexes[entity] = #added_queue
	end)

	monitor.removed(function(entity: jecs.Entity)
		local index = added_indexes[entity]
		if index then
			local last = table.remove(added_queue)
			if last and last ~= entity then
				added_queue[index] = last
				added_indexes[last] = index
			end
			added_indexes[entity] = nil
			return
		end

		index = removed_indexes[entity]
		if index then
			return
		end
		table.insert(removed_queue, entity)
		removed_indexes[entity] = #removed_queue
	end)

	local function added_iter()
		local now_queue = added_queue
		local row = #now_queue
		added_queue = {}
		added_indexes = {}
		return function(): jecs.Entity
			if row == 0 then
				return nil :: any
			end
			local entity = now_queue[row]
			row -= 1
			return entity
		end
	end

	local function removed_iter()
		local now_queue = removed_queue
		local row = #now_queue
		removed_queue = {}
		removed_indexes = {}
		return function(): jecs.Entity
			if row == 0 then
				return nil :: any
			end
			local entity = now_queue[row]
			row -= 1
			return entity
		end
	end

	local function disconnect()
		monitor.disconnect()
	end

	return {
		added = added_iter,
		removed = removed_iter,
		disconnect = disconnect,
	}
end

return query_monitored
