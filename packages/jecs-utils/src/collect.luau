--!nonstrict

type Signal<T...> = { [any]: any }
type Cleanup = () -> ()

local function collect<T...>(event: (listener: (T...) -> ()) -> Cleanup | Signal<T...>)
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
		disconnect = event(function(...) end)
	elseif type(event) == "table" then
		if event.Connect then
			disconnect = event:Connect(function(...)
				table.insert(storage, { ... })
			end)
		elseif event.connect then
			disconnect = event:connect(function(...)
				table.insert(storage, { ... })
			end)
		elseif event.on then
			disconnect = event:on(function(...)
				table.insert(storage, { ... })
			end)
		end
	elseif typeof(event) == "RBXScriptSignal" then
		disconnect = event:Connect(function(...)
			table.insert(storage, { ... })
		end)
	end

	setmetatable(storage, mt)
	return (storage :: any) :: () -> (number, T...),
		function()
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
end

return collect
