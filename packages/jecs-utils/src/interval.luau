local function interval(time: number)
	local pin: number = nil

	local function throttle()
		if not pin then
			pin = os.clock()
		end

		local elapsed = os.clock() - pin > time
		if elapsed then
			pin = os.clock()
		end

		return elapsed
	end
	return throttle
end

return interval
