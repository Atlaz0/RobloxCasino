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

-- Always shows 3 decimal places (e.g. 1.257M, 4.000K) so small per-second changes in a
-- big total are visible. Used by the HUD chip counter.
local function formatPrecise(n: number): string
	if n < 1000 then
		return tostring(math.floor(n))
	end
	for i = #suffixes, 1, -1 do
		local threshold = 10 ^ (i * 3)
		if n >= threshold then
			return string.format("%.3f%s", n / threshold, suffixes[i])
		end
	end
	return tostring(n)
end

return { format = format, formatPrecise = formatPrecise }
