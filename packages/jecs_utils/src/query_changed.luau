local jecs = require(script.Parent.Parent.jecs)
local observers = require(script.Parent.observers)

function query_changed(query: jecs.Query<any>): () -> () -> jecs.Entity
	local iter_queue = {} :: { jecs.Entity }
	local iter_indexes = {} :: { [jecs.Entity]: number }

	observers.observer(query, function(entity: jecs.Entity)
		local index = iter_indexes[entity]
		if index then
			return
		end

		table.insert(iter_queue, entity)
		iter_indexes[entity] = #iter_queue
	end)

	observers.monitor(query).added(function(entity)
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

	return function()
		local row = #iter_queue
		return function()
			if row == 0 then
				table.clear(iter_queue)
				table.clear(iter_indexes)
			end
			local entity = iter_queue[row]
			row -= 1
			return entity
		end
	end
end

return query_changed
