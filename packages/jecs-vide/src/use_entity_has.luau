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

function get_tag(entity: Derivable<jecs.Entity?>, tag: jecs.Entity)
	return if read(entity) then exports.world:has(read(entity), tag) else false
end

function useEntityHas(entity: Derivable<jecs.Entity?>, tag: jecs.Entity)
	local is_tagged = source(get_tag(entity, tag))

	effect(function()
		is_tagged(get_tag(entity, tag))
		cleanup(exports.world:added(tag, function(added)
			if added == read(entity) then
				is_tagged(get_tag(entity, tag))
			end
		end))
		cleanup(exports.world:removed(tag, function(removed)
			if removed == read(entity) then
				task.defer(function()
					is_tagged(get_tag(entity, tag))
				end)
			end
		end))
	end)

	return is_tagged
end

exports.useEntityHas = useEntityHas

return exports
