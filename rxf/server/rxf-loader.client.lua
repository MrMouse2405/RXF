local source_folder = game:GetService("ReplicatedStorage"):WaitForChild("rxf-replicated-src")
local rxf = require(game:GetService("ReplicatedFirst"):FindFirstChild("rxf"):FindFirstChild("$rxf"))
local network_folder = game:GetService("ReplicatedStorage"):WaitForChild("rxf-network")

local Count = 0
local TargetCount = script:GetAttribute("NumControllers")
local Controllers = {}
local Player = game:GetService('Players').LocalPlayer

local Loading = false
local function LoadModule(module: ModuleScript)
	if Controllers[module] then
		return
	end

	if module:IsA("ModuleScript") and string.match(module.Name, "%.controller$") then
		local controller = require(module)
		Controllers[module] = controller
		Count += 1
		-- Do networking
		local remote: RemoteEvent = network_folder:WaitForChild(module:GetAttribute("REMOTE"))
		remote.OnClientEvent:Connect(function(key, ...)
			print(key,...)
			if controller[key] then
				controller[key](nil,Player, ...)
			else
				warn(`[RXF {rxf.VERSION}] Server tried to call {module}::{key}(...) which probably doesn't exist!`)
			end
		end)
	end

	if Count == TargetCount and not Loading then
		Loading = true
		for _, controller in Controllers do
			if controller.OnStart then
				controller.OnStart()
			end
		end
		rxf.LOADED = true
	end
end

source_folder.DescendantAdded:Connect(LoadModule)
for _, module in source_folder:GetDescendants() do
	LoadModule(module)
end
