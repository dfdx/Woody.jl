
macro runtimes(nusers::Int, ntimes::Int, ex::Expr)
    return quote
        rserv = ReportServer()
        @async runserver(rserv)
        port = rserv.port
        @sync begin
            for uid=1:$nusers
                @async try
                    println("starting worker $uid")
                    r = Reporter(port)
                    for itr=1:$ntimes
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
        r = Reporter(port)
        summ = finalsummary(r)
        summ
    end
end
