--!nonstrict
--!native
-- Name:		gizmo.lua
-- Version:		2.0 (02/07/23)
-- Author:		Brad Sharp, Ethan Curtis, Christopher Buss
--
-- Repository:	https://github.com/BradSharp/Roblox-Miscellaneous/tree/master/Gizmo
-- License:		MIT
--
-- Copyright (c) 2021-2023 Brad Sharp
-------------------------------------------------------------------------------

local CONTAINER_TAG = "GizmoContainer"
local ADORNEE_TAG = "GizmoAdornee"

local DEFAULT_SCALE = 0.1
local DEFAULT_COLOR = Color3.fromRGB(255, 255, 0)

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local Event = RunService:IsServer() and RunService.Heartbeat or RunService.RenderStepped

-------------------------------------------------------------------------------
-- Type Definitions
-------------------------------------------------------------------------------

type Style = {
	alwaysOnTop: boolean,
	color: Color3,
	layer: number,
	advanced: boolean?,
	transparency: number,
	scale: number,
}

--optional style that will be filled out with global Style
export type OptionalStyle = {
	alwaysOnTop: boolean?,
	color: Color3?,
	layer: number?,
	advanced: boolean?,
	transparency: number?,
	scale: number?,
}

type Gizmo = {
	__properties: { [number]: any, n: number },
	style: Style,
}

-------------------------------------------------------------------------------
-- Internal Variables
-------------------------------------------------------------------------------

local active = false

local scheduledObjects = {}
local renderQueue = {}
local instanceCache = {}

-- Hoarcekat compatibility: Attempt to reuse existing container
local container = CollectionService:GetTagged(CONTAINER_TAG)[1]

if container == nil then
	container = Instance.new("Folder")
	container.Name = "Gizmos"
	container.Archivable = false
	container.Parent = workspace
	CollectionService:AddTag(container, CONTAINER_TAG)
end

-- Using workspace as a PVAdornment's adornee can cause the PVAdornments to
-- shift away from the origin in some cases. Using a part prevents this.
-- Hoarcekat compatibility: Attempt to reuse existing adornee part
local adornee = CollectionService:GetTagged(ADORNEE_TAG)[1]

if adornee == nil then
	adornee = Instance.new("Part")
	adornee.Name = "GizmoAdornee"
	adornee.Anchored = true
	adornee.Archivable = false
	adornee.CanCollide = false
	adornee.CanQuery = false
	adornee.CanTouch = false
	adornee.Locked = true
	adornee.Size = Vector3.one
	adornee.CFrame = CFrame.new()
	adornee.Transparency = 1
	adornee.Parent = workspace
	CollectionService:AddTag(adornee, ADORNEE_TAG)
end

local globalStyle: Style = {
	alwaysOnTop = true,
	color = DEFAULT_COLOR,
	layer = 1,
	advanced = true,
	transparency = 0,
	scale = DEFAULT_SCALE,
}

-------------------------------------------------------------------------------
-- Update Instance Visibility
-------------------------------------------------------------------------------

local instancesBuffer = {}
local frameIndex = 0
--saves instances to disable them on the next frame
local function processBuffer()
	--checks every 2nd frame
	frameIndex = (frameIndex + 1) % 2
	if frameIndex == 1 then
		return
	end

	for instance in instancesBuffer do
		instance.Enabled = false
		instancesBuffer[instance] = nil
	end
end

--ensures that all instances will be disabled if gizmo stops
local function safeCheckBuffer()
	if frameIndex == 0 then
		return
	end
	processBuffer()
end

local function show(instance)
	if instance:IsA("PVAdornment") or instance:IsA("GuiObject") then
		instance.Visible = true
	else
		instancesBuffer[instance] = nil
		instance.Enabled = true
	end
end

--billboard gui requires special handling
local function hide(instance)
	if instance:IsA("PVAdornment") or instance:IsA("GuiObject") then
		instance.Visible = false
	elseif instance:IsA("BillboardGui") then
		instancesBuffer[instance] = true
	else
		instance.Enabled = false
	end
end

-------------------------------------------------------------------------------
-- Instance Caching
-------------------------------------------------------------------------------

local function get(class)
	local classCache = instanceCache[class]
	if not classCache then
		classCache = {}
		instanceCache[class] = classCache
	end
	local instance = table.remove(classCache)
	if not instance then
		instance = Instance.new(class)
		instance.Parent = container
		hide(instance)
	end
	return instance
end

local function release(instance)
	local class = instance.ClassName
	local classCache = instanceCache[class]
	if not classCache then
		classCache = {}
		instanceCache[class] = classCache
	end
	hide(instance)
	table.insert(classCache, instance)
end

-- Hoarcekat compatibility: Release existing children
for _, child in container:GetChildren() do
	release(child)
end
processBuffer()
safeCheckBuffer()

-------------------------------------------------------------------------------
-- Style Instances
-------------------------------------------------------------------------------

local function applyStyleToAdornment(style: Style, adornment)
	adornment.Color3 = style.color
	adornment.Transparency = style.transparency
	adornment.ZIndex = style.layer
	adornment.Adornee = adornee
	adornment.AlwaysOnTop = style.alwaysOnTop
end

local function applyStyleToHighlight(style: Style, highlight)
	highlight.FillColor = style.color
	highlight.OutlineColor = style.color
	highlight.DepthMode = if style.alwaysOnTop
		then Enum.HighlightDepthMode.AlwaysOnTop
		else Enum.HighlightDepthMode.Occluded
end

-------------------------------------------------------------------------------
-- Render Instances
-------------------------------------------------------------------------------

local function renderPoint(style: Style, position: Vector3)
	local adornment = get("SphereHandleAdornment")
	adornment.Radius = style.scale * 0.5
	adornment.CFrame = CFrame.new(position)
	applyStyleToAdornment(style, adornment)
	table.insert(renderQueue, adornment)
end

local function renderBox(style, orientation: CFrame, size: Vector3)
	local adornment = get("BoxHandleAdornment")
	adornment.Size = size
	adornment.CFrame = orientation
	applyStyleToAdornment(style, adornment)
	table.insert(renderQueue, adornment)
end

-- If anyone has a better way to do this which is just as performant please let me know
local function renderWireBox(style, orientation: CFrame, size: Vector3)
	local x, y, z = size.X / 2, size.Y / 2, size.Z / 2
	local lineWidth = style.scale
	local sizeX = Vector3.new(size.X + lineWidth, lineWidth, lineWidth)
	local sizeY = Vector3.new(lineWidth, size.Y + lineWidth, lineWidth)
	local sizeZ = Vector3.new(lineWidth, lineWidth, size.Z + lineWidth)
	local relativeOrientation = orientation
	local adornmentX1 = get("BoxHandleAdornment")
	local adornmentX2 = get("BoxHandleAdornment")
	local adornmentX3 = get("BoxHandleAdornment")
	local adornmentX4 = get("BoxHandleAdornment")
	local adornmentY1 = get("BoxHandleAdornment")
	local adornmentY2 = get("BoxHandleAdornment")
	local adornmentY3 = get("BoxHandleAdornment")
	local adornmentY4 = get("BoxHandleAdornment")
	local adornmentZ1 = get("BoxHandleAdornment")
	local adornmentZ2 = get("BoxHandleAdornment")
	local adornmentZ3 = get("BoxHandleAdornment")
	local adornmentZ4 = get("BoxHandleAdornment")
	adornmentX1.Size = sizeX
	adornmentX1.CFrame = relativeOrientation * CFrame.new(0, y, z)
	adornmentX2.Size = sizeX
	adornmentX2.CFrame = relativeOrientation * CFrame.new(0, -y, z)
	adornmentX3.Size = sizeX
	adornmentX3.CFrame = relativeOrientation * CFrame.new(0, y, -z)
	adornmentX4.Size = sizeX
	adornmentX4.CFrame = relativeOrientation * CFrame.new(0, -y, -z)
	applyStyleToAdornment(style, adornmentX1)
	applyStyleToAdornment(style, adornmentX2)
	applyStyleToAdornment(style, adornmentX3)
	applyStyleToAdornment(style, adornmentX4)
	table.insert(renderQueue, adornmentX1)
	table.insert(renderQueue, adornmentX2)
	table.insert(renderQueue, adornmentX3)
	table.insert(renderQueue, adornmentX4)
	adornmentY1.Size = sizeY
	adornmentY1.CFrame = relativeOrientation * CFrame.new(x, 0, z)
	adornmentY2.Size = sizeY
	adornmentY2.CFrame = relativeOrientation * CFrame.new(-x, 0, z)
	adornmentY3.Size = sizeY
	adornmentY3.CFrame = relativeOrientation * CFrame.new(x, 0, -z)
	adornmentY4.Size = sizeY
	adornmentY4.CFrame = relativeOrientation * CFrame.new(-x, 0, -z)
	applyStyleToAdornment(style, adornmentY1)
	applyStyleToAdornment(style, adornmentY2)
	applyStyleToAdornment(style, adornmentY3)
	applyStyleToAdornment(style, adornmentY4)
	table.insert(renderQueue, adornmentY1)
	table.insert(renderQueue, adornmentY2)
	table.insert(renderQueue, adornmentY3)
	table.insert(renderQueue, adornmentY4)
	adornmentZ1.Size = sizeZ
	adornmentZ1.CFrame = relativeOrientation * CFrame.new(x, y, 0)
	adornmentZ2.Size = sizeZ
	adornmentZ2.CFrame = relativeOrientation * CFrame.new(-x, y, 0)
	adornmentZ3.Size = sizeZ
	adornmentZ3.CFrame = relativeOrientation * CFrame.new(x, -y, 0)
	adornmentZ4.Size = sizeZ
	adornmentZ4.CFrame = relativeOrientation * CFrame.new(-x, -y, 0)
	applyStyleToAdornment(style, adornmentZ1)
	applyStyleToAdornment(style, adornmentZ2)
	applyStyleToAdornment(style, adornmentZ3)
	applyStyleToAdornment(style, adornmentZ4)
	table.insert(renderQueue, adornmentZ1)
	table.insert(renderQueue, adornmentZ2)
	table.insert(renderQueue, adornmentZ3)
	table.insert(renderQueue, adornmentZ4)
end

local function renderSphere(style, position: Vector3, radius: number)
	local adornment = get("SphereHandleAdornment")
	adornment.Radius = radius
	adornment.CFrame = CFrame.new(position)
	applyStyleToAdornment(style, adornment)
	table.insert(renderQueue, adornment)
end

local function renderWireSphere(style, position: Vector3, radius: number)
	local offset = style.scale * 0.5
	local outerRadius, innerRadius = radius + offset, radius - offset
	local relativeOrientation = CFrame.new(position)
	local adornmentX = get("CylinderHandleAdornment")
	local adornmentY = get("CylinderHandleAdornment")
	local adornmentZ = get("CylinderHandleAdornment")
	adornmentX.Radius = outerRadius
	adornmentX.InnerRadius = innerRadius
	adornmentX.Height = style.scale
	adornmentX.CFrame = relativeOrientation
	applyStyleToAdornment(style, adornmentX)
	table.insert(renderQueue, adornmentX)
	adornmentY.Radius = outerRadius
	adornmentY.InnerRadius = innerRadius
	adornmentY.Height = style.scale
	adornmentY.CFrame = relativeOrientation * CFrame.Angles(math.pi * 0.5, 0, 0)
	applyStyleToAdornment(style, adornmentY)
	table.insert(renderQueue, adornmentY)
	adornmentZ.Radius = outerRadius
	adornmentZ.InnerRadius = innerRadius
	adornmentZ.Height = style.scale
	adornmentZ.CFrame = relativeOrientation * CFrame.Angles(0, math.pi * 0.5, 0)
	applyStyleToAdornment(style, adornmentZ)
	table.insert(renderQueue, adornmentZ)
end

local function renderLine(style, from: Vector3, to: Vector3)
	local distance = (to - from).Magnitude
	local adornment = get("CylinderHandleAdornment")
	adornment.Radius = style.scale * 0.5
	adornment.InnerRadius = 0
	adornment.Height = distance
	adornment.CFrame = CFrame.lookAt(from, to) * CFrame.new(0, 0, -distance * 0.5)
	applyStyleToAdornment(style, adornment)
	table.insert(renderQueue, adornment)
end

local function renderArrow(style, from: Vector3, to: Vector3)
	local coneHeight = style.scale * 3
	local distance = math.abs((to - from).Magnitude - coneHeight)
	local orientation = CFrame.lookAt(from, to)
	local adornmentLine = get("CylinderHandleAdornment")
	local adornmentCone = get("ConeHandleAdornment")
	adornmentLine.Radius = style.scale * 0.5
	adornmentLine.InnerRadius = 0
	adornmentLine.Height = distance
	adornmentLine.CFrame = orientation * CFrame.new(0, 0, -distance * 0.5)
	applyStyleToAdornment(style, adornmentLine)
	adornmentCone.Height = coneHeight
	adornmentCone.Radius = coneHeight * 0.5
	adornmentCone.CFrame = orientation * CFrame.new(0, 0, -distance)
	applyStyleToAdornment(style, adornmentCone)
	table.insert(renderQueue, adornmentLine)
	table.insert(renderQueue, adornmentCone)
end

local function renderRay(style, from: Vector3, direction: Vector3)
	return renderArrow(style, from, from + direction)
end

local function renderCFrame(style, cf: CFrame)
	renderPoint(style, cf.Position)

	if style.advanced then
		local newStyle = table.clone(style)

		newStyle.color = Color3.fromRGB(255, 103, 103)
		newStyle.scale = style.scale * 0.5

		renderArrow(newStyle, cf.Position, cf.Position + cf.RightVector * 0.5)
		newStyle.color = Color3.fromRGB(103, 255, 103)
		renderArrow(newStyle, cf.Position, cf.Position + cf.UpVector * 0.5)
		newStyle.color = Color3.fromHSV(0.636289, 0.796078, 1)
		renderArrow(newStyle, cf.Position, cf.Position + cf.LookVector * 0.5)
	end
end

local function renderPlane(style, cf: CFrame, size: Vector2?)
	size = size or Vector2.new(10, 10)
	local adornmentPlane = get("BoxHandleAdornment")
	adornmentPlane.CFrame = cf
	adornmentPlane.Size = Vector3.new((size :: Vector2).X, (size :: Vector2).Y, 0)
	applyStyleToAdornment(style, adornmentPlane)
	table.insert(renderQueue, adornmentPlane)
end

local function renderText(style, position: Vector3, text: string, ...)
	local safeText = tostring(text):format(...)
	local billboard = get("BillboardGui")
	local label = get("TextLabel")
	local textScale = style.scale * 8
	billboard.AlwaysOnTop = style.alwaysOnTop
	billboard.StudsOffsetWorldSpace = position
	billboard.Size = UDim2.fromScale(safeText:len() * 0.5 * textScale, textScale)
	billboard.LightInfluence = 0
	billboard.Adornee = adornee
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.RobotoMono
	label.TextColor3 = style.color
	label.TextTransparency = style.transparency
	label.TextScaled = true
	label.Text = safeText
	label.Parent = billboard
	table.insert(renderQueue, label)
	table.insert(renderQueue, billboard)
end

-------------------------------------------------------------------------------
-- Gizmo Class Wrapper
-------------------------------------------------------------------------------

local function fillOutStyle(optionalStyle: OptionalStyle)
	--avoids cloning table if gizmo is disabled
	if not active then
		return globalStyle
	end
	if optionalStyle == globalStyle then
		return globalStyle
	end

	local style = table.clone(globalStyle)
	for key, value in optionalStyle do
		style[key] = value
	end
	return style
end

local function createGizmo<T...>(render: (Style, T...) -> ())
	local class = { __index = {} }

	function class.draw(...: T...)
		if active then
			render(globalStyle, ...)
		end
	end

	function class.drawWithStyle(style: OptionalStyle, ...: T...)
		if active then
			render(fillOutStyle(style), ...)
		end
	end

	type Object = typeof(setmetatable({} :: Gizmo, class))

	function class.create(...: T...): Object
		return setmetatable({
			__properties = table.pack(...),
			style = table.clone(globalStyle),
		}, class)
	end

	function class.createWithStyle(style: OptionalStyle, ...: T...): Object
		return setmetatable({
			__properties = table.pack(...),
			style = fillOutStyle(style),
		}, class)
	end

	function class.__index:enable()
		scheduledObjects[self] = true
	end

	function class.__index:setStyle(optional_style: OptionalStyle)
		self.style = fillOutStyle(optional_style)
		return self
	end

	function class.__index:getStyle()
		return table.clone(self.style)
	end

	function class.__index:disable()
		scheduledObjects[self] = nil
	end

	function class.__index:update(...: T...)
		self.__properties = table.pack(...)
	end

	function class.__index:__render()
		render(self.style, table.unpack(self.__properties))
	end

	return table.freeze(class)
end

-------------------------------------------------------------------------------
-- Render Update
-------------------------------------------------------------------------------

local function update()
	-- All gizmos created with 'create' need to be queued for render
	for object in pairs(scheduledObjects) do
		object:__render()
	end
	-- Clone the queue and render all instances in it
	local queue = table.clone(renderQueue)
	for _, instance in ipairs(queue) do
		show(instance)
	end
	table.clear(renderQueue)
	task.wait()
	for _, instance in ipairs(queue) do
		release(instance)
	end
	processBuffer()
end

-------------------------------------------------------------------------------
-- State Management
-------------------------------------------------------------------------------

local onRender = nil

local function enable()
	active = true
	onRender = Event:Connect(update)
end

local function disable()
	active = false
	if onRender then
		onRender:Disconnect()
		onRender = nil
		safeCheckBuffer()
	end
end

enable()

-------------------------------------------------------------------------------
-- Exports
-------------------------------------------------------------------------------

return table.freeze({
	-- Globals
	style = globalStyle,

	-- Functions
	enable = enable,
	disable = disable,

	-- Gizmos
	point = createGizmo(renderPoint),
	cframe = createGizmo(renderCFrame),
	box = createGizmo(renderBox),
	wirebox = createGizmo(renderWireBox),
	sphere = createGizmo(renderSphere),
	wiresphere = createGizmo(renderWireSphere),
	line = createGizmo(renderLine),
	arrow = createGizmo(renderArrow),
	ray = createGizmo(renderRay),
	plane = createGizmo(renderPlane),
	text = createGizmo(renderText),
})
