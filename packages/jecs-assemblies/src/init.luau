local jecs = require(script.Parent.jecs)
local common = require(script.common)

local jecs_assemblies = {
	transform = (nil :: any) :: jecs.Entity<CFrame>,
	relative = (nil :: any) :: jecs.Entity<CFrame>,
	pivot = (nil :: any) :: jecs.Entity,

	world = (nil :: any) :: jecs.World,
}

function jecs_assemblies.init(world: jecs.World)
	if not jecs_assemblies.transform then
		jecs_assemblies.transform = world:component()
	end

	jecs_assemblies.relative = world:component()
	jecs_assemblies.pivot = world:entity()

	common.__alive_tracking__ = world:entity()

	common.world = world
end

function jecs_assemblies.system()
	local world = jecs_assemblies.world

	for _, assembly in common.assemblies do
		if #assembly <= 1 then
			continue
		end

		local start = world:get(assembly[1].entity, jecs_assemblies.transform) :: CFrame
		if not start then
			continue
		end
		local cframes = {} :: { CFrame }
		local nodes: { common.Node } = {}

		for index, node in assembly do
			local relative = world:get(node.entity, jecs_assemblies.relative) or CFrame.identity
			local final = (cframes[#cframes] or start) * relative

			world:set(node.entity, jecs_assemblies.transform, final)
			table.insert(nodes, node)
			table.insert(cframes, final)

			local latest_node = nodes[#nodes]
			while latest_node and latest_node.order_end == index do
				table.remove(nodes)
				table.remove(cframes)
				latest_node = nodes[#nodes]
			end
		end
	end
end

return jecs_assemblies
