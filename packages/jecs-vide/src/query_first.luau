function query_first(query, predicator)
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
