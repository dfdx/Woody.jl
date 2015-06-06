
using ZMQ
using Compat
using Docile
# using DataFrames
# using Winston


include("collector.jl")
include("reporter.jl")
include("controller.jl")
include("macros.jl")


function test_workers()
    ctr = Controller(5543)
    r = Reporter(5543, ctr.key)
    report(r, "hello")
    report(r, "bonjour")
    report(r, "goodbye")
    data = finalize(ctr)
end

