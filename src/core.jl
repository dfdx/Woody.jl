
using Compat
using Docile
using ZMQ
using IncDataStats


const COLLECTOR_PORT = int(get(ENV, "WOODY_PORT", 5543))

include("timetable.jl")
include("collector.jl")
include("reporter.jl")
include("controller.jl")
include("macros.jl")
include("analysis.jl")

@async begin
    c = Collector(COLLECTOR_PORT)
    run_collector_loop(c)
end
