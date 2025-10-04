local jecs = require(script.Parent.Parent.jecs)
local vide = require(script.Parent.Parent.vide)

type Derivable<T> = (() -> T) | T

local source = vide.source
local effect = vide.effect
local read = vide.read
local cleanup = vide.cleanup

local exports = {
	world = (nil :: any) :: jecs.World,
}

function get_component<T>(entity: Derivable<jecs.Entity?>, component: jecs.Entity<T>): T?
	return if read(entity) then exports.world:get(read(entity), component) else nil
end

function useEntityGet<T>(entity: Derivable<jecs.Entity?>, component: jecs.Entity<T>): () -> T?
	local output = source() :: vide.Source<T?>

	effect(function()
		output(get_component(entity, component))
		cleanup(exports.world:added(component, function(e, component, value)
			if e == read(entity) then
				output(value)
			end
		end))
		cleanup(exports.world:changed(component, function(e, component, value)
			if e == read(entity) then
				output(value)
			end
		end))
		cleanup(exports.world:removed(component, function(e, component)
			if e == read(entity) then
				output(nil)
			end
		end))
	end)

	return output
end

exports.useEntityGet = useEntityGet

return exports
