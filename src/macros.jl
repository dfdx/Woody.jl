

macro repeattimes(nusers::Int, ntimes::Int, ex::Expr)
    return quote
        @sync for usr=1:$nusers
            @async for itr=1:$ntimes
                $ex
            end
        end
    end
end


macro repeatduring(nusers::Int, seconds::Int, ex::Expr)
    return quote
        @sync for usr=1:$nusers
            start = time()
            @async while time() - start < $seconds
                $ex
            end
        end
    end
end


@doc """
Run expression by specieid number of users (threads) specified number of times 
in parallel and collect results.
Example - run GET request by 100 users 5000 times each:

    using Requests
    timetable = @runtimes 100 5000 get("http://example.com")

""" ->
macro runtimes(nusers::Int, ntimes::Int, ex::Expr)
    return quote
        ctr = Controller(COLLECTOR_PORT)
        @sync for usr=1:$nusers
            r = Reporter(COLLECTOR_PORT, ctr.key)
            @async for itr=1:$ntimes
                success = true
                errorbuf = IOBuffer()
                now = time()
                t = @elapsed try
                    $ex
                catch e
                    success = false
                    bt = catch_backtrace()
                    showerror(errorbuf, e, bt)
                end                
                err = split(bytestring(errorbuf), "\n")[1]
                report(r, "$now,$usr,$itr,$success,$err,$t")
            end
        end
        info("Ready, collecting results...")
        finalize(ctr)        
    end
end


@doc """
Run expression by specified number of users during specified time in parallel
and collect results. 
Example - run GET request by 100 users during 30 seconds:

    using Requests
    timetable = @runduring 100 30 get("http://example.com")

""" ->
macro runduring(nusers::Int, seconds::Int, ex::Expr)
    return quote
        ctr = Controller(COLLECTOR_PORT)
        @sync for usr=1:$nusers
            r = Reporter(COLLECTOR_PORT, ctr.key)
            start = time()
            @async begin
                itr = 0
                while time() - start < $seconds
                    itr += 1
                    success = true
                    errorbuf = IOBuffer()
                    now = time()
                    t = @elapsed try
                        $ex
                    catch e
                        success = false
                        bt = catch_backtrace()
                        showerror(errorbuf, e, bt)
                    end                    
                    err = split(bytestring(errorbuf), "\n")[1]
                    report(r, "$now,$usr,$itr,$success,$err,$t")
                end
            end
        end
        info("Ready, collecting results...")
        finalize(ctr)
    end
end

