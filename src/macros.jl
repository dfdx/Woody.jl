
## macro runtimesex(nusers::Int, ntimes::Int, ex::Expr)
##     return quote
##         c = Collector()
##         @async start(c)
##         port = c.port
##         @sync begin
##             for uid=1:$nusers
##                 @async try
##                     r = Reporter(port)
##                     for itr=1:$ntimes
##                         try
##                             t = @elapsed $ex
##                             report(r, "$(time()),1,$uid,$itr,$t")
##                         catch e
##                             report(r, "$(time()),0,$uid,$itr,$t")
##                         end
##                     end
##                     close(r)
##                 catch e
##                     warn(e)
##                 end
##             end
##         end
##         sleep(0.1) # give collector some time to receive all messages
##         r = Reporter(port)
##         dmp = getdump(r)
##         sendclose(r)
##         todataframe(dmp)
##     end
## end



macro runtimes(nusers::Int, ntimes::Int, ex::Expr)
    return quote
        @sync for usr=1:$nusers
            @async for itr=1:$ntimes
                $ex
            end
        end
    end    
end


macro runduring(nusers::Int, seconds::Int, ex::Expr)
    return quote        
        @sync for usr=1:$nusers
            start = time()
            @async while time() - start < $seconds
                $ex
            end
        end
    end
end

