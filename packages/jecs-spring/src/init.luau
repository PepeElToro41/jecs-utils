local jecs = require(script.Parent.jecs)
local ripple = require(script.Parent.ripple)

local NONE = nil :: any

local jecs_spring = {
	options = NONE :: jecs.Entity<ripple.SpringOptions>,
	goal = NONE :: jecs.Entity,
	completed = NONE :: jecs.Entity,
	motion = NONE :: jecs.Entity<ripple.Spring>,

	__spring_target = NONE :: jecs.Entity,
	__spring_controller = NONE :: jecs.Entity<jecs.Entity>,
	__spring_target_info = NONE :: jecs.Entity<{ entity: jecs.Entity, component: jecs.Entity }>,
}

local set_world = NONE :: jecs.World

function get_spring_query()
	return set_world
		:query(jecs.pair(jecs_spring.motion, jecs.Wildcard), jecs_spring.__spring_target_info)
		:with(jecs_spring.__spring_target)
		:without(jecs.pair(jecs_spring.completed, jecs.Wildcard))
		:cached()
end

local spring_query = NONE :: typeof(get_spring_query())

function jecs_spring.world(world: jecs.World)
	set_world = world

	jecs_spring.options = set_world:component()
	jecs_spring.goal = set_world:entity()
	jecs_spring.completed = set_world:entity()
	jecs_spring.motion = set_world:component()

	jecs_spring.__spring_target = set_world:entity()
	jecs_spring.__spring_controller = set_world:component()
	jecs_spring.__spring_target_info = set_world:component()

	spring_query = get_spring_query()

	local function spring_options_changed(entity: jecs.Entity, id: jecs.Entity, options: ripple.SpringOptions?)
		local component = jecs.pair_second(set_world, id)
		local motion = set_world:get(entity, jecs.pair(jecs_spring.motion, component))
		local goal = set_world:get(entity, jecs.pair(jecs_spring.goal, component))

		if motion and goal then
			motion:setGoal(goal, options or {})
		else
			if motion then
				motion:configure(options or {})
			end
		end
	end

	set_world:added(jecs_spring.options, spring_options_changed)
	set_world:changed(jecs_spring.options, spring_options_changed)
	set_world:removed(jecs_spring.options, spring_options_changed)

	set_world:added(jecs_spring.goal, function(entity: jecs.Entity, id, goal)
		local component = jecs.pair_second(set_world, id)
		local start = set_world:get(entity, component)
		local handler = set_world:entity()

		local motion = ripple.createSpring(start or goal)

		motion:onComplete(function()
			local goal = set_world:get(entity, jecs.pair(jecs_spring.goal, component))
			set_world:add(entity, jecs.pair(jecs_spring.completed, component))
			set_world:add(handler, jecs.pair(jecs_spring.completed, component))
			set_world:set(entity, component, goal)
		end)

		local options = set_world:get(entity, jecs.pair(jecs_spring.options, component))
		motion:setGoal(goal, options)

		set_world:set(entity, jecs.pair(jecs_spring.__spring_controller, component), handler)
		set_world:set(entity, jecs.pair(jecs_spring.motion, component), motion)

		set_world:set(handler, jecs.pair(jecs_spring.motion, component), motion)
		set_world:set(handler, jecs_spring.__spring_target_info, { entity = entity, component = component })
		set_world:add(handler, jecs_spring.__spring_target)
	end)

	set_world:changed(jecs_spring.goal, function(entity, id, goal)
		local component = jecs.pair_second(set_world, id)
		local motion = set_world:get(entity, jecs.pair(jecs_spring.motion, component))

		if motion then
			if motion.state.goal ~= goal then
				motion:setGoal(goal)
				local handler = set_world:get(entity, jecs.pair(jecs_spring.__spring_controller, component))

				set_world:remove(entity, jecs.pair(jecs_spring.completed, component))
				if handler then
					set_world:remove(handler, jecs.pair(jecs_spring.completed, component))
				end
			end
		end
	end)

	set_world:removed(jecs_spring.goal, function(entity, id)
		local component = jecs.pair_second(set_world, id)
		local handler = set_world:get(entity, jecs.pair(jecs_spring.__spring_controller, component))
		local motion = set_world:get(entity, jecs.pair(jecs_spring.motion, component))

		if motion then
			motion:destroy()
			set_world:remove(entity, jecs.pair(jecs_spring.motion, component))
		end
		if handler then
			set_world:delete(handler)
			set_world:remove(entity, jecs.pair(jecs_spring.__spring_controller, component))
		end
	end)
end

function jecs_spring.system(delta: number)
	for _, motion, target in spring_query:iter() do
		set_world:set(target.entity, target.component, motion:step(delta))
	end
end

return jecs_spring
