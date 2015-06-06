
const COLLECTOR_PORT = 5543

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


macro repeattimes(nusers::Int, ntimes::Int, ex::Expr)
    return quote
        ctr = Controller(COLLECTOR_PORT)
        @sync for usr=1:$nusers
            r = Reporter(COLLECTOR_PORT, ctr.key)
            @async for itr=1:$ntimes
                success = true
                errorbuf = IOBuffer()
                t = @elapsed try
                    $ex
                catch e
                    success = false
                    bt = catch_backtrace()
                    showerror(errorbuf, e, bt)
                end
                now = time()
                err = split(bytestring(errorbuf), "\n")[1]
                report(r, "$now,$usr,$itr,$success,$err,$t")
            end
        end
        data = finalize(ctr)
        split(data, "\n")
    end
end


macro repeatduring(nusers::Int, seconds::Int, ex::Expr)
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
                    t = @elapsed try
                        $ex
                    catch e
                        success = false
                        bt = catch_backtrace()
                        showerror(errorbuf, e, bt)
                    end
                    now = time()
                    err = split(bytestring(errorbuf), "\n")[1]
                    report(r, "$now,$usr,$itr,$success,$err,$t")
                end
            end
        end
        data = finalize(ctr)
        split(data, "\n")
    end
end
