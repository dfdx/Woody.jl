

function unix2second(ts)
    dt = unix2datetime(ts)
end


@doc "Read reported data from collector and prepare time table" -> 
function readtimetable(s::Socket)
    groupby = GroupBy([:mtime, :user, :iter, :success, :error, :time],
                      groupers=[:mtime => (t -> )])
    while 
end

