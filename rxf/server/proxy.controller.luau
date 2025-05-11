local Remote: RemoteEvent =
	game:GetService("ReplicatedStorage"):WaitForChild("rxf-network"):WaitForChild(script:GetAttribute("REMOTE"))
return table.freeze(setmetatable({}, {
	__index = function(_, key)
		return function(self,player,...)
			print(player,...)
			Remote:FireClient(player,key,...)
		end
	end,
}))
