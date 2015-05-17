
using Requests
using DataStructures
using DataFrames
using ZMQ

include("reporter.jl")
include("macros.jl")



function run_server()
    ctx = Context(1)
    serv_sock = Socket(ctx, PULL)
    bind(serv_sock, "tcp://*:5555")
    while true
        s = bytestring(recv(serv_sock))
        println(s)
    end
end


# TODO: gracefully shutdown server on control signal

function run_client(client_id)
    ctx = Context(1)
    cli_sock = Socket(ctx, PUSH)
    connect(cli_sock, "tcp://localhost:5555")
    for i=1:100
        rand(10, 10)
        send(cli_sock, Message("$client_id:$i"))
    end
end

function main()
    @sync begin
        @async run_server()        
        for client_id=1:100            
            @async run_client(client_id)
        end
        println("started all")
    end
end

