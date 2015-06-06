
type Reporter
    ctx::Context
    sock::Socket
    port::Int
end

function Reporter(port::Int)
    ctx = Context()
    sock = Socket(ctx, REQ)
    connect(sock, "tcp://localhost:$port")
    return Reporter(ctx, sock, port)
end

Base.show(io::IO, r::Reporter) =
    print(io, "Reporter($(r.sock),$(r.port))")


function report(r::Reporter, msg::String)
    send(r.sock, msg)
    resp = bytestring(recv(r.sock))
    if resp != "ok"
        error("Reporting failed with message: $resp")
    end
end
