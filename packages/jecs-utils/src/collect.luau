--!nonstrict

type Signal<T...> = {
	Connect: (self: any, listener: (T...) -> ()) -> any,
}
type SignalLower<T...> = {
	connect: (self: any, listener: (T...) -> ()) -> any,
}

type SignalOn<T...> = {
	on: (self: any, listener: (T...) -> ()) -> any,
}

type Subscribe<T...> = {
	subscribe: (self: any, listener: (T...) -> ()) -> any,
}

type Callback<T...> = (listener: (T...) -> ()) -> any

type Cleanup = () -> ()

type Event<T...> = Signal<T...> | RBXScriptSignal<T...>

export type CollectIterator<T...> = typeof(setmetatable(
	{} :: {
		iter: () -> () -> (number, T...),
		disconnect: () -> (),
	},
	{} :: { __iter: () -> (number, T...) }
))

local function collect<T...>(
	event: Callback<T...> | Signal<T...> | SignalLower<T...> | SignalOn<T...> | Subscribe<T...> | RBXScriptSignal<T...>
)
	local storage = {}
	local mt = {}

	local iter = function()
		local n = #storage
		return function()
			if n <= 0 then
				return nil
			end

			n -= 1
			return n + 1, unpack(table.remove(storage, 1) :: any)
		end
	end

	mt.__iter = iter

	local disconnect

	if type(event) == "function" then
		disconnect = event(function(...)
			table.insert(storage, { ... })
		end)
	elseif type(event) == "table" then
		local event_any = event :: any

		if event_any.Connect then
			disconnect = event_any:Connect(function(...)
				table.insert(storage, { ... })
			end)
		elseif event_any.connect then
			disconnect = event_any:connect(function(...)
				table.insert(storage, { ... })
			end)
		elseif event_any.on then
			disconnect = event_any:on(function(...)
				table.insert(storage, { ... })
			end)
		end
	elseif typeof(event) == "RBXScriptSignal" then
		disconnect = event:Connect(function(...)
			table.insert(storage, { ... })
		end)
	end

	local function disconnect_fn()
		if not disconnect then
			return
		end
		if type(disconnect) == "function" then
			disconnect()
		elseif type(disconnect) == "table" then
			if disconnect.Disconnect then
				disconnect:Disconnect()
			elseif disconnect.disconnect then
				disconnect:disconnect()
			elseif disconnect.Destroy then
				disconnect:Destroy()
			elseif disconnect.destroy then
				disconnect:destroy()
			end
		elseif typeof(disconnect) == "RBXScriptConnection" then
			disconnect:Disconnect()
		end
	end

	local collect_iter = setmetatable({
		iter = iter,
		disconnect = disconnect_fn,
	}, { __iter = iter }) :: any

	return collect_iter :: CollectIterator<T...>
end

return collect
