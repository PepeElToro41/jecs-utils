local jecs = require(script.Parent.Parent.jecs.jecs)

export type Entity<T = any> = jecs.Entity<T>
export type Query<T...> = jecs.Query<T...>

return jecs
