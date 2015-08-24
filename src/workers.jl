
using ZMQ
using Requests


function run()
    @sync for i=1:10
        @async begin
            ctx = Context()
            sock = Socket(ctx, PULL)
            connect(sock, "tcp://localhost:5501")
            while true
                try
                    url = bytestring(recv(sock))
                    r = get(url)
                    println("OK: status=$(r.status)")
                catch
                    println("Error")
                end
            end
        end
    end
end
