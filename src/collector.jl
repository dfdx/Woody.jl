
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


const BUF_SIZE = 1_000_000


function handle_control_message(c, msg)
    cmd, argstr = split(msg[3:end], " ", 2)
    if cmd == "createkey"
        key = argstr
        info("Creating new key: $key")
        c.buffers[key] = Array(String, BUF_SIZE)
        c.bufpos[key] = 1
        return "ok"
    elseif cmd == "finalize"
        key = argstr
        info("Finalizing key: $key")
        if haskey(c.buffers, key)
            pos = c.bufpos[key]
            data = join(c.buffers[key][1:pos-1], "\n")
            delete!(c.buffers, key)
            delete!(c.bufpos, key)
            return "$data"
        else
            warn("Key $key doesn't exist in collector")
            return "error: trying to finalize non-existing/deleted key: $key"
        end
    else
        return "unknown control message: $msg"
    end
end


function handle_report_message(c, msg)
    key, data = split(msg[3:end], " ", 2)
    if haskey(c.buffers, key)
        if c.bufpos[key] > length(c.buffers[key])
            return "error: buffer is full"   # TODO: dump to disk instead
        end    
        pos = c.bufpos[key]
        c.buffers[key][pos] = data
        c.bufpos[key] += 1
        return "ok"
    else
        return "error: key doesn't exist in collector: $key"
    end
end


function handle_message(c, msg)
    if @compat startswith(msg, "r:")       # report from workers
        return handle_report_message(c, msg)
    elseif @compat startswith(msg, "c:")   # control message
        return handle_control_message(c, msg)
    else
        return ("unknown message type: shoud start either with 'r' " *
                "(normal report) or with 'c' (control message)")
    end
end

function run_collector_loop(c)
    try
        while true
            msg = bytestring(recv(c.sock))
            resp = handle_message(c, msg)
            send(c.sock, resp)
        end
    finally
        close(c.ctx)
    end
end
