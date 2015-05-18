
######### ReportServer ##########

type ReportServer
    ctx::Context
    sock::Socket
    port::Int
    messages::Deque{String}
end


function ReportServer()
    ctx = Context()
    sock = Socket(ctx, PULL)
    port = -1
    bound = false
    while !bound
        # try random ports until one of them is free
        try
            port = rand(3000:50000)
            bind(sock, "tcp://*:$port")
            bound = true
        end
    end
    server = ReportServer(ctx, sock, port, Deque{String}())    
    server
end


function runserver(server::ReportServer)
    while true
        msg = bytestring(recv(server.sock))
        if msg == "[exit]"
            info("Got termination signal, exiting: $server")
            break
        else 
            push!(server.messages, msg)
        end
    end
end


function Base.show(io::IO, rserv::ReportServer)
    print(io, "ReportServer(port=$(rserv.port); " *
          "num_msgs=$(length(rserv.messages)))")
end


function Base.close(server::ReportServer)
    # send termination signal
    cli_sock = Socket(Context(), PUSH)
    connect(cli_sock, "tcp://localhost:$(server.port)")
    send(cli_sock, Message("[exit]"))
    ZMQ.close(server.sock)
    ZMQ.close(server.ctx)
end

######### Reporter ##########

type Reporter
    sock::Socket
    port::Int

    function Reporter(port::Int)
        ctx = Context()
        sock = Socket(ctx, PUSH)
        connect(sock, "tcp://localhost:$port")
        new(sock, port)
    end
end


function Base.show(io::IO, r::Reporter)
    print(io, "Reporter(port=$(r.port))")
end


function report(reporter::Reporter, text::String)
    send(reporter.sock, Message(text))
end


function Base.close(reporter::Reporter)
    ZMQ.close(reporter.sock)
end
