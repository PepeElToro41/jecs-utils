function query_count(query)
	local count = 0
	for _, archetype in query:archetypes() do
		count = count + #archetype.entities
	end
	return count
end

return query_count
