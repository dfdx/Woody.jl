
using Compat
using Docile
using ZMQ
using DataFrames
using IncDataStats

const COLLECTOR_PORT = int(get(ENV, "WOODY_PORT", 5543))

include("collector.jl")
include("reporter.jl")
include("macros.jl")

if !isdefined(:COLLECTOR)
    const COLLECTOR = Collector(COLLECTOR_PORT)
    @async run_collector_loop(COLLECTOR)
end


function run_reporter()
    mr = Reporter(5543)
    create_key(mr)
    @time for i=1:300_000
        report(mr, "1.434787842170113e9,100,3000,true,,1.1e-7")
    end
    destroy_key(mr)
end

