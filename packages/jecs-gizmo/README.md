# Jecs Gizmo

Utility for debug gizmos for Jecs.

### Setup

-   Set all your components that you want to debug. Components that are not provided will not be usable. These are available.

    -   `transform` for CFrames
    -   `position` for Vector3 positions
    -   `direction` for Vector3 directions

-   Call `jecs_gizmo.world(world)` **before using it** to set it up with your world.

-   Add `jecs_gizmo.system()` to your systems. Set the order after all your components are set so your gizmos show the up to date values.

```luau
local c = require(components)
local jecs_gizmo = require(jecs_gizmo)

jecs_gizmo.cframe = c.transform
jecs_gizmo.position = c.position
jecs_gizmo.direction = c.direction

jecs_gizmo.world(world)

return {
    system = function()
        jecs_gizmo.system()
    end
}
```

### Usage

Use the components inside `jecs_gizmo.gizmo` to draw gizmos.

    -  `jecs_gizmo.gizmo.cframe` for to draw CFrames. This draws the position and all of the direction vectors.
    -  `jecs_gizmo.gizmo.position` for to draw positions, This also works with cframes, Drawing only the position.
    -  `jecs_gizmo.gizmo.direction` for to draw directions. This also requires the component to have a position or cframe to draw where the direction starts from.
    -  `jecs_gizmo.gizmo.distance` for to draw distances. This is used as a pair and it calculates the distance between the entity and the target. This requires both entities to have a position or cframe. And they can be mixed up. Like the entity having a cframe and the target having a position.
    - `jecs_gizmo.gizmo.lookvector` for to draw the CFrame's LookVector as an arrow from the CFrame's position.

```luau
local gizmo = require(jecs_gizmo).gizmo


-- [[ cframes ]]
local cube = world:entity()
world:set(cube, c.transform, CFrame.new(1, 1, 1))

world:add(cube, gizmo.cframe)
-- also works
world:add(cube, gizmo.position)


-- [[ positions ]]
local cube = world:entity()

world:set(cube, c.position, Vector3.new(1, 1, 1))
world:add(cube, gizmo.position)


-- [[ directions ]]
local cube = world:entity()
world:set(cube, c.transform, CFrame.new(2, 2, 2))
world:set(cube, c.direction, Vector3.new(0, 1, 0))
-- also works
world:set(cube, c.position, Vector3.new(0, 1, 0))

world:add(cube, gizmo.direction)


-- [[ distances ]]
local cube1 = world:entity()
local cube2 = world:entity()

-- works with any combination of cframes and positions
world:set(cube1, c.position, Vector3.new(1, 1, 1))
world:set(cube2, c.cframe, Vector3.new(10, 10, 10))

world:add(cube1, pair(gizmo.distance, cube2))


-- [[ lookvectors ]]
local cube = world:entity()
world:set(cube, c.transform,
    CFrame.new(1, 1, 1) * CFrame.Angles(0, math.pi / 2, 0)
)

world:add(cube, gizmo.lookvector)
```

### Configuring the gizmo.

-   All of the `jecs_gizmo.gizmo` components accept a `Style` as a value. You can set this to change the style of the gizmo. A nil value will use the default style as well as an empty table.

```luau
local gizmo = require(jecs_gizmo).gizmo

local cube = world:entity()
world:set(cube, c.transform, CFrame.new(1, 1, 1))

world:set(cube, gizmo.cframe, {
    scale = true,
})
world:set(cube, gizmo.lookvector, {
    alwaysOnTop = true,
})

-- this is the equivalent of setting it to nil or using world:add instead
world:set(cube, gizmo.position, {})
```

### Disabling the gizmo.

-   You can change `jecs_gizmo.enabled` to enable or disable the gizmo. You can modify it at any time.

```luau
local RunService = game:GetService("RunService")
local jecs_gizmo = require(jecs_gizmo)

function enable_gizmo()
    jecs_gizmo.enabled = true
end

function disable_gizmo()
    jecs_gizmo.enabled = false
end

jecs_gizmo.enabled = RunService:IsStudio()
```
