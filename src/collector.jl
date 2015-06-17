
type Collector
    ctx::Context
    sock::Socket
    buffers::Dict{String, Vector{String}}
    bufpos::Dict{String, Int}
    tempfiles::Dict{String, @compat Tuple{String, IO}}
    port::Int
end


function Collector(port)
    ctx = Context()
    sock = Socket(ctx, REP)
    bind(sock, "tcp://*:$port")
    return Collector(ctx, sock, Dict(), Dict(), Dict(), port)
end

Base.show(io::IO, c::Collector) =
    print(io, "Collector($(c.sock.data),$(c.port))")


const BUF_SIZE = 100_000


function send_data(c::Collector, key::String)
    send(c.sock, "no data, hahaha!")
end


function finalize_key(c, key)
    pos = c.bufpos[key]
    dumpbuf(c, key)
    path, out = c.tempfiles[key]
    flush(out)
    # timetable = open(in -> aggregate(in), path)
    send_data(c, key)
    delete!(c.buffers, key)
    delete!(c.bufpos, key)
    close(out)
    rm(path)
    delete!(c.tempfiles, key)
end


function handle_control_message(c, msg)
    cmd, argstr = split(msg[3:end], " ", 2)
    if cmd == "createkey"
        key = argstr
        info("Creating new key: $key")
        c.buffers[key] = Array(String, BUF_SIZE)
        c.bufpos[key] = 1
        c.tempfiles[key] = mktemp()
        send(c.sock, "ok")
    elseif cmd == "finalize"
        key = argstr
        info("Finalizing key: $key")
        if haskey(c.buffers, key)
            finalize_key(c, key)
        else
            warn("Key $key doesn't exist in collector")
            send(c.sock, "error: trying to finalize non-existing/deleted key: $key")
        end
    else
        send(c.sock, "unknown control message: $msg")
    end
end


function dumpbuf(c, key)
    pos = c.bufpos[key]
    data = join(c.buffers[key][1:pos-1], "\n")
    io = c.tempfiles[key][2]
    write(io, data * "\n")
    c.bufpos[key] = 1
end


function handle_report_message(c, msg)
    key, data = split(msg[3:end], " ", 2)
    if haskey(c.buffers, key)
        if c.bufpos[key] > length(c.buffers[key])
            dumpbuf(c, key)
        end
        pos = c.bufpos[key]
        c.buffers[key][pos] = data
        c.bufpos[key] += 1
        send(c.sock, "ok")
    else
        send(c.sock, "error: key doesn't exist in collector: $key")
    end
end


function handle_message(c, msg)
    if @compat startswith(msg, "r:")       # report from workers
        handle_report_message(c, msg)
    elseif @compat startswith(msg, "c:")   # control message
        handle_control_message(c, msg)
    else
        send(c.sock, "unknown message type: shoud start either with 'r' " *
             "(normal report) or with 'c' (control message)")
    end
end

function run_collector_loop(c)
    try
        while true
            msg = bytestring(recv(c.sock))
            handle_message(c, msg)
        end
    finally
        close(c.ctx)
    end
end
