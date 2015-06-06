
type Collector
    ctx::Context
    sock::Socket
    buffers::Dict{String, Vector{String}}
    bufpos::Dict{String, Int}
    port::Int
end


function Collector(port)
    ctx = Context()
    sock = Socket(ctx, REP)
    bind(sock, "tcp://*:$port")
    return Collector(ctx, sock, Dict(), Dict(), port)
end

Base.show(io::IO, c::Collector) =
    print(io, "Collector($(c.sock.data),$(c.port))")


function handle_message(msg)
    if @compat startswith(msg, "r:")       # report from workers        
        println("got message: `$msg`")
        return "ok"
    elseif @compat startswith(msg, "c:")   # control message
        # no control messages yet
        return "ok"
    else
        print("ERROR (collector): can't understand message `$msg`")
        return ("unknown message type: shoud start either with 'r' " *
                "(normal report) or with 'c' (control message)")
    end
end

function run_collector_loop(c)
    try
        while true
            msg = bytestring(recv(c.sock))
            resp = handle_message(msg)
            send(c.sock, resp)
        end
    finally
        close(c.ctx)
    end
end

