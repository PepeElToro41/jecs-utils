local jecs = require(script.Parent.Parent.jecs)

--- Fast way to gather all entities that match the query into an array.
--- @param query: the query to get entities from
--- @return entities: an array of entities
function query_entities(query: jecs.Query<...any>)
	local entities = {}

	for _, archetype in query:archetypes() do
		table.move(archetype.entities, 1, #archetype.entities, #entities + 1, entities)
	end

	return entities
end

return query_entities
