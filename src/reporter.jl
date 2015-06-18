
type Reporter
    ctx::Context
    sock::Socket
    port::Int
    key::String
    path::String
end

function Reporter(port::Int)
    ctx = Context()
    sock = Socket(ctx, PUSH)
    connect(sock, "tcp://localhost:$port")
    path = tempname()
    touch(path)
    return Reporter(ctx, sock, port, randstring(5), path)
end

function Reporter(port::Int, key::String)
    ctx = Context()
    sock = Socket(ctx, PUSH)
    connect(sock, "tcp://localhost:$port")
    return Reporter(ctx, sock, port, key, "<none>")
end

Base.show(io::IO, r::Reporter) =
    print(io, "Reporter($(r.sock),$(r.port))")


@doc """Send reporting message""" ->
function report(r::Reporter, msg::String)
    send(r.sock, "r:$(r.key) $msg")    
end


@doc """Send control message""" ->
function control(r::Reporter, msg::String)
    return send(r.sock, "c:" * msg)
end


function create_key(mr::Reporter)
    control(mr, "create $(mr.key) $(mr.path)")
end


function destroy_key(mr::Reporter)
    control(mr, "destroy $(mr.key)")
    sleep(1) # give collector some time to flush last data to a file
    result = "<not initialized>"    
    open(mr.path) do inp
        result = readlines(inp)
        println("number of lines: $(length(result))")
    end    
    # rm(mr.path)
    return result
end
