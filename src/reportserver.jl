
type ReportServer
    ctx::Context
    sock::Socket
    port::Int
    messages::Deque{String}
end


function ReportServer()
    ctx = Context()
    sock = Socket(ctx, REP)
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


function summarize(messages::Deque{String})
    n = length(messages)
    arr = Array(String, n)
    for i=1:n
        arr[i] = pop!(messages)
    end
    return join(arr, "\n")
end

function runserver(rserv::ReportServer)
    println("server started")
    try
        while true
            msg = bytestring(recv(rserv.sock))
            println("ReportServer: got message -- " * msg)
            if msg == "!!stop-and-summary"
                println("ReportServer: Got termination signal, exiting: $rserv")
                summ = summarize(rserv.messages)
                println("ReportServer: summary -- " * summ)
                send(rserv.sock, Message(summ))
                println("ReportServer: sent summary")
                break
            else
                println("ReportServer: regular message -- " * msg)
                push!(rserv.messages, msg)
                println("ReportServer: preparing to send response")
                send(rserv.sock, Message("ok"))
                println("ReportServer: sent response")
            end
        end
    catch e
        # server will run in a separate task, so we need to explicitely print any exceptions
        warn(e)
        throw(e)
    finally
        println("ReportServer: stopped, closing server socket")
        sleep(5)  # let clints get sent messages
        ZMQ.close(rserv.sock)
        println("ReportServer: closed server socket")
    end
    println("server stopped")
end


function Base.show(io::IO, rserv::ReportServer)
    print(io, "ReportServer(port=$(rserv.port); " *
          "num_msgs=$(length(rserv.messages)); " *
          "sock=$(rserv.sock.data))")
end


function Base.close(server::ReportServer)
    # send termination signal
    cli_sock = Socket(Context(), PUSH)
    connect(cli_sock, "tcp://localhost:$(server.port)")
    send(cli_sock, Message("[exit]"))
    ZMQ.close(server.sock)
    ZMQ.close(server.ctx)
end
