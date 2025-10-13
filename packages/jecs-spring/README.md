# Jecs Spring

Utility for running springs in Jecs.

### Setup

-  Call `jecs_spring.world(world)` **before using it** to set it up with your world.

-  Add `jecs_spring.system(delta)` to your systems. Set the order right before your component values apply. This system needs the delta time to step the springs.

```luau
local c = require(components)
local jecs_spring = require(jecs_spring)

jecs_spring.world(world)

return {
    system = function(delta: number)
        jecs_spring.system(delta)
    end
}
```

### Usage

-  Use `jecs_spring.goal` as a pair to set your goal value.

-  The target should be the component you want to interpolate

-  The value of the pair should be the goal value. This value should be any of ripple `Animatable` types `(number | vector | Vector3 | Vector2 | CFrame | Color3 | UDim | UDim2 | Rect)`.

```luau
local spring = require(jecs_spring)

local cube = world:entity()

world:set(cube, c.size, Vector3.new(1, 1, 1))
world:set(cube, pair(spring.goal, c.size), Vector3.new(2, 2, 2))

-- cube will go from 1 -> 2
```

### Configuring the spring.

-  Use `jecs_spring.options` as a pair to set the options for the spring. Similar to jecs.goal, the target is the component's spring you want to configure.

-  Its recommended that you set the options before the goal so the spring starts with the correct configuration.

```luau
local spring = require(jecs_spring)

local cube = world:entity()

world:set(cube, c.size, Vector3.new(1, 1, 1))
world:set(cube, pair(spring.options, c.size), { friction = 30, tension = 800 })
world:set(cube, pair(spring.goal, c.size), Vector3.new(2, 2, 2))

-- cube will go from 1 -> 2 with a friction of 30 and tension of 800
```

### Manipulating the spring object.

-  The spring object is stored in a `jecs_spring.motion` pair. The target is the component's spring.

-  The spring object is available right after you set the goal.

-  The spring object is destroyed when the goal is removed.

```luau
local spring = require(jecs_spring)

local cube = world:entity()

world:set(cube, c.size, Vector3.new(1, 1, 1))
world:set(cube, pair(spring.goal, c.size), Vector3.new(2, 2, 2))

local spring_motion = world:get(cube, pair(spring.motion, c.size))
spring_motion:impulse(Vector3.new(5, 5, 5))

```

### Checking spring completion.

-  Springs that have completed will be marked with a `jecs_spring.completed` pair. The target is the component's spring.

-  The completed pair is removed if you change the goal.

-  The completed pair is removed if you remove the goal.

```luau
local spring = require(jecs_spring)

local cube = world:entity()
world:set(cube, c.size, Vector3.new(3, 3, 3))

task.wait(2)
-- animate out
world:set(cube, pair(spring.goal, c.size), Vector3.zero)

function system()
    for entity in world:query(pair(spring.completed, c.size)) do
        world:delete(entity)
    end
end
```
