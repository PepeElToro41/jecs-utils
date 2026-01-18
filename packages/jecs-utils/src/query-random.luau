local jecs = require(script.Parent.Parent.jecs)

--- Fast way to get a random entity from the query. This also returns its component values.
--- @param query: the query to get a random entity from
--- @return entity, T... : the random entity and its component values
function query_random<T...>(query: jecs.Query<T...>): (jecs.Entity, T...)
	local size = 0

	local archetypes = query:archetypes()

	for _, archetype in archetypes do
		size = size + #archetype.entities
	end

	if size == 0 then
		return nil :: any
	end

	local random = math.random(1, size)
	local target_row: number = nil :: any
	local target_archetype: jecs.Archetype = nil :: any
	local target: jecs.Entity = nil :: any

	for _, archetype in archetypes do
		local entities = archetype.entities
		if random <= #entities then
			target_archetype = archetype
			target = entities[random]
			target_row = random
			break
		end
		random -= #entities
	end

	if not target_archetype then
		return nil :: any
	end

	local A, B, C, D, E, F, G, H, I = unpack(query.ids)
	local columns_map = target_archetype.columns_map

	if not A then
		return target
	elseif not B then
		local a = columns_map[A]
		return target, a[target_row]
	elseif not C then
		local a = columns_map[A]
		local b = columns_map[B]
		return target, a[target_row], b[target_row]
	elseif not D then
		local a = columns_map[A]
		local b = columns_map[B]
		local c = columns_map[C]
		return target, a[target_row], b[target_row], c[target_row]
	elseif not E then
		local a = columns_map[A]
		local b = columns_map[B]
		local c = columns_map[C]
		local d = columns_map[D]
		return target, a[target_row], b[target_row], c[target_row], d[target_row]
	elseif not F then
		local a = columns_map[A]
		local b = columns_map[B]
		local c = columns_map[C]
		local d = columns_map[D]
		local e = columns_map[E]
		return target, a[target_row], b[target_row], c[target_row], d[target_row], e[target_row]
	elseif not G then
		local a = columns_map[A]
		local b = columns_map[B]
		local c = columns_map[C]
		local d = columns_map[D]
		local e = columns_map[E]
		local f = columns_map[F]
		return target, a[target_row], b[target_row], c[target_row], d[target_row], e[target_row], f[target_row]
	elseif not H then
		local a = columns_map[A]
		local b = columns_map[B]
		local c = columns_map[C]
		local d = columns_map[D]
		local e = columns_map[E]
		local f = columns_map[F]
		local g = columns_map[G]
		return target,
			a[target_row],
			b[target_row],
			c[target_row],
			d[target_row],
			e[target_row],
			f[target_row],
			g[target_row]
	elseif not I then
		local a = columns_map[A]
		local b = columns_map[B]
		local c = columns_map[C]
		local d = columns_map[D]
		local e = columns_map[E]
		local f = columns_map[F]
		local g = columns_map[G]
		local h = columns_map[H]
		return target,
			a[target_row],
			b[target_row],
			c[target_row],
			d[target_row],
			e[target_row],
			f[target_row],
			g[target_row],
			h[target_row]
	else
		local a = columns_map[A]
		local b = columns_map[B]
		local c = columns_map[C]
		local d = columns_map[D]
		local e = columns_map[E]
		local f = columns_map[F]
		local g = columns_map[G]
		local h = columns_map[H]

		local ids = query.ids
		local output = {} :: { any }
		local len = #ids
		for i = 9, len do
			output[i - 8] = columns_map[ids[i]]
		end

		return target,
			a[target_row],
			b[target_row],
			c[target_row],
			d[target_row],
			e[target_row],
			f[target_row],
			g[target_row],
			h[target_row],
			unpack(output)
	end
end

return query_random
