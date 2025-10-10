local jecs = require(script.Parent.Parent.jecs.jecs)

export type World = jecs.World
export type Entity<T = any> = jecs.Entity<T>
export type Query<T...> = jecs.Query<T...>
export type Id<T = any> = jecs.Id<T>
export type QueryInner = jecs.QueryInner
export type Record = jecs.Record
export type Archetype = jecs.Archetype

return jecs
