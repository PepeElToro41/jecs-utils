--!optimize 2
local jecs = require(script.Parent.Parent.jecs)
local refs: { [any]: any } = {}

local set_world = (nil :: any) :: jecs.World

--- Gets an entity the given key references to.
--- If the key is nil, an entirely new entity is created and returned.
--- If the key doesn't reference an entity, a new entity is made for it to reference and returned.
--- @param key: key to reference
--- @param initer: function to initialize the entity, this only gets called if the key doesn't reference an entity
--- @return Entity: the entity referenced by the key or a new entity
local function ref(key: any, initer: ((entity: jecs.Entity) -> ())?): jecs.Entity
	if not key then
		local entity = set_world:entity()
		if initer then
			initer(entity)
		end
		return entity
	end

	local entity = refs[key]
	if not entity then
		entity = set_world:entity()

		if initer then
			initer(entity)
		end

		refs[key] = entity
	end

	return entity
end

local function __call(_, key: any, initer: (entity: jecs.Entity) -> ())
	return ref(key, initer)
end

--- Search for an entity referenced by the given key.
--- This will not not create a new entity if the key doesn't exist.
--- @param key: the key to search for
--- @return entity: the entity referenced by the key
local function find(key: any): jecs.Entity?
	if not key then
		return nil
	end
	local entity = refs[key]

	if not entity then
		return nil
	end

	return entity
end

--- Modifies the entity that a key references to.
--- @param key: the key to modify
--- @param entity: the entity to reference
function set(key: any, entity: jecs.Entity)
	refs[key] = entity
end

function delete(key: any)
	if not key then
		return
	end
	refs[key] = nil
end

function world(wrld: jecs.World)
	set_world = wrld
end

local metatable = {
	__call = __call,
}

local lib = {
	get = ref,
	set = set,
	find = find,
	delete = delete,
	world = world,
}

local REF = (setmetatable :: any)(lib, metatable) :: typeof(ref) & typeof(setmetatable(lib, metatable))

return REF
