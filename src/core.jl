
# using Requests
using DataStructures
using DataFrames
using ZMQ
using Compat
using Winston
using Redis

# include("reportserver.jl")
# include("reporter.jl")
include("collector.jl")
include("summary.jl")
include("macros.jl")



function redis_test(nusers, niter)
    @time @sync for u=1:nusers
        @async begin
            conn = Redis.RedisConnection()
            for i=1:niter
                Redis.lpush(conn, "mytest", "hello")
                # Redis.lpop(conn, "mytest")
            end
        end
    end 
end


function test_collector()
    c = Collector()
    @async start(c)
    r = Reporter(c.port)
    # r = Reporter(5019)
    report(r, "hello")
    report(r, "how are you?")
    report(r, "bye")
    dmp = getdump(r)
    println(dmp)
    sendclose(r)
    close(r)
end

function run_collector()
    c = Collector()
    println("PORT: $(c.port)")
    start(c)
end
 
function run_reporter(port)
    r = Reporter(port)
    report(r, "hello")
    report(r, "how are you?")
    report(r, "bye")
    dmp = getdump(r)
    println(dmp) 
end


function zmq_test(nusers, niter)
    ctx = Context()
    s = Socket(ctx, PULL)
    bind(s, "tcp://*:5556")
    t = @async while true
        msg = bytestring(recv(s))
    end
    @time @sync for i=1:nusers
        @async begin
            c = Socket(ctx, PUSH)
            connect(c, "tcp://localhost:5556")
            for j=1:niter
                send(c, "hello")
            end            
            close(c)
        end        
    end
    close(s)
end

#########################################

## function test_reporter()
##     rserv = ReportServer()
##     r = Reporter(rserv.port)
##     # r = Reporter(45485)
##     @async runserver(rserv)
##     report(r, "hello")
##     report(r, "bye")
##     summary = finalsummary(r)
##     println(summary)
##     close(r)

## end









## function create_server()
##     ctx = Context(1)
##     serv_sock = Socket(ctx, PULL)
##     serv_sock
## end

## function run_server(serv_sock)
##     bind(serv_sock, "tcp://*:5555")
##     while true
##         s = bytestring(recv(serv_sock))
##         println(s)
##     end
## end



## function run_client(client_id)
##     ctx = Context(1)
##     cli_sock = Socket(ctx, PUSH)
##     connect(cli_sock, "tcp://localhost:5555")
##     for i=1:100
##         rand(10, 10)
##         send(cli_sock, Message("$client_id:$i"))
##     end
##     close(cli_sock)
## end

## function main()
##     serv_sock = create_server()
##     @async run_server(serv_sock)
##     @sync begin
##         for client_id=1:100
##             @async run_client(client_id)
##         end
##         println("started all")
##     end
##     println("all workers are done")
##     close(serv_sock)
##     println("done.")
## end
