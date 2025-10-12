# Jecs Assemblies

Utility for calculating object space CFrame offsets to a final world space CFrame.

### Setup

-  Replace `transform`, `relative`, and `pivot` with your own components. This is optional, and
   components will be created if they don't exist when calling `jecs_assemblies.world`.

-  Call `jecs_assemblies.world(world)` **before using it** to set it up with your world.

-  Add `jecs_assemblies.system()` to your systems. Set the order right before your transform cframes apply.

```luau
local c = require(components)
local jecs_assemblies = require(jecs_assemblies)

jecs_assemblies.transform = c.transform
jecs_assemblies.world(world)

return {
    system = function()
        jecs_assemblies.system()
    end
}
```

### Usage

-  Use `jecs_assemblies.pivot` as a pair to reference a parent entity.
-  Use `jecs_assemblies.relative` to set a relative CFrame to the parent.
-  Transforms will be applied to `jecs_assemblies.transform`. The very first parent will use the value of `jecs_assemblies.transform`.
-  You can chain multiple pivots to get a final transform.

```luau
local c = require(components)
local ja = require(jecs_assemblies)

local character = world:entity()
local camera = world:entity()

world:set(character, c.transform, cf)

world:add(camera, pair(ja.pivot, character))
world:set(camera, c.relative, rel)

-- camera transform = character transform * camera rel
```
