function query_first(query, predicator)
	for _, archetype in query:archetypes() do
		if #archetype.entities == 0 then
			continue
		end
		local entity = archetype.entities[1]
		if predicator then
			if predicator(entity) then
				return entity
			end
		else
			return entity
		end
	end
end

return query_first
