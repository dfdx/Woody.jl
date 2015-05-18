
using Requests
using DataStructures
using DataFrames
using ZMQ

include("reportserver.jl")
include("reporter.jl")
include("macros.jl")




#########################################

function test_reporter()
    rserv = ReportServer()
    r = Reporter(rserv.port)
    r = Reporter(45485)
    @async runserver(rserv)
    report(r, "hello")
    report(r, "bye")
    summary = finalsummary(r)
    println(summary)
    close(r)

end









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
