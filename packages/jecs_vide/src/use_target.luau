local vide = require(script.Parent.Parent.vide)
local jecs = require(script.Parent.Parent.jecs)

local source = vide.source
local read = vide.read
local cleanup = vide.cleanup
local effect = vide.effect

local exports = {
	world = (nil :: any) :: jecs.World,
}

type Derivable<T> = (() -> T) | T

function get_target(entity: Derivable<jecs.Entity?>, relation: jecs.Id<any>): jecs.Entity?
	return read(entity) and exports.world:target(read(entity), relation) or nil
end

function useTarget<T>(entity: Derivable<jecs.Entity?>, relation: jecs.Id<T>)
	local target = source(get_target(entity, relation))

	effect(function()
		target(get_target(entity, relation))
		if not read(entity) then
			return
		end

		cleanup(exports.world:added(relation, function(added)
			if added == entity then
				target(get_target(entity, relation))
			end
		end))
		cleanup(exports.world:removed(relation, function(removed)
			if removed == entity then
				task.defer(function()
					target(get_target(entity, relation))
				end)
			end
		end))
	end)

	return target
end

exports.useTarget = useTarget

return exports
