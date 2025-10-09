local jecs = require(script.Parent.Parent.jecs)

export type Node = {
	entity: jecs.Entity,
	order_start: number,
	order_end: number,
	assembly_index: number,
	children: { [Node]: true },
	parent: Node?,
}

local nodes = {} :: { [jecs.Entity]: Node }
local assemblies = {} :: { { Node } }

local common = {}
common.nodes = nodes
common.assemblies = assemblies
common.world = (nil :: any) :: jecs.World
common.__alive_tracking__ = (nil :: any) :: jecs.Entity

function common.depth_first(
	node: Node,
	assembly_index: number?,
	c_pushed: { Node }?,
	c_visited: { [Node]: boolean }?,
	c_order: number?
)
	local visited = c_visited or { [node] = true } :: { [Node]: boolean }
	local pushed = c_pushed or { node } :: { Node }
	local order = c_order or node.order_start - 1

	for child in node.children do
		if not visited[child] then
			visited[child] = true
			table.insert(pushed, child)
			if assembly_index then
				child.assembly_index = assembly_index
			end
			child.order_start = #pushed + order
			common.depth_first(child, assembly_index, pushed, visited, order)
			child.order_end = #pushed + order
		end
	end
	node.order_end = #pushed + order

	return pushed
end

function common.get_or_create_node(entity: jecs.Entity)
	if not nodes[entity] then
		local new_node = {
			entity = entity,
			order_start = 1,
			order_end = 1,
			assembly_index = #assemblies + 1,
			children = {},
			parent = nil,
		}
		common.world:add(entity, common.__alive_tracking__)
		table.insert(assemblies, { new_node })
		nodes[entity] = new_node
	end
	return nodes[entity]
end

function common.create_assembly_from(node: Node)
	local new_index = #assemblies + 1
	local pushed = common.depth_first(node, new_index)
	assemblies[new_index] = pushed
	return pushed
end

function common.remove_assembly(index: number)
	local last = table.remove(assemblies)
	local remove = assemblies[index]
	if last and last ~= remove then
		for _, node in last do
			node.assembly_index = index
		end
		assemblies[index] = last
	end
	return remove
end

function common.invalidate_nodes(assembly: { Node })
	for _, node in assembly do
		node.assembly_index = -1
	end
end

function common.move_node_parent(node: Node, new_parent: Node)
	if node.parent then
		node.parent.children[node] = nil
	end
	node.parent = new_parent
	new_parent.children[node] = true
end

return common
