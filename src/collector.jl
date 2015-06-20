
type Collector
    ctx::Context
    sock::Socket
    buffers::Dict{String, Vector{String}}
    bufpos::Dict{String, Int}
    paths::Dict{String, String}  # key => path
    files::Dict{String, IO}      # key => file
    port::Int
end


function Collector(port)
    ctx = Context()
    sock = Socket(ctx, PULL)
    bind(sock, "tcp://*:$port")
    return Collector(ctx, sock, Dict(), Dict(), Dict(), Dict(), port)
end

Base.show(io::IO, c::Collector) =
    print(io, "Collector($(c.sock.data),$(c.port))")


const BUF_SIZE = 100_000


function dumpbuf(c, key)
    pos = c.bufpos[key]
    data = join(c.buffers[key][1:pos-1], "\n")
    io = c.files[key]
    write(io, data * "\n")
    c.bufpos[key] = 1
end


function handle_control_message(c, msg)
    cmd, argstr = split(msg[3:end], " ", 2)
    if cmd == "create"
        println(argstr)
        key, path = split(argstr)
        info("Creating new key: $key")
        c.buffers[key] = Array(String, BUF_SIZE)
        c.bufpos[key] = 1
        c.paths[key] = path
        c.files[key] = open(path, "w")
    elseif cmd == "destroy"
        key = argstr
        info("Destroying key: $key")
        if haskey(c.buffers, key)
            println("all keys: $(keys(c.buffers))")
            dumpbuf(c, key)
            close(c.files[key])
            delete!(c.buffers, key)
            delete!(c.bufpos, key)
            delete!(c.paths, key)
            delete!(c.files, key)
        else
            warn("Key $key doesn't exist in collector")
        end
    else
        warn("Unknown control message: $msg")
    end
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
    else
        warn("Key doesn't exist in collector: key = $key; message = $msg")
    end
end


function handle_message(c, msg)
    if @compat startswith(msg, "r:")       # report from workers
        handle_report_message(c, msg)
    elseif @compat startswith(msg, "c:")   # control message
        handle_control_message(c, msg)
    else
        warn("unknown message type: shoud start either with 'r' " *
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
