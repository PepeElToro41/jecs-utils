local jecs = require(script.Parent.Parent.jecs.src.jecs)

export type Entity<T = any> = jecs.Entity<T>
export type Query<T...> = jecs.Query<T...>
export type World = jecs.World

return jecs
