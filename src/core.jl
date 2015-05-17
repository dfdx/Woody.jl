
using Requests
using DataStructures
using DataFrames
using ZMQ


const DEFAULT_PORT = 6911

type ReportServer
    ctx::Context
    sock::Socket
    messages::Deque{String}
end

function ReportServer()
    ctx = Context(1)
    sock = Socket(ctx, PULL)
    server = ReportServer(ctx, sock, Deque{String}())
    @async runserver(server)  # TODO: if port is in use,
                              #  this will go unnoticed
    server
end

type Reporter
    sock::Socket
    
    function Reporter(;port=DEFAULT_PORT)
        ctx = Context(1)
        sock = Socket(ctx, PUSH)
        connect(sock, "tcp://localhost:$port")
        new(sock)
    end
end

function runserver(server::ReportServer; port=DEFAULT_PORT)
    bind(server.sock, "tcp://*:$port")
    while true        
        msg = bytestring(recv(server.sock))
        push!(server.messages, msg)
    end
end

function Base.close(server::ReportServer)
    ZMQ.close(server.sock)
    ZMQ.close(server.ctx)
end


function Base.close(reporter::Reporter)
    ZMQ.close(reporter.sock)
end


function report(reporter::Reporter, text::String)
    send(reporter.sock, Message(text))
end

macro runtimes(nusers::Int, ntimes::Int, ex::Expr)
    return quote
        report_server = ReportServer()
        @sync begin
            for userid=1:$nusers
                reporter = Reporter()
                @async begin
                    for iter=1:$ntimes
                        t = @elapsed $ex
                        report(reporter, "$(time()),$userid,$iter,$t")
                    end                    
                end
                close(reporter)
            end
        end
        close(report_server)
    end
end







function zmq_test()
    ctx1 = Context(1)
    serv = Socket(ctx1, PULL)
    bind(serv, "tcp://*:5555")

    ctx2 = Context(1)
    cli = Socket(ctx2, PUSH)
    connect(cli, "tcp://localhost:5555")

    send(cli, Message("hello"))
    bytestring(recv(serv))

    send(cli, Message("hello2"))
    bytestring(recv(serv))
end

