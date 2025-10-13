local jecs = require(script.Parent.Parent.jecs.jecs)

export type World = jecs.World
export type Entity<T = any> = jecs.Entity<T>

return jecs
