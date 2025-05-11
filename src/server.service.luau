local Service = { __meta__ = { Events = {} } }
local RXF = require("./$rxf")

print(
	`[RXF {RXF.VERSION}]{script.Name} is loaded on {game:GetService("RunService"):IsServer() and "Server" or "Client"}`
)

function Service.__meta__:OnStart()
	print(`{script.Name} is running OnStart() on {game:GetService("RunService"):IsServer() and "Server" or "Client"}`)

	-- default modules
	require("./test")

	-- you can load shared modules, probably shouldn't.
	require("./test.shared")

	-- load server modules
	require("./test.module")
end

function Service:CallServer()
	print(`{self.player} called this on server!`)
end

function Service:TakeMessage(data: string)
	print(`{self.player} sent {data}`)
end

function Service:Ping()
    print(`{self.player} sent a ping!`)
	local controller = 	require(script.Parent:FindFirstChild('client.controller'))
	controller:Pong(self.player)
	controller:TakeSomething(self.player,'pong!')
end

return Service
