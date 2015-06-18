
type Controller
    ctx::Context
    sock::Socket
    port::Int
    key::String
end


function Controller(port)
    ctx = Context()
    sock = Socket(ctx, REQ)
    connect(sock, "tcp://localhost:$port")
    key = create_key(sock)
    return Controller(ctx, sock, port, key)
end


Base.show(io::IO, ctr::Controller) =
    print(io, "Controller($(ctr.sock.data),$(ctr.port))")


@doc """Send control message""" ->
function control(sock::Socket, msg::String)
    send(sock, "c:" * msg)
    resp = bytestring(recv(sock))
    return resp
end


@doc """Send control message""" ->
function control(ctr::Controller, msg::String)
    return control(ctr.sock, msg)
end


@doc """Create new buffer on Collector, return its key""" ->
function create_key(sock::Socket)
    key = randstring(5)
    control(sock, "createkey $key")
    return key
end


@doc """Get all data and remove buffers on Collector""" ->
function finalize(ctr::Controller)
    send(ctr.sock, "c:finalize $(ctr.key)")
    # read all data from socket
    stop = false
    timetable = String[]
    while !stop
        line = bytestring(recv(ctr.sock))
        if line == "--END--"
            stop = true
        else
            push!(timetable, line)
        end
        send(ctr.sock, "ok")
    end
    return timetable
end
