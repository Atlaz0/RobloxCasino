local suffixes = { "K", "M", "B", "T", "Qa", "Qi" }

local function format(n: number): string
	if n < 1000 then
		return tostring(math.floor(n))
	end
	for i = #suffixes, 1, -1 do
		local threshold = 10 ^ (i * 3)
		if n >= threshold then
			local val = n / threshold
			if val >= 100 then
				return string.format("%d%s", math.floor(val), suffixes[i])
			elseif val >= 10 then
				return string.format("%.1f%s", val, suffixes[i])
			else
				return string.format("%.2f%s", val, suffixes[i])
			end
		end
	end
	return tostring(n)
end

return { format = format }
