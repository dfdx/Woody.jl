
import Base.start
import Base.show
import Base.close

function bindrandom(sock)
    port = -1
    while true
        try
            port = rand(3000:50000)
            bind(sock, "tcp://*:$port")
            break  # will only work if bind succeeded
        end
    end
    return port
end


type Collector
    ctx::Context
    sock::Socket
    port::Int
    buffer::Deque{String}

    # Collector(ctx, sock, port, buffer) = new(ctx, sock, port, buffer)
    function Collector()
        ctx = Context()
        sock = Socket(ctx, PULL)
        port = bindrandom(sock)
        new(ctx, sock, port, Deque{String}())
    end
end

show(io::IO, c::Collector) =
        print(io, "Collector(sock=$(c.sock); port=$(c.port); " *
              "bufsize=$(length(c.buffer)))")


type Reporter
    ctx::Context
    sock::Socket
    host::String
    port::Int

    # Reporter(ctx, sock, host, port) = new(ctx, sock, host, port)
    function Reporter(host::String, port::Int)
        ctx = Context()
        sock = Socket(ctx, PUSH)
        connect(sock, "tcp://$host:$port")
        new(ctx, sock, host, port)
    end
    Reporter(port) = Reporter("localhost", port)
end

show(io::IO, r::Reporter) = print(io, "Reporter($(r.port))")


isspecial(msg::String) = @compat startswith(msg, "!!")


function parsespecial(msg::String)
    if contains(msg, ":")
        # command with parameters
        cmd, argstr = split(msg[3:end], ":")
        args = convert(Vector{String}, split(argstr, ","))
        return cmd, args
    else
        return msg[3:end], ASCIIString[]
    end
end


function dumpbuffer(c::Collector)    
    n = length(c.buffer)
    arr = Array(String, n)
    # revert buffer's reverse order
    for (i, s) in enumerate(c.buffer)
        arr[end-i+1] = s
    end
    return join(arr, "\n")
end


function senddump(c::Collector, host, port)
    ctx = Context()
    sock = Socket(ctx, PUSH)
    connect(sock, "tcp://$host:$port")
    dmp = dumpbuffer(c)
    send(sock, dmp)
    close(sock)
end

function handlespecial(c::Collector, msg::String)
    cmd, args = parsespecial(msg)    
    if cmd == "dump"
        senddump(c, args[1], args[2])
    elseif cmd == "close"
        close(c.ctx)
    else
        warn("Unknown command: $cmd")
    end
end


function start(c::Collector)
    while true
        msg = bytestring(recv(c.sock))
        if isspecial(msg)
            handlespecial(c, msg)
        else
            unshift!(c.buffer, msg)            
        end
    end
end



function report(r::Reporter, msg::String)
    send(r.sock, msg)
end


function getdump(r::Reporter)
    ctx = Context()
    sock = Socket(ctx, PULL)
    port = bindrandom(sock)
    send(r.sock, "!!dump:$(gethostname()),$port")
    dmp = bytestring(recv(sock))
    dmp
end


function sendclose(r::Reporter)
    send(r.sock, "!!close")
end

# TODO: in ZMQ, do we need to close Context separately?
close(r::Reporter) = close(r.sock)
