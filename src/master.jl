
using ZMQ


geturl(line) = strip(split(line, ",")[4], '\"')


function run()
    ctx = Context()
    sock = Socket(ctx, PUSH)
    bind(sock, "tcp://*:5501")
    open("dump1k.csv") do f
        readline(f) # header
        for line in eachline(f)
            url = "http://" * geturl(line)
            println("Sending $url")
            send(sock, url)
        end
    end
    println("done")
end




@everywhere using Requests

@everywhere function getallurls(filename)
    lines = split(readall(filename), "\n")[2:end-1]
    urls = Array(String, length(lines))
    for i=1:length(lines)
        urls[i] = "http://" * geturl(lines[i])
    end
    return urls
end





function run2()
    urls = getallurls("dump1k.csv")
    @time @sync for url in urls
        @async begin
            resp = get(url)
            println("Status: $(resp.status)")
        end
    end 
end












## using ZMQ




## PROD_CONS_PORT = 5501

## function runall(nworkers::Int, prod, cons::Function)
##     # @sync
##     begin
##         # produce data in a separate thread
##         # @async
##         begin
##             ctx = Context()
##             prod_sock = Socket(ctx, PUSH)
##             bind(prod_sock, "tcp://*:$PROD_CONS_PORT")
##             for rec in ["http://www.google.com" for i=1:100]
##                 send(prod_sock, rec)
##             end
##             close(prod_sock)
##         end
##         for i=1:nworkers
##             # @async
##             begin
##                 ctx = Context()
##                 cons_sock = Socket(ctx, PULL)
##                 connect(sock, "tcp://localhost:$PROD_CONS_PORT")
##                 while true
##                     rec = bytestring(recv(cons_sock))
##                     cons(rec)
##                 end
##             end
##         end
##     end
## end


## producer = ["http://www.google.com" for i=1:100]

## function consumer(rec)
##     println(rec)
## end


## function run()
##     runall(10, producer, consumer)
## end
