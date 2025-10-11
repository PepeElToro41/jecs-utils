local jecs = require(script.Parent.jecs)
local lib = require(script.gizmo)

export type Style = lib.OptionalStyle

type Debug = {
	cframe: jecs.Entity<Style?>,
	position: jecs.Entity<Style?>,
	direction: jecs.Entity<Style?>,
	distance: jecs.Entity<Style?>,
}

local NONE = nil :: any
local set_world = NONE :: jecs.World

local gizmo = {
	cframe = nil :: jecs.Entity<CFrame>?,
	position = nil :: jecs.Entity<Vector3>?,
	direction = nil :: jecs.Entity<Vector3>?,
	enabled = true,

	debug = NONE :: Debug,
}

function gizmo.world(world: jecs.World)
	if gizmo.debug then
		return
	end
	set_world = world

	local debug: Debug = {
		cframe = set_world:component(),
		position = set_world:component(),
		direction = set_world:component(),
		distance = set_world:component(),
		lookvector = set_world:component(),
	}
	gizmo.queries = {}

	if gizmo.cframe then
		gizmo.queries.cframe = set_world:query(gizmo.cframe, debug.cframe):cached()
		gizmo.queries.position_cframe = set_world:query(gizmo.cframe, debug.position):cached()
		gizmo.queries.distance_cframe = set_world:query(gizmo.cframe, jecs.pair(debug.distance, jecs.Wildcard)):cached()
	end
	if gizmo.position then
		gizmo.queries.position = set_world:query(gizmo.position, debug.position):cached()
		gizmo.queries.distance = set_world:query(gizmo.position, jecs.pair(debug.distance, jecs.Wildcard)):cached()
	end
	if gizmo.direction then
		if gizmo.position then
			gizmo.queries.direction = set_world:query(gizmo.position, gizmo.direction, debug.direction):cached()
		end
		if gizmo.cframe then
			gizmo.queries.direction_cframe = set_world:query(gizmo.cframe, gizmo.direction, debug.direction):cached()
		end
	end
end

function draw_distance(from: Vector3, to: Vector3, style: Style?)
	style = style or lib.style
	lib.point.drawWithStyle(style, from)
	lib.point.drawWithStyle(style, to)
	lib.arrow.drawWithStyle(style, from, to)
	local render = from:Lerp(to, 0.5) + Vector3.new(0, 4, 0)

	lib.text.drawWithStyle(style, render, "%.2f studs", (to - from).Magnitude)
end

function gizmo.system()
	if not gizmo.enabled then
		return
	end

	if gizmo.cframe then
		for _, cframe, style in gizmo.queries.cframe:iter() do
			lib.cframe.drawWithStyle(style, cframe)
		end
		for _, cframe, style in gizmo.queries.position_cframe:iter() do
			lib.point.drawWithStyle(style, cframe.Position)
		end
		for e, cframe, style in gizmo.queries.distance_cframe:iter() do
			local to = set_world:target(e, gizmo.debug.distance)
			if not to then
				continue
			end
			local to_cframe = set_world:get(to, gizmo.cframe)
			if to_cframe then
				draw_distance(cframe.Position, to_cframe.Position)
			else
				if gizmo.position then
					local to_position = set_world:get(to, gizmo.position)
					if to_position then
						draw_distance(cframe.Position, to_position)
					end
				end
			end
		end
	end
	if gizmo.position then
		for _, position, style in gizmo.queries.position:iter() do
			lib.point.drawWithStyle(style, position)
		end
		for e, position, style in gizmo.queries.distance:iter() do
			local to = set_world:target(e, gizmo.debug.distance)
			if not to then
				continue
			end
			local to_position = set_world:get(to, gizmo.position)
			if to_position then
				draw_distance(position, to_position)
			else
				if gizmo.cframe then
					local to_cframe = set_world:get(to, gizmo.cframe)
					if to_cframe then
						draw_distance(position, to_cframe.Position)
					end
				end
			end
		end
	end
	if gizmo.queries.direction then
		for _, position, direction, style in gizmo.queries.direction:iter() do
			lib.arrow.drawWithStyle(style, position, position + direction)
		end
	end
	if gizmo.queries.direction_cframe then
		for _, cframe, direction, style in gizmo.queries.direction_cframe:iter() do
			lib.arrow.drawWithStyle(style, cframe.Position, cframe.Position + cframe.LookVector)
		end
	end
end

return gizmo
