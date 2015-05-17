
macro runtimes(nusers::Int, ntimes::Int, ex::Expr)
    return quote
        rserv = ReportServer()
        port = rserv.port
        @sync begin
            for userid=1:$nusers
                @async begin
                    r = Reporter(port)
                    try
                    for iter=1:$ntimes
                        t = @elapsed $ex
                        println("userid=$userid,iter=$iter")
                        report(r, "$(time()),$userid,$iter,$t")
                    end
                    # close(r)
                    catch e
                        println("REPORTER SOCKET: $(r.sock)")
                    end
                end

            end
        end
        # close(rserv)
        rserv.messages
    end
end
