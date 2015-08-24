


using Requests
using URIParser

geturl(line) = strip(split(line, ",")[4], '\"')

function getallurls(filename)
    lines = split(readall(filename), "\n")[2:end-1]
    urls = Array(String, length(lines))
    for i=1:length(lines)
        urls[i] = "http://" * geturl(lines[i])
    end
    return urls
end


function resolvehost(url)
    h = URI(url).host
    ip = string(Base.getaddrinfo(h))
    replace(url, h, ip)
end

function resolvehosts(urls)
    result = String[]
    for url in urls
        try
            resolved = resolvehost(url)
            push!(result, resolved)
        catch
            println("Can't resolve $url)")
        end
    end
    return result
end

function get_stream(url::String)
    Requests.open_stream(URI(url), Dict(), "", "GET")
end




function foo()

    urls = resolvehosts(getallurls("dump1k.csv"))

    statuses = -ones(length(urls))
    times = -ones(length(urls))
    @time @sync for i=1:length(urls)
        @async begin
            try
                t = @elapsed resp = get(urls[i]; timeout=.8)
                statuses[i] = resp.status
                ## t = @elapsed begin
                ##     s = get_stream(urls[i])
                ##     r = readline(s)
                ##     close(s)
                ##     println(r)
                ## end
                times[i] = t
                println("Status: $(resp.status) ($(t) sec)")
            catch
                println("Error")
                rethrow()
            end
        end
    end

    @time for url in urls
        begin
            try
                t = @elapsed resp = get(url)
                println("Status: $(resp.status) ($(t) sec)")
            catch
                println("Error")
            end
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
