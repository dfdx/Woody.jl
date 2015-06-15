using Woody
using Base.Test

# write your own tests here
function test_workers()
    ctr = Controller(5543)
    r = Reporter(5543, ctr.key)
    report(r, "hello")
    report(r, "bonjour")
    report(r, "goodbye")
    timetable = finalize(ctr)
end

function test_collector()
    c = Collector(5543)
    Woody.run_collector_loop(c)
end


@test 1 == 1
