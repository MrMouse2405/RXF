-- Packages
local RepFirst = game:GetService("ReplicatedFirst"):FindFirstChild("rxf")
local RXF = require(RepFirst:FindFirstChild("$rxf"))
local RXFClientLoader = script:FindFirstChild("rxf-loader")
local HTTPService = game:GetService("HttpService")

-- Types
type ModuleType = "service" | "controller" | "shared" | "module" | "regular"
type MaybeModule = ModuleScript | Instance | Folder

type Service = {
	__meta__: {
		OnStart: () -> (),
	},
	[string]: (...any) -> (),
}

-- Assets
local ProxyService = script:FindFirstChild("proxy.service")
local ProxyController = script:FindFirstChild("proxy.controller")
local SourceFolder = game:GetService("ServerScriptService"):FindFirstChild("src")
local ClientFolder = Instance.new("Folder", game:GetService("ReplicatedStorage"))
local NetworkFolder = Instance.new("Folder", game:GetService("ReplicatedStorage"))
-- House Keeping
assert(SourceFolder and SourceFolder:IsA("Folder"), "Source Folder doesn't exist!!!")
ClientFolder.Name = "rxf-replicated-src"
NetworkFolder.Name = "rxf-network"

-- State
local Services = {}
local ControllerCount = 0

-- Functions
local function getModuleType(fileName: string): ModuleType
	if string.match(fileName, "%.service$") then
		return "service"
	elseif string.match(fileName, "%.controller$") then
		return "controller"
	elseif string.match(fileName, "%.shared$") then
		return "shared"
	elseif string.match(fileName, "%.module$") then
		return "module"
	else
		return "regular"
	end
end

local function LoadEvents(module: ModuleScript, replicated_module: ModuleScript, service: Service)
	local remote = Instance.new("RemoteEvent")
	local name = HTTPService:GenerateGUID()
	remote.Name = name
	remote.Parent = NetworkFolder
	remote.OnServerEvent:Connect(function(player: Player, event_name: string, ...)
		if typeof(event_name) ~= "string" then
			return
		end
		local func = service[event_name]
		if not func then
			warn(`{player} fired {module}::{event_name} which does not exist!!`)
			return
		end
		func({ player = player }, ...)
	end)
	replicated_module:SetAttribute("REMOTE", name)
end

local function LoadControllerEvents(module: ModuleScript, proxy_module: ModuleScript)
	local remote = Instance.new("RemoteEvent")
	local name = HTTPService:GenerateGUID()
	remote.Name = name
	remote.Parent = NetworkFolder
	module:SetAttribute("REMOTE", name)
	proxy_module:SetAttribute("REMOTE", name)
end

local function LoadService(module: ModuleScript): ModuleScript
	local service: Service = require(module)
	table.insert(Services, service)
	local replicated_module = ProxyService:Clone()
	replicated_module.Name = module.Name
	LoadEvents(module, replicated_module, service)
	return replicated_module
end

local function LoadController(module: ModuleScript): ModuleScript
	local proxy_module = ProxyController:Clone()
	proxy_module.Name = module.Name
	proxy_module.Parent = module.Parent
	LoadControllerEvents(module, proxy_module)
	return module -- module gets sent to client, proxy stays on server.
end

local ReplicatedTypes = {
	controller = true,
	shared = true,
	regular = true,
	service = false,
}

local function LoadChildren(replicated_parent: Instance, children: { MaybeModule })
	for _, instance: MaybeModule in children do
		if instance:IsA("Folder") then
			local folder = Instance.new("Folder", replicated_parent)
			folder.Name = instance.Name
			LoadChildren(folder, instance:GetChildren())
			continue
		end
		if instance:IsA("ModuleScript") then
			local module_type = getModuleType(instance.Name)

			--// services
			if module_type == "service" then
				local replicated_module = LoadService(instance)
				replicated_module.Parent = replicated_parent
				LoadChildren(replicated_module, instance:GetChildren())
			--// these all are sent to client
			elseif module_type == "controller" then
				ControllerCount += 1
				local replicated_module = LoadController(instance)
				replicated_module.Parent = replicated_parent
				LoadChildren(replicated_module, instance:GetChildren())
			elseif ReplicatedTypes[module_type] then
				if module_type == "controller" then
					ControllerCount += 1
				end
				local replicated_module = instance:Clone()
				replicated_module.Parent = replicated_parent
				LoadChildren(replicated_module, instance:GetChildren())
			elseif module_type == "module" then
				continue
			else
				warn(`[RXF {RXF.VERSION}]`, instance, "is ignored.")
			end
		end
	end
end

--[[

    RXF Loading Sequence

]]

print(`[RXF {RXF.VERSION}] Loaded.`)

local parent = SourceFolder
local replicated_parent = ClientFolder

-- Replicate Children
LoadChildren(replicated_parent, parent:GetChildren())
RXFClientLoader:SetAttribute("NumControllers", ControllerCount)
RXFClientLoader.Parent = RepFirst
print(`[RXF {RXF.VERSION}] Replication Finished. Starting Services.`)

-- Now clients

-- Load Services
for _, service: Service in Services do
	local __meta__ = service.__meta__

	if not __meta__ then
		return
	end

	local start = __meta__.OnStart
	if start then
		task.spawn(start)
	end
end

print(`[RXF {RXF.VERSION}] Services started. Job finished. RXF Exits.`)
