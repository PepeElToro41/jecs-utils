local jecs = require(script.Parent.Parent.jecs)
local NONE = nil :: any

local is_a = {
	is_a = NONE :: jecs.Entity,
}

local set_world = NONE :: jecs.World

function is_a.world(world: jecs.World)
	set_world = world
	is_a.is_a = world:entity()

	world:added(is_a.is_a, function(component, id)
		local second = jecs.pair_second(world, id)
		assert(second ~= component, "circular isA inheritance")

		local is_tag = jecs.is_tag(world, second)
		set_world:added(component, function(entity, _, value)
			if is_tag then
				world:add(entity, second)
			else
				world:set(entity, second, value)
			end
		end)

		world:removed(component, function(entity)
			world:remove(entity, second)
		end)

		if not is_tag then
			world:changed(component :: any, function(entity, _, value)
				world:set(entity, second, value)
			end)
		end
	end)
end

return is_a
