local jecs = require(script.Parent.Parent.jecs)

--- Returns the first entity in the query.
--- @param query: the query to get the first entity from
--- @param predicator: optional filter, if provided, it will return the first entity that matches the predicator
--- @return entity, T... : the first entity in the query and its component values
function query_first<T...>(query: jecs.Query<T...>, predicator: (jecs.Entity, T...) -> boolean?): (jecs.Entity, T...)
	local iterator = query:iter()
	if predicator then
		while true do
			local values = { iterator() }
			if not values[1] then
				break
			end
			if predicator(unpack(values)) then
				return unpack(values) :: any
			end
		end
		return nil :: any
	else
		return iterator()
	end
end

return query_first
