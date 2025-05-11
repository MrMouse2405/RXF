local Packages = game:GetService("ReplicatedStorage"):WaitForChild("Packages")
local RXF = {
	VERSION = "0.0.1",
	PACKAGES = Packages,
	ROOT = game:GetService("RunService"):IsServer() and game:GetService("ServerScriptService"):FindFirstChild("src")
		or game:GetService("ReplicatedStorage"):WaitForChild("rxf-replicated-src"),
	LOADED = false,

	jecs = require(Packages:WaitForChild("jecs")),
}

return RXF
