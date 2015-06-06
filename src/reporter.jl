
type Reporter
    ctx::Context
    sock::Socket
    port::Int
    key::String
end

function Reporter(port::Int, key::String)
    ctx = Context()
    sock = Socket(ctx, REQ)
    connect(sock, "tcp://localhost:$port")
    return Reporter(ctx, sock, port, key)
end

Base.show(io::IO, r::Reporter) =
    print(io, "Reporter($(r.sock),$(r.port))")


@doc """Send reporting message""" -> 
function report(r::Reporter, msg::String)
    send(r.sock, "r:$(r.key) $msg")
    resp = bytestring(recv(r.sock))
    if resp != "ok"
        error("Reporting failed with message: $resp")
    end
end

