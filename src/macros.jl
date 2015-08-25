

## macro repeattimes(nusers::Int, ntimes::Int, ex::Expr)
##     return quote
##         @sync for usr=1:$nusers
##             @async for itr=1:$ntimes
##                 $ex
##             end
##         end
##     end
## end


## macro repeatduring(nusers::Int, seconds::Int, ex::Expr)
##     return quote
##         @sync for usr=1:$nusers
##             start = time()
##             @async while time() - start < $seconds
##                 $ex
##             end
##         end
##     end
## end


function split_equally{T}(arr::Union(Array{T,1}, Range{T}), n::Int)
    @assert length(arr) >= n
    arr = collect(arr)
    result = Array(Array{T,1}, n)
    len, rem = divrem(length(arr), n)
    for i=1:n-1
        result[i] = copy(arr[(i-1)*len+1 : i*len])
    end
    result[end] = arr[(n-1)*len+1 : end]
    return result
end


macro runtimes(nusers::Int, ntimes::Int, ex::Expr)
    return quote
        local np = nprocs()
        local userids = split_equally(1:$nusers, np)
        # on each process
        all_results = @parallel vcat for p=1:np
            local_results = Array{Any}[]
            # run approx. nusers/nprocs() tasks
            @sync for uid in userids[p]
                @async begin
                    for itr=1:$ntimes
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
                        # TODO: use dict instead
                        push!(local_results, [now,uid,itr,success,err,t])
                    end
                end
            end
            local_results
        end
    end
end


## @doc """
## Run expression by specieid number of users (threads) specified number of times
## in parallel and collect results.
## Example - run GET request by 100 users 5000 times each:

##     using Requests
##     timetable = @runtimes 100 5000 get("http://example.com")

## """ ->
## macro runtimes(nusers::Int, ntimes::Int, ex::Expr)
##     return quote
##         mr = Reporter(COLLECTOR_PORT)
##         create_key(mr)
##         @sync for usr=1:$nusers
##             r = Reporter(COLLECTOR_PORT, mr.key)
##             @async for itr=1:$ntimes
##                 success = true
##                 errorbuf = IOBuffer()
##                 now = time()
##                 t = @elapsed try
##                     $ex
##                 catch e
##                     success = false
##                     bt = catch_backtrace()
##                     showerror(errorbuf, e, bt)
##                 end
##                 err = split(bytestring(errorbuf), "\n")[1]
##                 report(r, "$now,$usr,$itr,$success,$err,$t")
##             end
##         end
##         info("Finished, collecting results")
##         destroy_key(mr)
##     end
## end


@doc """
Run expression by specified number of users during specified time in parallel
and collect results.
Example - run GET request by 100 users during 30 seconds:

    using Requests
    timetable = @runduring 100 30 get("http://example.com")

""" ->
macro runduring(nusers::Int, seconds::Int, ex::Expr)
    return quote
        mr = Reporter(COLLECTOR_PORT)
        create_key(mr)
        @sync for usr=1:$nusers
            r = Reporter(COLLECTOR_PORT, mr.key)
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
        destroy_key(mr)
    end
end
