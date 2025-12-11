local vide = require(script.Parent.Parent.vide)
local jecs = require(script.Parent.Parent.jecs)
local jecs_utils = require(script.Parent.Parent["jecs-utils"])

local query_first = jecs_utils.query_first

local source = vide.source
local read = vide.read
local cleanup = vide.cleanup
local effect = vide.effect

local exports = {
	world = (nil :: any) :: jecs.World,
}

type Derivable<T> = (() -> T) | T

function use_query_first<T...>(query: Derivable<jecs.Query<T...>?>, predicator: ((entity: jecs.Entity, T...) -> boolean)?)
	local current = source(nil :: jecs.Entity?)

	effect(function()
		local queryobj = read(query) :: jecs.Query<...any>
		if not queryobj then
			current(nil)
			return
		end
		local monitor = jecs_utils.monitor(queryobj)

		monitor.added(function(e)
			task.defer(function()
				local first = query_first(queryobj, predicator :: any)
				current(first)
			end)
		end)
		monitor.removed(function()
			task.defer(function()
				local first = query_first(queryobj, predicator :: any)
				current(first)
			end)
		end)
		local first = query_first(queryobj, predicator :: any)
		current(first)
		cleanup(monitor.disconnect)
	end)

	return current
end

exports.use_query_first = use_query_first

return exports
