
type Reporter
    sock::Socket
    port::Int

    function Reporter(port::Int)
        ctx = Context()
        sock = Socket(ctx, REQ)
        connect(sock, "tcp://localhost:$port")
        new(sock, port)
    end
end


function Base.show(io::IO, r::Reporter)
    print(io, "Reporter(port=$(r.port); sock=$(r.sock.data))")
end


function report(r::Reporter, text::String)
    send(r.sock, Message(text))
    println("Reporter: sent text, waiting for response")
    resp = bytestring(recv(r.sock))
    println("Reporter: response from server -- " * resp)
    resp
end


function finalsummary(r::Reporter)
    send(r.sock, Message("!!stop-and-summary"))
    println("Reporter: sent termination signal to the server, waiting for response")
    summ = bytestring(recv(r.sock))
    println("Reporter: got response (summary) -- " * summ)
    summ
end


function Base.close(reporter::Reporter)
    ZMQ.close(reporter.sock)
end



