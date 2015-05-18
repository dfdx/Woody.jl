
macro runtimes(nusers::Int, ntimes::Int, ex::Expr)
    return quote
        rserv = ReportServer()
        port = rserv.port
        @sync begin
            for userid=1:$nusers
                @async try
                    println("starting worker $uid")
                    r = Reporter(port)
                    for iter=1:$ntimes
                        t = @elapsed $ex
                        # println("userid=$uid,iter=$itr")
                        report(r, "$(time()),$uid,$itr,$t")
                    end
                    close(r)
                    println("worker $uid finished")
                catch e
                    println(e)
                end
            end
        end
        println("starting server")
        runserver(rserv)  # TODO: how to stop consuming
        rserv.messages
    end
end
