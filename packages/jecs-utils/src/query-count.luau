local jecs = require(script.Parent.Parent.jecs)

function query_count(query: jecs.Query<...any>): number
	local count = 0
	for _, archetype in query:archetypes() do
		count = count + #archetype.entities
	end
	return count
end

return query_count
