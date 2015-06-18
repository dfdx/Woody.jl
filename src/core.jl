
using Compat
using Docile
using ZMQ
using DataFrames
using IncDataStats


const COLLECTOR_PORT = int(get(ENV, "WOODY_PORT", 5543))

include("collector.jl")
include("reporter.jl")
include("macros.jl")


function run_reporter()
    mr = Reporter(5543)
    create_key(mr)
    @time for i=1:1_000_000
        report(mr, "good morning")
    end
    destroy_key(mr)
end
