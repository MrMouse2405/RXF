--!nonstrict
local Controller = { __meta__ = {} }
local RXF = require("./$rxf")

print(
	`[RXF {RXF.VERSION}] {script.Name} is loaded on {game:GetService("RunService"):IsServer() and "Server" or "Client"}`
)

function Controller:OnStart()
	print(`{script.Name} is running OnStart() on {game:GetService("RunService"):IsServer() and "Server" or "Client"}`)

	-- shared modules are replicated
	require("./test.shared")

	-- so are regular module, you can use shared as a convention for 'client only'
	require("./test")

	-- errors server modules
	local _, e = pcall(require, "./test.module")
	print(e)

    -- You can also load services in client, and call them, client -> server
    -- you might get a cyclic dependency error / warning on intellisense, but it will run
    -- fine due to the fact that controllers / servers are replaced with proxies based
    -- on the environment.
	local service = require("./server.service")
	service:CallServer()
	service:TakeMessage("Hello World!")
    service:Ping()
end

function Controller:Pong(player: Player)
    print('server ponged!')
end

function Controller:TakeSomething(player: Player, data : string)
    print('server sent:',data)
end

return Controller
