
macro runtimes(nusers::Int, ntimes::Int, ex::Expr)
    return quote
        c = Collector()
        @async start(c)
        port = c.port
        @sync begin
            for uid=1:$nusers
                @async try
                    r = Reporter(port)
                    for itr=1:$ntimes
                        t = @elapsed $ex
                        report(r, "$(time()),$uid,$itr,$t")
                        sleep(0.1)
                    end
                    close(r)
                catch e
                    warn(e)
                end
            end
        end
        sleep(0.1) # give collector some time to receive all messages
        r = Reporter(port)
        dmp = getdump(r)
        sendclose(r)
        todataframe(dmp)
    end
end
