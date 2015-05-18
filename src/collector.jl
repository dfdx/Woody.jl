
import Base.start
import Base.show

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


function parse_special(msg::String)
    if contains(msg, ":")
        # command with parameters
        cmd, argstr = split(msg[3:end], ":")
        args = convert(Vector{String}, split(argstr, ","))
        return cmd, args
    else
        return msg[3:end], ASCIIString[]
    end
end


function dump_buffer(c::Collector)    
    n = length(c.buffer)
    arr = Array(String, n)
    # revert buffer's reverse order
    for (i, s) in enumerate(c.buffer)
        arr[end-i+1] = s
    end
    return join(arr, "\n")
end


function send_dump(c::Collector, host, port)
    ctx = Context()
    sock = Socket(ctx, PUSH)
    connect(sock, "tcp://$host:$port")
    dmp = dump_buffer(c)
    send(sock, dmp)
    close(sock)
end

function process_special(c::Collector, msg::String)
    cmd, args = parse_special(msg)
    println(args)
    if cmd == "dump"
        send_dump(c, args[1], args[2])
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
            process_special(c, msg)
        else
            unshift!(c.buffer, msg)
            println(msg)
        end
    end
end



function collect(r::Reporter, msg::String)
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
