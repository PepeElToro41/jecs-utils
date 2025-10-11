local jecs = require(script.Parent.jecs)
local common = require(script.common)

local NONE = nil :: any

local jecs_assemblies = {
	transform = (nil :: any) :: jecs.Entity<CFrame>,
	relative = (nil :: any) :: jecs.Entity<CFrame>,
	pivot = (nil :: any) :: jecs.Entity,
}

local set_world = NONE :: jecs.World

function remove_pivot(node: common.Node, parent: common.Node?)
	local assembly = common.assemblies[node.assembly_index]

	if parent then
		parent.children[node] = nil
	end
	node.parent = nil

	if assembly then
		local first = assembly[1]
		local last = assembly[#assembly]
		if first == node then
			local pushed = common.depth_first(first)
			common.assemblies[node.assembly_index] = pushed
		elseif last ~= node then
			common.create_assembly_from(node)

			local old_pushed = common.depth_first(first)
			common.assemblies[first.assembly_index] = old_pushed
		end
	else
		common.create_assembly_from(node)
	end
end

function jecs_assemblies.world(world: jecs.World)
	set_world = world

	if not jecs_assemblies.transform then
		jecs_assemblies.transform = set_world:component()
	end
	if not jecs_assemblies.relative then
		jecs_assemblies.relative = set_world:component()
	end

	if not jecs_assemblies.pivot then
		jecs_assemblies.pivot = set_world:entity()
	end

	common.__alive_tracking__ = set_world:entity()
	common.world = set_world

	set_world:added(jecs_assemblies.pivot, function(entity: jecs.Entity, id)
		local parent = jecs.pair_second(set_world, id)
		local parent_node = common.get_or_create_node(parent)

		local node = common.nodes[entity]

		if node then
			local node_assembly_index = node.assembly_index

			common.move_node_parent(node, parent_node)
			if node.assembly_index ~= parent_node.assembly_index then
				local other_assembly = common.assemblies[node_assembly_index]
				if other_assembly then
					local first = other_assembly[1]
					if first ~= node then
						local other_list = common.depth_first(first)
						common.assemblies[node_assembly_index] = other_list
					else
						common.remove_assembly(node_assembly_index)
					end
				end
			end
			local push_assembly = common.assemblies[parent_node.assembly_index]
			if push_assembly then
				local parent_assembly_index = parent_node.assembly_index
				local first = push_assembly[1]
				local node_list = common.depth_first(first, parent_assembly_index)
				common.assemblies[parent_assembly_index] = node_list
			end
		else
			local push_assembly = common.assemblies[parent_node.assembly_index]
			local new_node: common.Node = {
				entity = entity,
				order_start = 0,
				order_end = 0,
				assembly_index = parent_node.assembly_index,
				children = {},
				parent = parent_node,
			}
			set_world:add(entity, common.__alive_tracking__)
			parent_node.children[new_node] = true

			if push_assembly then
				local first = push_assembly[1]
				local node_list = common.depth_first(first)
				common.assemblies[parent_node.assembly_index] = node_list
			end
			common.nodes[entity] = new_node
		end
	end)

	set_world:removed(jecs_assemblies.pivot, function(entity, id)
		local node = common.nodes[entity]
		if not node then
			return
		end
		local parent = common.nodes[jecs.pair_second(set_world, id)]
		if node.parent == parent then
			return
		end
		remove_pivot(node, parent)
	end)

	set_world:removed(common.__alive_tracking__, function(entity)
		local node = common.nodes[entity]
		if not node then
			return
		end
		remove_pivot(node, node.parent)

		local assemblies: { [any]: true } = {}
		for child in node.children do
			child.parent = nil
			local assembly = common.assemblies[child.assembly_index]
			assemblies[assembly] = true
		end

		for assembly in assemblies do
			local first = assembly[1]
			local second = assembly[2]
			if first == node then
				if second then
					local pushed = common.depth_first(second)
					common.assemblies[second.assembly_index] = pushed
				else
					common.remove_assembly(first.assembly_index)
				end
			else
				local pushed = common.depth_first(first)
				common.assemblies[first.assembly_index] = pushed
			end
		end

		common.nodes[entity] = nil
	end)
end

function jecs_assemblies.system()
	for _, assembly in common.assemblies do
		if #assembly <= 1 then
			continue
		end

		local start = set_world:get(assembly[1].entity, jecs_assemblies.transform) :: CFrame
		if not start then
			continue
		end
		local cframes = {} :: { CFrame }
		local nodes: { common.Node } = {}

		for index, node in assembly do
			local relative = set_world:get(node.entity, jecs_assemblies.relative) or CFrame.identity
			local final = (cframes[#cframes] or start) * relative

			set_world:set(node.entity, jecs_assemblies.transform, final)
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
