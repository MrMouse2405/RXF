local Remote =
	game:GetService("ReplicatedStorage"):WaitForChild("rxf-network"):WaitForChild(script:GetAttribute("REMOTE"))
return table.freeze(setmetatable({}, {
	__index = function(_, key)
		return function(self, ...)
			Remote:FireServer(key, ...)
		end
	end,
}))
